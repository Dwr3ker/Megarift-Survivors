extends SceneTree
# Power combinations (pad.gd chord, Settings > Controls): defaults X + LT / X + RT / Y + RT; set by holding any two inputs
# (a button and a trigger, or two buttons: some controllers send L2 / R2 as buttons); in a run, a button that is half of
# a combination and also has its own action (Select = Build summary) only does that on a short tap with no combination.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func btn(b: int, down: bool) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = down
	return e

func trig(axis: int, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = v
	return e

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var PAD = load("res://scripts/pad.gd")
	SV.ensure()
	SV.load_dex()
	SV.d = SV.default_data()
	SV.d["nick"] = "Ash"
	SV.add_owned(4)
	SV.d["selected"] = 4
	PAD.reset(0)
	check("defaults: Tera = Y + RT, Z-Move = X + LT", PAD.chord("tera") == [JOY_BUTTON_Y, PAD.TRIG + JOY_AXIS_TRIGGER_RIGHT] and PAD.chord("zmove") == [JOY_BUTTON_X, PAD.TRIG + JOY_AXIS_TRIGGER_LEFT])
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("settings")
	for i in range(4):
		await process_frame
	var ti: int = menu.SET_TABS.find("Controls")
	if ti < 0:
		for i in range(menu.SET_TABS.size()):
			if String(menu.SET_TABS[i]).to_lower().contains("control"):
				ti = i
	menu.set_tab = ti
	menu._refresh_settings()
	for i in range(4):
		await process_frame
	var row: Button = menu.screens["settings"].find_child("Chord_tera", true, false)
	check("Settings > Controls lists the power combinations", row != null and row.text.contains("+"), row.text if row != null else "none")
	row.pressed.emit()
	await process_frame
	check("pressing it waits for two buttons", menu.listening == "chord:tera")
	menu._input(btn(JOY_BUTTON_BACK, true))   # e.g. a controller whose L2 arrives as the Select button
	check("one input held: still waiting, shows it", menu.listening == "chord:tera" and PAD.chord("tera") == [JOY_BUTTON_Y, PAD.TRIG + JOY_AXIS_TRIGGER_RIGHT])
	menu._input(trig(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	check("a button + a trigger held together: that is the combination", PAD.chord("tera") == [JOY_BUTTON_BACK, PAD.TRIG + JOY_AXIS_TRIGGER_RIGHT] and menu.listening == "", str(PAD.chord("tera")))
	menu._input(btn(JOY_BUTTON_BACK, false))
	menu._input(trig(JOY_AXIS_TRIGGER_RIGHT, 0.0))
	await process_frame
	var row2: Button = menu.screens["settings"].find_child("Chord_zmove", true, false)
	row2.pressed.emit()
	await process_frame
	menu._input(btn(JOY_BUTTON_Y, true))
	menu._input(btn(JOY_BUTTON_LEFT_SHOULDER, true))
	check("two plain buttons work too", PAD.chord("zmove") == [JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER], str(PAD.chord("zmove")))
	check("the names read well", PAD.chord_name("tera") == PAD.btn_name(JOY_BUTTON_BACK) + "+RT", PAD.chord_name("tera"))
	menu._input(btn(JOY_BUTTON_Y, false))
	menu._input(btn(JOY_BUTTON_LEFT_SHOULDER, false))
	await process_frame
	var row3: Button = menu.screens["settings"].find_child("Chord_dynamax", true, false)
	row3.pressed.emit()
	await process_frame
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	menu._input(e)
	check("Esc cancels without changing it", menu.listening == "" and PAD.chord("dynamax") == [JOY_BUTTON_X, PAD.TRIG + JOY_AXIS_TRIGGER_RIGHT])
	menu.queue_free()
	await process_frame
	# ---- in a run: Select is also half of the Tera combination ----
	SV.run_dex = 4
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	while m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	m._unhandled_input(btn(JOY_BUTTON_BACK, true))
	check("holding Select (half of a combination) doesn't open the summary yet", not m.paused)
	m._unhandled_input(btn(JOY_BUTTON_BACK, false))
	check("a short tap on it does open the Build summary", m.paused and m.pause_ui.tab == 0)
	m.paused = false
	m._unhandled_input(btn(JOY_BUTTON_BACK, true))
	m._chords_tick({"tera": true})   # the combination is made while Select is held
	m._chords_tick({"tera": false})
	m._unhandled_input(btn(JOY_BUTTON_BACK, false))
	check("when the combination is made, releasing Select doesn't open the summary", not m.paused)
	PAD.reset(0)
	m.queue_free()
	for i in range(3):
		await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
