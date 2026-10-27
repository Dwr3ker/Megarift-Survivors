extends RefCounted
# Eternatus Eternamax (jefe final de la Partida normal, al estilo Doofcraft). Sustituye al Eternatus sencillo: un jefe
# casi inmovil que ataca con avisos claros y dano en % de TU vida maxima (como en Doofcraft), con 3 obeliscos que lo curan.
#   Eternarrayo : arco de 180 grados que barre (se esquiva con el dash o alejandose)      dano 60%
#   Canon       : circulo que te sigue 1,5 s, se fija 1 s y explota (radio 56)           dano 30%
#   Anillos     : 3 anillos que se expanden con huecos por donde pasar                   dano 15%
#   Cola        : si te quedas pegado 3 s, golpe en area (radio 180)                     dano 35%
#   Meteoros    : 5-8 impactos cerca de ti, que dejan charcos de 5 s                     dano 25% + 4% / 0,5 s
#   Obeliscos   : 3, curan al jefe mientras vivan: hay que destruirlos primero
# Tiempos y danos son los del balance publicado por Doofcraft (eternatus); la vida se calcula para este juego.
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

const DEX := 890
const FORM_ID := 189001            # Eternatus Eternamax (SpriteCollab 0890/0001)
const OBELISK_DEX := 476           # Probopass: el obelisco oscuro
const HP_K := 12.0                 # vida = 12 x la de un legendario de grieta en ese minuto (3200 + 9 t)
const OBELISK_HP := 0.125          # cada obelisco: 12,5 % de la vida del jefe
const OBELISK_HEAL := 0.004        # fraccion de la vida del jefe que cura cada obelisco por segundo
const TIME_LIMIT := 420.0          # despues: furia
const PHASE2_AT := 0.5
const ENRAGE_AT := 0.25
const CAD_CURVE := [[60.0, 1.25], [90.0, 1.8], [120.0, 2.5]]   # ritmo de ataques por minuto de partida

const BEAM_FIRST := 15.0
const BEAM_EVERY := 25.0
const BEAM_CHARGE := 2.5
const BEAM_SWEEP := 3.0
const BEAM_LEN := 640.0
const BEAM_W := 44.0
const BEAM_DMG := 0.6
const CANNON_EVERY := 6.0
const CANNON_TRACK := 1.5
const CANNON_LOCK := 1.0
const CANNON_R := 56.0
const CANNON_DMG := 0.3
const CANNON_BEAM_CHANCE := 0.25
const RING_EVERY := 11.0
const RING_WINDUP := 1.0
const RING_COUNT := 3
const RING_GAP := 0.9              # segundos entre anillos
const RING_SPEED := 175.0
const RING_THICK := 22.0
const RING_GAP_DEG := 36.0
const RING_DMG := 0.15
const TAIL_CLOSE_R := 150.0
const TAIL_CLOSE_S := 3.0
const TAIL_WINDUP := 1.2
const TAIL_R := 180.0
const TAIL_DMG := 0.35
const TAIL_CD := 5.0
const METEOR_EVERY := 14.0
const METEOR_DELAY := 1.5
const METEOR_R := 46.0
const METEOR_SPREAD := 110.0
const METEOR_DMG := 0.25
const POOL_LIFE := 5.0
const POOL_TICK := 0.5
const POOL_DMG := 0.04

# Doom (doom.gd): cada vez que vuelve, Eternatus aprende algo (nivel = veces derrotado antes de este combate).
#   1+  Pozo gravitatorio: te atrae hacia el 3 s y explota en el centro (se resiste caminando o con el dash)
#   2+  Eternarrayo doble: el barrido vuelve en sentido contrario tras un aviso corto
#   3+  Los obeliscos oscuros reaparecen (uno cada 45 s mientras falten)
const WELL_FIRST := 20.0
const WELL_EVERY := 32.0
const WELL_WINDUP := 1.5
const WELL_PULL_T := 3.0
const WELL_PULL := 110.0          # px/s: menos que tu velocidad, asi que caminar lo vence
const WELL_R := 520.0
const WELL_CORE := 70.0
const WELL_DMG := 0.3
const BEAM2_WARN := 0.9
const OBELISK_REGEN := 45.0

const COL_BEAM := Color("#c04bff")
const COL_CANNON := Color("#ff9a3d")
const COL_RING := Color("#7a8bff")
const COL_POOL := Color("#6a2bd0")


# Nodo que dibuja los ataques (anillos, rayo, canones, charcos) en el mundo.
class EtxFx extends Node2D:
	var ctl = null

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if ctl != null:
			ctl.draw_on(self)


var m
var boss
var fxn: EtxFx = null
var t := 0.0
var phase := 1
var enraged := false
var berserk := false
var done := false
var beam_cd := BEAM_FIRST
var cannon_cd := CANNON_EVERY
var ring_cd := 9.0
var meteor_cd := 11.0
var tail_cd := 0.0
var close_t := 0.0
var tail_wind := -1.0
var beam: Dictionary = {}
var doom := 0
var well_cd := WELL_FIRST
var well: Dictionary = {}
var regen_cd := OBELISK_REGEN
var cannons: Array = []
var rings: Array = []
var ring_queue: Array = []
var pools: Array = []
var obelisks: Array = []
var stats := {"beams": 0, "cannons": 0, "rings": 0, "meteors": 0, "tails": 0}


static func boss_hp(game_t: float) -> float:
	return roundf(HP_K * (3200.0 + 9.0 * game_t))


static func curve(points: Array, x: float) -> float:
	if x <= float(points[0][0]):
		return float(points[0][1])
	for i in range(1, points.size()):
		var a: Array = points[i - 1]
		var b: Array = points[i]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(points[points.size() - 1][1])


func start(main, e) -> void:
	m = main
	boss = e
	boss.rebody(FORM_ID, m._sm(FORM_ID), false)
	boss.enemy_name = L.t("Eternamax Eternatus")
	doom = int(m.eter_kills)
	fxn = EtxFx.new()
	fxn.ctl = self
	fxn.z_index = 4
	m.fx.add_child(fxn)
	_spawn_obelisks()


func _spawn_obelisks() -> void:
	for i in range(3):
		_spawn_obelisk(TAU * (float(i) + 0.5) / 3.0 + randf() * 0.4)


func _spawn_obelisk(ang: float) -> void:
	var hp: float = roundf(boss.max_hp * OBELISK_HP)
	var pos: Vector2 = boss.position + Vector2.from_angle(ang) * 330.0
	var def := {"dex": OBELISK_DEX, "name": "Probopass", "hp": hp, "spd": 0.0, "dmg": 0.0, "xp": 0.0, "behavior": "chase", "scripted": true}
	var o = m._make_enemy(def, pos, {"hp": 1.0, "dmg": 1.0, "spd": 1.0}, false)
	o.set_meta("etx_obelisk", true)
	o.modulate = Color(0.55, 0.35, 0.85)
	o.enemy_name = L.t("Dark Obelisk")
	o.xp_val = 0.0
	obelisks.append(o)


func alive_obelisks() -> int:
	var n := 0
	for o in obelisks:
		if is_instance_valid(o) and not o.dead:
			n += 1
	return n


func cadence() -> float:
	var c: float = curve(CAD_CURVE, m.run_time / 60.0)
	if phase >= 2:
		c *= 1.1
	if enraged:
		c /= 0.9
	if berserk:
		c *= 1.5
	return c


func _hit(frac: float) -> void:
	if m.player.dead:
		return
	m._hurt_player(m.player.max_hp * frac)


func tick(delta: float) -> void:
	if done:
		return
	if boss == null or not is_instance_valid(boss) or boss.dead:
		stop()
		return
	if m.player.dead:
		return
	t += delta
	var cad: float = cadence()
	var pp: Vector2 = m.player.position
	var dist: float = boss.position.distance_to(pp)
	# casi inmovil: se acerca despacio para no dejarte pelear a rango infinito
	if dist > 260.0 and tail_wind < 0.0 and beam.is_empty():
		boss.position += (pp - boss.position).normalized() * 34.0 * delta
	boss.loop_anim("Idle", 0.8)
	# curacion de los obeliscos
	var heal: float = float(alive_obelisks()) * OBELISK_HEAL * boss.max_hp * delta
	if heal > 0.0 and boss.hp < boss.max_hp:
		boss.hp = minf(boss.max_hp, boss.hp + heal)
	# fases
	var frac: float = boss.hp / maxf(1.0, boss.max_hp)
	if phase == 1 and frac <= PHASE2_AT:
		phase = 2
		m._say(L.t("Eternatus is enraged!"), 3.0)
		m.shake = maxf(m.shake, 12.0)
		Aud.sfx("boss")
	if not enraged and frac <= ENRAGE_AT:
		enraged = true
		m._say(L.t("Eternatus goes into a frenzy!"), 3.0)
		m.shake = maxf(m.shake, 14.0)
	if not berserk and t >= TIME_LIMIT:
		berserk = true
		m._say(L.t("Time's up! Eternatus attacks relentlessly"), 3.5)
	# temporizadores de ataque
	beam_cd -= delta * cad
	cannon_cd -= delta * cad
	ring_cd -= delta * cad
	meteor_cd -= delta * cad
	tail_cd = maxf(0.0, tail_cd - delta)
	if beam.is_empty() and beam_cd <= 0.0:
		_start_beam()
	if cannon_cd <= 0.0:
		cannon_cd = CANNON_EVERY
		_start_cannon(0.0)
		_start_cannon(0.6)
	if ring_cd <= 0.0:
		ring_cd = RING_EVERY
		_start_rings()
	if meteor_cd <= 0.0:
		meteor_cd = METEOR_EVERY
		_start_meteors()
	# cola: si te quedas pegado
	if dist <= TAIL_CLOSE_R:
		close_t += delta
	else:
		close_t = maxf(0.0, close_t - delta)
	if tail_wind >= 0.0:
		tail_wind -= delta
		if tail_wind < 0.0:
			boss.play("Attack", 1.0)
	elif close_t >= TAIL_CLOSE_S and tail_cd <= 0.0:
		_start_tail()
	if doom >= 1:
		well_cd -= delta * cad
		if well.is_empty() and well_cd <= 0.0:
			_start_well()
	if doom >= 3 and alive_obelisks() < 3:
		regen_cd -= delta
		if regen_cd <= 0.0:
			regen_cd = OBELISK_REGEN
			_spawn_obelisk(randf() * TAU)
			m._say(L.t("A Dark Obelisk has returned!"), 2.4)
	_tick_beam(delta, pp)
	_tick_well(delta, pp)
	_tick_cannons(delta, pp)
	_tick_rings(delta, pp)
	_tick_pools(delta, pp)


# ---------- Eternarrayo ----------
func _start_beam() -> void:
	var aim: float = (m.player.position - boss.position).angle()
	beam = {"phase": "charge", "t": 0.0, "aim": aim, "dir": 1.0 if randf() < 0.5 else -1.0, "hit": false, "ang": aim, "origin": boss.position, "double": doom >= 2}
	stats["beams"] += 1
	boss.play("Charge", 1.0)
	Aud.sfx("rift")
	if stats["beams"] == 1:
		m._say(L.t("Take cover! Eternabeam: dodge it with the dash or stay out of the arc"), 3.2)


func _tick_beam(delta: float, pp: Vector2) -> void:
	if beam.is_empty():
		return
	var cad: float = cadence()
	beam["t"] = float(beam["t"]) + delta
	if String(beam["phase"]) == "charge":
		if float(beam["t"]) >= BEAM_CHARGE / cad:
			beam["phase"] = "sweep"
			beam["t"] = 0.0
			Aud.sfx("boss")
			m.shake = maxf(m.shake, 8.0)
		return
	var sweep: float = BEAM_SWEEP / cad
	var k: float = clampf(float(beam["t"]) / sweep, 0.0, 1.0)
	var start_a: float = float(beam["aim"]) - float(beam["dir"]) * PI * 0.5
	beam["ang"] = start_a + float(beam["dir"]) * PI * k
	if not bool(beam["hit"]) and _beam_hits(pp):
		beam["hit"] = true
		_hit(BEAM_DMG)
	if k >= 1.0:
		if bool(beam.get("double", false)):
			# Eternarrayo doble (Doom 2+): tras un aviso corto vuelve a barrer en sentido contrario, desde donde acabo el primero.
			beam = {"phase": "charge", "t": maxf(0.0, BEAM_CHARGE / cad - BEAM2_WARN), "aim": beam["aim"], "dir": -float(beam["dir"]),
				"hit": false, "ang": beam["aim"], "origin": beam["origin"], "double": false}
			Aud.sfx("rift")
			return
		beam = {}
		beam_cd = BEAM_EVERY


func _beam_hits(pp: Vector2) -> bool:
	var origin: Vector2 = beam["origin"]
	var d: Vector2 = Vector2.from_angle(float(beam["ang"]))
	var rel: Vector2 = pp - origin
	var along: float = rel.dot(d)
	if along < 0.0 or along > BEAM_LEN:
		return false
	return absf(-rel.x * d.y + rel.y * d.x) <= BEAM_W * 0.5 + m.player.radius * 0.6


# ---------- Pozo gravitatorio (Doom 1+) ----------
func _start_well() -> void:
	well_cd = WELL_EVERY
	well = {"phase": "charge", "t": 0.0, "hit": false, "origin": boss.position}
	boss.play("Charge", 1.0)
	Aud.sfx("rift")
	m._say(L.t("Gravity Well! Walk away and stay out of the center"), 3.0)


func _tick_well(delta: float, pp: Vector2) -> void:
	if well.is_empty():
		return
	var cad: float = cadence()
	well["t"] = float(well["t"]) + delta
	var origin: Vector2 = well["origin"]
	if String(well["phase"]) == "charge":
		if float(well["t"]) >= WELL_WINDUP / cad:
			well["phase"] = "pull"
			well["t"] = 0.0
			m.shake = maxf(m.shake, 6.0)
		return
	var to: Vector2 = origin - pp
	if to.length() <= WELL_R and to.length() > 4.0:
		var np: Vector2 = pp + to.normalized() * WELL_PULL * delta
		if not m._blocked(np, m.player.radius):
			m.player.position = np
	if float(well["t"]) >= WELL_PULL_T:
		m._ring(origin, 4.0, WELL_CORE, COL_RING, 0.4)
		m.shake = maxf(m.shake, 6.0)
		if pp.distance_to(origin) <= WELL_CORE + m.player.radius * 0.6:
			_hit(WELL_DMG)
		well = {}


# ---------- Canon ----------
func _start_cannon(delay: float) -> void:
	cannons.append({"pos": m.player.position, "t": -delay, "hit": false})
	stats["cannons"] += 1


func _tick_cannons(delta: float, pp: Vector2) -> void:
	for i in range(cannons.size() - 1, -1, -1):
		var c: Dictionary = cannons[i]
		c["t"] = float(c["t"]) + delta
		var ct: float = float(c["t"])
		if ct < 0.0:
			c["pos"] = pp
			continue
		if ct < CANNON_TRACK:
			c["pos"] = (c["pos"] as Vector2).move_toward(pp, 300.0 * delta)
		if ct >= CANNON_TRACK + CANNON_LOCK and not bool(c["hit"]):
			c["hit"] = true
			m._ring(c["pos"], 4.0, CANNON_R, COL_CANNON, 0.4)
			m.shake = maxf(m.shake, 4.0)
			if pp.distance_to(c["pos"]) < CANNON_R + m.player.radius * 0.6:
				_hit(CANNON_DMG)
			if randf() < CANNON_BEAM_CHANCE and beam.is_empty() and beam_cd > 6.0:
				beam_cd = 0.5   # el canon puede encadenar un Eternarrayo
		if ct >= CANNON_TRACK + CANNON_LOCK + 0.3:
			cannons.remove_at(i)


# ---------- Anillos ----------
func _start_rings() -> void:
	boss.play("Charge", 1.0)
	var n: int = RING_COUNT + (1 if phase >= 2 else 0)
	for i in range(n):
		ring_queue.append(RING_WINDUP + float(i) * RING_GAP)
	Aud.sfx("rift")


func _tick_rings(delta: float, pp: Vector2) -> void:
	for i in range(ring_queue.size() - 1, -1, -1):
		ring_queue[i] = float(ring_queue[i]) - delta
		if float(ring_queue[i]) <= 0.0:
			ring_queue.remove_at(i)
			var gaps: Array = []
			var ng: int = 2 if randf() < 0.5 else 3
			var base: float = randf() * TAU
			for g in range(ng):
				gaps.append(base + TAU * float(g) / float(ng) + randf_range(-0.3, 0.3))
			rings.append({"r": 30.0, "gaps": gaps, "hit": false, "origin": boss.position})
			stats["rings"] += 1
			Aud.sfx("surge")
	for i in range(rings.size() - 1, -1, -1):
		var r: Dictionary = rings[i]
		r["r"] = float(r["r"]) + RING_SPEED * delta
		if not bool(r["hit"]):
			var rel: Vector2 = pp - (r["origin"] as Vector2)
			var d: float = rel.length()
			if absf(d - float(r["r"])) <= RING_THICK * 0.5 + m.player.radius * 0.5:
				r["hit"] = true
				var a: float = rel.angle()
				var in_gap := false
				for g in r["gaps"]:
					if absf(angle_difference(a, float(g))) <= deg_to_rad(RING_GAP_DEG) * 0.5:
						in_gap = true
				if not in_gap:
					_hit(RING_DMG)
		if float(r["r"]) > 1100.0:
			rings.remove_at(i)


# ---------- Cola ----------
func _start_tail() -> void:
	tail_cd = TAIL_CD
	close_t = 0.0
	tail_wind = TAIL_WINDUP
	stats["tails"] += 1
	boss.play("Charge", 1.2)
	var h = m._hazard_zone(boss.position, TAIL_R, TAIL_WINDUP, 0.0, "dark", Color("#7a3bd0"))
	h.pct = TAIL_DMG


# ---------- Meteoros ----------
func _start_meteors() -> void:
	var n: int = randi_range(5, 8) + (2 if phase >= 2 else 0)
	var pp: Vector2 = m.player.position
	for i in range(n):
		var off: Vector2 = Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(20.0, METEOR_SPREAD)
		var pos: Vector2 = pp + off
		var h = m._hazard_zone(pos, METEOR_R, METEOR_DELAY + float(i) * 0.1, 0.0, "rock", COL_BEAM)
		h.pct = METEOR_DMG
		pools.append({"pos": pos, "delay": METEOR_DELAY + float(i) * 0.1, "t": 0.0, "tick": 0.0})
		stats["meteors"] += 1
	Aud.sfx("boss")


func _tick_pools(delta: float, pp: Vector2) -> void:
	for i in range(pools.size() - 1, -1, -1):
		var p: Dictionary = pools[i]
		p["t"] = float(p["t"]) + delta
		var life: float = float(p["t"]) - float(p["delay"])
		if life < 0.0:
			continue
		p["tick"] = float(p["tick"]) - delta
		if float(p["tick"]) <= 0.0:
			p["tick"] = POOL_TICK
			if pp.distance_to(p["pos"]) < METEOR_R + m.player.radius * 0.6:
				_hit(POOL_DMG)
		if life >= POOL_LIFE:
			pools.remove_at(i)


# ---------- dibujo ----------
func _squash(n: Node2D, c: Vector2) -> void:
	n.draw_set_transform(c, 0.0, Vector2(1.0, 0.8))


func draw_on(n: Node2D) -> void:
	if done or boss == null or not is_instance_valid(boss):
		return
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	# cables de los obeliscos
	for o in obelisks:
		if is_instance_valid(o) and not o.dead:
			n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var a: Vector2 = o.position + Vector2(0.0, -o.body_h * 0.5)
			var b: Vector2 = boss.position + Vector2(0.0, -boss.body_h * 0.5)
			n.draw_line(a, b, Color(0.7, 0.4, 1.0, 0.25 + 0.2 * pulse), 3.0)
	# charcos
	for p in pools:
		var life: float = float(p["t"]) - float(p["delay"])
		if life >= 0.0:
			_squash(n, p["pos"])
			var k: float = 1.0 - clampf(life / POOL_LIFE, 0.0, 1.0)
			n.draw_circle(Vector2.ZERO, METEOR_R, Color(COL_POOL.r, COL_POOL.g, COL_POOL.b, 0.35 * (0.5 + 0.5 * k)))
			n.draw_arc(Vector2.ZERO, METEOR_R, 0.0, TAU, 32, Color(0.8, 0.5, 1.0, 0.6), 2.0)
	# anillos
	for r in rings:
		_squash(n, r["origin"])
		var rad: float = float(r["r"])
		var gaps: Array = r["gaps"]
		var segs := 96
		for s in range(segs):
			var a0: float = TAU * float(s) / float(segs)
			var a1: float = TAU * float(s + 1) / float(segs)
			var mid: float = (a0 + a1) * 0.5
			var in_gap := false
			for g in gaps:
				if absf(angle_difference(mid, float(g))) <= deg_to_rad(RING_GAP_DEG) * 0.5:
					in_gap = true
			if not in_gap:
				n.draw_arc(Vector2.ZERO, rad, a0, a1 + 0.02, 3, Color(COL_RING.r, COL_RING.g, COL_RING.b, 0.9), RING_THICK * 0.6)
	# pozo gravitatorio
	if not well.is_empty():
		_squash(n, well["origin"])
		var pulling: bool = String(well["phase"]) == "pull"
		var wk: float = clampf(float(well["t"]) / WELL_PULL_T, 0.0, 1.0) if pulling else 0.0
		n.draw_circle(Vector2.ZERO, WELL_R, Color(COL_POOL.r, COL_POOL.g, COL_POOL.b, 0.05 + 0.05 * pulse))
		n.draw_arc(Vector2.ZERO, WELL_R * (1.0 - 0.15 * wk), 0.0, TAU, 64, Color(0.8, 0.5, 1.0, 0.5 if pulling else 0.25), 3.0)
		n.draw_circle(Vector2.ZERO, WELL_CORE, Color(1.0, 0.3, 0.45, 0.15 + 0.2 * wk))
		n.draw_arc(Vector2.ZERO, WELL_CORE, 0.0, TAU, 32, Color(1.0, 0.4, 0.55, 0.9), 3.0)
	# canones
	for c in cannons:
		var ct: float = float(c["t"])
		if ct < 0.0:
			continue
		_squash(n, c["pos"])
		var locked: bool = ct >= CANNON_TRACK
		var col: Color = COL_CANNON if not locked else Color("#ff3b30")
		n.draw_circle(Vector2.ZERO, CANNON_R, Color(col.r, col.g, col.b, 0.14 + 0.1 * pulse))
		n.draw_arc(Vector2.ZERO, CANNON_R, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.9), 3.0)
		var fill: float = clampf((ct - CANNON_TRACK) / CANNON_LOCK, 0.0, 1.0) if locked else 0.0
		n.draw_circle(Vector2.ZERO, CANNON_R * fill, Color(col.r, col.g, col.b, 0.4))
	# rayo
	if not beam.is_empty():
		n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var origin: Vector2 = beam["origin"] + Vector2(0.0, -boss.body_h * 0.4)
		var aim: float = float(beam["aim"])
		if String(beam["phase"]) == "charge":
			var pts := PackedVector2Array([origin])
			for s in range(25):
				pts.append(origin + Vector2.from_angle(aim - PI * 0.5 + PI * float(s) / 24.0) * BEAM_LEN)
			n.draw_colored_polygon(pts, Color(COL_BEAM.r, COL_BEAM.g, COL_BEAM.b, 0.08 + 0.1 * pulse))
			n.draw_line(origin, origin + Vector2.from_angle(aim - PI * 0.5) * BEAM_LEN, Color(1, 0.4, 0.8, 0.7), 2.0)
			n.draw_line(origin, origin + Vector2.from_angle(aim + PI * 0.5) * BEAM_LEN, Color(1, 0.4, 0.8, 0.7), 2.0)
		else:
			var d: Vector2 = Vector2.from_angle(float(beam["ang"]))
			n.draw_line(origin, origin + d * BEAM_LEN, Color(COL_BEAM.r, COL_BEAM.g, COL_BEAM.b, 0.45), BEAM_W * 1.4)
			n.draw_line(origin, origin + d * BEAM_LEN, Color(1.0, 0.85, 1.0, 0.95), BEAM_W * 0.55)
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func stop() -> void:
	if done:
		return
	done = true
	beam = {}
	well = {}
	cannons.clear()
	rings.clear()
	ring_queue.clear()
	pools.clear()
	for o in obelisks:
		if is_instance_valid(o):
			m.enemies.erase(o)
			o.queue_free()
	obelisks.clear()
	if fxn != null and is_instance_valid(fxn):
		fxn.queue_free()
	fxn = null
