extends SceneTree
# Wardrobe steps 57-58: the Wardrobe screen (tabs, item cards, equip / take off, locked items explain themselves, every
# card reachable with the controller, LB / RB tabs, B back) and unlocks from each source: a medal, an achievement and
# the gacha (a 10-pull).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var menu

func fo() -> Control:
	return menu.get_viewport().gui_get_focus_owner()

func press(a: String) -> void:
	var e := InputEventAction.new()
	e.action = a
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	var r := InputEventAction.new()
	r.action = a
	r.pressed = false
	Input.parse_input_event(r)
	await process_frame
	await process_frame

func pad(btn: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	var r := InputEventJoypadButton.new()
	r.button_index = btn
	r.pressed = false
	Input.parse_input_event(r)
	await process_frame
	await process_frame

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var WR = load("res://scripts/wardrobe.gd")
	var ACH = load("res://scripts/ach.gd")
	var PG = load("res://scripts/progress.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["nick"] = "Tester"
	SV.d["owned"]["25"] = {"n": 1, "shiny": false}
	# ---- unlock sources ----
	ACH.event("alpha", {})   # medal Alpha tamer
	check("a medal unlocks its item (Leaf)", WR.sync().has("leaf") and WR.owns("leaf"))
	SV.d["stats"]["best_time"] = 30 * 60
	SV.d["stats"]["runs"] = 1
	PG.check()
	var got: Array = WR.sync()
	check("an achievement unlocks its item (Gold frame from Marathon)", WR.owns("gold"), str(got))
	var g0: int = WR.ORDER.filter(func(i): return String(WR.ITEMS[i][2]) == "gacha" and WR.owns(i)).size()
	SV.d["tickets"] = 1000
	var tries := 0
	while WR.ORDER.filter(func(i): return String(WR.ITEMS[i][2]) == "gacha" and WR.owns(i)).size() == g0 and tries < 200:
		SV.pull(1, 10, "t1")
		SV.d["tickets"] = 1000
		tries += 1
	check("the gacha gives a gacha-only item from a 10-pull", tries < 200 and SV.last_look != "" and WR.owns(SV.last_look), "%d pulls, %s" % [tries, SV.last_look])
	check("the gacha rate is about 10% per 10-pull", tries <= 60, str(tries))
	# ---- the screen ----
	menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	check("the main menu has a Wardrobe button with a 'new' dot", menu.main_btns.has("wardrobe") and menu.wr_btn.get_node("NewDot").visible)
	menu.main_btns["wardrobe"].pressed.emit()
	for i in range(6):
		await process_frame
	var ui = menu.wr_ui
	check("it opens on Trails: None + 8 trails", menu.cur == "wardrobe" and ui.kind == "trail" and ui.cards.size() == 9, str(ui.cards.size()))
	check("the dot is cleared once seen", (WR.data()["new"] as Array).is_empty())
	var leaf = ui.grid.get_node("Item_leaf")
	leaf.pressed.emit()
	await process_frame
	check("pressing an owned trail equips it", WR.equipped("trail") == "leaf")
	ui.grid.get_node("Item_leaf").pressed.emit()
	await process_frame
	check("pressing it again takes it off", WR.equipped("trail") == "")
	ui.grid.get_node("Item_snow").pressed.emit()
	await process_frame
	check("a locked item stays locked and says where it's earned", WR.equipped("trail") == "" and menu.toast_lbl.text.contains("Night survivor"), menu.toast_lbl.text)
	# controller
	ui.cards[0].grab_focus()
	await process_frame
	await press("ui_right")
	check("Right moves along the grid", fo() == ui.cards[1])
	await press("ui_down")
	check("Down moves down a row", fo() == ui.cards[4])
	await press("ui_up")
	await press("ui_up")
	check("Up from the first row goes to the tab", fo() == ui.tabs["trail"], str(fo().name))
	await press("ui_up")
	check("Up on the tabs stays (not the top bar)", fo() == ui.tabs["trail"])
	await pad(JOY_BUTTON_RIGHT_SHOULDER)
	check("RB: Auras (None + 6)", ui.kind == "aura" and ui.cards.size() == 7)
	await pad(JOY_BUTTON_RIGHT_SHOULDER)
	check("RB: HUD frames (4)", ui.kind == "frame" and ui.cards.size() == 4)
	ui.grid.get_node("Item_gold").pressed.emit()
	await process_frame
	check("equip the Gold frame", WR.equipped("frame") == "gold")
	# every card reachable on every tab
	for k in ["trail", "aura", "frame"]:
		ui.set_kind(k)
		for i in range(3):
			await process_frame
		var seen := {}
		var todo: Array = [ui.cards[0]]
		while not todo.is_empty():
			var c: Control = todo.pop_back()
			if seen.has(c):
				continue
			seen[c] = true
			for a in ["ui_left", "ui_right", "ui_up", "ui_down"]:
				c.grab_focus()
				await process_frame
				await press(a)
				if fo() != null and not seen.has(fo()):
					todo.append(fo())
		var missing: Array = ui.cards.filter(func(c): return not seen.has(c))
		var outside: Array = seen.keys().filter(func(c): return not menu.screens["wardrobe"].is_ancestor_of(c))
		check("%s: every card reachable, nothing outside the screen" % k, missing.is_empty() and outside.is_empty(), "missing %d outside %d" % [missing.size(), outside.size()])
	await press("ui_cancel")
	check("B goes back to the main menu", menu.cur == "main")
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
