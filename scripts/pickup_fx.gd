extends RefCounted
# Idle "juice" for things lying on the ground (chests, parcels, supply crates, pouches, Elixirs, Prism Crystals and the
# rarer drops): a soft glow in the item's colour, a breathing ground shadow, a light sweep every few seconds and
# twinkling sparkles. All drawn with plain shapes on the item's own canvas, so they cost almost nothing.


# Soft layered glow around c, pulsing gently.
static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, t: float, strength: float = 1.0) -> void:
	var beat: float = 0.5 + 0.5 * sin(t * 3.0)
	for i in range(3):
		ci.draw_circle(c, r * (1.0 - float(i) * 0.28) + beat * 3.0, Color(col.r, col.g, col.b, (0.05 + 0.045 * float(i)) * strength))


# Ground shadow: an ellipse that shrinks a little while the item bobs up.
static func shadow(ci: CanvasItem, w: float, lift: float) -> void:
	var k: float = clampf(1.0 - lift * 0.03, 0.7, 1.0)
	var pts := PackedVector2Array()
	for i in range(20):
		var a: float = TAU * float(i) / 20.0
		pts.append(Vector2(cos(a) * w * k, 2.0 + sin(a) * w * 0.32 * k))
	ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.3))


# A diagonal light sweep across rect r, once every `period` seconds (it only shows for the first third of the cycle).
static func shine(ci: CanvasItem, r: Rect2, t: float, period: float = 2.8, seed_off: float = 0.0) -> void:
	var ph: float = fposmod(t + seed_off, period) / period
	if ph > 0.33:
		return
	var sx: float = lerpf(-r.size.x * 0.5, r.size.x * 1.3, ph / 0.33)
	var band := PackedVector2Array([r.position + Vector2(sx, 0.0), r.position + Vector2(sx + r.size.x * 0.22, 0.0),
		r.position + Vector2(sx - r.size.x * 0.1, r.size.y), r.position + Vector2(sx - r.size.x * 0.32, r.size.y)])
	var box := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	for poly in Geometry2D.intersect_polygons(band, box):
		ci.draw_colored_polygon(poly, Color(1.0, 1.0, 0.95, 0.28))


# n four-point sparkles twinkling around c (within rx by ry).
static func sparkles(ci: CanvasItem, c: Vector2, rx: float, ry: float, t: float, n: int, col: Color) -> void:
	for i in range(n):
		var ph: float = fposmod(t * 0.7 + float(i) * 0.37, 1.0)
		if ph > 0.45:
			continue
		var sz: float = 3.2 * sin(ph / 0.45 * PI)
		var p := c + Vector2(cos(float(i) * 2.39 + 0.6) * rx, sin(float(i) * 1.71 + 0.3) * ry)
		var cc := Color(col.r, col.g, col.b, 0.95)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -sz * 1.8), p + Vector2(sz * 0.45, 0), p + Vector2(0, sz * 1.8), p + Vector2(-sz * 0.45, 0)]), cc)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-sz * 1.8, 0), p + Vector2(0, sz * 0.45), p + Vector2(sz * 1.8, 0), p + Vector2(0, -sz * 0.45)]), cc)
