extends SceneTree
# Max pull is capped at 100 pulls: 10 batches of x10 with gold tickets, or 10 purple tickets. The rest of the tickets stay.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.load_dex()
	SV.d = SV.default_data()
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	menu.gacha_region = 1
	menu._show("gacha")
	await process_frame
	SV.d["tickets"] = 340
	var p0: int = int(SV.d["stats"]["pulls"])
	menu._do_max_pull("t1")
	check("Max pull with 340 gold tickets does 100 pulls", int(SV.d["stats"]["pulls"]) - p0 == 100, str(int(SV.d["stats"]["pulls"]) - p0))
	check("and keeps the other 240 tickets (achievements may add a few more)", int(SV.d["tickets"]) >= 240, str(SV.d["tickets"]))
	SV.d["tickets10"] = 25
	var p1: int = int(SV.d["stats"]["pulls"])
	menu._do_max_pull("t10")
	check("Max purple uses at most 10 purple tickets (100 pulls)", int(SV.d["tickets10"]) >= 15 and int(SV.d["stats"]["pulls"]) - p1 == 100, "%d left" % int(SV.d["tickets10"]))
	SV.d["tickets"] = 37
	var p2: int = int(SV.d["stats"]["pulls"])
	menu._do_max_pull("t1")
	check("below the cap it still spends every full batch", int(SV.d["stats"]["pulls"]) - p2 == 30 and int(SV.d["tickets"]) >= 7)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
