extends SceneTree
# Headless check of the Kecleon shop with a gamepad: Confirm buys, Back / Start close, a custom (Nintendo) layout works,
# an item you cannot afford gives feedback, and Android's Back request closes the shop instead of pausing behind it.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _pad(b: int) -> void:
	for pr in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		e.pressed = pr
		e.device = 0
		Input.parse_input_event(e)

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var PAD = load("res://scripts/pad.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(20):
		await process_frame
	m.run_time = 400.0
	for layout in [0, 2]:
		SV.d["settings"]["pad"] = layout
		SV.d["settings"].erase("padmap")
		PAD.apply()
		var name_l: String = "Xbox layout" if layout == 0 else "Nintendo layout"
		# ---------- can afford: Confirm buys ----------
		m.coins = 100000
		m.kec.spawn(func(p): return true, "blue")
		await process_frame
		m.player.position = m.kec.active.position + Vector2(10, 0)
		m.kec.open_ui()
		for i in range(4):
			await process_frame
		var fo = m.get_viewport().gui_get_focus_owner()
		check("%s: the first item you can afford is highlighted" % name_l, fo is Button and not (fo as Button).disabled and m.kec.ui_btns.has(fo))
		_pad(PAD.btn("confirm"))
		for i in range(5):
			await process_frame
		check("%s: Confirm buys the highlighted item" % name_l, m.kec.bought and m.coins < 100000, str(m.coins))
		_pad(PAD.btn("cancel"))
		for i in range(5):
			await process_frame
		check("%s: Back closes the shop" % name_l, m.kec.ui == null and not m.shop_open)
		m.kec.depart()
		await process_frame
		# ---------- cannot afford: feedback and Close ----------
		m.coins = 0
		m.kec.spawn(func(p): return true, "blue")
		await process_frame
		m.kec.open_ui()
		for i in range(4):
			await process_frame
		var fo2 = m.get_viewport().gui_get_focus_owner()
		check("%s: with no coins the Close button is highlighted" % name_l, fo2 is Button and (fo2 as Button).text == m.L.t("Close"), str((fo2 as Button).text if fo2 is Button else ""))
		(m.kec.ui_btns[0] as Button).grab_focus()
		await process_frame
		_pad(PAD.btn("confirm"))
		for i in range(4):
			await process_frame
		check("%s: Confirm on an item you cannot afford says so" % name_l, m.kec.ui != null and not m.kec.bought and String(m.kec.ui_info.text) == m.L.t("Not enough coins"), String(m.kec.ui_info.text))
		_pad(PAD.btn("pause"))
		for i in range(4):
			await process_frame
		check("%s: Start closes the shop" % name_l, m.kec.ui == null)
		m.kec.depart()
		await process_frame
	# ---------- Android Back ----------
	m.coins = 500
	m.kec.spawn(func(p): return true, "green")
	await process_frame
	m.kec.open_ui()
	await process_frame
	m.paused = false
	m._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	check("Android Back closes the shop and does not pause behind it", m.kec.ui == null and not m.paused)
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
