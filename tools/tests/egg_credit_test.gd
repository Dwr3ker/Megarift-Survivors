extends SceneTree
# Eggs step 23: at run end every incubated egg gains exactly the run's distance; eggs outside the incubator and eggs found
# in this run don't; progress stops at the egg's need; eggs that just became ready are listed.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var EG = load("res://scripts/eggs.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var a: Dictionary = EG.make(1, 1, "grass")      # 1000 m
	var b: Dictionary = EG.make(4, 3, "fire")       # 2500 m
	var c: Dictionary = EG.make(7, 2, "water")      # 1500 m, started
	var d: Dictionary = EG.make(10, 1, "bug")       # outside the incubator
	c["steps"] = 1200.0
	for e in [a, b, c, d]:
		EG.add(e)
	EG.place(int(d["id"]), -1)
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(20):
		await process_frame
	m.player.invuln = 1.0e9
	m.run_meters = 437.25
	var o = m._egg_try("boss", m.player.position, true)   # an egg found in this run
	for i in range(3):
		await process_frame
	m._finish_run()
	check("slot 1 egg gained exactly the run's distance", is_equal_approx(float(EG.by_id(int(a["id"]))["steps"]), 437.25), str(EG.by_id(int(a["id"]))["steps"]))
	check("slot 2 egg too", is_equal_approx(float(EG.by_id(int(b["id"]))["steps"]), 437.25))
	check("a started egg stops at its need (1500 m)", is_equal_approx(float(EG.by_id(int(c["id"]))["steps"]), 1500.0), str(EG.by_id(int(c["id"]))["steps"]))
	check("an egg outside the incubator gains nothing", float(EG.by_id(int(d["id"]))["steps"]) == 0.0)
	check("the egg that became ready is listed", m.eggs_hatchable.size() == 1 and int(m.eggs_hatchable[0]["id"]) == int(c["id"]))
	var newest: Dictionary = EG.eggs()[EG.count() - 1]
	check("this run's new egg is in the bag with no progress", EG.count() == 5 and float(newest["steps"]) == 0.0 and int(newest["slot"]) == -1,
		"slot %d (incubator full)" % int(newest["slot"]))
	check("the ready egg reads as ready", EG.is_ready(EG.by_id(int(c["id"]))) and EG.ready_eggs().size() == 1)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
