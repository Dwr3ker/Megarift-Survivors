extends RefCounted
# Calamidad Mega: el segundo jefe del final. Entre dos Eternatus (15 minutos de partida despues de cada victoria, desde la
# segunda mitad) aparece un legendario Mega / Primigenio / Corona. Pega fuerte, ataca con avisos claros (Pisotón y
# Bombardeo, dano en % de TU vida maxima) y se enfurece al 50 % de vida. Cada Doom lo hace un 15 % mas rapido.
# Premio: tickets, un ticket x10, monedas y un objeto (se recogen del suelo). No se repite el mismo legendario en la partida.
const L = preload("res://scripts/lang.gd")
const MG = preload("res://scripts/mega.gd")
const WL = preload("res://scripts/wildleg.gd")
const DM = preload("res://scripts/doom.gd")

const LEAD := 900.0            # aparece 15 min de partida antes del siguiente Eternatus...
const AFTER_KILL := 480.0      # ...pero nunca antes de 8 min tras vencer al anterior
const MIN_GAP := 120.0         # si no cabe 2 min antes del siguiente Eternatus, se salta este ciclo
const HP_K := 3.0              # x la vida de un legendario salvaje en ese minuto (la forma Mega suma otro x1,3): ~40-55 % de la de Eternatus
const DMG_K := 1.3
const SPD_K := 1.1
const XP_MUL := 40.0
const STOMP_FIRST := 6.0
const STOMP_EVERY := 9.0
const STOMP_R := 150.0
const STOMP_WARN := 1.2
const STOMP_PCT := 0.25
const BARRAGE_FIRST := 12.0
const BARRAGE_EVERY := 15.0
const BARRAGE_R := 60.0
const BARRAGE_WARN := 1.4
const BARRAGE_PCT := 0.2
const PHASE2_AT := 0.5
const PHASE2_K := 1.4
const PAY := {"coins": 600, "t": 4, "t10": 1}
const COL_STOMP := Color("#ff9a3d")
const COL_BARRAGE := Color("#ff5b8a")

var m
var boss
var done := false
var phase := 1
var stomp_cd := STOMP_FIRST
var barrage_cd := BARRAGE_FIRST
var stats := {"stomps": 0, "barrages": 0}


# Legendarios con forma Mega / Primigenia / Corona con sprites, sin repetir los ya vistos en esta partida.
static func pool(main) -> Array:
	var out: Array = []
	for p in main._dex_list:
		var dx: int = int(p["dex"])
		if not bool(p.get("leg", false)) or main.cal_used.has(dx) or not MG.is_capable(dx):
			continue
		if main._smeta.has(str(dx)) and main._smeta.has(str(int(MG.form_for(dx)["form"]))) and main._dex_by.has(dx):
			out.append(dx)
	return out


# Segundo de partida en que toca la Calamidad de este ciclo, o -1 si no cabe antes del siguiente Eternatus.
static func due_at(eter_at: float, eter_last: float) -> float:
	var at: float = maxf(eter_at - LEAD, eter_last + AFTER_KILL)
	return at if at <= eter_at - MIN_GAP else -1.0


static func spawn(main):
	var cand: Array = pool(main)
	if cand.is_empty():
		main.cal_used.clear()
		cand = pool(main)
	if cand.is_empty():
		return null
	var dex: int = int(cand[randi() % cand.size()])
	main.cal_used[dex] = true
	var p: Dictionary = main._dex_by[dex]
	var t: float = main._dt()
	var minute: float = t / 60.0
	var lx: float = main._late_x(t)
	var def := {"dex": dex, "name": String(p["name"]), "hp": roundf(main._wl_norm_hp(t) * WL.hp_k(minute) * HP_K),
		"spd": WL.speed(minute) * SPD_K, "dmg": WL.dmg(minute) * DMG_K, "xp": roundf(XP_MUL * main.XP_ENEMY * main.XP_K), "behavior": "chase"}
	var e = main._make_enemy(def, main._ring_point(randf() * TAU), {"hp": 1.0, "spd": 1.0, "dmg": (1.0 + 0.4 * lx) * DM.enemy_dmg_k(main.eter_kills)}, true)
	MG.apply_boss(main, e, dex)
	e.set_meta("enc", "calamity")
	var c = (load("res://scripts/calamity.gd") as GDScript).new()
	c.start(main, e)
	main.Aud.sfx("boss")
	main._say(L.t("A Mega Calamity approaches: %s!") % e.enemy_name, 3.6)
	main.shake = 16.0
	return c


# Premio en orbes del suelo: tickets, un ticket x10, monedas y un objeto.
static func pay(main, e) -> void:
	for i in range(int(PAY["t"])):
		main._spawn_orb(e.position, "ticket", 1.0)
	for i in range(int(PAY["t10"])):
		main._spawn_orb(e.position, "ticket10", 1.0)
	for i in range(30):
		main._spawn_orb(e.position, "coin", float(PAY["coins"]) / 30.0)
	main._spawn_orb(e.position + Vector2(24.0, 0.0), "item", 0.0)
	var st: Dictionary = main.SV.d["stats"]
	st["calamityKills"] = int(st.get("calamityKills", 0)) + 1


func start(main, e) -> void:
	m = main
	boss = e


func cadence() -> float:
	return (1.0 + 0.15 * float(m.eter_kills)) * (PHASE2_K if phase >= 2 else 1.0)


func _hit_zone(pos: Vector2, r: float, warn: float, pct: float, col: Color) -> void:
	var h = m._hazard_zone(pos, r, warn, 0.0, "rock", col)
	h.pct = pct


func tick(delta: float) -> void:
	if done:
		return
	if boss == null or not is_instance_valid(boss) or boss.dead:
		stop()
		return
	if m.player.dead:
		return
	if phase == 1 and boss.hp / maxf(1.0, boss.max_hp) <= PHASE2_AT:
		phase = 2
		m._say(L.t("The Calamity is enraged!"), 3.0)
		m.shake = maxf(m.shake, 10.0)
		m.Aud.sfx("boss")
	var cad: float = cadence()
	stomp_cd -= delta * cad
	barrage_cd -= delta * cad
	if stomp_cd <= 0.0:
		stomp_cd = STOMP_EVERY
		stats["stomps"] += 1
		_hit_zone(boss.position, STOMP_R, STOMP_WARN, STOMP_PCT, COL_STOMP)
		boss.play("Charge", 1.0)
	if barrage_cd <= 0.0:
		barrage_cd = BARRAGE_EVERY
		stats["barrages"] += 1
		var n: int = 3 + (1 if phase >= 2 else 0) + mini(2, m.eter_kills / 2)
		for i in range(n):
			var off: Vector2 = Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(60.0, 150.0)
			_hit_zone(m.player.position + off, BARRAGE_R, BARRAGE_WARN + float(i) * 0.15, BARRAGE_PCT, COL_BARRAGE)
		m.Aud.sfx("rift")


func stop() -> void:
	done = true
