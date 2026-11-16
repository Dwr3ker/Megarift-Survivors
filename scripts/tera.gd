extends RefCounted
# Terastallization (docs/tera.md): a once-per-run crystal transformation into the Pokémon's Tera type.
# Step 4: the Tera Orb, which charges by defeating enemies during the run.

const NEED := 300.0      # defeats to fill the orb (a Z-Move unlock needs 250, but over all runs)
const BOSS_PTS := 10.0   # a boss counts as this many defeats
const DUR := 45.0        # how long it lasts (step 6)
const ATK_K := 1.5       # Terastallized: moves of the Tera type deal +50%
const BOSS_FROM := 600.0   # Tera bosses (step 14): from minute 10 of run time
const BOSS_CHANCE := 0.2   # about 1 regular boss in 5
const BOSS_AT := 0.5       # it Terastallizes when its HP falls to half
const ATK_K_OWN := 1.75  # +75% when the Tera type is also one of your own types (on top of the usual same-type bonus)


# Modes that have Tera (no Tower, like Dynamax).
static func mode_ok(mode: String) -> bool:
	return mode != "tower"


# Points one defeat adds to the orb.
static func pts_for(e) -> float:
	return BOSS_PTS if e != null and is_instance_valid(e) and bool(e.boss) else 1.0


# Damage multiplier for a move of the Tera type while Terastallized.
static func mult(own_type: bool) -> float:
	return ATK_K_OWN if own_type else ATK_K


# The Tera jewel (step 10): a faceted gem floating above the Terastallized Pokémon, in the Tera type's colour, with the
# type's emblem inside. Each type has its own colour and emblem, and one of six gem shapes, so all 18 look different.
const SHAPES := ["diamond", "hexagon", "crown", "star", "drop", "octagon"]
const TYPE_ORDER := ["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying",
	"psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]


static func shape_of(type: String) -> String:
	return String(SHAPES[maxi(0, TYPE_ORDER.find(type)) % SHAPES.size()])


class Jewel extends Node2D:
	const IC = preload("res://scripts/icons.gd")
	const MD = preload("res://scripts/moves_data.gd")
	var type := "normal"
	var h := 40.0       # body height: the jewel floats above it
	var s := 1.0        # size
	var t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(d: float) -> void:
		t += d
		var p = get_parent()
		if p != null and "body_h" in p:   # follows the body if it changes (Mega Evolution, Ultra Burst...)
			h = float(p.body_h)
		queue_redraw()

	func _outline(shape: String, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		match shape:
			"diamond":
				pts = PackedVector2Array([Vector2(0, -r * 1.25), Vector2(r * 0.85, 0), Vector2(0, r * 1.05), Vector2(-r * 0.85, 0)])
			"hexagon":
				for i in range(6):
					pts.append(Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 6.0) * r)
			"crown":
				pts = PackedVector2Array([Vector2(-r, r * 0.7), Vector2(-r, -r * 0.3), Vector2(-r * 0.5, r * 0.05), Vector2(0, -r * 1.1),
					Vector2(r * 0.5, r * 0.05), Vector2(r, -r * 0.3), Vector2(r, r * 0.7)])
			"star":
				for i in range(10):
					var rr: float = r * (1.15 if i % 2 == 0 else 0.55)
					pts.append(Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * rr)
			"drop":
				for i in range(12):
					var a: float = -PI * 0.5 + TAU * float(i) / 12.0
					var rr2: float = r * (1.3 if i == 0 else (0.95 if i == 1 or i == 11 else 0.9))
					pts.append(Vector2.from_angle(a) * rr2 + Vector2(0, r * 0.15))
			_:   # octagon
				for i in range(8):
					pts.append(Vector2.from_angle(-PI * 0.5 + PI / 8.0 + TAU * float(i) / 8.0) * r)
		return pts

	func _draw() -> void:
		var col := Color.html(String(MD.TYPE_COLOR.get(type, "#b0a99f")))
		var c := Vector2(0.0, -h - 26.0 * s + sin(t * 2.4) * 3.0 * s)
		var r: float = 15.0 * s
		var beat: float = 0.5 + 0.5 * sin(t * 3.0)
		draw_circle(c, r * 1.9, Color(col.r, col.g, col.b, 0.14 + 0.08 * beat))
		var shp: String = Jewel.shape_name(type)
		var outer: PackedVector2Array = _outline(shp, r + 2.0 * s)
		var body: PackedVector2Array = _outline(shp, r)
		for i in range(outer.size()):
			outer[i] += c
		for i in range(body.size()):
			body[i] += c
		draw_colored_polygon(outer, Color(0.05, 0.04, 0.1))
		draw_colored_polygon(body, col.darkened(0.15))
		# facets: alternate light and dark slices from the centre, lit from the top-left
		for i in range(body.size()):
			var a: Vector2 = body[i]
			var b: Vector2 = body[(i + 1) % body.size()]
			var mid: Vector2 = (a + b) * 0.5 - c
			var lit: float = clampf(0.5 - (mid.normalized().dot(Vector2(0.7, 0.7))) * 0.5, 0.0, 1.0)
			draw_colored_polygon(PackedVector2Array([c, a, b]), col.lerp(Color.WHITE, 0.45 * lit).darkened(0.25 * (1.0 - lit)))
		draw_polyline(body + PackedVector2Array([body[0]]), col.lightened(0.55), 1.5 * s)
		IC.draw_in(self, "type:" + type, c + Vector2(0, r * 0.05), r * 1.05)
		# a glint that runs across now and then
		var g: float = fposmod(t * 0.6, 1.0)
		if g < 0.25:
			var gp: Vector2 = c + Vector2(-r + 2.0 * r * g / 0.25, -r * 0.4)
			draw_rect(Rect2(gp - Vector2(2, 2) * s, Vector2(4, 4) * s), Color(1, 1, 1, 0.9))

	static func shape_name(ty: String) -> String:
		var order := ["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying",
			"psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
		var sh := ["diamond", "hexagon", "crown", "star", "drop", "octagon"]
		return String(sh[maxi(0, order.find(ty)) % sh.size()])


# The activation scene (step 11), drawn around the Pokémon: crystal shards close in from a ring and form a faceted
# shell (0 - 0.45 s), cracks spread across it (0.45 - 0.7 s), then it shatters and the shards fly out (0.7 - 1.3 s).
# main.gd shows the crystal look and the jewel at SHATTER, and the TERASTALLIZE banner.
const SHATTER := 0.7
const SCENE_LEN := 1.3


class Shell extends Node2D:
	var col := Color.WHITE
	var h := 40.0
	var w := 24.0
	var t := 0.0
	var shards: Array = []

	func _ready() -> void:
		z_index = 4
		for i in range(14):
			var a: float = TAU * float(i) / 14.0 + randf_range(-0.15, 0.15)
			shards.append({"a": a, "r0": randf_range(110.0, 150.0), "sz": randf_range(5.0, 9.0), "spin": randf_range(-6.0, 6.0), "out": randf_range(140.0, 260.0)})

	func _process(d: float) -> void:
		t += d
		if t >= SCENE_LEN:
			queue_free()
			return
		queue_redraw()

	func _hexa(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in range(6):
			var a: float = -PI * 0.5 + TAU * float(i) / 6.0
			p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return p

	func _shard(p: Vector2, sz: float, ang: float, a: float) -> void:
		var pts := PackedVector2Array([p + Vector2.from_angle(ang) * sz * 1.4, p + Vector2.from_angle(ang + 2.2) * sz * 0.7, p + Vector2.from_angle(ang + PI) * sz, p + Vector2.from_angle(ang - 2.2) * sz * 0.7])
		draw_colored_polygon(pts, Color(col.lerp(Color.WHITE, 0.35), a))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, a), 1.5)

	func _draw() -> void:
		var c := Vector2(0.0, -h * 0.5)
		var rx: float = maxf(w * 1.5, 30.0)
		var ry: float = maxf(h * 0.8, 34.0)
		if t < SHATTER:
			var k: float = clampf(t / 0.45, 0.0, 1.0)
			for s in shards:   # shards closing in
				var r: float = lerpf(float(s["r0"]), 0.0, k * k)
				var p: Vector2 = c + Vector2(cos(float(s["a"])) * r * 1.2, sin(float(s["a"])) * r * 0.8)
				_shard(p, float(s["sz"]), float(s["a"]) + t * float(s["spin"]), 1.0 - 0.6 * k)
			if k > 0.3:   # the shell forms
				var sa: float = clampf((k - 0.3) / 0.7, 0.0, 1.0)
				var hx: PackedVector2Array = _hexa(c, rx * (0.6 + 0.4 * sa), ry * (0.6 + 0.4 * sa))
				draw_colored_polygon(hx, Color(col.r, col.g, col.b, 0.45 * sa))
				for i in range(6):   # facets
					draw_line(c, hx[i], Color(1, 1, 1, 0.35 * sa), 1.5)
				draw_polyline(hx + PackedVector2Array([hx[0]]), Color(1, 1, 1, 0.9 * sa), 3.0)
			if t > 0.45:   # cracks spreading
				var ck: float = clampf((t - 0.45) / 0.25, 0.0, 1.0)
				for i in range(5):
					var a2: float = 0.4 + float(i) * 1.25
					var p0: Vector2 = c
					var p1: Vector2 = c + Vector2(cos(a2) * rx * 0.5, sin(a2) * ry * 0.5) * ck
					var p2: Vector2 = p1 + Vector2(cos(a2 + 0.6) * rx * 0.45, sin(a2 + 0.6) * ry * 0.45) * ck
					draw_polyline(PackedVector2Array([p0, p1, p2]), Color(1, 1, 1, 0.95), 2.0)
		else:
			var k2: float = clampf((t - SHATTER) / (SCENE_LEN - SHATTER), 0.0, 1.0)
			if k2 < 0.3:   # the flash of the break
				draw_circle(c, maxf(rx, ry) * (1.0 + k2 * 2.0), Color(1, 1, 1, 0.55 * (1.0 - k2 / 0.3)))
			for s in shards:   # shards flying out and fading
				var r2: float = lerpf(10.0, float(s["out"]), 1.0 - pow(1.0 - k2, 2.0))
				var p2: Vector2 = c + Vector2(cos(float(s["a"])), sin(float(s["a"])) * 0.8) * r2 + Vector2(0, 40.0 * k2 * k2)
				_shard(p2, float(s["sz"]) * (1.0 - 0.4 * k2), float(s["a"]) + t * float(s["spin"]) * 2.0, 1.0 - k2)



# A Tera boss's new type: one it doesn't already have.
static func boss_type(types: Array) -> String:
	var pool: Array = TYPE_ORDER.filter(func(t): return not types.has(t))
	return String(pool[randi() % pool.size()])
