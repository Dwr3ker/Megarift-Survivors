extends RefCounted
# Placas de Arceus (al estilo Doofcraft): Arceus empieza con Sentencia (esferas teledirigidas de tipo Normal) y, desde el
# minuto 5, puede encontrar placas como carta unica: cambian el tipo de Arceus y de Sentencia (y su aspecto) hasta que
# elija otra placa. Una placa nueva sustituye a la anterior; la Placa Blanca vuelve al tipo Normal.
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")
const MD = preload("res://scripts/moves_data.gd")

const DEX := 493
const FROM_TIME := 300.0     # minuto 5 (segundos de partida)
const CHANCE := 0.15         # por subida de nivel
const COOLDOWN := 45.0       # segundos de partida entre dos placas
const ANIM_S := 1.0          # invulnerable un instante al cambiar

static var _list: Array = []


static func list() -> Array:
	if _list.is_empty():
		var f := FileAccess.open("res://data/plates.json", FileAccess.READ)
		if f != null:
			var arr = JSON.parse_string(f.get_as_text())
			if arr is Array:
				_list = arr
	return _list


# Nombre de la placa en el idioma del juego (clave en espanol: "Placa <Tipo>").
static func plate_name(type: String) -> String:
	return L.t("%s Plate") % L.t(String(MD.TYPE_NAME[type]))


# Carta unica de placa: solo Arceus, pasados 5 minutos; ofrece una placa al azar distinta de la que ya lleva.
static func card(main) -> Dictionary:
	if int(main._pdex()) != DEX or main.mode == "team" or main.mode == "tower" or main.banned.has("plate"):
		return {}
	if main.run_time < FROM_TIME or main.player.dead or main.run_time < main.plate_t + COOLDOWN:
		return {}
	var opts: Array = []
	for p in list():
		if String(p["type"]) != main.plate and main._smeta.has(str(int(p["form"]))):
			opts.append(p)
	if opts.is_empty():
		return {}
	var p: Dictionary = opts[randi() % opts.size()]
	var ty: String = String(p["type"])
	var col: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#b0a99f")))
	return {"cat": "plate", "id": "plate", "key": "plate:" + ty, "w": 1.0, "ptype": ty, "title": plate_name(ty),
		"desc": L.t("Changes Arceus and Judgment to %s type until you choose another plate. Replaces the previous plate.") % L.t(String(MD.TYPE_NAME[ty])),
		"icon": "type:" + ty, "tag": L.t("UNIQUE"), "color": col}


# Aplica la placa: tipo de Arceus y de Sentencia, y el cuerpo con el aspecto de ese tipo.
static func apply(main, type: String) -> void:
	var entry: Dictionary = {}
	for p in list():
		if String(p["type"]) == type:
			entry = p
	if entry.is_empty() or type == main.plate:
		return
	var pl = main.player
	var fid: int = int(entry["form"])
	pl.rebody(fid, main._sm(fid), bool(pl.shiny))
	pl.types = [type]
	for mv in pl.moves:
		if String(mv["id"]) == "judgment":
			mv["type"] = type
	main.plate = type
	main.plate_t = main.run_time
	var col: Color = Color.html(String(MD.TYPE_COLOR.get(type, "#b0a99f")))
	pl.invuln = maxf(pl.invuln, ANIM_S)
	pl.flash = 1.0
	main.shake = maxf(main.shake, 4.0)
	Aud.sfx("legend")
	main._ring(pl.position, 8.0, 220.0, col, 0.6, 5.0)
	main._ring(pl.position, 8.0, 140.0, Color.WHITE, 0.4, 3.0)
	main.pfx.burst(pl.position, col, 22, 220.0)
	main.add_text(pl.position + Vector2(0.0, -pl.body_h - 24.0), plate_name(type), col, 24)
	main._say(L.t("%s changed into %s!") % [L.t("Arceus"), plate_name(type)], 2.6)
