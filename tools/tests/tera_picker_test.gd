extends SceneTree
# Roadmap step 3: the Pokédex details show the Tera type with a Change button; the picker offers the 18 types with the
# current one marked, works with a controller (focus starts on the current type, moves around the grid, returns to the
# button after choosing) and saves the choice.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["nick"] = "Tester"
	SV.d["owned"]["25"] = {"n": 1}
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu.dex_sel = 25
	menu._show("dex")
	for i in range(6):
		await process_frame
	menu.dex_sel = 25
	menu._dex_detail()
	await process_frame
	var tb = menu.dex_detail.find_child("TeraBtn", true, false)
	check("owned Pokémon: the details have a Change Tera type button", tb is Button)
	var labels: Array = menu.dex_detail.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("it shows the current Tera type (Electric)", labels.has("Electric"))
	tb.pressed.emit()
	await process_frame
	var types: Array = menu.gacha_result.find_children("Tera_*", "Button", true, false)
	check("the picker offers the 18 types", types.size() == 18, str(types.size()))
	var fo = menu.get_viewport().gui_get_focus_owner()
	check("controller: focus starts on the current type", fo != null and fo.name == "Tera_electric", str(fo.name if fo else "none"))
	var right = fo.find_valid_focus_neighbor(SIDE_RIGHT) if fo else null
	var down = fo.find_valid_focus_neighbor(SIDE_BOTTOM) if fo else null
	check("controller: right and down move around the grid", right != null and right.name == "Tera_grass" and down != null and String(down.name).begins_with("Tera_"), "%s / %s" % [right.name if right else "none", down.name if down else "none"])
	var all_in := true
	for bt in types:
		for sd in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			var nb = bt.find_valid_focus_neighbor(sd)
			if nb == null or not menu.gacha_result.is_ancestor_of(nb):
				all_in = false
	check("controller: focus never leaves the picker", all_in)
	var fire = menu.gacha_result.find_child("Tera_fire", true, false)
	fire.pressed.emit()
	for i in range(3):
		await process_frame
	check("choosing Fire saves it", SV.tera_type(25) == "fire")
	check("the picker closes", not menu.gacha_result.visible)
	labels = menu.dex_detail.find_children("*", "Label", true, false).map(func(l): return l.text)
	check("the details now show Fire", labels.has("Fire"))
	fo = menu.get_viewport().gui_get_focus_owner()
	check("controller: focus is back on the Change button", fo != null and fo.name == "TeraBtn", str(fo.name if fo else "none"))
	# an unowned Pokémon has no picker
	menu.dex_sel = 150
	menu._dex_detail()
	await process_frame
	check("unowned Pokémon: no Tera picker", menu.dex_detail.find_child("TeraBtn", true, false) == null)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
