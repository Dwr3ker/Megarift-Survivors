extends Control
# HUD layout editor (Settings > Graphics > Edit HUD layout). A stage shows each on-run HUD element as a box where it sits in a run:
# drag it with the mouse or a finger, nudge it with the arrow keys or the controller's right stick, resize it with the slider
# (or L1/R1), switch the radar and the stats panel on or off, and save the result as a named preset.
const HL = preload("res://scripts/hud_layout.gd")
const L = preload("res://scripts/lang.gd")
const DSP = preload("res://scripts/display.gd")
const PAD = preload("res://scripts/pad.gd")
const SV = preload("res://scripts/save_data.gd")

const COLORS := {"plate": Color("#5fd08a"), "radar": Color("#5fb4ff"), "stats": Color("#ffd65c"), "items": Color("#ff8ad8"), "counters": Color("#ffb347"), "skills": Color("#b48aff")}
const KEY_STEP := 4.0
const STICK_SPEED := 320.0

var m   # the menu (for its button and label helpers)
var sel := "plate"
var stage: Control
var size_slider: HSlider
var size_lbl: Label
var preset_pick: OptionButton
var name_in: LineEdit
var map_btn: CheckButton
var stats_btn: CheckButton
var el_btns: Dictionary = {}
var _drag := false
var _grab := Vector2.ZERO
var _dirty := false
var _vp := Vector2(1280.0, 720.0)
var _ins := Vector4.ZERO


func build(menu) -> void:
	m = menu
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	stage = Control.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.focus_mode = Control.FOCUS_ALL
	stage.clip_contents = true
	stage.draw.connect(_draw_stage)
	stage.gui_input.connect(_stage_input)
	row.add_child(stage)
	var side_scroll := ScrollContainer.new()
	side_scroll.custom_minimum_size = Vector2(340, 0)
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(side_scroll)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 6)
	side_scroll.add_child(side)
	side.add_child(m._label(L.t("HUD layout"), 30, m.C_GOLD))
	side.add_child(m._label(L.t("Drag a box, or pick it below and use the arrow keys or the right stick. L1 / R1 change its size."), 15, Color("#f2e9d8")))
	for id in HL.IDS:
		var sid: String = String(id)
		var b: Button = m._btn(L.t(String(HL.NAMES[sid])), func(): _select(sid), Vector2(0, 40))
		side.add_child(b)
		el_btns[sid] = b
	var srow := HBoxContainer.new()
	side.add_child(srow)
	size_lbl = m._label("", 18)
	size_lbl.custom_minimum_size = Vector2(70, 0)
	srow.add_child(size_lbl)
	size_slider = HSlider.new()
	size_slider.min_value = HL.S_MIN
	size_slider.max_value = HL.S_MAX
	size_slider.step = 5
	size_slider.custom_minimum_size = Vector2(0, 30)
	size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_slider.value_changed.connect(_on_size)
	srow.add_child(size_slider)
	side.add_child(m._btn(L.t("Reset this element"), func(): HL.reset_el(sel); _sync(); _commit(), Vector2(0, 40)))
	map_btn = CheckButton.new()
	map_btn.text = L.t("Show radar")
	map_btn.toggled.connect(func(on: bool): HL.set_show_map(on); _commit(); stage.queue_redraw())
	side.add_child(map_btn)
	stats_btn = CheckButton.new()
	stats_btn.text = L.t("Show stats panel")
	stats_btn.toggled.connect(func(on: bool): SV.d["settings"]["stats_box"] = on; _commit(); stage.queue_redraw())
	side.add_child(stats_btn)
	side.add_child(m._label(L.t("Presets"), 22, m.C_GOLD))
	preset_pick = OptionButton.new()
	preset_pick.custom_minimum_size = Vector2(0, 40)
	side.add_child(preset_pick)
	var prow := HBoxContainer.new()
	side.add_child(prow)
	var lb: Button = m._btn(L.t("Load"), func(): _load_preset(), Vector2(0, 40))
	lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prow.add_child(lb)
	var db: Button = m._btn(L.t("Delete"), func(): _delete_preset(), Vector2(0, 40))
	db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prow.add_child(db)
	name_in = LineEdit.new()
	name_in.placeholder_text = L.t("Preset name")
	name_in.max_length = 20
	name_in.custom_minimum_size = Vector2(0, 40)
	side.add_child(name_in)
	side.add_child(m._btn(L.t("Save as preset"), func(): _save_preset(), Vector2(0, 40)))
	side.add_child(m._btn(L.t("Reset all"), func(): HL.reset_all(); _sync(); _commit(), Vector2(0, 40)))
	refresh()


func refresh() -> void:
	_vp = get_viewport_rect().size
	_ins = DSP.insets(get_tree())
	_sync()


func _sync() -> void:
	var e: Dictionary = HL.layout()[sel]
	size_slider.set_value_no_signal(float(int(e["s"])))
	size_lbl.text = "%d%%" % int(e["s"])
	map_btn.set_pressed_no_signal(HL.show_map())
	stats_btn.set_pressed_no_signal(bool(SV.d["settings"].get("stats_box", true)))
	for id in el_btns:
		(el_btns[id] as Button).modulate = Color(1, 1, 1) if id == sel else Color(0.78, 0.78, 0.9)
	_fill_presets()
	stage.queue_redraw()


func _fill_presets() -> void:
	preset_pick.clear()
	var names: Array = HL.preset_names()
	if names.is_empty():
		preset_pick.add_item(L.t("(no presets yet)"))
		preset_pick.disabled = true
		return
	preset_pick.disabled = false
	var cur := 0
	for i in range(names.size()):
		preset_pick.add_item(String(names[i]))
		if String(names[i]) == HL.active_preset():
			cur = i
	preset_pick.select(cur)


func _select(id: String) -> void:
	sel = id
	_sync()


func _on_size(v: float) -> void:
	var e: Dictionary = HL.layout()[sel]
	HL.set_el(sel, Vector2(float(e["x"]), float(e["y"])), int(v))
	size_lbl.text = "%d%%" % int(v)
	_commit()
	stage.queue_redraw()


func _commit() -> void:
	SV.save()
	_dirty = false


func _load_preset() -> void:
	if preset_pick.disabled:
		return
	if HL.load_preset(preset_pick.get_item_text(preset_pick.selected)):
		_sync()
		_commit()
		m.toast(L.t("Preset loaded"))


func _delete_preset() -> void:
	if preset_pick.disabled:
		return
	if HL.delete_preset(preset_pick.get_item_text(preset_pick.selected)):
		_sync()
		_commit()
		m.toast(L.t("Preset deleted"))


func _save_preset() -> void:
	var n: String = HL.clean_name(name_in.text)
	if n == "":
		n = HL.active_preset() if HL.active_preset() != "" else "Preset %d" % (HL.preset_names().size() + 1)
	if HL.save_preset(n):
		name_in.text = ""
		_sync()
		_commit()
		m.toast(L.t("Preset saved: %s") % n)
	else:
		m.toast(L.t("Too many presets: delete one first"))


# ---- stage geometry ----
func _k() -> float:
	return minf(stage.size.x / _vp.x, stage.size.y / _vp.y)


func _origin() -> Vector2:
	return (stage.size - _vp * _k()) * 0.5


func _box(id: String) -> Rect2:   # in virtual pixels
	var d: Rect2 = HL.default_rect(id, _vp, _ins)
	var s: float = HL.scale_of(id)
	return Rect2(d.position + HL.offset(id), d.size * s)


func _to_stage(r: Rect2) -> Rect2:
	var k := _k()
	return Rect2(_origin() + r.position * k, r.size * k)


func _hidden(id: String) -> bool:
	return (id == "radar" and not HL.show_map()) or (id == "stats" and not bool(SV.d["settings"].get("stats_box", true)))


func _draw_stage() -> void:
	var font := ThemeDB.fallback_font
	var k := _k()
	var o := _origin()
	stage.draw_rect(Rect2(Vector2.ZERO, stage.size), Color("#0c0a18"))
	stage.draw_rect(Rect2(o, _vp * k), Color("#1d3a26"))
	for gx in range(0, int(_vp.x), 64):
		stage.draw_line(o + Vector2(gx, 0) * k, o + Vector2(gx, _vp.y) * k, Color(1, 1, 1, 0.05))
	for gy in range(0, int(_vp.y), 64):
		stage.draw_line(o + Vector2(0, gy) * k, o + Vector2(_vp.x, gy) * k, Color(1, 1, 1, 0.05))
	stage.draw_rect(Rect2(o, Vector2(_vp.x * k, 12.0 * k)), Color("#5fb4ff", 0.8))   # the XP strip
	stage.draw_string(font, o + Vector2(0.0, 36.0 * k), "12:34", HORIZONTAL_ALIGNMENT_CENTER, _vp.x * k, int(28.0 * k), Color(1, 1, 1, 0.55))
	stage.draw_circle(o + _vp * k * 0.5, 14.0 * k, Color("#ffd65c", 0.7))
	for id in HL.IDS:
		var r: Rect2 = _to_stage(_box(String(id)))
		var col: Color = COLORS[id]
		var hid: bool = _hidden(String(id))
		stage.draw_rect(r, Color(col, 0.10 if hid else 0.30))
		stage.draw_rect(r, Color(col, 0.35 if hid else 1.0), false, 3.0 if id == sel else 1.5)
		var label: String = L.t(String(HL.NAMES[id])) + (" (" + L.t("off") + ")" if hid else "")
		stage.draw_string(font, r.position + Vector2(6.0, 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 8.0, 14, Color(1, 1, 1, 0.45 if hid else 0.95))
	if stage.has_focus():
		stage.draw_rect(Rect2(Vector2.ZERO, stage.size), Color("#ffd65c"), false, 2.0)


func _pick_at(p: Vector2) -> String:
	if _to_stage(_box(sel)).has_point(p):
		return sel   # the selected box wins where boxes overlap
	for i in range(HL.IDS.size() - 1, -1, -1):   # later elements draw on top
		var id: String = String(HL.IDS[i])
		if _to_stage(_box(id)).has_point(p):
			return id
	return ""


func _stage_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			stage.grab_focus()
			var id: String = _pick_at(event.position)
			if id != "":
				if id != sel:
					_select(id)
				_drag = true
				_grab = (event.position - _origin()) / _k() - (HL.default_rect(sel, _vp, _ins).position + HL.offset(sel))
		else:
			if _drag:
				_commit()
			_drag = false
		stage.accept_event()
	elif event is InputEventMouseMotion and _drag:
		var pos: Vector2 = (event.position - _origin()) / _k() - _grab
		_set_pos(pos)
		stage.accept_event()
	elif event is InputEventKey and event.pressed and stage.has_focus():
		var step: float = KEY_STEP * (4.0 if event.shift_pressed else 1.0)
		var d := Vector2.ZERO
		match event.keycode:
			KEY_LEFT:
				d.x = -step
			KEY_RIGHT:
				d.x = step
			KEY_UP:
				d.y = -step
			KEY_DOWN:
				d.y = step
			KEY_PAGEUP:
				_resize(5)
			KEY_PAGEDOWN:
				_resize(-5)
		if d != Vector2.ZERO:
			_nudge(d)
			stage.accept_event()


# Position the selected element's top-left at `pos` (virtual pixels), keeping some of it on screen.
func _set_pos(pos: Vector2) -> void:
	var def: Rect2 = HL.default_rect(sel, _vp, _ins)
	var s: float = HL.scale_of(sel)
	var sz: Vector2 = def.size * s
	var p := Vector2(clampf(pos.x, -sz.x + 48.0, _vp.x - 48.0), clampf(pos.y, 0.0, _vp.y - 24.0))
	HL.set_el(sel, p - def.position, int((HL.layout()[sel] as Dictionary)["s"]))
	_dirty = true
	stage.queue_redraw()


func _nudge(d: Vector2) -> void:
	var def: Rect2 = HL.default_rect(sel, _vp, _ins)
	_set_pos(def.position + HL.offset(sel) + d)


func _resize(delta_pct: int) -> void:
	var e: Dictionary = HL.layout()[sel]
	HL.set_el(sel, Vector2(float(e["x"]), float(e["y"])), int(e["s"]) + delta_pct)
	_sync()
	_commit()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == PAD.btn("prev"):
			_resize(-5)
			get_viewport().set_input_as_handled()
		elif event.button_index == PAD.btn("next"):
			_resize(5)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		return
	var v := Vector2(Input.get_joy_axis(int(pads[0]), JOY_AXIS_RIGHT_X), Input.get_joy_axis(int(pads[0]), JOY_AXIS_RIGHT_Y))
	if v.length() > 0.3:
		_nudge(v * STICK_SPEED * delta)
	elif _dirty:
		_commit()
