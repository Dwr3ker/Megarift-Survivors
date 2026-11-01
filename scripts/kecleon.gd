extends RefCounted
# S57.5-57.6: Kecleon, el comerciante. Seis variantes con catalogo propio de 6 objetos, una compra por visita,
# un reroll por visita con precio global creciente, un solo Kecleon activo y separacion minima.
# Los efectos se conectan a las funciones de estadisticas ya existentes en main.gd (no hay pipelines paralelos).

const PAD = preload("res://scripts/pad.gd")
const IC = preload("res://scripts/icons.gd")
const UIS = preload("res://scripts/ui_style.gd")
const SVD = preload("res://scripts/save_data.gd")
const REROLL := [50, 100, 175, 275, 400, 550]
const RESERVE_PCT := 0.3      # reserva: pagas el 30% ahora y el siguiente Kecleon trae el objeto por el resto
const RES_COL := "#f6b52b"
const VISIT_TIME := 75.0
const MIN_SEP := 520.0
const SEAL_FLOOR := 0.6

# variante -> nombre, color de etiqueta, tinte del sprite
const VAR := {
	"green": {"name": "Green Kecleon", "col": "#6bd66b", "tint": Color(1, 1, 1), "w": 40.0},
	"blue": {"name": "Blue Kecleon", "col": "#5ab0ff", "tint": Color(0.55, 0.72, 1.0), "w": 20.0},
	"purple": {"name": "Purple Kecleon", "col": "#b57bff", "tint": Color(0.82, 0.62, 1.0), "w": 16.0},
	"red": {"name": "Red Kecleon", "col": "#ff6b6b", "tint": Color(1.0, 0.55, 0.5), "w": 14.0},
	"gold": {"name": "Golden Kecleon", "col": "#ffd23f", "tint": Color(1.0, 0.88, 0.42), "w": 10.0},
	"shiny": {"name": "Shiny blue Kecleon", "col": "#7fe8ff", "tint": Color(0.8, 0.95, 1.25), "w": 0.0},
}
const ORDER := ["green", "blue", "purple", "red", "gold", "shiny"]

# id: [nombre, precio, maximo, descripcion]
const ITEMS := {
	"fortune": ["Clover", 120, 1, "+10% luck on chests and normal rewards. Never changes fixed odds."],
	"sprout": ["Healing Sprout", 100, 2, "Every 15 defeats, restore 4% of your max HP (per unit)."],
	"thornscarf": ["Thorn Scarf", 150, 1, "When hit, hurt the enemies next to you. Cooldown 4 s."],
	"opener": ["Opening Fang", 130, 1, "Your first hit on each normal enemy deals +40% damage."],
	"canteen": ["Canteen", 120, 1, "Every 45 s, restore 12% of your max HP."],
	"afterimage": ["Afterimage Charm", 280, 1, "When hit, a speed burst (+35%, 2.5 s). 20 s cooldown."],
	"ribbon": ["Evasion Ribbon", 140, 3, "+3% chance to dodge a hit per unit."],
	"gustback": ["Recoil Gust", 170, 1, "When hit, knock nearby enemies far away. Cooldown 8 s."],
	"veil": ["Spectral Veil", 220, 1, "Every 25 s, 1.2 s of invulnerability."],
	"tailwind": ["Tailwind", 180, 1, "Each defeat gives 0.8 s of +25% speed."],
	"mystic": ["Mystic Orb", 160, 2, "+10% status damage (poison and burn) per unit."],
	"hexing": ["Hexing Bell", 120, 2, "+8% duration of negative statuses per unit."],
	"echo": ["Resonant Echo", 140, 1, "Every 12 s, your next hit deals +20% damage."],
	"binding": ["Binding Rune", 200, 1, "15% chance to slow normal enemies on each hit."],
	"ember": ["Ember Fang", 150, 2, "+8% damage to enemies below 40% HP per unit."],
	"berserk": ["Berserker Band", 180, 1, "+10% damage while below 50% HP."],
	"shatter": ["Shatter Stone", 230, 2, "+10% damage to elites and bosses per unit."],
	"executioner": ["Executioner's Mark", 220, 1, "Normal enemies below 10% HP die instantly."],
	"drum": ["War Drum", 280, 1, "10 defeats within 6 s give +15% attack speed for 6 s."],
	"dragonfire": ["Dragonfire Core", 320, 1, "Every 25 hits, a small extra explosion."],
	"royal": ["Royal Spoils", 200, 2, "10% chance to gain +1 coin per defeat, per unit (max 300 per run)."],
	"tmap": ["Treasure Map", 240, 1, "+25% chests in newly explored areas."],
	"seal": ["Merchant's Seal", 150, 1, "-10% on future merchant items (not on rerolls)."],
	"dice": ["Lucky Dice", 200, 1, "Your next chest gives a higher-quality reward. Single use."],
	"crown": ["Crown of Plenty", 350, 1, "+160 coins for each of your first 3 bosses defeated."],
	"chrono": ["Chrono Relic", 320, 1, "Every 40 s, slows nearby normal enemies for 5 s."],
	"infinity": ["Infinity Shard", 450, 1, "Boosts your highest upgrade (+15% levels, minimum +1)."],
	"mirror": ["Double Mirror", 300, 1, "12% chance for each hit to repeat for 60% of its damage."],
	"starfall": ["Starfall", 350, 1, "Every 30 s, stars fall on the 5 nearest enemies."],
}
const CAT := {
	"green": ["fortune", "sprout", "thornscarf", "opener", "canteen"],
	"blue": ["afterimage", "ribbon", "gustback", "veil", "tailwind"],
	"purple": ["mystic", "hexing", "echo", "binding"],
	"red": ["ember", "executioner", "berserk", "shatter", "drum", "dragonfire"],
	"gold": ["royal", "tmap", "seal", "dice", "crown"],
	"shiny": ["chrono", "infinity", "mirror", "starfall"],
}

var m = null
var kc := {}
var reroll_n := 0
var active = null          # nodo Merchant
var variant := ""
var offers: Array = []
var bought := false
var rerolled := false
var kec_t := 210.0
var seen := {}             # variantes vistas esta partida
var log: Array = []
# estados de objetos
var echo_t := 12.0
var echo_ready := false
var after_t := 0.0
var after_cd := 0.0
var drum_times: Array = []
var drum_t := 0.0
var hit_n := 0
var chrono_t := 40.0
var phoenix_used := false
var tail_t := 0.0
var sprout_n := 0
var scarf_cd := 0.0
var gust_cd := 0.0
var canteen_t := 45.0
var veil_t := 25.0
var star_t := 30.0
var crown_done := false
var crown_n := 0
var royal_got := 0
var dice_ready := false
var infinity_id := ""
var _busy_hit := false
var reserved := ""            # objeto reservado (sobrevive a la marcha de Kecleon)
var reserve_paid := 0
var just_reserved := false
# interfaz
var ui = null
var ui_btns: Array = []       # 0-2: ofertas, 3: objeto reservado
var ui_res_btns: Array = []
var ui_parts: Array = []      # per card: {"box", "icon", "tag", "name", "desc", "price"}
var ui_info = null
var ui_coins = null
var ui_reroll = null


func n(id: String) -> int:
	return int(kc.get(id, 0))


# ------------------------------------------------------------------ catalogo
func valid(id: String) -> bool:
	return ITEMS.has(id)


func eligible(id: String) -> bool:
	if not valid(id):
		return false
	if n(id) >= int(ITEMS[id][2]):
		return false
	match id:
		"dice":
			return not dice_ready
		"crown":
			return not crown_done
		"infinity":
			return _inf_target() != ""
	return true


func _inf_target() -> String:
	var best := ""
	var bl := 0
	for sid in m.STAT_IDS:
		if sid == "hp" or sid == "heal" or sid == "rgn":
			continue
		var lv: int = int(m.stat_lv.get(sid, 0))
		if lv > bl and lv < int(m.STATS[sid]["max"]):
			bl = lv
			best = String(sid)
	return best


func price(id: String) -> int:
	var p: int = int(ITEMS[id][1])
	if n("seal") > 0 and id != "seal":
		p = maxi(int(round(float(ITEMS[id][1]) * SEAL_FLOOR)), int(round(float(p) * 0.9)))
	return p


func reroll_price() -> int:
	if reroll_n < REROLL.size():
		return int(REROLL[reroll_n])
	return int(REROLL[REROLL.size() - 1]) + 150 * (reroll_n - REROLL.size() + 1)


func pool_of(v: String) -> Array:
	var out: Array = []
	for id in CAT[v]:
		if eligible(String(id)):
			out.append(String(id))
	return out


func pick_offers(v: String, avoid: Array = []) -> Array:
	var pool: Array = pool_of(v)
	var fresh: Array = []
	for id in pool:
		if not avoid.has(id) and id != reserved:
			fresh.append(id)
	fresh.shuffle()
	var out: Array = fresh.slice(0, 3)
	if out.size() < 3:   # no hay suficientes alternativas: se completan con las anteriores
		var rest: Array = []
		for id in pool:
			if not out.has(id) and id != reserved:
				rest.append(id)
		rest.shuffle()
		for id in rest:
			if out.size() < 3:
				out.append(id)
	return out


# ------------------------------------------------------------------ compra
# Devuelve "" si todo fue bien o el motivo del rechazo. Nada se cobra si falla.
func buy(id: String) -> String:
	if bought:
		return "ya"
	var is_res: bool = reserved != "" and id == reserved
	if not (offers.has(id) or is_res) or not eligible(id):
		return "invalido"
	var p: int = reserved_price() if is_res else price(id)
	if m.coins < p:
		return "fondos"
	m.coins -= p
	bought = true
	if is_res:
		reserved = ""
		reserve_paid = 0
	_apply(id)
	log.append(["buy", variant, id, p])
	return ""


# ------------------------------------------------------------------ reserva
func reserve_cost(id: String) -> int:
	return int(ceil(float(price(id)) * RESERVE_PCT))


# Lo que falta por pagar del objeto reservado (el Sello de Mercader tambien rebaja este resto).
func reserved_price() -> int:
	return maxi(0, price(reserved) - reserve_paid)


# Reservar gasta la compra de esta visita: Kecleon se marcha y el siguiente trae el objeto.
func reserve(id: String) -> String:
	if bought:
		return "ya"
	if reserved != "":
		return "reservado"
	if not offers.has(id) or not eligible(id):
		return "invalido"
	var p: int = reserve_cost(id)
	if m.coins < p:
		return "fondos"
	m.coins -= p
	bought = true
	just_reserved = true
	reserved = id
	reserve_paid = p
	if SVD.d.has("stats"):   # for the Layaway achievements
		SVD.d["stats"]["reservations"] = int(SVD.d["stats"].get("reservations", 0)) + 1
	m.Aud.sfx("coin")
	m.add_text(m.player.position + Vector2(0, -m.player.body_h - 20.0), m.L.t("Reserved: %s") % m.L.t(String(ITEMS[id][0])), Color(RES_COL), 20)
	log.append(["reserve", variant, id, p])
	return ""


# Al llegar un Kecleon: si el objeto reservado ya no se puede entregar, devuelve lo pagado.
func _check_reserved() -> void:
	if reserved == "" or eligible(reserved):
		return
	m.coins += reserve_paid
	m._say(m.L.t("Your reserved %s can't be delivered: %d coins refunded") % [m.L.t(String(ITEMS[reserved][0])), reserve_paid], 3.5)
	log.append(["refund", reserved, reserve_paid])
	reserved = ""
	reserve_paid = 0


# Estado para el guardado a mitad de partida (run_save.gd).
func save_state() -> Dictionary:
	return {"kc": kc.duplicate(), "reroll_n": reroll_n, "seen": seen.duplicate(), "reserved": reserved, "reserve_paid": reserve_paid,
		"dice_ready": dice_ready, "crown_done": crown_done, "crown_n": crown_n, "royal_got": royal_got, "infinity_id": infinity_id,
		"phoenix_used": phoenix_used}


func load_state(s: Dictionary) -> void:
	kc = (s.get("kc", {}) as Dictionary).duplicate()
	reroll_n = int(s.get("reroll_n", 0))
	seen = (s.get("seen", {}) as Dictionary).duplicate()
	reserved = String(s.get("reserved", ""))
	if reserved != "" and not valid(reserved):
		reserved = ""
	reserve_paid = int(s.get("reserve_paid", 0)) if reserved != "" else 0
	dice_ready = bool(s.get("dice_ready", false))
	crown_done = bool(s.get("crown_done", false))
	crown_n = int(s.get("crown_n", 0))
	royal_got = int(s.get("royal_got", 0))
	infinity_id = String(s.get("infinity_id", ""))
	phoenix_used = bool(s.get("phoenix_used", false))


func _apply(id: String) -> void:
	match id:
		"dice":
			dice_ready = true
		"infinity":
			var t: String = _inf_target()
			infinity_id = t
			if t != "":
				var lv: int = int(m.stat_lv.get(t, 0))
				var add: int = maxi(1, int(ceil(float(lv) * 0.15)))
				m.stat_lv[t] = mini(int(m.STATS[t]["max"]), lv + add)
			kc[id] = n(id) + 1
		_:
			kc[id] = n(id) + 1
	m.Aud.sfx("shinyGet")
	m.add_text(m.player.position + Vector2(0, -m.player.body_h - 20.0), m.L.t(String(ITEMS[id][0])), Color(VAR[variant]["col"]), 22)


func try_reroll() -> String:
	if bought or rerolled:
		return "ya"
	var p: int = reroll_price()
	if m.coins < p:
		return "fondos"
	var fresh: Array = pick_offers(variant, offers)
	if fresh.is_empty():
		return "invalido"
	m.coins -= p
	reroll_n += 1
	rerolled = true
	offers = fresh
	log.append(["reroll", p])
	return ""


# ------------------------------------------------------------------ modificadores (se enchufan a main.gd)
func dmg_mul(e) -> float:
	var k := 1.0
	if e != null:
		if e.hp < e.max_hp * 0.4:
			k += 0.08 * float(n("ember"))
		if e.boss or e.has_meta("elite"):
			k += 0.10 * float(n("shatter"))
		if n("opener") > 0 and not e.boss and not e.has_meta("kop"):
			e.set_meta("kop", true)
			k += 0.4
	if n("berserk") > 0 and m.player.hp < m.player.max_hp * 0.5:
		k += 0.10
	return k


func spd_mul() -> float:
	return 1.0 + (0.35 if after_t > 0.0 else 0.0) + (0.25 if tail_t > 0.0 else 0.0)


func cd_mul() -> float:
	return 1.0 / (1.0 + (0.15 if drum_t > 0.0 else 0.0))


func def_add() -> float:
	return 0.0


func xp_mul() -> float:
	return 1.0


func mag_mul() -> float:
	return 1.0


func range_mul() -> float:
	return 1.0


func cc_dur() -> float:
	return 1.0 + 0.08 * float(n("hexing"))


func dot_mul() -> float:
	return 1.0 + 0.10 * float(n("mystic"))


func luck() -> float:
	return 0.10 if n("fortune") > 0 else 0.0


func map_mul() -> float:
	return 1.25 if n("tmap") > 0 else 1.0


func dodge() -> bool:
	var p: float = minf(0.15, 0.03 * float(n("ribbon")))
	return p > 0.0 and randf() < p


# Cofre: la suerte y los Dados mejoran la calidad (r mas alto = mejor premio). Los dados se gastan una vez.
func chest_roll_adjust(r: float) -> float:
	if dice_ready:
		dice_ready = false
		log.append(["dice"])
		return 0.85
	return minf(0.999, r + luck() * 0.8)


# ------------------------------------------------------------------ eventos de combate
func on_hit(e, d: float) -> void:
	if _busy_hit:
		return
	# Cristal Eco: se consume el siguiente golpe (el bonus ya se aplico en dmg_mul_echo)
	if n("executioner") > 0 and not e.boss and not e.dead and e.hp < e.max_hp * 0.10:
		_busy_hit = true
		m._damage_enemy(e, e.hp + 1.0, Color("#ff4a4a"))
		_busy_hit = false
		return
	if n("mirror") > 0 and not e.dead and randf() < 0.12:
		_busy_hit = true
		m._damage_enemy(e, maxf(1.0, d * 0.6), Color("#cfe8ff"))
		_busy_hit = false
	if n("binding") > 0 and not e.boss and randf() < 0.15:
		e.apply_slow(0.3, 2.0)
	if n("dragonfire") > 0:
		hit_n += 1
		if hit_n >= 25:
			hit_n = 0
			_busy_hit = true
			var c: Vector2 = e.position
			m._ring(c, 6.0, 90.0, Color("#ff7b3d"), 0.4, 4.0)
			for o in m.enemies.duplicate():
				if is_instance_valid(o) and not o.dead and o.position.distance_to(c) < 90.0:
					m._damage_enemy(o, maxf(8.0, d * 0.8), Color("#ff7b3d"))
			_busy_hit = false


func echo_take() -> float:
	if n("echo") > 0 and echo_ready:
		echo_ready = false
		echo_t = 12.0
		return 1.2
	return 1.0


func on_kill(e) -> void:
	if n("tailwind") > 0:
		tail_t = 0.8
	if n("sprout") > 0:
		sprout_n += 1
		if sprout_n >= 15:
			sprout_n = 0
			_heal_pct(0.04 * float(n("sprout")))
	if n("royal") > 0 and royal_got < 300 and randf() < 0.10 * float(n("royal")):
		m.coins += 1
		royal_got += 1
	if n("drum") > 0:
		drum_times.append(m.run_time)
		while not drum_times.is_empty() and m.run_time - float(drum_times[0]) > 6.0:
			drum_times.remove_at(0)
		if drum_times.size() >= 10 and drum_t <= 0.0:
			drum_t = 6.0
			drum_times.clear()
			m.add_text(m.player.position + Vector2(0, -m.player.body_h - 24.0), m.L.t("War Drum!"), Color("#ff6b6b"), 22)
	if n("crown") > 0 and crown_n < 3 and e.boss and not e.judge:
		crown_n += 1
		crown_done = crown_n >= 3
		for i in range(8):
			m._spawn_orb(e.position, "coin", 20.0)
		m.add_text(e.position + Vector2(0, -50), m.L.t("Crown of Plenty!"), Color("#ffd23f"), 24)


func on_hurt() -> void:
	if n("afterimage") > 0 and after_cd <= 0.0:
		after_cd = 20.0
		after_t = 2.5
	var c: Vector2 = m.player.position
	if n("thornscarf") > 0 and scarf_cd <= 0.0:
		scarf_cd = 4.0
		m._ring(c, 6.0, 80.0, Color("#6bd66b"), 0.35, 3.0)
		for o in m.enemies.duplicate():
			if is_instance_valid(o) and not o.dead and o.position.distance_to(c) < 80.0:
				m._damage_enemy(o, 14.0 + 3.0 * float(m.player.level), Color("#6bd66b"))
	if n("gustback") > 0 and gust_cd <= 0.0:
		gust_cd = 8.0
		m._ring(c, 6.0, 140.0, Color("#9fd8ff"), 0.4, 3.0)
		for o in m.enemies:
			if is_instance_valid(o) and not o.dead and not o.boss and o.position.distance_to(c) < 140.0:
				o.position += (o.position - c).normalized() * 110.0


func _heal_pct(p: float) -> void:
	var hl: float = m._heal_real(maxf(1.0, m.player.max_hp * p))
	if hl > 0.0:
		m.add_text(m.player.position + Vector2(randf_range(-10.0, 10.0), -m.player.body_h - 8.0), "+%d" % maxi(1, roundi(hl)), Color("#7dffb0"), 16)


# Ya no existe la Pluma Fenix (duplicaba Segunda oportunidad): se mantiene por compatibilidad con main.gd.
func try_phoenix() -> bool:
	return false


func tick(delta: float) -> void:
	echo_t -= delta
	if n("echo") > 0 and echo_t <= 0.0:
		echo_ready = true
		echo_t = 0.0
	tail_t = maxf(0.0, tail_t - delta)
	scarf_cd = maxf(0.0, scarf_cd - delta)
	gust_cd = maxf(0.0, gust_cd - delta)
	if n("canteen") > 0:
		canteen_t -= delta
		if canteen_t <= 0.0:
			canteen_t = 45.0
			_heal_pct(0.12)
	if n("veil") > 0:
		veil_t -= delta
		if veil_t <= 0.0:
			veil_t = 25.0
			m.player.invuln = maxf(m.player.invuln, 1.2)
			m._ring(m.player.position, 6.0, 90.0, Color("#cfc2ff"), 0.5, 3.0)
	if n("starfall") > 0:
		star_t -= delta
		if star_t <= 0.0:
			star_t = 30.0
			var near: Array = m._p_targets(5, 460.0)
			for o in near:
				m._ring(o.position, 4.0, 60.0, Color("#ffe14a"), 0.4, 3.0)
				m._damage_enemy(o, 80.0 + 8.0 * float(m.player.level), Color("#ffe14a"))
	after_t = maxf(0.0, after_t - delta)
	after_cd = maxf(0.0, after_cd - delta)
	drum_t = maxf(0.0, drum_t - delta)
	if n("chrono") > 0:
		chrono_t -= delta
		if chrono_t <= 0.0:
			chrono_t = 40.0
			var c: Vector2 = m.player.position
			m._ring(c, 8.0, 380.0, Color("#9fe8ff"), 0.7)
			for e in m.enemies:
				if is_instance_valid(e) and not e.dead and not e.boss and e.position.distance_to(c) < 380.0:
					e.apply_slow(0.6, 5.0)


# ------------------------------------------------------------------ aparicion del comerciante
class Merchant extends Node2D:
	var variant := "green"
	var ttl := 75.0
	var t := 0.0
	var actor = null
	var uid := 0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var K = load("res://scripts/kecleon.gd")
		var v: Dictionary = K.VAR[variant]
		var col: Color = Color(String(v["col"]))
		draw_circle(Vector2(0, 4), 22.0, Color(0, 0, 0, 0.3))
		draw_arc(Vector2(0, -20), 34.0 + 2.0 * sin(t * 3.0), 0, TAU, 28, Color(col.r, col.g, col.b, 0.5), 2.0)
		if actor != null:
			return
		# Kecleon dibujado (si no hay sprite): cuerpo, franja en zigzag y ojos
		var tint: Color = v["tint"]
		var body: Color = Color("#7bc36a") * tint
		body.a = 1.0
		draw_circle(Vector2(0, -22), 18.0, body)
		draw_circle(Vector2(0, -34), 13.0, body)
		for i in range(5):
			var x: float = -16.0 + 8.0 * float(i)
			draw_colored_polygon(PackedVector2Array([Vector2(x, -14), Vector2(x + 4, -5), Vector2(x + 8, -14)]), Color("#e8594a"))
		draw_circle(Vector2(-6, -36), 3.0, Color.WHITE)
		draw_circle(Vector2(6, -36), 3.0, Color.WHITE)
		draw_circle(Vector2(-6, -36), 1.5, Color.BLACK)
		draw_circle(Vector2(6, -36), 1.5, Color.BLACK)


func shiny_chance(t: float) -> float:
	var pts := [[180.0, 0.01], [300.0, 0.02], [480.0, 0.04], [720.0, 0.07], [960.0, 0.10], [1200.0, 0.12]]
	if t < 180.0:
		return 0.0
	for i in range(pts.size() - 1):
		if t <= float(pts[i + 1][0]):
			var a: Array = pts[i]
			var b: Array = pts[i + 1]
			return lerpf(float(a[1]), float(b[1]), (t - float(a[0])) / (float(b[0]) - float(a[0])))
	return 0.12


func choose_variant() -> String:
	var shiny_ok: bool = not pool_of("shiny").is_empty()
	if shiny_ok and randf() < shiny_chance(m.run_time):   # una sola tirada por oportunidad
		return "shiny"
	var tot := 0.0
	var ok: Array = []
	for v in ORDER:
		if v == "shiny":
			continue
		if not pool_of(v).is_empty():
			ok.append(v)
			tot += float(VAR[v]["w"])
	if ok.is_empty():
		return ""
	var r: float = randf() * tot
	for v in ok:
		r -= float(VAR[v]["w"])
		if r <= 0.0:
			return String(v)
	return String(ok[ok.size() - 1])


# pos_ok(pos) lo da el director de POI (muros, separacion con otros puntos).
func spawn(pos_ok: Callable, force: String = "") -> bool:
	if active != null and is_instance_valid(active):
		return false      # un solo Kecleon activo
	var v: String = force if force != "" else choose_variant()
	if v == "" or pool_of(v).is_empty():
		return false
	m.ach_event("kec", {"variant": v})
	var pos: Variant = null
	for i in range(8):
		var c: Vector2 = m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(300.0, 480.0)
		if pos_ok.call(c):
			pos = c
			break
	if pos == null:
		return false
	var mer := Merchant.new()
	mer.variant = v
	mer.ttl = VISIT_TIME
	mer.position = pos
	m.world.add_child(mer)
	_attach_sprite(mer, v)
	active = mer
	variant = v
	_check_reserved()
	offers = pick_offers(v)
	bought = false
	rerolled = false
	just_reserved = false
	seen[v] = true
	m.Aud.sfx("rift")
	m._say(m.L.t("A %s has arrived!") % m.L.t(String(VAR[v]["name"])), 3.0)
	m._ring(pos, 6.0, 90.0, Color(String(VAR[v]["col"])), 0.6, 4.0)
	log.append(["spawn", v])
	return true


func _attach_sprite(mer, v: String) -> void:
	if not (m._dex_by.has(352) and m._smeta.has("352")):
		return
	var a = m.Actor.new()
	a.setup(352, m._sm(352), m.flash_shader, 1.0, v == "shiny")
	a.modulate = VAR[v]["tint"]
	mer.add_child(a)
	mer.actor = a


func depart() -> void:
	if active != null and is_instance_valid(active):
		m._ring(active.position, 6.0, 70.0, Color(String(VAR[variant]["col"])), 0.4, 3.0)
		active.queue_free()
	active = null
	close_ui()
	log.append(["depart", variant])


# ------------------------------------------------------------------ interfaz de la tienda
func open_ui() -> void:
	if ui != null or active == null:
		return
	m.shop_open = true
	var layer := CanvasLayer.new()
	layer.layer = 70
	m.add_child(layer)
	ui = layer
	var dim := ColorRect.new()
	dim.color = Color(UIS.INK, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var root := CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var kth := Theme.new()
	kth.default_font_size = 20
	load("res://scripts/pxfont.gd").apply(kth)   # misma fuente pixelada que el resto del juego
	root.theme = kth
	layer.add_child(root)
	var panel := PanelContainer.new()
	var col := Color(String(VAR[variant]["col"]))
	# the menus' pixel frame (ink outline, accent band, dark fill), banded in this Kecleon's colour
	var sb: StyleBox = UIS.frame(UIS.PANEL, col.darkened(0.25)).duplicate()
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	# cabecera: nombre de la variante a la izquierda, monedas a la derecha
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	vb.add_child(head)
	var title := Label.new()
	title.text = m.L.t(String(VAR[variant]["name"]))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", col)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var coin_ic := TextureRect.new()
	coin_ic.texture = IC.tex("coin", 3)
	coin_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin_ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(coin_ic)
	ui_coins = Label.new()
	ui_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_coins.add_theme_font_size_override("font_size", 26)
	ui_coins.add_theme_color_override("font_color", UIS.GOLD)
	head.add_child(ui_coins)
	# tiempo que le queda a Kecleon (el reloj de la partida esta parado con la tienda abierta)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 12)
	vb.add_child(trow)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = VISIT_TIME
	bar.value = clampf(active.ttl, 0.0, VISIT_TIME)
	var bbg := UIS.box(UIS.INK, UIS.EDGE, 2, false)
	bbg.set_content_margin_all(0)
	var bfill := UIS.box(col, Color.TRANSPARENT, 0, false)
	bfill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bbg)
	bar.add_theme_stylebox_override("fill", bfill)
	trow.add_child(bar)
	var tl := Label.new()
	tl.text = m.L.t("Leaves in %ds") % ceili(maxf(active.ttl, 0.0))
	tl.add_theme_font_size_override("font_size", 18)
	tl.add_theme_color_override("font_color", UIS.MUTED)
	trow.add_child(tl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	ui_btns = []
	ui_res_btns = []
	ui_parts = []
	for i in range(4):
		var colv := VBoxContainer.new()
		colv.add_theme_constant_override("separation", 6)
		row.add_child(colv)
		var b := Button.new()
		b.custom_minimum_size = Vector2(230, 280)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL   # same height for every card, so the Reserve buttons line up
		_style_card(b, Color(RES_COL) if i == 3 else col)
		b.pressed.connect(_on_buy.bind(i))
		colv.add_child(b)
		ui_btns.append(b)
		ui_parts.append(_card_layout(b))
		if i < 3:
			var rb := Button.new()
			rb.custom_minimum_size = Vector2(230, 44)
			rb.add_theme_font_size_override("font_size", 17)
			_style_btn(rb, false)
			rb.pressed.connect(_on_reserve.bind(i))
			colv.add_child(rb)
			ui_res_btns.append(rb)
		# the reserved card has no Reserve button: it fills its whole column, down to the line of the Reserve buttons
	ui_info = Label.new()
	ui_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_info.add_theme_font_size_override("font_size", 18)
	vb.add_child(ui_info)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row2)
	ui_reroll = Button.new()
	ui_reroll.custom_minimum_size = Vector2(250, 64)
	ui_reroll.add_theme_font_size_override("font_size", 24)
	_style_btn(ui_reroll, true)
	ui_reroll.pressed.connect(_on_reroll)
	row2.add_child(ui_reroll)
	var close := Button.new()
	close.text = m.L.t("Close")
	close.custom_minimum_size = Vector2(200, 64)
	close.add_theme_font_size_override("font_size", 24)
	_style_btn(close, false)
	close.pressed.connect(close_ui)
	row2.add_child(close)
	_refresh_ui()
	PAD.apply()   # make sure the gamepad's Confirm / Back buttons drive the shop buttons
	_focus_first_buy(close)


# Focus the first item you can afford (a disabled button gives no feedback when you press it); with none, the Close button.
func _focus_first_buy(close: Button = null) -> void:
	for b in ui_btns:
		var bb: Button = b
		if bb.is_visible_in_tree() and not bb.disabled:
			bb.grab_focus()
			return
	if close != null:
		close.grab_focus()
	elif not ui_btns.is_empty():
		(ui_btns[0] as Button).grab_focus()


func _refresh_ui() -> void:
	if ui == null:
		return
	ui_coins.text = str(m.coins)
	for i in range(4):
		var b: Button = ui_btns[i]
		var id: String = ""
		if i < 3 and i < offers.size():
			id = String(offers[i])
		elif i == 3 and reserved != "" and not just_reserved:
			id = reserved
		b.get_parent().visible = id != ""
		if id == "":
			continue
		var it: Array = ITEMS[id]
		var cost: int = reserved_price() if i == 3 else price(id)
		var pt: Dictionary = ui_parts[i]
		(pt["icon"] as TextureRect).texture = IC.tex("kec:" + id, 4)
		(pt["tag"] as Label).text = m.L.t("RESERVED") if i == 3 else m.L.t("Owned %d/%d") % [n(id), int(it[2])]
		(pt["tag"] as Label).add_theme_color_override("font_color", UIS.GOLD if i == 3 else UIS.MUTED)
		(pt["name"] as Label).text = m.L.t(String(it[0]))
		(pt["desc"] as Label).text = m.L.t(String(it[3]))
		(pt["price"] as Label).text = "%d %s" % [cost, m.L.t("coins")]
		b.disabled = bought or m.coins < cost
		(pt["box"] as Control).modulate = Color(1, 1, 1, 0.5 if b.disabled else 1.0)
		if i < 3:
			var rb: Button = ui_res_btns[i]
			rb.text = "%s  (%d)" % [m.L.t("Reserve"), reserve_cost(id)]
			rb.disabled = bought or reserved != "" or m.coins < reserve_cost(id)
	ui_reroll.text = "%s  (%d)" % [m.L.t("Reroll offers"), reroll_price()]
	ui_reroll.disabled = bought or rerolled or m.coins < reroll_price()
	if just_reserved:
		ui_info.text = m.L.t("Reserved! The next Kecleon will bring it.")
	elif bought:
		ui_info.text = m.L.t("Thanks for your purchase!")
	elif reserved != "":
		ui_info.text = m.L.t("Your reserved item is here. One reservation at a time.")
	elif rerolled:
		ui_info.text = m.L.t("Only one reroll per visit")
	else:
		ui_info.text = m.L.t("One purchase per visit. Reserve: pay 30% now, the next Kecleon brings it.")


func _on_buy(i: int) -> void:
	var id: String = ""
	if i == 3:
		id = reserved
	elif i < offers.size():
		id = String(offers[i])
	if id == "":
		return
	var r: String = buy(id)
	if r == "":
		_refresh_ui()
		close_ui_later()
	elif r == "fondos":
		m.Aud.sfx("hit")
	_refresh_ui()


func _on_reserve(i: int) -> void:
	if i >= offers.size():
		return
	var r: String = reserve(String(offers[i]))
	if r == "":
		_refresh_ui()
		close_ui_later()
	elif r == "fondos":
		m.Aud.sfx("hit")
	_refresh_ui()


func _on_reroll() -> void:
	var r: String = try_reroll()
	if r == "":
		m.Aud.sfx("coin")
	_refresh_ui()
	if not ui_btns.is_empty() and (ui_btns[0] as Button).is_visible_in_tree():
		(ui_btns[0] as Button).grab_focus()


# Square box in the menus' palette (ui_style.gd), with an optional soft drop shadow.
static func _sbx(bg: Color, border: Color, bw: int, shadow: bool = true) -> StyleBoxFlat:
	var s := UIS.box(bg, border, bw, false)
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 5
		s.shadow_offset = Vector2(0, 3)
	return s


# Offer card in the menus' look (like the Pokémon list cards): dark fill tinted with the Kecleon's colour,
# a colour stripe along the top, cyan glow on hover, gold ring on focus.
func _style_card(b: Button, col: Color) -> void:
	var base: Color = UIS.BG.lerp(col, 0.07)
	b.add_theme_stylebox_override("normal", _sbx(base, UIS.EDGE, 2))
	var hov := _sbx(base.lerp(UIS.WAVE, 0.16), UIS.WAVE, 3, false)
	hov.shadow_color = Color(UIS.WAVE, 0.45)
	hov.shadow_size = 10
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", _sbx(UIS.INK, UIS.GOLD, 3))
	b.add_theme_stylebox_override("focus", _sbx(base.lightened(0.08), UIS.GOLD, 4))
	b.add_theme_stylebox_override("disabled", _sbx(UIS.INK, UIS.EDGE.darkened(0.35), 2, false))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, UIS.TEXT)
	b.add_theme_color_override("font_disabled_color", UIS.MUTED.darkened(0.25))
	var stripe := ColorRect.new()
	stripe.color = col
	stripe.anchor_right = 1.0
	stripe.offset_left = 2.0
	stripe.offset_right = -2.0
	stripe.offset_top = 2.0
	stripe.offset_bottom = 8.0
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(stripe)


# Card contents laid out top-down inside the button (icon, tag, name, description, price at the bottom),
# so every card lines up the same however long its text is.
func _card_layout(b: Button) -> Dictionary:
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 12)
	mc.add_theme_constant_override("margin_right", 12)
	mc.add_theme_constant_override("margin_top", 16)
	mc.add_theme_constant_override("margin_bottom", 12)
	b.add_child(mc)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	mc.add_child(vb)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(0, 68)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(icon)
	var out := {"box": mc, "icon": icon}
	for k in [["tag", 15, UIS.MUTED], ["name", 19, UIS.TITLE], ["desc", 16, UIS.TEXT], ["price", 18, UIS.GOLD]]:
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", int(k[1]))
		l.add_theme_color_override("font_color", k[2])
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if String(k[0]) == "desc":
			l.size_flags_vertical = Control.SIZE_EXPAND_FILL   # pushes the price to the bottom of the card
			l.custom_minimum_size = Vector2(0, 8)
		vb.add_child(l)
		out[String(k[0])] = l
	return out


# Buttons in the menus' look: dark panel buttons, or the gold accent for the main action (Reroll).
func _style_btn(b: Button, gold: bool) -> void:
	var bg: Color = UIS.PANEL.lerp(UIS.GOLD, 0.22) if gold else UIS.BG
	var edge: Color = UIS.GOLD if gold else UIS.EDGE
	b.add_theme_stylebox_override("normal", _sbx(bg, edge, 3))
	var hov := _sbx(bg.lerp(UIS.WAVE, 0.16), UIS.WAVE, 3, false)
	hov.shadow_color = Color(UIS.WAVE, 0.45)
	hov.shadow_size = 10
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", _sbx(UIS.INK, UIS.GOLD, 3))
	b.add_theme_stylebox_override("focus", _sbx(bg.lightened(0.1), UIS.GOLD, 4))
	b.add_theme_stylebox_override("disabled", _sbx(UIS.INK, UIS.EDGE.darkened(0.35), 2, false))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, UIS.TITLE if gold else UIS.TEXT)
	b.add_theme_color_override("font_disabled_color", UIS.MUTED.darkened(0.25))


func close_ui_later() -> void:
	# tras comprar, la tienda se cierra un instante despues para que se vea el mensaje
	if ui == null:
		return
	var tw: Tween = ui.create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(_leave_after_buy)


# Tras comprar, Kecleon se marcha de verdad (una compra por visita)
func _leave_after_buy() -> void:
	depart()
	kec_t = randf_range(150.0, 240.0)


func close_ui() -> void:
	if ui != null and is_instance_valid(ui):
		ui.queue_free()
	ui = null
	ui_btns = []
	ui_res_btns = []
	ui_parts = []
	m.shop_open = false


# Atajos de teclado / mando mientras la tienda esta abierta (los llama main._input)
func ui_input(event: InputEvent) -> bool:
	if ui == null:
		return false
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4:
				_on_buy(int(event.keycode) - KEY_1)
				return true
			KEY_R:
				_on_reroll()
				return true
			KEY_ESCAPE, KEY_BACKSPACE:
				close_ui()
				return true
	elif event is InputEventJoypadButton and event.pressed:
		var bi: int = event.button_index
		# Confirm first (on a Nintendo layout the right-hand button is Confirm), then Back / Start close the shop
		if bi == PAD.btn("confirm"):
			_press_focused()
			return true
		if bi == PAD.btn("cancel") or bi == PAD.btn("pause") or (bi == JOY_BUTTON_BACK and not PAD.is_mapped(JOY_BUTTON_BACK)):
			close_ui()
			return true
		if bi == PAD.btn("ban") or bi == JOY_BUTTON_X:
			_on_reroll()
			return true
	return false


# Confirm on the highlighted shop button, even if the engine did not turn it into a press (custom pad map, disabled item).
func _press_focused() -> void:
	var f = m.get_viewport().gui_get_focus_owner()
	if not (f is Button) or ui == null or not ui.is_ancestor_of(f):
		return
	var b: Button = f
	if b.disabled:
		m.Aud.sfx("hit")   # cannot afford it: say so instead of doing nothing
		if ui_info != null:
			if bought:
				ui_info.text = m.L.t("Thanks for your purchase!")
			elif ui_res_btns.has(b) and reserved != "":
				ui_info.text = m.L.t("You already have a reservation")
			else:
				ui_info.text = m.L.t("Not enough coins")
		return
	b.pressed.emit()


# ------------------------------------------------------------------ ciclo de vida (lo llama main cada frame de juego)
func _spawn_ok() -> bool:
	return ["normal", "type", "daily", "coop"].has(m.mode) and not m.poi._busy() and not m.shop_open \
		and (m.poi.supply == null or not is_instance_valid(m.poi.supply)) and m.run_time > 150.0


func update(delta: float) -> void:
	tick(delta)
	if active != null and not is_instance_valid(active):
		active = null
	if active != null:
		active.ttl -= delta
		if bought and ui == null:
			_leave_after_buy()
			return
		if active.ttl <= 0.0 or m.player.dead or m.poi._busy():
			depart()
			kec_t = randf_range(150.0, 240.0)
		return
	kec_t -= delta
	if kec_t <= 0.0:
		if _spawn_ok() and spawn(Callable(m.poi, "_ok_pos")):
			kec_t = 9999.0
		else:
			kec_t = 20.0   # reintento acotado; no bloquea nada


func near(pp: Vector2) -> bool:
	return active != null and is_instance_valid(active) and active.position.distance_to(pp) < 64.0 and not bought_done()


func bought_done() -> bool:
	return false


func mark() -> Variant:
	if active == null or not is_instance_valid(active):
		return null
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	return {"sp": ct * (active.position + Vector2(0, -50)), "txt": m.L.t(String(VAR[variant]["name"])) + "  %ds" % ceili(active.ttl),
		"col": Color(String(VAR[variant]["col"]))}
