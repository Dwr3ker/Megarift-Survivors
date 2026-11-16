extends SceneTree
# Roadmap step 5: the TERA button fills with the orb and lights up when charged; T on the keyboard, the Y + RT chord
# and a tapped button start it; the key and a single controller button can be rebound. Controller chords:
# X + LT Z-Move, X + RT Dynamax, Y + RT Tera; X or Y alone does nothing in a run.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _run(SV):
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	m.player.invuln = 1.0e9
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	return m

func _key(m, code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	m._unhandled_input(ev)

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var PAD = load("res://scripts/pad.gd")
	var KEYS = load("res://scripts/keys.gd")
	var TERA = load("res://scripts/tera.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.d["stats"]["dens"] = 1
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	check("default chords: X+LT Z-Move, X+RT Dynamax, Y+RT Tera", PAD.chord_name("zmove") == "X+LT" and PAD.chord_name("dynamax") == "X+RT" and PAD.chord_name("tera") == "Y+RT")
	check("X alone is no longer Dynamax", PAD.btn("dynamax") != JOY_BUTTON_X)
	check("T is the Tera key", KEYS.key("tera") == KEY_T)
	var m = await _run(SV)
	m.tera_pts = 120.0
	await process_frame
	check("charging: the TERA button shows and fills", m.hud.tera_btn == 1 and is_equal_approx(m.hud.tera_frac, 0.4), "%d %.2f" % [m.hud.tera_btn, m.hud.tera_frac])
	_key(m, KEY_T)
	await process_frame
	check("not charged: T does nothing", not m.tera_used)
	m.tera_pts = TERA.NEED
	await process_frame
	check("charged: the button lights up", m.hud.tera_btn == 2)
	var xb := InputEventJoypadButton.new()
	xb.button_index = JOY_BUTTON_X
	xb.pressed = true
	m.run_time = 400.0
	m._unhandled_input(xb)
	await process_frame
	check("X alone does not start Dynamax", not m._dyn_on())
	_key(m, KEY_T)
	await process_frame
	check("T Terastallizes", m.tera_used and m.tera_t > 0.0)
	await process_frame
	check("the button then shows the time left", m.hud.tera_btn == 3)
	m.queue_free()
	await process_frame
	# controller chord
	var r = await _run(SV)
	r.tera_pts = TERA.NEED
	r._chords_tick({"tera": true})
	check("Y + RT Terastallizes", r.tera_used)
	r.queue_free()
	await process_frame
	# tapping the button
	var t = await _run(SV)
	t.tera_pts = TERA.NEED
	await process_frame
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = t.hud.tera_rect().get_center()
	t._unhandled_input(tap)
	await process_frame
	check("tapping the button Terastallizes", t.tera_used)
	t.queue_free()
	await process_frame
	# rebinding
	KEYS.set_key("tera", KEY_G)
	PAD.set_btn("tera", JOY_BUTTON_LEFT_SHOULDER)
	var b = await _run(SV)
	b.tera_pts = TERA.NEED
	_key(b, KEY_T)
	await process_frame
	check("after rebinding, T no longer does it", not b.tera_used)
	var lb := InputEventJoypadButton.new()
	lb.button_index = JOY_BUTTON_LEFT_SHOULDER
	lb.pressed = true
	b._unhandled_input(lb)
	await process_frame
	check("the rebound controller button Terastallizes", b.tera_used)
	b.tera_used = false
	b.tera_t = 0.0
	_key(b, KEY_G)
	await process_frame
	check("the rebound key Terastallizes", b.tera_used)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
