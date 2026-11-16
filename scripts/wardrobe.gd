extends RefCounted
# Wardrobe (docs/wardrobe.md): trails, auras and HUD frames, drawn in code. Cosmetic only.
# Save: SV.d["wardrobe"] = {"own": [ids], "trail": id or "", "aura": id or "", "frame": id, "new": [ids not seen yet]}.
const SV = preload("res://scripts/save_data.gd")

const KINDS := ["trail", "aura", "frame"]
const KIND_NAME := {"trail": "Trails", "aura": "Auras", "frame": "HUD frames"}
# id: [kind, name, source, source id]  (source: free / ach / medal / gacha)
const ITEMS := {
	"sparkle": ["trail", "Sparkle", "free", ""],
	"flame": ["trail", "Flame", "ach", "time10"],
	"bubble": ["trail", "Bubble", "medal", "rescue1"],
	"petal": ["trail", "Petal", "ach", "egg1"],
	"leaf": ["trail", "Leaf", "medal", "alpha"],
	"star": ["trail", "Star", "ach", "shiny1"],
	"snow": ["trail", "Snow", "medal", "night"],
	"rainbow": ["trail", "Rainbow", "gacha", ""],
	"glow": ["aura", "Glow", "free", ""],
	"ember": ["aura", "Ember", "ach", "hard15"],
	"ripple": ["aura", "Ripple", "medal", "cave1"],
	"bloom": ["aura", "Bloom", "ach", "own50"],
	"spark": ["aura", "Spark", "medal", "secret1"],
	"shadow": ["aura", "Shadow", "gacha", ""],
	"classic": ["frame", "Classic", "free", ""],
	"gold": ["frame", "Gold", "ach", "time30"],
	"crystal": ["frame", "Crystal", "medal", "deoxys"],
	"neon": ["frame", "Neon", "gacha", ""],
}
const ORDER := ["sparkle", "flame", "bubble", "petal", "leaf", "star", "snow", "rainbow", "glow", "ember", "ripple", "bloom", "spark", "shadow",
	"classic", "gold", "crystal", "neon"]
const GACHA_CHANCE := 0.10   # per 10-pull: one gacha-only item you don't own


static func data() -> Dictionary:
	SV.ensure()
	if not (SV.d.get("wardrobe") is Dictionary):
		SV.d["wardrobe"] = {}
	var w: Dictionary = SV.d["wardrobe"]
	if not (w.get("own") is Array):
		w["own"] = []
	for id in ORDER:
		if String(ITEMS[id][2]) == "free" and not (w["own"] as Array).has(id):
			(w["own"] as Array).append(id)
	if not (w.get("new") is Array):
		w["new"] = []
	for k in KINDS:
		if not w.has(k) or not (w[k] is String):
			w[k] = "classic" if k == "frame" else ""
	return w


static func kind_of(id: String) -> String:
	return String(ITEMS.get(id, ["", ""])[0])


static func owns(id: String) -> bool:
	return (data()["own"] as Array).has(id)


static func equipped(kind: String) -> String:
	var id: String = String(data().get(kind, ""))
	return id if id == "" or owns(id) else ("classic" if kind == "frame" else "")


# Equip an owned item ("" takes the trail or aura off; frames fall back to Classic).
static func equip(kind: String, id: String) -> bool:
	if id != "" and (not owns(id) or kind_of(id) != kind):
		return false
	data()[kind] = id if id != "" else ("classic" if kind == "frame" else "")
	return true


static func unlock(id: String) -> bool:
	if not ITEMS.has(id) or owns(id):
		return false
	var w: Dictionary = data()
	(w["own"] as Array).append(id)
	(w["new"] as Array).append(id)
	return true


# Gives every item whose achievement or medal you already have. Returns the ids newly unlocked.
static func sync() -> Array:
	var got: Array = []
	var ach: Dictionary = SV.d.get("ach", {})
	var medals: Dictionary = SV.d.get("medals", {})
	for id in ORDER:
		var src: String = String(ITEMS[id][2])
		var sid: String = String(ITEMS[id][3])
		var have := false
		if src == "ach":
			have = ach.has(sid)
		elif src == "medal":
			have = medals.get(sid, {}) is Dictionary and bool(medals.get(sid, {}).get("got", false))
		if have and unlock(id):
			got.append(id)
	return got


# A 10-pull's extra: sometimes one gacha-only item you don't own. Returns its id or "".
static func gacha_roll(force: bool = false) -> String:
	var pool: Array = ORDER.filter(func(id): return String(ITEMS[id][2]) == "gacha" and not owns(id))
	if pool.is_empty() or (not force and randf() >= GACHA_CHANCE):
		return ""
	var id: String = String(pool[randi() % pool.size()])
	unlock(id)
	return id


static func seen_all() -> void:
	data()["new"] = []


static func source_text(id: String, L) -> String:
	var src: String = String(ITEMS[id][2])
	var sid: String = String(ITEMS[id][3])
	match src:
		"free":
			return L.t("Free")
		"gacha":
			return L.t("Gacha: sometimes from a 10-pull")
		"ach":
			var PG = load("res://scripts/progress.gd")
			for a in PG.list():
				if String(a["id"]) == sid:
					return L.t("Achievement: %s") % PG.name_of(a)
		"medal":
			var ACH = load("res://scripts/ach.gd")
			var df: Array = ACH.def_of(sid)
			if not df.is_empty():
				return L.t("Medal: %s") % L.t(String(df[2]))
	return ""


# ---------------------------------------------------------------- drawing ----------------------------------------------------------------
static func _rng(seed: int) -> float:   # a stable 0..1 per particle
	return fposmod(sin(float(seed) * 12.9898) * 43758.5453, 1.0)


static func _star(ci: CanvasItem, c: Vector2, r: float, rot: float, col: Color, pts: int = 5) -> void:
	var poly := PackedVector2Array()
	for i in range(pts * 2):
		var rr: float = r if i % 2 == 0 else r * 0.45
		poly.append(c + Vector2.from_angle(rot + PI * float(i) / float(pts)) * rr)
	ci.draw_colored_polygon(poly, col)


# One trail particle: position p, age a (0 new .. 1 gone), seed s, k = size scale.
static func draw_trail_bit(ci: CanvasItem, style: String, p: Vector2, a: float, s: int, k: float = 1.0) -> void:
	var f: float = 1.0 - a   # fades out
	var r1: float = _rng(s)
	var r2: float = _rng(s + 7)
	match style:
		"sparkle":
			var tw: float = 0.6 + 0.4 * sin(a * 18.0 + r1 * 6.0)
			var c := Color(1.0, 0.95, 0.55, f * tw)
			var sz: float = (4.0 + 4.0 * r1) * k * (0.6 + 0.4 * f)
			ci.draw_circle(p, sz * 0.7, Color(1.0, 0.9, 0.4, 0.18 * f))
			ci.draw_line(p + Vector2(-sz, 0), p + Vector2(sz, 0), c, 2.0 * k)
			ci.draw_line(p + Vector2(0, -sz), p + Vector2(0, sz), c, 2.0 * k)
			ci.draw_circle(p, 1.8 * k, Color(1, 1, 1, f))
		"flame":
			var q: Vector2 = p + Vector2((r1 - 0.5) * 8.0, -a * 22.0) * k
			var rr: float = (5.0 + 3.0 * r2) * k * f
			ci.draw_circle(q, rr, Color(1.0, 0.45, 0.1, 0.55 * f))
			ci.draw_circle(q + Vector2(0, -rr * 0.2), rr * 0.6, Color(1.0, 0.85, 0.3, 0.75 * f))
		"bubble":
			var q: Vector2 = p + Vector2(sin(a * 6.0 + r1 * 6.0) * 4.0, -a * 18.0) * k
			var rr: float = (3.0 + 4.0 * r2 + a * 3.0) * k
			ci.draw_arc(q, rr, 0.0, TAU, 14, Color(0.6, 0.85, 1.0, 0.8 * f), 1.4 * k)
			ci.draw_circle(q + Vector2(-rr * 0.35, -rr * 0.35), rr * 0.22, Color(1, 1, 1, 0.8 * f))
		"petal":
			var q: Vector2 = p + Vector2((r1 - 0.5) * 16.0 * a, a * 6.0) * k
			var rot: float = r2 * TAU + a * 4.0
			var d: Vector2 = Vector2.from_angle(rot) * 5.5 * k
			var n := Vector2(-d.y, d.x) * 0.55
			var o: float = 1.4
			ci.draw_colored_polygon(PackedVector2Array([q - d * 1.25, q + n * o, q + d * 1.25, q - n * o]), Color(0.45, 0.1, 0.3, 0.6 * f))
			ci.draw_colored_polygon(PackedVector2Array([q - d, q + n, q + d, q - n]), Color(1.0, 0.55, 0.78, f))
			ci.draw_circle(q - d * 0.3, 1.0 * k, Color(1, 0.9, 0.95, f))
		"leaf":
			var q: Vector2 = p + Vector2((r1 - 0.5) * 14.0 * a, a * 4.0) * k
			var rot: float = r2 * TAU + a * 3.0
			var d: Vector2 = Vector2.from_angle(rot) * 6.5 * k
			var n := Vector2(-d.y, d.x) * 0.45
			ci.draw_colored_polygon(PackedVector2Array([q - d * 1.2, q + n * 1.45, q + d * 1.2, q - n * 1.45]), Color(0.08, 0.25, 0.08, 0.7 * f))
			ci.draw_colored_polygon(PackedVector2Array([q - d, q + n, q + d, q - n]), Color(0.72, 0.95, 0.35, f))
			ci.draw_line(q - d, q + d, Color(0.25, 0.55, 0.15, f), 1.2)
		"star":
			_star(ci, p + Vector2(0, -a * 8.0) * k, (4.0 + 2.0 * r1) * k * (0.5 + 0.5 * f), r2 * TAU + a * 5.0, Color(1.0, 0.85, 0.25, 0.9 * f))
		"snow":
			var q: Vector2 = p + Vector2(sin(a * 5.0 + r1 * 6.0) * 5.0, a * 10.0) * k
			var sz: float = (2.5 + 2.0 * r2) * k
			var c := Color(0.92, 0.97, 1.0, 0.9 * f)
			for i in range(3):
				var d: Vector2 = Vector2.from_angle(float(i) * PI / 3.0 + r1) * sz
				ci.draw_line(q - d, q + d, c, 1.2 * k)
		"rainbow":
			var c := Color.from_hsv(fposmod(float(s) * 0.07, 1.0), 0.65, 1.0, 0.75 * f)
			ci.draw_circle(p, (5.0 * f + 1.5) * k, c)


# The aura ring at the feet: c = feet, w = half width, t = time, k = particle quality (0.35..1).
static func draw_aura(ci: CanvasItem, style: String, c: Vector2, w: float, t: float, k: float = 1.0) -> void:
	var ell := func(r: float, col: Color, width: float, segs: int = 40, a0: float = 0.0, a1: float = TAU) -> void:
		var pts := PackedVector2Array()
		for i in range(segs + 1):
			var an: float = lerpf(a0, a1, float(i) / float(segs))
			pts.append(c + Vector2(cos(an) * r, sin(an) * r * 0.38))
		ci.draw_polyline(pts, col, width)
	var nbits: int = maxi(3, int(round(8.0 * k)))
	match style:
		"glow":
			var p: float = 0.5 + 0.5 * sin(t * 2.5)
			ell.call(w * 1.05, Color(1.0, 0.95, 0.6, 0.5 + 0.25 * p), 3.0)
			ell.call(w * 1.22, Color(1.0, 0.9, 0.5, 0.2 + 0.12 * p), 5.0)
		"ember":
			ell.call(w * 1.05, Color(1.0, 0.45, 0.1, 0.7), 3.0)
			for i in range(nbits):
				var ph: float = fposmod(t * 0.7 + float(i) / float(nbits), 1.0)
				var an: float = float(i) * TAU / float(nbits) + t * 0.4
				var q: Vector2 = c + Vector2(cos(an) * w, sin(an) * w * 0.38 - ph * 26.0)
				ci.draw_circle(q, 3.0 * (1.0 - ph), Color(1.0, 0.75, 0.25, 0.9 * (1.0 - ph)))
		"ripple":
			for i in range(3):
				var ph: float = fposmod(t * 0.6 + float(i) / 3.0, 1.0)
				ell.call(w * (0.6 + 0.8 * ph), Color(0.55, 0.85, 1.0, 0.75 * (1.0 - ph)), 2.8)
		"bloom":
			ell.call(w * 1.0, Color(0.55, 0.9, 0.45, 0.5), 2.5)
			for i in range(nbits):
				var an: float = float(i) * TAU / float(nbits) + t * 0.8
				var q: Vector2 = c + Vector2(cos(an) * w * 1.08, sin(an) * w * 0.41)
				var d: Vector2 = Vector2.from_angle(an + PI * 0.5) * 6.0
				var n := Vector2(-d.y, d.x) * 0.5
				ci.draw_colored_polygon(PackedVector2Array([q - d, q + n, q + d, q - n]), Color(1.0, 0.6, 0.8, 0.7) if i % 2 else Color(0.5, 0.9, 0.45, 0.7))
		"spark":
			var pts := PackedVector2Array()
			var segs: int = 24
			for i in range(segs + 1):
				var an: float = TAU * float(i) / float(segs)
				var jag: float = 1.0 + (0.12 if (i + int(t * 12.0)) % 2 == 0 else -0.08)
				pts.append(c + Vector2(cos(an) * w * jag, sin(an) * w * 0.38 * jag))
			ci.draw_polyline(pts, Color(1.0, 0.92, 0.3, 0.9), 2.5)
			ell.call(w * 1.15, Color(0.6, 0.9, 1.0, 0.25 + 0.15 * sin(t * 9.0)), 1.5)
		"shadow":
			ell.call(w * 1.0, Color(0.5, 0.22, 0.72, 0.75), 3.5)
			for i in range(nbits):
				var ph: float = fposmod(t * 0.5 + float(i) / float(nbits), 1.0)
				var an: float = float(i) * TAU / float(nbits) - t * 0.3
				var q: Vector2 = c + Vector2(cos(an) * w * 0.95, sin(an) * w * 0.36 - ph * 18.0)
				ci.draw_circle(q, 3.2 * (1.0 - ph), Color(0.3, 0.1, 0.45, 0.6 * (1.0 - ph)))


# The HUD frame around the Pokémon card (r = the card's rectangle).
static func draw_frame(ci: CanvasItem, style: String, r: Rect2, t: float) -> void:
	match style:
		"gold":
			var g := Color("#ffd65c")
			ci.draw_rect(r.grow(3.0), Color("#7a5410"), false, 2.0)
			ci.draw_rect(r.grow(1.0), g, false, 2.0)
			for cc in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
				ci.draw_rect(Rect2(cc - Vector2(5, 5), Vector2(10, 10)), g)
				ci.draw_rect(Rect2(cc - Vector2(2, 2), Vector2(4, 4)), Color("#fff4c2"))
			var sx: float = r.position.x + fposmod(t * 0.25, 1.0) * r.size.x   # a glint running along the top
			ci.draw_line(Vector2(sx - 10.0, r.position.y - 1.0), Vector2(sx + 10.0, r.position.y - 1.0), Color(1, 1, 1, 0.8), 2.0)
		"crystal":
			var cy := Color("#9ff0ff")
			ci.draw_rect(r.grow(1.0), Color(cy, 0.9), false, 2.0)
			for i in range(4):
				var cc: Vector2 = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)][i]
				var dx: float = 1.0 if i == 0 or i == 3 else -1.0
				var dy: float = 1.0 if i < 2 else -1.0
				ci.draw_colored_polygon(PackedVector2Array([cc + Vector2(-4 * dx, -4 * dy), cc + Vector2(14 * dx, -4 * dy), cc + Vector2(-4 * dx, 14 * dy)]), Color(cy, 0.85))
				ci.draw_colored_polygon(PackedVector2Array([cc + Vector2(-1 * dx, -1 * dy), cc + Vector2(7 * dx, -1 * dy), cc + Vector2(-1 * dx, 7 * dy)]), Color(1, 1, 1, 0.5 + 0.4 * sin(t * 3.0 + float(i))))
		"neon":
			var p: float = 0.5 + 0.5 * sin(t * 3.0)
			var a := Color("#ff4fd8")
			var b := Color("#4fe3ff")
			ci.draw_rect(r.grow(5.0), Color(a, 0.18 + 0.12 * p), false, 6.0)
			ci.draw_rect(r.grow(2.0), a.lerp(b, p), false, 2.0)
			ci.draw_rect(r.grow(-1.0), Color(b, 0.35), false, 1.0)
