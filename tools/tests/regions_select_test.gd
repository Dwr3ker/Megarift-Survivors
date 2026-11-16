extends SceneTree
# Steps 47c-47d: the full-screen region select. Opens from a Normal run; the cursor starts on the last region; the 5 x 2
# grid and the strip (Back, Start run) are reachable with no way out of the screen; locked regions can be focused and
# explain themselves but don't start; B goes back to the mode select on Normal run; no overlapping buttons.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var menu

func fo() -> Control:
	return menu.get_viewport().gui_get_focus_owner()

func nm(c) -> String:
	return "none" if c == null else String(c.name)

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

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["nick"] = "Tester"
	SV.d["owned"]["25"] = {"n": 1}
	SV.d["ach"] = {"own1": 1}
	SV.region_record(1, 1834, true)   # Kanto cleared: Johto open, Hoenn on locked
	SV.d["region"] = 1
	menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("modes")
	await process_frame
	if load("res://scripts/run_save.gd").exists():
		menu._region_picker()   # a real saved run is waiting (Play would ask about it first): open the regions directly
	else:
		menu._modes_play()   # Normal run selected: Play asks for the region
	for i in range(5):
		await process_frame
	check("Play on Normal run opens the region screen", menu.cur == "regions")
	check("the cursor starts on the last region (Kanto)", nm(fo()) == "Region_1", nm(fo()))
	await press("ui_right")
	check("Right: Johto", nm(fo()) == "Region_2" and menu.reg_sel == 2)
	await press("ui_right")
	check("Right: Hoenn, locked, can be focused", nm(fo()) == "Region_3")
	check("the strip explains the lock; Start still starts Johto", menu.reg_line.text.contains("Johto") and menu.reg_sel == 2 and menu.reg_start.text.contains("Johto"), menu.reg_start.text)
	fo().pressed.emit()
	await process_frame
	check("pressing a locked region keeps you here", menu.cur == "regions" and menu.toast_lbl.text.contains("Arceus"))
	await press("ui_up")
	check("Up on the top row stays", nm(fo()) == "Region_3")
	await press("ui_down")
	check("Down: the card below (Kalos)", nm(fo()) == "Region_8", nm(fo()))
	await press("ui_down")
	check("Down from the bottom row: Start run", fo() == menu.reg_start, nm(fo()))
	await press("ui_up")
	check("Up from the strip: the selected region (Johto)", nm(fo()) == "Region_2", nm(fo()))
	await press("ui_down")
	await press("ui_down")
	check("from an open region, Down twice reaches Start run", fo() == menu.reg_start, nm(fo()))
	await press("ui_left")
	check("Left: Back", fo() == menu.reg_back)
	await press("ui_left")
	check("Left on Back stays (not the top bar)", fo() == menu.reg_back)
	# every card and button reachable; nothing outside the screen; no overlaps
	var seen := {}
	var todo: Array = [menu.reg_cards[0]]
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
	var all: Array = menu.screens["regions"].find_children("*", "BaseButton", true, false).filter(func(b): return b.is_visible_in_tree())
	var missing: Array = all.filter(func(b): return not seen.has(b)).map(func(b): return String(b.name))
	var outside: Array = seen.keys().filter(func(c): return not menu.screens["regions"].is_ancestor_of(c)).map(func(c): return String(c.name))
	check("every region and button reachable, nothing outside the screen", missing.is_empty() and outside.is_empty(), "missing %s outside %s" % [missing, outside])
	var bad: Array = []
	var vr := Rect2(Vector2.ZERO, menu.get_viewport_rect().size)
	for i in range(all.size()):
		if not vr.encloses(all[i].get_global_rect().grow(-1.0)):
			bad.append("%s off screen" % all[i].name)
		for j in range(i + 1, all.size()):
			if all[i].get_global_rect().grow(-1.0).intersects(all[j].get_global_rect().grow(-1.0)):
				bad.append("%s / %s" % [all[i].name, all[j].name])
	check("no overlapping buttons, all on screen (1280 x 720)", bad.is_empty(), str(bad))
	# B goes back to the mode select on Normal run
	menu.reg_cards[4].grab_focus()
	await press("ui_cancel")
	await process_frame
	check("B goes back to the mode select, on Normal run", menu.cur == "modes" and fo() == menu.mode_tiles.get("normal"), "%s %s" % [menu.cur, nm(fo())])
	# the last region is remembered
	SV.d["region"] = 2
	menu._show("regions")
	await process_frame
	await process_frame
	check("the last region (Johto) is focused next time", nm(fo()) == "Region_2", nm(fo()))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
