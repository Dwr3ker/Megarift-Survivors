extends CanvasLayer
# Menu de pausa como el del juego original: titulo, ayuda de controles, volumen de
# musica y efectos, silenciar y tres botones. Los controles son los del mando elegido.

const NAVG = preload("res://scripts/navgrid.gd")
const SV = preload("res://scripts/save_data.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")
const IC = preload("res://scripts/icons.gd")
const L = preload("res://scripts/lang.gd")
const Aud = preload("res://scripts/audio.gd")
const PXF = preload("res://scripts/pxfont.gd")
const UIS = preload("res://scripts/ui_style.gd")
const TXS = preload("res://scripts/textscale.gd")

signal resume
signal quit_run
signal save_quit
signal open_settings
signal summary_requested
signal fov_changed(pct: int)
signal stick_fixed_changed(on: bool)

const GOLD := Color("#ffd65c")
var th := Theme.new()
var cont_btn: Button
var txt_btn: Button
var mute_btn: Button
var hint_row: HBoxContainer
var sum_root: Control
var sum_box: VBoxContainer
var sum_back: Button
var sum_sc: ScrollContainer
var opt_root: Control
var tab := 0
var tab_btns: Array = []
var stat_grid: GridContainer
var moves_box: VBoxContainer
var head_row: HBoxContainer
var sum_front: Control
var stat_sc: ScrollContainer


func _init() -> void:
	layer = 90
	visible = false


static func _sb(bg: Color, border: Color, bw: int, _radius: int, shadow: int = 0) -> StyleBoxFlat:
	var s := UIS.box(bg, border, bw, shadow > 0)
	s.content_margin_left = 16
	s.content_margin_right = 16
	return s


func _label(t: String, size: int, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = L.t(t)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _btn(text: String, gold: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = L.t(text)
	b.custom_minimum_size = Vector2(210, 72)
	b.add_theme_font_size_override("font_size", 28)
	b.focus_mode = Control.FOCUS_ALL
	var bg: Color = UIS.GOLD if gold else UIS.PANEL_HI
	var bgh: Color = UIS.GOLD.lightened(0.25) if gold else UIS.EDGE
	var fc: Color = UIS.INK if gold else UIS.TEXT
	var edge: Color = UIS.INK if gold else UIS.EDGE
	b.add_theme_stylebox_override("normal", _sb(bg, edge, 3, 0, 3))
	b.add_theme_stylebox_override("hover", _sb(bgh, edge, 3, 0, 3))
	b.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.2), edge, 3, 0, 0))
	b.add_theme_stylebox_override("focus", _sb(bgh, UIS.WAVE if gold else UIS.GOLD, 4, 0, 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fc)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.0) if gold else UIS.INK)
	b.pressed.connect(cb)
	return b


func _knob() -> Texture2D:
	var img := Image.create(26, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color("#141028"))
	for y in range(3, 23):
		for x in range(3, 23):
			img.set_pixel(x, y, Color("#ffd65c") if y < 14 else Color("#f0a31e"))
	for y in range(3, 6):
		for x in range(3, 23):
			img.set_pixel(x, y, Color("#fff2a0"))
	return ImageTexture.create_from_image(img)


func build() -> void:
	PXF.apply(th)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = th
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.078, 0.063, 0.157, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.offset_top = 70
	root.add_child(cc)
	opt_root = cc
	var pc := PanelContainer.new()
	var pbox: StyleBox = UIS.frame(UIS.PANEL, UIS.EDGE).duplicate()
	pbox.content_margin_left = 28
	pbox.content_margin_right = 28
	pbox.content_margin_top = 18
	pbox.content_margin_bottom = 22
	pc.add_theme_stylebox_override("panel", pbox)
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(700, 0)
	pc.add_child(v)
	var title := _label("Pause", 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	hint_row = HBoxContainer.new()
	hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_row.add_theme_constant_override("separation", 8)
	v.add_child(hint_row)
	v.add_child(_slider_row("Music", "music"))
	v.add_child(_slider_row("Effects", "sfx"))
	v.add_child(_fov_row())
	v.add_child(_stick_row())
	v.add_child(_aim_row())
	var mrow := HBoxContainer.new()
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(mrow)
	mute_btn = _btn("Mute", true, _toggle_mute)
	mute_btn.custom_minimum_size = Vector2(190, 58)
	mute_btn.add_theme_font_size_override("font_size", 24)
	mrow.add_child(mute_btn)
	txt_btn = _btn("Texto: Normal", false, _cycle_text)
	txt_btn.custom_minimum_size = Vector2(250, 58)
	txt_btn.add_theme_font_size_override("font_size", 24)
	mrow.add_child(txt_btn)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 18)
	v.add_child(brow)
	cont_btn = _btn("Continue", true, func(): resume.emit())
	brow.add_child(cont_btn)
	brow.add_child(_btn("Settings", false, func(): open_settings.emit()))
	brow.add_child(_btn("Save and quit", false, func(): save_quit.emit()))
	brow.add_child(_btn("Quit run", false, func(): quit_run.emit()))
	_build_summary(root)
	_build_tabs(root)


func _build_tabs(root: Control) -> void:
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hb.offset_top = 10
	hb.add_theme_constant_override("separation", 10)
	root.add_child(hb)
	hb.add_child(PADI.rect(PAD.btn("prev"), 34.0))
	for i in 2:
		var bt := _btn("Summary" if i == 0 else "Options", i == 0, set_tab.bind(i))
		bt.custom_minimum_size = Vector2(190, 52)
		bt.add_theme_font_size_override("font_size", 24)
		hb.add_child(bt)
		tab_btns.append(bt)
	hb.add_child(PADI.rect(PAD.btn("next"), 34.0))
	tab_bar = hb


var tab_bar: Control


func set_tab(i: int) -> void:
	tab = i
	sum_root.visible = i == 0
	sum_front.visible = i == 0
	opt_root.visible = i == 1
	for k in tab_btns.size():
		var b: Button = tab_btns[k]
		_style_toggle(b, k == i)
	if i == 0:
		sum_back.grab_focus()
	else:
		cont_btn.grab_focus()


# Panel grande del resumen: marco achaflanado con mas aire interior.
func _px_panel(band: Color = UIS.EDGE) -> StyleBox:
	var sb: StyleBox = UIS.frame(Color(UIS.BG, 0.96), band).duplicate()
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 18
	return sb


func _build_summary(root: Control) -> void:
	sum_root = Control.new()
	sum_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	sum_root.visible = true
	root.add_child(sum_root)
	# fondo: cielo, colinas y suelo en pixel-art
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sum_root.add_child(bg)
	bg.draw.connect(func():
		var sz: Vector2 = bg.size
		var bands := 14
		for i in bands:
			var k: float = float(i) / float(bands - 1)
			bg.draw_rect(Rect2(0, sz.y * float(i) / bands, sz.x, sz.y / bands + 1), Color("#5a5099").lerp(Color("#bfe3ff"), k))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 5:
			var cx: float = rng.randf() * sz.x
			var cy: float = sz.y * (0.12 + rng.randf() * 0.35)
			for j in 4:
				bg.draw_rect(Rect2(cx + j * 26, cy - (6 if j % 3 == 1 else 0), 40, 14), Color(1, 1, 1, 0.55))
		var gy: float = sz.y * 0.74
		for i in 9:
			var hx: float = i * sz.x / 8.0 - 60
			var hh: float = 70 + (i * 37 % 50)
			bg.draw_rect(Rect2(hx, gy - hh, 160, hh), Color("#2f7d4a").darkened(0.12 * (i % 3)))
		bg.draw_rect(Rect2(0, gy, sz.x, sz.y - gy), Color("#3a9a52"))
		for i in int(sz.x / 24.0) + 1:
			bg.draw_rect(Rect2(i * 24, gy, 12, 6), Color("#58c06e"))
		bg.draw_rect(Rect2(0, gy + 40, sz.x, sz.y), Color("#7a5230")))
	var dim := ColorRect.new()
	dim.color = Color(0.078, 0.063, 0.157, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sum_root.add_child(dim)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 40)
	m.add_theme_constant_override("margin_right", 40)
	m.add_theme_constant_override("margin_top", 80)
	m.add_theme_constant_override("margin_bottom", 100)   # franja inferior reservada para los botones
	sum_root.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)
	head_row = HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 12)
	v.add_child(head_row)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cols)
	# panel de estadisticas
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", _px_panel())
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.size_flags_stretch_ratio = 1.3
	cols.add_child(lp)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 12)
	lp.add_child(lv)
	lv.add_child(_sec_title("Stats"))
	var lsc := ScrollContainer.new()
	lsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lv.add_child(lsc)
	stat_sc = lsc
	stat_grid = GridContainer.new()
	stat_grid.columns = 3
	stat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_grid.add_theme_constant_override("h_separation", 10)
	stat_grid.add_theme_constant_override("v_separation", 8)
	var sm := MarginContainer.new()
	sm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sm.add_theme_constant_override("margin_right", 20)
	lsc.add_child(sm)
	sm.add_child(stat_grid)
	# panel de movimientos
	var rp := PanelContainer.new()
	rp.add_theme_stylebox_override("panel", _px_panel())
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(rp)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 12)
	rp.add_child(rv)
	sum_sc = ScrollContainer.new()
	sum_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sum_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(sum_sc)
	moves_box = VBoxContainer.new()
	moves_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moves_box.add_theme_constant_override("separation", 12)
	var mm := MarginContainer.new()
	mm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mm.add_theme_constant_override("margin_right", 20)
	sum_sc.add_child(mm)
	mm.add_child(moves_box)
	sum_box = moves_box
	sum_front = Control.new()
	sum_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	sum_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sum_front)
	# franja inferior: Volver centrado y Abandonar a la derecha, fuera de los paneles
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 40
	bar.offset_right = -40
	bar.offset_top = -86
	bar.offset_bottom = -20
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 16)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sum_front.add_child(bar)
	var lsp := Control.new()
	lsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(lsp)
	sum_back = _btn("Back", true, func(): resume.emit())
	sum_back.custom_minimum_size = Vector2(300, 68)
	sum_back.add_theme_font_size_override("font_size", 32)
	bar.add_child(sum_back)
	var rsp := HBoxContainer.new()
	rsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsp.alignment = BoxContainer.ALIGNMENT_END
	rsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(rsp)
	var sum_save := _btn("Save and quit", false, func(): save_quit.emit())
	sum_save.custom_minimum_size = Vector2(250, 56)
	sum_save.add_theme_font_size_override("font_size", 22)
	sum_save.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rsp.add_child(sum_save)
	var sum_quit := _btn("Quit run", false, func(): quit_run.emit())
	sum_quit.custom_minimum_size = Vector2(250, 56)
	sum_quit.add_theme_font_size_override("font_size", 22)
	sum_quit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rsp.add_child(sum_quit)


func hide_summary() -> void:
	set_tab(1)


func _pokeball(sz: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(sz, sz)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var ctr := Vector2(sz, sz) * 0.5
		var r: float = sz * 0.5
		c.draw_circle(ctr, r, Color("#161616"))
		c.draw_circle(ctr, r - 3, Color("#f4f4f4"))
		c.draw_arc(ctr, r * 0.5, PI, TAU, 16, Color("#e8403a"), r - 3.0)
		c.draw_rect(Rect2(3, ctr.y - 2, sz - 6, 4), Color("#161616"))
		c.draw_circle(ctr, r * 0.3, Color("#161616"))
		c.draw_circle(ctr, r * 0.18, Color("#f4f4f4")))
	return c


func _tile(label: String, value: String, accent: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := _sb(Color("#2b2547"), accent, 0, 10)
	sb.border_width_left = 5
	sb.border_color = accent
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sb)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	var a := _label(label, 15, Color("#b4aed6"))
	a.text = label
	v.add_child(a)
	var b := _label(value, 25, Color.WHITE)
	b.text = value
	v.add_child(b)
	return pc


func _pill(txt: String, col: Color, icon: Control = null) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := _sb(col.darkened(0.55), col, 2, 14)
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	pc.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	pc.add_child(h)
	if icon != null:
		h.add_child(icon)
	var l := _label(txt, 18)
	l.text = txt
	h.add_child(l)
	return pc


func _sec_title(txt: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := _label(txt, 26, GOLD)
	h.add_child(l)
	var line := ColorRect.new()
	line.color = Color(UIS.EDGE, 0.9)
	line.custom_minimum_size = Vector2(0, 3)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(line)
	return h


func _proj_art(col: Color, sz: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(sz * 1.6, sz)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var y: float = sz * 0.5
		for i in 4:
			c.draw_circle(Vector2(sz * 1.45 - i * sz * 0.3, y), sz * (0.16 - i * 0.025), Color(col, 0.7 - i * 0.15))
		c.draw_circle(Vector2(sz * 1.45, y), sz * 0.24, Color(col, 0.35))
		c.draw_circle(Vector2(sz * 1.45, y), sz * 0.15, col.lightened(0.5)))
	return c


func _icon_box(icon: Control, col: Color, sz: float) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := _sb(Color("#141028"), col, 3, 4)
	sb.set_content_margin_all(4)
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(sz, sz)
	var cc := CenterContainer.new()
	pc.add_child(cc)
	cc.add_child(icon)
	return pc


func _stat_tile(label: String, value: String, icon: String, accent: Color, ratio: float = -1.0) -> PanelContainer:
	var pc := PanelContainer.new()
	# casilla plana con una franja de color a la izquierda (en vez de un borde de color completo)
	var sb := _sb(UIS.PANEL, accent, 0, 0)
	sb.border_width_left = 6
	sb.set_content_margin_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	pc.add_theme_stylebox_override("panel", sb)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.custom_minimum_size = Vector2(0, 62)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	pc.add_child(h)
	h.add_child(_icon_box(IC.rect(icon, 28), UIS.EDGE, 46))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var a := _label(label, 13, UIS.MUTED)
	a.text = label
	a.clip_text = true
	v.add_child(a)
	var b := _label(value, 23, UIS.TITLE)
	b.text = value
	b.clip_text = true
	v.add_child(b)
	if ratio >= 0.0:
		var bar := ColorRect.new()
		bar.color = UIS.INK
		bar.custom_minimum_size = Vector2(0, 8)
		v.add_child(bar)
		var f := ColorRect.new()
		f.color = Color("#6fd08a") if ratio > 0.35 else Color("#ff6a7a")
		f.anchor_bottom = 1.0
		f.anchor_right = clampf(ratio, 0.0, 1.0)
		bar.add_child(f)
	return pc


func show_summary(d: Dictionary) -> void:
	call_deferred("_scale_sum")
	for c in head_row.get_children():
		head_row.remove_child(c)
		c.queue_free()
	for c in stat_grid.get_children():
		stat_grid.remove_child(c)
		c.queue_free()
	for c in moves_box.get_children():
		moves_box.remove_child(c)
		c.queue_free()
	var t: int = int(d["time"])
	# cabecera: logo y cartel dorado a la izquierda, datos a la derecha
	var ban := PanelContainer.new()
	var bsb: StyleBox = UIS.frame(UIS.GOLD, UIS.GOLD.darkened(0.35)).duplicate()
	bsb.content_margin_top = 8
	bsb.content_margin_bottom = 8
	bsb.content_margin_left = 16
	bsb.content_margin_right = 20
	ban.add_theme_stylebox_override("panel", bsb)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	ban.add_child(bh)
	bh.add_child(_pokeball(40))
	var tl := _label("Run summary", 32, UIS.INK)
	bh.add_child(tl)
	head_row.add_child(ban)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(sp)
	var pic: Control = null
	if d.get("sprite") != null:
		var tr := TextureRect.new()
		tr.texture = d["sprite"]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(34, 34)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic = tr
	head_row.add_child(_pill(String(d["pname"]), Color("#ff9a4d"), pic))
	head_row.add_child(_pill("%s %d" % [L.t("Level"), int(d["level"])], Color("#6fd08a")))
	head_row.add_child(_pill("%02d:%02d" % [t / 60, t % 60], Color("#6ab7ff"), IC.rect("clock", 22)))
	head_row.add_child(_pill("%s %d" % [L.t("Defeats"), int(d["kills"])], Color("#ff6a7a"), IC.rect("fist", 22)))
	# estadisticas
	var accents := [Color("#ff6a7a"), Color("#ff9a4d"), Color("#6ab7ff"), Color("#ffd65c"), Color("#8fa3ff"), Color("#6fd08a"), Color("#c47bff")]
	var ai := 0
	# Nivel, Derrotas, Tipos y Habilidad ya salen en la cabecera y en la tarjeta del Pokemon.
	var dup: Array = [L.t("Level"), L.t("Defeats"), L.t("Types"), L.t("Ability")]
	for st in d["all"]:
		if dup.has(String(st[0])):
			continue
		var ratio: float = float(d["hp_ratio"]) if ai == 0 else -1.0
		var ic: String = String(st[2]) if (st as Array).size() > 2 else "star"
		stat_grid.add_child(_stat_tile(String(st[0]), String(st[1]), ic, accents[ai % accents.size()], ratio))
		ai += 1
	# tarjeta del Pokemon con su habilidad
	moves_box.add_child(_sec_title("Pokémon"))
	var pk := PanelContainer.new()
	var psb := _sb(Color("#2b2547"), Color("#ff9a4d"), 3, 4)
	psb.set_content_margin_all(8)
	pk.add_theme_stylebox_override("panel", psb)
	moves_box.add_child(pk)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pk.add_child(pv)
	var ptop := HBoxContainer.new()
	ptop.add_theme_constant_override("separation", 8)
	pv.add_child(ptop)
	var pn := _label("", 26, Color.WHITE)
	pn.text = String(d["pname"])
	pn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ptop.add_child(pn)
	for ty in d["types"]:
		ptop.add_child(_pill(String(ty), Color("#ff9a4d")))
	var abox := PanelContainer.new()
	var asb := _sb(Color("#141028"), Color("#ffd65c"), 2, 4)
	asb.set_content_margin_all(8)
	abox.add_theme_stylebox_override("panel", asb)
	pv.add_child(abox)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 2)
	abox.add_child(av)
	var an := _label("", 20, GOLD)
	an.text = "%s: %s" % [L.t("Ability"), String(d["ab_name"])]
	av.add_child(an)
	var ad := _label("", 16, Color("#f2e9d8"))
	ad.text = String(d["ab_desc"])
	ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ad.custom_minimum_size = Vector2(200, 0)
	av.add_child(ad)
	moves_box.add_child(_sec_title("Moves"))
	# moves: combined (bonded) moves share one frame with a "Combined" header, so the link is obvious
	var bond_box: VBoxContainer = null
	var bond_n := 0
	for mv in d["moves"]:
		if bool(mv.get("bond", false)):
			bond_n += 1
	for mv in d["moves"]:
		var col := Color(String(mv["col"]))
		var host: Node = moves_box
		if bool(mv.get("bond", false)) and bond_n >= 2:
			if bond_box == null:
				var bpc := PanelContainer.new()
				var bnd_sb := _sb(Color("#1c1833"), Color("#d77bff"), 3, 4)
				bnd_sb.set_content_margin_all(8)
				bpc.add_theme_stylebox_override("panel", bnd_sb)
				moves_box.add_child(bpc)
				bond_box = VBoxContainer.new()
				bond_box.add_theme_constant_override("separation", 6)
				bpc.add_child(bond_box)
				var bnd_h := _label("", 18, Color("#d77bff"))
				bnd_h.text = "%s · %s" % [L.t("Combined moves"), L.t("one slot")]
				bond_box.add_child(bnd_h)
			host = bond_box
		var card := PanelContainer.new()
		var sb := _sb(Color("#2b2547"), col, 3, 4)
		sb.set_content_margin_all(8)
		card.add_theme_stylebox_override("panel", sb)
		host.add_child(card)
		var ch := HBoxContainer.new()
		ch.add_theme_constant_override("separation", 10)
		card.add_child(ch)
		ch.add_child(_icon_box(IC.rect(String(mv.get("icon", "star")), 36), col, 58))
		var cv := VBoxContainer.new()
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_theme_constant_override("separation", 4)
		ch.add_child(cv)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		cv.add_child(top)
		var nl := _label(String(mv["name"]), 22, Color.WHITE)
		nl.text = String(mv["name"])
		top.add_child(nl)
		top.add_child(_pill(String(mv["type"]), col))
		top.add_child(_pill("%s %d" % [L.t("Lv."), int(mv["lvl"])], Color("#ffd65c")))
		var sp2 := Control.new()
		sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(sp2)
		top.add_child(_proj_art(col, 26))
		var dps_txt: String = ("%.1f" % float(mv["dps"])) if int(mv["dmg"]) > 0 else "–"
		var info := _label("", 16, Color("#f2e9d8"))
		info.text = "DPS (%ds): %s   |   %s: %d   |   %s: %d" % [int(d["window"]), dps_txt, L.t("Total damage"), int(mv["dmg"]), L.t("Defeats"), int(mv["kills"])]
		cv.add_child(info)
	# mejoras y objetos, al final de la lista de movimientos
	if not (d["stats"] as Array).is_empty():
		moves_box.add_child(_sec_title("Upgrades"))
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		fl.add_theme_constant_override("v_separation", 6)
		moves_box.add_child(fl)
		for st in d["stats"]:
			fl.add_child(_pill("%s %d" % [String(st["name"]), int(st["lv"])], Color("#ffd65c"), IC.rect(String(st["icon"]), 22)))
	if not (d["items"] as Array).is_empty():
		moves_box.add_child(_sec_title("Items"))
		for it in d["items"]:
			var ic2 := PanelContainer.new()
			var isb := _sb(Color("#2b2547"), Color("#ff8ad8"), 3, 4)
			isb.set_content_margin_all(6)
			ic2.add_theme_stylebox_override("panel", isb)
			moves_box.add_child(ic2)
			var ih := HBoxContainer.new()
			ih.add_theme_constant_override("separation", 10)
			ic2.add_child(ih)
			ih.add_child(_icon_box(IC.rect(String(it["id"]), 30), Color("#ff8ad8"), 48))
			var iv := VBoxContainer.new()
			iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			iv.add_theme_constant_override("separation", 0)
			ih.add_child(iv)
			var inm := _label("", 20, Color.WHITE)
			inm.text = String(it["name"])
			iv.add_child(inm)
			var ids := _label("", 15, Color("#f2e9d8"))
			ids.text = String(it["desc"])
			ids.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ids.custom_minimum_size = Vector2(200, 0)
			iv.add_child(ids)
	sum_sc.scroll_vertical = 0


func _slider_row(label: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var sic := IC.rect("sound", 30)
	sic.custom_minimum_size.x = 44
	row.add_child(sic)
	var l := _label(label, 24)
	l.custom_minimum_size = Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 5
	sl.value = float(SV.d["settings"][key])
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(360, 40)
	sl.focus_mode = Control.FOCUS_ALL
	var track := _sb(Color("#1c1833"), Color.TRANSPARENT, 0, 7)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", track)
	sl.add_theme_stylebox_override("grabber_area_highlight", track)
	var kn: Texture2D = _knob()
	sl.add_theme_icon_override("grabber", kn)
	sl.add_theme_icon_override("grabber_highlight", kn)
	sl.add_theme_icon_override("grabber_disabled", kn)
	sl.value_changed.connect(func(val: float):
		SV.d["settings"][key] = int(val)
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		if key == "sfx":
			Aud.sfx("coin"))
	row.add_child(sl)
	return row


# Campo de vision: acerca/aleja la camara (100-200 %). Se guarda y se aplica al instante.
func _fov_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var gap := Control.new()
	gap.custom_minimum_size.x = 44
	row.add_child(gap)
	var l := _label("View", 24)
	l.custom_minimum_size = Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 100
	sl.max_value = 200
	sl.step = 5
	sl.value = float(clampi(int(SV.d["settings"].get("fov", 165)), 100, 200))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(300, 40)
	sl.focus_mode = Control.FOCUS_ALL
	var track := _sb(Color("#1c1833"), Color.TRANSPARENT, 0, 7)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", track)
	sl.add_theme_stylebox_override("grabber_area_highlight", track)
	var kn: Texture2D = _knob()
	sl.add_theme_icon_override("grabber", kn)
	sl.add_theme_icon_override("grabber_highlight", kn)
	sl.add_theme_icon_override("grabber_disabled", kn)
	row.add_child(sl)
	var pl := _label("%d%%" % int(sl.value), 22, GOLD)
	pl.custom_minimum_size = Vector2(64, 0)
	row.add_child(pl)
	sl.value_changed.connect(func(val: float):
		SV.d["settings"]["fov"] = int(val)
		SV.save()
		pl.text = "%d%%" % int(val)
		fov_changed.emit(int(val)))
	return row


# Joystick fijo: lo deja siempre abajo a la izquierda (o flotante donde toques).
func _stick_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var gap := Control.new()
	gap.custom_minimum_size.x = 44
	row.add_child(gap)
	var l := _label("Fixed joystick", 24)
	l.custom_minimum_size = Vector2(190, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var on: bool = bool(SV.d["settings"].get("stick_fixed", false))
	var b := _btn("Yes" if on else "No", on, func(): pass)
	b.custom_minimum_size = Vector2(120, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func():
		var nv: bool = not bool(SV.d["settings"].get("stick_fixed", false))
		SV.d["settings"]["stick_fixed"] = nv
		SV.save()
		b.text = L.t("Yes") if nv else L.t("No")
		_style_toggle(b, nv)
		stick_fixed_changed.emit(nv))
	row.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	return row


var aim_btn: Button = null


func _aim_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var gap := Control.new()
	gap.custom_minimum_size.x = 44
	row.add_child(gap)
	var l := _label("Manual aim", 24)
	l.custom_minimum_size = Vector2(190, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var on: bool = bool(SV.d["settings"].get("manual_aim", false))
	var b := _btn("Yes" if on else "No", on, func(): pass)
	b.custom_minimum_size = Vector2(120, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func():
		var nv: bool = not bool(SV.d["settings"].get("manual_aim", false))
		SV.d["settings"]["manual_aim"] = nv
		SV.save()
		b.text = L.t("Yes") if nv else L.t("No")
		_style_toggle(b, nv))
	aim_btn = b
	row.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	return row


func _style_toggle(b: Button, on: bool) -> void:
	var bg: Color = UIS.GOLD if on else UIS.PANEL_HI
	var bgh: Color = UIS.GOLD.lightened(0.25) if on else UIS.EDGE
	var fc: Color = UIS.INK if on else UIS.TEXT
	var edge: Color = UIS.INK if on else UIS.EDGE
	b.add_theme_stylebox_override("normal", _sb(bg, edge, 3, 0, 3))
	b.add_theme_stylebox_override("hover", _sb(bgh, edge, 3, 0, 3))
	b.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.2), edge, 3, 0, 0))
	b.add_theme_stylebox_override("focus", _sb(bgh, UIS.WAVE if on else UIS.GOLD, 4, 0, 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fc)


func _toggle_mute() -> void:
	SV.d["settings"]["mute"] = not bool(SV.d["settings"].get("mute", false))
	SV.save()
	if Aud.inst != null:
		Aud.inst.apply()
	_refresh_mute()


func _refresh_mute() -> void:
	mute_btn.text = L.t("Unmute") if bool(SV.d["settings"].get("mute", false)) else L.t("Mute")


func _badge(t: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.12), Color(0.96, 0.97, 1.0, 0.35), 2, 7))
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	p.add_child(_label(t, 19, Color("#e8f0ff")))
	return p


func _txt(t: String) -> Label:
	var l := _label(t, 19, Color("#d9cdb5"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


# Ayuda de controles segun el mando elegido (Xbox, PlayStation o Nintendo).
func _refresh_hints() -> void:
	for c in hint_row.get_children():
		c.queue_free()
	hint_row.add_child(PADI.rect(7, 30.0))
	hint_row.add_child(_txt("move"))
	hint_row.add_child(_txt("·"))
	hint_row.add_child(PADI.rect(PAD.btn("prev"), 30.0))
	hint_row.add_child(_txt("/"))
	hint_row.add_child(PADI.rect(PAD.btn("next"), 30.0))
	hint_row.add_child(_txt("cycle"))
	hint_row.add_child(_txt("·"))
	hint_row.add_child(PADI.rect(PAD.btn("pause"), 30.0))
	hint_row.add_child(_txt("pause"))


# Mismo manejo del mando que el menu principal: filas, ciclo izquierda/derecha y columna recordada.
func _process(_d: float) -> void:
	if visible:
		PAD.stick_tick()
	else:
		PAD.stick_reset()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var sw := 0
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == PAD.btn("prev"):
			sw = -1
		elif event.button_index == PAD.btn("next"):
			sw = 1
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q or event.keycode == KEY_PAGEUP:
			sw = -1
		elif event.keycode == KEY_E or event.keycode == KEY_PAGEDOWN:
			sw = 1
	if sw != 0:
		set_tab(clampi(tab + sw, 0, 1))
		get_viewport().set_input_as_handled()
		return
	if tab == 0:
		# con el resumen abierto, arriba/abajo (stick o cruceta) desplazan la lista de movimientos
		if PAD.stick_event(event):
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true):
			var dy: int = 150 if event.is_action_pressed("ui_down", true) else -150
			sum_sc.scroll_vertical += dy
			stat_sc.scroll_vertical += dy
			get_viewport().set_input_as_handled()
		return
	if PAD.stick_event(event):
		get_viewport().set_input_as_handled()   # el stick izquierdo navega como cruceta
		return
	if NAVG.move(get_viewport(), event, NAVG.focusables(self)):
		get_viewport().set_input_as_handled()


func _cycle_text() -> void:
	TXS.set_idx((TXS.idx() + 1) % 3)
	_refresh_text_btn()
	TXS.scale_tree(self)


func _refresh_text_btn() -> void:
	if txt_btn != null:
		txt_btn.text = L.t("Text") + ": " + L.t(String(TXS.NAMES[TXS.idx()]))


func open() -> void:
	_refresh_text_btn()
	TXS.scale_tree(self)
	if aim_btn != null:
		var on: bool = bool(SV.d["settings"].get("manual_aim", false))
		aim_btn.text = L.t("Yes") if on else L.t("No")
		_style_toggle(aim_btn, on)
	_refresh_hints()
	_refresh_mute()
	visible = true
	summary_requested.emit()
	set_tab(0)


func close() -> void:
	visible = false


func _scale_sum() -> void:
	if sum_root != null:
		TXS.scale_tree(sum_root)
