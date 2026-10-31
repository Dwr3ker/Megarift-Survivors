extends Node2D
# Evolution scene in the style of the main games: the world freezes, light gathers into the Pokémon, its white
# silhouette swaps between the old and the new form faster and faster, a white flash, then the new Pokémon fades
# in from white with a "Congratulations!" banner. The real change (EVL.apply: stats, body, full heal) happens at the flash.
const EVL = preload("res://scripts/evolution.gd")
const L = preload("res://scripts/lang.gd")

const T_GATHER := 0.7     # dim + sparkles flow in, the Pokémon turns white
const T_MORPH := 2.3      # silhouettes alternate, faster and faster (ends at this time)
const T_FLASH := 2.65     # white flash peaks; the evolution is applied here
const T_END := 3.9

var m = null
var to_dex := 0
var from_dex := 0
var t := 0.0
var done := false
var applied := false
var old_a = null           # white silhouettes (Actor nodes), only during the morph
var new_a = null
var swap_t := 0.0
var show_new := false
var sparks: Array = []     # [pos, vel, life, max_life]
var name_from := ""
var name_to := ""


func start(main, dex: int) -> void:
	m = main
	to_dex = dex
	from_dex = int(m._cur_dex())
	name_from = L.t(String(m._dex_by[from_dex]["name"]))
	name_to = L.t(String(m._dex_by[dex]["name"]))
	z_index = 60
	m.fx.add_child(self)
	position = m.player.position
	var p = m.player
	p.invuln = maxf(p.invuln, T_END + 1.0)
	old_a = _ghost(from_dex)
	new_a = _ghost(to_dex)
	new_a.visible = false
	old_a.visible = false
	m.Aud.sfx("levelup")
	m.zoom_punch = maxf(m.zoom_punch, 0.12)


func _ghost(dex: int):
	var a = m.Actor.new()
	a.setup(dex, m._sm(dex), m.flash_shader, float(m.player.scl), bool(m.player.shiny))
	a.dir = m.player.dir
	a.z_index = 1
	add_child(a)
	return a


# Called by main every frame while the scene plays (the world is frozen meanwhile).
func tick(dt: float) -> void:
	t += dt
	var p = m.player
	position = p.position
	m.zoom_punch = maxf(m.zoom_punch, 0.12 if t < T_FLASH else 0.12 * clampf((T_END - t) / (T_END - T_FLASH), 0.0, 1.0))
	if t < T_GATHER:
		p.flash = 1.0 + clampf(t / T_GATHER, 0.0, 1.0)   # ramps to a full white silhouette (the actor eases it back each frame)
		if randf() < dt * 60.0:
			_spark_in()
	elif t < T_MORPH:
		# the real sprite hides; the two white silhouettes take turns, each turn shorter than the last
		p.visible = false
		var k: float = (t - T_GATHER) / (T_MORPH - T_GATHER)
		var period: float = lerpf(0.42, 0.045, pow(k, 1.3))
		swap_t -= dt
		if swap_t <= 0.0:
			swap_t = period
			show_new = not show_new
			if k > 0.3:
				m.shake = maxf(m.shake, 1.5 + 3.0 * k)
		old_a.visible = not show_new
		new_a.visible = show_new
		for g in [old_a, new_a]:
			g.flash = 2.0
			g.scale = Vector2.ONE * (1.0 + 0.06 * sin(t * 18.0))
		if randf() < dt * 40.0:
			_spark_in()
	elif not applied:
		old_a.visible = false
		new_a.visible = true
		new_a.flash = 2.0
		if t >= T_FLASH:
			applied = true
			old_a.queue_free()
			new_a.queue_free()
			old_a = null
			new_a = null
			p.visible = true
			EVL.apply(m, to_dex, false, false)   # stats, body, full heal, rings and sound (the banner below says what happened)
			p.flash = 2.5
			for i in range(40):
				var an: float = randf() * TAU
				sparks.append([Vector2(0.0, -p.body_h * 0.5), Vector2.from_angle(an) * randf_range(120.0, 320.0), 0.0, randf_range(0.5, 1.0)])
	else:
		# reveal: the new form fades from white to its colours
		p.flash = maxf(p.flash, 2.0 * clampf(1.0 - (t - T_FLASH) / 0.9, 0.0, 1.0))
	for s in sparks:
		s[2] = float(s[2]) + dt
		s[0] = (s[0] as Vector2) + (s[1] as Vector2) * dt
		s[1] = (s[1] as Vector2) * (1.0 - 2.2 * dt)
	sparks = sparks.filter(func(s): return float(s[2]) < float(s[3]))
	if t >= T_END:
		finish()
	queue_redraw()


# light streaks that fly into the Pokémon from all around
func _spark_in() -> void:
	var an: float = randf() * TAU
	var r: float = randf_range(120.0, 220.0)
	var target := Vector2(0.0, -m.player.body_h * 0.5)
	var from: Vector2 = target + Vector2.from_angle(an) * r
	var life: float = randf_range(0.35, 0.55)
	sparks.append([from, (target - from) / life, 0.0, life])


func finish() -> void:
	if done:
		return
	done = true
	if not applied:   # cut short (the run ended): still evolve, without the scene
		applied = true
		m.player.visible = true
		EVL.apply(m, to_dex)
	m.player.visible = true
	queue_free()


func dim() -> float:
	if t < T_FLASH:
		return clampf(t / 0.4, 0.0, 1.0) * 0.7
	return clampf((T_END - t) / (T_END - T_FLASH), 0.0, 1.0) * 0.7


func _draw() -> void:
	var p = m.player
	var c := Vector2(0.0, -p.body_h * 0.5)
	# darkened world (the scene is drawn in world space, so a big rect covers the screen)
	draw_rect(Rect2(Vector2(-4000, -4000), Vector2(8000, 8000)), Color(0.0, 0.0, 0.05, dim()))
	# soft light behind the Pokémon, pulsing faster as the morph speeds up
	var glow_k: float = clampf(t / T_GATHER, 0.0, 1.0) * clampf((T_END - t) / 0.8, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(t * (6.0 + 20.0 * clampf(t / T_MORPH, 0.0, 1.0)))
	for i in range(6):
		var rr: float = (30.0 + float(i) * 14.0) * (0.9 + 0.15 * pulse)
		draw_circle(c, rr, Color(0.75, 0.9, 1.0, 0.07 * glow_k))
	# rotating rays during the morph
	if t > T_GATHER * 0.6 and t < T_FLASH + 0.3:
		var ra_k: float = clampf((t - T_GATHER * 0.6) / 0.5, 0.0, 1.0) * clampf((T_FLASH + 0.3 - t) / 0.3, 0.0, 1.0)
		for i in range(12):
			var a0: float = float(i) * TAU / 12.0 + t * 0.9
			draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a0 - 0.06) * 260.0, c + Vector2.from_angle(a0 + 0.06) * 260.0]), Color(1.0, 1.0, 0.9, 0.10 * ra_k))
	# sparkles
	for s in sparks:
		var k: float = float(s[2]) / float(s[3])
		var sp: Vector2 = s[0]
		var a: float = (1.0 - k) if applied else minf(1.0, k * 3.0)
		var l: float = 4.0 + 3.0 * (1.0 - k)
		draw_line(sp - Vector2(l, 0), sp + Vector2(l, 0), Color(1, 1, 0.85, a), 2.0)
		draw_line(sp - Vector2(0, l), sp + Vector2(0, l), Color(1, 1, 0.85, a), 2.0)
		draw_circle(sp, 1.8, Color(1, 1, 1, a))
	# the white flash
	var fl: float = 0.0
	if t >= T_MORPH and t < T_FLASH:
		fl = (t - T_MORPH) / (T_FLASH - T_MORPH)
	elif t >= T_FLASH:
		fl = clampf(1.0 - (t - T_FLASH) / 0.45, 0.0, 1.0)
	if fl > 0.0:
		draw_rect(Rect2(Vector2(-4000, -4000), Vector2(8000, 8000)), Color(1, 1, 1, fl * 0.95 * float(m.hud.flash_k)))
	# banner text
	var font: Font = ThemeDB.fallback_font
	if "font" in m.hud and m.hud.font != null:
		font = m.hud.font
	var ty: float = c.y + p.body_h * 0.5 + 64.0   # under the Pokémon, like the games' text box (the HUD sits at the top)
	if not applied and t > 0.25:
		var a1: float = clampf((t - 0.25) / 0.3, 0.0, 1.0)
		_text(font, L.t("What? %s is evolving!") % name_from, ty, a1)
	elif applied:
		var a2: float = clampf((t - T_FLASH - 0.2) / 0.3, 0.0, 1.0) * clampf((T_END - t) / 0.3, 0.0, 1.0)
		_text(font, L.t("Congratulations! Your %s evolved into %s!") % [name_from, name_to], ty, a2)


func _text(font: Font, s: String, y: float, a: float) -> void:
	var w: float = maxf(360.0, font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x + 40.0)
	draw_rect(Rect2(-w * 0.5, y - 26.0, w, 40.0), Color(0.04, 0.06, 0.14, 0.82 * a))
	draw_rect(Rect2(-w * 0.5, y - 26.0, w, 40.0), Color(1, 1, 1, 0.9 * a), false, 2.0)
	draw_string(font, Vector2(-w * 0.5, y + 2.0), s, HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(0, 0, 0, 0.6 * a))
	draw_string(font, Vector2(-w * 0.5, y), s, HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(1, 1, 1, a))
