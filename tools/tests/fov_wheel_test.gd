extends SceneTree
# PC: the mouse wheel changes the camera view (Options > View) during a run, within 70-250%, and not while paused.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _wheel(up: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
	e.pressed = true
	e.position = Vector2(640, 400)
	e.global_position = e.position
	Input.parse_input_event(e)
	var r := e.duplicate()
	r.pressed = false
	Input.parse_input_event(r)

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	m.player.invuln = 1.0e9
	while m.cards.open:
		m.cards.open = false
		await process_frame
	SV.d["settings"]["fov"] = 165
	m._apply_fov()
	var z0: float = m.cam.zoom.x
	_wheel(true)
	await process_frame
	await process_frame
	check("wheel up zooms in by 5%", int(SV.d["settings"]["fov"]) == 170 and m.cam.zoom.x > z0, "%d, zoom %.2f" % [int(SV.d["settings"]["fov"]), m.cam.zoom.x])
	for i in range(3):
		_wheel(false)
		await process_frame
	check("wheel down zooms out", int(SV.d["settings"]["fov"]) == 155 and m.cam.zoom.x < z0, str(SV.d["settings"]["fov"]))
	for i in range(60):
		_wheel(false)
	await process_frame
	await process_frame
	check("it stops at the slider's minimum (70%)", int(SV.d["settings"]["fov"]) == 70)
	for i in range(60):
		_wheel(true)
	await process_frame
	await process_frame
	check("and at its maximum (250%)", int(SV.d["settings"]["fov"]) == 250)
	m.get_tree().paused = true
	_wheel(false)
	await process_frame
	await process_frame
	check("the wheel does nothing while paused (menus scroll instead)", int(SV.d["settings"]["fov"]) == 250)
	m.get_tree().paused = false
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
