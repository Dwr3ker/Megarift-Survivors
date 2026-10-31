extends RefCounted
# In-run Pokémon evolution (Charmander -> Charmeleon -> Charizard) and the two ways to start a run.
#
# The line a Pokémon belongs to comes from data/evolutions.json (PokéAPI chains): stage (1..n), n (stages in the line) and
# the species it evolves into. A level-up card offers the evolution once the Pokémon reaches the level for its stage.
#
# Starting UNEVOLVED has a weak early game (the first stage's own stats) but each evolution brings the next stage's stats,
# a full heal and an EVOLUTION SURGE (permanent damage, HP and speed bonus). Completing the line is worth SURGE_* in total.
# Starting FULLY EVOLVED (or with no evolution line at all) has the final stats from minute 0 and gains SEASONED: a bonus that
# grows with the Pokémon's level up to SEAS_SHARE of the surge (80%), so the late-game gap is small (a few percent) while the
# early game belongs to the evolved start. A Pokémon that starts in the middle of a line gets a matching share of each.
# Mega Evolution, Primal Reversion and Crowned forms still need the run to START as that Pokémon, so an evolved starter keeps
# something the in-run line does not.
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

# Total bonus for completing the whole line in a run.
const SURGE_DMG := 0.12
const SURGE_HP := 0.15
const SURGE_SPD := 0.05
# Fully evolved starts approach this share of the surge by SEAS_LEVEL (80%: the unevolved start ends about 5% ahead).
const SEAS_SHARE := 0.8
const SEAS_LEVEL := 50
# Level at which the card for each step appears: [stages in the line][stage the Pokémon is at now]
const LEVELS := {2: {1: 20}, 3: {1: 16, 2: 34}}
const ANIM_S := 2.4
const COLOR := Color("#ffd65c")

static var _data: Dictionary = {}


static func _load() -> void:
	if not _data.is_empty():
		return
	var f := FileAccess.open("res://data/evolutions.json", FileAccess.READ)
	if f == null:
		return
	var js = JSON.parse_string(f.get_as_text())
	if js is Dictionary:
		_data = js


static func info(dex: int) -> Dictionary:
	_load()
	return _data.get(str(dex), {})


static func stage_of(dex: int) -> int:
	return int(info(dex).get("stage", 1))


static func line_len(dex: int) -> int:
	return int(info(dex).get("n", 1))


# Pokémon that can still evolve (with the species it can become).
static func evolves_to(dex: int) -> Array:
	var out: Array = []
	for c in (info(dex).get("to", []) as Array):
		out.append(int(c))   # JSON numbers load as floats
	return out


# Level the evolution card appears at for this Pokémon (0 = it cannot evolve).
static func level_for(dex: int) -> int:
	var inf: Dictionary = info(dex)
	if inf.is_empty() or (inf["to"] as Array).is_empty():
		return 0
	return int(LEVELS.get(int(inf["n"]), {}).get(int(inf["stage"]), 0))


# Share of the whole line a starting Pokémon has already "completed" (0 for a first stage, 1 for the last stage or a single one).
static func start_progress(dex: int) -> float:
	var n: int = line_len(dex)
	if n <= 1:
		return 1.0
	return float(stage_of(dex) - 1) / float(n - 1)


# Fraction of the surge ONE evolution step gives in this line.
static func step_share(dex: int) -> float:
	var n: int = line_len(dex)
	return 1.0 / float(maxi(1, n - 1))


# Seasoned bonus (damage, hp, speed) of a run that started as `start_dex`, at player level `level`.
static func seasoned(start_dex: int, level: int) -> Dictionary:
	var k: float = SEAS_SHARE * start_progress(start_dex) * clampf(float(level) / float(SEAS_LEVEL), 0.0, 1.0)
	return {"dmg": SURGE_DMG * k, "hp": SURGE_HP * k, "spd": SURGE_SPD * k}


# ---------------------------------------------------------------- the card
static func card(main) -> Dictionary:
	if main.mode == "team" or main.mode == "tower" or main.player.dead or main.banned.has("evolve"):
		return {}
	var cur: int = int(main._cur_dex())
	var need: int = level_for(cur)
	if need <= 0 or main.player.level < need:
		return {}
	var targets: Array = _available(main, cur)
	if targets.is_empty():
		return {}
	var one: String = L.t(String(main._dex_by[int(targets[0])]["name"])) if targets.size() == 1 else ""
	return {"cat": "evolve", "id": "evolve", "key": "evolve", "w": 1.0, "title": L.t("Evolution"),
		"desc": (L.t("%s evolves into %s: new stats, a full heal and a permanent bonus.") % [L.t(String(main._dex_by[cur]["name"])), one]) if targets.size() == 1 else L.t("Your Pokémon is ready to evolve: choose its next form."),
		"icon": "star", "tag": L.t("UNIQUE"), "color": COLOR}


static func _available(main, cur: int) -> Array:
	var out: Array = []
	for c in evolves_to(cur):
		if main._dex_by.has(int(c)) and main._smeta.has(str(int(c))):
			out.append(int(c))
	return out


static func picks(main) -> Array:
	var out: Array = []
	var cur: int = int(main._cur_dex())
	var share: float = step_share(cur)
	for c in _available(main, cur):
		var p: Dictionary = main._dex_by[int(c)]
		out.append({"cat": "evolvepick", "id": str(int(c)), "key": "evolve:%d" % int(c), "w": 1.0, "title": L.t(String(p["name"])),
			"desc": L.t("+%d%% damage, +%d%% HP, +%d%% speed for good, and a full heal.") % [roundi(SURGE_DMG * share * 100.0), roundi(SURGE_HP * share * 100.0), roundi(SURGE_SPD * share * 100.0)],
			"icon": "star", "tag": L.t("Evolution"), "color": COLOR})
	return out


# ---------------------------------------------------------------- applying it
# Rebuilds the body and the numbers for species `dex`. `restore` (resuming a saved run) only rebuilds the body.
# `say` = false when the evolution scene (evo_cine.gd) shows its own message.
static func apply(main, dex: int, restore: bool = false, say: bool = true) -> void:
	if not main._dex_by.has(dex) or not main._smeta.has(str(dex)):
		return
	var p = main.player
	var from: int = int(main._cur_dex())
	var st: Dictionary = main._dex_by[dex]
	p.rebody(dex, main._sm(dex), bool(p.shiny))
	main.cur_dex = dex
	main.ab_fx = main.AB.fx_of(dex)
	main.hud.poke_name = L.t(String(st["name"]))
	main.hud.icon_tex = main._hud_icon(dex)
	if restore:
		return
	var old: Dictionary = main._dex_by[from]
	# the base stats become the new species' (stat cards and perks stay on top)
	var perks: Dictionary = main.perks
	var hp_new: float = float(st["hp"]) + float(perks["hp"])
	var hp_old: float = float(old["hp"]) + float(perks["hp"])
	var share: float = step_share(from)
	var gain: float = hp_new - hp_old
	p.max_hp = roundf((p.max_hp + gain) * (1.0 + SURGE_HP * share))
	p.hp = p.max_hp   # a full heal
	main.base_spd = float(st["spd"]) * float(perks["spd"])
	main.base_atk = float(st["atk"]) * float(perks["atk"])
	p.spd = float(st["spd"])
	p.atk = float(st["atk"])
	p.types = (st["types"] as Array).duplicate()
	main.evo_dmg += SURGE_DMG * share
	main.evo_spd += SURGE_SPD * share
	main.evo_steps += 1
	var col: Color = COLOR
	p.invuln = maxf(p.invuln, ANIM_S)
	p.flash = 1.0
	main.shake = maxf(main.shake, 7.0)
	Aud.sfx("legend")
	main._ring(p.position, 10.0, 320.0, col, 0.7, 6.0)
	main._ring(p.position, 10.0, 200.0, Color.WHITE, 0.5, 4.0)
	main.pfx.burst(p.position, col, 30, 260.0)
	if say:
		main.add_text(p.position + Vector2(0.0, -p.body_h - 24.0), L.t(String(st["name"])), col, 28)
		main._say(L.t("%s evolved into %s!") % [L.t(String(old["name"])), L.t(String(st["name"]))], 3.4)


# Seasoned bonus: refreshes the damage / speed multipliers and keeps max HP in step with the player's level
# (called every frame; it only acts when the level changed).
static func tick(main) -> void:
	if main.player == null or main.player.dead:
		return
	var lv: int = int(main.player.level)
	if lv == main.seas_level_seen:
		return
	main.seas_level_seen = lv
	var s: Dictionary = seasoned(int(main._pdex()), lv)
	main.seas_dmg = float(s["dmg"])
	main.seas_spd = float(s["spd"])
	var target: float = float(s["hp"])
	if target > main.seas_hp_done + 0.0001:
		var k: float = (1.0 + target) / (1.0 + main.seas_hp_done)
		main.player.max_hp = roundf(main.player.max_hp * k)
		main.player.hp = minf(main.player.max_hp, roundf(main.player.hp * k))
		main.seas_hp_done = target
