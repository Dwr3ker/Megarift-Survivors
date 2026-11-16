extends SceneTree
# Eggs step 30: the achievements First hatch (1 egg), Egg collector (10) and Shiny surprise (a shiny from an egg).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var EG = load("res://scripts/eggs.gd")
	var PG = load("res://scripts/progress.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	var ids: Array = PG.list().map(func(a): return String(a["id"]))
	check("the three egg achievements exist", ids.has("egg1") and ids.has("egg10") and ids.has("eggShiny"))
	var hatch1 := func(dex: int):
		var e: Dictionary = EG.make(dex, 1, "grass")
		e["slot"] = 0
		e["steps"] = e["need"]
		EG.eggs().append(e)
		return EG.hatch(int(e["id"]))
	hatch1.call(1)
	PG.check()
	check("First hatch after one egg", SV.d["ach"].has("egg1") and not SV.d["ach"].has("egg10"))
	for i in range(9):
		hatch1.call(1)
	PG.check()
	check("Egg collector after ten", SV.d["ach"].has("egg10"))
	check("no Shiny surprise without a shiny hatch", not SV.d["ach"].has("eggShiny") or int(SV.d["stats"].get("eggShinies", 0)) > 0)
	var n := 0
	while int(SV.d["stats"].get("eggShinies", 0)) == 0 and n < 2000:
		hatch1.call(1)
		n += 1
	PG.check()
	check("Shiny surprise after a shiny hatch", SV.d["ach"].has("eggShiny"), "%d hatches" % n)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
