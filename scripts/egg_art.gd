extends RefCounted
# Egg drawing (docs/eggs.md): 6 shell looks, drawn in code so any size stays crisp. Used by the run drop, the incubator
# and the hatch scene. draw(ci, centre, height, look, wobble angle, crack 0..1).

const COLS := {
	"red": [Color("#ffd9c8"), Color("#e8483c"), Color("#9a2a22")],
	"blue": [Color("#d2e9ff"), Color("#3d8ef0"), Color("#1f4f9a")],
	"green": [Color("#d9f2c8"), Color("#4fb84a"), Color("#2a6e2a")],
	"yellow": [Color("#fff0b0"), Color("#f2c21c"), Color("#9a7410")],
	"brown": [Color("#e8d4b8"), Color("#a8743e"), Color("#5e3e1e")],
	"purple": [Color("#e2d0ff"), Color("#9a5ae8"), Color("#4e2a8a")],
}
const OUTLINE := Color("#20182c")
const N := 36


# Half width of the egg at height yn (-1 top .. 1 bottom): a little narrower at the top.
static func _hw(yn: float) -> float:
	return sqrt(maxf(0.0, 1.0 - yn * yn)) * (1.0 + 0.14 * yn)


static func _outline(c: Vector2, w: float, h: float, rot: float, grow: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(N):
		var a: float = TAU * float(i) / float(N)
		var yn: float = -cos(a)
		var p := Vector2(sin(a) * (1.0 + 0.14 * yn) * (w + grow), yn * (h + grow))
		pts.append(c + p.rotated(rot))
	return pts


# Is the local point (unrotated, relative to the centre) inside the shell, with a margin?
static func _inside(p: Vector2, w: float, h: float, m: float) -> bool:
	var yn: float = p.y / maxf(h - m, 0.01)
	if absf(yn) >= 1.0:
		return false
	return absf(p.x) < _hw(yn) * w - m


static func _seg(ci: CanvasItem, c: Vector2, rot: float, a: Vector2, b: Vector2, w: float, h: float, col: Color, wd: float) -> void:
	if _inside(a, w, h, wd * 0.6) and _inside(b, w, h, wd * 0.6):
		ci.draw_line(c + a.rotated(rot), c + b.rotated(rot), col, wd)


static func _poly_line(ci: CanvasItem, c: Vector2, rot: float, pts: Array, w: float, h: float, col: Color, wd: float) -> void:
	for i in range(pts.size() - 1):
		_seg(ci, c, rot, pts[i], pts[i + 1], w, h, col, wd)


static func draw(ci: CanvasItem, c: Vector2, height: float, look: String, rot: float = 0.0, crack: float = 0.0) -> void:
	var cols: Array = COLS.get(look, COLS["yellow"])
	var h: float = height * 0.5
	var w: float = h * 0.78
	var k: float = height / 40.0     # pattern scale
	# shadow, outline, shell
	ci.draw_set_transform(c + Vector2(0.0, h * 0.98), 0.0, Vector2(1.0, 0.3))
	ci.draw_circle(Vector2.ZERO, w * 0.95, Color(0, 0, 0, 0.28))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_colored_polygon(_outline(c, w, h, rot, maxf(1.5, 2.0 * k)), OUTLINE)
	ci.draw_colored_polygon(_outline(c, w, h, rot, 0.0), cols[0])
	var acc: Color = cols[1]
	var dk: Color = cols[2]
	match look:
		"red":   # speckles
			var spots := [Vector2(-0.35, -0.45), Vector2(0.3, -0.2), Vector2(-0.1, 0.1), Vector2(0.45, 0.35), Vector2(-0.45, 0.45),
				Vector2(0.05, -0.75), Vector2(0.1, 0.65), Vector2(-0.55, -0.05)]
			for i in range(spots.size()):
				var s: Vector2 = spots[i]
				var p := Vector2(s.x * w, s.y * h)
				var r: float = (2.6 if i % 3 == 0 else 1.8) * k
				if _inside(p, w, h, r):
					ci.draw_circle(c + p.rotated(rot), r, acc if i % 2 == 0 else dk)
		"blue":   # waves
			for row in [-0.35, 0.15, 0.6]:
				var pts: Array = []
				for i in range(17):
					var x: float = -1.0 + 2.0 * float(i) / 16.0
					pts.append(Vector2(x * w, (float(row) + 0.09 * sin(x * 7.0)) * h))
				_poly_line(ci, c, rot, pts, w, h, acc, 2.4 * k)
		"green":   # leaves
			for s in [Vector2(-0.3, -0.35), Vector2(0.32, 0.0), Vector2(-0.2, 0.45), Vector2(0.15, -0.7)]:
				var p := Vector2(s.x * w, s.y * h)
				var dir := Vector2(1, -1).normalized().rotated(s.x * 2.0) * 6.5 * k
				var nrm := Vector2(-dir.y, dir.x) * 0.55
				var leaf := PackedVector2Array([c + (p - dir).rotated(rot), c + (p + nrm).rotated(rot), c + (p + dir).rotated(rot), c + (p - nrm).rotated(rot)])
				if _inside(p - dir, w, h, 1.0) and _inside(p + dir, w, h, 1.0):
					ci.draw_colored_polygon(leaf, acc)
					ci.draw_line(c + (p - dir).rotated(rot), c + (p + dir).rotated(rot), dk, 1.0 * k)
		"yellow":   # a zigzag band
			for band in [0.05]:
				var top: Array = []
				var bot: Array = []
				for i in range(11):
					var x: float = -1.0 + 0.2 * float(i)
					var up: float = -0.16 if i % 2 == 0 else 0.0
					top.append(Vector2(x * w, (float(band) + up) * h))
					bot.append(Vector2(x * w, (float(band) + up + 0.17) * h))
				_poly_line(ci, c, rot, top, w, h, dk, 2.2 * k)
				_poly_line(ci, c, rot, bot, w, h, acc, 3.2 * k)
		"brown":   # bands
			for row in [-0.45, 0.0, 0.45]:
				var pts: Array = []
				for i in range(13):
					var x: float = -1.0 + 2.0 * float(i) / 12.0
					pts.append(Vector2(x * w, float(row) * h))
				_poly_line(ci, c, rot, pts, w, h, acc if row != 0.0 else dk, (4.0 if row == 0.0 else 2.6) * k)
		"purple":   # swirls
			for s in [Vector2(-0.25, -0.3), Vector2(0.28, 0.3)]:
				var pts: Array = []
				var o := Vector2(s.x * w, s.y * h)
				for i in range(22):
					var a: float = float(i) * 0.5
					pts.append(o + Vector2.from_angle(a) * (0.6 + float(i) * 0.33) * k)
				_poly_line(ci, c, rot, pts, w, h, acc, 2.0 * k)
			var dot := Vector2(0.3 * w, -0.6 * h)
			ci.draw_circle(c + dot.rotated(rot), 1.8 * k, dk)
	# shading: darker on the lower right, a shine on the upper left
	var sh := PackedVector2Array()
	for i in range(N / 2 + 1):
		var a: float = PI * 0.15 + PI * float(i) / float(N / 2)
		var yn: float = -cos(a)
		sh.append(c + Vector2(sin(a) * (1.0 + 0.14 * yn) * w, yn * h).rotated(rot))
	for i in range(N / 2, -1, -1):
		var a: float = PI * 0.15 + PI * float(i) / float(N / 2)
		var yn: float = -cos(a)
		sh.append(c + Vector2(sin(a) * (1.0 + 0.14 * yn) * w * 0.72 - w * 0.12, yn * h * 0.92).rotated(rot))
	ci.draw_colored_polygon(sh, Color(dk.r, dk.g, dk.b, 0.16))
	ci.draw_circle(c + Vector2(-w * 0.38, -h * 0.42).rotated(rot), 3.2 * k, Color(1, 1, 1, 0.85))
	ci.draw_circle(c + Vector2(-w * 0.5, -h * 0.18).rotated(rot), 1.6 * k, Color(1, 1, 1, 0.7))
	if crack > 0.0:
		_cracks(ci, c, rot, w, h, k, crack)


# Cracks grow from the top as `crack` goes 0..1 (the hatch scene).
static func _cracks(ci: CanvasItem, c: Vector2, rot: float, w: float, h: float, k: float, crack: float) -> void:
	var path := [Vector2(0.0, -0.95), Vector2(0.12, -0.7), Vector2(-0.08, -0.5), Vector2(0.18, -0.3), Vector2(-0.05, -0.1), Vector2(0.2, 0.1)]
	var side := [Vector2(-0.08, -0.5), Vector2(-0.35, -0.42), Vector2(-0.5, -0.2)]
	var nseg: int = int(ceil(crack * float(path.size() - 1)))
	for i in range(nseg):
		ci.draw_line(c + Vector2(path[i].x * w, path[i].y * h).rotated(rot), c + Vector2(path[i + 1].x * w, path[i + 1].y * h).rotated(rot), OUTLINE, 2.0 * k)
	if crack > 0.6:
		for i in range(side.size() - 1):
			ci.draw_line(c + Vector2(side[i].x * w, side[i].y * h).rotated(rot), c + Vector2(side[i + 1].x * w, side[i + 1].y * h).rotated(rot), OUTLINE, 1.6 * k)
