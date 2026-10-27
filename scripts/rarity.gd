extends RefCounted
# Rareza de las cartas de mejora (al estilo Doofcraft): cada carta de estadistica sale Comun, Rara, Epica o Legendaria
# y su bonus se multiplica x1 / x1,25 / x1,5 / x2. Las probabilidades suben con el minuto de la partida
# (tabla publicada por Doofcraft: 0, 8, 15 y 30 minutos). Solo las estadisticas de formula limpia tienen rareza.

const MULT := [1.0, 1.25, 1.5, 2.0]
const NAMES := ["", "Rare", "Epic", "Legendary"]
const COLORS := [Color("#8fa3c4"), Color("#4f9cf0"), Color("#b45ec4"), Color("#ffd23f")]
const ODDS := [
	[0.0, [70, 22, 7, 1]],
	[8.0, [60, 30, 8, 2]],
	[15.0, [55, 29, 13, 3]],
	[30.0, [45, 32, 17, 6]],
]
const STATS := ["hp", "atk", "spd", "cd", "def", "rgn", "mag", "xp"]


static func eligible(sid: String) -> bool:
	return STATS.has(sid)


# Pesos [comun, rara, epica, legendaria] para ese minuto de partida (escalon: el ultimo tramo ya alcanzado).
static func weights(minute: float) -> Array:
	var w: Array = ODDS[0][1]
	for row in ODDS:
		if minute >= float(row[0]):
			w = row[1]
	return w


# Tira la rareza. `r` (0..1) se puede pasar para pruebas deterministas.
static func roll(minute: float, r: float = -1.0) -> int:
	var w: Array = weights(minute)
	var total := 0.0
	for x in w:
		total += float(x)
	var t: float = (randf() if r < 0.0 else r) * total
	for i in range(w.size()):
		t -= float(w[i])
		if t < 0.0:
			return i
	return w.size() - 1


# Valor del bonus que se muestra en la carta (en las unidades de su texto) para un multiplicador de rareza `m`.
static func value(sid: String, m: float) -> float:
	match sid:
		"hp":
			return 20.0 * m
		"atk":
			return (pow(1.10, m) - 1.0) * 100.0
		"spd":
			return (pow(1.07, m) - 1.0) * 100.0
		"cd":
			return (1.0 - pow(0.92, m)) * 100.0
		"def":
			return 6.0 * m
		"rgn":
			return 0.9 * m
		"mag":
			return (pow(1.30, m) - 1.0) * 100.0
		"xp":
			return (pow(1.12, m) - 1.0) * 100.0
	return 0.0


# Reescribe el primer numero del texto (ya traducido) con el valor de esta rareza, respetando el separador decimal.
static func desc(base: String, sid: String, m: float) -> String:
	var rx := RegEx.new()
	rx.compile("\\d+(?:([.,])(\\d+))?")
	var mt := rx.search(base)
	if mt == null:
		return base
	var v: float = value(sid, m)
	var sep: String = mt.get_string(1) if mt.get_string(1) != "" else "."
	var txt: String = String.num(v, 1).replace(".", sep) if sid == "rgn" else str(roundi(v))
	return base.substr(0, mt.get_start()) + txt + base.substr(mt.get_end())
