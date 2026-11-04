extends RefCounted
# Fuente pixelada del juego desde v0.1.3: "Megarift Pixel", que es Fusion Pixel 12 (TakWolf, licencia OFL) con la altura de
# linea ajustada. Cubre latin, cirilico, kana y kanji/hanzi; lo poco que le falta (algun simbolo) lo dibuja Pixelify Sans
# detras. El vietnamita sigue usando Inter (Fusion Pixel no tiene todas sus tildes dobles).
# Japones y chino usan Noto Sans CJK (licencia OFL) como fuente de respaldo; tambien cubre simbolos.

const OUTLINE := Color("#1b1528")
const CJK := {
	"ja": "res://fonts/NotoCJK_ja.otf",
	"zh_CN": "res://fonts/NotoCJK_zh_CN.otf",
	"zh_HK": "res://fonts/NotoCJK_zh_HK.otf",
}

const MAIN := "res://fonts/MegariftPixel.ttf"   # Fusion Pixel 12 (OFL, renamed: the line height is set to 1.25 like the old font; see CREDITS.md)
const PIXELIFY := "res://fonts/PixelifySansFix.ttf"   # second in line: the few symbols the main font lacks
const EMBOLDEN := 0.7   # thicker strokes: the pixel font reads better on a phone (0 = as drawn, 1 = heavy)
static var font: FontVariation = null
static var font_small: FontVariation = null   # same font without the extra boldness, for small text
static var lang_code := ""
# Small text: the font is drawn on a 12 px grid, so anything at or below SMALL_MAX is drawn at exactly 12 px (every font
# pixel lands on whole screen pixels) and without the extra boldness (at small sizes it fills the gaps inside letters).
const SMALL_MAX := 15
const GRID := 12


static func is_small(sz: int) -> bool:
	return sz <= SMALL_MAX


static func px_size(sz: int) -> int:
	return GRID if sz <= SMALL_MAX else sz


static func get_small() -> Font:
	if font_small == null:
		var f: Font = get_font()
		if not (f is FontVariation):
			return f
		font_small = (f as FontVariation).duplicate()
		font_small.variation_embolden = 0.0
		font_small.fallbacks = (f as FontVariation).fallbacks
	return font_small


# The font to draw a given size with (the thin one for small text, when it is the game font).
static func font_for(f: Font, sz: int) -> Font:
	if sz <= SMALL_MAX and f != null and f == font:
		return get_small()
	return f


# draw_string / draw_string_outline with the small-text rule applied (used by the run's HUD and cards).
static func dstr(ci: CanvasItem, f: Font, p: Vector2, t: String, al: int = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0, sz: int = 16, col: Color = Color.WHITE) -> void:
	ci.draw_string(font_for(f, sz), p, t, al, w, px_size(sz), col)


static func dstro(ci: CanvasItem, f: Font, p: Vector2, t: String, al: int = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0, sz: int = 16, o: int = 1, col: Color = Color.WHITE) -> void:
	ci.draw_string_outline(font_for(f, sz), p, t, al, w, px_size(sz), o, col)


# Labels / buttons: small sizes get the thin font at 12 px.
static func style_small(c: Control, sz: int) -> int:
	if sz <= SMALL_MAX and lang_code != "vi":
		c.add_theme_font_override("font", get_small())
		return GRID
	if c.has_theme_font_override("font") and c.get_theme_font("font") == font_small:
		c.remove_theme_font_override("font")   # grown back above the small sizes: the normal (bold) font again
	return sz


static func get_font() -> Font:
	if font == null:
		var base: FontFile = load(MAIN)
		if base == null:
			return ThemeDB.fallback_font
		_crisp(base)
		var px: FontFile = load(PIXELIFY)
		if px != null:
			_crisp(px)
		font = FontVariation.new()
		font.base_font = base
		font.variation_opentype = {"weight": 500}
		font.opentype_features = {"liga": 0, "clig": 0, "dlig": 0}
		font.variation_embolden = EMBOLDEN
		_set_fallbacks()
	return font


# The pixel font is drawn with hard pixel edges: no smoothing, no sub-pixel offsets. Godot already renders text at the
# screen's real resolution (font oversampling follows the window scale), so on a 1080p phone this keeps letters as sharp
# blocks instead of soft grey edges. Inter (Vietnamese) and the CJK fonts keep normal smoothing: they are not pixel fonts.
static func _crisp(f: FontFile) -> void:
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.hinting = TextServer.HINTING_NONE


# Respaldo segun el idioma: CJK propio (ja/zh) o, en el resto, el japones solo para simbolos.
static func _set_fallbacks() -> void:
	if font == null:
		return
	# Vietnamita: la fuente pixelada no trae todas las tildes, asi que se usa Inter (OFL) completa.
	var bp: String = "res://fonts/Inter_vi.otf" if lang_code == "vi" else MAIN
	var nb = load(bp)
	if nb is Font and font.base_font != nb:
		font.base_font = nb
	var path: String = CJK.get(lang_code, CJK["ja"])
	var fb = load(path)
	var arr: Array[Font] = []
	var pxf = load(PIXELIFY)
	if lang_code != "vi" and pxf is Font:
		arr.append(pxf)
	if fb is Font:
		arr.append(fb)
	font.fallbacks = arr
	if font_small != null:
		font_small.base_font = font.base_font
		font_small.fallbacks = arr


static func set_lang(code: String) -> void:
	lang_code = code
	if font != null:
		_set_fallbacks()


# Pone la fuente como predeterminada y, si se pasa un tema, con contorno oscuro.
static func apply(theme: Theme = null) -> void:
	var f: Font = get_font()
	ThemeDB.fallback_font = f
	if theme != null:
		theme.default_font = f
		for cls in ["Label", "Button", "CheckButton"]:
			# Sin sombra ni contorno: la sombra de 2 px dobla los trazos finos y parece un fallo de la fuente.
			theme.set_color("font_shadow_color", cls, Color(0, 0, 0, 0))
			theme.set_constant("shadow_offset_x", cls, 0)
			theme.set_constant("shadow_offset_y", cls, 0)
			theme.set_constant("outline_size", cls, 0)
