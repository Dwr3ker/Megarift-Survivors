extends SceneTree
# Headless check of the handheld fixes: D-pad stays in its column (gacha), the mode list keeps the right panel separate,
# the collection grid and main menu adapt to squarer screens, and the crash report flow.
# Run with the environment variable MEGARIFT_CRASH_TEST=1 so the crash flag is written on desktop.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func press(act: String) -> void:
	var e := InputEventAction.new()
	e.action = act
	e.pressed = true
	e.strength = 1.0
	Input.parse_input_event(e)
	await process_frame
	var r := InputEventAction.new()
	r.action = act
	r.pressed = false
	Input.parse_input_event(r)
	await process_frame
	await process_frame

func focus_rect() -> Rect2:
	var f: Control = root.gui_get_focus_owner()
	return f.get_global_rect() if f != null else Rect2()

func _init() -> void:
	Engine.set_meta("no_save", true)   # this test drives the real menus: never let it write the real save
	var SV = load("res://scripts/save_data.gd")
	var CR = load("res://scripts/crash_report.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end
	# ---------- gacha: Down keeps to one column ----------
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("gacha")
	for i in range(10):
		await process_frame
	var f0: Control = root.gui_get_focus_owner()
	check("gacha opens with something focused", f0 != null)
	var start_x: float = focus_rect().get_center().x
	var ys: Array = []
	var zig := 0
	for i in range(8):
		var before: Rect2 = focus_rect()
		await press("ui_down")
		var after: Rect2 = focus_rect()
		ys.append(after.get_center().y)
		if absf(after.get_center().x - before.get_center().x) > before.size.x * 0.6 and after.get_center().y != before.get_center().y:
			zig += 1
	check("Down moves down the column without hopping sideways", zig == 0, "hops=%d" % zig)
	check("Down never goes up", ys.size() == 8 and ys[7] >= ys[0], str(ys))
	# ---------- modes: the right panel is its own column ----------
	menu._show("modes")
	for i in range(10):
		await process_frame
	await press("ui_down")
	await press("ui_accept")
	var on_panel: Control = root.gui_get_focus_owner()
	check("accepting a mode moves focus to the right panel", on_panel != null and not menu.mode_tiles.values().has(on_panel), str(on_panel))
	await press("ui_down")
	var still: Control = root.gui_get_focus_owner()
	check("Down at the bottom of the right panel stays there (no jump into Challenges)", still != null and not menu.mode_tiles.values().has(still))
	for i in range(8):
		await press("ui_up")
	var back: Control = root.gui_get_focus_owner()
	check("Up past the top of the right panel returns to the selected mode", back != null and menu.mode_tiles.values().has(back) and back == menu.mode_tiles[menu.modes_sel], str(back))
	# ---------- squarer screens ----------
	Engine.set_meta("force_compact", false)
	check("normal layout: 8 columns, 32 per page", menu._dex_cols() == 8 and menu._per_page() == 32)
	Engine.set_meta("force_compact", true)
	check("compact layout: 6 columns, 24 per page", menu._dex_cols() == 6 and menu._per_page() == 24)
	menu._show("dex")
	for i in range(10):
		await process_frame
	check("the collection grid uses 6 columns and at most 24 cards", menu.dex_grid.columns == 6 and menu.dex_grid.get_child_count() <= 24, "%d cols, %d cards" % [menu.dex_grid.columns, menu.dex_grid.get_child_count()])
	var card: Control = menu.dex_grid.get_child(0)
	check("compact cards are bigger", card.custom_minimum_size.x > 100.0 and card.custom_minimum_size.y > 115.0, str(card.custom_minimum_size))
	menu.queue_free()
	await process_frame
	var menu2 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu2)
	for i in range(20):
		await process_frame
	check("compact main menu: taller stage card", menu2.main_card.custom_minimum_size.y >= 430.0, str(menu2.main_card.custom_minimum_size))
	check("compact main menu: taller buttons", menu2.cont_btn.custom_minimum_size.y >= 110.0 and menu2.main_btns["play"].custom_minimum_size.y >= 150.0)
	menu2.queue_free()
	await process_frame
	Engine.set_meta("force_compact", false)
	var menu3 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu3)
	for i in range(20):
		await process_frame
	check("normal main menu keeps the original sizes", menu3.main_card.custom_minimum_size.y == 320.0 and menu3.cont_btn.custom_minimum_size.y == 92.0)
	menu3.queue_free()
	await process_frame
	Engine.remove_meta("force_compact")
	# ---------- starter picker and redeem code ----------
	var menu5 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu5)
	for i in range(20):
		await process_frame
	menu5._show("test")
	for i in range(5):
		await process_frame
	menu5._test_pick_strong()
	for i in range(5):
		await process_frame
	var grid5: GridContainer = null
	for c in menu5.test_box.get_children():
		if c is GridContainer:
			grid5 = c
	check("'Skip the quiz' shows the 12 strong starters", grid5 != null and grid5.get_child_count() == 12, str(grid5.get_child_count() if grid5 != null else -1))
	(grid5.get_child(0) as Button).pressed.emit()
	await process_frame
	check("choosing one makes it the partner", int(SV.d["selected"]) == 6 and SV.d["owned"].has("6"), str(SV.d["selected"]))
	var tabs_n: int = menu5.SET_TABS.size()
	for ti in range(tabs_n):
		menu5.set_tab = ti
		menu5._refresh_settings()
		for i in range(3):
			await process_frame
	var found_code := false
	for ti in range(tabs_n):
		menu5.set_tab = ti
		menu5._refresh_settings()
		await process_frame
		for n in menu5.screens["settings"].find_children("*", "LineEdit", true, false):
			if (n as LineEdit).placeholder_text == "Enter code":
				found_code = true
	check("the settings have an 'Enter code' box", found_code)
	menu5.queue_free()
	await process_frame
	# ---------- level-up: skip with the controller ----------
	var PAD = load("res://scripts/pad.gd")
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(10):
		await process_frame
	m.player.level += 1
	m.pending_levels = 1
	m._open_cards()
	m.cards.age = 5.0
	await process_frame
	check("the level-up screen offers Skip", m.cards.open and m.cards.can_skip and m.cards._has_skip())
	var xp0: float = m.player.xp
	var jb := InputEventJoypadButton.new()
	jb.button_index = PAD.btn("cancel")
	jb.pressed = true
	Input.parse_input_event(jb)
	await process_frame
	await process_frame
	check("the controller's Cancel button skips the upgrade (+25% XP, screen closes)", not m.cards.open and not m.choosing and m.pending_levels == 0 and m.player.xp > xp0, "xp %.1f -> %.1f" % [xp0, m.player.xp])
	# Cancel does nothing on a screen without Skip (e.g. the Eternatus choice)
	m.choosing = true
	m.cards.show_cards([{"cat": "eter", "id": "go", "key": "k", "w": 1.0, "title": "a", "desc": "b", "icon": "star", "tag": "t", "color": Color.WHITE}, {"cat": "eter", "id": "end", "key": "k2", "w": 1.0, "title": "c", "desc": "d", "icon": "star", "tag": "t", "color": Color.WHITE}], "x", "y", false)
	m.cards.age = 5.0
	var jb2 := InputEventJoypadButton.new()
	jb2.button_index = PAD.btn("cancel")
	jb2.pressed = true
	Input.parse_input_event(jb2)
	await process_frame
	await process_frame
	check("Cancel does not dismiss a screen that has no Skip", m.cards.open and m.choosing)
	m.queue_free()
	await process_frame
	# ---------- crash report ----------
	var dir_ok := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs")) == OK
	var fake := "user://logs/godot2099-01-01T00.00.00.log"
	var lg := FileAccess.open(fake, FileAccess.WRITE)
	for i in range(60):
		lg.store_line("[run] t=%d enemies=3 hp=80 lvl=1 boss=false choosing=false" % (i * 10))
		lg.store_line("   at: something (core/x.cpp:1)")
		lg.store_line("")
	lg.close()
	CR.mark_run_start()
	check("a run start leaves the flag", FileAccess.file_exists(CR.FLAG))
	var tail: String = CR.previous_log_tail(10)
	var lines: PackedStringArray = tail.split("\n")
	check("the log tail has the last 10 useful lines only", lines.size() == 10 and lines[9].begins_with("[run] t=590") and not tail.contains("at: "), "%d lines, last=%s" % [lines.size(), lines[lines.size() - 1]])
	var menu4 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu4)
	for i in range(20):
		await process_frame
	var found := false
	for ch in menu4.get_children():
		if ch is Control and ch.get_script() != null and String(ch.get_script().resource_path).ends_with("crash_report.gd"):
			found = true
	check("after an unclean run the menu shows the crash report once", found and not FileAccess.file_exists(CR.FLAG))
	CR.mark_run_end()
	check("a normal run end clears the flag", not FileAccess.file_exists(CR.FLAG) and not CR.take_crash_flag())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fake))
	menu4.queue_free()
	await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
