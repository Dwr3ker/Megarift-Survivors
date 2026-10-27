extends RefCounted
# Novedades de cada version, como la pestaña "What's new" del original: lista de versiones (la mas nueva arriba) con
# titulo, fecha y secciones Nuevo / Cambios / Arreglos. Van dentro del juego (sin internet) y traducidas con L.t.
# PARA CADA ACTUALIZACION: anade una entrada NUEVA ARRIBA del todo en ENTRIES (ver = mismo numero que
# application/config/version), escribe sus lineas en espanol y anade sus traducciones a los 9 idiomas.

const SV = preload("res://scripts/save_data.gd")
const UPD = preload("res://scripts/updater.gd")

const ENTRIES := [
	{
		"ver": "0.1.0",
		"date": "2026-10-27",
		"title": "Megarift Survivors 0.1: Doofcraft-style edition (test build)",
		"new": [
			"Mega Evolution: from minute 30 a unique card transforms capable Pokémon (41 Mega, Primal and Crowned forms) with +30% damage and HP, +10% speed and -10% cooldowns.",
			"Mega Rifts from minute 15, a mega-capable badge in the collection, and Behemoth moves for Crowned Zacian and Zamazenta.",
			"Common, Rare, Epic and Legendary upgrade cards: their bonuses are multiplied by 1, 1.25, 1.5 and 2.",
			"Hyper mode on Normal Run: everything runs twice as fast, with +30% experience and ×1.5 coins. It has its own record and achievements.",
			"Dash: Shift or Space, a DASH button on screen and a controller button. You are briefly invulnerable and hit whatever you pass through.",
			"Eternamax Eternatus: the final boss now attacks with Eternabeam, cannons, rings, a tail slam and meteors, and is healed by three dark obelisks.",
			"After you defeat Eternatus you choose: end the run with a victory or keep fighting. You get a reward (coins, tickets and x10 tickets) and he returns every 30 minutes (15 in Hyper) with another reward.",
			"Doom: every time you defeat Eternatus and keep going, the Doom level rises: more elites with traits, a bigger swarm, Mega Rifts, and Eternatus learns the Gravity Well, a double Eternabeam and to revive obelisks. Coins are worth more (up to x2.5).",
			"Endgame: upgrades go beyond their maximum (Overcap, at half effect) and, after the first Eternatus, three new cards appear: Second Wind, Overdrive and Apex Predator. Seven new achievements.",
			"Mega Calamity: between two Eternatus fights a Mega legendary appears with telegraphed attacks (Stomp and Barrage) and a good reward. It arrives 15 minutes before the next Eternatus.",
			"Wild legendaries from minute 30: up to three at once, appearing more and more often.",
			"Deoxys can change Forme (Attack, Defense or Speed) with a unique card from minute 5.",
			"Arceus starts with Judgment and finds Plates that change its type and look.",
			"Z-Crystal as a card from minute 15: it unlocks your Z-Move for the run, with a 2-minute recharge.",
		],
		"changes": [
			"Balance: +10% damage with moves of your own type, Momentum for chained defeats (up to +20% damage), a ×2.5 speed cap and shorter enemy shields (3.5 s).",
			"Rifts: the first check is at 90 s and then every 30 s, with a 20% chance that grows 5% with every miss (max 50%). There is no longer a time limit: they keep appearing until Eternatus.",
		],
		"fixes": [],
	},
]


# Primera vez con esta version (y ya habia partidas jugadas): el menu abre la pantalla de novedades.
static func should_show() -> bool:
	var v: String = UPD.APP_VERSION
	if String(SV.d.get("notes_seen", "")) == v:
		return false
	SV.d["notes_seen"] = v
	SV.save()
	var has := false
	for e in ENTRIES:
		if String(e["ver"]) == v:
			has = true
	if not has:
		return false
	var st: Dictionary = SV.d.get("stats", {})
	return int(st.get("runs", 0)) > 0   # instalacion nueva: no hay nada que "haya cambiado" para esta persona


const MONTHS := {
	"es": ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
	"en": ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
	"fr": ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"],
	"it": ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"],
	"pt": ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"],
	"ru": ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"],
}


# "2026-10-15" -> "15 October 2026" / "15 de octubre de 2026" / "2026年10月15日", segun el idioma.
static func fmt_date(iso: String, code: String) -> String:
	var p: PackedStringArray = iso.split("-")
	if p.size() != 3:
		return iso
	var y: int = int(p[0])
	var m: int = clampi(int(p[1]), 1, 12)
	var d: int = int(p[2])
	if code == "ja" or code.begins_with("zh"):
		return "%d年%d月%d日" % [y, m, d]
	if code == "vi":
		return "%d tháng %d, %d" % [d, m, y]
	var key: String = code
	if code.begins_with("es"):
		key = "es"
	elif code.begins_with("pt"):
		key = "pt"
	if not MONTHS.has(key):
		key = "en"
	var mn: String = String(MONTHS[key][m - 1])
	if key == "es" or key == "pt":
		return "%d de %s de %d" % [d, mn, y]
	return "%d %s %d" % [d, mn, y]
