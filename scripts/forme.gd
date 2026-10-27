extends RefCounted
# Cambio de Forma de Deoxys (al estilo Doofcraft): desde el minuto 5 sale una carta rara "unica" que permite cambiar a la
# Forma Ataque, Defensa o Velocidad (cada una potencia su estadistica) y, mas adelante, cambiar de una a otra.
# Cifras de Doofcraft (formChange): fromMinute 5, attack / toughness / speed x1,3, animacion 2,8 s.
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

const DEX := 386
const FROM_TIME := 300.0     # minuto 5 (segundos de partida)
const ATK_K := 1.3           # Forma Ataque: dano
const SPD_K := 1.3           # Forma Velocidad: velocidad
const TAKEN := 0.2308        # Forma Defensa: 1 - 1/1,3 de dano recibido menos (resistencia x1,3, como el Dynamax)
const ANIM_S := 2.8          # invulnerable durante la transformacion
const CHANCE_FIRST := 0.12   # por subida de nivel, antes del primer cambio
const CHANCE_AFTER := 0.06   # despues, para poder volver a cambiar
const COOLDOWN := 90.0       # segundos de partida entre dos cambios
const COLOR := Color("#ff6bb0")

# clave -> [sprite (pseudo-especie), nombre, descripcion, icono, color]
const FORMES := {
	"attack": [138601, "Attack Forme", "+30% damage with every move.", "fist", Color("#ff6b5a")],
	"defense": [138602, "Defense Forme", "You take 30% less damage (x1.3 toughness).", "shield", Color("#6bb8ff")],
	"speed": [138603, "Speed Forme", "+30% movement speed.", "boot", Color("#ffd23f")],
}
const ORDER := ["attack", "defense", "speed"]


# Carta rara de la subida de nivel: solo Deoxys, pasados 5 minutos y fuera de los modos sin cambios de Pokemon.
static func card(main) -> Dictionary:
	if int(main._pdex()) != DEX or main.mode == "team" or main.mode == "tower" or main.banned.has("forme"):
		return {}
	if main.run_time < FROM_TIME or main.player.dead or main.run_time < main.forme_t + COOLDOWN:
		return {}
	for k in ORDER:
		if not main._smeta.has(str(int(FORMES[k][0]))):
			return {}
	var title: String = L.t("Forme Change")
	return {"cat": "forme", "id": "forme", "key": "forme", "w": 1.0, "title": title,
		"desc": L.t("Change to Attack, Defense or Speed Forme: each boosts its own stat.") if main.forme == "" else L.t("Switch to another Forme: Attack, Defense or Speed."),
		"icon": "star", "tag": L.t("UNIQUE"), "color": COLOR}


# Las tres formas a elegir (sin la actual).
static func picks(main) -> Array:
	var out: Array = []
	for k in ORDER:
		if k == main.forme:
			continue
		var f: Array = FORMES[k]
		out.append({"cat": "formepick", "id": k, "key": "forme:" + k, "w": 1.0, "title": L.t(String(f[1])), "desc": L.t(String(f[2])),
			"icon": String(f[3]), "tag": L.t("Forme"), "color": f[4]})
	return out


static func chance(main) -> float:
	return CHANCE_AFTER if main.forme != "" else CHANCE_FIRST


# Aplica la forma elegida: cuerpo nuevo, invulnerabilidad breve y efectos. Los multiplicadores los leen _atk / _spd / _reduction.
static func apply(main, key: String) -> void:
	if not FORMES.has(key) or key == main.forme:
		return
	var f: Array = FORMES[key]
	var p = main.player
	var fid: int = int(f[0])
	p.rebody(fid, main._sm(fid), bool(p.shiny))
	main.forme = key
	main.forme_t = main.run_time
	var col: Color = f[4]
	p.invuln = maxf(p.invuln, ANIM_S)
	p.flash = 1.0
	main.shake = maxf(main.shake, 7.0)
	Aud.sfx("legend")
	main._ring(p.position, 10.0, 300.0, col, 0.7, 6.0)
	main._ring(p.position, 10.0, 200.0, Color.WHITE, 0.5, 4.0)
	main.pfx.burst(p.position, col, 26, 240.0)
	main.add_text(p.position + Vector2(0.0, -p.body_h - 24.0), L.t(String(f[1])), col, 26)
	main._say(L.t("%s changed into %s!") % [L.t("Deoxys"), L.t(String(f[1]))], 3.0)
