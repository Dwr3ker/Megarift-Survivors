extends RefCounted
# Paleta y formas de la interfaz: "Dusk Tide" (mezcla propia de las versiones de PokeSurvivor).
# Toda la UI debe leer de aqui en vez de usar colores sueltos. Solo colores y medidas; sin recursos copiados.

const INK := Color("#141028")
const BG := Color("#1c1833")
const PANEL := Color("#2b2547")
const PANEL_HI := Color("#3a3262")
const EDGE := Color("#5a5099")
const TEXT := Color("#f2e9d8")
const TITLE := Color("#fff7d6")
const MUTED := Color("#b4aed6")
const WAVE := Color("#40d6ff")
const EMBER := Color("#ff7a45")
const GOLD := Color("#ffd65c")
const ORCHID := Color("#d77bff")
const GREEN := Color("#6fd08a")
const RED := Color("#ff6b5a")
const BAR := Color("#d9cdb5")
const SHADOW := Color(0.051, 0.039, 0.102, 0.8)   # #0d0a1acc
const SHADOW_OFF := Vector2(4, 4)
const BACKDROP := INK

# Escala de rareza (la del juego original).
const RARITY := [Color("#9fb1c9"), Color("#5fe08a"), Color("#4fb4ff"), Color("#c47bff"), Color("#ffcb3d")]

# Presets de acento: [nombre, acento, acento resaltado].
const ACCENTS := [
	["Wave", "#40d6ff", "#9be8ff"],
	["Ember", "#ff7a45", "#ffae8a"],
	["Gold", "#ffd65c", "#fff0a8"],
	["Orchid", "#d77bff", "#ebb8ff"],
]

static var _frame_cache := {}


# Pixel frame + soft drop shadow in one StyleBox (a StyleBoxTexture cannot cast a shadow by itself).
class ShadowFrame extends StyleBox:
	@export var inner: StyleBoxTexture = null

	func _draw(to_canvas_item: RID, rect: Rect2) -> void:
		for L in [[7.0, 0.10], [5.0, 0.14], [3.0, 0.18], [1.0, 0.22]]:
			var e: float = float(L[0])
			RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(rect.position + Vector2(-e, -e + 4.0), rect.size + Vector2(e * 2.0, e * 2.0)), Color(0, 0, 0, float(L[1])))
		inner.draw(to_canvas_item, rect)

	func _get_minimum_size() -> Vector2:
		return inner.get_minimum_size()

# Modo para daltonismo: el eje verde/rojo pasa a azul/magenta (y el HUD anade patrones).
static var colorblind := false


static func ok() -> Color:
	return Color("#4fb4ff") if colorblind else GREEN


static func bad() -> Color:
	return Color("#ff4fd8") if colorblind else RED


static func up() -> Color:
	return Color("#4fb4ff") if colorblind else GOLD


# Mezcla del fondo de boton con el acento, para los presets.
static func btn_fill(i: int) -> Color:
	return PANEL.lerp(accent(i), 0.18)


static func btn_fill_hi(i: int) -> Color:
	return PANEL.lerp(accent(i), 0.40)


static func accent(i: int) -> Color:
	return Color(String(ACCENTS[clampi(i, 0, ACCENTS.size() - 1)][1]))


static func accent_hi(i: int) -> Color:
	return Color(String(ACCENTS[clampi(i, 0, ACCENTS.size() - 1)][2]))


# Caja plana con borde y sombra dura desplazada (sin esquinas redondeadas).
static func box(fill: Color, edge: Color = EDGE, bw: int = 3, shadow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(bw)
	s.set_corner_radius_all(0)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.anti_aliasing = false
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 5
		s.shadow_offset = Vector2(0, 3)
	return s


# Marco de pixeles con esquinas achaflanadas: contorno tinta, banda de acento y relleno.
# Se dibuja en codigo (12x12) y se usa como 9-slice; se guarda en cache por combinacion de colores.
static func frame(fill: Color = PANEL, band: Color = EDGE, shadow: bool = true) -> StyleBox:
	var key := "%s|%s|%s" % [fill.to_html(), band.to_html(), str(shadow)]
	if _frame_cache.has(key):
		return _frame_cache[key]
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(12):
		for x in range(12):
			var cx: int = mini(x, 11 - x)
			var cy: int = mini(y, 11 - y)
			var d: int = mini(cx, cy)
			# esquinas achaflanadas: se quita el pixel mas externo y el chaflan de 2 px
			if cx < 2 and cy < 2 and (cx + cy) < 2:
				continue
			if d == 0:
				img.set_pixel(x, y, INK)
			elif d == 1:
				img.set_pixel(x, y, band)
			else:
				img.set_pixel(x, y, fill)
	var st := StyleBoxTexture.new()
	st.texture = ImageTexture.create_from_image(img)
	st.texture_margin_left = 4
	st.texture_margin_right = 4
	st.texture_margin_top = 4
	st.texture_margin_bottom = 4
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	st.draw_center = true
	var out: StyleBox = st
	if shadow:
		var sf := ShadowFrame.new()
		sf.inner = st
		sf.content_margin_left = st.content_margin_left
		sf.content_margin_right = st.content_margin_right
		sf.content_margin_top = st.content_margin_top
		sf.content_margin_bottom = st.content_margin_bottom
		out = sf
	_frame_cache[key] = out
	return out
