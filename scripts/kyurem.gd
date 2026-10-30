extends RefCounted
# Kyurem: DNA Splicers. From minute 30 a unique level-up card lets Kyurem fuse into Black Kyurem or White Kyurem for the rest
# of the run. Kyurem's own move is Glaciate (a freezing wind). Glaciate evolves into Glaciate+; once fused, the evolved
# move is Black Kyurem's Freeze Shock (a colossal electrified lance that paralyses) or White Kyurem's Ice Burn (a vast blaze
# of white fire that burns). If Glaciate was already evolved when Kyurem fuses, it turns into that move on the spot.
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

const DEX := 646
const FROM_TIME := 1800.0   # minute 30
const CHANCE := 0.12        # per level-up, from FROM_TIME
const ANIM_S := 2.6         # invulnerable while fusing
const HP_K := 1.2
const COLOR := Color("#bfe9ff")

# key -> sprite (pseudo-species), name, signature move, damage multiplier, cooldown multiplier, description, colour
const FORMS := {
	"black": {"sprite": 164601, "name": "Black Kyurem", "move": "freeze-shock", "atk": 1.4, "cd": 1.0,
		"desc": "+40% damage and +20% HP. Glaciate evolves into Freeze Shock, a colossal electrified lance that paralyses.", "color": Color("#8f86ff")},
	"white": {"sprite": 164602, "name": "White Kyurem", "move": "ice-burn-white", "atk": 1.25, "cd": 0.85,
		"desc": "+25% damage, -15% cooldowns and +20% HP. Glaciate evolves into Ice Burn, a vast blaze of white fire that burns.", "color": Color("#ffe9b8")},
}
const ORDER := ["black", "white"]


static func is_kyurem(main) -> bool:
	return int(main._pdex()) == DEX


static func atk_k(main) -> float:
	return float(FORMS[main.kyurem]["atk"]) if FORMS.has(main.kyurem) else 1.0


static func cd_k(main) -> float:
	return float(FORMS[main.kyurem]["cd"]) if FORMS.has(main.kyurem) else 1.0


# Unique level-up card: only Kyurem, from minute 30, once per run, and not in the modes without Pokémon changes.
static func card(main) -> Dictionary:
	if not is_kyurem(main) or main.kyurem != "" or main.mode == "team" or main.mode == "tower" or main.banned.has("kyurem"):
		return {}
	if main.run_time < FROM_TIME or main.player.dead:
		return {}
	for k in ORDER:
		if not main._smeta.has(str(int(FORMS[k]["sprite"]))):
			return {}
	return {"cat": "kyurem", "id": "kyurem", "key": "kyurem", "w": 1.0, "title": L.t("DNA Splicers"),
		"desc": L.t("Fuse Kyurem into Black Kyurem or White Kyurem for the rest of the run."),
		"icon": "star", "tag": L.t("UNIQUE"), "color": COLOR}


static func picks(_main) -> Array:
	var out: Array = []
	for k in ORDER:
		var f: Dictionary = FORMS[k]
		out.append({"cat": "kyurempick", "id": k, "key": "kyurem:" + k, "w": 1.0, "title": L.t(String(f["name"])), "desc": L.t(String(f["desc"])),
			"icon": "star", "tag": L.t("Fusion"), "color": f["color"]})
	return out


# Fuses into the chosen form. `restore` (resuming a saved run) only rebuilds the body: HP and moves come back from the save.
static func apply(main, key: String, restore: bool = false) -> void:
	if not FORMS.has(key) or main.kyurem == key:
		return
	var f: Dictionary = FORMS[key]
	var p = main.player
	var fid: int = int(f["sprite"])
	p.rebody(fid, main._sm(fid), bool(p.shiny))
	main.kyurem = key
	if restore:
		return
	var nm: float = roundf(p.max_hp * HP_K)
	p.hp += nm - p.max_hp
	p.max_hp = nm
	var conv: String = convert_evolved(main)
	var col: Color = f["color"]
	p.invuln = maxf(p.invuln, ANIM_S)
	p.flash = 1.0
	main.shake = maxf(main.shake, 8.0)
	Aud.sfx("legend")
	main._ring(p.position, 10.0, 320.0, col, 0.7, 6.0)
	main._ring(p.position, 10.0, 210.0, Color.WHITE, 0.5, 4.0)
	main.pfx.burst(p.position, col, 28, 250.0)
	main.add_text(p.position + Vector2(0.0, -p.body_h - 24.0), L.t(String(f["name"])), col, 26)
	main._say(L.t("%s changed into %s!") % [L.t("Kyurem"), L.t(String(f["name"]))], 3.2)
	if conv != "":
		main.add_text(p.position + Vector2(0.0, -p.body_h - 54.0), L.t(conv), Color("#ffe8a0"), 22)


# Glaciate already evolved when Kyurem fuses: it becomes the form's move now. Returns its name, or "" when nothing changed.
static func convert_evolved(main) -> String:
	for mv in main.player.moves:
		if String(mv["id"]) == "glaciate" and bool(mv["evolved"]):
			var nm: Dictionary = evolve_into(main, mv)
			return String(nm["name"]) if not nm.is_empty() else ""
	return ""


# Replaces the Glaciate dictionary with the form's evolved move, keeping its level, cooldown timer and bond.
# Called when Glaciate evolves after the fusion, and when an evolved Glaciate meets the fusion.
static func evolve_into(main, mv: Dictionary) -> Dictionary:
	if not FORMS.has(main.kyurem):
		return {}
	var to: String = String(FORMS[main.kyurem]["move"])
	var i: int = main.player.moves.find(mv)
	if i < 0 or not main.MD.MOVES.has(to):
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


# Text for the evolution card of Glaciate once Kyurem has fused (null = unchanged).
static func evo_info(main) -> Dictionary:
	if not FORMS.has(main.kyurem):
		return {}
	var to: String = String(FORMS[main.kyurem]["move"])
	var d: Dictionary = main.MD.MOVES[to]
	return {"name": String(d["name"]), "text": String(d["desc"])}
