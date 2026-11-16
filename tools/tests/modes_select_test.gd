extends SceneTree
# Steps 43-47: the rebuilt mode select. Controller rows (tabs / cards / panel) with no dead ends, LB/RB groups, B back from
# anywhere, Left from the panel never changes the mode, every control reachable, no overlapping hit areas (mouse/touch),
# Nightmare locked, the last mode and difficulty remembered.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var menu
var SV

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

func nm(c) -> String:
	return "none" if c == null else String(c.name)

# Every control reachable from the current focus with the four directions (the real menu input code).
func reach() -> Dictionary:
	var seen := {}
	var todo: Array = [fo()]
	var guard := 0
	while not todo.is_empty() and guard < 400:
		guard += 1
		var c: Control = todo.pop_back()
		if c == null or seen.has(c):
			continue
		seen[c] = true
		for a in ["ui_left", "ui_right", "ui_up", "ui_down"]:
			if not is_instance_valid(c):
				break
			c.grab_focus()
			await process_frame
			await press(a)
			var n: Control = fo()
			if n != null and not seen.has(n):
				todo.append(n)
	return seen

func overlaps() -> Array:
	var bs: Array = menu.screens["modes"].find_children("*", "BaseButton", true, false).filter(func(b): return b.is_visible_in_tree())
	var bad: Array = []
	for i in range(bs.size()):
		for j in range(i + 1, bs.size()):
			var a: Rect2 = bs[i].get_global_rect().grow(-1.0)
			var b: Rect2 = bs[j].get_global_rect().grow(-1.0)
			if a.intersects(b) and not bs[i].is_ancestor_of(bs[j]) and not bs[j].is_ancestor_of(bs[i]):
				bad.append("%s / %s" % [bs[i].name, bs[j].name])
	# buttons outside a scroll area must sit inside the screen
	var vr: Rect2 = Rect2(Vector2.ZERO, menu.get_viewport_rect().size)
	for b in bs:
		var p = b.get_parent()
		while p != null and not (p is ScrollContainer):
			p = p.get_parent()
		if p == null and not vr.encloses(b.get_global_rect().grow(-1.0)):
			bad.append("%s off screen" % b.name)
	return bad

func _init() -> void:
	Engine.set_meta("no_save", true)
	SV = load("res://scripts/save_data.gd")
	var DIF = load("res://scripts/difficulty.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["nick"] = "Tester"
	for d in [25, 4, 7]:
		SV.d["owned"][str(d)] = {"n": 1}
	SV.d["ach"] = {"own1": 1}
	menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._menu_pick("play")
	for i in range(6):
		await process_frame
	check("Play opens the mode select on Normal run (first time)", menu.cur == "modes" and menu.modes_sel == "normal" and fo() == menu.mode_tiles["normal"], nm(fo()))
	await press("ui_right")
	check("Right moves to the next mode card and selects it", fo() == menu.mode_tiles["daily"] and menu.modes_sel == "daily")
	await press("ui_left")
	check("Left goes back to Normal run", fo() == menu.mode_tiles["normal"] and menu.modes_sel == "normal")
	await press("ui_left")
	check("Left on the first card stays (not the Back button)", fo() == menu.mode_tiles["normal"])
	await press("ui_up")
	check("Up goes to the group tab", fo() == menu.mode_tabs["Classic"], nm(fo()))
	await press("ui_up")
	check("Up on the tabs stays (not the top bar)", fo() == menu.mode_tabs["Classic"], nm(fo()))
	await press("ui_down")
	check("Down from the tabs goes to the selected card", fo() == menu.mode_tiles["normal"])
	await press("ui_down")
	check("Down from the cards goes to the options (difficulty row)", nm(fo()).begins_with("Diff_"), nm(fo()))
	await press("ui_right")
	check("Right moves along the difficulty row", nm(fo()).begins_with("Diff_"), nm(fo()))
	for i in range(3):
		await press("ui_down")
	check("Down reaches Play", fo() == menu.mp_play, nm(fo()))
	await press("ui_down")
	check("Down on Play stays", fo() == menu.mp_play)
	await press("ui_left")
	check("Left from Play goes to the selected mode, which doesn't change", fo() == menu.mode_tiles["normal"] and menu.modes_sel == "normal", nm(fo()))
	# difficulty
	menu.mp_opts.find_child("Diff_nightmare", true, false).pressed.emit()
	await process_frame
	check("Nightmare is locked and can't be chosen", DIF.chosen() == "normal" and menu.toast_lbl.text.contains("minute 30"), menu.toast_lbl.text)
	menu.mp_opts.find_child("Diff_hard", true, false).grab_focus()
	menu.mp_opts.find_child("Diff_hard", true, false).pressed.emit()
	await process_frame
	await process_frame
	check("Hard can be chosen; the cursor stays on it", DIF.chosen() == "hard" and nm(fo()) == "Diff_hard", nm(fo()))
	check("the summary shows Hard's numbers", menu.mp_opts.find_child("DiffSummary", true, false).text.contains("1.5"))
	SV.d["stats"]["hardBestMin"] = 30
	menu._modes_select("normal")
	await process_frame
	menu.mp_opts.find_child("Diff_nightmare", true, false).pressed.emit()
	await process_frame
	check("once earned, Nightmare can be chosen", DIF.chosen() == "nightmare")
	# LB / RB
	menu.mode_tiles["normal"].grab_focus()
	await process_frame
	await pad(JOY_BUTTON_RIGHT_SHOULDER)
	check("RB switches to Variants (first mode selected)", menu.modes_group == "Variants" and menu.modes_sel == "type" and fo() == menu.mode_tiles["type"], menu.modes_group)
	await press("ui_right")
	await pad(JOY_BUTTON_LEFT_SHOULDER)
	check("LB goes back to Classic, on the mode you left there", menu.modes_group == "Classic" and menu.modes_sel == "normal", menu.modes_sel)
	await pad(JOY_BUTTON_LEFT_SHOULDER)
	check("LB from the first group wraps to Settings", menu.modes_group == "Settings" and menu.modes_sel == "mods")
	# mouse / touch: a tab press
	menu.mode_tabs["Challenges"].pressed.emit()
	await process_frame
	check("pressing a tab switches the group", menu.modes_group == "Challenges" and menu.mode_tiles.has("chal_p"))
	# every control reachable, every mode; no overlaps
	for g in menu.MODE_GROUPS:
		menu._modes_group_set(String(g))
		for i in range(3):
			await process_frame
		for id in menu.mode_tiles.keys():
			menu.modes_sel = id
			menu._refresh_modes()
			await process_frame
			await process_frame
			menu.mode_tiles[id].grab_focus()
			await process_frame
			var seen: Dictionary = await reach()
			var all: Array = menu.screens["modes"].find_children("*", "BaseButton", true, false).filter(func(b): return b.is_visible_in_tree() and b.focus_mode != Control.FOCUS_NONE)
			var missing: Array = all.filter(func(b): return not seen.has(b)).map(func(b): return String(b.name))
			var outside: Array = seen.keys().filter(func(c): return is_instance_valid(c) and not menu.screens["modes"].is_ancestor_of(c)).map(func(c): return String(c.name))
			check("%s: every control reachable, nothing outside the screen" % id, missing.is_empty() and outside.is_empty(), "missing %s outside %s" % [missing, outside])
			var ov: Array = overlaps()
			check("%s: no overlapping buttons, all on screen" % id, ov.is_empty(), str(ov))
	# B from anywhere
	menu.modes_sel = "normal"
	menu._refresh_modes()
	await process_frame
	menu.mp_play.grab_focus()
	await press("ui_cancel")
	check("B from the panel goes back to the main menu", menu.cur == "main", menu.cur)
	# remembered
	menu._menu_pick("play")
	await process_frame
	check("the last mode is remembered", menu.modes_sel == "normal")
	menu.modes_sel = "tower"
	menu._refresh_modes()
	await process_frame
	menu.queue_free()
	await process_frame
	var m2 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(m2)
	for i in range(15):
		await process_frame
	m2._menu_pick("play")
	await process_frame
	check("reopening the game: same mode (The Tower) and difficulty (Nightmare)", m2.modes_sel == "tower" and DIF.chosen() == "nightmare" and m2.modes_group == "Classic", "%s / %s" % [m2.modes_sel, DIF.chosen()])
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
