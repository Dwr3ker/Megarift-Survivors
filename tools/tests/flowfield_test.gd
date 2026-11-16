extends SceneTree
# Paths around walls (scripts/flowfield.gd): an enemy behind a wall walks around it and reaches you (without the field
# it stays stuck), the straight line is used when nothing is in the way, an enemy lost off-screen goes back to the spawn
# ring, your co-op partner also walks around, and building the field is cheap.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var m

# A clean floor around you with a wall 4 tiles to your right, 15 tiles tall (a U-shape opening away from the enemy).
func lay_wall(pt: Vector2i) -> void:
	for dy in range(-14, 15):
		for dx in range(-14, 15):
			m.ground.terr[Vector2i(pt.x + dx, pt.y + dy)] = 0
	for dy in range(-7, 8):
		m.ground.terr[Vector2i(pt.x + 4, pt.y + dy)] = 1
	for dx in range(4, 9):   # arms of the U toward the enemy's side, so walking straight jams it in the corner
		m.ground.terr[Vector2i(pt.x + dx, pt.y - 7)] = 1
		m.ground.terr[Vector2i(pt.x + dx, pt.y + 7)] = 1

func chase(e, secs: float, use_flow: bool) -> float:
	var keep = m.flow
	if not use_flow:
		m.flow = null
	var best := INF
	var t := 0.0
	while t < secs:
		var dt := 1.0 / 30.0
		m._update_enemies(dt)
		if use_flow:
			m.flow.update(dt)
		best = minf(best, e.position.distance_to(m.player.position))
		if use_flow and OS.has_environment("TRACE") and int(t * 30.0) % 30 == 0:
			var et: Vector2i = m.ground.tile_of(e.position) - m.ground.tile_of(m.player.position)
			print("  t %.0f  tile %s  steps %d  dir %s" % [t, str(et), m.flow.steps_at(m.ground.tile_of(e.position)), str(m.flow.dir_for(e.position))])
		t += dt
		if best < 70.0:
			break
	m.flow = keep
	return best

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["owned"]["25"] = {"n": 1, "shiny": false}
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.set_process(false)
	m.player.invuln = 1.0e9
	for e in m.enemies:
		e.queue_free()
	m.enemies.clear()
	var TS: float = 48.0
	m.player.position = Vector2(TS * 0.5, TS * 0.5) + Vector2(TS * 40.0, TS * 40.0)
	var pt: Vector2i = m.ground.tile_of(m.player.position)
	lay_wall(pt)
	var t0: int = Time.get_ticks_usec()
	m.flow.build(pt)
	var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	t0 = Time.get_ticks_usec()
	m.flow.build(pt)
	var ms2: float = (Time.get_ticks_usec() - t0) / 1000.0
	check("building the field is cheap (under 15 ms once the map is known)", ms2 < 15.0, "first %.1f ms, then %.1f ms" % [ms, ms2])
	# straight line: nothing in the way
	check("an open straight line is walked directly", m.flow.dir_for(m.player.position + Vector2(-5.0 * TS, 0.0)) == Vector2.ZERO)
	# behind the wall
	var behind: Vector2 = m.player.position + Vector2(6.0 * TS, 0.0)
	var d: Vector2 = m.flow.dir_for(behind)
	check("behind the wall it heads for the way round (up or down, not into the wall)", d != Vector2.ZERO and absf(d.y) > absf(d.x) * 0.5 and d.x >= -0.2, str(d))
	var def: Dictionary = {"dex": 19, "name": "Rattata", "behavior": "chase", "hp": 1.0e9, "spd": 90.0, "dmg": 0.0, "xp": 1.0}
	var e = m._make_enemy(def, behind, {"hp": 1.0, "dmg": 1.0, "spd": 1.0})
	e.dif_done = true
	var stuck: float = chase(e, 12.0, false)
	check("without the field it stays stuck behind the wall", stuck > 3.5 * TS, "closest %.0f px" % stuck)
	e.position = behind
	e.knock = Vector2.ZERO
	var got: float = chase(e, 20.0, true)
	check("with it, it walks around and reaches you", got < 70.0, "closest %.0f px" % got)
	e.queue_free()
	m.enemies.erase(e)
	# lost off-screen: back to the spawn ring
	var far: Vector2 = m.player.position + Vector2(30.0 * TS, 0.0)
	var e2 = m._make_enemy(def, far, {"hp": 1.0, "dmg": 1.0, "spd": 1.0})
	e2.best_d = e2.position.distance_to(m.player.position)
	e2.stuck_t = m.STUCK_T - 0.01
	m._stuck_check(e2, e2.best_d, 0.1)
	var nd: float = e2.position.distance_to(m.player.position)
	check("an enemy lost off-screen for 6 s goes back to the spawn ring", nd < 30.0 * TS - 200.0 and e2.stuck_t == 0.0, "%.0f px" % nd)
	e2.stuck_t = 0.0
	e2.best_d = 300.0
	var p0: Vector2 = e2.position
	m._stuck_check(e2, 290.0, 7.0)
	check("one that is still getting closer is left alone", e2.position == p0)
	# co-op partner
	var pd: Vector2 = m.flow.dir_for(behind)
	check("your co-op partner uses the same way round", pd == d)
	m.queue_free()
	for i in range(3):
		await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
