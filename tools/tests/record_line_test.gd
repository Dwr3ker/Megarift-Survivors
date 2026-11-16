extends SceneTree
# Small features step 64: the "New record!" line on the run summary. A time record per mode and difficulty (per type
# in Survival, Hyper apart); the first run of a mode sets it quietly; old saves keep their Classic record; the line
# names the mode, the difficulty and the old best.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var SV

func run(mode: String, secs: int, diff: String = "normal", hyper: bool = false, sub: String = "") -> Dictionary:
	return SV.finish_run({"time": secs, "kills": 10, "level": 5, "bosses": 0, "chests": 0, "coins": 0, "tickets": 0,
		"mode": mode, "sub": sub, "diff": diff, "hyper": hyper, "dex": 25}).duplicate()

func _init() -> void:
	Engine.set_meta("no_save", true)
	SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	check("the first Classic run sets the record quietly", not run("normal", 300)["record"])
	var r: Dictionary = run("normal", 400)
	check("beating it shows the line", r["record"] and int(r["rec_prev"]) == 300)
	check("a slower run doesn't", not run("normal", 350)["record"])
	check("Hard keeps its own record (first Hard run: quiet)", not run("normal", 200, "hard")["record"])
	check("then Hard beats Hard's record, not Classic's", run("normal", 250, "hard")["record"])
	var h_first: bool = run("normal", 900, "normal", true)["record"]
	var after: Dictionary = run("normal", 800)
	check("Hyper keeps its own record too (a 15:00 Hyper run doesn't raise Classic's 6:40)", not h_first and after["record"] and int(after["rec_prev"]) == 400, str(after["rec_prev"]))
	check("a Team run doesn't beat the Classic record", not run("team", 1000)["record"])
	var t: Dictionary = run("team", 1100)
	check("it beats the Team record", t["record"] and int(t["rec_prev"]) == 1000)
	check("Survival keeps one record per type", not run("type", 300, "normal", false, "fire")["record"] and not run("type", 400, "normal", false, "water")["record"] and run("type", 350, "normal", false, "fire")["record"])
	check("Tower, Boss Rush, Rift Time Attack and Daily use their own lines", not run("tower", 5000)["record"] and not run("rush", 5000)["record"] and not run("rifts", 5000)["record"] and not run("daily", 5000)["record"])
	# old save: only the shared record
	SV.d = SV.default_data()
	SV.d["stats"]["runs"] = 12
	SV.d["stats"]["best_time"] = 900
	SV.d["stats"]["best_hard"] = 600
	check("an old save's Classic record still counts", not run("normal", 850)["record"] and run("normal", 950)["record"])
	check("and its Hard record", not run("normal", 500, "hard")["record"] and int(run("normal", 610, "hard")["rec_prev"]) == 600)
	# the line itself
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(10):
		await process_frame
	var ln: String = menu._record_line({"mode": "team", "diff": "hard", "hyper": false, "time": 754, "rec_prev": 602})
	check("the line names the mode, difficulty, time and old best", ln == "New record! Team Mode · Hard: 12:34 (best was 10:02)", ln)
	ln = menu._record_line({"mode": "type", "sub": "fire", "diff": "normal", "hyper": true, "time": 61, "rec_prev": 59})
	check("Survival names the type; Hyper is shown", ln.contains("Fire") and ln.contains("Hyper") and ln.contains("1:01") and ln.contains("0:59"), ln)
	SV.last_run = {"judge": {}, "time": 754, "kills": 3, "level": 4, "coins": 1, "tickets": 0, "tickets10": 0, "gcoins": 0, "bosses": 0, "dex": 25,
		"dead": true, "record": true, "rec_prev": 602, "mode": "normal", "sub": "", "diff": "nightmare", "hyper": false, "moves": [], "breakdown": "Collected 1"}
	menu._show_run_summary()
	for i in range(4):
		await process_frame
	var line = menu.find_child("RecordLine", true, false)
	check("the summary shows it", line != null and String(line.text).contains("Nightmare") and line.is_visible_in_tree(), String(line.text) if line != null else "none")
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
