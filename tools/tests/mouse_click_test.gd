extends SceneTree
# Mouse clicks through the real input path (Input.parse_input_event, so Godot also makes its emulated touch from each
# click). A click must never flip the input mode to "touch": that rebuilt the Pokémon details panel between press and
# release, and its buttons (Change Tera type, Train IVs...) ignored the click.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func click(p: Vector2) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	mm.relative = Vector2(20, 0)
	Input.parse_input_event(mm)
	await process_frame
	await process_frame
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = p
		e.global_position = p
		Input.parse_input_event(e)
		await process_frame
		await process_frame
	for i in range(4):
		await process_frame

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var INP = load("res://scripts/input_mode.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["nick"] = "Tester"
	for d in [25, 4, 7, 1]:
		SV.d["owned"][str(d)] = {"n": 1}
	# the rule itself: the touch Godot makes from a mouse click is not a finger
	INP.mode = "kb"
	var et := InputEventScreenTouch.new()
	et.pressed = true
	et.device = InputEvent.DEVICE_ID_EMULATION
	check("an emulated touch (from a mouse click) keeps keyboard and mouse", not INP.feed(et) and INP.mode == "kb", INP.mode)
	if DisplayServer.get_name() == "headless":   # headless Godot doesn't deliver mouse clicks to buttons: the rule above is the check
		print("RESULT: ", "PASS" if ok else "FAIL")
		quit(0 if ok else 1)
		return
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("dex")
	for i in range(10):
		await process_frame
	var cards: Array = menu.dex_grid.get_children().filter(func(c): return c is BaseButton and c.is_visible_in_tree())
	await click(cards[3].get_global_rect().get_center())
	check("clicking a Pokémon card selects it", menu.dex_sel == 4, str(menu.dex_sel))
	check("a click leaves the input mode on keyboard and mouse", INP.mode == "kb", INP.mode)
	var tb = menu.dex_detail.find_child("TeraBtn", true, false)
	menu.dex_dsc.ensure_control_visible(tb)
	for i in range(4):
		await process_frame
	await click(tb.get_global_rect().get_center())
	check("clicking Change Tera type opens the picker", menu.gacha_result.visible)
	menu._go_back()
	await process_frame
	# a real finger still switches to touch
	var t := InputEventScreenTouch.new()
	t.pressed = true
	t.device = 0
	check("a real touch still switches to touch", INP.feed(t) and INP.mode == "touch")
	INP.mode = "kb"
	# mode select: a difficulty button and a mode card by mouse
	menu._show("modes")
	for i in range(6):
		await process_frame
	var hard = menu.mp_opts.find_child("Diff_hard", true, false)
	await click(hard.get_global_rect().get_center())
	check("clicking Hard chooses it", load("res://scripts/difficulty.gd").chosen() == "hard")
	await click(menu.mode_tiles["rush"].get_global_rect().get_center())
	check("clicking a mode card selects it", menu.modes_sel == "rush")
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
