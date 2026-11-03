extends SceneTree
# Pokémon list filters (Show: all / owned / unowned / shiny, grid size, type icons) are kept in the save between sessions;
# the username prompt saves a name; one special username may redeem a code more than once.
# That name is only stored hashed: set MEGARIFT_DEV_NAME to it to test the reuse (skipped otherwise).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var CODES = load("res://scripts/codes.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["owned"]["1"] = {"n": 1, "shiny": true}
	SV.d["owned"]["4"] = {"n": 1, "shiny": false}
	SV.d["owned"]["7"] = {"n": 1, "shiny": false}
	SV.d["selected"] = 4
	Engine.set_meta("force_name_prompt", true)
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	# ---------- username prompt ----------
	check("a save without a name asks for a username", is_instance_valid(menu.name_prompt))
	var le: LineEdit = menu.name_prompt.find_child("NameEdit", true, false)
	var okb: Button = menu.name_prompt.find_child("NameOk", true, false)
	check("Confirm is off until a name is typed", okb != null and okb.disabled)
	menu._name_confirm("   ")
	check("a blank name is refused", is_instance_valid(menu.name_prompt) and String(SV.d["nick"]) == "")
	le.text = "Ash"
	le.text_changed.emit("Ash")
	check("typing a name turns Confirm on", not okb.disabled)
	menu._name_confirm("  Ash  ")
	await process_frame
	check("the name is saved (trimmed) and the prompt closes", String(SV.d["nick"]) == "Ash" and not is_instance_valid(menu.name_prompt))
	check("names are at most 16 characters", menu._random_name().length() <= menu.NAME_MAX)
	Engine.remove_meta("force_name_prompt")
	# ---------- codes: once each, unless the username is the special one ----------
	var r1: Dictionary = CODES.redeem("MEGARIFT", SV.d)
	var r2: Dictionary = CODES.redeem("MEGARIFT", SV.d)
	check("a code works once for a normal username", bool(r1["ok"]) and not bool(r2["ok"]), str(r2.get("msg", "")))
	check("an ordinary username is not the special one", not CODES.unlimited(SV.d))
	var dev: String = OS.get_environment("MEGARIFT_DEV_NAME")
	if dev != "":
		SV.d["nick"] = " " + dev.to_upper() + " "
		var c0: int = int(SV.d["coins"])
		var r3: Dictionary = CODES.redeem("MEGARIFT", SV.d)
		var r4: Dictionary = CODES.redeem("MEGARIFT", SV.d)
		check("the special username (any capitalisation) can redeem it again and again", bool(r3["ok"]) and bool(r4["ok"]) and int(SV.d["coins"]) > c0)
		check("unknown codes are still refused for it", not bool(CODES.redeem("nope-nope", SV.d)["ok"]))
	else:
		print("SKIP  special username reuse (set MEGARIFT_DEV_NAME to test it)")
	SV.d["nick"] = "Ash"
	# ---------- filters ----------
	menu._show("dex")
	for i in range(6):
		await process_frame
	var to: OptionButton = menu.find_child("DexType", true, false)
	check("the type filter shows an icon next to each type", to != null and to.item_count == menu.TYPE_IDS.size() + 1 and to.get_item_icon(0) == null and to.get_item_icon(1) != null and to.get_item_icon(to.item_count - 1) != null)
	menu.dex_gen = 1
	var counts := {}
	for sh in range(4):
		menu.dex_show = sh
		counts[sh] = menu._dex_filtered().size()
	var gen1: int = 0
	for p in SV.dex_list:
		if int(p["gen"]) == 1 and SV.smeta.has(str(int(p["dex"]))):
			gen1 += 1
	check("Show: Owned lists only owned Pokémon", int(counts[1]) == 3, str(counts))
	check("Show: Unowned lists the rest", int(counts[2]) == gen1 - 3, str(counts))
	check("Show: Shiny lists Pokémon whose shiny you own", int(counts[3]) == 1 and int(menu._dex_filtered()[0]["dex"]) == 1, str(counts))
	var med_pp: int = menu._per_page()
	var med_cols: int = menu._dex_cols()
	# change filters through the controls, as a player would
	(menu.find_child("DexShow", true, false) as OptionButton).item_selected.emit(2)
	to.item_selected.emit(menu.TYPE_IDS.find("fire") + 1)
	(menu.find_child("DexSort", true, false) as OptionButton).item_selected.emit(2)
	(menu.find_child("DexGrid", true, false) as OptionButton).item_selected.emit(0)
	await process_frame
	check("Small grid has more cards per page", menu._per_page() > med_pp and menu.dex_grid.columns > med_cols, "%d per page" % menu._per_page())
	(menu.find_child("DexGrid", true, false) as OptionButton).item_selected.emit(2)
	await process_frame
	check("Large grid has fewer, bigger cards", menu._per_page() < med_pp and menu.dex_grid.columns < med_cols)
	var st: Dictionary = SV.d["settings"]
	check("filter choices are written to the save", int(st["dex_show"]) == 2 and String(st["dex_type"]) == "fire" and int(st["dex_sort"]) == 2 and int(st["dex_grid"]) == 2 and int(st["dex_gen"]) == 1, str([st["dex_show"], st["dex_type"], st["dex_sort"], st["dex_grid"], st["dex_gen"]]))
	# a later login: a fresh menu reads them back
	var saved: Dictionary = SV.d.duplicate(true)
	menu.queue_free()
	await process_frame
	SV.d = SV._merge(SV.default_data(), saved)
	var m2 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(m2)
	for i in range(20):
		await process_frame
	check("no username prompt once a name is set", not is_instance_valid(m2.name_prompt))
	check("the next session restores Show, type, sort, grid size and region", m2.dex_show == 2 and m2.dex_type == "fire" and m2.dex_sort == 2 and m2.dex_grid_sz == 2 and m2.dex_gen == 1)
	var to2: OptionButton = m2.find_child("DexType", true, false)
	check("and the controls show them", to2.selected == m2.TYPE_IDS.find("fire") + 1 and (m2.find_child("DexShow", true, false) as OptionButton).selected == 2 and (m2.find_child("DexGrid", true, false) as OptionButton).selected == 2)
	# an old save without these keys falls back to the defaults
	var old: Dictionary = SV.default_data()
	for k in ["dex_gen", "dex_type", "dex_sort", "dex_show", "dex_grid"]:
		old["settings"].erase(k)
	SV.d = SV._merge(SV.default_data(), old)
	m2._dex_load_filters()
	check("an older save opens with All / medium grid", m2.dex_show == 0 and m2.dex_grid_sz == 1 and m2.dex_type == "")
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
