extends SceneTree
# Headless check that a saved run keeps the permanent upgrades it was saved with: leaving the run, buying upgrades and resuming
# does not give the run the new upgrades. Also: the rarity Poké Ball on the Pokémon page.
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
	for i in range(14):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	m.jd.done = true
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var RS = load("res://scripts/run_save.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.d["pup"]["6"] = {"hp": 2, "atk": 1}
	var had_real: bool = RS.exists()
	var real_text: String = FileAccess.get_file_as_string(RS.PATH) if had_real else ""
	RS.clear()
	var m = await _new_run(SV, 6)
	var perks0: Dictionary = m.perks.duplicate()
	check("the run starts with the Pokémon's upgrades", float(perks0["hp"]) == 16.0 and absf(float(perks0["atk"]) - 1.04) < 0.001, str(perks0["hp"]))
	check("a run can be saved", RS.save(m), RS.block_reason(m))
	var snap: Dictionary = RS.load_snap()
	check("the saved run remembers its upgrades", snap.has("pup") and int(snap["pup"]["hp"]) == 2)
	m.queue_free()
	await process_frame
	# ---------- leave the run, buy upgrades ----------
	SV.d["coins"] = 99999999
	for i in range(5):
		SV.buy_upgrade("hp", 6)
		SV.buy_upgrade("atk", 6)
		SV.buy_upgrade("spd", 6)
	check("setup: the upgrades were bought", SV.up_level("hp", 6) > 2 and SV.up_level("spd", 6) > 0, str(SV.d["pup"]["6"]))
	# ---------- resume ----------
	SV.resume_snap = snap
	SV.pin_run(snap)   # what the menu does when you press Resume run
	var m2 = await _new_run(SV, int(snap["dex"]))
	check("the resumed run keeps the OLD upgrades (no new HP, damage or speed)", float(m2.perks["hp"]) == float(perks0["hp"]) and float(m2.perks["atk"]) == float(perks0["atk"]) and float(m2.perks["spd"]) == float(perks0["spd"]), "hp %.0f atk %.2f spd %.2f" % [m2.perks["hp"], m2.perks["atk"], m2.perks["spd"]])
	check("the real upgrades are untouched in the save", int(SV.d["pup"]["6"]["hp"]) > 2, str(SV.d["pup"]["6"]))
	m2.queue_free()
	await process_frame
	# ---------- back on the menu the pin is gone ----------
	SV.pin_clear()
	var m3 = await _new_run(SV, 6)
	check("a fresh run gets the new upgrades", float(m3.perks["hp"]) > float(perks0["hp"]) and float(m3.perks["spd"]) > float(perks0["spd"]))
	m3.queue_free()
	await process_frame
	SV.resume_snap = snap
	SV.pin_run(snap)
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	check("opening the menu clears the pin", SV.pin_dex == -1)
	menu.queue_free()
	await process_frame
	# ---------- an older saved run (no upgrades stored) just uses the current ones ----------
	var old: Dictionary = snap.duplicate(true)
	old.erase("pup")
	SV.pin_run(old)
	check("a run saved by an older version pins nothing", SV.pin_dex == -1)
	# ---------- balance settings are pinned too ----------
	SV.d["settings"]["mono_bonus"] = false
	SV.d["settings"]["adaptive"] = true
	var s2: Dictionary = snap.duplicate(true)
	s2["set"] = {"adaptive": false, "mono_bonus": true}
	SV.pin_run(s2)
	check("the saved run's adaptive and mono-type settings win over the current ones", bool(SV.run_setting("mono_bonus", false)) and not bool(SV.run_setting("adaptive", true)))
	SV.pin_clear()
	check("without a pin the current settings apply", not bool(SV.run_setting("mono_bonus", false)) and bool(SV.run_setting("adaptive", true)))
	# ---------- rarity ball ----------
	var menu2 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu2)
	for i in range(20):
		await process_frame
	var ok_balls := true
	for rar in range(1, 6):
		if String(menu2.RARITY_BALL[rar - 1]) == "":
			ok_balls = false
	check("every rarity has its own ball", ok_balls and menu2.RARITY_BALL.size() == 5 and menu2.RARITY_BALL[0] != menu2.RARITY_BALL[4])
	menu2.queue_free()
	await process_frame
	RS.clear()
	if had_real:
		var rf := FileAccess.open(RS.PATH, FileAccess.WRITE)
		rf.store_string(real_text)
		rf.close()
	SV.pin_clear()
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
