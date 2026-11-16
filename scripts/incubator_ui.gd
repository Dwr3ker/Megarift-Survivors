extends VBoxContainer
# The Incubator screen (docs/eggs.md, roadmap steps 24-25): 3 incubator slots on top, the egg bag below.
# Mouse, touch and controller all use plain Buttons:
#  - a bag egg goes into the first free slot; with the incubator full it is picked, and the next slot pressed swaps it in;
#  - an egg in a slot goes back to the bag, or hatches when it is ready (the `hatch` signal, step 26).
# Built by menu.gd (_build_eggs); `m` is the menu, for its button helpers.
signal hatch(id: int)

const SV = preload("res://scripts/save_data.gd")
const EG = preload("res://scripts/eggs.gd")
const EGA = preload("res://scripts/egg_art.gd")
const L = preload("res://scripts/lang.gd")
const UIS = preload("res://scripts/ui_style.gd")
const Aud = preload("res://scripts/audio.gd")

var m   # the menu
var sel_id := -1          # a bag egg picked to go into a slot (incubator full)
var slot_btns: Array = []
var bag_btns: Array = []
var bag_ids: Array = []
var status: Label
var bag_title: Label
var slot_row: HBoxContainer
var bag_grid: GridContainer
var first: Button = null


# The egg picture inside a button: wobbles when ready, dims when picked elsewhere.
class EggFace extends Control:
	var look := ""
	var rdy := false
	var picked := false
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		if rdy or picked:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		if look == "":
			# an empty slot: a dashed oval
			var c := size * 0.5
			var h: float = size.y * 0.42
			for i in range(24):
				if i % 2 == 0:
					var a0: float = TAU * float(i) / 24.0
					var a1: float = TAU * float(i + 1) / 24.0
					draw_line(c + Vector2(sin(a0) * h * 0.78, -cos(a0) * h), c + Vector2(sin(a1) * h * 0.78, -cos(a1) * h), Color(UIS.MUTED, 0.6), 2.0)
			return
		var rot := 0.0
		if rdy:
			var ph: float = fmod(_t, 1.6)
			rot = sin(ph * 18.0) * 0.16 * maxf(0.0, 1.0 - ph / 0.7)   # a wobble, then a pause
		var lift: float = -4.0 - sin(_t * 5.0) * 3.0 if picked else 0.0
		EGA.draw(self, size * 0.5 + Vector2(0.0, lift), size.y * 0.82, look, rot)


func setup(menu) -> void:
	m = menu
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	add_child(head)
	var tt: Label = m._label(L.t("Incubator"), 32, UIS.GOLD)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(tt)
	var sub: Label = m._label(L.t("Eggs in the incubator gain the distance you walk in your runs."), 18, UIS.MUTED)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(sub)
	slot_row = HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 14)
	slot_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_row.size_flags_stretch_ratio = 1.4
	add_child(slot_row)
	status = m._label("", 18, UIS.TEXT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size = Vector2(0, 26)
	add_child(status)
	var bag := PanelContainer.new()
	bag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bsb: StyleBoxFlat = UIS.box(Color(UIS.INK, 0.7), UIS.EDGE, 2, true)
	bsb.set_content_margin_all(10)
	bag.add_theme_stylebox_override("panel", bsb)
	add_child(bag)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	bag.add_child(bv)
	bag_title = m._label("", 20, UIS.TITLE)
	bv.add_child(bag_title)
	bag_grid = GridContainer.new()
	bag_grid.columns = 6
	bag_grid.add_theme_constant_override("h_separation", 8)
	bag_grid.add_theme_constant_override("v_separation", 8)
	bag_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bv.add_child(bag_grid)


static func _fmt_m(v: float) -> String:
	var n: int = int(floor(v))
	if n >= 1000:
		return "%d,%03d" % [n / 1000, n % 1000]
	return str(n)


func _face(look: String, ready: bool, picked: bool, minh: float) -> EggFace:
	var f := EggFace.new()
	f.look = look
	f.rdy = ready
	f.picked = picked
	f.custom_minimum_size = Vector2(0, minh)
	f.size_flags_vertical = Control.SIZE_EXPAND_FILL
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return f


func _inner(b: Button) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	b.add_child(v)
	return v


func _bar(frac: float, col: Color) -> Control:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 1.0
	pb.value = frac
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 12)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pb.add_theme_stylebox_override("background", UIS.box(UIS.INK, UIS.EDGE, 2, false))
	pb.add_theme_stylebox_override("fill", UIS.box(col, col, 0, false))
	return pb


func _small(text: String, size: int, col: Color) -> Label:
	var lb: Label = m._label(text, size, col)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.autowrap_mode = TextServer.AUTOWRAP_OFF
	lb.clip_text = true
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lb


# Rebuilds both rows. keep = the focus to restore: ["slot", i] or ["bag", i].
func refresh(keep: Array = []) -> void:
	for c in slot_row.get_children():
		c.queue_free()
	for c in bag_grid.get_children():
		c.queue_free()
	slot_btns.clear()
	bag_btns.clear()
	bag_ids.clear()
	first = null
	if sel_id >= 0 and (EG.by_id(sel_id).is_empty() or int(EG.by_id(sel_id).get("slot", -1)) >= 0):
		sel_id = -1
	for s in range(EG.SLOTS):
		var e: Dictionary = EG.in_slot(s)
		var slot: int = s
		var b: Button = m._btn("", func(): _slot_pressed(slot), Vector2(0, 200))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		m._lift_btn(b, UIS.PANEL, UIS.GOLD if EG.is_ready(e) else UIS.EDGE)
		var v: VBoxContainer = _inner(b)
		v.add_child(_small(L.t("Slot %d") % (s + 1), 16, UIS.MUTED))
		if e.is_empty():
			v.add_child(_face("", false, false, 90))
			v.add_child(_small(L.t("Empty") if sel_id < 0 else L.t("Put the egg here"), 18, UIS.MUTED if sel_id < 0 else UIS.WAVE))
		else:
			var rdy: bool = EG.is_ready(e)
			v.add_child(_face(String(e["look"]), rdy, false, 90))
			if rdy:
				v.add_child(_small(L.t("Ready to hatch!"), 20, UIS.GOLD))
			else:
				v.add_child(_small("%s / %s m" % [_fmt_m(float(e["steps"])), _fmt_m(float(e["need"]))], 18, UIS.TEXT))
			v.add_child(_bar(float(e["steps"]) / maxf(1.0, float(e["need"])), UIS.GOLD if rdy else UIS.GREEN))
		slot_row.add_child(b)
		slot_btns.append(b)
	var bag: Array = EG.eggs().filter(func(x): return int(x.get("slot", -1)) < 0)
	bag_title.text = L.t("Egg bag (%d / %d)") % [EG.count(), EG.MAX_EGGS]
	for e in bag:
		var id: int = int(e["id"])
		var b: Button = m._btn("", func(): _bag_pressed(id), Vector2(96, 104))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m._lift_btn(b, UIS.PANEL_HI if id == sel_id else UIS.PANEL, UIS.WAVE if id == sel_id else UIS.EDGE)
		var v: VBoxContainer = _inner(b)
		v.add_child(_face(String(e["look"]), false, id == sel_id, 56))
		var frac: float = float(e["steps"]) / maxf(1.0, float(e["need"]))
		v.add_child(_bar(frac, UIS.GREEN))
		bag_grid.add_child(b)
		bag_btns.append(b)
		bag_ids.append(id)
	if bag.is_empty():
		var lb: Label = m._label(L.t("No eggs in the bag. Bosses, Alphas and rescues sometimes drop one in runs.") if EG.count() == 0
			else L.t("Every egg is in the incubator."), 18, UIS.MUTED)
		lb.custom_minimum_size = Vector2(600, 0)
		bag_grid.add_child(lb)
	_status_text()
	var want: Button = null
	if keep.size() == 2:
		var arr: Array = slot_btns if String(keep[0]) == "slot" else bag_btns
		if not arr.is_empty():
			want = arr[clampi(int(keep[1]), 0, arr.size() - 1)]
	if want == null:
		want = slot_btns[0]
	first = want
	if is_visible_in_tree():
		want.call_deferred("grab_focus")


func _status_text() -> void:
	if sel_id >= 0:
		status.text = L.t("Choose a slot for this egg: it swaps with the egg there.")
		status.add_theme_color_override("font_color", UIS.WAVE)
	elif not EG.ready_eggs().is_empty():
		status.text = L.t("Oh? The egg is moving! Press it to hatch.")
		status.add_theme_color_override("font_color", UIS.GOLD)
	elif EG.count() > 0:
		status.text = L.t("Press an egg in the bag to incubate it, or an incubated egg to take it out.")
		status.add_theme_color_override("font_color", UIS.MUTED)
	else:
		status.text = ""


func _slot_pressed(slot: int) -> void:
	var e: Dictionary = EG.in_slot(slot)
	if sel_id >= 0:
		EG.place(sel_id, slot)
		sel_id = -1
		_done(["slot", slot])
		return
	if e.is_empty():
		status.text = L.t("Pick an egg from the bag to put it here.")
		return
	if EG.is_ready(e):
		hatch.emit(int(e["id"]))
		return
	EG.place(int(e["id"]), -1)   # back to the bag (its progress stays)
	_done(["slot", slot])


func _bag_pressed(id: int) -> void:
	var idx: int = bag_ids.find(id)
	if sel_id == id:   # pressed again: put it down
		sel_id = -1
		_done(["bag", idx])
		return
	var free: int = EG.free_slot()
	if free >= 0:
		EG.place(id, free)
		sel_id = -1
		_done(["bag", idx])
		return
	sel_id = id
	refresh(["slot", 0])   # the incubator is full: pick a slot to swap with


func _done(keep: Array) -> void:
	SV.save()
	refresh(keep)


# Controller B / Back while an egg is picked: drop the pick instead of leaving the screen.
func cancel_pick() -> bool:
	if sel_id < 0:
		return false
	sel_id = -1
	refresh(["bag", 0])
	return true
