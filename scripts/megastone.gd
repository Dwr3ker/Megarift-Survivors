extends RefCounted
# Pixel icons for the item each form uses (data/megas.json "item"), drawn in code and cached per Pokémon:
# - Mega Stones: an orb with a swirl, coloured after the Mega form's types (base colour + swirl colour)
# - Red Orb / Blue Orb (Primal): an orb with a gold mark
# - Mega Shard (Rayquaza): a crystal shard
# - Rusted Sword / Rusted Shield (Crowned): a small rusty sword or shield
const MG = preload("res://scripts/mega.gd")
const MD = preload("res://scripts/moves_data.gd")
const SV = preload("res://scripts/save_data.gd")
const N := 14   # icon size in art pixels

static var _cache: Dictionary = {}

const INK := Color("#15131f")

# swirl strands of the stone, in a 14x14 grid (two strands crossing the middle)
const SWIRL_A := [Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 4), Vector2i(7, 5), Vector2i(6, 6), Vector2i(6, 7), Vector2i(7, 8), Vector2i(7, 9), Vector2i(8, 10)]
const SWIRL_B := [Vector2i(8, 3), Vector2i(9, 4), Vector2i(9, 5), Vector2i(8, 6), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 8), Vector2i(9, 9), Vector2i(8, 10)]
const SWORD := ["..........##..", ".........#oo#.", "........#oo#..", ".......#oo#...", "......#oo#....", "..#..#oo#.....", "..##.#o#......", "...####.......", "...###........", "..#..##.......", ".##...........", "##............"]
const SHIELD := ["..##########..", ".#oooooooooo#.", ".#o++oooo++o#.", ".#o++oooo++o#.", ".#oooo##oooo#.", ".#ooo####ooo#.", ".#oooo##oooo#.", "..#oooooooo#..", "..#o++oo++o#..", "...#oooooo#...", "....#oooo#....", ".....#oo#.....", "......##......"]
const SHARD := [".......#......", "......#o#.....", "......#oo#....", ".....#ooo#....", ".....#o+oo#...", "....#oo+oo#...", "....#oo+ooo#..", "...#ooo+ooo#..", "...#oo+oooo#..", "....#o+ooo#...", ".....#ooo#....", "......###....."]


static func tex(dex: int) -> Texture2D:
	if _cache.has(dex):
		return _cache[dex]
	var f: Dictionary = MG.form_for(dex)
	if f.is_empty():
		return null
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var item: String = String(f.get("item", ""))
	match item:
		"Rusted Sword":
			_mask(img, SWORD, {"#": INK, "o": Color("#c58a5a"), "+": Color("#7d4e2e")})
		"Rusted Shield":
			_mask(img, SHIELD, {"#": INK, "o": Color("#b8794a"), "+": Color("#e0b27a")})
		"Mega Shard":
			_mask(img, SHARD, {"#": INK, "o": Color("#5ed88a"), "+": Color("#d8ffe6")})
		"Red Orb":
			_orb(img, Color("#d8342c"), Color("#ffd65c"), true)
		"Blue Orb":
			_orb(img, Color("#2f6fe0"), Color("#ffd65c"), true)
		_:
			var cols: Array = _type_cols(dex, f)
			_orb(img, cols[0], cols[1], false)
	var t := ImageTexture.create_from_image(img)
	_cache[dex] = t
	return t


# Base and swirl colours from the form's types (or the Pokémon's own), the swirl lighter so it always shows.
static func _type_cols(dex: int, f: Dictionary) -> Array:
	var types: Array = f.get("types", [])
	if types.is_empty():
		SV.load_dex()
		if SV.dex_by.has(dex):
			types = SV.dex_by[dex]["types"]
	var c1 := Color.html(String(MD.TYPE_COLOR.get(String(types[0]) if not types.is_empty() else "normal", "#b0a99f")))
	var c2: Color = Color.html(String(MD.TYPE_COLOR.get(String(types[1]), "#ffffff"))) if types.size() > 1 else c1.lightened(0.55)
	if absf(c1.get_luminance() - c2.get_luminance()) < 0.12:
		c2 = c2.lightened(0.45)
	return [c1, c2]


static func _orb(img: Image, base: Color, mark: Color, orb_mark: bool) -> void:
	var c := Vector2(6.5, 6.5)
	for y in range(N):
		for x in range(N):
			var d: float = Vector2(x, y).distance_to(c)
			if d > 6.6:
				continue
			if d > 5.6:
				img.set_pixel(x, y, INK)
				continue
			# lit from the top-left: lighter there, darker at the bottom-right
			var k: float = (float(x + y) - 13.0) / 13.0
			var col: Color = base.lightened(0.28) if k < -0.45 else (base if k < 0.3 else base.darkened(0.3))
			img.set_pixel(x, y, col)
	if orb_mark:
		for q in [Vector2i(6, 4), Vector2i(7, 4), Vector2i(5, 5), Vector2i(8, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(6, 7), Vector2i(7, 7), Vector2i(6, 8), Vector2i(7, 8), Vector2i(5, 9), Vector2i(8, 9)]:
			img.set_pixelv(q, mark)
	else:
		for q in SWIRL_A:
			img.set_pixelv(q, mark)
		for q in SWIRL_B:
			img.set_pixelv(q, mark.lerp(Color.WHITE, 0.35))
	img.set_pixel(4, 3, Color(1, 1, 1, 0.95))   # shine
	img.set_pixel(3, 4, Color(1, 1, 1, 0.7))


static func _mask(img: Image, rows: Array, pal: Dictionary) -> void:
	var oy: int = (N - rows.size()) / 2
	for j in range(rows.size()):
		var row: String = rows[j]
		for i in range(row.length()):
			var ch: String = row[i]
			if pal.has(ch):
				img.set_pixel(i, j + oy, pal[ch])
