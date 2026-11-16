extends SceneTree
# The HUD and menus follow the input you are using: a key or the mouse = keyboard hints, a controller button or stick
# = controller hints, a touch = no hints. Touch-emulated mouse events don't count as a mouse.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var INP = load("res://scripts/input_mode.gd")
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["nick"] = "Tester"
	SV.d["owned"]["25"] = {"n": 1}
	SV.d["owned"]["6"] = {"n": 1}
	var k := InputEventKey.new()
	k.keycode = KEY_A
	k.pressed = true
	var jb := InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_A
	jb.pressed = true
	var jm := InputEventJoypadMotion.new()
	jm.axis = JOY_AXIS_LEFT_X
	jm.axis_value = 0.9
	var tc := InputEventScreenTouch.new()
	tc.pressed = true
	var em := InputEventMouseButton.new()
	em.pressed = true
	em.button_index = MOUSE_BUTTON_LEFT
	em.device = InputEvent.DEVICE_ID_EMULATION
	INP.feed(k)
	check("a key: keyboard mode", INP.current() == "kb")
	check("a controller button switches to controller mode", INP.feed(jb) and INP.current() == "pad")
	INP.feed(k)
	check("a stick push switches to controller mode", INP.feed(jm) and INP.current() == "pad")
	check("a touch switches to touch mode", INP.feed(tc) and INP.current() == "touch")
	check("a touch-emulated mouse click doesn't count as a mouse", not INP.feed(em) and INP.current() == "touch")
	# the Pokédex details rebuild their controller hint when you switch
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu.dex_sel = 6
	menu._show("dex")
	for i in range(4):
		await process_frame
	menu.dex_sel = 6
	INP.feed(jb)
	menu._dex_detail()
	await process_frame
	var choose: Button = null
	for b in menu.dex_foot.find_children("*", "Button", true, false) + menu.dex_detail.find_children("*", "Button", true, false):
		if b.text == menu.L.t("Choose"):
			choose = b
	check("controller: the Choose button shows the controller button", choose != null and choose.icon != null)
	menu._input(k)
	for i in range(3):
		await process_frame
	choose = null
	for b in menu.dex_foot.find_children("*", "Button", true, false) + menu.dex_detail.find_children("*", "Button", true, false):
		if b.text == menu.L.t("Choose"):
			choose = b
	check("keyboard: the details rebuild without the controller icon", choose != null and choose.icon == null)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
