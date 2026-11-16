extends HBoxContainer
# The Wardrobe screen (docs/wardrobe.md, roadmap step 57): a live stage on the left (your partner walking a loop with the
# equipped trail and aura, and a HUD card in the equipped frame), the items on the right in three tabs (Trails, Auras,
# HUD frames; LB / RB or Q / E). Each item card plays its own effect. Press an owned item to equip it (press the equipped
# trail or aura again, or None, to take it off); a locked one says where it is earned. Built by menu.gd (_build_wardrobe).
const SV = preload("res://scripts/save_data.gd")
const WR = preload("res://scripts/wardrobe.gd")
const L = preload("res://scripts/lang.gd")
const UIS = preload("res://scripts/ui_style.gd")
const Aud = preload("res://scripts/audio.gd")

var m   # the menu
var kind := "trail"
var tabs: Dictionary = {}
var grid: GridContainer
var cards: Array = []
var stage: Stage
var info: Label
var first: Button = null


# One item's own effect, looping, inside its card (or the big stage when big = true).
class FxView extends Control:
	var item := ""
	var kind := ""
	var t := 0.0
	var bits: Array = []
	var _seed := 0
	var _acc := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _process(delta: float) -> void:
		t += delta
		if kind == "trail" and item != "":
			_acc += delta
			while _acc > 0.045:
				_acc -= 0.045
				_seed += 1
				bits.append([_path(t), t, _seed])
			while not bits.is_empty() and t - float(bits[0][1]) > 0.9:
				bits.pop_front()
		queue_redraw()

	func _path(tt: float) -> Vector2:   # left to right across the card, with a little wave
		return Vector2(size.x * (0.08 + 0.84 * fposmod(tt * 0.5, 1.0)), size.y * (0.5 + 0.18 * sin(tt * 5.0)))

	func _draw() -> void:
		if item == "":
			return
		match kind:
			"trail":
				for b in bits:
					if (b[0] as Vector2).x <= _path(t).x + 2.0:   # not the bits left behind when the loop restarts
						WR.draw_trail_bit(self, item, b[0], clampf((t - float(b[1])) / 0.9, 0.0, 1.0), int(b[2]), 1.4)
				draw_circle(_path(t), 6.0, Color(1, 1, 1, 0.9))
			"aura":
				var fc := Vector2(size.x * 0.5, size.y * 0.78)
				WR.draw_aura(self, item, fc, minf(size.x * 0.32, 40.0), t)
				draw_rect(Rect2(fc + Vector2(-11.0, -38.0), Vector2(22.0, 38.0)), Color(1, 1, 1, 0.22))
			"frame":
				var r := Rect2(size * Vector2(0.12, 0.2), size * Vector2(0.76, 0.6))
				draw_rect(r, Color(UIS.BG, 0.95))
				draw_rect(r, UIS.EDGE, false, 2.0)
				if item != "classic":
					WR.draw_frame(self, item, r, t)


# The big stage: your partner walking a loop with the equipped trail and aura; a HUD card in the equipped frame below.
class Stage extends Control:
	var m
	var pv: Control = null
	var t := 0.0
	var bits: Array = []
	var _seed := 0
	var _last := Vector2.INF
	var _acc := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func set_partner(menu) -> void:
		m = menu
		if pv != null:
			pv.queue_free()
		pv = load("res://scripts/menu.gd").Preview.new()
		pv.custom_minimum_size = Vector2(120, 110)
		pv.size = Vector2(120, 110)
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pv)
		pv.walk = true
		var dex: int = int(SV.d.get("selected", 25))
		pv.setup(dex, SV.shiny_wanted(dex), 3.0)

	func _feet(tt: float) -> Vector2:
		var h: float = size.y - 120.0
		return Vector2(size.x * (0.5 + 0.3 * sin(tt * 0.7)), 30.0 + h * (0.55 + 0.25 * sin(tt * 1.4)))   # a figure eight

	func _process(delta: float) -> void:
		t += delta
		var feet: Vector2 = _feet(t)
		var tr: String = WR.equipped("trail")
		if tr != "" and size.x > 10.0:
			if _last == Vector2.INF or _last.distance_to(feet) > 120.0:   # first frame or a resize: start here, no streak
				_last = feet
			_acc += delta
			while _acc > 0.05:   # by time, not distance: the stage walk is slow, and the trail should still read
				_acc -= 0.05
				_seed += 1
				bits.append([feet + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0)), t, _seed])
			_last = feet
		while not bits.is_empty() and t - float(bits[0][1]) > 0.9:
			bits.pop_front()
		if pv != null:
			pv.position = feet - Vector2(pv.size.x * 0.5, pv.size.y * 0.92)
			var d: Vector2 = _feet(t + 0.05) - feet
			pv.set("row", _dir_row(d))
		queue_redraw()

	static func _dir_row(d: Vector2) -> int:
		# sheet rows: 0 down, 1 down-right, 2 right, 3 up-right, 4 up, 5 up-left, 6 left, 7 down-left
		var a: float = fposmod(atan2(d.x, d.y), TAU)
		return int(round(a / (TAU / 8.0))) % 8

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#3f6b35"))
		for i in range(14):   # a few grass speckles, so it reads as ground
			var q := Vector2(fposmod(float(i) * 97.0, size.x), fposmod(float(i) * 53.0 + 20.0, size.y - 100.0))
			draw_rect(Rect2(q, Vector2(3, 3)), Color("#4f8a45"))
		var au: String = WR.equipped("aura")
		if au != "":
			WR.draw_aura(self, au, _feet(t), 26.0, t)
		var tr: String = WR.equipped("trail")
		for b in bits:
			WR.draw_trail_bit(self, tr, b[0], clampf((t - float(b[1])) / 0.9, 0.0, 1.0), int(b[2]), 1.3)
		# the HUD card in the equipped frame
		var r := Rect2(Vector2(16.0, size.y - 92.0), Vector2(232.0, 76.0))
		draw_rect(r, Color(UIS.BG, 0.95))
		draw_rect(r, UIS.EDGE, false, 2.0)
		var fr: String = WR.equipped("frame")
		if fr != "classic":
			WR.draw_frame(self, fr, r, t)
		var font: Font = ThemeDB.fallback_font
		var dex: int = int(SV.d.get("selected", 25))
		var nm: String = L.t(String(SV.dex_by[dex]["name"])) if SV.dex_by.has(dex) else ""
		draw_string(font, r.position + Vector2(12, 24), nm, HORIZONTAL_ALIGNMENT_LEFT, 200.0, 17, UIS.TITLE)
		draw_rect(Rect2(r.position + Vector2(12, 32), Vector2(206, 14)), UIS.INK)
		draw_rect(Rect2(r.position + Vector2(14, 34), Vector2(160, 10)), Color("#6fd08a"))
		draw_string(font, r.position + Vector2(12, 66), L.t("Lv. %d") % 12, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UIS.WAVE)


func setup(menu) -> void:
	m = menu
	add_theme_constant_override("separation", 16)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	# left: the stage
	var lp := PanelContainer.new()
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.size_flags_stretch_ratio = 0.9
	lp.add_theme_stylebox_override("panel", UIS.box(Color(0, 0, 0, 0.35), UIS.EDGE, 3, false))
	add_child(lp)
	stage = Stage.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lp.add_child(stage)
	# right: title, tabs, items, info line
	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 10)
	add_child(rv)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	rv.add_child(head)
	var tl: Label = m._lnw("Wardrobe", 32, UIS.GOLD)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	for k in WR.KINDS:
		var kk: String = String(k)
		var tb: Button = m._btn(L.t(String(WR.KIND_NAME[kk])), func(): set_kind(kk), Vector2(0, 44))
		tb.name = "Tab_" + kk
		tb.add_theme_font_size_override("font_size", 18)
		head.add_child(tb)
		tabs[kk] = tb
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.follow_focus = true
	rv.add_child(sc)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	info = m._label("", 17, UIS.TEXT)
	info.custom_minimum_size = Vector2(0, 48)
	rv.add_child(info)


func set_kind(k: String) -> void:
	kind = k
	refresh()
	if not cards.is_empty():
		cards[0].grab_focus()


func refresh(keep: String = "") -> void:
	if stage.pv == null:
		stage.set_partner(m)
	for c in grid.get_children():
		grid.remove_child(c)   # out of the grid now, so the new cards keep their names (Item_<id>)
		c.queue_free()
	cards.clear()
	for k in tabs:
		m._gold_btn(tabs[k], k == kind)
	var ids: Array = WR.ORDER.filter(func(i): return WR.kind_of(i) == kind)
	if kind != "frame":
		ids.push_front("")   # None
	var eq: String = WR.equipped(kind)
	var newl: Array = WR.data()["new"]
	first = null
	for id in ids:
		var iid: String = String(id)
		var owned: bool = iid == "" or WR.owns(iid)
		var b := Button.new()
		b.name = "Item_" + (iid if iid != "" else "none")
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(0, 150)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_contents = true
		var on: bool = iid == eq
		m._lift_btn(b, Color("#3b3466") if on else UIS.PANEL, UIS.GOLD if on else UIS.EDGE)
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 8
		v.offset_right = -8
		v.offset_top = 6
		v.offset_bottom = -6
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var fv := FxView.new()
		fv.item = iid   # locked items play too, dimmed: you see what you would earn
		fv.kind = kind
		fv.custom_minimum_size = Vector2(0, 74)
		fv.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fv.modulate = Color(1, 1, 1, 1.0 if owned else 0.35)
		v.add_child(fv)
		var nm: String = L.t("None") if iid == "" else L.t(String(WR.ITEMS[iid][1]))
		var nl: Label = m._lnw(nm + ("  •" if newl.has(iid) else ""), 19, UIS.TITLE if owned else UIS.MUTED)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nl)
		var st: String = L.t("Equipped") if on else (L.t("Locked") if not owned else "")
		var sl: Label = m._lnw(st, 16, UIS.GOLD if on else UIS.MUTED)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(sl)
		b.pressed.connect(func(): _press(iid))
		b.focus_entered.connect(func(): _describe(iid))
		b.mouse_entered.connect(func(): _describe(iid))
		grid.add_child(b)
		cards.append(b)
		if first == null or on:
			first = b
	if keep != "":
		var kb: Node = grid.find_child(keep, false, false)
		if kb is Button:
			first = kb
	_describe(eq)
	if is_visible_in_tree() and first != null:
		first.call_deferred("grab_focus")


func _describe(id: String) -> void:
	if id == "":
		info.text = L.t("No trail") if kind == "trail" else (L.t("No aura") if kind == "aura" else "")
		return
	var nm: String = L.t(String(WR.ITEMS[id][1]))
	info.text = (nm + " · " + L.t("Equipped")) if WR.equipped(kind) == id else (nm + " · " + (L.t("Owned: press to wear it") if WR.owns(id) else WR.source_text(id, L)))


func _press(id: String) -> void:
	if id != "" and not WR.owns(id):
		Aud.sfx("error")
		m.toast(WR.source_text(id, L))
		return
	var now: String = WR.equipped(kind)
	if id == now and kind != "frame":
		id = ""   # pressing the equipped trail or aura again takes it off
	WR.equip(kind, id)
	SV.save()
	Aud.sfx("confirm")
	refresh("Item_" + (id if id != "" else "none"))


# Controller / keyboard: LB / RB (Q / E) switch tabs; the grid and the tabs are rows; nothing outside the screen.
func nav(event: InputEvent) -> bool:
	var PAD = load("res://scripts/pad.gd")
	var prev: bool = (event is InputEventJoypadButton and event.pressed and event.button_index == PAD.btn("prev")) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q)
	var next: bool = (event is InputEventJoypadButton and event.pressed and event.button_index == PAD.btn("next")) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E)
	if prev or next:
		var i: int = WR.KINDS.find(kind)
		set_kind(String(WR.KINDS[posmod(i + (-1 if prev else 1), WR.KINDS.size())]))
		Aud.sfx("click")
		return true
	var side := -1
	if event.is_action_pressed("ui_left", true):
		side = SIDE_LEFT
	elif event.is_action_pressed("ui_right", true):
		side = SIDE_RIGHT
	elif event.is_action_pressed("ui_up", true):
		side = SIDE_TOP
	elif event.is_action_pressed("ui_down", true):
		side = SIDE_BOTTOM
	if side < 0:
		return false
	var f: Control = get_viewport().gui_get_focus_owner()
	var tl: Array = []
	for k in WR.KINDS:
		tl.append(tabs[k])
	var to: Control = f
	var cols: int = grid.columns
	var ci: int = cards.find(f)
	if ci >= 0:
		if side == SIDE_LEFT:
			to = cards[ci - 1] if ci % cols > 0 else f
		elif side == SIDE_RIGHT:
			to = cards[ci + 1] if ci % cols < cols - 1 and ci + 1 < cards.size() else f
		elif side == SIDE_TOP:
			to = cards[ci - cols] if ci >= cols else tabs[kind]
		else:
			to = cards[ci + cols] if ci + cols < cards.size() else (cards[cards.size() - 1] if ci / cols < (cards.size() - 1) / cols else f)
	elif tl.has(f):
		var ti: int = tl.find(f)
		if side == SIDE_LEFT:
			to = tl[maxi(0, ti - 1)]
		elif side == SIDE_RIGHT:
			to = tl[mini(tl.size() - 1, ti + 1)]
		elif side == SIDE_BOTTOM:
			to = first if first != null else (cards[0] if not cards.is_empty() else f)
	else:
		to = first if first != null else tl[0]
	if to != null and to != f:
		to.grab_focus()
		Aud.sfx("hover")
	return true
