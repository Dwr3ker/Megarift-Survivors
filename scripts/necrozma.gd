extends RefCounted
# Necrozma: fusion and Ultra Burst, like Kyurem's DNA Splicers (kyurem.gd).
# Necrozma starts with its own move, Photon Geyser. From minute 30 a unique level-up card fuses it with the sun or the
# moon for the rest of the run: Dusk Mane (Psychic/Steel, Sunsteel Strike) or Dawn Wings (Psychic/Ghost, Moongeist
# Beam). Once fused, from minute 45 a second unique card Ultra Bursts it into Ultra Necrozma (Psychic/Dragon, Light
# That Burns the Sky) for the rest of the run. Dusk Mane and Dawn Wings have no sprites anywhere, so they keep
# Necrozma's sprite and wear armour drawn here (a solar mane, lunar wings); Ultra Necrozma uses its own sprites.
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

const DEX := 800
const START_MOVE := "photon-geyser"
const FROM_TIME := 1800.0    # minute 30: the fusion card
const ULTRA_FROM := 2700.0   # minute 45: the Ultra Burst card (once fused)
const CHANCE := 0.12         # per level-up
const ANIM_S := 2.6          # invulnerable while changing
const HP_K := 1.2
const COLOR := Color("#c8a8ff")

const FORMS := {
	"dusk": {"name": "Dusk Mane Necrozma", "move": "sunsteel-strike", "atk": 1.35, "cd": 1.0, "types": ["psychic", "steel"],
		"desc": "Psychic/Steel. +35% damage and +20% HP. Photon Geyser evolves into Sunsteel Strike, a blazing meteor charge.", "color": Color("#ffb53d")},
	"dawn": {"name": "Dawn Wings Necrozma", "move": "moongeist-beam", "atk": 1.2, "cd": 0.85, "types": ["psychic", "ghost"],
		"desc": "Psychic/Ghost. +20% damage, -15% cooldowns and +20% HP. Photon Geyser evolves into Moongeist Beam, a sweeping beam of moonlight.", "color": Color("#9a7bff")},
}
const ORDER := ["dusk", "dawn"]
const ULTRA := {"sprite": 180003, "name": "Ultra Necrozma", "move": "light-that-burns-the-sky", "atk": 1.3, "cd": 0.9, "spd": 1.1,
	"types": ["psychic", "dragon"], "color": Color("#fff1a8"),
	"desc": "Psychic/Dragon. +30% more damage, +10% speed, -10% cooldowns and +20% HP. Its signature move becomes Light That Burns the Sky."}
const SIG := ["photon-geyser", "sunsteel-strike", "moongeist-beam", "light-that-burns-the-sky"]


static func is_necrozma(main) -> bool:
	return int(main._pdex()) == DEX


static func atk_k(main) -> float:
	var k: float = float(FORMS[main.necrozma]["atk"]) if FORMS.has(main.necrozma) else 1.0
	return k * (float(ULTRA["atk"]) if main.necro_ultra else 1.0)


static func cd_k(main) -> float:
	var k: float = float(FORMS[main.necrozma]["cd"]) if FORMS.has(main.necrozma) else 1.0
	return k * (float(ULTRA["cd"]) if main.necro_ultra else 1.0)


static func spd_k(main) -> float:
	return float(ULTRA["spd"]) if main.necro_ultra else 1.0


# The unique card of this moment: the fusion (minute 30) or, once fused, Ultra Burst (minute 45). Not in Team / Tower.
static func card(main) -> Dictionary:
	if not is_necrozma(main) or main.mode == "team" or main.mode == "tower" or main.player.dead:
		return {}
	if main.necrozma == "" and main.run_time >= FROM_TIME and not main.banned.has("necrozma"):
		return {"cat": "necrozma", "id": "necrozma", "key": "necrozma", "w": 1.0, "title": L.t("Sun and Moon"),
			"desc": L.t("Fuse Necrozma with the sun or the moon: Dusk Mane or Dawn Wings, for the rest of the run."),
			"icon": "star", "tag": L.t("UNIQUE"), "color": COLOR}
	if main.necrozma != "" and not main.necro_ultra and main.run_time >= ULTRA_FROM and main._smeta.has(str(int(ULTRA["sprite"]))) and not main.banned.has("necroultra"):
		return {"cat": "necroultra", "id": "necroultra", "key": "necroultra", "w": 1.0, "title": L.t("Ultra Burst"),
			"desc": L.t(String(ULTRA["desc"])), "icon": "star", "tag": L.t("UNIQUE"), "color": ULTRA["color"]}
	return {}


static func picks(_main) -> Array:
	var out: Array = []
	for k in ORDER:
		var f: Dictionary = FORMS[k]
		out.append({"cat": "necropick", "id": k, "key": "necrozma:" + k, "w": 1.0, "title": L.t(String(f["name"])), "desc": L.t(String(f["desc"])),
			"icon": "star", "tag": L.t("Fusion"), "color": f["color"]})
	return out


# Fuses into Dusk Mane or Dawn Wings. `restore` (resuming a saved run) only rebuilds the look and types.
static func apply(main, key: String, restore: bool = false) -> void:
	if not FORMS.has(key) or main.necrozma == key:
		return
	var f: Dictionary = FORMS[key]
	var p = main.player
	main.necrozma = key
	p.types = (f["types"] as Array).duplicate()
	_armour(main)
	if restore:
		return
	var nm: float = roundf(p.max_hp * HP_K)
	p.hp += nm - p.max_hp
	p.max_hp = nm
	var conv: String = _convert(main, String(f["move"]))
	_fanfare(main, String(f["name"]), f["color"], conv)


# Ultra Burst: Ultra Necrozma's own sprite, more power, Light That Burns the Sky.
static func ultra(main, restore: bool = false) -> void:
	if main.necro_ultra or main.necrozma == "":
		return
	var p = main.player
	var fid: int = int(ULTRA["sprite"])
	main.necro_ultra = true
	p.rebody(fid, main._sm(fid), bool(p.shiny))
	p.types = (ULTRA["types"] as Array).duplicate()
	_armour(main)
	if restore:
		return
	var nm: float = roundf(p.max_hp * HP_K)
	p.hp += nm - p.max_hp
	p.max_hp = nm
	var conv: String = _convert(main, String(ULTRA["move"]))
	_fanfare(main, String(ULTRA["name"]), ULTRA["color"], conv)
	main.shake = maxf(main.shake, 14.0)
	main._ring(p.position, 10.0, 460.0, Color.WHITE, 0.9, 7.0)


static func _fanfare(main, nm: String, col: Color, conv: String) -> void:
	var p = main.player
	p.invuln = maxf(p.invuln, ANIM_S)
	p.flash = 1.0
	main.shake = maxf(main.shake, 8.0)
	Aud.sfx("legend")
	main._ring(p.position, 10.0, 320.0, col, 0.7, 6.0)
	main._ring(p.position, 10.0, 210.0, Color.WHITE, 0.5, 4.0)
	main.pfx.burst(p.position, col, 28, 250.0)
	main.add_text(p.position + Vector2(0.0, -p.body_h - 24.0), L.t(nm), col, 26)
	main._say(L.t("%s changed into %s!") % [L.t("Necrozma"), L.t(nm)], 3.2)
	if conv != "":
		main.add_text(p.position + Vector2(0.0, -p.body_h - 54.0), L.t(conv), Color("#ffe8a0"), 22)


# The signature move (Photon Geyser or a form's move), if it is already evolved, becomes `to` now.
static func _convert(main, to: String) -> String:
	for mv in main.player.moves:
		if SIG.has(String(mv["id"])) and String(mv["id"]) != to and bool(mv["evolved"]):
			var nm: Dictionary = evolve_into(main, mv, to)
			return String(nm["name"]) if not nm.is_empty() else ""
	return ""


# The move the signature evolves into now: Ultra's, else the form's ("" before fusing).
static func target(main) -> String:
	if main.necro_ultra:
		return String(ULTRA["move"])
	return String(FORMS[main.necrozma]["move"]) if FORMS.has(main.necrozma) else ""


# Replaces the signature move with `to` (default: target()), evolved, keeping its level, timer and bond.
static func evolve_into(main, mv: Dictionary, to: String = "") -> Dictionary:
	if to == "":
		to = target(main)
	var i: int = main.player.moves.find(mv)
	if to == "" or i < 0 or not main.MD.MOVES.has(to):
		return {}
	var nm: Dictionary = main._new_move(to, main._max_lvl(mv))
	main._apply_mods(nm, main.MD.EVO_MODS[String(nm["kind"])]["m"])
	nm["evolved"] = true
	nm["t"] = float(mv.get("t", 0.0))
	var bi: int = main.bond_ids.find(String(mv["id"]))
	if bi >= 0:
		main.bond_ids[bi] = to
	main.player.moves[i] = nm
	return nm


# Text for the evolution card of the signature move once fused (empty = unchanged).
static func evo_info(main) -> Dictionary:
	var to: String = target(main)
	if to == "":
		return {}
	var d: Dictionary = main.MD.MOVES[to]
	return {"name": String(d["name"]), "text": String(d["desc"])}


# The armour drawn on Necrozma's own sprite for Dusk Mane / Dawn Wings, or the light around Ultra Necrozma.
static func _armour(main) -> void:
	var p = main.player
	for c in p.get_children():
		if c is Armour:
			c.queue_free()
	var a := Armour.new()
	a.kind = "ultra" if main.necro_ultra else main.necrozma
	a.h = float(p.body_h)
	a.w = float(p.radius) * 1.8
	p.add_child(a)


class Armour extends Node2D:
	var kind := "dusk"
	var t := 0.0
	var h := 40.0
	var w := 24.0

	func _ready() -> void:
		show_behind_parent = true

	func _process(d: float) -> void:
		t += d
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(0.0, -h * 0.55)
		var beat: float = 0.5 + 0.5 * sin(t * 3.0)
		match kind:
			"dusk":   # Solgaleo's blazing mane: gold rays turning behind the head, and a warm glow
				draw_circle(c, w * 1.6, Color(1.0, 0.62, 0.2, 0.16 + 0.06 * beat))
				for i in range(14):
					var a: float = t * 0.6 + TAU * float(i) / 14.0
					var ln: float = w * (1.35 + 0.25 * sin(t * 4.0 + float(i)))
					var p0: Vector2 = c + Vector2.from_angle(a) * w * 0.55
					draw_colored_polygon(PackedVector2Array([p0 + Vector2.from_angle(a + 1.57) * 5.0, c + Vector2.from_angle(a) * ln, p0 - Vector2.from_angle(a + 1.57) * 5.0]),
						Color(1.0, 0.75 + 0.15 * sin(float(i)), 0.25, 0.85))
				draw_arc(c, w * 0.62, 0.0, TAU, 30, Color(1.0, 0.95, 0.7, 0.8), 3.0)
			"dawn":   # Lunala's wings: two wide violet crescents with stars, slowly beating
				var flap: float = 0.12 * sin(t * 2.2)
				for sd in [-1.0, 1.0]:
					var base: Vector2 = c + Vector2(sd * w * 0.35, 0.0)
					var pts := PackedVector2Array()
					for j in range(9):   # wide wings that reach well past the body
						var u: float = float(j) / 8.0
						pts.append(base + Vector2(sd * w * (0.3 + 3.0 * u), -h * (0.75 * sin(u * PI) + flap * u) + h * 0.45 * u * u))
					for j in range(8, -1, -1):
						var u2: float = float(j) / 8.0
						pts.append(base + Vector2(sd * w * (0.3 + 2.5 * u2), -h * (0.3 * sin(u2 * PI) + flap * u2) + h * 0.55 * u2 * u2))
					draw_colored_polygon(pts, Color(0.18, 0.1, 0.42, 0.92))
					var edge := PackedVector2Array()
					for j in range(9):
						var u3: float = float(j) / 8.0
						edge.append(base + Vector2(sd * w * (0.3 + 3.0 * u3), -h * (0.75 * sin(u3 * PI) + flap * u3) + h * 0.45 * u3 * u3))
					draw_polyline(edge, Color(0.75, 0.6, 1.0, 0.95), 3.0)
					for j in range(6):
						var sp: Vector2 = base + Vector2(sd * w * (0.7 + 0.4 * float(j)), -h * 0.38 + h * 0.08 * float(j % 2))
						var s: float = 1.5 + 1.5 * (0.5 + 0.5 * sin(t * 5.0 + float(j) * 1.7))
						draw_rect(Rect2(sp - Vector2(s, s), Vector2(s * 2.0, s * 2.0)), Color(0.9, 0.85, 1.0, 0.9))
				draw_circle(c, w * 1.2, Color(0.55, 0.4, 1.0, 0.12 + 0.05 * beat))
			"ultra":   # Ultra Necrozma: blinding golden light
				for i in range(4):
					draw_circle(c, w * (1.9 - 0.35 * float(i)) * (0.95 + 0.05 * beat), Color(1.0, 0.92, 0.55, 0.06 + 0.04 * float(i)))
				for i in range(8):
					var a2: float = -t * 0.8 + TAU * float(i) / 8.0
					draw_line(c + Vector2.from_angle(a2) * w * 0.7, c + Vector2.from_angle(a2) * w * 2.0, Color(1.0, 0.95, 0.7, 0.35), 3.0)
