extends RefCounted
# Extra visuals for Dynamax and Z-Moves (visual only, no damage):
#   - Z-Move: while the cinematic plays, energy motes spiral into the Pokémon, two rune rings turn around its feet and a
#     bright glow builds up; the camera pushes in a little.
#   - Dynamax: a light beam drops onto the Pokémon when it grows, every Max Wave is a real shockwave (filled flash, expanding
#     ring, radial streaks) with the name of the type's Max move on the big ones, and the end is a puff of red mist.
const VFX = preload("res://scripts/vfx.gd")

const MAX_NAME := {
	"normal": "Max Strike", "fire": "Max Flare", "water": "Max Geyser", "electric": "Max Lightning", "grass": "Max Overgrowth",
	"ice": "Max Hailstorm", "fighting": "Max Knuckle", "poison": "Max Ooze", "ground": "Max Quake", "flying": "Max Airstream",
	"psychic": "Max Mindstorm", "bug": "Max Flutterby", "rock": "Max Rockfall", "ghost": "Max Phantasm", "dragon": "Max Wyrmwind",
	"dark": "Max Darkness", "steel": "Max Steelspike", "fairy": "Max Starfall",
}


static func _additive() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


static func tint(type: String) -> Color:
	return VFX.pc(type, 3)


# ---------------------------------------------------------------
# Z-Move: energy gathers into the Pokémon while the cinematic plays
# ---------------------------------------------------------------
class Gather extends Node2D:
	var col := Color.WHITE
	var hi := Color.WHITE
	var life := 2.2
	var t := 0.0
	var h := 40.0
	var rad := 24.0
	const MOTES := 44

	func _init() -> void:
		material = PFX_ADD.new()._mat()
		z_index = 4

	func _process(d: float) -> void:
		t += d
		if t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(t / life, 0.0, 1.0)
		var fade: float = clampf((life - t) / 0.25, 0.0, 1.0) * clampf(t / 0.2, 0.0, 1.0)
		var c := Vector2(0.0, -h * 0.5)
		# glow that builds up around the body
		for i in range(3):
			var rr: float = (maxf(rad, h * 0.5) * (1.0 + 0.55 * float(i))) * (0.6 + 0.6 * k)
			draw_circle(c, rr, Color(col.r, col.g, col.b, (0.10 + 0.14 * k) * fade))
		# rune rings on the ground turning in opposite directions
		for ring in range(2):
			var rx: float = rad * (2.3 + 0.9 * float(ring)) * (0.7 + 0.5 * k)
			var dir: float = 1.0 if ring == 0 else -1.0
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36))
			for j in range(18):
				var a: float = TAU * float(j) / 18.0 + dir * t * (1.6 + 0.8 * float(ring))
				var p := Vector2(cos(a), sin(a)) * rx
				var sz: float = 6.0 if j % 3 == 0 else 3.5
				draw_rect(Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(hi.r, hi.g, hi.b, 0.85 * fade))
			draw_arc(Vector2.ZERO, rx, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.8 * fade), 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# motes spiralling in
		for i in range(MOTES):
			var seed_v: float = float(i) / float(MOTES)
			var ph: float = fposmod(k * 1.6 + seed_v, 1.0)   # each mote repeats its trip
			var r: float = lerpf(rad * 9.0, rad * 0.5, ph * ph)
			var a2: float = seed_v * TAU * 3.0 + ph * 4.5
			var p2 := c + Vector2(cos(a2) * r, sin(a2) * r * 0.7)
			var sz2: float = lerpf(8.0, 3.0, ph)
			var al: float = sin(ph * PI) * fade
			draw_rect(Rect2((p2 - Vector2(sz2, sz2) * 0.5).round(), Vector2(sz2, sz2)), Color(hi.r, hi.g, hi.b, al))
			var tail: Vector2 = c + Vector2(cos(a2 - 0.25) * r * 1.08, sin(a2 - 0.25) * r * 1.08 * 0.7)
			draw_line(p2, tail, Color(col.r, col.g, col.b, al * 0.9), 3.0)
		# the last moment: a bright pulse
		var last: float = clampf((k - 0.85) / 0.15, 0.0, 1.0)
		if last > 0.0:
			draw_circle(c, maxf(rad, h * 0.5) * (1.0 + 1.6 * last), Color(1, 1, 1, 0.25 * (1.0 - last)))


# helper so the node can be additive without a separate scene
class PFX_ADD:
	func _mat() -> CanvasItemMaterial:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return mat


# ---------------------------------------------------------------
# Dynamax: sky beam, Max Wave shockwaves, and the red puff at the end
# ---------------------------------------------------------------
class SkyBeam extends Node2D:
	var col := Color(1.0, 0.2, 0.4)
	var t := 0.0
	var life := 1.3

	func _init() -> void:
		material = PFX_ADD.new()._mat()
		z_index = 3

	func _process(d: float) -> void:
		t += d
		if t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k: float = t / life
		var grow: float = clampf(t / 0.12, 0.0, 1.0)
		var fade: float = clampf((1.0 - k) / 0.55, 0.0, 1.0)
		var hgt: float = 1000.0 * grow
		for ly in [[90.0, 0.16], [56.0, 0.26], [30.0, 0.45], [14.0, 0.8]]:
			var w: float = float(ly[0]) * (1.0 + 0.4 * (1.0 - fade))
			var a: float = float(ly[1]) * fade
			var c: Color = col.lerp(Color.WHITE, 0.25 if w < 40.0 else 0.0)
			draw_polygon(PackedVector2Array([Vector2(-w * 0.5, 0.0), Vector2(w * 0.5, 0.0), Vector2(w * 0.35, -hgt), Vector2(-w * 0.35, -hgt)]),
				PackedColorArray([Color(c.r, c.g, c.b, a), Color(c.r, c.g, c.b, a), Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, 0.0)]))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
		draw_circle(Vector2.ZERO, 70.0 * (0.6 + 0.8 * k), Color(col.r, col.g, col.b, 0.35 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Shock extends Node2D:
	var col := Color.WHITE
	var r1 := 280.0
	var t := 0.0
	var life := 0.55
	var big := false

	func _init() -> void:
		material = PFX_ADD.new()._mat()

	func _process(d: float) -> void:
		t += d
		if t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(t / life, 0.0, 1.0)
		var e: float = 1.0 - pow(1.0 - k, 3.0)   # fast start, slow end
		var r: float = r1 * e
		var a: float = 1.0 - k
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.16 * a))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(col.r, col.g, col.b, 0.9 * a), 8.0 * a + 2.0)
		draw_arc(Vector2.ZERO, r * 0.86, 0.0, TAU, 64, Color(1, 1, 1, 0.7 * a), 3.0)
		var n: int = 18 if big else 12
		for i in range(n):
			var an: float = TAU * float(i) / float(n) + 0.2
			var d0: Vector2 = Vector2(cos(an), sin(an))
			draw_line(d0 * r * 0.55, d0 * r * 1.02, Color(col.r, col.g, col.b, 0.8 * a), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------- entry points ----------------
static func z_gather(main, type: String, seconds: float) -> void:
	var g := Gather.new()
	g.col = VFX.pc(type, 2)
	g.hi = VFX.pc(type, 4)
	g.life = seconds
	g.h = float(main.player.body_h)
	g.rad = float(main.player.radius)
	main.player.add_child(g)
	main.zoom_punch = maxf(main.zoom_punch, 0.1)


static func dyn_enter(main, type: String) -> void:
	var b := SkyBeam.new()
	b.col = Color(1.0, 0.2, 0.4).lerp(VFX.pc(type, 3), 0.35)
	b.position = main.player.position
	main.fx.add_child(b)
	main.zoom_punch = maxf(main.zoom_punch, 0.12)


static func dyn_wave(main, pos: Vector2, r: float, type: String, big: bool) -> void:
	var s := Shock.new()
	s.col = Color(1.0, 0.25, 0.45).lerp(VFX.pc(type, 3), 0.55)
	s.r1 = r
	s.big = big
	s.life = 0.7 if big else 0.5
	s.position = pos
	main.gfx.add_child(s)   # the ground layer: the wave spreads out from under the Pokémon
	if big:
		var nm: String = String(MAX_NAME.get(type, "Max Strike"))
		main.add_text(pos + Vector2(0.0, -float(main.player.body_h) - 30.0), nm, VFX.pc(type, 4), 24)


static func dyn_exit(main, type: String) -> void:
	var col: Color = Color(1.0, 0.2, 0.4)
	for i in range(18):
		var a: float = randf() * TAU
		var sp: float = randf_range(40.0, 150.0)
		main.pfx.px(main.player.position + Vector2(randf_range(-20.0, 20.0), -main.player.body_h * 0.4), col.lerp(Color(0.5, 0.1, 0.7), randf()), Vector2(cos(a) * sp, sin(a) * sp * 0.5 - 40.0), randf_range(0.5, 0.9), 2.0, 0.0, 0.94)
	var s := Shock.new()
	s.col = col
	s.r1 = 170.0
	s.life = 0.45
	s.position = main.player.position
	main.gfx.add_child(s)
