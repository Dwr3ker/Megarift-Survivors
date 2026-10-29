extends Control
# Menu principal: jugar, Pokemon, mejoras, gacha, misiones y ajustes.
# Funciona con toque, mando (cruceta + A / B) y teclado (flechas + Enter / Esc).

const NAVG = preload("res://scripts/navgrid.gd")
const SV = preload("res://scripts/save_data.gd")
const Aud = preload("res://scripts/audio.gd")
const PG = preload("res://scripts/progress.gd")
const CH = preload("res://scripts/challenges.gd")
const L = preload("res://scripts/lang.gd")
const MD = preload("res://scripts/moves_data.gd")
const FUS = preload("res://scripts/fusions.gd")
const TD = preload("res://scripts/types_data.gd")
const KCX = preload("res://scripts/kecleon.gd")
const AB = preload("res://scripts/abilities.gd")
const ZM = preload("res://scripts/zmove.gd")
const DYN = preload("res://scripts/dynamax.gd")
const MG = preload("res://scripts/mega.gd")
const FM = preload("res://scripts/forme.gd")
const ST = preload("res://scripts/starters_data.gd")
const IC = preload("res://scripts/icons.gd")
const TXS = preload("res://scripts/textscale.gd")
const PXF = preload("res://scripts/pxfont.gd")
const DSP = preload("res://scripts/display.gd")
const SLOTS = preload("res://scripts/slots.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")
const UPD = preload("res://scripts/updater.gd")
const PN = preload("res://scripts/patchnotes.gd")
const UIS = preload("res://scripts/ui_style.gd")

var C_PANEL := Color("#2b2547")
var C_PANEL_D := Color("#1c1833")
var C_BTN := Color("#2f4568")
var C_BTN_H := Color("#336c91")
var C_ACC := Color("#40d6ff")
# Temas de interfaz (base Dusk Tide con acento): [panel, panel oscuro, acento, boton, boton resaltado]
const UI_THEMES := [
	["#2b2547", "#1c1833", Color("#40d6ff"), "#2f4568", "#336c91"],   # Wave
	["#2b2547", "#1c1833", Color("#ff7a45"), "#513447", "#804746"],   # Ember
	["#2b2547", "#1c1833", Color("#ffd65c"), "#51454b", "#806c4f"],   # Gold
	["#2b2547", "#1c1833", Color("#d77bff"), "#4a3468", "#704791"],   # Orchid
]
const DEFAULT_THEME := 0
const GP := preload("res://scripts/gachapon.gd")
const C_GOLD := Color("#ffd65c")
const CR = preload("res://scripts/crash_report.gd")
const CODES = preload("res://scripts/codes.gd")
const LayoutEditor = preload("res://scripts/layout_editor.gd")
const RS = preload("res://scripts/run_save.gd")
const PER_PAGE := 32   # 8 columns x 4 rows per page: the grid fits the screen without a half-clipped row
const PER_PAGE_COMPACT := 24   # 6 columns x 4 rows with bigger cards on squarer / handheld screens

var theme_main := Theme.new()
var screens := {}
var cur := ""
var coin_lbl: Label
var coin_pill: PanelContainer
var tix_pill: PanelContainer
var name_pill: Button
var name_lbl: Button
var tab_sel: Button
var fav_btns: Array = []   # botones de los 3 favoritos (para devolverles el foco al elegir)
var tab_row: Control
var mute_top: Button
var set_top: Button
var ticket_lbl: Label
var ticket10_lbl: Label
var toast_lbl: Label
var is_overlay := false
signal closed
var ach_pop: PanelContainer
var ach_box: HBoxContainer
var ach_t := 0.0
var toast_t := 0.0
var back_btn: Button
var credit_lbl: Label
var credit_box: VBoxContainer
var pad_hint: HBoxContainer
var pad_hint_key := ""
var shade: ColorRect
var focus_first: Control = null
var news_top: Button
var news_rail: VBoxContainer
var news_sel := 0
var support_top: Button
var support_focus: Button
var news_box: VBoxContainer
var news_scroll: ScrollContainer

# estado de pantallas
var dex_gen := 0
var dex_page := 0
var dex_only_owned := false
var dex_sel := 25
var dex_grid: GridContainer
var dex_page_lbl: Label
var dex_detail: VBoxContainer
var dex_prev: Preview
var gacha_region := 1
var gacha_box: VBoxContainer
var gacha_rail: VBoxContainer   # region list on the left
var gacha_result: Control
var gp_machine
var gp_info: VBoxContainer
var gp_msg: Label
var gp_btn1: Button
var gp_btn2: Button
var gp_focus: Control
var gp_collection: HFlowContainer
var up_picker: Control = null
var pk_gen := 0
var pk_type := ""
var pk_q := ""
var pk_focus := ""
var slots_ui: Control = null
var slots_busy := false
var goals_tab := "m"
var goals_box: VBoxContainer
var up_box: VBoxContainer
var up_head: VBoxContainer   # left column: portrait + Pokemon selector
var up_dex := 25
var ban_open := false
var tm_open := false
var main_prev: Preview
var main_card: PanelContainer
var main_info: Label
var main_stats: Label
var main_chips: Dictionary = {}
var main_news_ov: Control
var main_title: Label
var main_tagline: Label
var test_box: VBoxContainer
var test_idx := 0
var test_scores := {}
var test_result_dex := 0
var reset_armed := false
var settings_box: VBoxContainer


# ---------------------------------------------------------------
# Vista previa animada de un Pokemon (hoja Idle, fila 0)
# ---------------------------------------------------------------
class Preview extends Control:
	var dex := 25
	var shiny := false
	var scale_k := 5.0
	var dark := false
	var t := 0.0
	var frame := 0
	var tr: TextureRect = null
	var walk := false     # usa la hoja Walk (8 direcciones) en lugar de Idle
	var row := 0          # fila de la hoja = dirección

	func setup(d: int, shn: bool = false, k: float = 5.0, drk: bool = false) -> void:
		dex = d
		shiny = shn
		scale_k = k
		dark = drk
		frame = 0
		t = 0.0
		queue_redraw()

	static func anim_of(d: int, wk: bool = false) -> Dictionary:
		var SVl = load("res://scripts/save_data.gd")
		var sm: Dictionary = SVl.smeta.get(str(d), {})
		if sm.is_empty():
			return {}
		var a: Dictionary = sm["a"]
		var nm := "Idle" if a.has("Idle") else "Walk"
		if wk and a.has("Walk"):
			nm = "Walk"
		return {"name": nm, "info": a[nm], "sm": sm}

	static func tex_of(d: int, nm: String, shn: bool) -> Texture2D:
		if shn:
			var ps := "res://assets/pokemon/%d/s/%s.png" % [d, nm]
			if ResourceLoader.exists(ps):
				return load(ps)
		var p := "res://assets/pokemon/%d/%s.png" % [d, nm]
		if ResourceLoader.exists(p):
			return load(p)
		return null

	func _process(delta: float) -> void:
		var an: Dictionary = anim_of(dex, walk)
		if an.is_empty():
			return
		var info: Dictionary = an["info"]
		frame = frame % int(info["n"])
		t += delta * 60.0
		var guard := 0
		while t >= float(info["d"][frame]) and guard < 12:
			guard += 1
			t -= float(info["d"][frame])
			frame = (frame + 1) % int(info["n"])
		queue_redraw()

	func _draw() -> void:
		var an: Dictionary = anim_of(dex, walk)
		if an.is_empty():
			return
		var info: Dictionary = an["info"]
		var tx: Texture2D = tex_of(dex, String(an["name"]), shiny)
		if tx == null:
			draw_rect(Rect2(size * 0.5 - Vector2(16, 16), Vector2(32, 32)), Color(1, 1, 1, 0.15))
			return
		var w: float = float(info["w"])
		var h: float = float(info["h"])
		var k: float = scale_k
		# ajusta para que no se salga del cuadro
		k = minf(k, minf(size.x / w, size.y / h) * 0.92)
		var pos := Vector2(size.x * 0.5 - float(info["ax"]) * k, size.y * 0.5 + h * k * 0.5 - (h - float(info["ay"])) * k * 0.0 - float(info["ay"]) * k + (float(info["ay"]) * k) * 0.0)
		pos = Vector2(size.x * 0.5 - float(info["ax"]) * k, size.y * 0.84 - float(info["ay"]) * k)
		draw_set_transform(Vector2(size.x * 0.5, size.y * 0.84), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, w * k * 0.28, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if tr == null:
			tr = TextureRect.new()
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(tr)
		var at := AtlasTexture.new()
		at.atlas = tx
		var rows_n: int = maxi(1, int(round(tx.get_height() / h)))
		at.region = Rect2(float(frame) * w, float(mini(row, rows_n - 1)) * h if walk else 0.0, w, h)
		tr.texture = at
		tr.position = pos
		tr.size = Vector2(w * k, h * k)
		tr.modulate = Color(0, 0, 0, 0.9) if dark else Color.WHITE



# ---------------------------------------------------------------
# Pokemon animado que anda y ataca (como en Mundo Misterioso).
# Hojas: columnas = fotogramas, filas = 8 direcciones (0 abajo, 1 abajo-der, 2 der, 3 arriba-der, 4 arriba, 5 arriba-izq, 6 izq, 7 abajo-izq)
# ---------------------------------------------------------------
class Mon extends Node2D:
	var dex := 25
	var shiny := false
	var k := 3.0
	var bounds := Rect2(0.0, 0.0, 200.0, 40.0)
	var wander := true
	var state := "idle"
	var anim := "Idle"
	var frame := 0
	var t := 0.0
	var dir := 0
	var wait := 0.6
	var target := Vector2.ZERO
	var meta: Dictionary = {}
	var sprite: Sprite2D
	var shadow_w := 24.0
	var fx0 := 0.0
	var fx1 := 1.0
	var ysort := false
	var fixed := false      # quieto en su sitio, de frente, y embiste cada cierto tiempo (como en Mundo Misterioso)
	var home := Vector2.ZERO
	var lunge := 22.0
	var fdir := 0
	var walk_ok: Callable = Callable()   # (desde, hasta) -> bool: el camino esta libre de paredes y agua

	func setup(d: int, kk: float, shn: bool, b: Rect2, wd: bool = true) -> void:
		dex = d
		k = kk
		shiny = shn
		bounds = b
		wander = wd
		var SVl = load("res://scripts/save_data.gd")
		var sm: Dictionary = SVl.smeta.get(str(d), {})
		meta = sm.get("a", {})
		sprite = Sprite2D.new()
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		position = Vector2(randf_range(b.position.x, b.end.x), randf_range(b.position.y, b.end.y))
		wait = randf_range(0.2, 1.2)
		if meta.has("Idle"):
			shadow_w = float(meta["Idle"]["w"]) * k * 0.22
		_set_anim("Idle")

	func _set_anim(a: String) -> void:
		if meta.is_empty():
			return
		if not meta.has(a):
			a = "Idle" if meta.has("Idle") else "Walk"
		anim = a
		frame = 0
		t = 0.0
		_apply()

	func _lunge_vec() -> Vector2:
		var a: float = float(fdir) * PI / 4.0
		return Vector2(sin(a), cos(a))

	func _face(v: Vector2) -> void:
		var a: float = v.angle()
		dir = posmod(int(floor((PI / 2.0 - a) / (PI / 4.0) + 0.5)), 8)

	func _apply() -> void:
		if meta.is_empty() or not meta.has(anim):
			return
		var am: Dictionary = meta[anim]
		var tx: Texture2D = Preview.tex_of(dex, anim, shiny)
		if tx == null:
			sprite.visible = false
			return
		sprite.visible = true
		sprite.texture = tx
		sprite.offset = Vector2(-float(am["ax"]), -float(am["ay"]))
		sprite.scale = Vector2(k, k)
		var rows: int = int(am.get("r", 8))
		var w: float = float(am["w"])
		var h: float = float(am["h"])
		sprite.region_rect = Rect2(float(frame) * w, float(mini(dir, rows - 1)) * h, w, h)

	func _next() -> void:
		if randf() < 0.55:
			var tg := position
			var found := false
			for tr in range(10):
				tg = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
				if tg.distance_to(position) < 24.0:
					continue
				if walk_ok.is_valid() and not bool(walk_ok.call(position, tg)):
					continue
				found = true
				break
			if not found:
				wait = 0.3
				return
			target = tg
			state = "walk"
			_face(tg - position)
			_set_anim("Walk")
		else:
			var a := "Attack"
			if randf() < 0.4:
				var opts: Array = []
				for n in ["Shoot", "Charge"]:
					if meta.has(n):
						opts.append(n)
				if not opts.is_empty():
					a = String(opts[randi() % opts.size()])
			if not meta.has(a):
				wait = 1.0
				return
			state = "attack"
			dir = randi() % 8
			_set_anim(a)

	func _process(delta: float) -> void:
		if meta.is_empty() or not meta.has(anim):
			return
		var am: Dictionary = meta[anim]
		t += delta * 60.0
		var guard := 0
		while t >= float(am["d"][frame]) and guard < 16:
			guard += 1
			t -= float(am["d"][frame])
			frame += 1
			if frame >= int(am["n"]):
				frame = 0
				if state == "attack":
					state = "idle"
					wait = randf_range(1.4, 2.6) if fixed else randf_range(0.5, 1.4)
					_set_anim("Idle")
					am = meta[anim]
		if fixed:
			dir = fdir
			if state == "idle":
				wait -= delta
				position = home
				if wait <= 0.0:
					if meta.has("Attack"):
						state = "attack"
						_set_anim("Attack")
					else:
						wait = 1.5
			elif state == "attack":
				var ai: Dictionary = meta[anim]
				var prog: float = clampf((float(frame) + t / maxf(1.0, float(ai["d"][frame]))) / float(maxi(1, int(ai["n"]))), 0.0, 1.0)
				position = home + _lunge_vec() * sin(prog * PI) * lunge
		elif state == "idle":
			wait -= delta
			if wait <= 0.0 and wander:
				_next()
		elif state == "walk":
			var v: Vector2 = target - position
			var step: float = 46.0 * delta * (k / 3.0)
			if v.length() <= step:
				position = target
				state = "idle"
				wait = randf_range(0.4, 1.2)
				_set_anim("Idle")
			else:
				position += v.normalized() * step
		if not ysort and not fixed:
			z_index = int(position.y)
		_apply()
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, shadow_w, Color(0, 0, 0, 0.32))


# Fondo del menu: un trozo del mapa del juego que se desplaza solo, con Pokemon caminando.
class MenuWorld extends Node2D:
	const TW = preload("res://scripts/tileworld.gd")
	const MAINS = preload("res://scripts/main.gd")
	const PERIOD := 30.0   # segundos por ambiente, como en el menu del juego original (bosque -> cueva -> volcan)
	const CAST := [1, 4, 7, 25, 133, 52, 39, 35, 16, 43, 60, 69, 74, 92, 129, 147, 113, 143, 54, 79]
	var cam := Vector2.ZERO
	var t := 0.0
	var tw: Node2D            # el mismo terreno que una partida (lagos, paredes, tierra)
	var gen: Node2D           # instancia de main.gd sin escena: solo genera arboles, rocas, hierba y objetos igual que la partida
	var props: Node2D
	var mons: Array = []
	var vs := Vector2(1280, 720)
	var drift := Vector2(1, 0.3)
	var pool: Array = []
	var amb: Ambient = null
	var cur_chunk := Vector2i(99999, 99999)
	var gen_q: Array = []
	var biome_i := 0

	# Particulas de ambiente en pantalla: luciernagas, motas de cueva y ascuas de volcan.
	class Ambient extends Node2D:
		var t := 0.0
		var vs := Vector2(1280, 720)
		var w := [1.0, 0.0, 0.0]

		static func _h(n: float, k: float) -> float:
			var v: float = sin(n * 12.9898 + k * 78.233) * 43758.5453
			return v - floorf(v)

		func _draw() -> void:
			for k in range(3):
				var wk: float = float(w[k])
				if wk <= 0.01:
					continue
				for n in range(44):
					var fn := float(n)
					var r1: float = _h(fn, 1.0 + float(k))
					var r2: float = _h(fn, 7.0 + float(k))
					var r3: float = _h(fn, 13.0 + float(k))
					var pos: Vector2
					var col: Color
					var sz: float = 3.0
					if k == 0:
						pos = Vector2(r1 * vs.x + sin(t * 0.4 + r2 * 6.0) * 40.0, r3 * vs.y * 0.9 + cos(t * 0.3 + r1 * 6.0) * 30.0)
						col = Color(1.0, 0.95, 0.5, (0.5 + 0.5 * sin(t * 1.5 + r2 * 10.0)) * 0.8 * wk)
					elif k == 1:
						pos = Vector2(r1 * vs.x + sin(t * 0.5 + r3 * 9.0) * 20.0, fmod(r3 * vs.y + t * (10.0 + 20.0 * r2), vs.y))
						col = Color(0.7, 0.88, 1.0, 0.55 * wk)
						sz = 2.0 + floorf(r2 * 2.0)
					else:
						var yy: float = fmod(r3 * vs.y + t * (30.0 + 60.0 * r2), vs.y)
						pos = Vector2(r1 * vs.x + sin(t * 1.2 + r2 * 9.0) * 25.0, vs.y - yy)
						col = Color(1.0, 0.55 + 0.3 * r2, 0.15, 0.9 * (1.0 - yy / vs.y) * wk)
					draw_rect(Rect2(pos.round(), Vector2(sz, sz)), col)

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func start() -> void:
		var SVl = load("res://scripts/save_data.gd")
		SVl.ensure()
		# Los mismos 20 Pokemon que pasean por el menu del juego original
		for d in CAST:
			for p in SVl.dex_list:
				if int(p["dex"]) == d and SVl.smeta.has(str(d)):
					pool.append(p)
					break
		cam = Vector2(randf_range(-3000.0, 3000.0), randf_range(-3000.0, 3000.0))
		var sd: int = randi() % 100000
		tw = TW.new()
		add_child(tw)
		tw.setup(sd)
		props = Node2D.new()
		props.y_sort_enabled = true
		add_child(props)
		gen = MAINS.new()
		gen.ground = tw
		gen.world = props
		gen.world_seed = sd
		gen.menu_mode = true
		MAINS.Prop.tw = tw
		vs = get_viewport_rect().size
		_update_chunks(true)
		tw.flush_bake()
		for i in range(pool.size()):
			_spawn_mon(true)
		amb = Ambient.new()
		get_parent().add_child(amb)
		get_parent().move_child(amb, get_index() + 1)
		tree_exiting.connect(func():
			if is_instance_valid(gen):
				gen.free())

	func _update_chunks(first: bool = false) -> void:
		var c: Vector2i = tw.chunk_of(cam)
		tw.center = cam
		if c != cur_chunk:
			cur_chunk = c
			tw.set_center(c)
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var key := Vector2i(c.x + dx, c.y + dy)
					if not gen.chunks.has(key) and not gen_q.has(key):
						gen_q.append(key)
			gen_q.sort_custom(func(a, b): return absi(a.x - c.x) + absi(a.y - c.y) < absi(b.x - c.x) + absi(b.y - c.y))
			for key in gen.chunks.keys():
				if absi(key.x - c.x) > 3 or absi(key.y - c.y) > 3:
					gen._free_chunk(key)
		# los trozos nuevos se crean de uno en uno (sin tirones); al empezar, todos de golpe
		var made := 0
		while not gen_q.is_empty():
			var nk: Vector2i = gen_q.pop_front()
			if not gen.chunks.has(nk):
				gen.chunks[nk] = gen._gen_chunk(nk.x, nk.y)
				made += 1
			# al empezar solo los 9 de alrededor; el resto llega de uno en uno
			if not first or made >= 9:
				break

	# Sitio libre: sin pared, agua ni lava alrededor.
	func _free_spot(pos: Vector2) -> bool:
		if tw.liquid_at(pos) != "":
			return false
		for o in [Vector2.ZERO, Vector2(18, 0), Vector2(-18, 0), Vector2(0, 18), Vector2(0, -18)]:
			if tw.collide(pos + o, 14.0) != pos + o:
				return false
		return true

	func _can_stand(m: Node2D, pos: Vector2) -> bool:
		if tw.collide(pos, 14.0) != pos:
			return false
		var liq: String = tw.liquid_at(pos)
		if liq == "":
			return true
		var ty: Array = m.get_meta("types", [])
		return ty.has("flying") or (liq == "water" and ty.has("water")) or (liq == "lava" and ty.has("fire")) or (liq == "swamp" and (ty.has("water") or ty.has("poison")))

	func _path_ok(m: Node2D, a: Vector2, b: Vector2) -> bool:
		for i in range(1, 7):
			if not _can_stand(m, a.lerp(b, float(i) / 6.0)):
				return false
		return true

	func _spawn_mon(anywhere: bool) -> void:
		if pool.is_empty():
			return
		# Uno de los 20 del menu original que ahora no este en pantalla
		var used := {}
		for mm in mons:
			used[mm.dex] = true
		var free: Array = []
		for pp in pool:
			if not used.has(int(pp["dex"])):
				free.append(pp)
		if free.is_empty():
			free = pool
		var p: Dictionary = free[randi() % free.size()]
		var pos: Vector2 = Vector2.ZERO
		var good := false
		for tries in range(40):
			if anywhere:
				pos = cam + Vector2(randf_range(-vs.x * 0.5, vs.x * 0.5), randf_range(-vs.y * 0.5, vs.y * 0.5))
			else:
				var side: Vector2 = drift.normalized()
				var perp := Vector2(-side.y, side.x)
				pos = cam + side * (vs.x * 0.5 + 120.0) + perp * randf_range(-vs.y * 0.5, vs.y * 0.5)
			if _free_spot(pos):
				good = true
				break
		if not good:
			return   # sin sitio razonable: no aparece (mejor que dentro de una pared)
		var m := Mon.new()
		m.ysort = true
		m.setup(int(p["dex"]), 2.4, randf() < 0.03, Rect2(pos - Vector2(170.0, 90.0), Vector2(340.0, 180.0)), true)
		m.position = pos
		m.set_meta("types", p.get("types", []))
		m.walk_ok = func(a: Vector2, b: Vector2) -> bool: return _path_ok(m, a, b)
		m.set_meta("lp", pos)
		props.add_child(m)
		mons.append(m)

	func _process(delta: float) -> void:
		t += delta
		vs = get_viewport_rect().size
		var ang: float = 0.3 + sin(t * 0.05) * 0.9
		drift = Vector2.from_angle(ang)
		cam += drift * 26.0 * delta
		position = vs * 0.5 - cam
		_update_chunks()
		for m in mons.duplicate():
			var pushed: Vector2 = tw.collide(m.position, 12.0)   # no atraviesan paredes (como en el juego original)
			if pushed.distance_to(m.position) > 0.5:
				m.position = pushed
				if m.state == "walk":   # chocó con una pared: se para y elige otro destino
					m.state = "idle"
					m.wait = 0.15
					m._set_anim("Idle")
			# agua: solo tipo agua o volador; lava: solo fuego o volador; el resto da la vuelta
			var liq: String = tw.liquid_at(m.position)
			if liq != "":
				var ty: Array = m.get_meta("types")
				var ok: bool = ty.has("flying") or (liq == "water" and ty.has("water")) or (liq == "lava" and ty.has("fire")) or (liq == "swamp" and (ty.has("water") or ty.has("poison")))
				if not ok:
					m.position = m.get_meta("lp")
					m.target = m.position
					m.wait = 0.5
			m.set_meta("lp", m.position)
			if absf(m.position.x - cam.x) > vs.x * 0.5 + 520.0 or absf(m.position.y - cam.y) > vs.y * 0.5 + 420.0:
				mons.erase(m)
				m.queue_free()
				_spawn_mon(false)
		# ambiente: bosque -> cueva de cristal -> volcan, como el original: el mismo mapa con los recursos de cada bioma
		var bi: int = int(floor(t / PERIOD)) % 3
		if bi != biome_i:
			biome_i = bi
			tw.set_biome(bi)
		if amb != null:
			var pv := [0.0, 0.0, 0.0]
			var kf: float = tw.fade_t * tw.fade_t * (3.0 - 2.0 * tw.fade_t)
			pv[tw.prev_biome % 3] += 1.0 - kf
			pv[biome_i] += kf
			amb.t = t
			amb.vs = vs
			amb.w = pv
			amb.queue_redraw()



# Escenario del Gacha: degradado de la region + Pokemon que se mueven.
class Banner extends Control:
	var c1 := Color("#5b2f8f")
	var c2 := Color("#1f6f7a")
	var mons: Array = []

	func _init() -> void:
		clip_contents = true

	const TEXT_H := 150.0   # height reserved at the top for the title and description

	func add_mon(d: int, kk: float, f0: float, f1: float) -> void:
		var m := Mon.new()
		m.set_meta("k0", kk)
		m.fx0 = f0
		m.fx1 = f1
		add_child(m)
		m.setup(d, kk, false, Rect2(f0 * 700.0, 250.0, (f1 - f0) * 700.0, 60.0), false)
		m.fixed = true
		m.fdir = 1   # diagonal abajo-derecha
		m.dir = 1
		m.wait = 0.5 + 0.9 * float(mons.size())
		mons.append(m)
		_layout()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _layout() -> void:
		for m in mons:
			# fixed row: centred in its third, all at the same height; the scale is capped so a big legendary
			# never grows over the title/description text at the top
			m.home = Vector2((m.fx0 + m.fx1) * 0.5 * size.x, size.y * 0.86)
			m.position = m.home
			var ay: float = 48.0
			if m.meta.has("Idle"):
				ay = maxf(24.0, float(m.meta["Idle"]["ay"]))
			var room: float = m.home.y - TEXT_H
			var k_fit: float = clampf(room / ay, 1.0, float(m.get_meta("k0", m.k)))
			if absf(k_fit - m.k) > 0.01:
				m.k = k_fit
				m._apply()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
		var cols := PackedColorArray([c1, c1.lerp(c2, 0.5), c2, c1.lerp(c2, 0.5)])
		draw_polygon(pts, cols)
		draw_circle(Vector2(w * 0.55, h * 0.4), h * 0.6, Color(1, 1, 1, 0.05))
		draw_rect(Rect2(0, h * 0.64, w, h * 0.36), Color(0, 0, 0, 0.12))
		draw_rect(Rect2(1.5, 1.5, w - 3.0, h - 3.0), Color(0.7, 0.78, 1.0, 0.75), false, 3.0)


# Retrato del Pokemon (pantalla de mejoras)
class Portrait extends Control:
	var edge := Color("#ff7b3d")
	var mon: Mon = null

	func _init() -> void:
		clip_contents = true

	func setup(d: int, col: Color) -> void:
		edge = col
		if mon != null:
			mon.queue_free()
		mon = Mon.new()
		add_child(mon)
		mon.setup(d, 3.0, false, Rect2(60.0, 120.0, 80.0, 24.0), false)
		mon.dir = 0
		mon.ysort = true   # sin z_index propio: nunca queda por encima de menus y resultados
		_layout()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _layout() -> void:
		if mon != null:
			# Quieto, centrado y mirando al frente; solo se anima en el sitio.
			mon.position = Vector2(size.x * 0.5, size.y * 0.82)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), PackedColorArray([Color("#1c1833"), Color("#1c1833"), Color("#141028"), Color("#141028")]))
		draw_rect(Rect2(2, 2, w - 4.0, h - 4.0), edge, false, 4.0)


# Barras de nivel (pips)
class Pips extends Control:
	var lv := 0
	var mx := 5

	func setup(l: int, m: int) -> void:
		lv = l
		mx = m
		custom_minimum_size = Vector2(60.0, 10.0)   # pips scale with the card width instead of forcing it wide
		queue_redraw()

	func _draw() -> void:
		var step: float = maxf(6.0, size.x / float(maxi(1, mx)))
		for i in range(mx):
			draw_rect(Rect2(float(i) * step, 1.0, maxf(4.0, step - 4.0), 8.0), UIS.GOLD if i < lv else UIS.EDGE.darkened(0.45))


# ---------------------------------------------------------------
# Construccion
# ---------------------------------------------------------------
# Foco de mando: borde negro con halo blanco (se ve sobre dorado, gris y azul).
const TOWER_FLOORS_M := 60

func _sb_focus(col: Color) -> StyleBoxFlat:
	# Foco de mando: contorno dorado de 3 px (como Doofcraft), visible sobre cualquier fondo.
	var s := _sb(col, UIS.GOLD, 4, 0)
	s.shadow_color = UIS.INK
	s.shadow_size = 0
	s.shadow_offset = UIS.SHADOW_OFF
	return s


# Caja plana: sin esquinas redondeadas (el parametro radius se conserva por compatibilidad) y con sombra dura
# solo cuando tiene borde visible.
func _sb(col: Color, border: Color = Color.TRANSPARENT, bw: int = 0, _radius: int = 0) -> StyleBoxFlat:
	var s := UIS.box(col, border, bw, bw > 0 and border.a > 0.0)
	return s


# Soft drop shadow under a box (UIS.box sets shadow_size 0, which draws nothing).
func _shad(sb: StyleBoxFlat, size: int = 6, off: Vector2 = Vector2(0, 4), a: float = 0.55) -> StyleBoxFlat:
	sb.shadow_color = Color(0, 0, 0, a)
	sb.shadow_size = size
	sb.shadow_offset = off
	return sb


# Button look used by the main-menu tiles: shadowed box, cyan glow on hover, gold focus ring.
func _lift_btn(b: Button, base: Color, edge: Color) -> void:
	b.add_theme_stylebox_override("normal", _shad(_sb(base, edge, 3)))
	var hv: StyleBoxFlat = _sb(base.lerp(UIS.WAVE, 0.22), UIS.WAVE, 4)
	hv.shadow_color = Color(UIS.WAVE, 0.5)
	hv.shadow_size = 10
	hv.shadow_offset = Vector2.ZERO
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", _shad(_sb(UIS.INK, UIS.GOLD, 3), 2, Vector2(0, 1)))
	b.add_theme_stylebox_override("focus", _shad(_sb_focus(base.lerp(UIS.WAVE, 0.12))))


func _apply_ui_theme(i: int) -> void:
	i = clampi(i, 0, UI_THEMES.size() - 1)
	SV.d["ui_theme"] = i
	SV.save()
	var t: Array = UI_THEMES[i]
	C_PANEL = Color(String(t[0]))
	C_PANEL_D = Color(String(t[1]))
	C_BTN = Color(String(t[3]))
	C_BTN_H = Color(String(t[4]))
	C_ACC = t[2]
	_build_theme()
	# Buttons and cards were built with the old colours: rebuild the whole menu and come back to this screen.
	if not is_overlay and get_tree().current_scene != null:
		SV.reopen = cur
		get_tree().call_deferred("reload_current_scene")


func _build_theme() -> void:
	theme_main.default_font_size = 22
	PXF.apply(theme_main)
	theme_main.set_stylebox("normal", "Button", _sb(C_BTN, UIS.EDGE, 3))
	theme_main.set_stylebox("hover", "Button", _sb(C_BTN_H, C_ACC.lightened(0.25), 3))
	theme_main.set_stylebox("pressed", "Button", _sb(UIS.INK, UIS.GOLD, 3, 0))
	theme_main.set_stylebox("focus", "Button", _sb(C_BTN_H, UIS.GOLD, 4))
	theme_main.set_stylebox("disabled", "Button", _sb(UIS.BG, UIS.EDGE, 3, 0))
	theme_main.set_color("font_color", "Button", UIS.TEXT)
	theme_main.set_color("font_hover_color", "Button", UIS.TITLE)
	theme_main.set_color("font_disabled_color", "Button", UIS.MUTED)
	theme_main.set_color("font_color", "Label", UIS.TEXT)
	theme_main.set_stylebox("panel", "PanelContainer", UIS.frame(C_PANEL, UIS.EDGE))
	theme_main.set_stylebox("fill", "ProgressBar", _sb(UIS.GREEN, Color.TRANSPARENT, 0))
	theme_main.set_stylebox("background", "ProgressBar", _sb(UIS.INK, UIS.EDGE, 2, 0))
	theme_main.set_constant("separation", "VBoxContainer", 10)
	theme_main.set_constant("separation", "HBoxContainer", 10)
	theme_main.set_constant("scrollbar_h_separation", "ScrollContainer", 26)   # keep content clear of the scroll bar
	theme = theme_main


func _ready() -> void:
	if not bool(Engine.get_meta("menu_overlay", false)) and CR.take_crash_flag():
		_show_crash_report.call_deferred()
	if "--autorun" in OS.get_cmdline_args():   # test hook: start a normal run a few seconds after launch (never used by a normal launch)
		get_tree().create_timer(5.0).timeout.connect(func(): _start_mode("normal"))
	TXS.hook(self)
	get_tree().node_added.connect(_on_node_added)
	SV.ensure()
	var th0: Array = UI_THEMES[clampi(int(SV.d.get("ui_theme", DEFAULT_THEME)), 0, UI_THEMES.size() - 1)]
	C_PANEL = Color(String(th0[0])); C_PANEL_D = Color(String(th0[1])); C_BTN = Color(String(th0[3])); C_BTN_H = Color(String(th0[4])); C_ACC = th0[2]
	is_overlay = bool(Engine.get_meta("menu_overlay", false))
	Engine.set_meta("menu_overlay", false)
	L.apply()
	DSP.menu_mode = true
	DSP.apply(get_tree())
	PAD.apply()
	if not is_overlay:
		DSP.apply_window()
		Aud.setup(self)
		Aud.music("village")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	RenderingServer.set_default_clear_color(UIS.BACKDROP)
	# fondo: un trozo del mapa que se desplaza solo, con Pokemon caminando
	if not is_overlay:
		var world := MenuWorld.new()
		world.z_index = -4000   # el fondo siempre queda detras de toda la interfaz
		add_child(world)
		world.start()
		var upd := UPD.new()
		add_child(upd)
		upd.found.connect(func(info: Dictionary):
			var pop := UPD.UpdatePopup.new()
			add_child(pop)
			pop.build(info))
		upd.start()
	shade = ColorRect.new()
	shade.color = Color(UIS.INK, 0.30)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	# barra superior
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var ins: Vector4 = DSP.insets(get_tree())
	top.offset_left = 16 + ins.x
	top.offset_right = -16 - ins.z
	top.offset_top = 10 + ins.y
	top.offset_bottom = 58
	add_child(top)
	back_btn = _btn("◀ Back", func(): _leave(), Vector2(150, 44))
	top.add_child(back_btn)
	credit_lbl = Label.new()
	credit_lbl.text = L.t("Made by Dwr3ker")
	credit_lbl.add_theme_font_size_override("font_size", 18)
	credit_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credit_lbl.custom_minimum_size = Vector2(118, 0)
	credit_lbl.add_theme_color_override("font_color", Color("#ffe9a8"))
	credit_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	credit_lbl.add_theme_constant_override("outline_size", 6)
	credit_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit_box = VBoxContainer.new()
	credit_box.add_theme_constant_override("separation", -4)
	credit_box.alignment = BoxContainer.ALIGNMENT_CENTER
	credit_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit_box.custom_minimum_size = Vector2(118, 0)
	credit_box.add_child(credit_lbl)
	var ver_lbl := Label.new()
	ver_lbl.text = L.t("Version") + " " + UPD.APP_VERSION + " · " + L.t("Doofcraft-style edition")
	ver_lbl.add_theme_font_size_override("font_size", 16)
	ver_lbl.add_theme_color_override("font_color", Color("#f2e9d8"))
	ver_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	ver_lbl.add_theme_constant_override("outline_size", 5)
	ver_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit_box.add_child(ver_lbl)
	# El credito va abajo a la izquierda: asi la barra superior termina antes del menu de la derecha.
	credit_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	credit_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	credit_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	credit_box.offset_right = -24 - ins.z
	credit_box.offset_left = -324 - ins.z
	credit_box.offset_top = -62 - ins.w
	credit_box.offset_bottom = -8 - ins.w
	credit_box.custom_minimum_size = Vector2(300, 0)
	credit_lbl.custom_minimum_size = Vector2(300, 0)
	credit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credit_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(credit_box)
	# Barra superior como la del original: monedas, tickets, nombre, sonido y ajustes.
	coin_pill = _pill()
	coin_lbl = _pill_item(coin_pill, "coin", C_GOLD)
	tix_pill = _pill()
	tix_pill.tooltip_text = L.t("Tickets · ×10 tickets")
	ticket_lbl = _pill_item(tix_pill, "ticket", C_GOLD)
	ticket10_lbl = _pill_item(tix_pill, "ticket10", Color("#c47bff"))
	name_pill = _icon_btn("crown", func(): _show("profile"))
	name_pill.custom_minimum_size = Vector2(0, 44)
	name_pill.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_pill.add_theme_font_size_override("font_size", 22)
	name_pill.add_theme_constant_override("h_separation", 10)
	name_lbl = name_pill
	top.add_theme_constant_override("separation", 12)   # one even gap between every top-bar item
	top.add_child(coin_pill)
	top.add_child(tix_pill)
	top.add_child(name_pill)
	news_top = _icon_btn("news", func(): if cur != "news": _show("news"))
	news_top.tooltip_text = L.t("What's new")   # solo icono: la barra superior debe caber en cualquier pantalla
	news_top.custom_minimum_size = Vector2(52, 44)
	top.add_child(news_top)
	support_top = _icon_btn("heart", func(): if cur != "support": _show("support"))
	support_top.tooltip_text = L.t("Support")
	support_top.custom_minimum_size = Vector2(52, 44)
	support_top.visible = false   # sin donaciones en esta edicion
	support_top.focus_mode = Control.FOCUS_NONE
	top.add_child(support_top)
	mute_top = _icon_btn("sound", func(): _toggle_mute_top())
	top.add_child(mute_top)
	set_top = _icon_btn("gear", func(): if cur != "settings": _show("settings"))
	top.add_child(set_top)
	var sp := Control.new()   # pushes the pills to the right; Back stays on the left of the sub-screens
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.move_child(sp, 1)
	news_top.visible = false   # patch notes now live on the main-menu stage card (bottom-right)
	toast_lbl = Label.new()
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_lbl.offset_left = -300
	toast_lbl.offset_right = 300
	toast_lbl.offset_top = -80
	toast_lbl.offset_bottom = -30
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_font_size_override("font_size", 24)
	toast_lbl.add_theme_color_override("font_color", C_GOLD)
	toast_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	toast_lbl.add_theme_constant_override("outline_size", 6)
	toast_lbl.z_index = 50
	add_child(toast_lbl)
	ach_pop = PanelContainer.new()
	ach_pop.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ach_pop.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ach_pop.offset_top = 64
	ach_pop.z_index = 60
	ach_pop.visible = false
	ach_pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var apsb := _sb(Color("#3a3262"), Color("#ffd65c"), 3, 12)
	apsb.set_expand_margin_all(3)
	apsb.shadow_color = Color("#141028")
	apsb.shadow_size = 3
	apsb.content_margin_left = 18
	apsb.content_margin_right = 22
	apsb.content_margin_top = 10
	apsb.content_margin_bottom = 10
	ach_pop.add_theme_stylebox_override("panel", apsb)
	ach_box = HBoxContainer.new()
	ach_box.add_theme_constant_override("separation", 12)
	ach_pop.add_child(ach_box)
	add_child(ach_pop)
	pad_hint = HBoxContainer.new()
	pad_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad_hint.offset_left = 24
	pad_hint.offset_top = -46
	pad_hint.offset_bottom = -6
	pad_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pad_hint.add_theme_constant_override("separation", 8)
	pad_hint.z_index = 49
	pad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pad_hint)
	_build_main()
	_build_test()
	_build_dex()
	_build_modes()
	_build_chal()
	_build_up()
	_build_gacha()
	_build_gachapon()
	_build_goals()
	_build_profile()
	_build_lexicon()
	_build_settings()
	_build_news()
	_build_support()
	_build_layout()
	# El gui elige el control por orden en el arbol (no por z_index): el panel de resultados/tarjetas
	# debe ser el ultimo hijo o los toques lo atraviesan y pulsan los botones de la pantalla de debajo.
	move_child(gacha_result, get_child_count() - 1)
	if is_overlay:
		_show("settings")
		return
	if SV.reopen != "":
		var ro: String = SV.reopen
		SV.reopen = ""
		_show(ro)
	elif SV.owned_count() == 0:
		_show("test")
	else:
		_show("main")
		if PN.should_show():
			_show("news")
		elif not SV.last_run.is_empty():
			_show_run_summary()


func _gap(w: float) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(w, 0)
	return g


# Capsula oscura con borde claro (pildora de la barra superior del original).
func _pill() -> PanelContainer:
	var pc := PanelContainer.new()
	var sbx := _shad(_sb(Color("#141028"), UIS.EDGE.lightened(0.4), 2, 24))
	sbx.content_margin_left = 16
	sbx.content_margin_right = 16
	sbx.content_margin_top = 6
	sbx.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sbx)
	pc.custom_minimum_size = Vector2(0, 44)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(h)
	return pc


func _pill_item(pc: PanelContainer, icon: String, col: Color) -> Label:
	var h: HBoxContainer = pc.get_child(0)
	if h.get_child_count() > 0:
		h.add_child(_gap(6))
	var ic := IC.rect(icon, 26)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := Label.new()
	l.add_theme_color_override("font_color", Color.WHITE if icon == "coin" else col)
	l.add_theme_font_size_override("font_size", 22)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	return l


func _icon_btn(icon: String, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(52, 44)
	b.focus_mode = Control.FOCUS_ALL
	b.icon = IC.tex(icon, IC.scale_for(icon, 26))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_theme_stylebox_override("normal", _shad(_sb(Color("#141028"), UIS.EDGE.lightened(0.4), 2, 12)))
	b.add_theme_stylebox_override("hover", _shad(_sb(Color(0.169, 0.145, 0.278, 0.95), C_ACC, 2, 12)))
	b.add_theme_stylebox_override("pressed", _shad(_sb(Color("#141028"), C_ACC, 2, 12), 2, Vector2(0, 1)))
	b.add_theme_stylebox_override("focus", _shad(_sb(Color(0.169, 0.145, 0.278, 0.95), C_GOLD, 3, 12)))
	b.pressed.connect(func():
		Aud.sfx("click")
		cb.call())
	return b


func _toggle_mute_top() -> void:
	SV.d["settings"]["mute"] = not bool(SV.d["settings"].get("mute", false))
	SV.save()
	if Aud.inst != null:
		Aud.inst.apply()
	_update_top()


func _chip(icon: String = "") -> Label:
	var l := Label.new()
	var sbx := _sb(Color(0, 0, 0, 0.55), Color.WHITE, 2, 22)
	sbx.content_margin_left = 46
	l.add_theme_stylebox_override("normal", sbx)
	l.add_theme_color_override("font_color", C_GOLD)
	l.custom_minimum_size = Vector2(150, 44)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if icon != "":
		var ic := IC.rect(icon, 24)
		ic.position = Vector2(12, 10)
		l.add_child(ic)
	return l


# Boton con iconos dentro: [icono] titulo + coste con su propio icono.
func _cost_btn(title: String, cost: String, icon: String, cost_icon: String, cb: Callable, min_size: Vector2, enabled: bool = true, vertical: bool = false, gold: bool = false) -> Button:
	var b := _btn("", cb, min_size)
	b.disabled = not enabled
	var tcol: Color = Color.WHITE
	if gold:
		_gold_btn(b, enabled)
		tcol = Color.WHITE if enabled else Color.BLACK
		if not enabled:
			for st0 in ["normal", "hover", "pressed", "disabled"]:
				b.add_theme_stylebox_override(st0, _sb(Color("#a89c82"), Color("#6b6250"), 3, 12))
			b.add_theme_stylebox_override("focus", _sb_focus(Color("#b8ad94")))
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 10)
	if not enabled and not gold:
		hb.modulate = Color(1, 1, 1, 0.5)
	if icon != "":
		hb.add_child(IC.rect(icon, 32))
	var holder: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("separation", 8 if not vertical else 0)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if title != "":
		var tl := _label(title, 22, tcol)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if gold:
			tl.add_theme_constant_override("outline_size", 5 if enabled else 0)
			tl.add_theme_color_override("font_outline_color", Color("#3a2606"))
		holder.add_child(tl)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.add_theme_constant_override("separation", 6)
	cr.add_child(IC.rect(cost_icon, 24))
	var cl := _label(cost, 22, tcol if gold else C_GOLD)
	cl.autowrap_mode = TextServer.AUTOWRAP_OFF
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gold:
		cl.add_theme_constant_override("outline_size", 5 if enabled else 0)
		cl.add_theme_color_override("font_outline_color", Color("#3a2606"))
	cr.add_child(cl)
	holder.add_child(cr)
	hb.add_child(holder)
	b.add_child(hb)
	return b


# Boton dorado (se puede pagar) o marron apagado (no alcanza).
func _gold_btn(b: Button, on: bool) -> void:
	var c: Color = C_BTN_H if on else UIS.BG
	var edge: Color = UIS.GOLD if on else UIS.EDGE
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, _sb(c, edge, 3, 0))
	b.add_theme_stylebox_override("focus", _sb_focus(c.lightened(0.15)))


func _card_sb() -> StyleBoxFlat:
	var sb := _sb(Color(0.110, 0.094, 0.200, 0.8), Color("#5a5099"), 2, 14)
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


# Fila [icono] texto
func _icon_label(icon: String, text: String, size: int = 22, col: Color = Color.WHITE, isz: float = 24.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(IC.rect(icon, isz))
	var l := _label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	return h


func _btn(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 52)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	b.pressed.connect(func(): Aud.sfx("click"))
	b.focus_entered.connect(func(): Aud.sfx("hover"))
	return b


# Con mando: el ScrollContainer sigue al control enfocado.
# Si no hay nada enfocable mas abajo (o arriba) pero el menu sigue, el D-pad desplaza la lista.
func _scroll_fallback(down: bool) -> bool:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f == null or not screens.has(cur):
		return false
	var p: Node = f.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p == null:
		return false
	var sc := p as ScrollContainer
	var nb: Control = f.find_valid_focus_neighbor(SIDE_BOTTOM if down else SIDE_TOP)
	if nb != null and sc.is_ancestor_of(nb):
		return false
	if nb != null and not down:
		sc.scroll_vertical = 0   # el foco sale de la lista hacia arriba (pestañas): que el contenido suba del todo
		return false
	var mx: float = maxf(0.0, (sc.get_v_scroll_bar().max_value - sc.size.y))
	var cur_v: float = float(sc.scroll_vertical)
	if down and cur_v >= mx - 1.0:
		return false
	if not down and cur_v <= 0.0:
		return false
	sc.scroll_vertical = int(cur_v + (140.0 if down else -140.0))
	return true


func _follow_focus() -> void:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f != null and is_visible_in_tree():
		_follow(f)


func _follow(c: Control) -> void:
	var p: Node = c.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		(p as ScrollContainer).call_deferred("ensure_control_visible", c)
		call_deferred("_follow_top", p as ScrollContainer, c)


# Si el foco llega al primer control de la lista, se sube del todo para ver el título y lo que haya encima.
func _follow_top(sc: ScrollContainer, c: Control) -> void:
	if not is_instance_valid(sc) or not is_instance_valid(c):
		return
	var first: Control = null
	for n in NAVG.focusables(sc):
		var cn := n as Control
		if first == null or cn.get_global_rect().position.y < first.get_global_rect().position.y - 1.0:
			first = cn
	if first != null and (first == c or absf(first.get_global_rect().position.y - c.get_global_rect().position.y) < 2.0):
		sc.scroll_vertical = 0


func _panel(parent: Node) -> VBoxContainer:
	var pc := PanelContainer.new()
	parent.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	return v


func _label(text: String, size: int = 22, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _screen(name: String) -> Control:
	var c := MarginContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ins: Vector4 = DSP.insets(get_tree())
	c.add_theme_constant_override("margin_left", 24 + int(ins.x))
	c.add_theme_constant_override("margin_right", 24 + int(ins.z))
	c.add_theme_constant_override("margin_top", 72 + int(ins.y))
	c.add_theme_constant_override("margin_bottom", 18 + int(ins.w))
	c.visible = false
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	screens[name] = c
	return c


func _leave() -> void:
	if cur == "chal":
		_show("modes")
		return
	if is_overlay:
		closed.emit()
		queue_free()
	else:
		_show("main")


func _show(name: String) -> void:
	if name == "up" and cur != "up":
		up_dex = int(SV.d["selected"])
	_close_up_picker()
	cur = name
	if name != "dex":
		dex_pick_party = false
		dex_pick_team = false
		dex_pick_coop = false
	for k in screens:
		screens[k].visible = k == name
	back_btn.visible = name != "main" and name != "test"
	credit_box.visible = name == "main"
	if is_instance_valid(main_title):
		main_title.visible = name == "main"
	if is_instance_valid(main_tagline):
		main_tagline.visible = name == "main"
	shade.color.a = 0.48 if name == "main" else 0.62
	for pn in [coin_pill, tix_pill, name_pill, mute_top, set_top]:
		pn.visible = name != "test"
	if is_overlay:
		for pn2 in [coin_pill, tix_pill, name_pill, mute_top, set_top]:
			pn2.visible = false
		shade.color.a = 0.8
	_update_top()
	focus_first = null
	call("_refresh_" + name)
	if focus_first != null and is_instance_valid(focus_first):
		_gf(focus_first)
	if name == "modes":
		_modes_to_top()


# Sube del todo la lista de modos (despues del foco, que a veces la desplaza hacia abajo).
func _modes_to_top() -> void:
	for i in range(3):
		await get_tree().process_frame
		if cur != "modes" or modes_box == null or not is_instance_valid(modes_box):
			return
		var msc: Node = modes_box.get_parent()
		if msc is ScrollContainer and modes_sel == String(MODE_LIST[0][0]):
			(msc as ScrollContainer).scroll_vertical = 0


func _gf(c: Control) -> void:
	call_deferred("_do_focus", c)


func _do_focus(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree():
		c.grab_focus()


func _update_top() -> void:
	coin_lbl.text = "%d" % int(SV.d["coins"])
	ticket_lbl.text = "%d" % int(SV.d["tickets"])
	ticket10_lbl.text = "%d" % int(SV.d.get("tickets10", 0))
	var tt: String = String(SV.d.get("title", ""))
	name_lbl.text = _nick().left(12)
	var muted: bool = bool(SV.d["settings"].get("mute", false))
	var mn: String = "mute" if muted else "sound"
	mute_top.icon = IC.tex(mn, IC.scale_for(mn, 26))


func toast(msg: String) -> void:
	toast_lbl.text = msg
	toast_t = 2.6


# Ayuda de mando abajo a la izquierda: icono del boton + accion (sin texto del boton).
func _build_pad_hint() -> void:
	for c in pad_hint.get_children():
		pad_hint.remove_child(c)
		c.queue_free()
	for pair in [[PAD.confirm_btn(), "Accept"], [PAD.cancel_btn(), "Back"]]:
		pad_hint.add_child(PADI.rect(int(pair[0]), 36.0))
		var l := _label(L.t(String(pair[1])), 20, Color("#f2e9d8"))
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		pad_hint.add_child(l)
		pad_hint.add_child(_gap(10))


# Todo lo que cuelga de un ScrollContainer deja pasar el gesto del dedo (si no, las tarjetas lo tragan y la lista no se mueve).
func _on_node_added(n: Node) -> void:
	if not (n is Control) or n is BaseButton or n is Range or n is LineEdit or n is TextEdit or n is ScrollContainer:
		return
	if not is_ancestor_of(n):
		return
	var p: Node = n.get_parent()
	while p != null and p != self:
		if p is ScrollContainer:
			(n as Control).mouse_filter = Control.MOUSE_FILTER_PASS
			return
		p = p.get_parent()


# Las tarjetas (PanelContainer) paran los gestos del dedo y el ScrollContainer no se mueve: las dejamos pasar.
func _touch_pass(node: Node) -> void:
	for c in node.get_children():
		if c is Control and not (c is BaseButton) and not (c is ProgressBar) and not (c is Range):
			(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_touch_pass(c)


# Stick izquierdo y cruceta (mantenidos): desplazan las listas del Lexico y de Misiones/logros/Cristales Z (el contenido no tiene botones que enfocar).
func _stick_scroll(delta: float) -> void:
	if not (cur == "lexicon" or cur == "goals") or not screens.has(cur):
		return
	if gacha_result != null and gacha_result.visible:
		return
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		return
	# El stick izquierdo ya navega como cruceta (PAD.stick_event): aqui solo la cruceta mantenida.
	var ay := 0.0
	if Input.is_joy_button_pressed(int(pads[0]), JOY_BUTTON_DPAD_DOWN):
		ay = 0.7
	elif Input.is_joy_button_pressed(int(pads[0]), JOY_BUTTON_DPAD_UP):
		ay = -0.7
	if ay == 0.0:
		return
	var sc: ScrollContainer = _first_scroll(screens[cur])
	if sc == null:
		return
	var f: Control = get_viewport().gui_get_focus_owner()
	if f != null and sc.is_ancestor_of(f):
		return   # el foco esta en la lista: ya la sigue el mando
	if f != null and f.find_valid_focus_neighbor(SIDE_BOTTOM if ay > 0.0 else SIDE_TOP) != null:
		return   # hay un control enfocable en esa dirección: lo gestiona la navegación
	sc.scroll_vertical += int(ay * 900.0 * delta)


func _first_scroll(n: Node) -> ScrollContainer:
	if n is ScrollContainer:
		return n as ScrollContainer
	for c in n.get_children():
		var r: ScrollContainer = _first_scroll(c)
		if r != null:
			return r
	return null


func _process(delta: float) -> void:
	PAD.stick_tick()
	_stick_scroll(delta)
	if pad_hint != null:
		var has_pad := Input.get_connected_joypads().size() > 0
		pad_hint.visible = false   # sin la ayuda "Accept / Back" de mando: tapaba las listas
		if false and has_pad:
			var hk := "%d_%d_%d_%s" % [PAD.layout(), PAD.confirm_btn(), PAD.cancel_btn(), L.t("Accept")]
			if hk != pad_hint_key:
				pad_hint_key = hk
				_build_pad_hint()
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast_lbl.text = ""
	if ach_t > 0.0:
		ach_t -= delta
		ach_pop.modulate.a = clampf(minf(ach_t, 2.8 - ach_t + 0.001) * 4.0, 0.0, 1.0)
		ach_pop.position.x = (get_viewport_rect().size.x - ach_pop.size.x) * 0.5
		if ach_t <= 0.0:
			ach_pop.visible = false
	elif not PG.toasts.is_empty() and not is_overlay:
		var tt: Dictionary = PG.toasts.pop_front()
		var msg: String = L.t(String(tt["title"])) % L.t(String(tt["arg"]))
		var sub := ""
		if String(tt["sub"]) != "":
			sub = L.t(String(tt["sub"])) % String(tt["subarg"]) if String(tt["subarg"]) != "" else L.t(String(tt["sub"]))
		_ach_toast(msg, sub, int(tt["tier"]))
		Aud.sfx("legend")
		_update_top()


# Aviso de logro: caja azul con borde dorado y la medalla, como en el juego original.
func _ach_toast(msg: String, sub: String, tier: int) -> void:
	for c in ach_box.get_children():
		c.queue_free()
	var mi := IC.rect("medal%d" % clampi(tier, 1, 3), 36)
	mi.custom_minimum_size.x = 40
	ach_box.add_child(mi)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	ach_box.add_child(col)
	var l := _label(msg, 24, Color("#ffd65c"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(l)
	if sub != "":
		var l2 := _label(sub, 16, Color("#d9cdb5"))
		l2.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(l2)
	ach_pop.reset_size()
	ach_pop.visible = true
	ach_pop.modulate.a = 0.0
	ach_t = 2.8


var back_t := 0.0


func _exit_tree() -> void:
	DSP.menu_mode = false
	if get_tree() != null:
		DSP.apply(get_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


# Atras: cierra el cuadro abierto, sube al menu principal o (en el principal) pide pulsar otra vez para salir.
func _go_back() -> void:
	if listening != "":
		listening = ""
		_refresh_listen()
		return
	if slots_busy:
		slots_ui.fast = true
		return
	if cur == "gachapon" and gp_machine != null and gp_machine.busy():
		gp_machine.speed_up()   # atras/cancelar tambien acelera la animacion (S37)
		return
	if gacha_result != null and gacha_result.visible:
		gacha_result.visible = false
		if cur == "gacha":
			_refresh_gacha()
		elif cur == "gachapon":
			_refresh_gachapon()
		return
	if up_picker != null and is_instance_valid(up_picker):
		_close_up_picker()
		return
	if cur != "main" and cur != "test":
		_leave()
		return
	if cur == "main":
		if Time.get_ticks_msec() / 1000.0 - back_t < 2.0:
			get_tree().quit()
		else:
			back_t = Time.get_ticks_msec() / 1000.0
			toast(L.t("Press back again to exit"))


func _popup_open() -> bool:
	for n in find_children("*", "OptionButton", true, false):
		if (n as OptionButton).get_popup().visible:
			return true
	return false


# --- Desplazamiento arrastrando (dedo o raton) tambien ENCIMA de los botones: Godot no lo hace solo y las listas se quedaban fijas.
var _ds_sc: ScrollContainer = null
var _ds_start := Vector2.ZERO
var _ds_move := false
var _ds_acc := 0.0
const DS_THRESHOLD := 12.0


func _scroll_under(n: Node, pos: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return null
	if n is ScrollContainer:
		var sc := n as ScrollContainer
		var bar: VScrollBar = sc.get_v_scroll_bar()
		if sc.get_global_rect().has_point(pos) and bar.max_value - bar.page > 1.0 and sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			best = sc
	for c in n.get_children():
		var r: ScrollContainer = _scroll_under(c, pos)
		if r != null:
			best = r   # el mas profundo gana
	return best


func _drag_scroll(event: InputEvent) -> bool:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_ds_sc = null
			_ds_move = false
			_ds_acc = 0.0
			var hov: Control = get_viewport().gui_get_hovered_control()
			if hov is Range or hov is LineEdit or hov is TextEdit or hov is OptionButton:
				return false
			var root: Node = screens[cur] if screens.has(cur) else self
			_ds_sc = _scroll_under(root, mb.position)
			_ds_start = mb.position
			return false
		else:
			var was: bool = _ds_move
			_ds_sc = null
			_ds_move = false
			return was   # el soltar tras arrastrar no debe pulsar nada
	if event is InputEventMouseMotion and _ds_sc != null and is_instance_valid(_ds_sc):
		var mm := event as InputEventMouseMotion
		if not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_ds_sc = null
			return false
		if not _ds_move:
			if absf(mm.position.y - _ds_start.y) < DS_THRESHOLD:
				return false
			_ds_move = true
			_ds_sc.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)   # cancela el boton que se estaba pulsando
		_ds_acc -= mm.relative.y
		var step: int = int(_ds_acc)
		if step != 0:
			_ds_sc.scroll_vertical += step
			_ds_acc -= float(step)
		return true
	return false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# v5.2.1: escribiendo en un campo de texto (nombre de entrenador, buscadores) el teclado es del campo:
	# antes Borrar/Retroceso contaba como "atrás", cerraba la pantalla y no se podía borrar ni pegar.
	var typing: Control = get_viewport().gui_get_focus_owner()
	if (typing is LineEdit or typing is TextEdit) and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			typing.release_focus()
			DisplayServer.virtual_keyboard_hide()
			get_viewport().set_input_as_handled()
		return
	# En la lista de modos el stick solo mueve arriba/abajo: un empuje lateral sin querer ya no mete el cursor en los modificadores.
	var sf: Control = get_viewport().gui_get_focus_owner()
	PAD.vertical_only = cur == "modes" and sf != null and mode_tiles.values().has(sf)
	if listening == "" and PAD.stick_event(event):
		get_viewport().set_input_as_handled()   # el stick izquierdo navega como cruceta (un salto por empujon)
		return
	if listening != "":
		if event is InputEventJoypadButton and event.pressed:
			PAD.set_btn(listening, event.button_index)
			listening = ""
			_refresh_listen()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			listening = ""
			_refresh_listen()
			get_viewport().set_input_as_handled()
			return
	# L1/R1 (o los botones prev/next): cambian de pestana en el Lexico y en Misiones y logros
	if event is InputEventJoypadButton and event.pressed and (cur == "lexicon" or cur == "goals") and not (gacha_result != null and gacha_result.visible):
		if event.button_index == PAD.btn("prev") or event.button_index == PAD.btn("next"):
			var dd := -1 if event.button_index == PAD.btn("prev") else 1
			if cur == "lexicon":
				var lk: Array = ["m", "f", "i", "s", "a", "z", "k", "n"]
				lex_tab = String(lk[posmod(lk.find(lex_tab) + dd, lk.size())])
				_refresh_lexicon()
			else:
				var gk: Array = ["m", "a", "h", "z", "r"]
				goals_tab = String(gk[posmod(gk.find(goals_tab) + dd, gk.size())])
				_refresh_goals()
			if tab_sel != null and is_instance_valid(tab_sel):
				tab_sel.grab_focus()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventJoypadButton and event.pressed and cur == "gacha" and not (gacha_result != null and gacha_result.visible):
		if event.button_index == PAD.btn("prev") or event.button_index == PAD.btn("next"):
			var d := -1 if event.button_index == PAD.btn("prev") else 1
			gacha_region = posmod(gacha_region - 1 + d, SV.REGIONS.size()) + 1
			_refresh_gacha()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_left") and cur in ["settings", "goals", "gacha", "lexicon"] and tab_sel != null and is_instance_valid(tab_sel) and tab_row != null:
		var f0: Control = get_viewport().gui_get_focus_owner()
		if f0 != null and not tab_row.is_ancestor_of(f0) and screens.has(cur) and screens[cur].is_ancestor_of(f0):
			var nb: Control = f0.find_valid_focus_neighbor(SIDE_LEFT)
			if nb == null or not screens[cur].is_ancestor_of(nb):
				tab_sel.grab_focus()
				get_viewport().set_input_as_handled()
				return
	if cur == "modes" and event.is_action_pressed("ui_left"):
		var lf3: Control = get_viewport().gui_get_focus_owner()
		if lf3 is CheckButton and lf3.get_parent() is GridContainer and mp_opts.is_ancestor_of(lf3):
			var gi: int = lf3.get_parent().get_children().find(lf3)
			if gi % (lf3.get_parent() as GridContainer).columns == 0 and mode_tiles.has(modes_sel):
				(mode_tiles[modes_sel] as Control).grab_focus()
				get_viewport().set_input_as_handled()
				return
	if cur == "modes" and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")):
		var mf: Control = get_viewport().gui_get_focus_owner()
		var mdn: bool = event.is_action_pressed("ui_down")
		if mf != null and mode_tiles.values().has(mf):
			# la lista de modos nunca salta al panel derecho: solo se entra con Derecha
			var lastb: Control = mode_tiles[String(MODE_LIST[MODE_LIST.size() - 1][0])]
			var firstb: Control = mode_tiles[String(MODE_LIST[0][0])]
			if (mdn and mf == lastb) or (not mdn and mf == firstb):
				(firstb if mdn else lastb).grab_focus()   # da la vuelta: arriba del primero va al último y viceversa
				call_deferred("_follow_focus")
				get_viewport().set_input_as_handled()
				return
		elif mf is CheckButton and mf.get_parent() is GridContainer and mp_opts.is_ancestor_of(mf):
			# Modificadores: al pasar del primero hacia arriba (o del ultimo hacia abajo) da la vuelta
			var cbs: Array = mf.get_parent().get_children()
			var ix: int = cbs.find(mf)
			var cols: int = (mf.get_parent() as GridContainer).columns
			var tgt: Control = null
			if not mdn and ix < cols:
				var want: int = ix + int((cbs.size() - 1 - ix) / cols) * cols
				tgt = cbs[want]
			elif mdn and ix + cols >= cbs.size():
				tgt = cbs[ix % cols]
			if tgt != null:
				tgt.grab_focus()
				get_viewport().set_input_as_handled()
				call_deferred("_follow_focus")
				return
	if cur == "lexicon" and _lex_nav(event):
		get_viewport().set_input_as_handled()
		call_deferred("_follow_focus")
		return
	if cur == "news" and news_scroll != null and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)):
		news_scroll.scroll_vertical += 130 if event.is_action_pressed("ui_down", true) else -130
		get_viewport().set_input_as_handled()
		return
	if (cur == "lexicon" or cur == "goals") and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)) and screens.has(cur):
		var lsc: ScrollContainer = _first_scroll(screens[cur])
		var lf: Control = get_viewport().gui_get_focus_owner()
		var lnb: Control = null
		if lf != null:
			lnb = lf.find_valid_focus_neighbor(SIDE_BOTTOM if event.is_action_pressed("ui_down", true) else SIDE_TOP)
		# si hay algo enfocable en esa dirección (p. ej. la pestaña Colección), el D-pad mueve el foco en vez de desplazar
		if lsc != null and not (lf != null and lsc.is_ancestor_of(lf)) and lnb == null:
			lsc.scroll_vertical += 130 if event.is_action_pressed("ui_down", true) else -130
			get_viewport().set_input_as_handled()
			return
	# S18: con el foco dentro de una pantalla con scroll (p. ej. Misiones > Coleccion) y sin mas controles enfocables
	# en esa direccion, el mando desplaza el contenido hasta llegar a todas las entradas; el foco nunca se atasca.
	if (cur == "lexicon" or cur == "goals") and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)) and screens.has(cur):
		var dn2: bool = event.is_action_pressed("ui_down", true)
		var sc2: ScrollContainer = _first_scroll(screens[cur])
		var f2: Control = get_viewport().gui_get_focus_owner()
		if sc2 != null and f2 != null and sc2.is_ancestor_of(f2):
			var nb2: Control = f2.find_valid_focus_neighbor(SIDE_BOTTOM if dn2 else SIDE_TOP)
			if nb2 == null or not sc2.is_ancestor_of(nb2) or nb2 == f2:
				var vb: VScrollBar = sc2.get_v_scroll_bar()
				var can: bool = (sc2.scroll_vertical < int(vb.max_value - vb.page) - 1) if dn2 else (sc2.scroll_vertical > 0)
				if can:
					sc2.scroll_vertical += 130 if dn2 else -130
					get_viewport().set_input_as_handled()
					return
	if _column_nav(event):
		get_viewport().set_input_as_handled()
		call_deferred("_follow_focus")
		return
	if _grid_nav(event):
		get_viewport().set_input_as_handled()
		call_deferred("_follow_focus")
		return
	if (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")) and _scroll_fallback(event.is_action_pressed("ui_down")):
		get_viewport().set_input_as_handled()
		return
	if _nav_event(event):
		call_deferred("_follow_focus")
	if _nav_event(event) and get_viewport().gui_get_focus_owner() == null:
		# Al reconstruir una pantalla se pierde el foco: con mando/teclado lo recuperamos.
		var fc: Control = _first_focusable()
		if fc != null:
			fc.grab_focus()
			get_viewport().set_input_as_handled()
			return
	if PAD.is_cancel(event) or event.is_action_pressed("ui_cancel"):
		if _popup_open():
			return
		_go_back()
		get_viewport().set_input_as_handled()


# Focusable controls under a node (visible, enabled), used by _column_nav.
func _focusables(n: Node, out: Array) -> void:
	for ch in n.get_children():
		if ch is Control:
			var c := ch as Control
			if not c.visible:
				continue
			if c.focus_mode == Control.FOCUS_ALL and not (c is BaseButton and (c as BaseButton).disabled) and c.size.x > 4.0 and c.size.y > 4.0:
				out.append(c)
		_focusables(ch, out)


# D-pad Up/Down that stays in the current column. The row-based navigation (_grid_nav) merges a left tab column and the
# right-hand buttons into shared rows, so the focus zig-zags between them. Only acts when a control overlaps the current one
# horizontally; otherwise the row navigation runs as before.
func _column_nav(event: InputEvent) -> bool:
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_down", true):
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_up", true):
		dir = Vector2i(0, -1)
	else:
		return false   # Left/Right keep the row-cycling of _grid_nav
	if _popup_open() or listening != "" or not screens.has(cur):
		return false
	if gacha_result != null and gacha_result.visible:
		return false
	var f: Control = get_viewport().gui_get_focus_owner()
	if f == null or f is Slider or f is LineEdit or f is TextEdit or f is OptionButton or not screens[cur].is_ancestor_of(f):
		return false
	var all: Array = []
	_focusables(screens[cur], all)
	var fr: Rect2 = f.get_global_rect()
	var best: Control = null
	var best_gap := INF
	var best_ov := 0.0
	for c in all:
		if c == f or f.is_ancestor_of(c) or c.is_ancestor_of(f):
			continue
		var cr: Rect2 = c.get_global_rect()
		var gap: float
		var ov: float
		if dir.y != 0:
			gap = (cr.get_center().y - fr.get_center().y) * float(dir.y)
			ov = minf(fr.end.x, cr.end.x) - maxf(fr.position.x, cr.position.x)
		else:
			gap = (cr.get_center().x - fr.get_center().x) * float(dir.x)
			ov = minf(fr.end.y, cr.end.y) - maxf(fr.position.y, cr.position.y)
		if gap <= 2.0 or ov <= 1.0:
			continue
		if gap < best_gap - 0.5 or (absf(gap - best_gap) <= 0.5 and ov > best_ov):
			best = c
			best_gap = gap
			best_ov = ov
	if best != null:
		best.grab_focus()
		Aud.sfx("hover")
		return true
	# Mode list: the right-hand panel is its own column. Up past its first control goes back to the selected mode, and Down at the
	# bottom stays put instead of jumping into the list's Challenges section.
	if cur == "modes" and dir.y != 0 and not mode_tiles.values().has(f) and mode_tiles.has(modes_sel):
		if dir.y < 0:
			(mode_tiles[modes_sel] as Control).grab_focus()
		return true
	return false


# Léxico con mando: pestañas (columna izquierda), filtros y rejilla se recorren por separado, sin saltos raros.
func _lex_tiles() -> Array:
	var out: Array = []
	var cols := 1
	for ch in lex_box.get_children():
		if ch is GridContainer:
			cols = (ch as GridContainer).columns
			for b in ch.get_children():
				if b is Button and (b as Button).focus_mode == Control.FOCUS_ALL:
					out.append(b)
		elif ch is Button and (ch as Button).focus_mode == Control.FOCUS_ALL:
			out.append(ch)
	return [out, cols]


func _lex_nav(event: InputEvent) -> bool:
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_down", true): dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_up", true): dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_left", true): dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right", true): dir = Vector2i(1, 0)
	else:
		return false
	if _popup_open() or listening != "":
		return false
	var f: Control = get_viewport().gui_get_focus_owner()
	if f == null or f is LineEdit or lex_tabs == null:
		return false
	var tabs: Array = lex_tabs.get_children()
	var info: Array = _lex_tiles()
	var tiles: Array = info[0]
	var cols: int = info[1]
	var chips: Array = []
	if lex_chips != null and lex_chips.visible:
		for c in lex_chips.get_children():
			if c is Button:
				chips.append(c)
	var tgt: Control = null
	var ti: int = tabs.find(f)
	var ci: int = chips.find(f)
	var gi: int = tiles.find(f)
	if ti >= 0:
		if dir.y != 0:
			tgt = tabs[clampi(ti + dir.y, 0, tabs.size() - 1)]
		elif dir.x > 0:
			if not chips.is_empty():
				tgt = chips[0]
			elif not tiles.is_empty():
				tgt = tiles[0]
	elif ci >= 0:
		if dir.x != 0:
			tgt = chips[posmod(ci + dir.x, chips.size())]
		elif dir.y > 0 and not tiles.is_empty():
			tgt = tiles[0]
	elif gi >= 0:
		if dir.x < 0:
			tgt = tab_sel if gi % cols == 0 else tiles[gi - 1]
		elif dir.x > 0:
			if gi % cols < cols - 1 and gi + 1 < tiles.size():
				tgt = tiles[gi + 1]
		elif dir.y < 0:
			if gi - cols >= 0:
				tgt = tiles[gi - cols]
			elif not chips.is_empty():
				tgt = chips[0]
		else:
			if gi + cols < tiles.size():
				tgt = tiles[gi + cols]
			elif gi / cols < (tiles.size() - 1) / cols:
				tgt = tiles[tiles.size() - 1]
	else:
		return false
	if tgt != null and tgt != f:
		tgt.grab_focus()
	return true   # siempre se consume: el foco nunca salta a otra zona por su cuenta


# Navegacion con mando igual de comoda en todas las pantallas (navgrid.gd), como en Mejoras.
func _grid_items() -> Array:
	var root: Node = self
	if gacha_result != null and gacha_result.visible:
		root = gacha_result
	if up_picker != null and is_instance_valid(up_picker):
		root = up_picker
	var out: Array = []
	for c in NAVG.focusables(root):
		# con una pantalla abierta solo cuentan ella y la barra superior (no las ocultas)
		if root == self and screens.has(cur):
			if not (screens[cur].is_ancestor_of(c) or not _in_any_screen(c)):
				continue
		out.append(c)
	return out


func _in_any_screen(c: Control) -> bool:
	for k in screens:
		if screens[k].is_ancestor_of(c):
			return true
	return false


func _grid_nav(event: InputEvent) -> bool:
	if _popup_open() or listening != "":
		return false
	# v5.2.1: ciclando modos con arriba/abajo solo cuentan los modos. Antes los botones del panel derecho
	# (elegir companero, cambiar tipo, Jugar...) formaban filas intermedias y el cursor saltaba a los modificadores.
	var gf: Control = get_viewport().gui_get_focus_owner()
	if cur == "modes" and gf != null and mode_tiles.values().has(gf) and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)):
		return NAVG.move(get_viewport(), event, mode_tiles.values())
	return NAVG.move(get_viewport(), event, _grid_items())


func _nav_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton and event.pressed:
		return true
	if event is InputEventJoypadMotion:
		return (event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y) and absf(event.axis_value) > 0.6
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_ENTER, KEY_SPACE]
	return false


# Primer control con foco visible: dentro del resultado del gacha si esta abierto, si no en la pantalla actual.
func _first_focusable() -> Control:
	var root: Node = self
	if gacha_result != null and gacha_result.visible:
		root = gacha_result
	elif screens.has(cur):
		root = screens[cur]
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() and not (c is Slider) and not (c is LineEdit):
			if c is BaseButton and (c as BaseButton).disabled:
				continue
			return c
	return null


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _name_of(dex: int) -> String:
	return L.t(String(SV.dex_by[dex]["name"]))


func _type_text(dex: int) -> String:
	var out: Array = []
	for t in SV.dex_by[dex]["types"]:
		out.append(L.t(String(MD.TYPE_NAME[String(t)])))
	return " / ".join(out)


# ---------------------------------------------------------------
# Pantalla principal
# ---------------------------------------------------------------
func _build_main() -> void:
	var s: Control = _screen("main")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	s.add_child(row)
	# columna izquierda: titulo, escenario con el Pokemon y marcas personales
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 6)
	row.add_child(left)
	if is_instance_valid(main_title):
		main_title.queue_free()
	main_title = _label("Megarift Survivors", 54, UIS.GOLD)
	main_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	main_title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var tins: Vector4 = DSP.insets(get_tree())
	main_title.offset_left = 24.0 + tins.x
	main_title.offset_top = 2.0 + tins.y   # top row, level with the top-bar buttons
	main_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_title.visible = false
	add_child(main_title)
	# S58.5: frase aleatoria y amable (se elige una sola vez al construir el menu)
	var tags: Array = ["Now with more grass to cut!", "Careful: Meowth might steal your lunch.", "Today is a good day to evolve.", "Recommended by 9 out of 10 Pikachu.", "Survive one more minute!", "Don't feed wild Snorlax.", "Kecleon accepts coins, not compliments.", "Poké Balls don't include aim.", "A Charmander never sleeps: it just blinks.", "Every Pokémon is a little shiny on the inside."]
	if is_instance_valid(main_tagline):
		main_tagline.queue_free()
	main_tagline = _label(L.t(String(tags[randi() % tags.size()])), 20, UIS.MUTED)
	main_tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	main_tagline.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main_tagline.offset_left = 26.0 + tins.x
	main_tagline.offset_top = 66.0 + tins.y   # right under the title
	main_tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_tagline.visible = false
	add_child(main_tagline)
	var card := PanelContainer.new()
	var cbx: StyleBoxFlat = _shad(UIS.box(UIS.INK, UIS.EDGE, 3, false), 10, Vector2(0, 6), 0.6)
	cbx.set_content_margin_all(3)
	card.add_theme_stylebox_override("panel", cbx)
	card.custom_minimum_size = Vector2(0, 440 if _compact() else 320)   # squarer screens have room for a taller stage
	left.add_child(card)
	var stage := StageBG.new()   # escenario bajo el Pokemon (el Pokemon se anade despues, encima)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stage)
	main_card = card
	# "What's new" (patch notes): bottom-right corner of the stage card
	main_news_ov = Control.new()
	main_news_ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(main_news_ov)
	var nbtn := _btn(L.t("What's new"), func(): _show("news"), Vector2(150, 40))
	nbtn.icon = IC.btn_tex("news", 22)
	nbtn.expand_icon = false
	nbtn.add_theme_font_size_override("font_size", 16)
	nbtn.add_theme_constant_override("h_separation", 8)
	_lift_btn(nbtn, UIS.PANEL, UIS.EDGE)
	nbtn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	nbtn.offset_left = -170.0
	nbtn.offset_top = -56.0
	nbtn.offset_right = -14.0
	nbtn.offset_bottom = -14.0
	nbtn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	nbtn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	main_news_ov.add_child(nbtn)
	main_btns["news"] = nbtn
	var tbtn := _btn(L.t("View my trainer card"), func(): _show_card(), Vector2(150, 40))
	tbtn.icon = IC.btn_tex("crown", 22)
	tbtn.expand_icon = false
	tbtn.add_theme_font_size_override("font_size", 16)
	tbtn.add_theme_constant_override("h_separation", 8)
	_lift_btn(tbtn, UIS.PANEL, UIS.EDGE)
	tbtn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tbtn.offset_left = 14.0
	tbtn.offset_top = -56.0
	tbtn.offset_right = 250.0
	tbtn.offset_bottom = -14.0
	tbtn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	main_news_ov.add_child(tbtn)
	main_btns["card"] = tbtn
	main_info = _label("", 24)
	main_info.autowrap_mode = TextServer.AUTOWRAP_OFF
	left.add_child(main_info)
	# marcas personales: cuatro fichas en una cuadricula 4x1 (antes un bloque de texto que se salia de la pantalla)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	left.add_child(chips)
	for ck in [["dex", "Pokémon"], ["runs", "Runs"], ["time", "Best time"], ["level", "Best level"], ["kills", "Defeated"]]:
		_stat_chip(String(ck[0]), String(ck[1]), chips)
	# columna derecha: Continuar + mosaico de secciones (la franja de color indica el grupo)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(540 if _compact() else 500, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	resume_btn = _btn("", func(): _resume_run(), Vector2(0, 84 if _compact() else 70))
	resume_btn.visible = false
	resume_btn.add_theme_font_size_override("font_size", 22)
	_gold_btn(resume_btn, false)
	right.add_child(resume_btn)
	main_btns["resume"] = resume_btn
	cont_btn = _btn("", func(): _start_mode(_last_mode_id()), Vector2(0, 116 if _compact() else 92))
	cont_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	cont_btn.icon = IC.btn_tex("flag", 44)
	cont_btn.add_theme_constant_override("icon_max_width", 48)
	cont_btn.add_theme_constant_override("h_separation", 18)
	cont_btn.add_theme_font_size_override("font_size", 28 if _compact() else 24)
	_gold_btn(cont_btn, true)
	for stn in ["normal", "hover", "pressed", "focus"]:
		var csb := cont_btn.get_theme_stylebox(stn) as StyleBoxFlat
		if csb != null:
			_shad(csb, 8, Vector2(0, 5), 0.55)
	var chv := cont_btn.get_theme_stylebox("hover") as StyleBoxFlat
	if chv != null:
		chv.bg_color = chv.bg_color.lightened(0.14)
		chv.shadow_color = Color(UIS.GOLD, 0.45)
		chv.shadow_size = 12
		chv.shadow_offset = Vector2.ZERO
	right.add_child(cont_btn)
	main_btns["continue"] = cont_btn
	var rows := [
		[["play", "Play", "flag", UIS.WAVE], ["dex", "Pokémon", "ball", UIS.GOLD], ["lexicon", "Lexicon", "book", UIS.GOLD]],
		[["up", "Upgrades", "up", UIS.GREEN], ["goals", "Missions", "trophy", UIS.GREEN], ["gacha", "Gacha", "ballLux", UIS.ORCHID]],
	]
	for r in rows:
		var hr := HBoxContainer.new()
		hr.add_theme_constant_override("separation", 10)
		right.add_child(hr)
		for info in r:
			var key: String = String(info[0])
			var tb: Button = _tile(String(info[1]), String(info[2]), info[3], func(): _menu_pick(key), 156.0 if _compact() else 116.0)
			hr.add_child(tb)
			main_btns[key] = tb
			if key == "goals":
				goals_btn = tb
	var gp := _tile("TM Gachapon", "gcoin", UIS.ORCHID, func(): _menu_pick("gachapon"), 80.0 if _compact() else 64.0, true)
	right.add_child(gp)
	main_btns["gachapon"] = gp
	main_play_btn = cont_btn   # el foco por defecto es "Continuar": una pulsacion y a jugar


# Mosaico del menu principal: icono grande arriba, nombre debajo y una franja del color del grupo.
func _tile(text: String, icon: String, accent: Color, cb: Callable, h: float, wide: bool = false) -> Button:
	var b := _btn(text, cb, Vector2(0, h))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24 if _compact() else 20)
	if wide:
		# icon + name centred together as one group
		b.text = ""
		var hb := HBoxContainer.new()
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.offset_top = 6.0   # clear of the accent stripe
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 12)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hb)
		var wic := TextureRect.new()
		wic.texture = IC.btn_tex(icon, 28)
		wic.custom_minimum_size = Vector2(32, 0)
		wic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(wic)
		var wlb := _label(text, 20, UIS.TEXT)
		wlb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wlb.autowrap_mode = TextServer.AUTOWRAP_OFF
		wlb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(wlb)
		b.set_meta("lbl", wlb)
	else:
		# icon above the name, the pair centred vertically in the tile (a Button's own icon layout pins it to the top)
		b.text = ""
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.offset_top = 8.0   # clear of the accent stripe
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 6)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(vb)
		var ic := TextureRect.new()
		ic.texture = IC.btn_tex(icon, 48)
		ic.custom_minimum_size = Vector2(0, 52)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(ic)
		var lb := _label(text, 20, UIS.TEXT)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.autowrap_mode = TextServer.AUTOWRAP_OFF
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(lb)
		b.set_meta("lbl", lb)
	_lift_btn(b, C_BTN, UIS.EDGE)
	if b.has_meta("lbl"):
		var tl: Label = b.get_meta("lbl")
		b.mouse_entered.connect(func(): tl.add_theme_color_override("font_color", UIS.TITLE))
		b.mouse_exited.connect(func(): tl.add_theme_color_override("font_color", UIS.TEXT))
	var bar := ColorRect.new()
	bar.color = accent
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 3
	bar.offset_right = -3
	bar.offset_top = 3
	bar.offset_bottom = 8
	b.add_child(bar)
	return b


# Sets a tile's caption (tiles keep the name in a child label so icon + text stay centred).
func _set_tile_text(b: Button, t: String) -> void:
	if b.has_meta("lbl"):
		(b.get_meta("lbl") as Label).text = t
	else:
		b.text = t


func _stat_chip(key: String, label: String, parent: Node) -> void:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sbx: StyleBoxFlat = _shad(UIS.box(Color(UIS.INK, 0.92), UIS.EDGE, 2, false), 6, Vector2(0, 4), 0.5)
	sbx.content_margin_left = 10
	sbx.content_margin_right = 10
	sbx.content_margin_top = 4
	sbx.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sbx)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	var cap := _label(L.t(label), 14, UIS.MUTED)
	cap.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(cap)
	var val := _label("", 22, UIS.TEXT)
	val.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(val)
	main_chips[key] = val
	parent.add_child(pc)


var main_play_btn: Button
var cont_btn: Button
var main_btns: Dictionary = {}
var last_pick := "continue"


func _menu_pick(key: String) -> void:
	last_pick = key
	if key == "goals" and goals_tab == "p":
		goals_tab = "m"
	if key == "play":
		modes_sel = String(MODE_LIST[0][0])   # v5.2.1: al darle a Jugar siempre se empieza arriba, en el primer modo (Partida normal)
		_show("modes")
	else:
		_show(key)


# ---------------------------------------------------------------
# Modos de juego
# ---------------------------------------------------------------
# Modos de juego (pantalla Jugar): lista a la izquierda; a la derecha, reglas + vista previa + opciones + Jugar del modo enfocado.
# La vista previa es una ilustracion animada (no ejecuta la partida: no gasta recursos ni toca ningun reloj).
var modes_box: VBoxContainer
var mp_title: Label
var mp_rules: VBoxContainer
var mp_prev: Control
var mp_opts_sc: ScrollContainer
var mp_stat: Label
var mp_opts: VBoxContainer
var mp_play: Button
var modes_sel := "normal"
var mode_tiles: Dictionary = {}
var dex_pick_party := false
var dex_pick_team := false
var dex_pick_coop := false
const TYPE_IDS := ["normal", "fire", "water", "grass", "electric", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
const MOD_ICON := {"fast": "boot", "horde": "m_horde", "tank": "shield", "hard": "fist", "frail": "heart", "nohealing": "berry", "slow": "r_heavy", "brainy": "r_scholar", "glass": "r_glass", "rich": "r_l_bag", "plague": "r_swarm"}
const MOD_INFO := {
	"fast": ["Fast", "Enemies move 40% faster."],
	"horde": ["Horde", "Almost twice as many enemies."],
	"tank": ["Tough", "Enemies have 60% more health."],
	"hard": ["Heavy hitters", "Enemies deal 50% more damage."],
	"frail": ["Fragile", "Your max health is halved."],
	"nohealing": ["No healing", "You can't recover health (only what Health upgrades give you)."],
	"slow": ["Heavy", "You move 20% slower."],
	"brainy": ["Bright mind", "You gain 50% more experience, but enemies have 25% more health."],
	"glass": ["Glass cannon", "You deal 50% more damage, but enemies deal double."],
	"rich": ["Gold rush", "Coins are worth double, but enemies have 30% more health."],
	"plague": ["Plague", "2.5 times more enemies appear, but with 35% less health."],
}
# id, nombre, icono, grupo, reglas
const MODE_LIST := [
	["normal", "Normal run", "flag", "Classic", ["Survive as enemies keep coming.", "Level up and choose moves and items.", "Defeat the bosses that appear every few minutes.", "At the end you earn Pokécoins and sometimes tickets.", "Lasts 60 minutes: Arceus arrives at minute 30 and Eternatus at 60."]],
	["daily", "Daily Challenge", "m_daily", "Classic", ["Today's Pokémon and rule change every day and are the same for everyone.", "Try to beat your best time of the day.", "+25% coins."]],
	["rush", "Boss Rush", "m_rush", "Classic", ["Only bosses and legendaries, one after another.", "Each boss is stronger than the last.", "Your record counts how many bosses you defeat."]],
	["tower", "The Tower", "m_tower", "Classic", ["60 floors, each with a fixed boss and a big boss every 5.", "Between floors you choose rest or risk pacts.", "Every 5 floors you earn a permanent relic.", "No Z-Moves or Dynamax."]],
	["rifts", "Rift Time Attack", "m_clock", "Classic", ["8 minutes: rifts open non-stop.", "Win as many fights as you can.", "+25% coins."]],
	["type", "Survival by Type", "m_type", "Variants", ["Only Pokémon of the chosen type and their bosses appear.", "+50% coins."]],
	["team", "Team Mode", "m_team", "Variants", ["Bring up to 3 Pokémon and swap them mid-run.", "If one falls, the next one comes in; benched ones recover.", "Each Pokémon keeps its own moves."]],
	["coop", "Co-op Mode", "m_coop", "Variants", ["A second Pokémon joins you and attacks on its own.", "With a second controller, player 2 moves it with their left stick.", "Shares your upgrades. -20% coins."]],
	["party", "Party Mode", "m_party", "Variants", ["Choose any Pokémon, whether you own it or not.", "You cannot die.", "No progress is saved."]],
	["chal_p", "Permanent challenges", "gcoin", "Challenges", ["100 challenges of 10 minutes at most.", "Each one gives its reward only once.", "The hardest ones give a Golden Gachapon Coin."]],
	["chal_d", "Daily challenges", "gcoin", "Challenges", ["3 new challenges every day.", "Each one gives 1 Gachapon Coin the first time."]],
	["chal_w", "Weekly challenges", "gcoin_gold", "Challenges", ["5 new challenges every week.", "One is Expert level and gives a Golden Gachapon Coin."]],
	["mods", "Modifiers", "m_horde", "Settings", ["Change the rules of the run to earn more coins.", "+25% coins for each active modifier.", "They do not apply to the Daily Challenge or Party Mode."]],
]


# Nombre (traducido) de un modo de juego por su id; si no existe, Partida normal.
func _mode_name(id: String) -> String:
	for m in MODE_LIST:
		if String(m[0]) == id:
			return L.t(String(m[1]))
	return L.t("Normal run")


# Ultimo modo jugado (para "Continuar"); los retos no se repiten desde aqui.
func _last_mode_id() -> String:
	var id: String = String(SV.d.get("last_mode", "normal"))
	for m in MODE_LIST:
		if String(m[0]) == id and not id.begins_with("chal_") and id != "mods":
			return id
	return "normal"


# Repite la ultima partida con el mismo Pokemon (boton "Jugar de nuevo" del resumen).
func _replay_last() -> void:
	if SV.run_mode == "chal" and not SV.run_chal.is_empty():
		_chal_play(SV.run_chal)
	else:
		_start_mode(_last_mode_id() if SV.run_mode == "chal" else String(SV.run_mode))


# Puts a run saved with "Save and quit" back (run_save.gd).
func _resume_run() -> void:
	var snap: Dictionary = RS.load_snap()
	if snap.is_empty():
		toast(L.t("The saved run could not be read."))
		RS.clear()
		_refresh_main()
		return
	SV.run_mode = String(snap["mode"])
	SV.run_hyper = bool(snap["hyper"])
	SV.run_dex = int(snap["dex"])
	SV.run_mods = Array(snap["mods"]).duplicate()
	SV.resume_snap = snap
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _start_mode(mode: String) -> void:
	if not mode.begins_with("chal"):
		SV.d["last_mode"] = mode
	SV.run_mode = mode
	SV.run_hyper = mode == "normal" and bool(SV.d.get("hyper", false))   # Hyper solo en la partida normal
	SV.run_dex = int(SV.d["selected"])
	SV.run_type = String(SV.d.get("mode_type", "fire"))
	SV.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# Ilustracion animada del modo (sprites + decoracion). No simula la partida.
class ModePrev extends Control:
	var mode := "normal"
	var t := 0.0
	var ents: Array = []     # {n: Preview, k: movimiento, a: punto base (0..1), p: fase}
	var info: Dictionary = {}
	var vp: VideoStreamPlayer = null   # video de gameplay real del modo (assets/previews/<modo>.ogv)
	var has_video := false
	const VID := Vector2(640.0, 360.0)

	func _fit_video() -> void:
		if vp == null:
			return
		var k: float = maxf(size.x / VID.x, size.y / VID.y)   # cubrir el recuadro sin deformar
		vp.size = VID * k
		vp.position = (size - vp.size) * 0.5

	static func sprite_dex(d: int) -> int:
		return d if ResourceLoader.exists("res://assets/pokemon/%d/Idle.png" % d) or ResourceLoader.exists("res://assets/pokemon/%d/Walk.png" % d) else 4

	func setup(m: String, inf: Dictionary) -> void:
		mode = m
		info = inf
		t = 0.0
		for e in ents:
			e["n"].queue_free()
		ents.clear()
		for c in get_children():
			c.queue_free()
		var hero: int = int(inf.get("hero", 4))
		if vp != null:
			vp.queue_free()
			vp = null
		var vpath := "res://assets/previews/%s.ogv" % String(inf.get("vid", m))
		if ResourceLoader.exists(vpath) and not ["type", "mods", "chal"].has(m):
			vp = VideoStreamPlayer.new()
			vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vp.stream = load(vpath)
			vp.expand = true
			vp.loop = true
			add_child(vp)
			vp.play()
			has_video = true
			var tg := Label.new()
			tg.text = String(inf.get("tag", ""))
			tg.add_theme_font_size_override("font_size", 14)
			tg.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
			tg.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
			tg.add_theme_constant_override("shadow_offset_x", 1)
			tg.add_theme_constant_override("shadow_offset_y", 1)
			tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
			add_child(tg)
			_fit_video()
			if inf.has("overlay"):
				_add(int(inf["overlay"]), 150.0, "ovl", Vector2(0.5, 0.5), 0.0)
			queue_redraw()
			return
		has_video = false
		match m:
			"normal":
				_add(hero, 150.0, "hero", Vector2(0.5, 0.78), 0.0)
				var foes := [19, 16, 41, 10, 21, 74, 19, 16]
				for i in range(foes.size()):
					_add(int(foes[i]), 70.0, "orbit", Vector2(0.5, 0.78), float(i) / float(foes.size()) * TAU)
			"daily":
				_add(int(inf.get("dex", 25)), 170.0, "bob", Vector2(0.3, 0.8), 0.0)
			"rush":
				_add(hero, 110.0, "bob", Vector2(0.2, 0.84), 0.0)
				_add(int(inf.get("boss", 248)), 220.0, "bob", Vector2(0.7, 0.9), 1.0)
			"tower":
				_add(hero, 90.0, "climb", Vector2(0.3, 0.9), 0.0)
				_add(int(inf.get("boss", 248)), 100.0, "bob", Vector2(0.78, 0.38), 1.0)
			"rifts":
				_add(hero, 120.0, "rhero", Vector2(0.12, 0.82), 0.0)
				for fd in [19, 41, 74]:
					_add(int(fd), 70.0, "rfoe", Vector2(0.7, 0.82), float(fd))
			"type":
				_add(hero, 130.0, "hero", Vector2(0.5, 0.78), 0.0)
				var ids: Array = inf.get("dexes", [])
				for i in range(ids.size()):
					_add(int(ids[i]), 66.0, "orbit", Vector2(0.5, 0.78), float(i) / float(maxi(1, ids.size())) * TAU)
			"team":
				var tl: Array = inf.get("team", [hero])
				for i in range(tl.size()):
					_add(int(tl[i]), 130.0 if i == 0 else 95.0, "bob", Vector2(0.28 + 0.22 * float(i) + (0.0 if tl.size() > 2 else 0.1), 0.82), float(i))
			"coop":
				_add(hero, 150.0, "bob", Vector2(0.32, 0.82), 0.0)
				_add(int(inf.get("coop", 133)), 130.0, "bob", Vector2(0.62, 0.82), 1.0)
			"party":
				_add(int(inf.get("dex", 25)), 170.0, "bob", Vector2(0.5, 0.82), 0.0)
			"chal":
				_add(hero, 130.0, "bob", Vector2(0.2, 0.84), 0.0)
			"mods":
				_add(hero, 150.0, "bob", Vector2(0.16, 0.8), 0.0)
		queue_redraw()

	func _add(d: int, box: float, kind: String, a: Vector2, ph: float) -> void:
		var sc = load("res://scripts/menu.gd")
		var n = sc.Preview.new()
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.custom_minimum_size = Vector2(box, box)
		n.size = Vector2(box, box)
		add_child(n)
		n.setup(sprite_dex(d), false, 8.0, kind == "boss_dark")
		ents.append({"n": n, "k": kind, "a": a, "p": ph, "b": box})

	func _process(delta: float) -> void:
		t += delta
		if has_video:
			_fit_video()
			if mode == "team":   # el video ya muestra al equipo rotando entre sus 3 Pokémon
				for e0 in ents:
					(e0["n"] as Control).visible = false
				return
			var nent: int = ents.size()
			for ei in range(nent):   # el Pokémon del día va encima del video (que se grabó sin jugador)
				var e = ents[ei]
				var bx: float = size.y * (0.5 if nent == 1 else 0.36)
				var nn: Control = e["n"]
				nn.custom_minimum_size = Vector2(bx, bx)
				nn.size = Vector2(bx, bx)
				var spread: float = (float(ei) - float(nent - 1) * 0.5) * size.x * 0.26   # varios Pokémon: no se apilan
				var ctr := Vector2(size.x * 0.5 + spread, size.y * 0.5 + bx * 0.14 - absf(sin(t * 3.0 + float(ei))) * 3.0)
				nn.position = ctr - Vector2(bx * 0.5, bx * 0.84)
				# misma trayectoria que el bot del video: dirección según el tiempo del video
				var vt: float = vp.stream_position if vp != null else t
				var vx: float = cos(vt * 0.9)
				var vy: float = sin(vt * 0.9 * 1.3)
				var ix: int = (1 if vx > 0.25 else -1 if vx < -0.25 else 0)
				var iy: int = (1 if vy > 0.25 else -1 if vy < -0.25 else 0)
				var rmap := {Vector2i(0, 1): 0, Vector2i(1, 1): 1, Vector2i(1, 0): 2, Vector2i(1, -1): 3, Vector2i(0, -1): 4, Vector2i(-1, -1): 5, Vector2i(-1, 0): 6, Vector2i(-1, 1): 7}
				(nn as Control).set("walk", true)
				(nn as Control).set("row", int(rmap.get(Vector2i(ix, iy), 0)))
			return
		for e in ents:
			var n: Control = e["n"]
			var base := Vector2(size.x * float(e["a"].x), size.y * float(e["a"].y))
			var off := Vector2.ZERO
			match String(e["k"]):
				"bob":
					off = Vector2(0.0, -absf(sin(t * 3.0 + float(e["p"]))) * 6.0)
				"hero":
					off = Vector2(sin(t * 1.6) * 6.0, 0.0)
				"climb":
					off = Vector2(0.0, -absf(sin(t * 4.0)) * 8.0)
				"rhero":
					var ph: float = fposmod(t, 8.0)
					var portal := Vector2(size.x * 0.7, size.y * 0.78)
					var sc2 := 1.0
					var pos2 := Vector2(size.x * 0.28, size.y * 0.82)
					var walking := false
					if ph < 2.6:
						pos2 = Vector2(size.x * lerpf(0.1, 0.66, ph / 2.6), size.y * 0.82)
						walking = true
					elif ph < 3.3:
						var f1: float = (ph - 2.6) / 0.7
						pos2 = Vector2(size.x * 0.66, size.y * 0.82).lerp(portal, f1)
						sc2 = 1.0 - f1
						walking = true
					elif ph < 3.9:
						sc2 = (ph - 3.3) / 0.6
					base = pos2
					off = Vector2.ZERO if walking else Vector2(0.0, -absf(sin(t * 3.0)) * 4.0)
					n.pivot_offset = Vector2(float(e["b"]) * 0.5, float(e["b"]) * 0.84)
					n.scale = Vector2(sc2, sc2)
					n.visible = sc2 > 0.03
					(n as Control).set("walk", walking)
					(n as Control).set("row", 2)
				"rfoe":
					var ph2: float = fposmod(t, 8.0)
					var idx: int = [19, 41, 74].find(int(e["p"]))
					var tdie: float = 3.9 + float(idx) * 1.3 + 0.5
					n.visible = ph2 >= 3.3 and ph2 < tdie
					base = Vector2(size.x * (0.58 + 0.12 * float(idx)), size.y * (0.78 + 0.03 * float(idx % 2)))
					off = Vector2(0.0, -absf(sin(t * 3.0 + float(idx))) * 5.0)
				"orbit":
					var r: float = 170.0 + 40.0 * sin(t * 0.9 + float(e["p"]))
					var ang: float = float(e["p"]) + t * 0.5
					off = Vector2(cos(ang) * r * 1.15, sin(ang) * r * 0.42 - 20.0)
			n.position = base + off - Vector2(float(e["b"]) * 0.5, float(e["b"]) * 0.84)
		queue_redraw()

	func _font() -> Font:
		return get_theme_default_font()

	func _txt(p: Vector2, s: String, fs: int, col: Color, w: float = -1.0, al: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
		draw_string(_font(), p, s, al, w, fs, col)

	func _draw() -> void:
		var W: float = size.x
		var H: float = size.y
		if has_video:
			draw_rect(Rect2(0, 0, W, H), Color.BLACK)
			return
		draw_rect(Rect2(0, 0, W, H), Color("#1c1833"))
		draw_rect(Rect2(0, H * 0.5, W, H * 0.5), Color("#2b2547"))
		if mode != "type" and mode != "mods":
			draw_rect(Rect2(0, H * 0.84, W, H * 0.16), Color("#26602f"))
			draw_rect(Rect2(0, H * 0.84, W, 4.0), Color("#3b8a45"))
		match mode:
			"normal":
				for i in 3:
					draw_arc(Vector2(W * 0.5, H * 0.78), 90.0 + float(i) * 70.0, 0.0, TAU, 48, Color(1, 1, 1, 0.05), 2.0)
				draw_rect(Rect2(14, 12, W - 28, 14), Color(0, 0, 0, 0.45))
				draw_rect(Rect2(14, 12, (W - 28) * fposmod(t * 0.12, 1.0), 14), Color("#5fd0ff"))
				_txt(Vector2(14, 46), "Lv %d" % (1 + int(t * 0.12)), 18, Color.WHITE)
			"daily":
				draw_rect(Rect2(W * 0.52, 26, W * 0.4, H * 0.62), Color("#f4f6fb"), true)
				draw_rect(Rect2(W * 0.52, 26, W * 0.4, 34), Color("#e0434f"))
				_txt(Vector2(W * 0.52, 51), String(info.get("month", "")), 22, Color.WHITE, W * 0.4, HORIZONTAL_ALIGNMENT_CENTER)
				_txt(Vector2(W * 0.52, 118), String(info.get("day", "")), 56, Color("#2b2547"), W * 0.4, HORIZONTAL_ALIGNMENT_CENTER)
				_txt(Vector2(W * 0.52, 148), String(info.get("rule", "")), 18, Color("#5a5099"), W * 0.4, HORIZONTAL_ALIGNMENT_CENTER)
			"rush":
				var bx: float = W * 0.7
				draw_rect(Rect2(bx - 90, 14, 180, 14), Color(0, 0, 0, 0.55))
				draw_rect(Rect2(bx - 90, 14, 180.0 * (0.55 + 0.45 * absf(sin(t * 0.7))), 14), Color("#ff5a6a"))
				for i in 4:
					var px: float = fposmod(t * 160.0 + float(i) * 70.0, 330.0) + W * 0.28
					draw_circle(Vector2(px, H * 0.7), 6.0, Color("#ffb347"))
			"tower":
				for i in 6:
					var fy: float = H * 0.88 - float(i) * (H * 0.14)
					draw_rect(Rect2(W * 0.08, fy - H * 0.12, W * 0.4, H * 0.12 - 3.0), Color(0.227, 0.196, 0.384, 0.7))
					_txt(Vector2(W * 0.1, fy - 10.0), str(int(info.get("floor", 1)) + i), 18, Color("#b4aed6"))
				_txt(Vector2(W * 0.56, 40), "%s %d" % [String(info.get("floor_lbl", "")), int(info.get("floor", 1))], 22, Color("#ffd65c"))
			"rifts":
				var ph3: float = fposmod(t, 8.0)
				var c := Vector2(W * 0.7, H * 0.7)
				if ph3 >= 3.3:
					draw_rect(Rect2(0, 0, W, H), Color(0.22, 0.08, 0.38, 0.55))
					for si in 14:
						draw_circle(Vector2(fposmod(float(si) * 91.0, W), fposmod(float(si) * 53.0, H * 0.7)), 2.0, Color(1, 1, 1, 0.5 + 0.4 * sin(t * 3.0 + float(si))))
				else:
					var grow: float = 1.0 if ph3 < 2.6 else clampf(1.0 - (ph3 - 2.6) / 0.7 * 0.6, 0.3, 1.0)
					for i in 4:
						var r: float = (44.0 + float(i) * 22.0) * grow
						draw_arc(c, r, t * (1.0 + float(i) * 0.3), t * (1.0 + float(i) * 0.3) + 4.2, 32, Color(0.62, 0.42, 1.0, 0.7 - float(i) * 0.12), 5.0)
				if ph3 >= 3.9:
					var hp := Vector2(W * 0.28 + 30.0, H * 0.82 - 40.0)
					for k in 3:
						var ts: float = 3.9 + float(k) * 1.3
						var f2: float = (ph3 - ts) / 0.5
						if f2 >= 0.0 and f2 <= 1.0:
							var tp := Vector2(W * (0.58 + 0.12 * float(k)), H * (0.78 + 0.03 * float(k % 2)) - 40.0)
							var bp: Vector2 = hp.lerp(tp, f2)
							draw_circle(bp, 12.0, Color(1.0, 0.45, 0.1, 0.85))
							draw_circle(bp, 7.0, Color(1.0, 0.85, 0.3))
							draw_line(bp, bp - (tp - hp).normalized() * 30.0, Color(1.0, 0.5, 0.15, 0.6), 8.0)
						elif f2 > 1.0 and f2 < 1.5:
							var ep := Vector2(W * (0.58 + 0.12 * float(k)), H * (0.78 + 0.03 * float(k % 2)) - 40.0)
							draw_arc(ep, 10.0 + (f2 - 1.0) * 60.0, 0.0, TAU, 20, Color(1.0, 0.7, 0.2, 1.5 - f2), 4.0)
				var left: int = maxi(0, 480 - int(t * 8.0))
				_txt(Vector2(0, 38), "%d:%02d" % [left / 60, left % 60], 32, Color.WHITE, W, HORIZONTAL_ALIGNMENT_CENTER)
			"type":
				_txt(Vector2(W * 0.04, 36), String(info.get("type_lbl", "")), 24, Color("#ffd65c"))
			"team":
				var tl: Array = info.get("team", [])
				for i in range(maxi(0, tl.size() - 1)):
					var ax: float = W * (0.28 + 0.22 * float(i) + (0.0 if tl.size() > 2 else 0.1)) + 55.0
					draw_arc(Vector2(ax + 18.0, H * 0.55), 14.0, 0.2 + t * 2.0, 4.4 + t * 2.0, 14, Color(1, 1, 1, 0.8), 4.0)
			"coop":
				var a1 := Vector2(W * 0.32, H * 0.5)
				var a2 := Vector2(W * 0.62, H * 0.5)
				for i in 6:
					var f: float = fposmod(t * 0.8 + float(i) / 6.0, 1.0)
					draw_circle(a1.lerp(a2, f), 3.0 + 3.0 * sin(f * PI), Color(1, 0.85, 0.3, 0.85))
			"party":
				for i in 40:
					var fx: float = fposmod(float(i) * 37.0, W)
					var fy2: float = fposmod(t * (40.0 + float(i % 7) * 12.0) + float(i) * 23.0, H)
					draw_rect(Rect2(fx, fy2, 6, 6), Color.from_hsv(float(i % 9) / 9.0, 0.7, 1.0, 0.9))
				_txt(Vector2(0, 44), "∞", 46, Color("#ffd65c"), W, HORIZONTAL_ALIGNMENT_CENTER)
			"chal":
				var c2 := Vector2(W * 0.66, H * 0.5)
				var fr: float = fposmod(t * 0.15, 1.0)
				draw_arc(c2, 66.0, 0.0, TAU, 48, Color(1, 1, 1, 0.15), 10.0)
				draw_arc(c2, 66.0, -PI * 0.5, -PI * 0.5 + TAU * fr, 48, Color("#ffd65c"), 10.0)
				var rem: int = 600 - int(600.0 * fr)
				_txt(Vector2(c2.x - 70, c2.y + 12), "%d:%02d" % [rem / 60, rem % 60], 38, Color.WHITE, 140.0, HORIZONTAL_ALIGNMENT_CENTER)
				_txt(Vector2(W * 0.34, 34), String(info.get("goal1", "")), 18, Color("#d6e2ff"))
			"mods":
				var on: Array = info.get("on", [])
				var k := {"hp": 1.0, "spd": 1.0, "dmg": 1.0, "xp": 1.0, "coin": 1.0 + 0.25 * float(on.size()), "ehp": 1.0, "espd": 1.0, "edmg": 1.0, "ecnt": 1.0}
				var has := func(id: String) -> bool: return on.has(id)
				if has.call("frail"): k["hp"] *= 0.5
				if has.call("slow"): k["spd"] *= 0.8
				if has.call("glass"): k["dmg"] *= 1.5; k["edmg"] *= 2.0
				if has.call("brainy"): k["xp"] *= 1.5; k["ehp"] *= 1.25
				if has.call("rich"): k["coin"] *= 2.0; k["ehp"] *= 1.3
				if has.call("tank"): k["ehp"] *= 1.6
				if has.call("plague"): k["ehp"] *= 0.65; k["ecnt"] *= 2.5
				if has.call("fast"): k["espd"] *= 1.4
				if has.call("hard"): k["edmg"] *= 1.5
				if has.call("horde"): k["ecnt"] *= 1.8
				var rows_p := [["HP", "hp", true], ["Speed", "spd", true], ["Damage", "dmg", true], ["Experience", "xp", true], ["Coins", "coin", true]]
				var rows_e := [["HP", "ehp", false], ["Speed", "espd", false], ["Damage", "edmg", false], ["Amount", "ecnt", false]]
				var cols := [[W * 0.33, L.t("You"), rows_p], [W * 0.67, L.t("Enemies"), rows_e]]
				for c in cols:
					var x0: float = float(c[0])
					var cw: float = W * 0.31
					_txt(Vector2(x0, 28), String(c[1]), 20, Color("#ffd65c"))
					var rr: Array = c[2]
					for i in rr.size():
						var y: float = 46.0 + 36.0 * float(i)
						var key: String = String(rr[i][1])
						var v: float = float(k[key])
						var good: bool = (v >= 1.0) == bool(rr[i][2])
						var col: Color = Color("#ffffff") if absf(v - 1.0) < 0.001 else (Color("#6fd08a") if good else Color("#ff6b6b"))
						_txt(Vector2(x0, y + 14), L.t(String(rr[i][0])), 16, Color("#f2e9d8"))
						var bx: float = x0 + cw * 0.46
						var bw: float = cw * 0.54
						draw_rect(Rect2(bx, y + 3, bw, 12), Color(0, 0, 0, 0.4))
						draw_rect(Rect2(bx + bw * 0.5 - 1.0, y, 2, 18), Color(1, 1, 1, 0.5))
						var f: float = clampf(log(v) / log(4.0), -1.0, 1.0) * 0.5
						draw_rect(Rect2(bx + bw * 0.5 + minf(0.0, f) * bw, y + 3, absf(f) * bw, 12), col)
						_txt(Vector2(bx, y + 32), "×%s" % (("%.2f" % v).rstrip("0").rstrip(".")), 14, col, bw, HORIZONTAL_ALIGNMENT_RIGHT)
				if has.call("nohealing"):
					_txt(Vector2(14, 26), L.t("No healing"), 16, Color("#ff6b6b"))
		_txt(Vector2(W - 150, H - 8), String(info.get("tag", "")), 14, Color(1, 1, 1, 0.45), 140.0, HORIZONTAL_ALIGNMENT_RIGHT)


func _build_modes() -> void:
	var s: Control = _screen("modes")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_label("Choose a mode", 34, C_GOLD))
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 14)
	v.add_child(hb)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(400, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	hb.add_child(sc)
	var mgap := MarginContainer.new()   # keeps the mode buttons off the scroll bar
	mgap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mgap.add_theme_constant_override("margin_right", 12)
	sc.add_child(mgap)
	modes_box = VBoxContainer.new()
	modes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modes_box.add_theme_constant_override("separation", 8)
	mgap.add_child(modes_box)
	# panel derecho: reglas arriba, vista previa, datos, opciones y Jugar
	var rp := PanelContainer.new()
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.6), Color("#5a5099"), 2, 14))
	hb.add_child(rp)
	# Todo el panel derecho se desplaza de arriba abajo (con rueda, dedo o mando) para que nada quede tapado ni fuera de pantalla.
	var rpv := VBoxContainer.new()   # details scroll; the Play button below never does
	rpv.add_theme_constant_override("separation", 8)
	rp.add_child(rpv)
	var rsc := ScrollContainer.new()
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rsc.follow_focus = true
	rsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rpv.add_child(rsc)
	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 8)
	rsc.add_child(rv)
	mp_title = _label("", 30, C_GOLD)
	rv.add_child(mp_title)
	var rbox := PanelContainer.new()
	rbox.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.28), Color(1, 1, 1, 0.12), 1, 10))
	rv.add_child(rbox)
	var rbv := VBoxContainer.new()
	rbv.add_theme_constant_override("separation", 3)
	rbox.add_child(rbv)
	rbv.add_child(_label("Rules", 17, Color("#b4aed6")))
	mp_rules = VBoxContainer.new()
	mp_rules.add_theme_constant_override("separation", 2)
	rbv.add_child(mp_rules)
	mp_prev = load("res://scripts/menu.gd").ModePrev.new()
	mp_prev.custom_minimum_size = Vector2(0, 190)
	mp_prev.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mp_prev.clip_contents = true
	rv.add_child(mp_prev)
	mp_stat = _label("", 18, Color("#f2e9d8"))
	rv.add_child(mp_stat)
	mp_opts_sc = ScrollContainer.new()
	mp_opts_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mp_opts_sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rpv.add_child(mp_opts_sc)   # toggles (Hyper, co-op partner, party...) stay pinned above Play: no scrolling to reach them
	mp_opts = VBoxContainer.new()
	mp_opts.add_theme_constant_override("separation", 6)
	mp_opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_opts_sc.add_child(mp_opts)
	mp_play = _btn("Play", func(): _modes_play(), Vector2(0, 52))
	mp_play.add_theme_font_size_override("font_size", 26)
	rpv.add_child(mp_play)


func _mode_tile(m: Array) -> Button:
	var id: String = String(m[0])
	var b := Button.new()
	b.icon = IC.btn_tex(String(m[2]), 40)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", 14)
	b.add_theme_constant_override("icon_max_width", 40)
	b.text = L.t(String(m[1]))
	b.custom_minimum_size = Vector2(0, 58)
	b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func():
		Aud.sfx("click")
		_modes_select(id)
		_gf(mp_play if mp_play.visible else mp_opts.get_child(0) if mp_opts.get_child_count() > 0 else b))
	b.focus_entered.connect(func():
		Aud.sfx("hover")
		_modes_select(id))
	modes_box.add_child(b)
	mode_tiles[id] = b
	return b


var _warmed: Dictionary = {}


# Carga en segundo plano las hojas de sprites que usan las vistas previas, para que al cambiar de modo
# no haya un tirón (y la música no se corte) la primera vez que se ve cada uno.
func _warm_previews() -> void:
	var ds: Array = [int(SV.d["selected"]), SV.daily_dex(SV.daily_seed()), int(SV.d.get("coop_dex", 133)), 133, 248, 19, 16, 41, 10, 21, 74, 25, 150, 144, 145, 146]
	for x in SV.team_list():
		ds.append(int(x))
	for d in ds:
		if d <= 0 or _warmed.has(d):
			continue
		_warmed[d] = true
		for sub in ["s/", ""]:
			for nm in ["Idle", "Walk"]:
				var path := "res://assets/pokemon/%d/%s%s.png" % [d, sub, nm]
				if ResourceLoader.exists(path):
					ResourceLoader.load_threaded_request(path)


func _refresh_modes() -> void:
	_warm_previews()
	_clear(modes_box)
	mode_tiles.clear()
	SV.run_mods = Array(SV.d.get("mods", []))
	var group := ""
	var first: Button = null
	for m in MODE_LIST:
		if String(m[3]) != group:
			group = String(m[3])
			var gl := _label(group, 18, Color("#b4aed6"))
			modes_box.add_child(gl)
		var tb: Button = _mode_tile(m)
		if first == null or String(m[0]) == modes_sel:
			if first == null or String(m[0]) == modes_sel:
				first = tb
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 60)   # margen final: la ultima opcion nunca queda pegada al borde
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modes_box.add_child(tail)
	# v5.2.1: arriba/abajo entre modos solo recorre la lista de modos (antes, a veces, el cursor saltaba al panel de modificadores)
	var tl: Array = []
	for mm in MODE_LIST:
		tl.append(mode_tiles[String(mm[0])])
	for ti in range(tl.size()):
		var tt: Control = tl[ti]
		tt.focus_neighbor_top = tt.get_path_to(tl[maxi(ti - 1, 0)])
		tt.focus_neighbor_bottom = tt.get_path_to(tl[mini(ti + 1, tl.size() - 1)])
	_modes_select(modes_sel)
	focus_first = mode_tiles.get(modes_sel, first)


func _mode_def(id: String) -> Array:
	for m in MODE_LIST:
		if String(m[0]) == id:
			return m
	return MODE_LIST[0]


func _modes_select(id: String) -> void:
	modes_sel = id
	var m: Array = _mode_def(id)
	for k in mode_tiles:
		var tb: Button = mode_tiles[k]
		if is_instance_valid(tb):
			_gold_btn(tb, k == id)
	mp_title.text = L.t(String(m[1]))
	_clear(mp_rules)
	for r in m[4]:
		mp_rules.add_child(_label("• " + L.t(String(r)), 19))
	_clear(mp_opts)
	mp_stat.text = ""
	mp_play.visible = true
	mp_play.text = L.t("Play")
	var hero: int = int(SV.d["selected"])
	var info := {"hero": hero, "tag": L.t("Preview")}
	var pm := "normal"
	match id:
		"normal":
			var hy: bool = bool(SV.d.get("hyper", false))
			var hbest: int = int(SV.d["stats"].get("hyper_best", 0))
			mp_stat.text = L.t("Hyper: everything runs twice as fast (waves, bosses, rifts and Eternatus at 30 min), with +30% experience and ×1.5 coins.")
			if hbest > 0:
				mp_stat.text += "  " + L.t("Best Hyper time: %s") % ("%d:%02d" % [hbest / 60, hbest % 60])
			mp_opts.add_child(_btn(L.t("Hyper mode: ON") if hy else L.t("Hyper mode: OFF"), func():
				SV.d["hyper"] = not hy
				SV.save()
				_modes_select("normal"), Vector2(0, 46)))
		"daily":
			var ds: int = SV.daily_seed()
			var dd: Dictionary = SV.d.get("daily", {})
			var best: int = int(dd.get("best", 0)) if int(dd.get("date", 0)) == ds else 0
			var dm: String = SV.daily_mod(ds)
			mp_stat.text = L.t("Today: %s with the rule “%s” (same for everyone). +25%% coins.") % [_name_of(SV.daily_dex(ds)), L.t(String(MOD_INFO[dm][0]))] + "  " + (L.t("Your best time today: %s") % ("%d:%02d" % [best / 60, best % 60]) if best > 0 else L.t("You haven't played it today."))
			var td: Dictionary = Time.get_date_dict_from_system()
			info["dex"] = SV.daily_dex(ds)
			info["overlay"] = SV.daily_dex(ds)
			var dmv: String = SV.natural_start_of(SV.daily_dex(ds))
			if not ResourceLoader.exists("res://assets/previews/daily_%s.ogv" % dmv):
				dmv = String(MD.START.get(String(SV.dex_by[SV.daily_dex(ds)]["types"][0]), "tackle"))
			info["vid"] = "daily_" + dmv
			info["day"] = str(int(td["day"]))
			info["month"] = ["", "ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"][int(td["month"])]
			info["rule"] = L.t(String(MOD_INFO[dm][0]))
			pm = "daily"
		"rush":
			mp_stat.text = L.t("Record: %d bosses") % int(SV.d.get("rush_best", 0))
			pm = "rush"
		"tower":
			var tw: Dictionary = SV.d.get("tower", {})
			mp_stat.text = L.t("Best floor: %d · Relics: %d / %d") % [int(tw.get("best", 0)), SV.tower_relics(), TOWER_FLOORS_M / 5]
			var tstarts: Array = [1]
			var tcl: Dictionary = tw.get("claimed", {})
			for k in range(5, TOWER_FLOORS_M, 5):
				if tcl.has(str(k)):
					tstarts.append(k + 1)
			var tcur: int = int(SV.d.get("tower_start", 1))
			if not tstarts.has(tcur):
				tcur = 1
				SV.d["tower_start"] = 1
			info["floor"] = tcur
			info["floor_lbl"] = L.t("Floor")
			if tstarts.size() > 1:
				mp_opts.add_child(_btn(L.t("Starting floor: %d") % tcur, func():
					var i: int = tstarts.find(int(SV.d.get("tower_start", 1)))
					SV.d["tower_start"] = int(tstarts[(i + 1) % tstarts.size()])
					SV.save()
					_modes_select("tower"), Vector2(0, 46)))
			pm = "tower"
		"rifts":
			mp_stat.text = L.t("Record: %d rifts") % int(SV.d.get("rifts_best", 0))
			pm = "rifts"
		"type":
			var ty: String = String(SV.d.get("mode_type", "fire"))
			if not TYPE_IDS.has(ty):
				ty = "fire"
			mp_stat.text = L.t("Type: %s") % L.t(String(MD.TYPE_NAME[ty]))
			var ids: Array = []
			for maxr in [2, 3, 9]:
				ids.clear()
				for p in SV.dex_list:
					if ids.size() >= 10:
						break
					if Array(p["types"]).has(ty) and int(p["rarity"]) <= maxr and not bool(p.get("leg", false)):
						ids.append(int(p["dex"]))
				if ids.size() >= 6:
					break
			info["dexes"] = ids
			info["type_lbl"] = L.t(String(MD.TYPE_NAME[ty]))
			mp_opts.add_child(_btn(L.t("Change type: %s") % L.t(String(MD.TYPE_NAME[ty])), func():
				SV.d["mode_type"] = String(TYPE_IDS[(TYPE_IDS.find(ty) + 1) % TYPE_IDS.size()])
				SV.save()
				_modes_select("type"), Vector2(0, 46)))
			pm = "type"
		"team":
			var tl: Array = SV.team_list()
			var names: Array = []
			for x in tl:
				names.append(_name_of(int(x)))
			info["team"] = tl
			if SV.owned_count() >= 2:
				mp_stat.text = L.t("Team: %s") % ", ".join(names)
				mp_opts.add_child(_btn(L.t("Choose team (up to 3)"), func():
					dex_pick_team = true
					SV.d["team"] = []
					toast(L.t("Tap up to 3 of your Pokémon for the team"))
					_show("dex"), Vector2(0, 46)))
			else:
				mp_stat.text = L.t("You need at least 2 Pokémon to form a team.")
				mp_play.disabled = true
			pm = "team"
		"coop":
			var cdx: int = int(SV.d.get("coop_dex", 0))
			if cdx <= 0 or not SV.dex_by.has(cdx):
				cdx = 133
				for x in SV.team_list():
					if int(x) != int(SV.d["selected"]):
						cdx = int(x)
						break
			info["coop"] = cdx
			mp_stat.text = L.t("Partner: %s") % _name_of(cdx)
			mp_opts.add_child(_btn(L.t("Choose partner"), func():
				dex_pick_coop = true
				toast(L.t("Tap the Pokémon that will be your partner"))
				_show("dex"), Vector2(0, 46)))
			pm = "coop"
		"party":
			info["dex"] = SV.party_dex
			mp_stat.text = L.t("Party Pokémon: %s") % _name_of(SV.party_dex)
			mp_opts.add_child(_btn(L.t("Choose the party Pokémon"), func():
				dex_pick_party = true
				toast(L.t("Tap a Pokémon for the party"))
				_show("dex"), Vector2(0, 46)))
			pm = "party"
		"chal_p", "chal_d", "chal_w":
			CH.st()
			var cat: String = id.substr(5)
			var done_n := 0
			for d in CH.all():
				if CH.is_done(CH.key_perm(int(d["id"]))):
					done_n += 1
			if cat == "p":
				mp_stat.text = L.t("Completed: %d / 100") % done_n
			else:
				mp_stat.text = L.t("Renew in %s") % CH.fmt_left(CH.secs_to_reset(cat == "w"))
			info["goal1"] = L.t("Survive %d min") % 3
			mp_play.text = L.t("View challenges")
			pm = "chal"
		"mods":
			mp_play.visible = false
			info["on"] = SV.run_mods
			var mg := GridContainer.new()
			mg.columns = 2
			mg.add_theme_constant_override("h_separation", 10)
			mg.add_theme_constant_override("v_separation", 4)
			mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mp_opts.add_child(mg)
			mp_stat.text = L.t("Tap a modifier to turn it on. They all stack.")
			for mid in SV.MOD_IDS:
				var cb := CheckButton.new()
				cb.text = L.t(String(MOD_INFO[mid][0]))
				cb.focus_mode = Control.FOCUS_ALL
				cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				cb.clip_text = true
				cb.icon = IC.btn_tex(String(MOD_ICON[mid]), 28)
				cb.add_theme_constant_override("icon_max_width", 28)
				cb.add_theme_font_size_override("font_size", 18)
				cb.button_pressed = SV.run_mods.has(mid)
				var minfo: String = L.t(String(MOD_INFO[mid][1]))
				cb.focus_entered.connect(func(): mp_stat.text = minfo)
				cb.mouse_entered.connect(func(): mp_stat.text = minfo)
				cb.toggled.connect(func(on: bool):
					mp_stat.text = minfo
					if on and not SV.run_mods.has(mid):
						SV.run_mods.append(mid)
					elif not on:
						SV.run_mods.erase(mid)
					SV.d["mods"] = SV.run_mods.duplicate()
					SV.save()
					mp_prev.info["on"] = SV.run_mods)
				mg.add_child(cb)
			pm = "mods"
	if id != "daily" and id != "party":
		mp_play.disabled = mp_play.disabled and id == "team"
	else:
		mp_play.disabled = false
	if id != "team":
		mp_play.disabled = false
	if id == "team" and SV.owned_count() < 2:
		mp_play.disabled = true
	(mp_prev as Control).visible = not id.begins_with("chal_")
	mp_opts_sc.custom_minimum_size = Vector2.ZERO
	mp_opts_sc.visible = mp_opts.get_child_count() > 0
	call_deferred("_fit_mode_opts")
	mp_prev.custom_minimum_size = Vector2(0, 110 if id == "mods" else 140)
	(mp_prev as Control).call("setup", pm, info)


# Pinned options take their natural height, capped so Play always stays on screen (taller sets scroll inside).
func _fit_mode_opts() -> void:
	if not is_instance_valid(mp_opts_sc):
		return
	var h: float = mp_opts.get_combined_minimum_size().y
	mp_opts_sc.custom_minimum_size = Vector2(0, minf(h, 170.0))


func _modes_play() -> void:
	var id: String = modes_sel
	if id.begins_with("chal_"):
		chal_cat = id.substr(5)
		_show("chal")
	else:
		_start_mode(id)



# ---------------------------------------------------------------
# Retos de 10 minutos (challenges.gd): pantalla propia, se abre desde Jugar > Retos
# ---------------------------------------------------------------
var chal_box: VBoxContainer
var chal_cat := "p"      # p permanentes, d diarios, w semanales
var chal_diff := ""      # filtro de dificultad de los permanentes ("" = todos)


func _build_chal() -> void:
	var s: Control = _screen("chal")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)
	chal_box = VBoxContainer.new()
	chal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chal_box.add_theme_constant_override("separation", 8)
	sc.add_child(chal_box)


func _coin_row(n: int, gold: bool, size: float = 26.0) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	r.add_child(IC.rect("gcoin_gold" if gold else "gcoin", size))
	var l := _label("×%d" % n, int(size * 0.85), Color("#ffd65c") if gold else Color("#d9cdb5"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_child(l)
	return r


func _chal_card(d: Dictionary, inst: Dictionary) -> Button:
	var done: bool = CH.is_done(String(inst["key"]))
	var ok: bool = CH.available(d)
	var gold: bool = CH.reward_gold(inst)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(0.110, 0.094, 0.200, 0.8) if ok else Color(0.078, 0.063, 0.157, 0.7), Color("#ffd65c") if (gold and ok) else Color("#5a5099"), 3 if gold else 2, 14))
	chal_box.add_child(pc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	pc.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	col.add_child(top)
	var num := _label("#%03d" % int(d["id"]), 18, Color("#b4aed6"))
	num.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(num)
	var nm := _label(CH.name_of(d), 24, Color.WHITE if ok else Color("#8a93a8"))
	nm.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(nm)
	var dc := PanelContainer.new()
	dc.add_theme_stylebox_override("panel", _sb(Color(CH.DIFF_COL[String(d["d"])], 0.25), CH.DIFF_COL[String(d["d"])], 2, 8))
	var dl := _label(L.t(String(CH.DIFF_NAME[String(d["d"])])), 16, CH.DIFF_COL[String(d["d"])])
	dl.autowrap_mode = TextServer.AUTOWRAP_OFF
	dc.add_child(dl)
	top.add_child(dc)
	for ln in CH.lines(d, CH.new_metrics()):
		col.add_child(_label("• " + String(ln[0]), 18, Color("#d6e2ff") if ok else Color("#7d869b")))
	for rt in CH.restrictions(d):
		col.add_child(_label("⚠ " + String(rt), 17, Color("#ffb454") if ok else Color("#7d869b")))
	var rc := VBoxContainer.new()
	rc.custom_minimum_size = Vector2(190, 0)
	rc.alignment = BoxContainer.ALIGNMENT_CENTER
	rc.add_theme_constant_override("separation", 8)
	row.add_child(rc)
	var cr := _coin_row(1, gold)
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	rc.add_child(cr)
	var out: Button = null
	var b: Button
	if done:
		b = _btn("Claimed", func(): pass, Vector2(180, 48))
		b.disabled = true
	elif not ok:
		b = _btn("Coming soon", func(): pass, Vector2(180, 48))
		b.disabled = true
	else:
		var ii: Dictionary = inst
		b = _btn("Play", func(): _chal_play(ii), Vector2(180, 48))
		out = b
	rc.add_child(b)
	return out


func _chal_play(inst: Dictionary) -> void:
	SV.run_mode = "chal"
	SV.run_chal = inst.duplicate()
	SV.run_mods = []
	SV.run_dex = int(SV.d["selected"])
	SV.run_type = String(SV.d.get("mode_type", "fire"))
	SV.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _refresh_chal() -> void:
	_clear(chal_box)
	CH.st()
	var sel_chip: Button = null
	var bal := HBoxContainer.new()
	bal.add_theme_constant_override("separation", 22)
	var t1 := _label("10-minute challenges", 28, C_GOLD)
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bal.add_child(t1)
	bal.add_child(_coin_row(int(SV.d.get("gcoins", 0)), false, 30.0))
	bal.add_child(_coin_row(int(SV.d.get("gold_coins", 0)), true, 30.0))
	var bsp := Control.new()
	bsp.custom_minimum_size = Vector2(14, 0)
	bal.add_child(bsp)
	chal_box.add_child(bal)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	chal_box.add_child(chips)
	for c in [["p", "Permanent"], ["d", "Daily"], ["w", "Weekly"]]:
		var ck: String = String(c[0])
		var cb := _btn(String(c[1]), func(): chal_cat = ck; _refresh_chal(); _gf(tab_sel), Vector2(190, 46))
		_gold_btn(cb, ck == chal_cat)
		chips.add_child(cb)
		if ck == chal_cat:
			sel_chip = cb
			tab_sel = cb
	tab_row = chips
	chal_box.add_child(_label("Each attempt lasts 10 minutes at most. If you fail, there is no reward and you can retry. Each challenge gives its reward only once.", 16, Color("#f2e9d8")))
	var first_card: Button = null
	if chal_cat == "p":
		var dch := HFlowContainer.new()
		dch.add_theme_constant_override("h_separation", 8)
		chal_box.add_child(dch)
		for f in [["", "All"], ["e", "Easy"], ["n", "Normal"], ["h", "Hard"], ["x", "Expert"]]:
			var fk: String = String(f[0])
			var fb := _btn(String(f[1]), func(): chal_diff = fk; _refresh_chal(), Vector2(130, 40))
			_gold_btn(fb, fk == chal_diff)
			dch.add_child(fb)
		var done_n := 0
		for d in CH.all():
			if CH.is_done(CH.key_perm(int(d["id"]))):
				done_n += 1
		chal_box.add_child(_label(L.t("Completed: %d / 100") % done_n, 20, Color("#f2e9d8")))
		for d in CH.all():
			if chal_diff != "" and String(d["d"]) != chal_diff:
				continue
			var b: Button = _chal_card(d, CH.instance_perm(d))
			if b != null and first_card == null:
				first_card = b
	else:
		var wk: bool = chal_cat == "w"
		var lst: Array = CH.weekly() if wk else CH.daily()
		chal_box.add_child(_label(L.t("Renew in %s") % CH.fmt_left(CH.secs_to_reset(wk)), 20, Color("#ffd65c")))
		for inst in lst:
			var b2: Button = _chal_card(CH.by_id(int(inst["id"])), inst)
			if b2 != null and first_card == null:
				first_card = b2
	focus_first = first_card if first_card != null else sel_chip



func _refresh_main() -> void:
	var dex: int = int(SV.d["selected"])
	if not SV.owns(dex) and SV.owned_count() > 0:
		dex = int(SV.d["owned"].keys()[0])
		SV.d["selected"] = dex
	var shn: bool = SV.shiny_wanted(dex)
	if is_instance_valid(main_prev):
		main_prev.queue_free()
	main_prev = Preview.new()
	main_prev.custom_minimum_size = Vector2(340, 240)
	main_card.add_child(main_prev)
	main_prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_prev.setup(dex, shn, 6.0)
	if is_instance_valid(main_news_ov):
		main_card.move_child(main_news_ov, main_card.get_child_count() - 1)
	main_info.text = "%s · %s" % [_name_of(dex), _type_text(dex)]
	var ttl: String = String(SV.d.get("title", ""))
	if ttl != "":
		main_info.text += "\n" + L.t(ttl)
	if is_instance_valid(resume_btn):
		var snap: Dictionary = RS.load_snap()
		resume_btn.visible = not snap.is_empty()
		if not snap.is_empty():
			resume_btn.text = "%s\n%s" % [L.t("Resume run"), RS.describe(snap)]
	if is_instance_valid(cont_btn):
		var first_run: bool = int(SV.d["stats"].get("runs", 0)) <= 0
		cont_btn.text = "%s\n%s \u00b7 %s" % [L.t("Play") if first_run else L.t("Play again"), _name_of(dex), _mode_name(_last_mode_id())]
	PG.ensure()
	PG.check()
	var pn: int = PG.pending()
	_set_tile_text(goals_btn, L.t("Missions") + ("  (%d)" % pn if pn > 0 else ""))
	var st: Dictionary = SV.d["stats"]
	main_chips["dex"].text = "%d / %d" % [SV.owned_count(), SV.dex_list.size()]
	main_chips["runs"].text = str(int(st["runs"]))
	main_chips["time"].text = "%d:%02d" % [int(st["best_time"]) / 60, int(st["best_time"]) % 60]
	main_chips["level"].text = str(int(st["best_level"]))
	main_chips["kills"].text = str(int(st["kills"]))
	var lb = main_btns.get(last_pick, null)
	focus_first = lb if lb != null and is_instance_valid(lb) else main_play_btn


# Pantalla de fin de partida como la del original: titulo, cuadricula de datos,
# monedas con desglose, tickets, movimientos y boton de volver.
func _stat_cell(label: String, value: String, col: Color = Color.WHITE, wide: bool = false) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	v.add_child(_label(label, 16, Color("#b4aed6")))
	var l := _label(value, 28 if not wide else 24, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(l)
	return pc


func _show_run_summary() -> void:
	var r: Dictionary = SV.last_run
	SV.last_run = {}
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.6)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.z_index = 40
	add_child(ov)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(c)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(620, 0)
	pc.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Todo el contenido va en un scroll de alto limitado a la pantalla y el boton queda FIJO debajo (antes se salia y no se veia).
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	var sum_sc := ScrollContainer.new()
	sum_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sum_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sum_sc.add_child(v)
	outer.add_child(sum_sc)
	pc.add_child(outer)
	var title := _label("You fell…" if bool(r.get("dead", true)) else "Run over", 38, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var t: int = int(r["time"])
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	g.add_child(_stat_cell(L.t("Time"), "%02d:%02d" % [t / 60, t % 60]))
	g.add_child(_stat_cell(L.t("Level"), str(int(r["level"]))))
	g.add_child(_stat_cell(L.t("Defeated"), str(int(r["kills"]))))
	g.add_child(_stat_cell(L.t("Bosses"), str(int(r["bosses"]))))
	var jr: Dictionary = r.get("judge", {})
	if not jr.is_empty():
		var jt: int = int(jr["time"])
		var jb: int = int(jr["bosses"])
		var jc := _stat_cell(L.t("Against Arceus"), "%d:%02d · %d %s" % [jt / 60, jt % 60, jb, L.t("legendary") if jb == 1 else L.t("legendaries")], C_GOLD, true)
		v.add_child(jc)
	# monedas con desglose
	var cc := PanelContainer.new()
	cc.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 2)
	cc.add_child(cv)
	cv.add_child(_label("PokéCoins earned", 16, Color("#b4aed6")))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 8)
	gr.add_child(IC.rect("coin", 28))
	var gl := _label("+%d" % int(r["coins"]), 28, Color("#ffd65c"))
	gl.autowrap_mode = TextServer.AUTOWRAP_OFF
	gr.add_child(gl)
	cv.add_child(gr)
	if String(r.get("breakdown", "")) != "":
		var bl := _label(L.t("Collected %d · Time +%d · Defeated +%d") % _bd_nums(String(r["breakdown"])), 13, Color("#b4aed6"))
		bl.autowrap_mode = TextServer.AUTOWRAP_OFF
		cv.add_child(bl)
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(cc)
	v.add_child(mid)
	if int(r["tickets"]) > 0 or int(r.get("tickets10", 0)) > 0:
		var tc := PanelContainer.new()
		tc.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 2)
		tc.add_child(tv)
		tv.add_child(_label("Gacha tickets", 16, Color("#b4aed6")))
		var tr := HBoxContainer.new()
		tr.add_theme_constant_override("separation", 8)
		if int(r["tickets"]) > 0:
			tr.add_child(IC.rect("ticket", 26))
			var tl1 := _label("+%d" % int(r["tickets"]), 26, Color("#ffd65c"))
			tl1.autowrap_mode = TextServer.AUTOWRAP_OFF
			tr.add_child(tl1)
		if int(r.get("tickets10", 0)) > 0:
			tr.add_child(IC.rect("ticket10", 26))
			var tl2 := _label("+%d ×10" % int(r["tickets10"]), 26, Color("#c47bff"))
			tl2.autowrap_mode = TextServer.AUTOWRAP_OFF
			tr.add_child(tl2)
		tv.add_child(tr)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_child(tc)
	# movimientos de la partida
	var mc := PanelContainer.new()
	mc.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	mc.add_child(mv)
	mv.add_child(_label("Damage and defeats per move", 16, Color("#b4aed6")))
	var mlist: Array = r.get("moves", []).duplicate()
	mlist.sort_custom(func(x, y): return int(x.get("dmg", 0)) > int(y.get("dmg", 0)))
	var tot_dmg: int = int(r.get("other_dmg", 0))
	tot_dmg += int(r.get("ally_dmg", 0))
	for m0 in mlist:
		tot_dmg += int(m0.get("dmg", 0))
	var mg := GridContainer.new()
	mg.columns = 3
	mg.add_theme_constant_override("h_separation", 18)
	mg.add_theme_constant_override("v_separation", 3)
	if mlist.size() > 999:
		var msc := ScrollContainer.new()
		msc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		msc.custom_minimum_size = Vector2(0, 170)
		mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		msc.add_child(mg)
		mv.add_child(msc)
	else:
		mv.add_child(mg)
	if mlist.is_empty():
		mg.add_child(_label("—", 18))
	else:
		var h1 := _label("Move", 13, Color("#b4aed6"))
		h1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h1.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h1)
		var h2 := _label("Damage", 13, Color("#b4aed6"))
		h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h2.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h2)
		var h3 := _label("Defeated", 13, Color("#b4aed6"))
		h3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h3.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h3)
	for m in mlist:
		var mr := HBoxContainer.new()
		mr.add_theme_constant_override("separation", 6)
		mr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mr.add_child(IC.rect(("evo:" if bool(m.get("evo", false)) else "move:") + String(m["id"]), 20))
		var mnm: String = String(m["name"])
		var mparts: PackedStringArray = mnm.split(" + ")
		var mtr: Array = []
		for mp in mparts:
			mtr.append(L.t(mp))
		var ml := _label("%s Nv.%d" % [" + ".join(PackedStringArray(mtr)), int(m["lvl"])], 17)
		ml.autowrap_mode = TextServer.AUTOWRAP_OFF
		mr.add_child(ml)
		mg.add_child(mr)
		var md_: int = int(m.get("dmg", 0))
		var pct: int = roundi(100.0 * float(md_) / float(maxi(1, tot_dmg)))
		var dl := _label("%s (%d%%)" % [_fmt_n(md_), pct], 17, Color("#ffd65c"))
		dl.autowrap_mode = TextServer.AUTOWRAP_OFF
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(dl)
		var kl := _label(str(int(m.get("kills", 0))), 17)
		kl.autowrap_mode = TextServer.AUTOWRAP_OFF
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(kl)
	if int(r.get("ally_dmg", 0)) > 0 or int(r.get("ally_kills", 0)) > 0:
		var al := _label("Partner / team", 17, Color("#6fd08a"))
		al.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(al)
		var ad := _label("%s (%d%%)" % [_fmt_n(int(r.get("ally_dmg", 0))), roundi(100.0 * float(int(r.get("ally_dmg", 0))) / float(maxi(1, tot_dmg)))], 17, Color("#6fd08a"))
		ad.autowrap_mode = TextServer.AUTOWRAP_OFF
		ad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ad)
		var ak := _label(str(int(r.get("ally_kills", 0))), 17, Color("#6fd08a"))
		ak.autowrap_mode = TextServer.AUTOWRAP_OFF
		ak.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ak)
	if int(r.get("other_dmg", 0)) > 0 or int(r.get("other_kills", 0)) > 0:
		var ol := _label("Other (status, traps, items)", 15, Color("#b4aed6"))
		ol.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(ol)
		var od := _label(_fmt_n(int(r.get("other_dmg", 0))), 15, Color("#b4aed6"))
		od.autowrap_mode = TextServer.AUTOWRAP_OFF
		od.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(od)
		var ok2 := _label(str(int(r.get("other_kills", 0))), 15, Color("#b4aed6"))
		ok2.autowrap_mode = TextServer.AUTOWRAP_OFF
		ok2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ok2)
	v.add_child(mc)
	# v5.2: objetos y movimientos de la partida con su descripcion
	var info_items: Array = r.get("items", [])
	var info_moves: Array = r.get("moves", [])
	if not info_items.is_empty() or not info_moves.is_empty():
		var ic2 := PanelContainer.new()
		ic2.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
		var iv := VBoxContainer.new()
		iv.add_theme_constant_override("separation", 5)
		ic2.add_child(iv)
		if not info_items.is_empty():
			iv.add_child(_label("Items", 16, Color("#b4aed6")))
			for iid in info_items:
				for it in TD.ITEMS:
					if String(it["id"]) == String(iid):
						var irow := HBoxContainer.new()
						irow.add_theme_constant_override("separation", 8)
						irow.add_child(IC.rect(String(it["id"]), 30))
						var itx := _label("%s: %s" % [L.t(String(it["name"])), L.t(String(it["desc"]))], 15)
						itx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						irow.add_child(itx)
						iv.add_child(irow)
		if not info_moves.is_empty():
			iv.add_child(_label("What each move does", 16, Color("#b4aed6")))
			for m1 in info_moves:
				if String(m1.get("desc", "")) == "":
					continue
				var mrow := HBoxContainer.new()
				mrow.add_theme_constant_override("separation", 8)
				mrow.add_child(IC.rect(("evo:" if bool(m1.get("evo", false)) else "move:") + String(m1["id"]), 26))
				var mtx := _label("%s: %s" % [L.t(String(m1["name"])), L.t(String(m1["desc"]))], 15)
				mtx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				mrow.add_child(mtx)
				iv.add_child(mrow)
		v.add_child(ic2)
	if bool(r.get("record", false)):
		var rl := _label("New time record!", 22, C_GOLD)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outer.add_child(rl)
	var ok := _btn("Back to menu", func(): ov.queue_free(); _update_top(); focus_first = main_play_btn; main_play_btn.grab_focus(), Vector2(260, 56))
	var again := _btn("Play again", func(): _replay_last(), Vector2(260, 56))
	_gold_btn(again, true)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 16)
	brow.add_child(again)
	brow.add_child(ok)
	outer.add_child(brow)
	_gf(again)
	var fit := func():
		var avail: float = get_viewport_rect().size.y - 150.0
		sum_sc.custom_minimum_size = Vector2(0, clampf(v.get_combined_minimum_size().y, 100.0, maxf(100.0, avail)))
	fit.call()
	fit.call_deferred()
	_update_top()


func _fmt_n(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (float(n) / 1000000.0)
	if n >= 10000:
		return "%.1fk" % (float(n) / 1000.0)
	return str(n)


func _bd_nums(bd: String) -> Array:
	var out: Array = []
	for part in bd.split(" · "):
		out.append(int(part.get_slice(" ", part.get_slice_count(" ") - 1).replace("+", "")))
	while out.size() < 3:
		out.append(0)
	return out


# ---------------------------------------------------------------
# Test de personalidad
# ---------------------------------------------------------------
func _build_test() -> void:
	var s: Control = _screen("test")
	var c := CenterContainer.new()
	s.add_child(c)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(820, 0)
	c.add_child(pc)
	test_box = VBoxContainer.new()
	pc.add_child(test_box)


func _refresh_test() -> void:
	test_idx = -1
	test_scores = {}
	_clear(test_box)
	test_box.add_child(_label("Welcome to Megarift Survivors!", 36, C_GOLD))
	test_box.add_child(_label("Like in Mystery Dungeon, a few questions will decide your personality and your partner.\nYou can accept the result or pick a different starter.", 24))
	var b := _btn("Start the quiz", func(): _test_next(), Vector2(0, 60))
	test_box.add_child(b)
	var skip := _btn("Skip the quiz: pick a strong starter", func(): _test_pick_strong(), Vector2(0, 60))
	test_box.add_child(skip)
	focus_first = b


func _test_next() -> void:
	test_idx += 1
	_clear(test_box)
	if test_idx >= ST.TEST.size():
		_test_finish()
		return
	var q: Dictionary = ST.TEST[test_idx]
	test_box.add_child(_label(L.t("Question %d / %d") % [test_idx + 1, ST.TEST.size()], 20, Color("#b4aed6")))
	test_box.add_child(_label(String(q["q"]), 30, Color.WHITE))
	var first: Button = null
	for a in q["a"]:
		var ans: Dictionary = a
		var b := _btn(String(ans["t"]), func(): _test_answer(ans), Vector2(0, 56))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		test_box.add_child(b)
		if first == null:
			first = b
	_gf(first)


func _test_answer(ans: Dictionary) -> void:
	for k in ans["p"]:
		test_scores[k] = int(test_scores.get(k, 0)) + int(ans["p"][k])
	_test_next()


func _test_finish() -> void:
	var trt := ""
	var best := -1
	for k in test_scores:
		if int(test_scores[k]) > best:
			best = int(test_scores[k])
			trt = String(k)
	var cands: Array = []
	var best_s := -1
	for s in ST.STARTERS:
		var v: int = int(test_scores.get(String(s["traits"][0]), 0)) * 2 + int(test_scores.get(String(s["traits"][1]), 0))
		if v > best_s:
			best_s = v
			cands = [s]
		elif v == best_s:
			cands.append(s)
	test_result_dex = int(cands[randi() % cands.size()]["dex"])
	_test_show_result(trt)


func _test_show_result(trt: String) -> void:
	_clear(test_box)
	test_box.add_child(_label(L.t("Your personality: %s") % L.t(trt.capitalize()), 34, C_GOLD))
	test_box.add_child(_label(String(ST.TRAIT_TEXT.get(trt, "")), 22, Color("#f2e9d8")))
	var pv := Preview.new()
	pv.custom_minimum_size = Vector2(0, 220)
	test_box.add_child(pv)
	pv.setup(test_result_dex, false, 5.0)
	var nm := _label(L.t("Your partner: %s (%s)") % [_name_of(test_result_dex), _type_text(test_result_dex)], 28)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_box.add_child(nm)
	var row := HBoxContainer.new()
	test_box.add_child(row)
	var ok := _btn("Accept!", func(): _accept_starter(test_result_dex), Vector2(0, 58))
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ok)
	var other := _btn("Choose another", func(): _test_pick_other(), Vector2(0, 58))
	other.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(other)
	_gf(ok)


# "Skip the quiz": a short list of strong, fully evolved partners (most can Mega Evolve), chosen right away.
func _test_pick_strong() -> void:
	_clear(test_box)
	test_box.add_child(_label("Pick a strong starter", 32, C_GOLD))
	test_box.add_child(_label("Fully evolved partners, most of them able to Mega Evolve. You can collect the rest from the Gacha.", 18, Color("#f2e9d8")))
	var grid := GridContainer.new()
	grid.columns = 4 if _compact() else 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	test_box.add_child(grid)
	var first: Button = null
	for dx in ST.STRONG:
		var dxi: int = int(dx)
		if not SV.dex_by.has(dxi):
			continue
		var b := _btn("", func(): _accept_starter(dxi), Vector2(120, 110))
		var tx: Texture2D = _icon_tex(dxi, false)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
		b.text = _name_of(dxi)
		b.add_theme_font_size_override("font_size", 14)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		grid.add_child(b)
		if first == null:
			first = b
	var back := _btn("Back", func(): _refresh_test(), Vector2(0, 52))
	test_box.add_child(back)
	_gf(first)


func _test_pick_other() -> void:
	_clear(test_box)
	test_box.add_child(_label("Choose your partner", 32, C_GOLD))
	var grid := GridContainer.new()
	grid.columns = 6
	test_box.add_child(grid)
	var first: Button = null
	for s in ST.STARTERS:
		var dx: int = int(s["dex"])
		var b := _btn("", func(): _accept_starter(dx), Vector2(120, 100))
		var tx: Texture2D = _icon_tex(dx, false)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
		b.text = _name_of(dx)
		b.add_theme_font_size_override("font_size", 14)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		grid.add_child(b)
		if first == null:
			first = b
	_gf(first)


func _accept_starter(dex: int) -> void:
	SV.add_owned(dex)
	SV.d["selected"] = dex
	SV.save()
	toast(L.t("%s joins your team!") % _name_of(dex))
	_show("main")


# ---------------------------------------------------------------
# Iconos
# ---------------------------------------------------------------
func _icon_tex(dex: int, shiny: bool) -> Texture2D:
	var an: Dictionary = Preview.anim_of(dex)
	if an.is_empty():
		return null
	var tx: Texture2D = Preview.tex_of(dex, String(an["name"]), shiny)
	if tx == null:
		return null
	var info: Dictionary = an["info"]
	var at := AtlasTexture.new()
	at.atlas = tx
	at.region = Rect2(0.0, 0.0, float(info["w"]), float(info["h"]))
	return at


# ---------------------------------------------------------------
# Coleccion de Pokemon
# ---------------------------------------------------------------
# Fondo del retrato: paisaje con cielo, montanas y claro (tintado con el tipo del Pokemon).
class DexBack extends Control:
	var tint := Color("#ff7b3d")

	# Escenario del retrato: degradado Dusk teñido con el tipo, suelo en perspectiva y foco bajo el Pokemon.
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var top: Color = UIS.INK.lerp(tint, 0.10)
		var bot: Color = UIS.PANEL_HI.lerp(tint, 0.32)
		var n := 22
		for i in n:
			draw_rect(Rect2(0, h * float(i) / n, w, h / n + 1.0), top.lerp(bot, float(i) / float(n - 1)))
		for i in 18:
			var sx: float = fposmod(float(i) * 83.7, w)
			var sy: float = fposmod(float(i) * 47.3, h * 0.55)
			draw_rect(Rect2(sx, sy, 2, 2), Color(UIS.TEXT, 0.25 + 0.4 * fposmod(float(i) * 0.37, 1.0)))
		var hy: float = h * 0.62
		draw_rect(Rect2(0, hy, w, h - hy), Color(UIS.BG, 0.92).lerp(tint.darkened(0.6), 0.25))
		for i in range(-8, 9):
			draw_line(Vector2(w * 0.5 + float(i) * 18.0, hy), Vector2(w * 0.5 + float(i) * 90.0, h), Color(tint.lightened(0.3), 0.28), 1.0)
		for j in range(1, 6):
			var yy: float = hy + (h - hy) * pow(float(j) / 6.0, 1.6)
			draw_line(Vector2(0, yy), Vector2(w, yy), Color(tint.lightened(0.3), 0.22), 1.0)
		draw_rect(Rect2(0, hy - 1, w, 2), Color(tint.lightened(0.4), 0.7))
		var pts := PackedVector2Array()
		for a in range(32):
			var ang: float = TAU * float(a) / 32.0
			pts.append(Vector2(w * 0.5 + cos(ang) * w * 0.28, h * 0.8 + sin(ang) * 16.0))
		draw_colored_polygon(pts, Color(tint, 0.30))


var dex_search := ""
var dex_sort := 0
var dex_type := ""   # filtro por tipo ("" = todos)
var dex_prog_lbl: Label
var dex_prog_bar: ProgressBar
var dex_cards: Dictionary = {}
var dex_hearts: Dictionary = {}
var dex_tabs: Array = []
var dex_pv_box: Control
var dex_namebar: HBoxContainer
var dex_name_heart: Button
var dex_foot: HBoxContainer
var dex_hint: Label
var dex_stat_max: Dictionary = {}
const RAR_COL := ["#b0a99f", "#5fcb6a", "#4b9bff", "#b45ec4", "#ffd65c"]


func _dpanel(col: Color = Color(0.078, 0.063, 0.157, 0.72)) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := _sb(col, Color("#5a5099"), 2, 12)
	st.set_content_margin_all(10)
	pc.add_theme_stylebox_override("panel", st)
	return pc


func _is_fav(dx: int) -> bool:
	return Dictionary(SV.d.get("dex_fav", {})).has(str(dx))


func _heart_btn(dx: int, size: float) -> Button:
	var hb := Button.new()
	hb.flat = true
	hb.focus_mode = Control.FOCUS_NONE
	hb.icon = IC.btn_tex("heart", size)
	hb.add_theme_constant_override("icon_max_width", int(size))
	hb.custom_minimum_size = Vector2(size + 8.0, size + 8.0)
	hb.pressed.connect(func(): _fav_toggle(dx))
	hb.modulate = Color(1, 0.3, 0.42) if _is_fav(dx) else Color(0.227, 0.196, 0.384, 0.9)
	return hb


func _fav_toggle(dx: int) -> void:
	var fv: Dictionary = Dictionary(SV.d.get("dex_fav", {}))
	if fv.has(str(dx)):
		fv.erase(str(dx))
	else:
		fv[str(dx)] = true
	SV.d["dex_fav"] = fv
	SV.save()
	Aud.sfx("click")
	for k in dex_hearts:
		var hb: Button = dex_hearts[k]
		if is_instance_valid(hb):
			hb.modulate = Color(1, 0.3, 0.42) if _is_fav(absi(int(k))) else Color(0.227, 0.196, 0.384, 0.9)


func _build_dex() -> void:
	var s: Control = _screen("dex")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	s.add_child(row)
	# ---- izquierda: retrato + ficha
	var dp := PanelContainer.new()
	dp.custom_minimum_size = Vector2(430, 0)
	var dst: StyleBox = UIS.frame(UIS.INK, UIS.EDGE).duplicate()
	dst.content_margin_left = 10
	dst.content_margin_right = 10
	dst.content_margin_top = 10
	dst.content_margin_bottom = 10
	dp.add_theme_stylebox_override("panel", dst)
	row.add_child(dp)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	dp.add_child(lv)
	var port := DexBack.new()
	port.custom_minimum_size = Vector2(0, 210)
	port.clip_contents = true
	lv.add_child(port)
	dex_pv_box = Control.new()
	dex_pv_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	dex_pv_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	port.add_child(dex_pv_box)
	for sd in [-1, 1]:
		var ab := Button.new()
		ab.focus_mode = Control.FOCUS_ALL
		ab.text = "◀" if sd < 0 else "▶"
		ab.add_theme_font_size_override("font_size", 26)
		ab.custom_minimum_size = Vector2(54, 54)
		ab.anchor_top = 0.68   # lower than centre: clears the type badge in the top-right corner
		ab.anchor_bottom = 0.68
		ab.anchor_left = 0.0 if sd < 0 else 1.0
		ab.anchor_right = ab.anchor_left
		ab.offset_left = 6.0 if sd < 0 else -60.0
		ab.offset_right = ab.offset_left + 54.0
		ab.offset_top = -27.0
		ab.offset_bottom = 27.0
		var dsd: int = sd
		ab.pressed.connect(func(): Aud.sfx("click"); _dex_step(dsd))
		port.add_child(ab)
	var nbp := _dpanel(Color("#141028"))
	lv.add_child(nbp)
	dex_namebar = HBoxContainer.new()
	dex_namebar.add_theme_constant_override("separation", 10)
	nbp.add_child(dex_namebar)
	var dsc := ScrollContainer.new()
	dsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dsc.follow_focus = true
	lv.add_child(dsc)
	dex_detail = VBoxContainer.new()
	dex_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dex_detail.add_theme_constant_override("separation", 8)
	dsc.add_child(dex_detail)
	dex_foot = HBoxContainer.new()
	lv.add_child(dex_foot)
	# ---- derecha: pestanas de region, filtros, cuadricula
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	var rpn := PanelContainer.new()
	rpn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rst: StyleBox = UIS.frame(UIS.PANEL, UIS.EDGE).duplicate()
	rst.content_margin_left = 10
	rst.content_margin_right = 10
	rst.content_margin_top = 10
	rst.content_margin_bottom = 10
	rpn.add_theme_stylebox_override("panel", rst)
	row.add_child(rpn)
	rpn.add_child(right)
	dex_hint = _label("", 20, C_GOLD)
	dex_hint.visible = false
	right.add_child(dex_hint)
	# progreso de coleccion de la region elegida
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 12)
	right.add_child(ph)
	dex_prog_lbl = _label("", 22, C_GOLD)
	dex_prog_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	ph.add_child(dex_prog_lbl)
	dex_prog_bar = ProgressBar.new()
	dex_prog_bar.show_percentage = false
	dex_prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dex_prog_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dex_prog_bar.custom_minimum_size = Vector2(0, 14)
	dex_prog_bar.add_theme_stylebox_override("fill", _sb(C_GOLD, Color.TRANSPARENT, 0))
	ph.add_child(dex_prog_bar)
	# regiones en una sola fila: Todas + 1..9 (nombre de la region en el tooltip)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	right.add_child(tabs)
	dex_tabs.clear()
	for i in range(10):
		var gi: int = i
		var tb := _btn(L.t("All") if i == 0 else L.t(String(SV.REGIONS[i - 1])), func(): dex_gen = gi; dex_page = 0; _refresh_dex(), Vector2(0, 40))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.clip_text = true
		tb.add_theme_font_size_override("font_size", 13)
		tb.tooltip_text = L.t("All") if i == 0 else "%s · %s" % [L.t(String(SV.REGIONS[i - 1])), L.t("Gen %d") % i]
		tabs.add_child(tb)
		dex_tabs.append(tb)
	# filtros: busqueda, tipo, orden y "solo los mios"
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 8)
	right.add_child(frow)
	var se := LineEdit.new()
	se.placeholder_text = L.t("Search Pokémon…")
	se.clear_button_enabled = true
	se.custom_minimum_size = Vector2(0, 44)
	se.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	se.add_theme_font_size_override("font_size", 18)
	se.add_theme_stylebox_override("normal", _sb(Color("#1c1833"), Color("#3a3262"), 2, 10))
	se.add_theme_stylebox_override("focus", _sb(Color("#1c1833"), C_GOLD, 3, 10))
	se.text_changed.connect(func(t: String): dex_search = t.strip_edges().to_lower(); dex_page = 0; _refresh_dex())
	frow.add_child(se)
	var to := OptionButton.new()
	to.custom_minimum_size = Vector2(150, 44)
	to.add_theme_font_size_override("font_size", 18)
	to.add_item(L.t("All the Types"))
	for ty in TYPE_IDS:
		to.add_item(L.t(String(MD.TYPE_NAME[String(ty)])))
	to.select(maxi(0, TYPE_IDS.find(dex_type) + 1))
	to.item_selected.connect(func(ix: int): dex_type = "" if ix == 0 else String(TYPE_IDS[ix - 1]); dex_page = 0; _refresh_dex())
	frow.add_child(to)
	var so := OptionButton.new()
	so.custom_minimum_size = Vector2(190, 44)
	so.add_theme_font_size_override("font_size", 18)
	for o in ["Number (Asc)", "Number (Desc)", "Name (A-Z)", "Rarity", "Favorites first"]:
		so.add_item(L.t(String(o)))
	so.select(dex_sort)
	so.item_selected.connect(func(ix: int): dex_sort = ix; dex_page = 0; _refresh_dex())
	frow.add_child(so)
	var own := CheckButton.new()
	own.text = "Mine only"
	own.add_theme_font_size_override("font_size", 18)
	own.button_pressed = dex_only_owned
	own.toggled.connect(func(on: bool): dex_only_owned = on; dex_page = 0; _refresh_dex())
	frow.add_child(own)
	var gsc := ScrollContainer.new()
	gsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gsc.follow_focus = true
	right.add_child(gsc)
	dex_grid = GridContainer.new()
	dex_grid.columns = 8
	dex_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dex_grid.add_theme_constant_override("h_separation", 6)
	dex_grid.add_theme_constant_override("v_separation", 6)
	gsc.add_child(dex_grid)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 14)
	right.add_child(nav)
	nav.add_child(_btn("◀", func(): dex_page = maxi(0, dex_page - 1); _refresh_dex(), Vector2(90, 44)))
	dex_page_lbl = _label("", 22)
	dex_page_lbl.custom_minimum_size = Vector2(260, 0)
	dex_page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(dex_page_lbl)
	nav.add_child(_btn("▶", func(): dex_page += 1; _refresh_dex(), Vector2(90, 44)))


func _dex_filtered() -> Array:
	var out: Array = []
	var q: String = dex_search
	for p in SV.dex_list:
		if dex_gen != 0 and int(p["gen"]) != dex_gen:
			continue
		var dxo: int = int(p["dex"])
		if (dex_only_owned or dex_pick_team or dex_pick_coop) and not dex_pick_party and not SV.owns(dxo):
			continue
		if not SV.smeta.has(str(dxo)):
			continue
		if dex_type != "" and not (p["types"] as Array).has(dex_type):
			continue
		if q != "":
			var known: bool = SV.owns(dxo) or dex_pick_party
			var hit: bool = str(dxo).contains(q.trim_prefix("#"))
			if known and not hit:
				hit = L.t(String(p["name"])).to_lower().contains(q) or String(p["name"]).to_lower().contains(q)
				if not hit:
					for t in p["types"]:
						if L.t(String(MD.TYPE_NAME[String(t)])).to_lower().contains(q):
							hit = true
			if not hit:
				continue
		out.append(p)
	match dex_sort:
		1:
			out.sort_custom(func(a, b): return int(a["dex"]) > int(b["dex"]))
		2:
			out.sort_custom(func(a, b): return L.t(String(a["name"])) < L.t(String(b["name"])))
		3:
			out.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["dex"]) < int(b["dex"])))
		4:
			out.sort_custom(func(a, b):
				var fa: bool = _is_fav(int(a["dex"]))
				var fb: bool = _is_fav(int(b["dex"]))
				return (fa and not fb) or (fa == fb and int(a["dex"]) < int(b["dex"])))
	return out


func _dex_step(d: int) -> void:
	var list: Array = _dex_filtered()
	if list.is_empty():
		return
	var ix := -1
	for i in range(list.size()):
		if int(list[i]["dex"]) == dex_sel:
			ix = i
			break
	ix = posmod(ix + d, list.size())
	dex_sel = int(list[ix]["dex"])
	dex_page = ix / _per_page()
	_refresh_dex()


func _card_style(b: Button, base: Color, edge: Color, bw: int) -> void:
	b.add_theme_stylebox_override("normal", _sb(base, edge, bw, 10))
	b.add_theme_stylebox_override("hover", _sb(base.lightened(0.12), C_GOLD, 2, 10))
	b.add_theme_stylebox_override("pressed", _sb(base.darkened(0.1), C_GOLD, 3, 10))
	b.add_theme_stylebox_override("focus", _sb_focus(base.lightened(0.1)))


func _dex_mark() -> void:
	for k in dex_cards:
		var b: Button = dex_cards[k]
		if not is_instance_valid(b):
			continue
		var base: Color = b.get_meta("base")
		var sel: bool = int(k) == dex_sel
		var team: bool = bool(b.get_meta("team"))
		_card_style(b, base, C_GOLD if sel else (Color("#35d0b0") if team else Color("#3a3262")), 4 if sel else 2)


# Shown on the first menu after a run that did not end normally: the tail of the previous session's log.
func _show_crash_report() -> void:
	var cr: Control = CR.new()
	add_child(cr)
	cr.build(CR.previous_log_tail())


# Squarer screens (4:3 handhelds) get bigger collection cards: fewer columns, larger text.
func _compact() -> bool:
	if Engine.has_meta("force_compact"):   # tests
		return bool(Engine.get_meta("force_compact"))
	var vp: Vector2 = get_viewport_rect().size
	return vp.x / maxf(vp.y, 1.0) < 1.5


func _per_page() -> int:
	return PER_PAGE_COMPACT if _compact() else PER_PAGE


func _dex_cols() -> int:
	return 6 if _compact() else 8


func _dex_card(p: Dictionary, owned: bool) -> Button:
	var ck: float = 1.3 if _compact() else 1.0
	var dx: int = int(p["dex"])
	var show: bool = owned or dex_pick_party
	var types: Array = p["types"]
	var tcol := Color.html(String(MD.TYPE_COLOR.get(String(types[0]), "#b0a99f")))
	var b := Button.new()
	b.custom_minimum_size = Vector2(86, 96) * ck
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.clip_contents = true
	var base := Color(0.110, 0.094, 0.200, 0.95).lerp(tcol, 0.22) if show else Color(0.078, 0.063, 0.157, 0.95)
	b.set_meta("base", base)
	b.set_meta("team", dex_pick_team and Array(SV.d.get("team", [])).has(dx))
	if show:
		var tn: Array = []
		for t in types:
			tn.append(L.t(String(MD.TYPE_NAME[String(t)])))
		b.tooltip_text = "%s · %s" % [L.t(String(p["name"])), " / ".join(PackedStringArray(tn))]
	# numero
	var nl := _label("#%03d" % dx, roundi(11.0 * ck), UIS.MUTED if show else Color(UIS.MUTED, 0.55))
	nl.autowrap_mode = TextServer.AUTOWRAP_OFF
	nl.position = Vector2(6.0, 3.0)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nl)
	# sprite
	var tr := TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_top = 16.0 * ck
	tr.offset_bottom = -32.0 * ck
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shn: bool = owned and SV.shiny_wanted(dx)
	tr.texture = _icon_tex(dx, shn)
	if not show:
		tr.modulate = Color(0, 0, 0, 0.5)
	b.add_child(tr)
	# nombre
	var nm := _label(L.t(String(p["name"])) if show else "", roundi(12.0 * ck), UIS.TEXT)
	nm.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nm.offset_top = -30.0 * ck
	nm.offset_bottom = -9.0
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.autowrap_mode = TextServer.AUTOWRAP_OFF
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	# franjas de tipo abajo (una por tipo)
	if show:
		for ti in range(types.size()):
			var sr := ColorRect.new()
			sr.color = Color.html(String(MD.TYPE_COLOR.get(String(types[ti]), "#b0a99f")))
			sr.anchor_left = float(ti) / float(types.size())
			sr.anchor_right = float(ti + 1) / float(types.size())
			sr.anchor_top = 1.0
			sr.anchor_bottom = 1.0
			sr.offset_top = -6.0
			sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(sr)
	if show:
		var mbadge: Control = _mega_badge(dx)
		if mbadge != null:   # "Megaevolucionable": solo la inicial (M / P / F / C); el detalle esta en la ficha
			(mbadge.get_child(0) as Label).text = (mbadge.get_child(0) as Label).text.left(1)
			mbadge.position = Vector2(40.0, 3.0)
			b.add_child(mbadge)
	if shn:
		var sh := _label("\u2726", 13, UIS.GOLD)
		sh.position = Vector2(6.0, 16.0)
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sh)
	if owned:
		var hb := _heart_btn(dx, 14.0)
		hb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		hb.offset_left = -26.0
		hb.offset_right = -2.0
		hb.offset_top = 1.0
		hb.offset_bottom = 25.0
		b.add_child(hb)
		dex_hearts[dx] = hb
		if dx == int(SV.d["selected"]):
			var st := IC.rect("star", 14)
			st.position = Vector2(62.0, 26.0)
			st.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(st)
	return b


# Insignia rosa "MEGA" / "PRIMAL" / "CORONA" para los Pokemon que pueden cambiar de forma en una partida (null si no).
func _mega_badge(dx: int) -> Control:
	var mf: Dictionary = MG.form_for(dx)
	if mf.is_empty() and dx != FM.DEX:
		return null
	var kind: String = String(mf["kind"]) if not mf.is_empty() else "forme"
	var txt: String = "MEGA" if kind == "mega" else ("PRIMAL" if kind == "primal" else (L.t("FORME") if kind == "forme" else L.t("CROWNED")))
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := _sb(Color("#ff8ad8").darkened(0.55), Color("#ff8ad8"), 1, 5)
	st.set_content_margin_all(1)
	st.content_margin_left = 4
	st.content_margin_right = 4
	pc.add_theme_stylebox_override("panel", st)
	var lb := _label(txt, 10, Color("#ffd2f0"))
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.autowrap_mode = TextServer.AUTOWRAP_OFF
	pc.add_child(lb)
	return pc


func _refresh_dex() -> void:
	var list: Array = _dex_filtered()
	dex_grid.columns = _dex_cols()
	var pages: int = maxi(1, ceili(float(list.size()) / float(_per_page())))
	dex_page = clampi(dex_page, 0, pages - 1)
	_clear(dex_grid)
	dex_cards.clear()
	dex_hearts.clear()
	for i in range(dex_tabs.size()):
		_gold_btn(dex_tabs[i], i == dex_gen)
	dex_hint.visible = dex_pick_team or dex_pick_coop or dex_pick_party
	if dex_pick_team:
		dex_hint.text = L.t("Pick 3 Pokémon for your team (%d / 3)") % Array(SV.d.get("team", [])).size()
	elif dex_pick_coop:
		dex_hint.text = L.t("Choose your co-op partner")
	elif dex_pick_party:
		dex_hint.text = L.t("Choose the party Pokémon")
	var prog := Vector2i(SV.owned_count(), SV.dex_list.size()) if dex_gen == 0 else _region_counts(dex_gen)
	dex_prog_lbl.text = "%s  %d / %d" % [L.t("Collection") if dex_gen == 0 else L.t(String(SV.REGIONS[dex_gen - 1])), prog.x, prog.y]
	dex_prog_bar.max_value = maxf(1.0, float(prog.y))
	dex_prog_bar.value = float(prog.x)
	var first: Button = null
	for i in range(dex_page * _per_page(), mini(list.size(), (dex_page + 1) * _per_page())):
		var p: Dictionary = list[i]
		var dx: int = int(p["dex"])
		var owned: bool = SV.owns(dx)
		var b: Button = _dex_card(p, owned)
		if dex_pick_party:
			b.pressed.connect(func():
				SV.party_dex = dx
				dex_pick_party = false
				toast(L.t("Party Pokémon: %s") % _name_of(dx))
				_show("modes"))
		elif dex_pick_coop:
			b.pressed.connect(func():
				SV.d["coop_dex"] = dx
				SV.save()
				dex_pick_coop = false
				toast(L.t("Partner: %s") % _name_of(dx))
				_show("modes"))
		elif dex_pick_team:
			b.pressed.connect(func():
				var tm: Array = Array(SV.d.get("team", []))
				if tm.has(dx):
					tm.erase(dx)
				elif tm.size() < 3:
					tm.append(dx)
				SV.d["team"] = tm
				SV.save()
				if tm.size() >= 3:
					dex_pick_team = false
					toast(L.t("Team ready!"))
					_show("modes")
				else:
					toast(L.t("Team: %d / 3") % tm.size())
					_refresh_dex())
		else:
			b.pressed.connect(func(): dex_sel = dx; Aud.sfx("click"); _dex_detail())
		b.focus_entered.connect(func(): Aud.sfx("hover"))
		dex_grid.add_child(b)
		dex_cards[dx] = b
		if first == null:
			first = b
	dex_page_lbl.text = L.t("Page %d / %d  (%d)") % [dex_page + 1, pages, list.size()]
	if not SV.dex_by.has(dex_sel):
		dex_sel = int(SV.d["selected"])
	_dex_detail()
	focus_first = first


func _stat_bar(title: String, value: String, frac: float, col: Color, icon: String = "") -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if icon != "":
		row.add_child(IC.rect(icon, 28))
	var lb := _label(title, 18, Color("#fff7d6"))
	lb.custom_minimum_size = Vector2(96, 0)
	row.add_child(lb)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(frac, 0.0, 1.0)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(80, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.078, 0.063, 0.157, 0.9)
	bg.set_corner_radius_all(0)
	bar.add_theme_stylebox_override("fill", fg)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	var vl := _label(value, 20, Color.WHITE)
	vl.custom_minimum_size = Vector2(62, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(vl)
	return row


func _dex_detail() -> void:
	_clear(dex_detail)
	_clear(dex_pv_box)
	_clear(dex_namebar)
	_clear(dex_foot)
	dex_hearts.erase(-dex_sel)
	var dx: int = dex_sel
	var p: Dictionary = SV.dex_by[dx]
	var owned: bool = SV.owns(dx)
	var tcol := Color.html(String(MD.TYPE_COLOR.get(String(p["types"][0]), "#b0a99f")))
	(dex_pv_box.get_parent() as DexBack).tint = tcol
	dex_pv_box.get_parent().queue_redraw()
	# retrato
	var pv := Preview.new()
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dex_pv_box.add_child(pv)
	var shiny_owned: bool = owned and bool(SV.d["owned"][str(dx)].get("shiny", false))
	pv.setup(dx, shiny_owned and SV.shiny_wanted(dx), 6.0, not owned)
	var ball := IC.rect("ball", 52)
	ball.position = Vector2(8, 8)
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dex_pv_box.add_child(ball)
	if owned:
		var bdg := PanelContainer.new()
		bdg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bst := _sb(tcol.darkened(0.3), tcol.lightened(0.3), 2, 12)
		bst.set_content_margin_all(5)
		bdg.add_theme_stylebox_override("panel", bst)
		bdg.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		bdg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		bdg.offset_left = -10.0
		bdg.offset_right = -10.0
		bdg.offset_top = 8.0
		var bv := VBoxContainer.new()
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_theme_constant_override("separation", 0)
		bdg.add_child(bv)
		for t in p["types"]:
			var ir := IC.rect("type:" + String(t), 34)
			ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			bv.add_child(ir)
		var tl := _label(L.t(String(MD.TYPE_NAME[String(p["types"][0])])).to_upper(), 14, Color.WHITE)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		bv.add_child(tl)
		dex_pv_box.add_child(bdg)
	# barra de nombre
	dex_namebar.add_child(IC.rect("ball", 36))
	var nm := _label(("#%03d  %s" % [dx, L.t(String(p["name"]))]) if owned else "#%03d  ???" % dx, 26, C_GOLD)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.autowrap_mode = TextServer.AUTOWRAP_OFF
	dex_namebar.add_child(nm)
	if owned:
		dex_namebar.add_child(IC.rect("star" if dx == int(SV.d["selected"]) else "starDim", 30))
		dex_name_heart = _heart_btn(dx, 26.0)
		dex_hearts[-dx] = dex_name_heart
		dex_namebar.add_child(dex_name_heart)
	if not owned:
		var nl := _label(L.t("You don't have it yet. Get it from the Gacha (region %d · %s).") % [int(p["gen"]), L.t(SV.REGIONS[int(p["gen"]) - 1])], 20, Color("#f2e9d8"))
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dex_detail.add_child(nl)
		_dex_mark()
		return
	# estadisticas reales con barras (relativas al maximo del catalogo)
	if dex_stat_max.is_empty():
		dex_stat_max = {"hp": 1.0, "spd": 1.0, "atk": 1.0}
		for q in SV.dex_list:
			dex_stat_max["hp"] = maxf(dex_stat_max["hp"], float(q["hp"]))
			dex_stat_max["spd"] = maxf(dex_stat_max["spd"], float(q["spd"]))
			dex_stat_max["atk"] = maxf(dex_stat_max["atk"], float(q["atk"]))
	var sp := _dpanel()
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	sp.add_child(sv)
	dex_detail.add_child(sp)
	sv.add_child(_stat_bar(L.t("HP"), str(int(p["hp"])), float(p["hp"]) / float(dex_stat_max["hp"]), Color("#ff6b7a"), "heart"))
	sv.add_child(_stat_bar(L.t("Speed"), str(int(p["spd"])), float(p["spd"]) / float(dex_stat_max["spd"]), Color("#6bd66b"), "boot"))
	sv.add_child(_stat_bar(L.t("Attack"), "x%.2f" % float(p["atk"]), float(p["atk"]) / float(dex_stat_max["atk"]), Color("#ffb86b"), "fist"))
	var mfm: Dictionary = MG.form_for(dx)
	if not mfm.is_empty():   # megaevolucion en partida: aviso con el objeto que la activa
		var mk: String = String(mfm["kind"])
		var mtxt: String = L.t("Can Mega Evolve in runs, using %s")
		if mk == "primal":
			mtxt = L.t("Can undergo Primal Reversion in runs, with the %s")
		elif mk == "crowned":
			mtxt = L.t("Can take its Crowned Form in runs, with the %s")
		var mlb := _label(mtxt % String(mfm["item"]), 18, Color("#ff9ee0"))
		mlb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sv.add_child(mlb)
	if dx == FM.DEX:   # Deoxys: cambio de forma en partida
		var flb := _label(L.t("Can change Forme in runs (Attack, Defense or Speed)"), 18, Color("#ff9ee0"))
		flb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sv.add_child(flb)
	# habilidad
	var abd: Dictionary = AB.FX[AB.of(dx)]
	var ap := _dpanel()
	var av := VBoxContainer.new()
	ap.add_child(av)
	dex_detail.add_child(ap)
	av.add_child(_icon_label("type:" + String(p["types"][0]), L.t("Ability: %s") % L.t(String(abd["name"])), 22, Color("#ffd98a"), 30.0))
	var ad := _label(L.t(String(abd["desc"])), 16, Color("#dbe6ff"))
	ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	av.add_child(ad)
	# movimiento inicial
	var mv: String = SV.start_move_of(dx)
	var mp := _dpanel()
	var mvv := VBoxContainer.new()
	mp.add_child(mvv)
	dex_detail.add_child(mp)
	mvv.add_child(_label(L.t("Starting Move"), 18, Color("#ffd98a")))
	mvv.add_child(_icon_label("move:" + mv, L.t(String(MD.MOVES[mv]["name"])), 24, Color.WHITE, 40.0))
	# movimiento Z
	var zl: Array = SV.zm_types(dx)
	if zl.is_empty():
		var zt := _label(L.t("Z-Move: locked (defeat %d Pokémon of its type)") % ZM.NEED, 15, Color("#8a96b0"))
		zt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dex_detail.add_child(zt)
	else:
		var zcur: String = SV.zm_type_for(dx)
		dex_detail.add_child(_icon_label("zc:" + zcur, L.t("Z-Move: %s") % L.t(String(ZM.DEF[zcur]["name"])), 18, Color("#ffb86b"), 32.0))
		if zl.size() > 1:
			dex_detail.add_child(_btn(L.t("Switch Z-Move"), func():
				var nx: String = String(zl[(zl.find(zcur) + 1) % zl.size()])
				SV.d["pz"][str(dx)] = nx
				SV.save()
				_dex_detail(), Vector2(0, 46)))
	var bl: Array = SV.bind_list(dx)
	var any_b := false
	for bm in bl:
		if String(bm) != "" and MD.MOVES.has(String(bm)):
			if not any_b:
				any_b = true
				dex_detail.add_child(_label(L.t("Equipped moves"), 16, Color("#ffd98a")))
			dex_detail.add_child(_icon_label("move:" + String(bm), L.t(String(MD.MOVES[String(bm)]["name"])), 16, Color("#f2e9d8"), 28.0))
	# rareza y cantidad
	var rr: int = clampi(int(p["rarity"]) - 1, 0, 4)
	var rrow := HBoxContainer.new()
	rrow.add_child(IC.rect("shiny" if rr == 4 else "star", 22))
	var rl := _label(L.t("Rarity: %s") % L.t(SV.RARITY_NAME[rr]), 18, Color.html(RAR_COL[rr]))
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rl.clip_text = true
	rrow.add_child(rl)
	var own_l := _label(L.t("Owned: x%d") % int(SV.d["owned"][str(dx)]["n"]), 18, Color("#fff7d6"))
	own_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	rrow.add_child(own_l)
	dex_detail.add_child(rrow)
	if shiny_owned:
		var cb := CheckButton.new()
		cb.text = "Use shiny version ✨"
		cb.button_pressed = SV.shiny_wanted(dx)
		cb.toggled.connect(func(on: bool): SV.set_shiny_pref(dx, on); SV.save(); _refresh_dex())
		dex_detail.add_child(cb)
	# boton Elegir (fijo abajo)
	if not (dex_pick_party or dex_pick_team or dex_pick_coop):
		var sel_b: Button
		if dx == int(SV.d["selected"]):
			sel_b = _btn("✔ Is your partner", func(): pass, Vector2(0, 54))
			sel_b.disabled = true
		else:
			sel_b = _btn("Choose", func(): SV.d["selected"] = dx; SV.save(); toast(L.t("Partner: %s") % _name_of(dx)); _refresh_dex(), Vector2(0, 54))
		sel_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sel_b.add_theme_font_size_override("font_size", 24)
		dex_foot.add_child(sel_b)
	_dex_mark()


# ---------------------------------------------------------------
# Mejoras permanentes
# ---------------------------------------------------------------
func _build_up() -> void:
	var s: Control = _screen("up")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	s.add_child(row)
	var lp := PanelContainer.new()
	lp.custom_minimum_size = Vector2(330, 0)
	row.add_child(lp)
	up_head = VBoxContainer.new()
	up_head.add_theme_constant_override("separation", 10)
	lp.add_child(up_head)
	# upgrade cards live on their own panel so they stay readable over the map
	var cpanel := PanelContainer.new()
	cpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cbox := UIS.box(Color(UIS.BG, 0.92), UIS.EDGE, 3, false)
	cbox.set_content_margin_all(12)
	cpanel.add_theme_stylebox_override("panel", cbox)
	row.add_child(cpanel)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cpanel.add_child(sc)
	up_box = VBoxContainer.new()
	up_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_box.add_theme_constant_override("separation", 12)
	sc.add_child(up_box)


const UP_ICON := {"hp": "heart", "atk": "fist", "spd": "boot", "cd": "clock", "def": "shield", "regen": "sprout", "magnet": "magnet", "xp": "book", "coins": "coin", "moves": "cards", "crit": "star", "size": "size", "reroll": "bond", "ban": "ban", "revive": "revive", "bag": "bag", "bag3": "bag", "tm": "tm", "wslot": "cards"}


# Reconstruye la pantalla de mejoras sin perder la seleccion del mando ni el scroll.
func _refresh_up_keep(key: String) -> void:
	var sc: ScrollContainer = null
	var p: Node = up_box.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		sc = p as ScrollContainer
	var sv: int = sc.scroll_vertical if sc != null else 0
	_refresh_up()
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(up_box) or cur != "up":
		return
	if sc != null:
		sc.scroll_vertical = sv
	var cand: Array = []
	for b in screens["up"].find_children("*", "Control", true, false):
		if b is BaseButton or b is OptionButton:
			cand.append(b)
	var target: Control = null
	var idx_key := -1
	for i in range(cand.size()):
		if String(cand[i].get_meta("fk", "")) == key:
			idx_key = i
			if not cand[i].disabled:
				target = cand[i]
			break
	if target == null and idx_key >= 0:
		# el boton quedo desactivado (maximo / sin monedas): el siguiente activo, o el anterior
		for i in range(idx_key + 1, cand.size()):
			if not cand[i].disabled:
				target = cand[i]
				break
		if target == null:
			for i in range(idx_key - 1, -1, -1):
				if not cand[i].disabled:
					target = cand[i]
					break
	if target != null:
		target.grab_focus()
		if sc != null:
			sc.scroll_vertical = sv
			sc.ensure_control_visible(target)


func _refresh_up() -> void:
	_clear(up_box)
	_clear(up_head)
	if not SV.owns(up_dex):
		up_dex = int(SV.d["selected"])
	var first: Button = null
	# --- left column: title, animated portrait, Pokemon selector, partner / upgrade-all buttons
	up_head.add_child(_label("Permanent upgrades", 28, UIS.GOLD))
	var por := Portrait.new()
	por.custom_minimum_size = Vector2(0, 190)
	por.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_head.add_child(por)
	var tcol := Color("#ff7b3d")
	var types: Array = SV.dex_by[up_dex]["types"]
	if not types.is_empty():
		tcol = Color.html(String(MD.TYPE_COLOR.get(String(types[0]), "#ff7b3d")))
	por.setup(up_dex, tcol)
	up_head.add_child(_label("Each Pokémon has its own upgrades: they only count when you play with it.", 16, UIS.MUTED))
	var orow := HBoxContainer.new()
	orow.add_theme_constant_override("separation", 6)
	up_head.add_child(orow)
	var owned: Array = _up_owned()
	var prev_b := _btn("◀", func(): _up_step(-1), Vector2(52, 56))
	prev_b.set_meta("fk", "upprev")
	orow.add_child(prev_b)
	var par0: String = L.t(" (partner)") if up_dex == int(SV.d["selected"]) else ""
	var pick_b := _btn((L.t("%s%s · %d levels") % [_name_of(up_dex), par0, SV.up_total(up_dex)]).replace(" · ", "\n") + "  ▾", _open_up_picker, Vector2(0, 56))
	pick_b.set_meta("fk", "uppick")
	pick_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick_b.clip_text = true
	pick_b.add_theme_font_size_override("font_size", 15)
	orow.add_child(pick_b)
	var next_b := _btn("▶", func(): _up_step(1), Vector2(52, 56))
	next_b.set_meta("fk", "upnext")
	orow.add_child(next_b)
	if owned.size() < 2:
		prev_b.disabled = true
		next_b.disabled = true
	if up_dex != int(SV.d["selected"]):
		var pb := _btn("Use as partner", func(): SV.d["selected"] = up_dex; SV.save(); toast(L.t("Partner: %s") % _name_of(up_dex)); _refresh_up(), Vector2(0, 48))
		up_head.add_child(pb)
	# S62.3: "Upgrade all" (only finite permanent upgrades of this Pokemon; atomic purchase with confirmation)
	var all_cost := 0
	for u0 in SV.UPGRADES:
		var l0: int = SV.up_level(String(u0["id"]), up_dex)
		for q in range(l0, int(u0["max"])):
			all_cost += SV.up_cost(String(u0["id"]), q)
	if all_cost > 0:
		var ab_txt: String = L.t("Upgrade all: %d") % all_cost
		if up_all_ok:
			ab_txt = L.t("Confirm: %d coins") % all_cost
		var ab := _btn(ab_txt, func(): _up_all(all_cost), Vector2(0, 52))
		ab.disabled = int(SV.d["coins"]) < all_cost
		ab.set_meta("fk", "upall")
		if not ab.disabled:
			_gold_btn(ab, true)
		up_head.add_child(ab)
	# --- tarjetas de mejoras
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_box.add_child(grid)
	var up_anchors: Array = []
	var up_extra: Array = []
	for u in SV.UPGRADES:
		var id: String = String(u["id"])
		var lv: int = SV.up_level(id, up_dex)
		var mx: int = int(u["max"])
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cbx := UIS.box(Color(UIS.INK, 0.7), UIS.WAVE if lv >= mx else UIS.EDGE, 2, false)
		cbx.content_margin_left = 12
		cbx.content_margin_right = 12
		cbx.content_margin_top = 10
		cbx.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", cbx)
		grid.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var uic := IC.rect(String(UP_ICON.get(id, "star")), 36)
		uic.custom_minimum_size.x = 44
		row.add_child(uic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		row.add_child(col)
		col.add_child(_label(String(u["name"]), 22))
		col.add_child(_label(String(u["unit"]), 16, Color("#f2e9d8")))
		var pips := Pips.new()
		pips.setup(lv, mx)
		col.add_child(pips)
		var btn: Button
		if lv >= mx:
			btn = _btn("Max", func(): pass, Vector2(120, 52))
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", _sb(Color("#2b2547"), Color("#3a3262"), 3, 12))
		else:
			var cost: int = SV.up_cost(id, lv)
			btn = _cost_btn("", str(cost), "", "coin", func(): _buy(id), Vector2(120, 52), int(SV.d["coins"]) >= cost, false, true)
			btn.set_meta("fk", "u:" + id)
			if first == null and not btn.disabled:
				first = btn
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		up_anchors.append(btn if not btn.disabled else null)
		up_extra.append(null)
		if id == "tm" and lv > 0:
			var tmcol := VBoxContainer.new()
			tmcol.add_theme_constant_override("separation", 6)
			tmcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var et := _btn(L.t("Choose"), func(): tm_open = not tm_open; _refresh_up_keep("tmelegir"), Vector2(120, 44))
			et.set_meta("fk", "tmelegir")
			up_extra[up_extra.size() - 1] = et
			tmcol.add_child(et)
			tmcol.add_child(btn)
			row.add_child(tmcol)
		elif id == "ban" and lv > 0:
			var bcol := VBoxContainer.new()
			bcol.add_theme_constant_override("separation", 6)
			bcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var nb: int = mini(SV.ban_list(up_dex).size(), lv)
			var eb := _btn(L.t("Choose (%d/%d)") % [nb, lv], func(): ban_open = not ban_open; _refresh_up_keep("elegir"), Vector2(120, 44))
			eb.set_meta("fk", "elegir")
			up_extra[up_extra.size() - 1] = eb
			bcol.add_child(eb)
			bcol.add_child(btn)
			row.add_child(bcol)
		else:
			row.add_child(btn)
	focus_first = first
	# Izquierda/derecha: cicla dentro de la fila de tarjetas (con vuelta al otro extremo).
	var ncol: int = grid.columns
	var ri := 0
	while ri < up_anchors.size():
		var rowb: Array = []
		var rowx: Array = []
		for ci in range(ncol):
			if ri + ci < up_anchors.size() and up_anchors[ri + ci] != null:
				rowb.append(up_anchors[ri + ci])
				rowx.append(up_extra[ri + ci])
		for k in range(rowb.size()):
			var nxt: Control = rowb[(k + 1) % rowb.size()]
			var prv: Control = rowb[posmod(k - 1, rowb.size())]
			for bb in [rowb[k], rowx[k]]:
				if bb == null:
					continue
				bb.focus_neighbor_right = bb.get_path_to(nxt)
				bb.focus_neighbor_left = bb.get_path_to(prv)
		ri += ncol
	if SV.up_level("tm", up_dex) > 0 and tm_open:
		up_box.add_child(_tm_panel())
	var ban_lv: int = SV.up_level("ban", up_dex)
	if ban_lv > 0 and ban_open:
		up_box.add_child(_ban_panel(ban_lv))
	up_box.add_child(_bind_panel())


# MT: elige el movimiento con el que empiezas cada partida (gratis cambiarlo cuando quieras).
func _tm_panel() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var cur: String = SV.start_move_of(up_dex)
	var sub := _label(L.t("Choose the move you start every run with. You can change it for free whenever you want."), 18, Color("#f2e9d8"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	v.add_child(fl)
	var ids: Array = SV.tm_pool(up_dex)
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	for id in ids:
		var on: bool = String(id) == cur
		var b := _btn(("✔ " if on else "") + L.t(String(MD.MOVES[id]["name"])), func():
			SV.tm_set(up_dex, String(id))
			Aud.sfx("select")
			_refresh_up_keep("tm:" + String(id)), Vector2(0, 40))
		b.set_meta("fk", "tm:" + String(id))
		if on:
			b.add_theme_stylebox_override("normal", _sb(Color("#7a5a14"), Color("#ffd65c"), 3, 10))
		fl.add_child(b)
	return pc


# Veto: toca los movimientos que no quieres que te salgan en las cartas de este Pokemon.
func _ban_panel(max_n: int) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var l := SV.ban_list(up_dex)
	var sub := _label(L.t("Tap the moves you don't want to see in your cards (%d/%d). The starting move can't be banned.") % [l.size(), max_n], 18, Color("#f2e9d8"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	v.add_child(fl)
	var ids: Array = SV.move_pool(up_dex)
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	for id in ids:
		var on: bool = l.has(id)
		var b := _btn(("✕ " if on else "") + L.t(String(MD.MOVES[id]["name"])), func():
			if SV.ban_toggle(up_dex, String(id), max_n):
				Aud.sfx("select")
			else:
				Aud.sfx("error")
				toast(L.t("You already have %d banned: remove one first") % max_n)
			_refresh_up_keep("b:" + String(id)), Vector2(0, 40))
		b.set_meta("fk", "b:" + String(id))
		if on:
			b.add_theme_stylebox_override("normal", _sb(Color("#7a2438"), Color("#ff6b7a"), 3, 10))
		fl.add_child(b)
	return pc


# Atajos: que movimiento va siempre en cada hueco (teclas 1-4 o iconos de abajo).
func _bind_panel() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_label("Move shortcuts", 22))
	var sub := _label("Choose which move always goes in each slot (keys 1-4 or the icons at the bottom), for muscle memory. If you do not have that many moves yet, it goes to the closest slot.", 17, Color("#f2e9d8"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var ids: Array = SV.move_pool(up_dex)
	ids.append(SV.start_move_of(up_dex))
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	var cur: Array = SV.bind_list(up_dex)
	var row := GridContainer.new()   # 2x2: four pickers in one row forced the whole screen wider than the viewport
	row.columns = 2
	row.add_theme_constant_override("h_separation", 16)
	row.add_theme_constant_override("v_separation", 8)
	v.add_child(row)
	for i in range(4):
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 10)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cell)
		var num := _label(str(i + 1), 22, C_GOLD)
		cell.add_child(num)
		var ob := OptionButton.new()
		ob.custom_minimum_size = Vector2(120, 46)
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.focus_mode = Control.FOCUS_ALL
		ob.add_item(L.t("Free"), 0)
		var sel := 0
		for k in range(ids.size()):
			ob.add_item(L.t(String(MD.MOVES[ids[k]]["name"])), k + 1)
			if String(cur[i]) == String(ids[k]):
				sel = k + 1
		ob.select(sel)
		var slot: int = i
		ob.item_selected.connect(func(idx: int):
			var pick: String = "" if idx == 0 else String(ids[idx - 1])
			SV.bind_set(up_dex, slot, pick)
			Aud.sfx("select")
			_refresh_up_keep("bind%d" % slot))
		ob.set_meta("fk", "bind%d" % slot)
		cell.add_child(ob)
	return pc


func _up_owned() -> Array:
	var owned: Array = []
	for k in SV.d["owned"].keys():
		owned.append(int(k))
	owned.sort()
	return owned


func _up_step(d: int) -> void:
	var owned: Array = _up_owned()
	if owned.is_empty():
		return
	var i: int = posmod(maxi(owned.find(up_dex), 0) + d, owned.size())
	up_dex = int(owned[i])
	Aud.sfx("select")
	_refresh_up_keep("uppick")


func _kb_hide() -> void:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f is LineEdit or f is TextEdit:
		f.release_focus()
	DisplayServer.virtual_keyboard_hide()


# Boton de cerrar/cancelar para pantalla tactil: antes baja el teclado virtual, que si no se "come" el primer toque.
func _btn_close(t: String, cb: Callable, sz: Vector2) -> Button:
	var b := _btn(t, func():
		_kb_hide()
		cb.call(), sz)
	return b


func _close_up_picker() -> void:
	if up_picker != null and is_instance_valid(up_picker):
		up_picker.queue_free()
	up_picker = null


# Selector grande y tactil (la lista desplegable normal es dificil de usar en el movil).
func _open_up_picker() -> void:
	pk_gen = 0
	pk_type = ""
	pk_q = ""
	pk_focus = ""
	_build_up_picker()


func _pk_filter_row(parent: Control, items: Array, cur_val, on_pick: Callable, prefix: String) -> void:
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 58)
	sc.get_h_scroll_bar().custom_minimum_size.y = 12
	parent.add_child(sc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	sc.add_child(hb)
	for it in items:
		var key: String = prefix + str(it["v"])
		var b := _btn(String(it["t"]), func():
			pk_focus = key
			on_pick.call(it["v"]), Vector2(0, 44))
		b.add_theme_font_size_override("font_size", 16)
		if it["v"] == cur_val:
			b.add_theme_stylebox_override("normal", _sb(Color("#3a6a2e"), C_GOLD, 3))
		if it.has("c"):
			b.add_theme_color_override("font_color", Color.html(String(it["c"])))
		hb.add_child(b)
		if key == pk_focus:
			b.call_deferred("grab_focus")


func _build_up_picker() -> void:
	_close_up_picker()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 50
	add_child(root)
	up_picker = root
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.98), Color(0.5, 0.62, 0.9, 0.8), 3, 14))
	pan.anchor_left = 0.06
	pan.anchor_right = 0.94
	pan.anchor_top = 0.05
	pan.anchor_bottom = 0.95
	pan.offset_left = 0
	pan.offset_right = 0
	pan.offset_top = 0
	pan.offset_bottom = 0
	root.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pan.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var tl := _label("Choose Pokémon", 26, C_GOLD)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	top.add_child(_btn_close("Close", _close_up_picker, Vector2(150, 56)))
	var search := LineEdit.new()
	search.text = pk_q
	search.placeholder_text = L.t("Search Pokémon by name…")
	search.clear_button_enabled = true
	search.custom_minimum_size = Vector2(0, 52)
	search.add_theme_font_size_override("font_size", 24)
	v.add_child(search)
	var gens: Array = [{"v": 0, "t": L.t("All")}]
	for gi in range(SV.REGIONS.size()):
		gens.append({"v": gi + 1, "t": "%d · %s" % [gi + 1, L.t(SV.REGIONS[gi])]})
	_pk_filter_row(v, gens, pk_gen, func(x): pk_gen = int(x); _build_up_picker(), "g")
	var tys: Array = [{"v": "", "t": L.t("All")}]
	for tk in MD.TYPE_NAME.keys():
		tys.append({"v": String(tk), "t": L.t(String(MD.TYPE_NAME[tk])), "c": String(MD.TYPE_COLOR.get(tk, "#ffffff"))})
	_pk_filter_row(v, tys, pk_type, func(x): pk_type = String(x); _build_up_picker(), "t")
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().custom_minimum_size.x = 30
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport_rect().size.x >= 1150.0 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	var focus_b: Button = null
	var shown := 0
	for dx in _up_owned():
		var d: int = int(dx)
		var info: Dictionary = SV.dex_by[d]
		if pk_gen != 0 and int(info["gen"]) != pk_gen:
			continue
		if pk_type != "" and not Array(info["types"]).has(pk_type):
			continue
		shown += 1
		var par: String = L.t(" (partner)") if d == int(SV.d["selected"]) else ""
		var mark: String = "✔ " if d == up_dex else ""
		var b := _btn(mark + L.t("%s%s · %d levels") % [_name_of(d), par, SV.up_total(d)], func():
			up_dex = d
			_close_up_picker()
			Aud.sfx("select")
			_refresh_up_keep("uppick"), Vector2(0, 76))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tx: Texture2D = _icon_tex(d, false)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.set_meta("q", (_name_of(d) + " " + String(info["name"]) + " " + str(d)).to_lower())
		grid.add_child(b)
		if d == up_dex and pk_focus == "":
			focus_b = b
	var none_l := _label("None match the filter.", 20, Color("#f2e9d8"))
	none_l.visible = shown == 0
	grid.add_child(none_l)
	var apply_q := func(t: String):
		pk_q = t
		var q: String = t.strip_edges().to_lower()
		var vis := 0
		for ch in grid.get_children():
			if ch == none_l:
				continue
			var ok: bool = q == "" or String(ch.get_meta("q", "")).contains(q)
			ch.visible = ok
			if ok:
				vis += 1
		none_l.visible = vis == 0
	search.text_changed.connect(apply_q)
	if pk_q != "":
		apply_q.call(pk_q)
	if focus_b != null and pk_q == "":
		await get_tree().process_frame
		if is_instance_valid(focus_b):
			focus_b.grab_focus()
			sc.ensure_control_visible(focus_b)


var up_all_ok := false


func _up_all(total: int) -> void:
	if int(SV.d["coins"]) < total:
		Aud.sfx("error")
		return
	if not up_all_ok:
		up_all_ok = true
		_refresh_up_keep("upall")
		return
	up_all_ok = false
	# compra atomica: con el total comprobado, cada compra individual es valida
	var ok := true
	for u in SV.UPGRADES:
		var id: String = String(u["id"])
		while SV.up_level(id, up_dex) < int(u["max"]) and ok:
			ok = SV.buy_upgrade(id, up_dex)
	Aud.sfx("buy" if ok else "error")
	toast(L.t("Upgrades purchased!") if ok else L.t("The purchase could not be completed."))
	_update_top()
	_refresh_up_keep("upall")


func _buy(id: String) -> void:
	if SV.buy_upgrade(id, up_dex):
		Aud.sfx("buy")
		toast("Upgrade bought!")
	else:
		Aud.sfx("error")
	_update_top()
	_refresh_up_keep("u:" + id)


# ---------------------------------------------------------------
# Gacha
# ---------------------------------------------------------------
func _build_gacha() -> void:
	var s: Control = _screen("gacha")
	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 16)
	s.add_child(grow)
	var rail := PanelContainer.new()
	rail.custom_minimum_size = Vector2(250, 0)
	grow.add_child(rail)
	gacha_rail = VBoxContainer.new()
	gacha_rail.add_theme_constant_override("separation", 6)
	rail.add_child(gacha_rail)
	gacha_box = VBoxContainer.new()
	gacha_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gacha_box.add_theme_constant_override("separation", 12)
	grow.add_child(gacha_box)
	gacha_result = ColorRect.new()
	gacha_result.color = Color(0, 0, 0, 0.7)
	gacha_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.z_index = 30
	gacha_result.visible = false
	add_child(gacha_result)


# ---------------------------------------------------------------------------
# Maquina Gachapon: una Gachapon Coin = 1 movimiento nuevo; la dorada = 2.
func _build_gachapon() -> void:
	var s: Control = _screen("gachapon")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	s.add_child(row)
	var lp := PanelContainer.new()
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lp.size_flags_stretch_ratio = 1.0
	row.add_child(lp)
	gp_machine = GP.Machine.new()
	gp_machine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gp_machine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gp_machine.sfx_cb = func(n: String): Aud.sfx(n)
	gp_machine.finished.connect(_gp_finished)
	lp.add_child(gp_machine)
	var rp := PanelContainer.new()
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.size_flags_stretch_ratio = 1.25
	row.add_child(rp)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rp.add_child(sc)
	gp_info = VBoxContainer.new()
	gp_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gp_info.add_theme_constant_override("separation", 10)
	sc.add_child(gp_info)


var gp_pending: Array = []


func _refresh_gachapon() -> void:
	_clear(gp_info)
	gacha_result.visible = false
	var hd := _label("TM Gachapon Machine", 36, C_GOLD)
	hd.autowrap_mode = TextServer.AUTOWRAP_OFF
	gp_info.add_child(hd)
	gp_info.add_child(_label("Insert a Gachapon Coin and turn the lever: a capsule comes out with a new move. The golden coin gives 2 moves.", 21, Color("#f2e9d8")))
	var bal := HBoxContainer.new()
	bal.add_theme_constant_override("separation", 22)
	bal.add_child(_coin_row(int(SV.d.get("gcoins", 0)), false, 34.0))
	bal.add_child(_coin_row(int(SV.d.get("gold_coins", 0)), true, 34.0))
	gp_info.add_child(bal)
	var bb := HFlowContainer.new()
	bb.add_theme_constant_override("h_separation", 10)
	bb.add_theme_constant_override("v_separation", 10)
	gp_info.add_child(bb)
	gp_btn1 = _btn("Use Gachapon Coin  (1 move)", func(): _gp_insert(false), Vector2(0, 54))
	gp_btn1.icon = IC.tex("gcoin", IC.scale_for("gcoin", 28))
	gp_btn1.add_theme_font_size_override("font_size", 22)
	bb.add_child(gp_btn1)
	gp_btn2 = _btn("Use Golden Gachapon Coin  (2 moves)", func(): _gp_insert(true), Vector2(0, 54))
	gp_btn2.icon = IC.tex("gcoin_gold", IC.scale_for("gcoin_gold", 28))
	gp_btn2.add_theme_font_size_override("font_size", 22)
	bb.add_child(gp_btn2)
	gp_btn1.disabled = int(SV.d.get("gcoins", 0)) <= 0
	gp_btn2.disabled = int(SV.d.get("gold_coins", 0)) <= 0
	gp_msg = _label("", 20, Color("#ff9a8a"))
	gp_info.add_child(gp_msg)
	if gp_btn1.disabled and gp_btn2.disabled:
		gp_msg.text = L.t("You have no coins. Earn Gachapon Coins by completing challenges.")
	elif GP.locked_ids().is_empty():
		gp_msg.text = L.t("You have unlocked every move in the machine!")
	var tot: int = GP.DATA.MOVES.size()
	gp_info.add_child(_label(L.t("Moves unlocked: %d / %d") % [GP.unlocked().size(), tot], 24, C_GOLD))
	gp_collection = HFlowContainer.new()
	gp_collection.add_theme_constant_override("h_separation", 8)
	gp_collection.add_theme_constant_override("v_separation", 8)
	gp_info.add_child(gp_collection)
	for m in GP.DATA.MOVES:
		var d = GP.Disc.new(GP.type_color(String(m["type"])), 46.0)
		d.locked = not GP.is_unlocked(String(m["id"]))
		d.tooltip_text = "" if d.locked else String(m["name"])
		gp_collection.add_child(d)
	gp_focus = gp_btn1 if not gp_btn1.disabled else (gp_btn2 if not gp_btn2.disabled else null)
	focus_first = gp_focus


func _gp_insert(gold: bool) -> void:
	if gp_machine.busy():
		return
	var got: Array = GP.spend(gold)
	if got.is_empty():
		gp_msg.text = L.t("The coin could not be used.")
		return
	gp_pending = got
	var cols: Array = []
	for id in got:
		cols.append(GP.type_color(String(GP.def_of(String(id))["type"])))
	gp_btn1.disabled = true
	gp_btn2.disabled = true
	gp_machine.play(gold, cols)
	_update_top()


func _gp_finished() -> void:
	var rows: Array = gp_pending
	gp_pending = []
	_clear(gacha_result)
	gacha_result.visible = true
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(620, 0)
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pc.add_child(v)
	var tt := _label("Move unlocked!" if rows.size() == 1 else "Moves unlocked!", 34, C_GOLD)
	tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tt)
	for id in rows:
		var m: Dictionary = GP.def_of(String(id))
		var col: Color = GP.type_color(String(m["type"]))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 16)
		v.add_child(hb)
		hb.add_child(GP.Disc.new(col, 84.0))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		vb.add_child(_label(String(m["name"]), 28, col.lightened(0.25)))
		vb.add_child(_label(L.t("Type: %s") % L.t(String(MD.TYPE_NAME[String(m["type"])])), 20, Color("#f2e9d8")))
		vb.add_child(_label(String(m["desc"]), 20))
	var ok := _btn_close("Accept", func():
		gacha_result.visible = false
		_refresh_gachapon()
		_gf(gp_focus if gp_focus != null else back_btn), Vector2(220, 54))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	_gf(ok)


# Por region: 2 legendarios a los lados, uno popular en el centro, y colores del escenario.
const BANNERS := [
	{"legs": [150, 151], "star": 6, "c1": "#5b2f8f", "c2": "#1f6f7a"},
	{"legs": [249, 250], "star": 157, "c1": "#b07a1c", "c2": "#3a3262"},
	{"legs": [383, 382], "star": 257, "c1": "#9a2f2f", "c2": "#3a3262"},
	{"legs": [483, 484], "star": 448, "c1": "#3a3262", "c2": "#9a2f78"},
	{"legs": [643, 644], "star": 571, "c1": "#2b2f3b", "c2": "#5a5099"},
	{"legs": [716, 717], "star": 658, "c1": "#3a3262", "c2": "#a8304f"},
	{"legs": [791, 792], "star": 778, "c1": "#c76a2a", "c2": "#2a8f93"},
	{"legs": [888, 889], "star": 815, "c1": "#8f2f8f", "c2": "#5a5099"},
	{"legs": [1007, 1005], "star": 908, "c1": "#c0581a", "c2": "#5a2fa0"},
]
const RARITY_COL := ["#f2e9d8", "#6fd08a", "#5fa8ff", "#c47bff", "#ffd65c"]
const RARITY_BALL := ["ball", "ball2", "ball3", "ball4", "ballLux"]


func _region_counts(region: int) -> Vector2i:
	var pool: Array = SV.region_pool(region)
	var n := 0
	for p in pool:
		if SV.owns(int(p["dex"])):
			n += 1
	return Vector2i(n, pool.size())


func _refresh_gacha() -> void:
	_clear(gacha_box)
	var first: Button = null
	# --- pestanas de region
	_clear(gacha_rail)
	tab_row = gacha_rail
	for i in range(1, 10):
		var r: int = i
		var tb := _btn("%s · %s" % [L.t(SV.REGIONS[r - 1]), L.t("Gen %d") % r], func(): gacha_region = r; _refresh_gacha(); _gf(tab_sel), Vector2(0, 52))
		tb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tb.add_theme_font_size_override("font_size", 20)
		if r == gacha_region:
			for st in ["normal", "hover", "pressed"]:
				tb.add_theme_stylebox_override(st, _sb(UIS.PANEL_HI, UIS.GOLD, 3, 0))
			first = tb
			tab_sel = tb
		gacha_rail.add_child(tb)
	# --- escenario + probabilidades
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gacha_box.add_child(main)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	main.add_child(left)
	var bd: Dictionary = BANNERS[gacha_region - 1]
	var banner := Banner.new()
	banner.c1 = Color.html(String(bd["c1"]))
	banner.c2 = Color.html(String(bd["c2"]))
	banner.custom_minimum_size = Vector2(0, 320)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(banner)
	var cnt: Vector2i = _region_counts(gacha_region)
	var tx := VBoxContainer.new()
	tx.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tx.offset_left = 22
	tx.offset_top = 16
	tx.offset_right = -22
	tx.add_theme_constant_override("separation", 6)
	banner.add_child(tx)
	var ttl := _label(L.t("%s Mystery") % L.t(SV.REGIONS[gacha_region - 1]), 40, C_GOLD)
	ttl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tx.add_child(ttl)
	tx.add_child(_label(L.t("The %d Pokémon of generation %d. The legendaries await!") % [cnt.y, gacha_region], 22))
	tx.add_child(_label(L.t("You have %d of %d") % [cnt.x, cnt.y], 20, Color("#f2e9d8")))
	banner.add_mon(int(bd["legs"][0]), 3.2, 0.0, 0.36)
	banner.add_mon(int(bd["star"]), 3.2, 0.34, 0.66)
	banner.add_mon(int(bd["legs"][1]), 3.2, 0.64, 1.0)
	# --- botones de tirada
	var brow := VBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	left.add_child(brow)
	var b1 := _cost_btn(L.t("Pull ×1"), "1", "", "ticket", func(): _do_pull(1, "t1"), Vector2(0, 44), SV.can_pull(1, "t1"), false, true)
	var b10 := _cost_btn(L.t("Pull ×10"), "10", "", "ticket", func(): _do_pull(10, "t1"), Vector2(0, 44), SV.can_pull(10, "t1"), false, true)
	var bt := _cost_btn(L.t("Purple ×10 pull"), "1", "", "ticket10", func(): _do_pull(10, "t10"), Vector2(0, 44), SV.can_pull(10, "t10"), false, true)
	for b in [b1, b10, bt]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		brow.add_child(b)
	var pity: int = int(SV.d["pity"].get(str(gacha_region), 0))
	var pcard := PanelContainer.new()
	pcard.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	left.add_child(pcard)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pcard.add_child(pv)
	pv.add_child(_label(L.t("Pulls without a legendary in %s: %d / %d") % [L.t(SV.REGIONS[gacha_region - 1]), pity, SV.PITY_5], 18, UIS.TEXT))
	var pbar := ProgressBar.new()
	pbar.min_value = 0
	pbar.max_value = SV.PITY_5
	pbar.value = pity
	pbar.show_percentage = false
	pbar.custom_minimum_size = Vector2(0, 18)
	pbar.add_theme_stylebox_override("fill", _sb(UIS.GOLD, Color.TRANSPARENT, 0))
	pv.add_child(pbar)
	if first == null:
		first = b1
	# --- panel de probabilidades
	var pool: Array = SV.region_pool(gacha_region)
	var counts: Array = [0, 0, 0, 0, 0]
	for p in pool:
		counts[clampi(int(p["rarity"]) - 1, 0, 4)] += 1
	var op := PanelContainer.new()
	op.custom_minimum_size = Vector2(300, 0)
	op.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	main.add_child(op)
	var osc := ScrollContainer.new()   # the odds card scrolls on its own, so reading the rules never moves the banner
	osc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	osc.follow_focus = true
	op.add_child(osc)
	var ov := VBoxContainer.new()
	ov.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ov.add_theme_constant_override("separation", 5)
	osc.add_child(ov)
	ov.add_child(_label("Odds", 26, UIS.WAVE))
	for j in range(4, -1, -1):
		var rr := HBoxContainer.new()
		rr.add_theme_constant_override("separation", 8)
		rr.add_child(IC.rect(String(RARITY_BALL[j]), 24))
		var rn := _label(SV.RARITY_NAME[j], 20, Color.html(String(RARITY_COL[j])))
		rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rn.autowrap_mode = TextServer.AUTOWRAP_OFF
		rr.add_child(rn)
		var pc := _label("%s%% · %d" % [str(SV.PULL_RATES[j]), int(counts[j])], 20, Color("#fff7d6"))
		pc.autowrap_mode = TextServer.AUTOWRAP_OFF
		rr.add_child(pc)
		ov.add_child(rr)
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 8)
	sr.add_child(IC.rect("shiny", 24))
	var sn := _label("Shiny", 20)
	sn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sr.add_child(sn)
	var s32 := _label("1%", 20, Color("#fff7d6"))
	s32.autowrap_mode = TextServer.AUTOWRAP_OFF
	sr.add_child(s32)
	ov.add_child(sr)
	# Cristales Z: probabilidad y cuales ya tienes (los desbloqueados brillan, el resto se ve apagado)
	var zr := HBoxContainer.new()
	zr.add_theme_constant_override("separation", 8)
	zr.add_child(IC.rect("zc:" + String(ZM.ORDER[0]), 24))
	var zn := _label("Z-Crystal", 20, Color("#7fe0ff"))
	zn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zn.autowrap_mode = TextServer.AUTOWRAP_OFF
	zr.add_child(zn)
	var zp := _label("%d%% · ×10" % roundi(SV.Z_CRYSTAL_P * 100.0), 20, Color("#fff7d6"))
	zp.autowrap_mode = TextServer.AUTOWRAP_OFF
	zr.add_child(zp)
	ov.add_child(zr)
	var zg := GridContainer.new()
	zg.columns = 9
	zg.add_theme_constant_override("h_separation", 2)
	zg.add_theme_constant_override("v_separation", 2)
	for zt in ZM.ORDER:
		var zi = IC.rect("zc:" + String(zt), 32)
		if not ZM.unlocked(String(zt), SV.d["stats"]):
			zi.modulate = Color(0.35, 0.35, 0.4, 0.45)
		zg.add_child(zi)
	ov.add_child(zg)
	var rules := VBoxContainer.new()
	rules.add_theme_constant_override("separation", 5)
	rules.visible = false
	var qb := _btn("? " + L.t("Rules"), func(): rules.visible = not rules.visible, Vector2(0, 40))
	ov.add_child(qb)
	ov.add_child(rules)
	rules.add_child(_label(L.t("· The ×10 pull guarantees at least one very rare Pokémon."), 16, Color("#f2e9d8")))
	rules.add_child(_label(L.t("· Purple ×10 ticket: the last pull has a %d%% chance to be legendary (otherwise Very Rare or better) and the Z-Crystal chance rises to %d%%.") % [roundi(SV.PURPLE_LEGEND_P * 100.0), roundi(SV.Z_CRYSTAL_P_PURPLE * 100.0)], 16, Color("#d9a8ff")))
	rules.add_child(_label(L.t("· After %d pulls without a legendary on a banner, the next one is.") % SV.PITY_5, 16, Color("#f2e9d8")))
	rules.add_child(_label(L.t("· Duplicates give PokéCoins. Shinies don't repeat."), 16, Color("#f2e9d8")))
	rules.add_child(_label(L.t("· Tickets are earned by playing: some Pokémon drop them when they fall, and bosses and chests sometimes give ×10 tickets."), 16, Color("#f2e9d8")))
	focus_first = first


func _nw(parent: Node, l: Label) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(l)


func _do_pull(n: int, use: String) -> void:
	if not SV.can_pull(n, use):
		toast(L.t("Not enough tickets: earn them by playing"))
		return
	var results: Array = SV.pull(gacha_region, n, use)
	SV.save()
	_update_top()
	_play_slots(results)


# Tragaperras animada (como el original); al terminar muestra la lista de premios.
func _play_slots(results: Array) -> void:
	if slots_ui == null or not is_instance_valid(slots_ui):
		slots_ui = SLOTS.new()
		slots_ui.z_index = 31
		slots_ui.visible = false
		add_child(slots_ui)
	slots_busy = true
	slots_ui.play(results)
	await slots_ui.finished
	slots_busy = false
	slots_ui.visible = false
	var best := 1
	var anyshiny := false
	for r in results:
		best = maxi(best, clampi(int(r.get("rarity", 1)), 1, 5))
		anyshiny = anyshiny or bool(r["shiny"])
	Aud.sfx("burst%d" % best)
	if anyshiny:
		Aud.sfx("shinyGet")
	_show_pulls(results)


func _show_pulls(results: Array) -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_label("Result!", 32, C_GOLD))
	var grid := GridContainer.new()
	grid.columns = 5 if results.size() > 1 else 1
	v.add_child(grid)
	for r in results:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(150, 0)
		grid.add_child(cell)
		var pv := Preview.new()
		pv.custom_minimum_size = Vector2(150, 110)
		cell.add_child(pv)
		pv.setup(int(r["dex"]), bool(r["shiny"]), 3.0)
		var nm := _label(L.t(String(r["name"])) + (" ✨" if bool(r["shiny"]) else ""), 18)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(nm)
		if bool(r["new"]) or int(r["refund"]) <= 0:
			var tag := "NEW!" if bool(r["new"]) else "Shiny"
			var tl := _label(tag, 16, Color("#6fd08a") if bool(r["new"]) else Color("#ffd65c"))
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(tl)
		else:
			var rf := _icon_label("coin", "+%d" % int(r["refund"]), 16, Color("#ffd65c"), 24.0)
			rf.alignment = BoxContainer.ALIGNMENT_CENTER
			cell.add_child(rf)
		var rar: int = clampi(int(r["rarity"]), 1, 5)
		var rl := _icon_label(String(["ball", "ball2", "ball3", "ball4", "ballLux"][rar - 1]), SV.RARITY_NAME[rar - 1], 14, Color("#b4aed6"), 24.0)
		rl.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(rl)
	if SV.last_crystal != "":
		var zc: String = SV.last_crystal
		var zrow := _icon_label("zc:" + zc, L.t("Z-Crystal found! You unlock: %s") % L.t(String(ZM.DEF[zc]["name"])), 20, Color("#ffd65c"), 40.0)
		zrow.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(zrow)
		Aud.sfx("legend")
	var ok := _btn_close("Accept", func(): gacha_result.visible = false; _refresh_gacha(), Vector2(0, 54))
	v.add_child(ok)
	gacha_result.visible = true
	_gf(ok)


# ---------------------------------------------------------------
# Misiones, logros y titulos (progress.gd)
# ---------------------------------------------------------------
var ach_cat := "coleccion"
var goals_btn: Button
var goals_tabs: VBoxContainer


var prof_box: VBoxContainer


func _build_profile() -> void:
	var s: Control = _screen("profile")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)
	prof_box = VBoxContainer.new()
	prof_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prof_box.add_theme_constant_override("separation", 8)
	sc.add_child(prof_box)


func _refresh_profile() -> void:
	PG.ensure()
	_clear(prof_box)
	call_deferred("_touch_pass", prof_box)
	var first: Button = _goals_profile()
	tab_row = null
	focus_first = first
	_update_top()


func _build_goals() -> void:
	var s: Control = _screen("goals")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	s.add_child(row)
	# left rail with the tabs (same layout as Settings)
	var rail := PanelContainer.new()
	rail.custom_minimum_size = Vector2(250, 0)
	row.add_child(rail)
	goals_tabs = VBoxContainer.new()
	goals_tabs.add_theme_constant_override("separation", 6)
	rail.add_child(goals_tabs)
	for t in [["m", "Missions", "flag"], ["a", "Achievements", "medal1"], ["h", "Medals", "trophy"], ["z", "Z-Crystals", "zc:ice"], ["p", "Profile", "crown"], ["r", "Records", "book"]]:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): goals_tab = k; _refresh_goals(); _gf(tab_sel), Vector2(0, 56))
		tb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tb.icon = IC.btn_tex(String(t[2]), 26)
		tb.expand_icon = false
		tb.add_theme_constant_override("icon_max_width", 30)
		tb.add_theme_constant_override("h_separation", 14)
		if k == "p":
			tb.visible = false
		goals_tabs.add_child(tb)
	# content area on its own panel so every tab stays readable over the map
	var cpanel := PanelContainer.new()
	cpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cbox := UIS.box(Color(UIS.BG, 0.92), UIS.EDGE, 3, false)
	cbox.set_content_margin_all(12)
	cpanel.add_theme_stylebox_override("panel", cbox)
	row.add_child(cpanel)
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cpanel.add_child(sc)
	goals_box = VBoxContainer.new()
	goals_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_theme_constant_override("separation", 14)
	sc.add_child(goals_box)


# ---------------------------------------------------------------
# Lexico: objetos, movimientos y estados alterados
# ---------------------------------------------------------------
var lex_tab := "m"
var lex_tabs: BoxContainer
var lex_box: VBoxContainer
const LEX_NEW := [
	["Legendary altar", "A large solid altar with stairs at the front. Climb them, stand in the central circle and wait for the \"Summoning\" bar to fill (4 s). If you step off, the bar pauses and drains only a little. It summons a Legendary Pokémon that attacks on its own with area lightning and has visible HP: it can't be healed and enemies touching it hurt it. Only one at a time.", "tex:altar"],
	["Manual aim", "Optional (Settings). Aim yourself with the gamepad right stick, the mouse or a second finger dragging on the right half of the screen. An arrow shows where you fire. If you don't aim, the game aims for you.", "tex:aim"],
	["Bigger traps", "Map traps are bigger and show the real area they affect. Each type (poison, sticky, ice, shock, sleep, confusion and fire) has its own animation while armed and when it goes off.", "tex:trap"],
	["Moves with unique patterns", "Every new move has its own attack pattern, not just another animation: zones, waves, traps, trails, dashes, bursts and more. Read each one's description in the Moves tab.", "tex:pat"],
	["Weapon slots", "New shop upgrade: you start with 4 move slots and can buy up to 2 more (max 6).", "cards"],
	["Items with cooldown", "Items with a cooldown (Sitrus Berry, Focus Sash, Weakness Policy...) appear in an on-screen box with their remaining time, or \"Ready\" when usable.", "clock"],
	["Progressive difficulty", "From minute 20 enemies gain more HP, damage and speed, and more elites appear. At 60 min the challenge is at its peak.", "r_berserk"],
	["Terrain bonus", "If you step on a liquid matching your type (water, lava, swamp, ice, poison or sparks), you gain +12% speed while on it.", "boot"],
	["Bond Moves", "Link at most 2 moves into a single slot and they fire together. If both are evolved and at max level, you're offered to fuse them into a much stronger Bond Move. The originals are lost for the rest of the run, but you can cancel and keep them. It takes a single slot.", "bond"],
	["Infatuation", "Fairy-type moves can infatuate an enemy for 20 s (26 s with Fairy Feather). An infatuated enemy fights on your side: it attacks other enemies and doesn't hurt you. Bosses are immune, and afterwards the enemy can't be infatuated again right away.", "heart"],
	["Run summary", "In the pause menu, the Summary button shows each move with its type, level, total damage, defeats and DPS over the last 20 s, plus your upgrades and items.", "book"],
	["Normal Run to Eternatus", "The Normal Run no longer ends at 30 min. 00:30 small wave; 01:00 first guaranteed Rift; 02:00 a fleeing Meowth with coins; 03:00 the first boss; 04:00 a single switch to the next map (once the boss falls). If a Rift or boss is active, the event waits its turn. After that, rare giant mini-bosses appear (Tyranitar, Wailord, Onix, Steelix). At 60:00 ETERNATUS awakens, the final boss: the fight goes on until it falls, you die or you quit. Other modes are unchanged.", "tex:eter"],
	["Lost items and parcels", "Small items appear around the map and are picked up by touching them: the Poké Ball Pouch (+3 Poké Balls), the Elixir (a random power-up for 25 s) and the Prism Crystal (stuns nearby enemies for 2.5 s: an emergency escape). If they are no use at that moment (Poké Balls full, a power-up already active, or no enemies nearby) they stay on the ground. Mystery parcels open with the action button (E, A on the gamepad or the golden on-screen button). They give gold, experience, healing, a consumable or, rarely, a ticket. They disappear over time.", "tex:pack"],
	["Paid and trap chests", "Poké Ball piggy-vaults cost run coins (each one you open costs more, and the ball type changes). Get close and press the action button: the price shows on the button. If you can't afford it, you aren't charged. Each vault gives a FREE UPGRADE (you level up and pick a card) or a Poké Ball; the pricier ones can give both. Other vaults are traps: some look suspicious (red eyes) and others are disguised as a normal vault (watch for a fang). If you open one, a small ambush appears, but you can run.", "tex:paid"],
	["Supply drops", "A notice announces a crate landing nearby. Reach it and press the action button before time runs out (30 s). There are four types: medical and resource (no extra enemies), rare and exceptional (they attract enemies, but you don't need to defeat them). Only one crate at a time.", "tex:crate"],
	["Kecleon, the merchant", "A colorful Kecleon visits the map for a short while (60-75 s). Get close and press the \"Trade\" action button: it offers 3 items from its catalog for run coins. You can buy only one per visit and reroll the offers once (the reroll price rises each time you use it). Each color sells different items; the shiny blue one is rare and sells the best. Only one Kecleon at a time.", "dex:352"],
	["Renewed Pokémon menu", "In Pokémon you see your partner in a portrait with arrows to go to the previous or next one, its type, its HP, Speed and Attack bars, its ability and its starting move. On the right: region tabs, “Mine only”, a search box (by name, type or number) and sorting (number, name, rarity or favorites). Tap a card's heart to mark a favorite; the star marks your partner. The same screen is used to pick your team, co-op partner and party Pokémon.", "ball"],
	["Pokémon rescues", "Now and then a wild Pokémon that needs help appears (no trainers). Injured: stay by its side for a few seconds. Threatened: defeat the 4 enemies attacking it. Lost: follow the arrow, find it and press the action button. If you succeed, it thanks you, gives you a reward (coins, EXP, ticket, healing or an item) and leaves; it never joins your team. If you are too late, it just leaves. Only one rescue at a time.", "tex:rescue"],
	["Poké Ball and Alphas", "Sometimes an Alpha prowls the area: a huge, reddish, very tough Pokémon. It is optional. If you defeat it, it is stunned for 8 seconds: press the action button to throw ONE Poké Ball at it (80% success). If it works, it joins you as an ally for the rest of the run (it slowly recovers and uses the same slot as the Legendary Altar ally). With manual aim on, the throw must be aimed at the Alpha; if you miss the shot, the ball is not spent. Poké Balls are rare: they sometimes come from chests, backpacks, supply crates and cutting grass. The number you carry is shown next to your coins.", "tex:ball"],
	["Capturing bosses and giants", "If you carry Poké Balls, when you defeat a regular boss (not Rift bosses) or a giant Pokémon (Snorlax, Tyranitar, Onix, Steelix, Gyarados, Metagross and more) it is left weakened for 8 seconds: press the action button to throw a Poké Ball at it (60% success on bosses, 75% on giants). If it works, it joins you as an ally. You can capture at most 2 allies per run, and they can fight at the same time.", "tex:ball"],
	["Wild legendaries", "After minute 30 of a Normal run, a huge, tough wild legendary occasionally appears. Defeat it for a special prize (coins, tickets and an item). It never appears during rifts, caves, invasions or with another boss, and stops appearing shortly before Eternatus.", "tex:wildleg"],
	["Rift return", "When you return to the world from a Rift or a den, a 3-2-1 countdown runs: run time and enemies pause and you are invulnerable until it ends.", "tex:return"],
	["Day and night", "Each run cycles through day, dusk, night and dawn (8-minute cycle). At night more Ghost, Dark and nocturnal Bug Pokémon appear; by day, more daytime Pokémon. Some secrets only reveal themselves at night.", "tex:daynight"],
	["Biome hazards", "Extreme biomes have hazards that are marked before they strike: eruptions and burns in volcanoes, slowing gusts on ice, lightning that can paralyze, and toxic bubbles. Pokémon of the matching type are immune. Only one warning at a time.", "tex:hazard"],
	["Caves and altars", "A cave of one type opens (14 types). Defeat the wave and step on the altar: your status effects of that type improve (burn, poison, slow, sleep, paralysis…), up to 3 levels. Normal, Flying, Rock and Steel have no cave yet.", "tex:cave"],
	["Invasions", "After a 5 s warning, an invasion (ghost, dark, electric, stampede, shiny, mixed, Alpha or night nightmare) lasts 45 s. Survive to win the prize; if you fall, no prize.", "tex:invasion"],
	["Meteorite and Deoxys", "A meteorite marks a zone: get away. It leaves loot and, with a 10% chance, Deoxys emerges. Defeat it before it escapes for a special prize.", "tex:meteor"],
	["Project Mewtwo", "After 13 minutes, 3 research stations can appear. Stay at each for a few seconds; once all are done, Mewtwo awakens, with telegraphed attacks. Once per run.", "tex:mewtwo"],
	["Secrets", "Hidden clearings, runes to step on in order, moon secrets revealed at night and secret nests. Each gives a modest prize only once.", "tex:secret"],
	["Elemental mechanisms", "Torches, fountains, generators and seals that only activate when hit by a move of the right type (not by getting close). They are optional.", "tex:mech"],
	["Medals", "New tab in Missions and Achievements: medals for exploring, rescuing, capturing Alphas and beating events. They are cosmetic.", "tex:medals"],
	["Faster Gachapon", "Tap the screen during the animation to speed it up, and go back without losing your prize.", "ticket"],
	["Fusions and Fusion Dex", "Combine two fully evolved moves with Bond to create a unique fused move (50 recipes). Every discovered recipe stays in the Fusion Dex forever.", "book"],
	["Automatic fusion", "When you bond two evolved, max-level moves they fuse on their own, with a big \"FUSION!\" banner. Every recipe has its own animated special attack: storms, vortexes, beams, prisons, eruptions and more.", "book"],
	["Player profile", "Tap your trainer name to open your profile: 3 favorite Pokémon, stats, type medals, a favorite type with its own background, cap, bag and interface theme.", "tex:medals"],
	["Kecleon leaves", "After your purchase, Kecleon disappears from the map (one purchase per visit). Its shop now uses the same style and font as the rest of the game, and all its items are in the Kecleon tab of the Lexicon.", "dex:352"],
	["Animated Evolutions", "Every evolved move gains its own ability the base move lacks: echoes, vortexes, detonating marks, freeze-and-shatter, meteors, lightning leaps, spinning beams, leech links and more. It triggers by itself when attacking (with its own cooldown) and has a unique animation. Roost and Milk Drink can now evolve too.", "move:inferno_tempest"],
	["Fusion Moves", "If you bond two evolved moves and raise them to max level, they fuse by themselves into a Fusion Move, with the «FUSION!» banner and an epic sound. You can only have ONE per run: it replaces the two original moves, which will no longer show up in upgrades. It takes a single slot, is stronger than any evolved move and casts both attacks at once, plus a unique special attack with its own animation every few seconds (there are 50 recipes). It can no longer be upgraded. Every discovered recipe is saved in the Fusion Dex.", "move:inferno_tempest"],
	["Wide screens", "The game adapts to 16:9 and 16:10 screens (like the Odin 3 Max): the field of view widens instead of cropping, and buttons stay inside the screen.", "cards"],
	["Text size", "In Settings you can change the text size (Normal to Very large) to read better on small screens.", "cards"],
]
const LEX_STATUS := [
	["freeze", "Frozen", "The enemy can't move or attack and takes 25% more damage. Bosses resist it."],
	["para", "Paralyzed", "The enemy moves much slower and takes more Electric damage. Bosses resist it."],
	["sleep", "Asleep", "The enemy doesn't act, takes 30% more damage and wakes up on the first hit. Darkrai is immune."],
	["conf", "Confused", "The enemy wanders aimlessly and attacks other enemies. Bosses resist it."],
	["burn", "Burned", "Damage over time, and the enemy deals less damage."],
	["poison", "Poisoned", "Damage over time based on its max HP (less against bosses)."],
	["slow", "Slowed", "The enemy moves slower for a while."],
	["charm", "Infatuation", "The enemy fights on your side for 20 s: it attacks other enemies and does not hurt you. Bosses are immune and, when it ends, it can't be charmed again right away."],
]


const AB_TYPE := {
	"blaze": "fire", "overgrow": "grass", "torrent": "water", "swarm": "bug", "intimidate": "dark", "levitate": "flying", "static": "electric",
	"flamebody": "fire", "poisonpoint": "poison", "cutecharm": "fairy", "effectspore": "grass", "roughskin": "rock", "thickfat": "ice",
	"waterabsorb": "water", "voltabsorb": "electric", "flashfire": "fire", "sapsipper": "grass", "hugepower": "fighting", "sturdy": "rock",
	"regenerator": "psychic", "speedboost": "fire", "swiftswim": "water", "chlorophyll": "grass", "sandrush": "ground", "slushrush": "ice",
	"sandveil": "ground", "technician": "bug", "ironfist": "fighting", "megalauncher": "water", "adaptability": "normal", "compoundeyes": "bug",
	"luck": "normal", "pickup": "normal", "magnetpull": "steel", "earlybird": "flying", "runaway": "normal", "innerfocus": "fighting",
	"limber": "fighting", "battlearmor": "bug", "solidrock": "rock", "multiscale": "dragon", "furcoat": "normal", "guts": "fighting",
	"moxie": "dark", "prankster": "dark", "tintedlens": "bug", "defiant": "dark", "moldbreaker": "dragon", "wonderguard": "ghost",
	"drought": "fire", "drizzle": "water", "snowwarning": "ice", "sandstream": "rock", "poisonheal": "poison", "rockhead": "rock",
	"pressure": "psychic", "sheerforce": "fighting", "strongjaw": "dark", "steelworker": "steel", "transistor": "electric",
	"dragonsmaw": "dragon", "waterbubble": "water", "lightningrod": "electric", "motordrive": "electric", "dryskin": "water",
	"heatproof": "fire", "purifyingsalt": "ghost", "galewings": "flying", "pixilate": "fairy", "aerilate": "flying", "refrigerate": "ice",
	"protean": "normal",
}


const LEX_CATS := [
	["m", "Moves", "move:flamethrower"],
	["f", "Fusion Dex", "move:inferno_tempest"],
	["i", "Items", "leftovers"],
	["s", "Status", "star"],
	["a", "Abilities", "sprout"],
	["z", "Z-Moves & Dynamax", "zc:fire"],
	["k", "Kecleon", "dex:352"],
	["n", "What's new", "book"],
]
var lex_title: Label
var lex_count: Label
var lex_chips: HFlowContainer
var lex_search: LineEdit
var lex_det: VBoxContainer
var lex_filter := "all"
var lex_entries: Array = []


func _build_lexicon() -> void:
	var s: Control = _screen("lexicon")
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	s.add_child(hb)
	# columna izquierda: categorias
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	lp.custom_minimum_size = Vector2(250, 0)
	hb.add_child(lp)
	lex_tabs = VBoxContainer.new()
	lex_tabs.add_theme_constant_override("separation", 6)
	lp.add_child(lex_tabs)
	for t in LEX_CATS:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): lex_tab = k; lex_filter = "all"; lex_search.text = ""; _refresh_lexicon(); _gf(tab_sel), Vector2(0, 54))
		tb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tb.icon = _lex_tex(String(t[2]), 32)
		tb.expand_icon = true
		tb.add_theme_constant_override("icon_max_width", 34)
		tb.add_theme_constant_override("h_separation", 12)
		tb.add_theme_font_size_override("font_size", 22)
		lex_tabs.add_child(tb)
	# centro: cabecera, filtros, busqueda y rejilla
	var cp := PanelContainer.new()
	cp.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(cp)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	cp.add_child(cv)
	var hh := HBoxContainer.new()
	cv.add_child(hh)
	lex_title = _label("Moves", 34, UIS.WAVE)
	lex_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lex_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	hh.add_child(lex_title)
	lex_count = _label("", 22, Color("#b4aed6"))
	lex_count.autowrap_mode = TextServer.AUTOWRAP_OFF
	hh.add_child(lex_count)
	lex_chips = HFlowContainer.new()
	lex_chips.add_theme_constant_override("h_separation", 6)
	lex_chips.add_theme_constant_override("v_separation", 6)
	cv.add_child(lex_chips)
	lex_search = LineEdit.new()
	lex_search.placeholder_text = L.t("Search...")
	lex_search.custom_minimum_size = Vector2(0, 40)
	lex_search.add_theme_font_size_override("font_size", 20)
	lex_search.text_changed.connect(func(_t: String): _lex_render())
	cv.add_child(lex_search)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cv.add_child(sc)
	lex_box = VBoxContainer.new()
	lex_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lex_box.add_theme_constant_override("separation", 8)
	sc.add_child(lex_box)
	# derecha: detalle
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	dp.custom_minimum_size = Vector2(340, 0)
	hb.add_child(dp)
	var dsc := ScrollContainer.new()
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dsc)
	lex_det = VBoxContainer.new()
	lex_det.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lex_det.add_theme_constant_override("separation", 8)
	dsc.add_child(lex_det)


# Icono (Texture2D) de una entrada: "tex:x" = imagen del Lexico; otro valor = icono pixel art de icons.gd.
var _dex_crop_cache := {}


# Primer fotograma del Pokemon recortado al contenido (el cuadro original tiene mucho margen transparente).
func _dex_cropped(dex: int) -> Texture2D:
	if _dex_crop_cache.has(dex):
		return _dex_crop_cache[dex]
	var t: Texture2D = _icon_tex(dex, false)
	var out: Texture2D = t
	if t is AtlasTexture and (t as AtlasTexture).atlas != null:
		var at: AtlasTexture = t as AtlasTexture
		var img: Image = at.atlas.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var sub: Image = img.get_region(Rect2i(at.region))
			var ur: Rect2i = sub.get_used_rect()
			if ur.size.x > 0 and ur.size.y > 0:
				out = ImageTexture.create_from_image(sub.get_region(ur))
	_dex_crop_cache[dex] = out
	return out


func _lex_tex(spec: String, size: float) -> Texture2D:
	if spec.begins_with("dex:"):
		return _dex_cropped(int(spec.substr(4)))   # sprite real del Pokemon
	if spec.begins_with("tex:"):
		var t: Texture2D = load("res://assets/world/lexn_%s.png" % spec.substr(4))
		return t
	return IC.btn_tex(spec, size)


func _lex_big(spec: String, size: float) -> Control:
	var tr := TextureRect.new()
	tr.texture = _lex_tex(spec, size)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(size, size)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _lex_e(k: String, name: String, icon: String, sub: String, col: Color, desc: String, dim: bool = false, stats: Array = [], evo: Array = [], ty: String = "") -> Dictionary:
	return {"k": k, "name": name, "icon": icon, "sub": sub, "col": col, "desc": desc, "dim": dim, "stats": stats, "evo": evo, "ty": ty}


func _lex_build(tab: String) -> Array:
	var out: Array = []
	var cat_cols: Color = Color("#8fa3c4")
	if tab == "m":
		for mid in MD.ORDER:
			if not MD.MOVES.has(mid):
				continue
			var m: Dictionary = MD.MOVES[mid]
			var ty: String = String(m["type"])
			var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#ffffff")))
			var st: Array = []
			if m.has("dmg"):
				st.append([L.t("Damage"), str(int(m["dmg"]))])
			if m.has("cd"):
				st.append([L.t("Cooldown"), "%.1f s" % float(m["cd"])])
			if m.has("count"):
				st.append([L.t("Projectiles"), str(int(m["count"]))])
			if m.has("radius"):
				st.append([L.t("Radius"), str(int(m["radius"]))])
			var evo: Array = []
			var desc: String = L.t(String(m["desc"]))
			if MD.EVO.has(mid):
				evo = [["move:" + String(mid), L.t(String(m["name"]))], ["evo:" + String(mid), L.t(String(MD.EVO[mid][0]))]]
			if MD.EVO_ALT.has(mid):
				if evo.is_empty():
					evo = [["move:" + String(mid), L.t(String(m["name"]))]]
				evo.append(["evo:" + String(mid), L.t(String(MD.EVO_ALT[mid][0]))])
			out.append(_lex_e("mv_" + String(mid), L.t(String(m["name"])), "move:" + String(mid), L.t(String(MD.TYPE_NAME[ty])), tcol, desc, false, st, evo, ty))
	elif tab == "f":
		var fnd: Array = SV.d.get("fusions", [])
		for fr in FUS.R:
			var fok: bool = fnd.has(fr[0])
			var fcol: Color = Color.html(String(fr[5]))
			if fok:
				out.append(_lex_e("fu_" + String(fr[0]), L.t(String(fr[1])), "move:" + String(fr[0]), L.t("Unlocked"), fcol, L.t(String(fr[4])), false, [],
					[["move:" + String(fr[2]), _fname(String(fr[2]))], ["move:" + String(fr[3]), _fname(String(fr[3]))], ["move:" + String(fr[0]), L.t(String(fr[1]))]]))
			else:
				out.append(_lex_e("fu_" + String(fr[0]), "???", "", L.t("Locked"), cat_cols, L.t("Fuse two evolved moves to discover this recipe."), true))
	elif tab == "i":
		var found: Dictionary = SV.d.get("itemsFound", {})
		for it in TD.ITEMS:
			var id: String = String(it["id"])
			var ok: bool = found.has(id)
			out.append(_lex_e("it_" + id, L.t(String(it["name"])), id, L.t("✔ Found") if ok else L.t("Not found yet"), Color("#6fd08a") if ok else cat_cols, L.t(String(it["desc"])), not ok))
		for ie in INF_UP:
			var rows: Array = []
			for lv in [1, 2, 5, 10, 25, 50]:
				rows.append(L.t("Lv. %d: %s") % [lv, _inf_fx(String(ie[0]), lv)])
			rows.append(L.t("Cap: %s") % _inf_fx(String(ie[0]), 100000))
			out.append(_lex_e("up_" + String(ie[0]), L.t(String(ie[1])), String(ie[2]), L.t("No maximum level"), Color("#6fd08a"), L.t(String(INF_DESC.get(String(ie[0]), ""))) + "\n\n" + "\n".join(rows)))
	elif tab == "s":
		var sic := {"freeze": "type:ice", "para": "type:electric", "sleep": "type:psychic", "conf": "type:ghost", "burn": "type:fire", "poison": "type:poison", "slow": "type:water", "charm": "st:charm"}
		for st2 in LEX_STATUS:
			out.append(_lex_e("st_" + String(st2[0]), L.t(String(st2[1])), String(sic.get(String(st2[0]), "star")), "", Color.WHITE, L.t(String(st2[2]))))
	elif tab == "a":
		for aid in AB.FX:
			var ad: Dictionary = AB.FX[aid]
			var aty: String = String(AB_TYPE.get(String(aid), "normal"))
			var acol: Color = Color.html(String(MD.TYPE_COLOR.get(aty, "#b0a99f")))
			out.append(_lex_e("ab_" + String(aid), L.t(String(ad["name"])), "type:" + aty, L.t(String(MD.TYPE_NAME[aty])), acol, L.t(String(ad["desc"])), false, [], [], aty))
	elif tab == "z":
		var dn: int = int(SV.d["stats"].get("dens", 0))
		var dok: bool = dn >= 1
		out.append(_lex_e("dyn", "Dynamax", "type:dragon", L.t("Unlocked") if dok else L.t("Clear a Dynamax den: %d/1") % dn, Color("#ff7a9a"),
			L.t("Every 4 minutes (from minute 3): your Pokémon turns giant for %d s with +30%% to all its stats and fires Max waves of its type. Each Dynamax den you defeat recharges it instantly.") % [int(DYN.DUR)], not dok))
		for zt in ZM.ORDER:
			var zd: Dictionary = ZM.DEF[zt]
			var zn: int = int(SV.d["stats"].get("tk_" + zt, 0))
			var zok: bool = ZM.unlocked(zt, SV.d["stats"])
			var zcol: Color = Color.html(String(MD.TYPE_COLOR.get(zt, "#ffffff")))
			var zsub: String = L.t(String(MD.TYPE_NAME[zt])) + " · " + (L.t("Unlocked") if zok else L.t("Defeat %d %s-type Pokémon: %d/%d") % [ZM.NEED, L.t(String(MD.TYPE_NAME[zt])), zn, ZM.NEED])
			out.append(_lex_e("z_" + String(zt), L.t(String(zd["name"])), "zc:" + String(zt), zsub, zcol, L.t(String(zd["desc"])), not zok))
	elif tab == "k":
		for kv in KCX.ORDER:
			var kvc: Color = Color.html(String(KCX.VAR[kv]["col"]))
			for kid in KCX.CAT[kv]:
				if not KCX.ITEMS.has(kid):
					continue
				var kit: Array = KCX.ITEMS[kid]
				out.append(_lex_e("kc_" + String(kid), L.t(String(kit[0])), "kec:" + String(kid), L.t(String(KCX.VAR[kv]["name"])), kvc, L.t(String(kit[3])), false,
					[[L.t("Price"), str(int(kit[1]))], [L.t("Max"), str(int(kit[2]))]]))
	else:
		for nw in LEX_NEW:
			var ns: String = String(nw[2])
			out.append(_lex_e("nw_" + String(nw[0]), L.t(String(nw[0])), ns, "", Color.WHITE, L.t(String(nw[1]))))
	return out


func _refresh_lexicon() -> void:
	var tbs: Array = lex_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = String(LEX_CATS[i][0])
		_gold_btn(tbs[i], key == lex_tab)
		if key != lex_tab:
			for stn in ["normal", "hover", "pressed"]:
				(tbs[i] as Button).add_theme_stylebox_override(stn, _sb(Color("#3a3262") if stn == "normal" else Color("#5a5099"), Color("#9fb4ff"), 2, 12))
		if key == lex_tab:
			tab_sel = tbs[i]
			lex_title.text = L.t(String(LEX_CATS[i][1]))
	tab_row = lex_tabs
	lex_entries = _lex_build(lex_tab)
	# filtros por tipo (solo movimientos)
	_clear(lex_chips)
	lex_chips.visible = lex_tab == "m" or lex_tab == "a"
	if lex_tab == "m" or lex_tab == "a":
		var allb := _btn("All", func(): lex_filter = "all"; _lex_chips_hl(); _lex_render(), Vector2(54, 32))
		allb.add_theme_font_size_override("font_size", 15)
		allb.set_meta("ty", "all")
		lex_chips.add_child(allb)
		for ty in TYPE_IDS:
			var tyk: String = String(ty)
			var cb := Button.new()
			cb.icon = IC.btn_tex("type:" + tyk, 24)
			cb.custom_minimum_size = Vector2(38, 32)
			cb.tooltip_text = L.t(String(MD.TYPE_NAME[tyk]))
			cb.focus_mode = Control.FOCUS_ALL
			cb.add_theme_stylebox_override("normal", _sb(Color("#141028"), Color.html(String(MD.TYPE_COLOR[tyk])), 2, 8))
			cb.add_theme_stylebox_override("hover", _sb(Color("#5a5099"), Color.WHITE, 2, 8))
			cb.add_theme_stylebox_override("focus", _sb(Color("#5a5099"), C_GOLD, 3, 8))
			for stn in ["normal", "hover", "focus"]:
				var csb := cb.get_theme_stylebox(stn) as StyleBoxFlat
				if csb != null:
					csb.content_margin_left = 3
					csb.content_margin_right = 3
			cb.set_meta("ty", tyk)
			cb.pressed.connect(func(): lex_filter = tyk; _lex_chips_hl(); _lex_render())
			lex_chips.add_child(cb)
		_lex_chips_hl()
	_lex_render()
	focus_first = tab_sel
	_update_top()


func _lex_chips_hl() -> void:
	for c in lex_chips.get_children():
		var on: bool = String(c.get_meta("ty", "")) == lex_filter
		c.modulate = Color.WHITE if on else Color(1.0, 1.0, 1.0, 0.85)
		if c is Button and String(c.get_meta("ty", "")) != "all":
			var tcl: Color = Color.html(String(MD.TYPE_COLOR[String(c.get_meta("ty", ""))]))
			var hsb: StyleBoxFlat = _sb(Color("#141028").lerp(tcl, 0.35) if on else Color("#141028"), C_GOLD if on else tcl, 3 if on else 2, 8)
			hsb.content_margin_left = 3
			hsb.content_margin_right = 3
			(c as Button).add_theme_stylebox_override("normal", hsb)


func _lex_render() -> void:
	_clear(lex_box)
	var q: String = lex_search.text.strip_edges().to_lower()
	var shown: Array = []
	for e in lex_entries:
		if (lex_tab == "m" or lex_tab == "a") and lex_filter != "all" and String(e["ty"]) != lex_filter:
			continue
		if q != "" and String(e["name"]).to_lower().find(q) < 0:
			continue
		shown.append(e)
	var tot := 0
	var got := 0
	for e2 in lex_entries:
		tot += 1
		if not bool(e2["dim"]):
			got += 1
	lex_count.text = ("%d / %d" % [got, tot]) if (lex_tab == "i" or lex_tab == "f" or lex_tab == "z") else str(shown.size())
	if lex_tab == "n":
		# las novedades son texto largo: una lista, no una rejilla
		for e3 in shown:
			var bn := Button.new()
			bn.text = String(e3["name"])
			bn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bn.icon = _lex_tex(String(e3["icon"]), 40)
			bn.expand_icon = true
			bn.add_theme_constant_override("icon_max_width", 40)
			bn.add_theme_constant_override("h_separation", 12)
			bn.add_theme_font_size_override("font_size", 20)
			bn.custom_minimum_size = Vector2(0, 52)
			bn.focus_mode = Control.FOCUS_ALL
			bn.clip_text = true
			_lex_style_tile(bn)
			_lex_bind(bn, e3)
			lex_box.add_child(bn)
	else:
		var g := GridContainer.new()
		g.columns = 5
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 8)
		if lex_tab == "k":
			var lg := HFlowContainer.new()
			lg.add_theme_constant_override("h_separation", 10)
			lg.add_theme_constant_override("v_separation", 4)
			lg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lex_box.add_child(lg)
			var lgt := _label(L.t("Sold by:"), 15, Color("#b4aed6"))
			lgt.autowrap_mode = TextServer.AUTOWRAP_OFF
			lg.add_child(lgt)
			for kv2 in KCX.ORDER:
				var chip := PanelContainer.new()
				var kc2: Color = Color.html(String(KCX.VAR[kv2]["col"]))
				var cst := _sb(Color("#141028").lerp(kc2, 0.3), kc2, 2, 8)
				cst.set_content_margin_all(4)
				chip.add_theme_stylebox_override("panel", cst)
				var cl := _label(L.t(String(KCX.VAR[kv2]["name"])), 14, Color.WHITE)
				cl.autowrap_mode = TextServer.AUTOWRAP_OFF
				chip.add_child(cl)
				lg.add_child(chip)
		lex_box.add_child(g)
		for e4 in shown:
			var b := Button.new()
			b.text = String(e4["name"])
			b.custom_minimum_size = Vector2(108, 96)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_ALL
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var longest := 0
			for wd in String(e4["name"]).split(" "):
				longest = maxi(longest, wd.length())
			# las palabras largas ("Flamethrower") se achican en vez de partirse a mitad
			b.add_theme_font_size_override("font_size", 13 if longest <= 8 else (12 if longest <= 9 else (11 if longest <= 10 else 10)))
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			if String(e4["icon"]) != "":
				b.icon = _lex_tex(String(e4["icon"]), 44)
				b.expand_icon = true
				b.add_theme_constant_override("icon_max_width", 44)
			else:
				b.text = "?\n" + String(e4["name"])
			if bool(e4["dim"]):
				b.modulate = Color(0.62, 0.66, 0.78, 0.85)
			_lex_style_tile(b, e4["col"] if lex_tab == "k" else Color.TRANSPARENT)
			_lex_bind(b, e4)
			g.add_child(b)
	call_deferred("_touch_pass", lex_box)
	if shown.size() > 0:
		_lex_show(shown[0])
	else:
		_clear(lex_det)


func _lex_style_tile(b: Button, edge: Color = Color.TRANSPARENT) -> void:
	if edge.a > 0.0:
		# Kecleon: el borde y el fondo llevan el color de la variante que vende el objeto
		var bg: Color = Color("#141028").lerp(edge, 0.22)
		b.add_theme_stylebox_override("normal", _sb(bg, edge, 4, 8))
		b.add_theme_stylebox_override("hover", _sb(bg.lightened(0.15), Color.WHITE, 3, 8))
		b.add_theme_stylebox_override("pressed", _sb(bg.lightened(0.15), Color.WHITE, 3, 8))
		b.add_theme_stylebox_override("focus", _sb(bg.lightened(0.1), C_GOLD, 5, 8))
		return
	b.add_theme_stylebox_override("normal", _sb(Color("#141028"), Color("#5a5099"), 2, 8))
	b.add_theme_stylebox_override("hover", _sb(Color("#5a5099"), Color.WHITE, 2, 8))
	b.add_theme_stylebox_override("pressed", _sb(Color("#5a5099"), Color.WHITE, 2, 8))
	b.add_theme_stylebox_override("focus", _sb(Color("#3a3262"), C_GOLD, 4, 8))


func _lex_bind(b: Button, e: Dictionary) -> void:
	b.focus_entered.connect(func(): _lex_show(e))
	b.mouse_entered.connect(func(): _lex_show(e))
	b.pressed.connect(func(): _lex_show(e))


func _lex_show(e: Dictionary) -> void:
	_clear(lex_det)
	lex_det.add_child(_label(String(e["name"]), 26, C_GOLD))
	if String(e["sub"]) != "":
		var sl := _label(String(e["sub"]), 17, e["col"])
		lex_det.add_child(sl)
	if String(e["icon"]) != "":
		var ic := _lex_big(String(e["icon"]), 96)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lex_det.add_child(ic)
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", _sb(Color("#141028"), Color("#5a5099"), 2, 8))
	var dl := _label(String(e["desc"]), 16, Color("#dbe6ff"))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dp.add_child(dl)
	lex_det.add_child(dp)
	var stats: Array = e["stats"]
	if not stats.is_empty():
		var gs := GridContainer.new()
		gs.columns = 2
		gs.add_theme_constant_override("h_separation", 6)
		gs.add_theme_constant_override("v_separation", 6)
		for sv in stats:
			var pc := PanelContainer.new()
			pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pc.add_theme_stylebox_override("panel", _sb(Color("#141028"), Color("#5a5099"), 2, 8))
			var vb := VBoxContainer.new()
			vb.add_theme_constant_override("separation", 0)
			pc.add_child(vb)
			vb.add_child(_label(String(sv[0]), 13, Color("#b4aed6")))
			vb.add_child(_label(String(sv[1]), 20, Color.WHITE))
			gs.add_child(pc)
		lex_det.add_child(gs)
	var evo: Array = e["evo"]
	if not evo.is_empty():
		lex_det.add_child(_label(L.t("Evolution") if lex_tab == "m" else L.t("Recipe"), 20, C_GOLD))
		var hr := HBoxContainer.new()
		hr.add_theme_constant_override("separation", 4)
		hr.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in range(evo.size()):
			if i > 0:
				var ar := _label("→" if lex_tab == "m" else ("=" if i == evo.size() - 1 else "+"), 24, C_GOLD)
				ar.autowrap_mode = TextServer.AUTOWRAP_OFF
				hr.add_child(ar)
			var vb2 := VBoxContainer.new()
			vb2.custom_minimum_size = Vector2(88, 0)
			var ib := _lex_big(String(evo[i][0]), 48)
			ib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vb2.add_child(ib)
			var nl := _label(String(evo[i][1]), 13, Color("#f2e9d8"))
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vb2.add_child(nl)
			hr.add_child(vb2)
		lex_det.add_child(hr)


func _lex_card(icon: Control, title: String, sub: String, sub_col: Color, desc: String, dim: bool = false) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_sb())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	if icon != null:
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)
	var tl := _label(title, 22, Color.WHITE if not dim else Color("#8fa3c4"))
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(tl)
	if sub != "":
		var sl := _label(sub, 15, sub_col)
		sl.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(sl)
	var dl := _label(desc, 16, Color("#f2e9d8"))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(dl)
	return card


func _fname(id: String) -> String:
	return L.t(String(MD.MOVES[id]["name"])) if MD.MOVES.has(id) else id


func _lex_q() -> Control:
	var q := _label("?", 36, Color("#5a5099"))
	q.custom_minimum_size = Vector2(48, 48)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return q


func _lex_grid(cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	lex_box.add_child(g)
	return g


const INF_DESC := {
	"mult": "+1 projectile on shot, cone and boomerang moves (each level gives less).",
	"pierce": "+1 pierce on shots, cones and waves (each level gives less).",
	"amp": "+12% chance and duration of statuses: paralysis, freeze, confusion, burn and poison.",
	"lens": "+3% critical chance (3 levels: +9%; then diminishing, cap 30%).",
	"fang": "Recover 4% of the damage you deal (3 levels: 12%; then diminishing, cap 25%).",
	"edge": "+12% critical damage (each level gives less, cap x3).",
	"dstrike": "+6% chance to hit twice (diminishing, cap 45%).",
	"trs": "+8% Pokémon coins at the end of the run (each level gives less).",
}
const INF_UP := [["mult", "Multiplier", "cards"], ["pierce", "Piercing Force", "quickclaw"], ["amp", "Amplifier", "star"], ["lens", "Precision Lens", "scopelens"], ["fang", "Vampiric Fang", "lifeorb"], ["edge", "Fatal Edge", "expertbelt"], ["dstrike", "Double Strike", "choiceband"], ["trs", "Treasure Magnet", "amuletcoin"]]


static func _dimf(lv: float, first: float, cap: float) -> float:
	if lv <= 0.0:
		return 0.0
	return cap * (1.0 - exp(-lv * first / cap))


func _inf_fx(id: String, lv: int) -> String:
	var l: float = float(lv)
	match id:
		"mult":
			return "+%d" % int(_dimf(l, 0.6, 5.0) + 0.5)
		"pierce":
			return "+%d" % int(_dimf(l, 0.7, 6.0) + 0.5)
		"amp":
			return "+%d%%" % int(roundf(_dimf(l, 0.12, 0.8) * 100.0))
		"lens":
			return "+%d%%" % int(roundf(3.0 * l if l <= 3.0 else 9.0 + _dimf(l - 3.0, 0.03, 0.21) * 100.0))
		"fang":
			return "%d%%" % int(roundf(4.0 * l if l <= 3.0 else 12.0 + _dimf(l - 3.0, 0.04, 0.13) * 100.0))
		"edge":
			return "x%.2f" % (1.5 + _dimf(l, 0.12, 1.5))
		"dstrike":
			return "%d%%" % int(roundf(_dimf(l, 0.06, 0.45) * 100.0))
		"trs":
			return "+%d%%" % int(roundf(_dimf(l, 0.08, 1.0) * 100.0))
	return ""


func _reward_box(r: Dictionary, w: float = 170.0) -> HBoxContainer:
	var rw := HBoxContainer.new()
	rw.custom_minimum_size = Vector2(w, 0)
	rw.add_theme_constant_override("separation", 6)
	if int(r.get("coins", 0)) > 0:
		rw.add_child(IC.rect("coin", 24))
		var l1 := _label("%d" % int(r["coins"]), 20, C_GOLD)
		l1.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l1)
	if int(r.get("t1", 0)) > 0:
		rw.add_child(IC.rect("ticket", 24))
		var l2 := _label("%d" % int(r["t1"]), 20, Color("#ffd65c"))
		l2.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l2)
	if int(r.get("t10", 0)) > 0:
		rw.add_child(IC.rect("ticket10", 24))
		var l3 := _label("%d ×10" % int(r["t10"]), 20, Color("#c47bff"))
		l3.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l3)
	return rw


func _refresh_goals() -> void:
	if cur == "profile":
		_refresh_profile()
		return
	PG.ensure()
	PG.check()
	_clear(goals_box)
	call_deferred("_touch_pass", goals_box)
	var first: Button = null
	var tbs: Array = goals_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = ["m", "a", "h", "z", "p", "r"][i]
		if key == goals_tab:
			for st in ["normal", "hover", "pressed"]:
				tbs[i].add_theme_stylebox_override(st, _sb(UIS.PANEL_HI, UIS.GOLD, 3, 0))
		else:
			for st in ["normal", "hover", "pressed"]:
				tbs[i].remove_theme_stylebox_override(st)
		if key == goals_tab:
			tab_sel = tbs[i]
	tab_row = goals_tabs
	if goals_tab == "m":
		first = _goals_missions()
	elif goals_tab == "a":
		first = _goals_ach()
	elif goals_tab == "h":
		first = _goals_medals()
	elif goals_tab == "z":
		first = _goals_zcrystals()
	elif goals_tab == "r":
		first = _goals_records()
	else:
		first = _goals_missions()
	focus_first = first if first != null else tbs[0]
	_update_top()


func _mission_row(m: Dictionary, weekly: bool, idx: int, parent: Node) -> Button:
	var def: Dictionary = PG.def_of(String(m["id"]))
	var done: bool = PG.m_done(m)
	var claimed: bool = bool(m["claimed"])
	var ready: bool = done and not claimed
	var pc := PanelContainer.new()
	var sbx := UIS.box(Color(UIS.INK, 0.45 if claimed else 0.75), UIS.GOLD if ready else UIS.EDGE, 3 if ready else 2, false)
	sbx.content_margin_left = 12
	sbx.content_margin_right = 12
	sbx.content_margin_top = 10
	sbx.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sbx)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	pc.add_child(row)
	var gic := IC.rect("flag", 32)
	gic.custom_minimum_size.x = 40
	gic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gic.modulate = Color(1, 1, 1, 0.5) if claimed else Color.WHITE
	row.add_child(gic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	col.add_child(_label(PG.mission_text(m), 20, UIS.MUTED if claimed else UIS.TEXT))
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 10)
	col.add_child(prow)
	var pb := ProgressBar.new()
	pb.max_value = float(m["goal"])
	pb.value = minf(float(m["prog"]), float(m["goal"]))
	pb.custom_minimum_size = Vector2(0, 14)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.show_percentage = false
	prow.add_child(pb)
	prow.add_child(_lnw("%d / %d" % [mini(int(m["prog"]), int(m["goal"])), int(m["goal"])], 16, UIS.MUTED))
	var rwb := _reward_box(def["reward"], 230.0)
	rwb.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(rwb)
	var out: Button = null
	var mm: Dictionary = m
	if not weekly and not done and not bool(SV.d["missions"].get("rerolled", false)):
		var rb := _btn("Swap", func(): _reroll(idx), Vector2(110, 44))
		row.add_child(rb)
		out = rb
	if claimed:
		var cl := _lnw(L.t("Claimed"), 18, UIS.GREEN)
		cl.custom_minimum_size.x = 110
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(cl)
	elif done:
		var b := _btn("Claim!", func(): _claim_mission(mm, weekly), Vector2(130, 44))
		_gold_btn(b, true)
		row.add_child(b)
		out = b
	return out


func _goals_missions() -> Button:
	var first: Button = null
	var M: Dictionary = SV.d["missions"]
	var dv := _pcard(goals_box, "Daily missions", UIS.WAVE)
	var i := 0
	for m in M["daily"]:
		var b: Button = _mission_row(m, false, i, dv)
		if first == null and b != null:
			first = b
		i += 1
	var wv := _pcard(goals_box, "Weekly missions", UIS.GOLD)
	for m in M["weekly"]:
		var b2: Button = _mission_row(m, true, 0, wv)
		if first == null and b2 != null:
			first = b2
	wv.add_child(_label("They reset at 00:00 (Puerto Rico time). You can swap one daily mission per day.", 16, UIS.MUTED))
	return first


func _reroll(i: int) -> void:
	if PG.reroll(i):
		Aud.sfx("confirm")
	_refresh_goals()


func _claim_mission(m: Dictionary, weekly: bool) -> void:
	if PG.claim(m, weekly):
		Aud.sfx("buy")
		toast(L.t("Reward claimed!"))
	_refresh_goals()


func _goals_medals() -> Button:
	const ACHM = preload("res://scripts/ach.gd")
	goals_box.add_child(_label(L.t("Medals: %d / %d") % [ACHM.count_got(), ACHM.LIST.size()], 28, C_GOLD))
	goals_box.add_child(_label(L.t("Type medals"), 22, Color("#d9cdb5")))
	goals_box.add_child(_label(L.t("Defeat %d Pokémon of a type to earn its medal.") % ZM.NEED, 16, Color("#f2e9d8")))
	var tg := GridContainer.new()
	tg.columns = 6
	tg.add_theme_constant_override("h_separation", 10)
	tg.add_theme_constant_override("v_separation", 10)
	goals_box.add_child(tg)
	for ty2 in TYPE_IDS:
		var tcard := VBoxContainer.new()
		tcard.add_child(_medal_icon(String(ty2), 84))
		var tl2 := _label("%d/%d" % [mini(int(SV.d["stats"].get("tk_" + String(ty2), 0)), ZM.NEED), ZM.NEED], 15, Color("#f2e9d8"))
		tl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl2.autowrap_mode = TextServer.AUTOWRAP_OFF
		tcard.add_child(tl2)
		tg.add_child(tcard)
	var first: Button = null
	for c in ACHM.CATS:
		goals_box.add_child(_label(L.t(String(c[1])), 22, Color("#d9cdb5")))
		for a in ACHM.LIST:
			if String(a[1]) != String(c[0]):
				continue
			var e: Dictionary = ACHM.entry(String(a[0]))
			var got: bool = bool(e["got"])
			var prog: int = mini(int(e["prog"]), int(a[4]))
			var txt: String = ("★ " if got else "☆ ") + L.t(String(a[2])) + "  (" + str(prog) + "/" + str(int(a[4])) + ")\n" + L.t(String(a[3]))
			var lb := _label(txt, 20, C_GOLD if got else Color(0.7, 0.7, 0.75))
			lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			goals_box.add_child(lb)
	return first


func _goals_ach() -> Button:
	var all: Array = PG.list()
	var ach: Dictionary = SV.d.get("ach", {})
	var total := 0
	for a in all:
		if ach.has(String(a["id"])):
			total += 1
	goals_box.add_child(_label(L.t("Achievements: %d / %d") % [total, all.size()], 28, C_GOLD))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	goals_box.add_child(chips)
	var first: Button = null
	for c in PG.CATS:
		var ck: String = String(c[0])
		var n := 0
		var d := 0
		for a in all:
			if String(a["cat"]) == ck:
				n += 1
				if ach.has(String(a["id"])):
					d += 1
		var cb := _btn("%s  %d/%d" % [L.t(String(c[1])), d, n], func(): ach_cat = ck; _refresh_goals(), Vector2(0, 44))
		_gold_btn(cb, ck == ach_cat)
		chips.add_child(cb)
		if first == null:
			first = cb
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for a in all:
		if String(a["cat"]) != ach_cat or int(a["dex"]) > 0:
			continue
		grid.add_child(_ach_card(a, ach.has(String(a["id"]))))
	if ach_cat == "legendaries":
		var legs: Array = []
		var beaten := 0
		for a in all:
			if int(a["dex"]) > 0:
				legs.append(a)
				if ach.has(String(a["id"])):
					beaten += 1
		goals_box.add_child(_label(L.t("Legendaries defeated %d / %d") % [beaten, legs.size()], 24, Color.WHITE))
		var lg := GridContainer.new()
		lg.columns = 10
		lg.add_theme_constant_override("h_separation", 6)
		lg.add_theme_constant_override("v_separation", 6)
		lg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		goals_box.add_child(lg)
		for a in legs:
			var ok: bool = ach.has(String(a["id"]))
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.25), Color(1.0, 0.82, 0.25, 0.5) if ok else Color.TRANSPARENT, 2, 8))
			var cv := VBoxContainer.new()
			cv.alignment = BoxContainer.ALIGNMENT_CENTER
			cell.add_child(cv)
			var tr := TextureRect.new()
			tr.texture = _icon_tex(int(a["dex"]), false)
			tr.custom_minimum_size = Vector2(0, 56)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if not ok:
				tr.modulate = Color(0.0, 0.0, 0.0, 0.55)
			cv.add_child(tr)
			var nl := _label(String(a["arg"]) if ok else "???", 12, Color("#d9cdb5"))
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(nl)
			lg.add_child(cell)
	return first


func _goals_zcrystals() -> Button:
	var zl: Array = PG.zlist()
	var nd := 0
	for zm in zl:
		if PG.zdone(zm):
			nd += 1
	goals_box.add_child(_label(L.t("Z-Crystals: %d / %d") % [nd, zl.size()], 28, C_GOLD))
	var hint := _label(L.t("Complete a type's mission to unlock its Z-Move. It also unlocks by defeating 250 Pokémon of that type or with a gacha crystal."), 16, Color("#d9cdb5"))
	goals_box.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for zm in zl:
		grid.add_child(_zmis_card(zm, PG.zdone(zm)))
	return null


func _zmis_card(zm: Dictionary, done: bool) -> PanelContainer:
	var t: String = String(zm["type"])
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.2), Color(1.0, 0.82, 0.25, 0.6) if done else Color(0.96, 0.97, 1.0, 0.1), 2, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var mi := IC.rect("zc:" + t, 48)
	mi.custom_minimum_size.x = 52
	if not done:
		mi.modulate = Color(0.35, 0.35, 0.4, 0.55)
	row.add_child(mi)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label(L.t(String(ZM.DEF[t]["name"])), 22, Color.WHITE))
	col.add_child(_label(L.t(String(zm["desc"])), 16, Color("#d9cdb5")))
	var v: int = mini(PG.stat(String(zm["stat"])), int(zm["goal"]))
	if not done:
		var pb := ProgressBar.new()
		pb.max_value = float(zm["goal"])
		pb.value = float(v)
		pb.custom_minimum_size = Vector2(0, 12)
		pb.show_percentage = false
		col.add_child(pb)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 0)
	col.add_child(fl)
	var st: String = L.t("Unlocked!") if done else "%s / %s" % [PG._thousands(v), PG._thousands(int(zm["goal"]))]
	var l0 := _label(st, 18, Color.WHITE)
	l0.autowrap_mode = TextServer.AUTOWRAP_OFF
	fl.add_child(l0)
	fl.add_child(_label("·", 18, Color.WHITE))
	fl.add_child(_reward_box({"coins": PG.ZMIS_COINS}, 0.0))
	return card


func _ach_card(a: Dictionary, done: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.2), Color(1.0, 0.82, 0.25, 0.6) if done else Color(0.96, 0.97, 1.0, 0.1), 2, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var mi := IC.rect(("medal%d" % int(a["tier"])) if done else "medalOff", 36)
	mi.custom_minimum_size.x = 48
	row.add_child(mi)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label(PG.name_of(a), 24, Color.WHITE))
	var ds: String = PG.desc_of(a)
	if PG.is_multi(a):
		ds += " " + L.t("(Requires multiplayer: not available in this version)")
	col.add_child(_label(ds, 16, Color("#d9cdb5")))
	var v: int = mini(PG.value(a), int(a["goal"]))
	if not done:
		var pb := ProgressBar.new()
		pb.max_value = float(a["goal"])
		pb.value = float(v)
		pb.custom_minimum_size = Vector2(0, 12)
		pb.show_percentage = false
		col.add_child(pb)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 0)
	col.add_child(fl)
	var st: String = L.t("Unlocked!") if done else "%s / %s" % [PG._thousands(v), PG._thousands(int(a["goal"]))]
	var l0 := _label(st, 18, Color.WHITE)
	l0.autowrap_mode = TextServer.AUTOWRAP_OFF
	fl.add_child(l0)
	fl.add_child(_label("·", 18, Color.WHITE))
	var rb := _reward_box(a["reward"], 0.0)
	fl.add_child(rb)
	if String(a["title"]) != "":
		fl.add_child(_label("·", 18, Color.WHITE))
		var tl := _label(L.t("Title: %s") % L.t(String(a["title"])), 18, C_GOLD)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		fl.add_child(tl)
	return card


# ---------------------------------------------------------------
# Perfil del jugador (sin online): nombre, Pokemon actual, 3 favoritos, titulo y tarjeta
# ---------------------------------------------------------------
func _nick() -> String:
	var n: String = String(SV.d.get("nick", "")).strip_edges()
	return n if n != "" else L.t("Trainer")


class TrainerFig extends Control:
	var tc := {}
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var CV = load("res://scripts/cave_int.gd")
		var fem: bool = int(tc.get("g", 0)) == 1
		var n: int = 5 if fem else 4
		var body: Texture2D = CV.tex_in("trainer", ("nf" if fem else "nm") + str(clampi(int(tc.get("outfit", 0)), 0, n - 1)))
		if body == null:
			return
		var k: float = minf(size.x / float(body.get_width()), size.y / float(body.get_height() * 1.1))
		var bw: float = body.get_width() * k
		var bh: float = body.get_height() * k
		var bob: float = sin(t * 2.4) * 1.5
		var org := Vector2((size.x - bw) * 0.5, size.y - bh - 2.0 + bob)
		var bag_i: int = int(tc.get("bag", -1))
		if bag_i >= 0:
			var bt: Texture2D = CV.tex_in("trainer", "bag%d" % bag_i)
			if bt != null:
				var bsz: Vector2 = bt.get_size() * (bw * 0.36 / float(bt.get_width()))
				var bx: float = bw * (0.70 if fem else -0.06)
				draw_texture_rect(bt, Rect2(org + Vector2(bx, bh * 0.34), bsz), false)
		draw_texture_rect(body, Rect2(org, Vector2(bw, bh)), false)


func _lnw(t: String, sz: int, col: Color = Color.WHITE) -> Label:
	var l := _label(t, sz, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _pp(title: String, ty: String = "", bgtex: String = "") -> VBoxContainer:
	# Panel del perfil: cabecera con pokeball; si ty != "" el fondo toma el color del tipo.
	var pc := PanelContainer.new()
	var base := Color(0.078, 0.063, 0.157, 0.88)
	var bd := Color("#5a5099")
	if ty != "":
		var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#a8a878")))
		base = tcol.darkened(0.72)
		bd = tcol
	pc.add_theme_stylebox_override("panel", _sb(base, bd, 2, 14))
	if ty != "":
		var gt := GradientTexture2D.new()
		var tgr := Gradient.new()
		var tc2: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#a8a878")))
		tgr.colors = PackedColorArray([tc2.darkened(0.2), tc2.darkened(0.75)])
		gt.gradient = tgr
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(1, 1)
		var gbg := TextureRect.new()
		gbg.texture = gt
		gbg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gbg.stretch_mode = TextureRect.STRETCH_SCALE
		gbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gbg.modulate = Color(1, 1, 1, 0.9)
		pc.add_child(gbg)
	if bgtex != "":
		var fb := TextureRect.new()
		fb.texture = load("res://scripts/cave_int.gd").tex_in("ui", bgtex)
		fb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fb.stretch_mode = TextureRect.STRETCH_SCALE
		fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pc.add_child(fb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	pc.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var ic := TextureRect.new()
	ic.texture = IC.btn_tex("ball", 24)
	ic.custom_minimum_size = Vector2(24, 24)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	h.add_child(ic)
	h.add_child(_lnw(title, 22, C_GOLD))
	if bgtex != "":
		var hp := PanelContainer.new()
		hp.add_theme_stylebox_override("panel", _sb(Color(0.078, 0.063, 0.157, 0.8), Color(0, 0, 0, 0), 0, 10))
		hp.add_child(h)
		v.add_child(hp)
	else:
		v.add_child(h)
	v.set_meta("panel", pc)
	return v


# Profile card: titled panel in the shared frame style. Returns the inner box to fill.
func _pcard(parent: Node, title: String, accent: Color = UIS.WAVE) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_lnw(title, 22, accent))
	return v


# Arrow button laid over the left/right edge of a stage.
func _stage_arrow(stage: Control, sd: int, cb: Callable) -> void:
	var ab := Button.new()
	ab.focus_mode = Control.FOCUS_ALL
	ab.text = "◀" if sd < 0 else "▶"
	ab.add_theme_font_size_override("font_size", 24)
	ab.custom_minimum_size = Vector2(48, 48)
	ab.anchor_top = 0.5
	ab.anchor_bottom = 0.5
	ab.anchor_left = 0.0 if sd < 0 else 1.0
	ab.anchor_right = ab.anchor_left
	ab.offset_left = 6.0 if sd < 0 else -54.0
	ab.offset_right = ab.offset_left + 48.0
	ab.offset_top = -24.0
	ab.offset_bottom = 24.0
	ab.pressed.connect(func(): Aud.sfx("click"); cb.call())
	stage.add_child(ab)


# One-line stat tile: label on the left, value on the right.
func _prof_stat(label: String, value: String) -> PanelContainer:
	var pc := PanelContainer.new()
	var sbx := UIS.box(Color(UIS.INK, 0.7), UIS.EDGE, 2, false)
	sbx.content_margin_left = 10
	sbx.content_margin_right = 10
	sbx.content_margin_top = 6
	sbx.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sbx)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	pc.add_child(h)
	var l := _lnw(label, 15, UIS.MUTED)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_lnw(value, 19, UIS.TEXT))
	return pc


func _goals_profile() -> Button:
	var tc: Dictionary = SV.d.get("tc", {"g": 0, "outfit": 0, "hat": 0, "bag": 0})
	var CVT = load("res://scripts/cave_int.gd")
	var first: Button = null
	# ---- identity bar: name, title, trainer card ----
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	prof_box.add_child(top)
	top.add_child(_lnw("Trainer", 18, UIS.MUTED))
	var le := LineEdit.new()
	le.text = String(SV.d.get("nick", ""))
	le.placeholder_text = L.t("Trainer")
	le.max_length = 16
	le.custom_minimum_size = Vector2(240, 44)
	le.add_theme_font_size_override("font_size", 20)
	var save_nick := func(_t = ""):
		SV.d["nick"] = le.text.strip_edges()
		SV.save()
		_update_top()
	le.text_submitted.connect(save_nick)
	le.focus_exited.connect(save_nick)
	top.add_child(le)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(240, 44)
	ob.add_theme_font_size_override("font_size", 18)
	ob.focus_mode = Control.FOCUS_ALL
	ob.add_item(L.t("(no title)"))
	ob.set_item_metadata(0, "")
	var cur_t: String = String(SV.d.get("title", ""))
	var sel := 0
	for t in PG.titles():
		ob.add_item(L.t(String(t)))
		ob.set_item_metadata(ob.item_count - 1, String(t))
		if String(t) == cur_t:
			sel = ob.item_count - 1
	ob.select(sel)
	ob.item_selected.connect(func(idx: int):
		SV.d["title"] = String(ob.get_item_metadata(idx))
		SV.save()
		Aud.sfx("confirm")
		_update_top())
	top.add_child(ob)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prof_box.add_child(root)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	root.add_child(left)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 12)
	root.add_child(mid)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	root.add_child(right)
	var sd: int = int(SV.d.get("selected", 25))
	var sty := "normal"
	if SV.dex_by.has(sd) and not SV.dex_by[sd]["types"].is_empty():
		sty = String(SV.dex_by[sd]["types"][0])
	var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(sty, "#a8a878")))
	# ---- left: partner on a stage + lifetime stats ----
	var hv := _pcard(left, "Your Pokémon", tcol.lightened(0.2))
	var stage_card := PanelContainer.new()
	stage_card.add_theme_stylebox_override("panel", UIS.frame(UIS.INK, tcol.darkened(0.2)))
	hv.add_child(stage_card)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 148)
	stage_card.add_child(stage)
	var sbg := StageBG.new()
	sbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sbg)
	var pv2 := Preview.new()
	pv2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv2.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(pv2)
	pv2.setup(sd, SV.shiny_wanted(sd), 2.8)
	_stage_arrow(stage, -1, func(): _cycle_sel(-1))
	_stage_arrow(stage, 1, func(): _cycle_sel(1))
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 10)
	hv.add_child(nrow)
	var mi1 := _medal_icon(sty, 40)
	mi1.modulate = Color.WHITE
	nrow.add_child(mi1)
	var nm := _lnw(_name_of(sd) if SV.dex_by.has(sd) else "?", 26)
	nrow.add_child(nm)
	if SV.dex_by.has(sd):
		var tl := _lnw(L.t(String(MD.TYPE_NAME[sty])), 18, tcol.lightened(0.3))
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		nrow.add_child(tl)
	var sv := _pcard(left, "Profile stats")
	var sg := GridContainer.new()
	sg.columns = 2
	sg.add_theme_constant_override("h_separation", 8)
	sg.add_theme_constant_override("v_separation", 8)
	sv.add_child(sg)
	var st: Dictionary = SV.d["stats"]
	var tm: int = int(st.get("total_time", 0))
	var rows: Array = [
		["Total runs", str(int(st.get("runs", 0)))],
		["Time played", "%dh %02dm" % [tm / 3600, (tm % 3600) / 60]],
		["Pokémon unlocked", "%d / %d" % [SV.owned_count(), SV.dex_list.size()]],
		["Highest level", L.t("Lv. %d") % int(st.get("best_level", 1))],
		["Enemies defeated", str(int(st.get("kills", 0)))],
		["Total coins", str(int(st.get("coins_total", 0)))],
		["Bosses defeated", str(int(st.get("bosses", 0)))],
	]
	for r in rows:
		sg.add_child(_prof_stat(L.t(String(r[0])), String(r[1])))
	# ---- middle: favourites + favourite type ----
	var fv := _pcard(mid, "Your 3 Favorite Pokémon", UIS.GOLD)
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 8)
	fv.add_child(fr)
	fav_btns = []
	for i in range(3):
		var slot: int = i
		var dex: int = int(favs[i]) if i < favs.size() else 0
		var b := _btn("", func(): _fav_picker(slot), Vector2(100, 140))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if dex > 0 and SV.dex_by.has(dex):
			var fcol: Color = Color.html(String(MD.TYPE_COLOR.get(String(SV.dex_by[dex]["types"][0]), "#a8a878")))
			for stn in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(stn, _sb(fcol.darkened(0.7), fcol, 3, 0))
			var pv := Preview.new()
			pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pv.set_anchors_preset(Control.PRESET_FULL_RECT)
			pv.offset_top = 8
			pv.offset_bottom = -34
			b.add_child(pv)
			pv.setup(dex, false, 2.6)
			var nl := _lnw("%d · %s" % [i + 1, _name_of(dex)], 15)
			nl.set_anchors_preset(Control.PRESET_FULL_RECT)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			nl.offset_bottom = -8
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(nl)
		else:
			b.text = "+\n%s" % L.t("Choose")
			b.add_theme_font_size_override("font_size", 20)
		fr.add_child(b)
		fav_btns.append(b)
		if first == null:
			first = b
	var cnt: Dictionary = {}
	for k in SV.d["owned"].keys():
		var dk: int = int(k)
		if SV.dex_by.has(dk):
			for t in SV.dex_by[dk]["types"]:
				cnt[String(t)] = int(cnt.get(String(t), 0)) + 1
	var tkeys: Array = cnt.keys()
	tkeys.sort_custom(func(x, y): return int(cnt[x]) > int(cnt[y]))
	var t0: String = String(tkeys[0]) if not tkeys.is_empty() else sty
	var favt: String = String(SV.d.get("fav_type", ""))
	if TYPE_IDS.has(favt):
		t0 = favt
	var t0col: Color = Color.html(String(MD.TYPE_COLOR.get(t0, "#a8a878")))
	var tv := _pcard(mid, "Favorite Type", t0col.lightened(0.2))
	var tix0: int = TYPE_IDS.find(t0)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 10)
	tv.add_child(trow)
	trow.add_child(_btn("<", func(): _set_fav_type(String(TYPE_IDS[posmod(tix0 - 1, TYPE_IDS.size())])), Vector2(52, 52)))
	var mi2 := _medal_icon(t0, 64)
	mi2.modulate = Color.WHITE
	trow.add_child(mi2)
	var tb2 := _lnw("%s (%d)" % [L.t(String(MD.TYPE_NAME[t0])).to_upper(), int(cnt.get(t0, 0))], 22, t0col.lightened(0.25))
	tb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tb2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trow.add_child(tb2)
	trow.add_child(_btn(">", func(): _set_fav_type(String(TYPE_IDS[posmod(tix0 + 1, TYPE_IDS.size())])), Vector2(52, 52)))
	var chips := GridContainer.new()
	chips.columns = 3
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 6)
	tv.add_child(chips)
	var shown := 0
	for ty3 in tkeys:
		if String(ty3) == t0 or shown >= 6:
			continue
		shown += 1
		var cl := _lnw("%s %d" % [L.t(String(MD.TYPE_NAME[String(ty3)])), int(cnt[String(ty3)])], 16, Color.html(String(MD.TYPE_COLOR.get(String(ty3), "#ffffff"))).lightened(0.2))
		cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chips.add_child(cl)
	# ---- right: appearance + medals ----
	var cv := _pcard(right, "Interface theme", UIS.ORCHID)
	for grp in []:
		var gk: String = String(grp[0])
		cv.add_child(_lnw(L.t(String(grp[1])), 16, UIS.MUTED))
		var r2 := HBoxContainer.new()
		r2.add_theme_constant_override("separation", 6)
		cv.add_child(r2)
		for ci in range(int(grp[2])):
			var idx2: int = ci
			var sw2 := _btn("", func(): _tc_set(gk, idx2), Vector2(0, 46))
			sw2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var ic2 := TextureRect.new()
			ic2.texture = CVT.tex_in("ui", "u" + gk + str(ci))
			ic2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic2.set_anchors_preset(Control.PRESET_FULL_RECT)
			ic2.offset_left = 4; ic2.offset_top = 4; ic2.offset_right = -4; ic2.offset_bottom = -4
			ic2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sw2.add_child(ic2)
			if int(tc.get(gk, 0)) == ci:
				_gold_btn(sw2, true)
			r2.add_child(sw2)
	var tr2 := HBoxContainer.new()
	tr2.add_theme_constant_override("separation", 8)
	cv.add_child(tr2)
	var cur_th: int = int(SV.d.get("ui_theme", DEFAULT_THEME))
	for ti in range(UI_THEMES.size()):
		var tix: int = ti
		var tb := _btn("", func(): _apply_ui_theme(tix); _refresh_goals(), Vector2(0, 40))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sel_t: bool = ti == cur_th
		for stn in ["normal", "hover", "pressed", "focus"]:
			tb.add_theme_stylebox_override(stn, _sb(Color(0, 0, 0, 0), UIS.GOLD if (sel_t or stn == "focus") else Color(0, 0, 0, 0), 4 if (sel_t or stn == "focus") else 0, 0))
		var tic := ColorRect.new()
		tic.color = Color(String(UI_THEMES[ti][3])).lerp(UI_THEMES[ti][2], 0.55)
		tic.set_anchors_preset(Control.PRESET_FULL_RECT)
		tic.offset_left = 6; tic.offset_top = 6; tic.offset_right = -6; tic.offset_bottom = -6
		tic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tb.add_child(tic)
		tr2.add_child(tb)
	var mv := _pcard(right, "Medals", UIS.GOLD)
	var tm_got := 0
	for ty0 in TYPE_IDS:
		if _type_medal_got(String(ty0)):
			tm_got += 1
	(mv.get_child(0) as Label).text = L.t("Medals: %d / %d") % [tm_got, TYPE_IDS.size()]
	var mg := GridContainer.new()
	mg.columns = 9
	mg.add_theme_constant_override("h_separation", 6)
	mg.add_theme_constant_override("v_separation", 6)
	mv.add_child(mg)
	for ty1 in TYPE_IDS:
		var mic := _medal_icon(String(ty1), 34)
		mic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mg.add_child(mic)
	mv.add_child(_btn("See all medals", func(): goals_tab = "h"; _show("goals"), Vector2(0, 40)))
	return first


func _set_fav_type(t: String) -> void:
	SV.d["fav_type"] = t
	SV.save()
	Aud.sfx("confirm")
	_refresh_profile()


func _tex_bg(parent: Control, name: String) -> void:
	var tr := TextureRect.new()
	tr.texture = load("res://scripts/cave_int.gd").tex_in("ui", name)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(tr)


# Fondo de los paneles del perfil dibujado en codigo (antes eran imagenes azules y doradas).
func _code_bg(parent: Control, kind: String, col: Color) -> void:
	var bg := ProfBG.new()
	bg.kind = kind
	bg.tcol = col
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)


func _place(c: Control, r: Rect2, w: float, h: float) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.anchor_left = r.position.x / w
	c.anchor_top = r.position.y / h
	c.anchor_right = (r.position.x + r.size.x) / w
	c.anchor_bottom = (r.position.y + r.size.y) / h
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0


func _flat_btn(cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	for stn in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(stn, StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", _sb(Color(0, 0, 0, 0), C_GOLD, 3, 8))
	b.pressed.connect(cb)
	return b


func _type_medal_got(ty: String) -> bool:
	return int(SV.d["stats"].get("tk_" + ty, 0)) >= ZM.NEED or int(SV.d["stats"].get("zcr_" + ty, 0)) >= 1


func _medal_icon(ty: String, sz: int) -> Control:
	var tr := TextureRect.new()
	tr.texture = load("res://scripts/cave_int.gd").tex_in("medal", ty)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(sz, sz)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var got: bool = _type_medal_got(ty)
	if not got:
		tr.modulate = Color(0.169, 0.145, 0.278, 0.9)
	var n: int = int(SV.d["stats"].get("tk_" + ty, 0))
	tr.tooltip_text = "%s: %s (%d/%d)" % [L.t("Medal"), L.t(String(MD.TYPE_NAME[ty])), mini(n, ZM.NEED), ZM.NEED]
	return tr


func _tc_set(key: String, v: int) -> void:
	var t2: Dictionary = SV.d.get("tc", {"g": 0, "outfit": 0, "hat": -1, "bag": -1})
	t2[key] = v
	SV.d["tc"] = t2
	SV.save()
	Aud.sfx("confirm")
	_refresh_goals()


func _cycle_sel(dir: int) -> void:
	var keys: Array = []
	for k in SV.d["owned"].keys():
		keys.append(int(k))
	if keys.is_empty():
		return
	keys.sort()
	var i: int = keys.find(int(SV.d.get("selected", 25)))
	SV.d["selected"] = int(keys[posmod(i + dir, keys.size())])
	SV.save()
	Aud.sfx("confirm")
	_update_top()
	_refresh_goals()


# Elegir uno de tus Pokemon para un hueco de favoritos.
func _fav_picker(slot: int) -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	v.add_child(_label("Pick a favorite", 30, C_GOLD))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(760, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var keys: Array = []
	for k in SV.d["owned"].keys():
		keys.append(int(k))
	keys.sort()
	var firstb: Button = null
	for dex in keys:
		var d2: int = int(dex)
		if not SV.dex_by.has(d2):
			continue
		var b := _btn("", func(): _set_fav(slot, d2), Vector2(140, 120))
		var pv := Preview.new()
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(pv)
		pv.setup(d2, false, 2.0)
		var nl := _label(_name_of(d2), 14)
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		nl.set_anchors_preset(Control.PRESET_FULL_RECT)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nl)
		grid.add_child(b)
		if firstb == null:
			firstb = b
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	hb.add_child(_btn("Remove", func(): _set_fav(slot, 0), Vector2(180, 52)))
	var cancel := _btn_close("Cancel", func(): gacha_result.visible = false; _refresh_goals(); _fav_focus(slot), Vector2(180, 52))
	hb.add_child(cancel)
	gacha_result.visible = true
	_gf(firstb if firstb != null else cancel)


func _set_fav(slot: int, dex: int) -> void:
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	while favs.size() < 3:
		favs.append(0)
	favs[slot] = dex
	SV.d["favs"] = favs
	SV.save()
	Aud.sfx("confirm")
	gacha_result.visible = false
	_refresh_goals()
	_fav_focus(slot)


# El foco vuelve al favorito que se acaba de elegir (no al nombre ni al principio de la pantalla).
func _fav_focus(slot: int) -> void:
	if slot >= 0 and slot < fav_btns.size() and is_instance_valid(fav_btns[slot]):
		_gf(fav_btns[slot])


# Tarjeta de entrenador: lo que antes era "ver mi perfil publico", pero sin conexion.
# 1234567 -> "1,234,567"
func _fmt_num(n: int) -> String:
	var t: String = str(absi(n))
	var out := ""
	var c := 0
	for i in range(t.length() - 1, -1, -1):
		out = t[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


func _show_card() -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.custom_minimum_size = Vector2(760, 0)
	pc.add_child(v)
	var nm := _label(_nick(), 34, C_GOLD)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var tt: String = String(SV.d.get("title", ""))
	var tl := _label(L.t(tt) if tt != "" else L.t("(no title)"), 20, Color("#f2e9d8"))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var pr := HBoxContainer.new()
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.add_theme_constant_override("separation", 14)
	v.add_child(pr)
	var sd: int = int(SV.d.get("selected", 25))
	var main_pv := Preview.new()
	main_pv.custom_minimum_size = Vector2(230, 170)
	pr.add_child(main_pv)
	main_pv.setup(sd, SV.shiny_wanted(sd), 6.0)
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	for i in range(3):
		var dex: int = int(favs[i]) if i < favs.size() else 0
		if dex > 0 and SV.dex_by.has(dex):
			var fp := Preview.new()
			fp.custom_minimum_size = Vector2(110, 96)
			pr.add_child(fp)
			fp.setup(dex, false, 3.0)
	var st: Dictionary = SV.d["stats"]
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	var bt: int = int(st.get("best_time", 0))
	g.add_child(_prof_stat(L.t("Runs"), str(int(st.get("runs", 0)))))
	g.add_child(_prof_stat(L.t("Best time"), "%02d:%02d" % [bt / 60, bt % 60]))
	g.add_child(_prof_stat(L.t("Best level"), str(int(st.get("best_level", 0)))))
	g.add_child(_prof_stat(L.t("Defeated"), str(int(st.get("kills", 0)))))
	g.add_child(_prof_stat(L.t("Bosses"), str(int(st.get("bosses", 0)))))
	g.add_child(_prof_stat(L.t("Chests"), str(int(st.get("chests", 0)))))
	g.add_child(_prof_stat(L.t("Pokémon"), "%d / %d" % [SV.owned_count(), SV.dex_list.size()]))
	g.add_child(_prof_stat(L.t("Achievements"), "%d / %d" % [SV.d.get("ach", {}).size(), PG.list().size()]))
	var tm: int = int(st.get("total_time", 0))
	g.add_child(_prof_stat(L.t("Time played"), "%dh %02dm" % [tm / 3600, (tm % 3600) / 60]))
	# extra lifetime stats (list rows, like the Doofcraft trainer card)
	var top: Array = SV.d.get("top", [])
	var hr: String = "-"
	if not top.is_empty():
		var t0: Dictionary = top[0]
		var tsec: int = int(t0.get("time", 0))
		hr = "%d:%02d · %s · Lv. %d" % [tsec / 60, tsec % 60, L.t("%d defeated") % int(t0.get("kills", 0)), int(t0.get("level", 1))]
	var hyb: int = int(st.get("hyper_best", 0))
	var best_p := 0
	var best_pd := 0
	for k in st.keys():
		if String(k).begins_with("pr_") and int(st[k]) > best_p:
			best_p = int(st[k])
			best_pd = int(String(k).substr(3))
	var fav: String = "-"
	if best_pd > 0 and SV.dex_by.has(best_pd):
		fav = "%s (%s)" % [_name_of(best_pd), L.t("%d runs") % best_p]
	var dex_pct: float = 100.0 * float(SV.owned_count()) / maxf(1.0, float(SV.dex_list.size()))
	var rows: Array = [
		[L.t("Highest run"), hr],
		[L.t("Best Hyper run"), ("%d:%02d" % [hyb / 60, hyb % 60]) if hyb > 0 else L.t("None yet")],
		[L.t("Damage dealt"), _fmt_num(int(st.get("dmg_total", 0)))],
		[L.t("Biggest hit"), _fmt_num(int(st.get("big_hit", 0)))],
		[L.t("Meters ran"), "%s m" % _fmt_num(int(st.get("meters", 0)))],
		[L.t("Favorite partner"), fav],
		[L.t("Pokédex"), "%.1f%% (%d/%d)" % [dex_pct, SV.owned_count(), SV.dex_list.size()]],
		[L.t("Shinies"), str(int(st.get("shinies", 0)))],
		[L.t("Eternatus wins"), str(int(st.get("eternatusKills", 0)))],
		[L.t("Rifts won"), str(int(st.get("rifts", 0)))],
	]
	var eg := GridContainer.new()
	eg.columns = 2
	eg.add_theme_constant_override("h_separation", 8)
	eg.add_theme_constant_override("v_separation", 6)
	v.add_child(eg)
	for r in rows:
		eg.add_child(_prof_stat(String(r[0]), String(r[1])))
	var ok := _btn_close("Close", func(): gacha_result.visible = false, Vector2(220, 52))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	hb.add_child(ok)
	v.add_child(hb)
	gacha_result.visible = true
	_gf(ok)


# Ranking local: tus 10 mejores partidas (tiempo aguantado) guardadas en este dispositivo.
func _goals_records() -> Button:
	goals_box.add_child(_label("Your best runs", 28, C_GOLD))
	var top: Array = SV.d.get("top", [])
	if top.is_empty():
		goals_box.add_child(_label("No runs yet. Play one to appear here!", 20, Color("#f2e9d8")))
		return null
	for i in range(top.size()):
		var e: Dictionary = top[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		goals_box.add_child(row)
		var rk := _label("#%d" % (i + 1), 26, C_GOLD if i == 0 else Color.WHITE)
		rk.custom_minimum_size.x = 56
		rk.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(rk)
		var pv := Preview.new()
		pv.custom_minimum_size = Vector2(56, 48)
		row.add_child(pv)
		pv.setup(int(e.get("dex", 25)), false, 1.0)
		var tm: int = int(e["time"])
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var nm: String = _name_of(int(e.get("dex", 25))) if SV.dex_by.has(int(e.get("dex", 25))) else "?"
		col.add_child(_label("%02d:%02d · %s" % [tm / 60, tm % 60, nm], 24))
		col.add_child(_label(L.t("Lv. %d") % int(e["level"]) + "  ·  " + L.t("Defeated: %d") % int(e["kills"]) + ("  ·  DOOM " + (load("res://scripts/doom.gd") as GDScript).roman(int(e["doom"])) if int(e.get("doom", 0)) > 0 else "") + "  ·  " + String(e.get("date", "")), 16, Color("#f2e9d8")))
	return null


func _goals_titles() -> Button:
	var cur_t: String = String(SV.d.get("title", ""))
	goals_box.add_child(_label(L.t("Title in use: %s") % (L.t(cur_t) if cur_t != "" else L.t("none")), 28, C_GOLD))
	var first: Button = null
	var nb := _btn("No title", func(): _set_title(""), Vector2(220, 46))
	goals_box.add_child(nb)
	first = nb
	var ach: Dictionary = SV.d.get("ach", {})
	for a in PG.list():
		var t: String = String(a["title"])
		if t == "":
			continue
		var done: bool = ach.has(String(a["id"]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		goals_box.add_child(row)
		var mi := IC.rect(("medal%d" % int(a["tier"])) if done else "medalOff", 36)
		mi.custom_minimum_size.x = 48
		row.add_child(mi)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(_label(L.t(t), 24, C_GOLD if done else Color("#8a94b0")))
		col.add_child(_label(L.t("Achievement: %s") % PG.name_of(a), 16, Color("#f2e9d8")))
		var b: Button
		if not done:
			b = _btn("Locked", func(): pass, Vector2(170, 46))
			b.disabled = true
		elif cur_t == t:
			b = _btn("In use", func(): pass, Vector2(170, 46))
			b.disabled = true
		else:
			b = _btn("Use", func(): _set_title(t), Vector2(170, 46))
		row.add_child(b)
	return first


func _set_title(t: String) -> void:
	SV.d["title"] = t
	SV.save()
	Aud.sfx("confirm")
	_refresh_goals()


# ---------------------------------------------------------------
# Ajustes
# ---------------------------------------------------------------
var set_tab := 0
var set_tabs_row: VBoxContainer
var set_card: VBoxContainer = null   # tarjeta abierta por _sec(): las filas nuevas van dentro
const SET_TAB_ICONS := ["sound", "phone", "boot", "crown", "news"]
var listening := ""
var last_act := ""
var import_armed := false
const SET_TABS := ["Sound", "Graphics", "Controls", "Account", "About"]
const REPO_URL := "https://github.com/Dwr3ker/Megarift-Survivors"
# Enlace de donaciones (Ko-fi).
# Esta edicion no recibe donaciones: la pantalla "Apoyar" (heredada del port original, con el Ko-fi de su autor) ya no es accesible.
const SUPPORT_URL := ""


func _build_settings() -> void:
	var s: Control = _screen("settings")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	s.add_child(row)
	# carril izquierdo: titulo + categorias (arriba/abajo con el mando, izquierda desde el contenido)
	var rail := PanelContainer.new()
	rail.custom_minimum_size = Vector2(250, 0)
	row.add_child(rail)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	rail.add_child(rv)
	var tt := _label("Settings", 34, UIS.GOLD)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	rv.add_child(tt)
	rv.add_child(HSeparator.new())
	set_tabs_row = VBoxContainer.new()
	set_tabs_row.add_theme_constant_override("separation", 6)
	rv.add_child(set_tabs_row)
	var ssc := ScrollContainer.new()
	ssc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ssc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ssc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(ssc)
	settings_box = VBoxContainer.new()
	settings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.add_theme_constant_override("separation", 14)
	ssc.add_child(settings_box)


# Pantalla de novedades, como la pestana "What's new" del original: una tarjeta por version con etiquetas de color.
var layout_ed: Control = null
var resume_btn: Button = null


func _build_layout() -> void:
	var s: Control = _screen("layout")
	layout_ed = LayoutEditor.new()
	s.add_child(layout_ed)
	layout_ed.build(self)


func _refresh_layout() -> void:
	if layout_ed != null:
		layout_ed.refresh()
		focus_first = layout_ed.stage


func _build_news() -> void:
	var s: Control = _screen("news")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	s.add_child(row)
	# left rail: one button per release (newest first)
	var rail := PanelContainer.new()
	rail.custom_minimum_size = Vector2(250, 0)
	row.add_child(rail)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	rail.add_child(rv)
	var tt := _label("What's new", 30, UIS.GOLD)
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	rv.add_child(tt)
	rv.add_child(HSeparator.new())
	news_rail = VBoxContainer.new()
	news_rail.add_theme_constant_override("separation", 6)
	rv.add_child(news_rail)
	var cpanel := PanelContainer.new()
	cpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cbox := UIS.box(Color(UIS.BG, 0.92), UIS.EDGE, 3, false)
	cbox.set_content_margin_all(14)
	cpanel.add_theme_stylebox_override("panel", cbox)
	row.add_child(cpanel)
	news_scroll = ScrollContainer.new()
	news_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	news_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cpanel.add_child(news_scroll)
	news_box = VBoxContainer.new()
	news_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_box.add_theme_constant_override("separation", 12)
	news_scroll.add_child(news_box)

# Pantalla "Apoyar el proyecto": donacion voluntaria, sin ventajas en el juego.
func _build_support() -> void:
	var s: Control = _screen("support")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pc.add_child(v)
	var hd := HBoxContainer.new()
	v.add_child(hd)
	var tt := _label("Support the project", 38)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	hd.add_child(tt)
	hd.add_child(_btn_close("Close", func(): _leave(), Vector2(130, 44)))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var b := VBoxContainer.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_constant_override("separation", 12)
	sc.add_child(b)
	b.add_child(_label("Pokémon Survivors is and will stay free, with no ads or purchases. If you want me to make multiplayer or online play possible, you can make a voluntary donation: all the money goes to the project's costs, nothing else.", 27))
	b.add_child(_label("Donating gives no advantage in the game.", 23, Color("#f2e9d8")))
	b.add_child(_label("What servers would be for", 33, C_GOLD))
	b.add_child(_label("Servers would help a lot to upload all of this to a cloud so players can save their progress and play online, and they would allow multiplayer modes to be developed.", 27))
	b.add_child(_label("If you support the project, I will develop all of that. Right now I can't because of a lack of funds.", 27, C_GOLD))
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 10)
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	var db := _btn("Donate on Ko-fi", func(): OS.shell_open(SUPPORT_URL), Vector2(0, 54))
	db.icon = IC.tex("heart", IC.scale_for("heart", 26))
	for st in ["normal", "hover", "pressed", "focus"]:
		var yc := Color("#f4b93a") if st != "hover" else Color("#ffd066")
		db.add_theme_stylebox_override(st, _sb(yc, Color("#fff1b8") if st != "focus" else Color.WHITE, 3 if st == "focus" else 2, 12))
	for fc in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		db.add_theme_color_override(fc, Color("#3a2200"))
	hb.add_child(db)
	support_focus = db


func _refresh_support() -> void:
	focus_first = support_focus


func _news_tag(text: String, col: Color) -> Control:
	var wrap := HBoxContainer.new()
	var pc := PanelContainer.new()
	var sb := _sb(col, col.darkened(0.25), 2, 8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	pc.add_theme_stylebox_override("panel", sb)
	var l := _label(text, 18, Color("#141028"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	pc.add_child(l)
	wrap.add_child(pc)
	return wrap


func _refresh_news() -> void:
	_clear(news_rail)
	_clear(news_box)
	news_sel = clampi(news_sel, 0, maxi(0, PN.ENTRIES.size() - 1))
	var first_btn: Button = null
	for n in range(PN.ENTRIES.size()):
		var ent: Dictionary = PN.ENTRIES[n]
		var idx: int = n
		var rb := _btn("v%s
%s" % [String(ent["ver"]), PN.fmt_date(String(ent["date"]), L.lang())], func(): news_sel = idx; _refresh_news(), Vector2(0, 62))
		rb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		rb.add_theme_font_size_override("font_size", 18)
		if n == news_sel:
			for st in ["normal", "hover", "pressed"]:
				rb.add_theme_stylebox_override(st, _sb(UIS.PANEL_HI, UIS.GOLD, 3, 0))
			first_btn = rb
		news_rail.add_child(rb)
	if PN.ENTRIES.is_empty():
		return
	var e: Dictionary = PN.ENTRIES[news_sel]
	var t := _label(L.t(String(e["title"])), 30, UIS.GOLD)
	news_box.add_child(t)
	news_box.add_child(_label("%s  ·  v%s" % [PN.fmt_date(String(e["date"]), L.lang()), String(e["ver"])], 18, UIS.MUTED))
	for sec in [["new", "New", UIS.GREEN], ["changes", "Changes", UIS.WAVE], ["fixes", "Fixes", UIS.EMBER]]:
		var lines: Array = e.get(String(sec[0]), [])
		if lines.is_empty():
			continue
		var scol: Color = sec[2]
		var card := PanelContainer.new()
		var csb := UIS.box(Color(UIS.INK, 0.6), scol, 2, true)
		csb.border_width_left = 6
		csb.content_margin_left = 16
		card.add_theme_stylebox_override("panel", csb)
		news_box.add_child(card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 8)
		card.add_child(cv)
		var hd := _label("%s  (%d)" % [L.t(String(sec[1])), lines.size()], 22, scol)
		hd.autowrap_mode = TextServer.AUTOWRAP_OFF
		cv.add_child(hd)
		for ln in lines:
			var brow := HBoxContainer.new()
			brow.add_theme_constant_override("separation", 10)
			var dot := ColorRect.new()
			dot.color = scol
			dot.custom_minimum_size = Vector2(6, 6)
			dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			var dwrap := MarginContainer.new()
			dwrap.add_theme_constant_override("margin_top", 11)
			dwrap.add_child(dot)
			brow.add_child(dwrap)
			var bl := _label(L.t(String(ln)), 20)
			bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			brow.add_child(bl)
			cv.add_child(brow)
	news_scroll.scroll_vertical = 0
	focus_first = first_btn if first_btn != null else back_btn


func _slider_row(label: String, key: String) -> void:
	var row := HBoxContainer.new()
	_sadd(row)
	var sic := IC.rect("sound", 28)
	sic.custom_minimum_size.x = 40
	row.add_child(sic)
	var l := _label(label, 22)
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 5
	sl.value = float(SV.d["settings"][key])
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 40)
	sl.focus_mode = Control.FOCUS_ALL
	sl.value_changed.connect(func(v: float):
		SV.d["settings"][key] = int(v)
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		if key == "sfx":
			Aud.sfx("coin"))
	row.add_child(sl)


# Slider for one HUD element size (60-150 %, multiplies the master HUD size).
func _hud_size(label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_sadd(row)
	var l := _label(label, 20)
	l.custom_minimum_size = Vector2(220, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 60
	sl.max_value = 150
	sl.step = 5
	sl.value = float(SV.d["settings"].get(key, 100))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 40)
	sl.focus_mode = Control.FOCUS_ALL
	row.add_child(sl)
	var pl := _label("%d%%" % int(sl.value), 20, UIS.GOLD)
	pl.custom_minimum_size = Vector2(70, 0)
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(pl)
	sl.value_changed.connect(func(v: float):
		SV.d["settings"][key] = int(v)
		SV.save()
		pl.text = "%d%%" % int(v))


func _view_row() -> void:
	var box := VBoxContainer.new()
	_sadd(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var sic := IC.rect("phone", 28)
	sic.custom_minimum_size.x = 40
	row.add_child(sic)
	var l := _label("Screen size", 22)
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = DSP.MIN_PCT
	sl.max_value = DSP.MAX_PCT
	sl.step = 5
	sl.value = float(DSP.pct())
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 40)
	sl.focus_mode = Control.FOCUS_ALL
	row.add_child(sl)
	var pl := _label("%d%%" % DSP.pct(), 22, C_GOLD)
	pl.custom_minimum_size = Vector2(80, 0)
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(pl)
	var rs := _btn("Reset", func(): pass, Vector2(150, 40))
	row.add_child(rs)
	var info := _label("", 16, Color("#f2e9d8"))
	box.add_child(info)
	var upd := func():
		pl.text = "%d%%" % DSP.pct()
		info.text = L.t("Screen (px) → game view: ") + DSP.info(get_tree())
	upd.call()
	sl.value_changed.connect(func(v: float):
		DSP.set_pct(get_tree(), int(v))
		upd.call())
	rs.pressed.connect(func():
		sl.value = 100.0)


func _sadd(n: Node) -> void:
	(set_card if set_card != null else settings_box).add_child(n)


# Abre una tarjeta con titulo: todas las filas siguientes se agrupan dentro hasta la proxima seccion.
func _sec(title: String) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UIS.frame(UIS.PANEL, UIS.EDGE))
	settings_box.add_child(pc)
	set_card = VBoxContainer.new()
	set_card.add_theme_constant_override("separation", 10)
	pc.add_child(set_card)
	var l := _label(title, 26, UIS.WAVE)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	set_card.add_child(l)


# Fila: titulo + descripcion a la izquierda, control a la derecha.
func _srow(title: String, desc: String, ctrl: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_sadd(row)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	row.add_child(tv)
	tv.add_child(_label(title, 22))
	if desc != "":
		tv.add_child(_label(desc, 16, UIS.MUTED))
	row.add_child(ctrl)
	var sep := HSeparator.new()
	_sadd(sep)


# Selector de opciones: la elegida lleva borde dorado.
func _seg(opts: Array, cur_i: int, cb: Callable, translate: bool = true) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for i in range(opts.size()):
		var b := _btn(L.t(String(opts[i])) if translate else String(opts[i]), func(): cb.call(i), Vector2(0, 44))
		if i == cur_i:
			for st in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(st, _sb(C_BTN_H, C_GOLD, 3, 22))
			b.add_theme_color_override("font_color", C_GOLD)
		h.add_child(b)
	return h


func _yesno(on: bool, cb: Callable) -> Button:
	var b := _btn(L.t("Yes") if on else L.t("No"), func(): cb.call(not on), Vector2(90, 46))
	if on:
		_gold_btn(b, true)
	return b


func _toggle_set(key: String, inverted: bool = false) -> Button:
	var on: bool = bool(SV.d["settings"].get(key, false))
	if inverted:
		on = not on
	return _yesno(on, func(v: bool):
		SV.d["settings"][key] = (not v) if inverted else v
		SV.save()
		_refresh_settings())


func _refresh_settings() -> void:
	reset_armed = false
	import_armed = false
	listening = ""
	set_card = null
	_clear(set_tabs_row)
	var first_tab: Button = null
	for i in range(SET_TABS.size()):
		var tb := _btn(L.t(SET_TABS[i]), func(): set_tab = i; last_act = ""; _refresh_settings(); _gf(tab_sel), Vector2(0, 56))
		tb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tb.icon = IC.btn_tex(String(SET_TAB_ICONS[i]), 26)
		tb.add_theme_constant_override("icon_max_width", 30)
		tb.add_theme_constant_override("h_separation", 14)
		if i == set_tab:
			for st in ["normal", "hover", "pressed"]:
				tb.add_theme_stylebox_override(st, _sb(UIS.PANEL_HI, UIS.GOLD, 3, 0))
			first_tab = tb
			tab_sel = tb
		set_tabs_row.add_child(tb)
	tab_row = set_tabs_row
	_clear(settings_box)
	focus_first = first_tab
	match set_tab:
		0:
			_set_sound()
		1:
			_set_graphics()
		2:
			_set_controls()
		3:
			_set_account()
		4:
			_set_about()


func _set_sound() -> void:
	_sec("Sound")
	_slider_row("Master volume", "master")
	_slider_row("Music", "music")
	_slider_row("Effects", "sfx")
	var muted: bool = bool(SV.d["settings"]["mute"])
	var mb := _btn(L.t("Unmute") if muted else L.t("Mute all"), func():
		SV.d["settings"]["mute"] = not muted
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		_refresh_settings(), Vector2(220, 50))
	if not muted:
		_gold_btn(mb, true)
	mb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_sadd(mb)


func _set_graphics() -> void:
	_sec("Language")
	_sadd(_label("The game reloads when you change it.", 18, Color("#f2e9d8")))
	var lg := GridContainer.new()
	lg.columns = 2
	lg.add_theme_constant_override("h_separation", 8)
	lg.add_theme_constant_override("v_separation", 8)
	var cur_lang: String = L.lang()
	for entry in L.LANGS:
		var code: String = entry[0]
		var lb := _btn(String(entry[1]), func():
			if code == L.lang():
				return
			SV.d["settings"]["lang"] = code
			SV.save()
			L.apply()
			SV.reopen = "settings"
			get_tree().reload_current_scene(), Vector2(0, 46))
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.add_theme_font_size_override("font_size", 20)
		if code == cur_lang:
			for st in ["normal", "hover", "pressed"]:
				lb.add_theme_stylebox_override(st, _sb(C_BTN_H, C_GOLD, 3, 22))
			lb.add_theme_color_override("font_color", C_GOLD)
		lg.add_child(lb)
	_sadd(lg)
	_sec("Quality")
	_srow("Effects and particles", "How many effects and particles are drawn. Auto lowers it automatically if the game stutters.", _seg(["Auto", "High", "Medium", "Low"], int(SV.d["settings"]["quality"]), func(i: int):
		SV.d["settings"]["quality"] = i
		SV.save()
		_refresh_settings()))
	_srow("Effect opacity", "How transparent your moves' attacks look, so you can see enemies better. Danger warnings are not affected.", _seg(["100%", "75%", "50%", "30%"], clampi(int(SV.d["settings"].get("fx_op", 1)), 0, 3), func(i: int):
		SV.d["settings"]["fx_op"] = i
		SV.save()
		_refresh_settings()))
	_sec("Display")
	_view_row()
	if DSP.is_desktop():
		_srow("Window mode", "Windowed or fullscreen (PC only).", _seg(["Windowed", "Fullscreen"], DSP.win_mode(), func(i: int):
			DSP.set_window(i, DSP.win_res())
			_refresh_settings()))
		var res_names: Array = []
		for rv in DSP.WIN_RES:
			res_names.append("%d×%d" % [rv.x, rv.y])
		_srow("Window resolution", "Window size on PC. If it doesn't fit your screen it adjusts itself. Not used in fullscreen.", _seg(res_names, DSP.win_res(), func(i: int):
			DSP.set_window(DSP.win_mode(), i)
			_refresh_settings(), false))
	_srow("Text size", "Makes the game text a bit larger (menus and in-run screen).", _seg(["Normal", "Large", "Very large"], TXS.idx(), func(i: int):
		TXS.set_idx(i)
		TXS.scale_tree(self)
		_refresh_settings()))
	_srow("Damage numbers", "The numbers that pop up when you hit or get hit.", _toggle_set("dmg_numbers"))
	_srow("Less shaking and flashing", "The camera shakes less and flashes are softer.", _toggle_set("shake", true))
	_srow("Vibration", "The phone vibrates when you get hit.", _toggle_set("vibration"))
	_srow("Show FPS", "Frames per second, in the corner.", _toggle_set("fps"))
	_srow("Stats box", "Shows your stats (damage, speed…) at the top left.", _toggle_set("stats_box"))
	_srow("In-run stats", "How many stats the right-hand panel shows during a run.", _seg(["Auto", "Compact", "Full"], clampi(int(SV.d["settings"].get("stats_mode", 0)), 0, 2), func(i: int):
		SV.d["settings"]["stats_mode"] = i
		SV.save()
		_refresh_settings()))
	var hud_opts := [80, 100, 115, 130]
	_srow("HUD size", "Master scale for every HUD element during a run. Each element has its own slider below.", _seg(["80%", "100%", "115%", "130%"], maxi(0, hud_opts.find(int(SV.d["settings"].get("hud_scale", 100)))), func(i: int):
		SV.d["settings"]["hud_scale"] = hud_opts[i]
		SV.save()
		_refresh_settings(), false))
	_srow("Colorblind mode", "Swaps red and green for blue and magenta and adds a pattern to the low-health bar.", _toggle_set("colorblind"))
	_srow("Mono-type bonus (+20%)", "Experimental: single-type Pokémon deal +20% damage with moves of that type. Off by default while balance is reviewed.", _toggle_set("mono_bonus"))
	_srow("Adaptive difficulty", "In normal runs, the game starts easy and gets harder as you upgrade: more enemy health and damage, more enemies, more frequent hordes and more experience needed per level.", _toggle_set("adaptive"))
	_sec("HUD layout")
	_srow("Radar", "Shows the radar (map) at the top left during a run.", _toggle_set("show_map"))
	_sadd(_label("Move, resize and hide each HUD element, and save your layouts as presets.", 18, Color("#f2e9d8")))
	var lay_btn := _btn("Edit HUD layout", func(): _show("layout"), Vector2(0, 50))
	_sadd(lay_btn)


func _set_controls() -> void:
	_sec("On mobile or tablet")
	_sadd(_label("Put your finger anywhere and drag to move: the joystick appears where you touch. Tap a move at the bottom to switch to it and the top-right button to pause. Play in landscape.", 20, Color("#f2e9d8")))
	_srow("Action button side", "Where the golden action button (pick up, trade, throw a Poké Ball…) appears, at mid-height.", _seg(["Right", "Left"], clampi(int(SV.d["settings"].get("act_side", 0)), 0, 1), func(i: int):
		SV.d["settings"]["act_side"] = i
		SV.save()
		_refresh_settings()))
	_srow("Mirrored controls", "Action buttons move to the left and the joystick to the right (for left-handed play).", _toggle_set("mirror"))
	_srow("Joystick size", "How far you need to drag your finger.", _seg(["Small", "Normal", "Large"], clampi(int(SV.d["settings"]["stick"]), 0, 2), func(i: int):
		SV.d["settings"]["stick"] = i
		SV.save()
		_refresh_settings()))
	_srow("Fixed joystick", "The joystick stays at the bottom left instead of appearing where you touch.", _toggle_set("stick_fixed"))
	_srow("Manual aim", "Aim yourself: gamepad right stick, mouse, or a second finger dragging on the right half of the screen. If you don't aim, the game aims for you.", _toggle_set("manual_aim"))
	_sec("Gamepad")
	_sadd(_label("Left stick or D-pad: move and navigate menus. Press a button in the list, then the gamepad button you want to assign to it.", 20, Color("#f2e9d8")))
	_srow("Gamepad type", "Changes the button names and resets the mapping.", _seg(PAD.NAMES, PAD.layout(), func(i: int):
		PAD.reset(i)
		_refresh_settings(), false))
	for a in PAD.ACTIONS:
		var act: String = a
		var txt: String = L.t("Press a button…") if listening == act else ""
		var cb := _btn(txt, func():
			listening = "" if listening == act else act
			last_act = act
			_refresh_listen(), Vector2(190, 46))
		if listening == act:
			_gold_btn(cb, true)
		else:
			cb.icon = PADI.tex(PAD.btn(act))
			cb.expand_icon = true
			cb.add_theme_constant_override("icon_max_width", 36)
			cb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_srow(PAD.LABELS[act], "", cb)
		if act == last_act:
			focus_first = cb
	var rb := _btn("Reset mapping", func(): PAD.reset(); last_act = ""; _refresh_settings(), Vector2(280, 46))
	_sadd(rb)


# Redibuja la pestana de controles manteniendo el modo "escuchando".
func _refresh_listen() -> void:
	var keep := listening
	_clear(settings_box)
	_set_controls()
	listening = keep
	if focus_first != null and is_instance_valid(focus_first):
		_gf(focus_first)


func _set_account() -> void:
	_sec("Account")
	var l1 := _label("Local (this device)", 22, Color("#fff7d6"))
	l1.autowrap_mode = TextServer.AUTOWRAP_OFF
	_srow("Account type", "", l1)
	var l2 := _label("On this device", 22, Color("#fff7d6"))
	l2.autowrap_mode = TextServer.AUTOWRAP_OFF
	_srow("Save", "", l2)
	_sadd(_label("Your progress is saved on this device. To keep it safe or move it to another device: copy the save code, paste it into a Google Keep note, Google Drive, an email or a message to yourself, and on the other device use “Paste save code”.", 18, Color("#f2e9d8")))
	_sec("Backup")
	var cb := _btn("Copy save code", func():
		DisplayServer.clipboard_set(SV.encode_code(SV.d))
		toast(L.t("Code copied")), Vector2(0, 50))
	_sadd(cb)
	focus_first = cb
	var ib := _btn("Paste save code", func(): pass, Vector2(0, 50))
	ib.pressed.connect(func():
		if not import_armed:
			import_armed = true
			ib.text = L.t("Replace your current progress? Press again")
			return
		import_armed = false
		var res: Dictionary = SV.decode_code(DisplayServer.clipboard_get())
		if bool(res["ok"]):
			SV.d = SV._merge(SV.default_data(), res["data"])
			SV._migrate_upgrades()
			SV.save()
			L.apply()
			SV.reopen = "settings"
			get_tree().reload_current_scene()
		else:
			ib.text = L.t("Paste save code")
			var why: String = L.t(String(res["error"]))
			if res.has("n"):
				why = why % int(res["n"])
			toast(L.t("Invalid code") + ": " + why))
	_sadd(ib)
	_sec("Redeem code")
	_sadd(_label("Have a code for a special unlock? Type it here. Each code works once.", 18, Color("#f2e9d8")))
	var code_in := LineEdit.new()
	code_in.placeholder_text = L.t("Enter code")
	code_in.max_length = 40
	code_in.custom_minimum_size = Vector2(0, 50)
	_sadd(code_in)
	var redeem_fn := func():
		var res: Dictionary = CODES.redeem(code_in.text, SV.d)
		if bool(res["ok"]):
			SV.save()
			code_in.text = ""
			toast(L.t(String(res["msg"])))
			Aud.sfx("legend")
			_update_top()
		else:
			toast(L.t(String(res["msg"])))
	var rd := _btn("Redeem", redeem_fn, Vector2(0, 50))
	code_in.text_submitted.connect(func(_t: String): redeem_fn.call())
	_sadd(rd)
	_sec("Danger zone")
	var rb := _btn("Erase all progress", func(): pass, Vector2(0, 50))
	_danger(rb)
	rb.pressed.connect(func():
		if not reset_armed:
			reset_armed = true
			rb.text = L.t("Sure? Press again to erase EVERYTHING")
		else:
			SV.reset_all()
			_show("test"))
	_sadd(rb)


func _danger(b: Button) -> void:
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, _sb(Color("#8a1f2d"), Color("#ff7a85"), 3, 12))
	b.add_theme_stylebox_override("focus", _sb(Color("#a92a3b"), Color.WHITE, 5, 12))


func _set_about() -> void:
	var t := _label("Megarift Survivors", 52, C_GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sadd(t)
	var by := _label("Doofcraft-style edition", 30)
	by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sadd(by)
	var ver := _label(L.t("Version") + " " + UPD.APP_VERSION + " · Android", 20, Color("#f2e9d8"))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sadd(ver)
	_sadd(_label("Fan game free and non-profit: no ads or purchases. Pokémon and its characters are owned by Nintendo, Creatures and GAME FREAK; this project is not affiliated with them.", 20, Color("#f2e9d8")))
	_sec("Credits")
	for line in ["• Original game (web): PokéSurvivor, by JPTER78.", "• Android port (Godot): JayElDragon.", "• This edition: Dwr3ker.", "• Inspired by PokeSurvivor Doofcraft (not affiliated); the dash, by PokeTide.", "• Sprites: PMD SpriteCollab and its artists (CC BY-NC 4.0).", "• Pokémon data: PokéAPI.", "• Font: Pixelify Sans (OFL)."]:
		_sadd(_label(line, 20))
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 10)
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	_sadd(hb)
	var dxb := _btn("Pokédex", func(): _show("dex"), Vector2(0, 50))
	hb.add_child(dxb)
	hb.add_child(_btn("GitHub repository", func(): OS.shell_open(REPO_URL), Vector2(0, 50)))
	focus_first = dxb


# Escenario del Pokemon del menu principal: degradado Dusk, suelo en perspectiva y foco bajo el Pokemon.
class StageBG extends Control:
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var n := 16
		for i in range(n):
			var t: float = float(i) / float(n - 1)
			draw_rect(Rect2(0.0, h * float(i) / float(n), w, h / float(n) + 1.0), UIS.INK.lerp(UIS.PANEL_HI, t * 0.85))
		var hy: float = h * 0.62
		draw_rect(Rect2(0.0, hy, w, h - hy), Color(UIS.BG, 0.9))
		for i in range(-6, 7):
			draw_line(Vector2(w * 0.5 + float(i) * 14.0, hy), Vector2(w * 0.5 + float(i) * 70.0, h), Color(UIS.EDGE, 0.5), 1.0)
		for j in range(1, 6):
			var yy: float = hy + (h - hy) * pow(float(j) / 6.0, 1.6)
			draw_line(Vector2(0.0, yy), Vector2(w, yy), Color(UIS.EDGE, 0.4), 1.0)
		draw_rect(Rect2(0.0, hy - 1.0, w, 2.0), Color(UIS.WAVE, 0.5))
		var pts := PackedVector2Array()
		for a in range(28):
			var ang: float = TAU * float(a) / 28.0
			pts.append(Vector2(w * 0.5 + cos(ang) * 92.0, h * 0.8 + sin(ang) * 16.0))
		draw_colored_polygon(pts, Color(UIS.WAVE, 0.22))


# Fondos de los paneles del perfil (coordenadas de diseño de las imagenes originales, para no mover los textos).
class ProfBG extends Control:
	var kind := "stats"
	var tcol := Color("#40d6ff")
	const DESIGN := {"stats": Vector2(552, 326), "tp": Vector2(391, 352), "tf": Vector2(389, 274)}

	func _plate(r: Rect2, edge: Color) -> void:
		draw_rect(r, Color(UIS.INK, 0.8))
		draw_rect(r, edge, false, 2.0)

	func _arrow(r: Rect2, left: bool) -> void:
		draw_rect(r, UIS.PANEL_HI)
		draw_rect(r, UIS.EDGE, false, 2.0)
		var c: Vector2 = r.get_center()
		var s: float = 10.0 if not left else -10.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(s, 0.0), c + Vector2(-s * 0.6, -10.0), c + Vector2(-s * 0.6, 10.0)]), UIS.GOLD)

	func _draw() -> void:
		var d: Vector2 = DESIGN[kind]
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / d.x, size.y / d.y))
		var fill: Color = Color(UIS.BG, 0.95) if kind == "stats" else UIS.BG.lerp(tcol, 0.18)
		draw_style_box(UIS.frame(fill, UIS.EDGE if kind == "stats" else tcol.darkened(0.2)), Rect2(Vector2.ZERO, d))
		_plate(Rect2(12.0, 8.0, d.x - 24.0, 40.0), UIS.EDGE if kind == "stats" else tcol.darkened(0.3))
		draw_rect(Rect2(12.0, 8.0, 5.0, 40.0), UIS.WAVE if kind == "stats" else tcol)
		if kind == "stats":
			var cys := [76, 114, 151, 188, 225, 262, 296]
			for i in range(cys.size()):
				var cy: float = float(cys[i])
				draw_rect(Rect2(58.0, cy - 17.0, d.x - 116.0, 34.0), Color(UIS.PANEL, 0.7 if i % 2 == 0 else 0.4))
				_plate(Rect2(446.0, cy - 16.0, 86.0, 32.0), UIS.EDGE)
		elif kind == "tp":
			var stage := Rect2(73.0, 50.0, 250.0, 165.0)
			for i in range(11):
				draw_rect(Rect2(stage.position.x, stage.position.y + stage.size.y * float(i) / 11.0, stage.size.x, stage.size.y / 11.0 + 1.0), UIS.INK.lerp(tcol.darkened(0.55), float(i) / 10.0 * 0.8))
			draw_rect(stage, tcol.darkened(0.3), false, 2.0)
			_arrow(Rect2(17.0, 124.0, 52.0, 82.0), true)
			_arrow(Rect2(323.0, 124.0, 52.0, 82.0), false)
			_plate(Rect2(50.0, 242.0, 283.0, 47.0), tcol.darkened(0.2))
			_plate(Rect2(100.0, 292.0, 190.0, 50.0), tcol.darkened(0.3))
		else:
			_plate(Rect2(84.0, 86.0, 205.0, 46.0), tcol.darkened(0.2))
			_plate(Rect2(14.0, 150.0, 362.0, 100.0), UIS.EDGE)
