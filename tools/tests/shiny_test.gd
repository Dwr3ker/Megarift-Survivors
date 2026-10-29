extends SceneTree
# Headless check: "Use shiny version" is per Pokémon, and the old global switch migrates without changing what you saw.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.d["shiny_pref"] = {}
	SV.d["owned"] = {"6": {"n": 1, "shiny": true}, "9": {"n": 1, "shiny": true}, "3": {"n": 1, "shiny": false}}
	check("owning a shiny does not turn it on", not SV.shiny_wanted(6) and not SV.shiny_wanted(9))
	SV.set_shiny_pref(6, true)
	check("turning it on for one Pokémon leaves the others alone", SV.shiny_wanted(6) and not SV.shiny_wanted(9) and not SV.shiny_wanted(3))
	SV.set_shiny_pref(3, true)
	check("a Pokémon without a shiny never shows one", not SV.shiny_wanted(3))
	check("a Pokémon you do not own never shows one", not SV.shiny_wanted(25))
	SV.set_shiny_pref(6, false)
	check("turning it off works", not SV.shiny_wanted(6))
	# migration of the old switch
	SV.d = SV.default_data()
	SV.d["shiny_on"] = true
	SV.d.erase("shiny_pref")
	SV.d["owned"] = {"6": {"n": 1, "shiny": true}, "9": {"n": 1, "shiny": true}, "3": {"n": 1, "shiny": false}}
	SV._migrate_shiny()
	check("the old switch keeps your shinies on once, then is retired", SV.shiny_wanted(6) and SV.shiny_wanted(9) and not SV.shiny_wanted(3) and not bool(SV.d["shiny_on"]))
	SV.set_shiny_pref(9, false)
	check("after migrating you can switch one off", SV.shiny_wanted(6) and not SV.shiny_wanted(9))
	SV.d = SV.default_data()
	SV.d["shiny_on"] = false
	SV.d.erase("shiny_pref")
	SV.d["owned"] = {"6": {"n": 1, "shiny": true}}
	SV._migrate_shiny()
	check("a switch that was off migrates to nothing on", not SV.shiny_wanted(6))
	# the collection screen toggle
	SV.d = SV.default_data()
	SV.d["shiny_pref"] = {}
	SV.d["owned"] = {"150": {"n": 3, "shiny": true}, "151": {"n": 1, "shiny": true}}
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu.dex_sel = 150
	menu._show("dex")
	for i in range(6):
		await process_frame
	menu._dex_detail()
	for i in range(4):
		await process_frame
	var cb: CheckButton = null
	for n in menu.dex_detail.find_children("*", "CheckButton", true, false):
		cb = n
	check("the collection screen has the toggle for the open Pokémon", cb != null and not cb.button_pressed)
	if cb != null:
		cb.button_pressed = true
		await process_frame
		await process_frame
	check("pressing it changes only that Pokémon", SV.shiny_wanted(150) and not SV.shiny_wanted(151))
	menu.queue_free()
	await process_frame
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
