extends SceneTree
# Eggs steps 24-25: the Incubator screen shows 3 slots and the bag; pressing (mouse, touch or controller A, all plain
# Buttons) moves eggs: bag -> free slot; full incubator -> pick, then a slot swaps; slot -> bag; Back drops a pick
# before leaving; the controller reaches every egg with the D-pad.
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
	SV.load_dex()
	SV.d["nick"] = "Tester"
	SV.d["owned"]["25"] = {"n": 1}
	var ids: Array = []
	for sp in [[1, 1, "grass"], [4, 2, "fire"], [7, 3, "water"], [92, 2, "ghost"], [74, 1, "rock"]]:
		var e: Dictionary = EG.make(sp[0], sp[1], sp[2])
		EG.add(e)
		ids.append(int(e["id"]))
	EG.by_id(ids[1])["steps"] = 1500.0   # ready
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	check("the main menu has an Incubator button", menu.main_btns.has("eggs") and menu.main_btns["eggs"].is_visible_in_tree())
	var bd = menu.egg_btn.get_node("EggBadge")
	check("step 28: a badge shows 1 egg ready", bd.visible and bd.text == "1")
	check("step 28: a notice says the egg is moving", menu.toast_lbl.text.contains("moving"), menu.toast_lbl.text)
	menu.toast_lbl.text = ""
	menu._refresh_main()
	check("the notice shows only once per egg", menu.toast_lbl.text == "")
	menu.main_btns["eggs"].pressed.emit()
	for i in range(4):
		await process_frame
	var ui = menu.inc_ui
	check("it opens the Incubator", menu.cur == "eggs" and ui.is_visible_in_tree())
	check("3 slots and 2 eggs in the bag", ui.slot_btns.size() == 3 and ui.bag_btns.size() == 2, "%d / %d" % [ui.slot_btns.size(), ui.bag_btns.size()])
	var fo = menu.get_viewport().gui_get_focus_owner()
	check("controller: focus starts on slot 1", fo == ui.slot_btns[0])
	var r = ui.slot_btns[0].find_valid_focus_neighbor(SIDE_RIGHT)
	var d = ui.slot_btns[0].find_valid_focus_neighbor(SIDE_BOTTOM)
	check("D-pad right moves to slot 2", r == ui.slot_btns[1])
	check("D-pad down reaches the bag", ui.bag_btns.has(d))
	check("D-pad up from the bag comes back to the slots", ui.slot_btns.has(ui.bag_btns[0].find_valid_focus_neighbor(SIDE_TOP)))
	# slot 1 (not ready) -> back to the bag
	ui.slot_btns[0].pressed.emit()
	await process_frame
	check("pressing an incubated egg takes it out", int(EG.by_id(ids[0])["slot"]) == -1 and EG.in_slot(0).is_empty())
	# a bag egg goes into the free slot
	var bag_id: int = ui.bag_ids[0]
	ui.bag_btns[0].pressed.emit()
	await process_frame
	check("pressing a bag egg puts it in the free slot", int(EG.by_id(bag_id)["slot"]) == 0)
	# incubator full: pick, then a slot swaps
	var pick: int = ui.bag_ids[0]
	var was_in_3: int = int(EG.in_slot(2)["id"])
	ui.bag_btns[0].pressed.emit()
	await process_frame
	check("full incubator: the egg is picked", ui.sel_id == pick and int(EG.by_id(pick)["slot"]) == -1)
	fo = menu.get_viewport().gui_get_focus_owner()
	check("focus jumps to the slots to choose one", ui.slot_btns.has(fo))
	ui.slot_btns[2].pressed.emit()
	await process_frame
	check("pressing a slot swaps the eggs", int(EG.by_id(pick)["slot"]) == 2 and int(EG.by_id(was_in_3)["slot"]) == -1 and ui.sel_id == -1)
	# Back drops a pick before leaving
	ui.bag_btns[0].pressed.emit()
	await process_frame
	menu._leave()
	await process_frame
	check("Back drops the pick and stays", menu.cur == "eggs" and ui.sel_id == -1)
	menu._leave()
	await process_frame
	check("a second Back leaves", menu.cur == "main")
	# a ready egg asks to hatch (the signal)
	menu._show("eggs")
	await process_frame
	var got := [-1]
	ui.hatch.connect(func(i): got[0] = i)
	var rs: int = int(EG.by_id(ids[1])["slot"])
	ui.slot_btns[rs].pressed.emit()
	await process_frame
	check("pressing a ready egg starts hatching it", got[0] == ids[1])
	check("the hatch scene plays", menu.hatch_ui != null and menu.hatch_ui.visible)
	check("the egg hatched: it left the bag and Charmander is owned", EG.count() == 4 and SV.owns(4))
	menu.hatch_ui.skip()
	for i in range(4):
		await process_frame
	var okb = menu.get_viewport().gui_get_focus_owner()
	check("skip shows the Pokémon with OK focused", okb is Button and okb.text == "OK", str(okb))
	okb.pressed.emit()
	await process_frame
	check("OK closes the scene and the slot is empty", not menu.hatch_ui.visible and EG.in_slot(rs).is_empty())
	menu._show("main")
	await process_frame
	check("no egg ready: the badge hides", not bd.visible)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
