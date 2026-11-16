extends Control
# The hatch scene (docs/eggs.md, roadmap step 27): over a dark backdrop the egg wobbles harder and harder, cracks,
# shakes, bursts in a white flash and the Pokémon appears (menu.gd adds it on `revealed`). A tap, click or A press skips
# straight to the reveal. Full screen, drawn in code; sizes follow the screen height so 16:9 and 4:3 look the same.
signal revealed

const EGA = preload("res://scripts/egg_art.gd")
const Aud = preload("res://scripts/audio.gd")

const WOBBLES := [0.55, 1.15, 1.7]   # wobble bursts, each harder
const SHAKE_AT := 2.05
const FLASH_AT := 2.6
const LEN := 3.4

var look := "yellow"
var t := 0.0
var done := false        # revealed already
var bits: Array = []     # shell pieces flying out after the flash: [pos, vel, rot, spin]
var _sfx_i := 0


func play(egg_look: String) -> void:
	look = egg_look
	t = 0.0
	done = false
	bits.clear()
	_sfx_i = 0
	position = Vector2.ZERO   # the menu root has no size of its own: cover the screen by hand
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL   # holds the focus while it plays, so A / Enter skip instead of pressing a button below
	visible = true
	set_process(true)


func skip() -> void:
	if not done:
		t = FLASH_AT


func _gui_input(ev: InputEvent) -> void:
	if done:
		return
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed) or ev.is_action_pressed("ui_accept"):
		skip()
		accept_event()


func _unhandled_input(ev: InputEvent) -> void:
	if visible and not done and (ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel")):
		skip()
		get_viewport().set_input_as_handled()


func _centre() -> Vector2:
	return size * Vector2(0.5, 0.46)


func _egg_h() -> float:
	return size.y * 0.34


func _process(delta: float) -> void:
	t += delta
	while _sfx_i < WOBBLES.size() and t >= float(WOBBLES[_sfx_i]):
		Aud.sfx("shake")
		_sfx_i += 1
	if not done and t >= FLASH_AT:
		done = true
		Aud.sfx("break")
		Aud.sfx("reveal3")
		var cols: Array = EGA.COLS.get(look, EGA.COLS["yellow"])
		for i in range(14):
			var a: float = TAU * float(i) / 14.0 + randf_range(-0.2, 0.2)
			bits.append([_centre(), Vector2.from_angle(a) * randf_range(260.0, 520.0) * (size.y / 720.0), randf() * TAU, randf_range(-8.0, 8.0),
				cols[0] if i % 3 else cols[1]])
		revealed.emit()
	for b in bits:
		b[0] += b[1] * delta
		b[1] *= pow(0.12, delta)
		b[1].y += 500.0 * delta * (size.y / 720.0)
		b[2] += b[3] * delta
	if t > LEN + 2.0:
		set_process(false)
	queue_redraw()


# How much the egg leans now: still, then three bursts of wobble, then a fast shake before it bursts.
func _rot() -> float:
	var r := 0.0
	for i in range(WOBBLES.size()):
		var dt: float = t - float(WOBBLES[i])
		if dt > 0.0 and dt < 0.45:
			r += sin(dt * 26.0) * (0.12 + 0.07 * i) * (1.0 - dt / 0.45)
	if t > SHAKE_AT and t < FLASH_AT:
		r += sin(t * 70.0) * 0.08
	return r


func _draw() -> void:
	var c: Vector2 = _centre()
	var h: float = _egg_h()
	var fade: float = clampf(t / 0.3, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.1, 0.88 * fade))
	if not done:
		# a soft glow that grows as it gets close
		var g: float = clampf((t - 1.0) / (FLASH_AT - 1.0), 0.0, 1.0)
		for k in range(4):
			draw_circle(c, h * (0.62 + 0.14 * k) * (0.9 + 0.2 * g), Color(1.0, 0.95, 0.75, (0.05 + 0.08 * g) * fade))
		var drop: float = (1.0 - clampf(t / 0.35, 0.0, 1.0)) * -h * 0.6
		var crack: float = clampf((t - 1.15) / (FLASH_AT - 1.25), 0.0, 1.0)
		var sx: float = sin(t * 90.0) * h * 0.012 if t > SHAKE_AT else 0.0
		EGA.draw(self, c + Vector2(sx, drop), h, look, _rot(), crack)
		return
	var ft: float = t - FLASH_AT
	# rays behind the Pokémon
	var ra: float = clampf(1.0 - ft / 2.4, 0.25, 1.0)
	for i in range(12):
		var a: float = TAU * float(i) / 12.0 + ft * 0.35
		var pts := PackedVector2Array([c, c + Vector2.from_angle(a - 0.09) * size.y, c + Vector2.from_angle(a + 0.09) * size.y])
		draw_colored_polygon(pts, Color(1.0, 0.92, 0.6, 0.10 * ra))
	for b in bits:
		var p: Vector2 = b[0]
		var s: float = h * 0.07
		var tri := PackedVector2Array([p + Vector2(-s, -s * 0.6).rotated(b[2]), p + Vector2(s, -s * 0.3).rotated(b[2]), p + Vector2(0, s).rotated(b[2])])
		var col: Color = b[4]
		col.a = clampf(1.0 - ft / 1.2, 0.0, 1.0)
		draw_colored_polygon(tri, col)
	# the white flash
	var fl: float = clampf(1.0 - ft / 0.45, 0.0, 1.0)
	if fl > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, fl * 0.95))
