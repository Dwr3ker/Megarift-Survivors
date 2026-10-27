extends RefCounted
# Megaevolucion (al estilo Doofcraft): una vez por partida, desde el minuto 30, una carta rara permite que un Pokemon
# "capaz" (Mega, Reversion Primigenia o Forma Corona) se transforme el resto de la partida: +30% dano y vida,
# +10% velocidad, -10% de enfriamiento. Cifras del balance publicado por Doofcraft (mega: fromMinute 30, 1.3/1.3/1.1/0.9).
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

const FROM_TIME := 1800.0   # minuto 30
const OFFER_CHANCE := 0.12  # por subida de nivel, a partir de FROM_TIME
const ATK_K := 1.3
const HP_K := 1.3
const SPD_K := 1.1
const CD_K := 0.9
const ANIM_S := 2.6         # invulnerable durante la transformacion
const COLOR := Color("#ff8ad8")

# Grietas Mega: el legendario de la grieta puede aparecer en su forma Mega / Primigenia / Corona (Doofcraft: desde el
# minuto 15, cada vez mas a menudo). Curva [minuto, probabilidad] interpolada; mas vida, dano y premio que el normal.
const RIFT_CURVE := [[15.0, 0.05], [30.0, 0.15], [60.0, 0.30]]
const RIFT_HP_K := 1.3
const RIFT_DMG_K := 1.2
const RIFT_REWARD_K := 1.2

# Zacian y Zamazenta (Doofcraft): aprenden Cabeza de Hierro antes de coronarse; al coronarse, esa linea de movimiento
# (con su nivel y su evolucion) se convierte en Mandoble Titanico (Zacian) o Golpe Titanico (Zamazenta). En este juego
# la linea es Garra Metal > Cabeza de Hierro.
const EXTRA_MOVES := {888: ["metal-claw"], 889: ["metal-claw"]}
const CROWN_MOVE := {888: "behemoth-blade", 889: "behemoth-bash"}

static var _by_dex: Dictionary = {}

var m
var active := false
var form: Dictionary = {}


static func _load() -> void:
	if not _by_dex.is_empty():
		return
	var f := FileAccess.open("res://data/megas.json", FileAccess.READ)
	if f == null:
		return
	var arr = JSON.parse_string(f.get_as_text())
	if arr is Array:
		for e in arr:
			_by_dex[int(e["dex"])] = e


# Datos de la forma de este Pokemon, o {} si no puede megaevolucionar.
static func form_for(dex: int) -> Dictionary:
	_load()
	return _by_dex.get(dex, {})


static func is_capable(dex: int) -> bool:
	return not form_for(dex).is_empty()


# Movimientos fuera de tipo que este Pokemon puede recibir en las cartas (p. ej. Garra Metal para Zacian).
static func extra_ok(dex: int, move_id: String) -> bool:
	return EXTRA_MOVES.has(dex) and (EXTRA_MOVES[dex] as Array).has(move_id)


# Al coronarse: Garra Metal / Cabeza de Hierro pasa a ser el movimiento de la Forma Corona, conservando nivel y evolucion.
static func convert_signature(main, dex: int) -> String:
	var to: String = String(CROWN_MOVE.get(dex, ""))
	if to == "" or not main.MD.MOVES.has(to):
		return ""
	for i in range(main.player.moves.size()):
		var mv: Dictionary = main.player.moves[i]
		if String(mv["id"]) != "metal-claw":
			continue
		var nm: Dictionary = main._new_move(to, int(mv["lvl"]))
		if bool(mv["evolved"]):
			main._apply_mods(nm, main.MD.EVO_MODS[String(nm["kind"])]["m"])
			nm["name"] = String(main.MD.EVO[to][0])
			nm["evolved"] = true
		nm["t"] = float(mv.get("t", 0.0))
		var bi: int = main.bond_ids.find("metal-claw")
		if bi >= 0:
			main.bond_ids[bi] = to
		main.player.moves[i] = nm
		return String(nm["name"])
	return ""


# Probabilidad de que una grieta sea Mega en ese minuto de partida (0 antes del minuto 15, tope en el ultimo punto).
static func rift_chance(minute: float) -> float:
	if minute < float(RIFT_CURVE[0][0]):
		return 0.0
	for i in range(1, RIFT_CURVE.size()):
		var a: Array = RIFT_CURVE[i - 1]
		var b: Array = RIFT_CURVE[i]
		if minute < float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (minute - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(RIFT_CURVE[RIFT_CURVE.size() - 1][1])


# Convierte al jefe de la grieta (ya creado con su especie base) en su forma Mega: cuerpo, nombre, tipos y numeros.
static func apply_boss(main, e, base_dex: int) -> void:
	var fm: Dictionary = form_for(base_dex)
	if fm.is_empty():
		return
	var fid: int = int(fm["form"])
	e.rebody(fid, main._sm(fid), bool(e.shiny))
	e.base_dex = base_dex
	e.enemy_name = String(fm["name"])
	if fm.has("types"):
		e.types = (fm["types"] as Array).duplicate()
		e.atk_type = String(e.types[0])
	e.max_hp = roundf(e.max_hp * RIFT_HP_K)
	e.hp = e.max_hp
	e.dmg *= RIFT_DMG_K
	e.xp_val *= RIFT_REWARD_K


# Carta rara de la subida de nivel: solo si el Pokemon es capaz, aun no se ha usado y ya pasaron 30 minutos.
static func card(main) -> Dictionary:
	if main.mega_done or main.mode == "team" or main.mode == "tower" or main.banned.has("mega"):
		return {}
	if main.run_time < FROM_TIME or main.player.dead:
		return {}
	var fm: Dictionary = form_for(int(main._pdex()))
	if fm.is_empty() or not main._smeta.has(str(int(fm["form"]))):
		return {}
	var kind: String = String(fm["kind"])
	var title: String = L.t("Mega Evolution")
	if kind == "primal":
		title = L.t("Primal Reversion")
	elif kind == "crowned":
		title = L.t("Crowned Form")
	var desc: String = L.t("%s: +30%% damage and HP, +10%% speed and -10%% cooldowns for the rest of the run") % String(fm["name"])
	if main.z_type != "":
		desc += ". " + L.t("You lose your Z-Move.")
	return {"cat": "mega", "id": "mega", "key": "mega", "w": 1.0, "title": title, "desc": desc,
		"icon": "star", "tag": L.t("UNIQUE"), "color": COLOR}


func start(main) -> void:
	m = main
	form = form_for(int(m._pdex()))
	if form.is_empty():
		return
	active = true
	var p = m.player
	var fid: int = int(form["form"])
	p.rebody(fid, m._sm(fid), bool(p.shiny))
	var nm: float = roundf(p.max_hp * HP_K)
	p.hp += nm - p.max_hp
	p.max_hp = nm
	if form.has("types"):
		p.types = (form["types"] as Array).duplicate()
	m.z_type = ""   # los Pokemon megaevolucionados no pueden usar Movimiento Z
	var conv: String = ""
	if String(form["kind"]) == "crowned":
		conv = convert_signature(m, int(form["dex"]))
	p.invuln = maxf(p.invuln, ANIM_S)
	p.flash = 1.0
	m.shake = maxf(m.shake, 8.0)
	Aud.sfx("legend")
	m._ring(p.position, 10.0, 340.0, COLOR, 0.7, 6.0)
	m._ring(p.position, 10.0, 220.0, Color.WHITE, 0.5, 4.0)
	m.pfx.burst(p.position, COLOR, 30, 260.0)
	m.add_text(p.position + Vector2(0.0, -p.body_h - 24.0), String(form["name"]), COLOR, 26)
	m._say(L.t("%s changed into %s!") % [L.t(String((m._dex_by[int(form["dex"])])["name"])), String(form["name"])], 3.2)
	if conv != "":   # el movimiento de la Forma Corona sustituye a Garra Metal / Cabeza de Hierro
		m.add_text(p.position + Vector2(0.0, -p.body_h - 54.0), L.t(conv), Color("#ffe8a0"), 22)
	for k in [0.35, 0.8, 1.4]:
		m.get_tree().create_timer(float(k)).timeout.connect(_pulse.bind(float(k)))


func _pulse(k: float) -> void:
	if not active or m == null or m.player == null:
		return
	m.player.flash = 1.0
	m.shake = maxf(m.shake, 3.0 + 4.0 * k)
	m._ring(m.player.position, 8.0, 100.0 + 120.0 * k, COLOR.lerp(Color.WHITE, 0.4), 0.45, 4.0)
	m.pfx.burst(m.player.position + Vector2(0.0, -m.player.body_h * 0.5), COLOR, int(10.0 + 12.0 * k), 220.0)
