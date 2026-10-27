extends Node
# Desplazamiento tactil global: arrastrar con el dedo (o el raton) sobre cualquier lista con scroll del juego,
# incluso encima de botones. Godot solo lo hace en zonas vacias; aqui lo hacemos en todas partes.
var _sc: ScrollContainer = null
var _start := Vector2.ZERO
var _moved := false
var _acc := 0.0
const THRESH := 12.0


const UIS = preload("res://scripts/ui_style.gd")
const BAR_W := 30.0   # v5.2: barras de desplazamiento mas gruesas para tocarlas con el dedo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(n: Node) -> void:
	if n is ScrollContainer:
		var sc := n as ScrollContainer
		_style_bar(sc.get_v_scroll_bar(), true)
		_style_bar(sc.get_h_scroll_bar(), false)


# Thick bars for fingers. The thickness lives in the track stylebox margins (not custom_minimum_size):
# ScrollContainer only reserves the bar's own minimum size, so content used to slide under the bar.
func _style_bar(bar: ScrollBar, vertical: bool) -> void:
	var m: float = (BAR_W if vertical else BAR_W * 0.7) * 0.5
	var track := StyleBoxFlat.new()
	track.bg_color = Color(UIS.INK, 0.55)
	track.content_margin_left = m if vertical else 0.0
	track.content_margin_right = m if vertical else 0.0
	track.content_margin_top = 0.0 if vertical else m
	track.content_margin_bottom = 0.0 if vertical else m
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	for gs in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var g := StyleBoxFlat.new()
		g.bg_color = UIS.EDGE if gs == "grabber" else (UIS.WAVE if gs == "grabber_pressed" else UIS.EDGE.lightened(0.25))
		g.set_content_margin_all(0.0)
		g.set_border_width_all(2)
		g.border_color = UIS.INK
		bar.add_theme_stylebox_override(gs, g)


func _under(n: Node, pos: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	if n is CanvasItem and not (n as CanvasItem).visible:
		return null
	if n is Window and n != get_tree().root:
		pass
	if n is ScrollContainer:
		var sc := n as ScrollContainer
		var bar: VScrollBar = sc.get_v_scroll_bar()
		if sc.is_visible_in_tree() and sc.get_global_rect().has_point(pos) and bar.max_value - bar.page > 1.0 \
				and sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			best = sc
	for c in n.get_children():
		var r: ScrollContainer = _under(c, pos)
		if r != null:
			best = r
	return best


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_sc = null
			_moved = false
			_acc = 0.0
			var hov: Control = get_viewport().gui_get_hovered_control()
			if hov is Range or hov is LineEdit or hov is TextEdit or hov is OptionButton:
				return
			_sc = _under(get_tree().root, mb.position)
			_start = mb.position
		else:
			var was := _moved
			_sc = null
			_moved = false
			if was:
				get_viewport().set_input_as_handled()   # soltar tras arrastrar no pulsa nada
	elif event is InputEventMouseMotion and _sc != null:
		if not is_instance_valid(_sc):
			_sc = null
			return
		var mm := event as InputEventMouseMotion
		if not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_sc = null
			return
		if not _moved:
			if absf(mm.position.y - _start.y) < THRESH:
				return
			_moved = true
			_sc.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		_acc -= mm.relative.y
		var step := int(_acc)
		if step != 0:
			_sc.scroll_vertical += step
			_acc -= float(step)
		get_viewport().set_input_as_handled()
