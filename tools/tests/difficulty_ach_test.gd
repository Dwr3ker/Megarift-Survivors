extends SceneTree
# Difficulty step 41: the Hard and Nightmare achievements, earned through real run ends.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _end_run(SV, diff: String, minutes: float, arceus: bool = false, eter: int = 0) -> void:
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = diff
	SV.run_region = 0
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(15):
		await process_frame
	m.player.invuln = 1.0e9
	m.run_time = minutes * 60.0
	m.arceus_beaten = arceus
	m.eter_kills = eter
	m._finish_run()
	m.queue_free()
	for i in range(3):
		await process_frame

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var DIF = load("res://scripts/difficulty.gd")
	SV.ensure()
	SV.d = SV.default_data()
	var ach = func(): return SV.d.get("ach", {})
	await _end_run(SV, "normal", 40.0)
	check("a Normal run earns none of them", not ach.call().has("hard15") and not ach.call().has("hard30"))
	await _end_run(SV, "hard", 16.0)
	check("Hard as nails: minute 15 on Hard", ach.call().has("hard15") and not ach.call().has("hard30"))
	check("Nightmare still locked", not DIF.unlocked("nightmare"))
	await _end_run(SV, "hard", 31.0)
	check("Unbreakable: minute 30 on Hard", ach.call().has("hard30"))
	check("...and Nightmare unlocks", DIF.unlocked("nightmare"))
	await _end_run(SV, "nightmare", 15.5)
	check("Sweet dreams: minute 15 on Nightmare", ach.call().has("night15") and not ach.call().has("nightArceus"))
	await _end_run(SV, "nightmare", 31.0, true)
	check("Nightmare slayer: Arceus on Nightmare", ach.call().has("nightArceus") and not ach.call().has("nightEter"))
	await _end_run(SV, "nightmare", 61.0, true, 1)
	check("Wide awake: Eternatus on Nightmare", ach.call().has("nightEter"))
	check("it gives the title Nightmare", load("res://scripts/progress.gd").titles().has("Nightmare"))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
