extends SceneTree
# Headless check of the mid-run save: what is stored, what blocks it, the round trip into a fresh run, and the menu button.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _new_run(SV, dex: int):
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(12):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true   # keep the director out of the hand-driven checks
	m.rift_check = 1.0e9
	m.jd.done = true
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var RS = load("res://scripts/run_save.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	# keep a real saved run (if the player has one) safe while the test uses the same file
	var had_real: bool = RS.exists()
	var real_text: String = FileAccess.get_file_as_string(RS.PATH) if had_real else ""
	RS.clear()
	# ---------- build a run with some progress ----------
	var m = await _new_run(SV, 6)
	check("no saved run to start with", not RS.exists() and RS.load_snap().is_empty())
	m.run_time = 900.0
	m.kills = 321
	m.coins = 777
	m.tickets = 5
	m.tickets10 = 2
	m.player.level = 14
	m.player.xp = 33.0
	m.player.xp_next = 99.0
	m.stat_lv["atk"] = 3.5
	m.stat_lv["spd"] = 2.0
	m.player.max_hp = 300.0
	m.player.hp = 123.0
	m.player.position = Vector2(1500.0, -800.0)
	m.item = "leftovers"
	m.rerolls = 4
	m.revives = 2
	m.run_bosses = 3
	m.eter_kills = 1
	m.eter_at = 5400.0
	m.dir_done["rift"] = true
	m.boss_idx = 5   # at 15:00 every scheduled boss has already come (a lower number would make them all appear at once)
	m.biome_idx = 1
	m.dir_map = true
	var extra: Dictionary = m._new_move("ice-beam", 3)
	m.player.moves.append(extra)
	m._arrange()
	var n_moves: int = m.player.moves.size()
	m.player.moves[0]["lvl"] = 4
	var seed0: int = m.world_seed
	# ---------- what blocks a save ----------
	check("a quiet moment can be saved", RS.block_reason(m) == "")
	m.mode = "rush"
	check("only Normal runs can be saved", RS.block_reason(m) != "")
	m.mode = "normal"
	m.dir_finale = true
	check("a boss fight blocks the save", RS.block_reason(m) != "")
	m.dir_finale = false
	m.choosing = true
	check("an open card screen blocks the save", RS.block_reason(m) != "")
	m.choosing = false
	# ---------- save ----------
	var snap: Dictionary = RS.capture(m)
	check("the snapshot is plain data (no objects)", RS.plain(snap))
	check("saving writes the file", RS.save(m) and RS.exists())
	var back: Dictionary = RS.load_snap()
	check("the file reads back as the same snapshot", not back.is_empty() and float(back["f"]["run_time"]) == 900.0 and int(back["p"]["level"]) == 14 and (back["p"]["moves"] as Array).size() == n_moves)
	var desc: String = RS.describe(back)
	check("the description shows the Pokémon, the clock and the level", desc.contains("15:00") and desc.contains("14"), desc)
	m.queue_free()
	await process_frame
	# ---------- resume into a fresh run ----------
	SV.resume_snap = back
	var m2 = await _new_run(SV, int(back["dex"]))
	check("the resume hand-off is consumed", SV.resume_snap.is_empty() and m2.resumed)
	check("clock, kills, coins and tickets come back", m2.run_time >= 900.0 and m2.run_time < 902.0 and m2.kills == 321 and m2.coins == 777 and m2.tickets == 5 and m2.tickets10 == 2, "%.1f %d %d" % [m2.run_time, m2.kills, m2.coins])
	check("level, XP and HP come back", m2.player.level == 14 and absf(m2.player.xp - 33.0) < 1.0 and m2.player.max_hp == 300.0 and absf(m2.player.hp - 123.0) < 12.0, "lv %d hp %.0f/%.0f" % [m2.player.level, m2.player.hp, m2.player.max_hp])
	check("stat upgrades come back", m2._lvf("atk") == 3.5 and m2._lvf("spd") == 2.0)
	check("every move and its level come back", m2.player.moves.size() == n_moves and int(m2.player.moves[0]["lvl"]) == 4)
	check("item, rerolls and revives come back", m2.item == "leftovers" and m2.rerolls == 4 and m2.revives == 2)
	check("Doom level and the boss schedule come back", m2.eter_kills == 1 and m2.eter_at == 5400.0 and m2.boss_idx == 5 and bool(m2.dir_done.get("rift", false)))
	check("the map comes back", m2.world_seed == seed0 and m2.biome_idx == 1, "seed %d vs %d, biome %d" % [m2.world_seed, seed0, m2.biome_idx])
	check("the player stands where they were", m2.player.position.distance_to(Vector2(1500.0, -800.0)) < 2.0, str(m2.player.position))
	check("a short grace period after resuming", m2.player.invuln > 1.0)
	for i in range(30):
		await process_frame
	check("the resumed run keeps running", m2.run_time > 900.0 and not m2.player.dead)
	# ---------- Mega state ----------
	m2._mega_start()
	await process_frame
	var mega_hp: float = m2.player.max_hp
	check("setup: a Mega Charizard", m2._mega_on() and m2.player.types.size() > 0)
	m2.player.hp = mega_hp * 0.5
	check("a Mega run can be saved", RS.save(m2), RS.block_reason(m2))
	var mb: Dictionary = RS.load_snap()
	m2.queue_free()
	await process_frame
	SV.resume_snap = mb
	var m3 = await _new_run(SV, int(mb["dex"]))
	check("Mega Evolution is back with the same HP (not applied twice)", m3._mega_on() and absf(m3.player.max_hp - mega_hp) < 0.5 and absf(m3.player.hp - mega_hp * 0.5) < 12.0, "%.0f / %.0f" % [m3.player.hp, m3.player.max_hp])
	# ---------- ending the resumed run clears the save ----------
	m3._finish_run()
	check("finishing a resumed run removes the saved run", not RS.exists())
	m3.queue_free()
	await process_frame
	# ---------- the menu button ----------
	RS.save(m2) if false else null
	var f := FileAccess.open(RS.PATH, FileAccess.WRITE)
	f.store_string(var_to_str(mb))
	f.close()
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._refresh_main()
	check("the main menu shows Resume run with the details", menu.resume_btn.visible and menu.resume_btn.text.contains("Resume") and menu.resume_btn.text.contains("Lv"), menu.resume_btn.text)
	RS.clear()
	menu._refresh_main()
	check("no saved run: no Resume button", not menu.resume_btn.visible)
	# a damaged file is ignored and cleaned up
	var f2 := FileAccess.open(RS.PATH, FileAccess.WRITE)
	f2.store_string("this is not a saved run")
	f2.close()
	check("a damaged save reads as empty", RS.load_snap().is_empty())
	menu._resume_run()
	check("resuming a damaged save does nothing and clears it", not RS.exists() and SV.resume_snap.is_empty())
	menu.queue_free()
	await process_frame
	# ---------- restore what the player had ----------
	RS.clear()
	if had_real:
		var rf := FileAccess.open(RS.PATH, FileAccess.WRITE)
		rf.store_string(real_text)
		rf.close()
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
