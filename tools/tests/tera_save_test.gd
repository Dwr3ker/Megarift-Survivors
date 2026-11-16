extends SceneTree
# Roadmap step 2: every Pokémon has a Tera type (default: its first type), it can be set to any of the 18 types,
# it survives saving and loading, and an old save without Tera data still works.
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
	check("18 Tera types", SV.TERA_TYPES.size() == 18)
	check("a new save has Tera data", SV.d.has("tera"))
	check("default is the first type (Charizard: fire)", SV.tera_type(6) == "fire")
	check("default is the first type (Gyarados: water)", SV.tera_type(130) == "water")
	# an old save from before Tera
	SV.d.erase("tera")
	check("an old save without Tera data still gives the first type", SV.tera_type(25) == "electric")
	check("setting a Tera type on an old save works", SV.set_tera_type(25, "fire") and SV.tera_type(25) == "fire")
	check("an unknown type is refused", not SV.set_tera_type(25, "stellar") and SV.tera_type(25) == "fire")
	# survives a save and load (the save file is JSON)
	var back = JSON.parse_string(JSON.stringify(SV.d))
	SV.d = back
	check("it survives saving and loading", SV.tera_type(25) == "fire")
	check("other Pokémon keep their default", SV.tera_type(1) == "grass")
	check("setting it back to the first type clears it", SV.set_tera_type(25, "electric") and not (SV.d["tera"] as Dictionary).has("25") and SV.tera_type(25) == "electric")
	check("every type can be chosen", SV.TERA_TYPES.all(func(t): return SV.set_tera_type(143, t) and SV.tera_type(143) == t))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
