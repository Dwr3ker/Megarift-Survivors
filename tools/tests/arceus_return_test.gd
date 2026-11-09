extends SceneTree
# After defeating Arceus you return to where you stood, next to the enemies that were waiting, and new ones can spawn.
# Before this, the return point was inside the arena: you landed far from the map with the waiting enemies filling the cap.
# Also: every region map can open a Mega rift, and the Arceus banner no longer says he is invincible.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _run(dex: int, region: int):
	var SV = load("res://scripts/save_data.gd")
	SV.d = SV.default_data()
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_region = region
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	m.player.invuln = 1.0e9
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map"]:
		m.dir_done[id] = true
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var MG = load("res://scripts/mega.gd")
	SV.ensure()
	SV.load_dex()
	var src: String = FileAccess.get_file_as_string("res://scripts/judgment.gd")
	check("the Arceus banner no longer says he is invincible", not src.contains("He is invincible"))
	var m = await _run(6, 0)
	m.run_time = 1700.0
	while m.enemies.size() < m._cap():   # a full map, as in a real run at minute 30
		m._spawn_one()
	m.run_time = 1799.0
	m.player.position += Vector2(300, -200)
	var before: Vector2 = m.player.position
	var g := 0
	while m.jd.phase != "fight" and g < 20000:
		g += 1
		await process_frame
	check("the fight remembers where you stood", (m.ainfo["back"] as Vector2).distance_to(before) < 40.0, str(m.ainfo["back"]))
	for i in range(30):
		await process_frame
	m.jd.A.hp = 1.0
	m._damage_enemy(m.jd.A, 100.0, Color.WHITE)
	g = 0
	while m.jd.active() and g < 20000:
		g += 1
		await process_frame
	check("defeating Arceus clears the region", m.arceus_beaten and m.arena == null)
	check("you return to where you stood", m.player.position.distance_to(before) < 120.0, "%.0f px away" % m.player.position.distance_to(before))
	var near := 0
	for e in m.enemies:
		if is_instance_valid(e) and not e.dead and e.position.distance_to(m.player.position) < 1500.0:
			near += 1
	check("the waiting enemies are around you, not out of reach", near > 40, "%d near" % near)
	m.queue_free()
	await process_frame
	# Mega rifts on the regions with no Mega-capable legendary
	for rg in [2, 5, 9]:
		var r = await _run(6, rg)
		var all_ok := true
		for i in range(12):
			if not MG.is_capable(int(r._pick_legend(true).get("dex", 0))):
				all_ok = false
		check("region %d can open Mega rifts" % rg, all_ok)
		r.run_time = 1250.0
		for tries in range(8):   # a Dynamax den (5% a check) can open instead: close it and check again
			r.rift_check = 0.0
			r._update_rift(0.01)
			if r.rift == null or not bool(r.rift_info.get("den", false)):
				break
			r.rift.queue_free()
			r.rift = null
			r._rift_drop_arena()
		check("region %d: the Mega Stone rift opens at minute 20" % rg, r.rift != null and bool(r.rift_info.get("stone", false)) and r.stone_tried)
		r.queue_free()
		await process_frame
	SV.run_region = 0
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
