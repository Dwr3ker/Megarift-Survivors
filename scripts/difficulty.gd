extends RefCounted
# Difficulty (docs/difficulty.md): Normal, Hard and Nightmare for Normal runs, stacking with Hyper.
# The chosen one is SV.d["difficulty"]; the run's is SV.run_diff (set when a Normal run starts or resumes).
const SV = preload("res://scripts/save_data.gd")

const IDS := ["normal", "hard", "nightmare"]
const NAME := {"normal": "Normal", "hard": "Hard", "nightmare": "Nightmare"}
const COLOR := {"normal": Color("#6fd08a"), "hard": Color("#ff9a3d"), "nightmare": Color("#c04cff")}
# hp / dmg / spd: enemy multipliers. elite_from: run minute from which elites can appear, elite_min: their least chance.
# alpha / event: how much more often (the gap is divided by it). coins / xp / egg: reward multipliers.
# ticket_every: one extra ticket per this many minutes survived (0 = none).
const K := {
	"normal": {"hp": 1.0, "dmg": 1.0, "spd": 1.0, "elite_from": 20.0, "elite_min": 0.0, "alpha": 1.0, "event": 1.0, "coins": 1.0, "xp": 1.0, "egg": 1.0, "ticket_every": 0},
	"hard": {"hp": 1.5, "dmg": 1.35, "spd": 1.08, "elite_from": 10.0, "elite_min": 0.04, "alpha": 1.25, "event": 1.15, "coins": 1.5, "xp": 1.15, "egg": 1.25, "ticket_every": 10},
	"nightmare": {"hp": 2.2, "dmg": 1.7, "spd": 1.15, "elite_from": 3.0, "elite_min": 0.08, "alpha": 1.5, "event": 1.3, "coins": 2.25, "xp": 1.3, "egg": 1.5, "ticket_every": 5},
}
const UNLOCK_MIN := 30   # Nightmare: reach minute 30 of a Hard run (game time, so 15 real minutes with Hyper)


static func valid(id: String) -> String:
	return id if K.has(id) else "normal"


static func k(id: String, key: String) -> float:
	return float(K[valid(id)][key])


static func chosen() -> String:
	SV.ensure()
	var id: String = valid(String(SV.d.get("difficulty", "normal")))
	return id if unlocked(id) else "normal"


static func choose(id: String) -> bool:
	if not unlocked(id):
		return false
	SV.d["difficulty"] = valid(id)
	return true


static func unlocked(id: String) -> bool:
	if id != "nightmare":
		return K.has(id)
	return int(SV.d.get("stats", {}).get("hardBestMin", 0)) >= UNLOCK_MIN


# Best time (seconds) per difficulty, with or without Hyper. Normal keeps the old records (best_time, hyper_best).
static func rec_key(id: String, hyper: bool) -> String:
	if valid(id) == "normal":
		return "hyper_best" if hyper else "best_time"
	return "best_%s%s" % [valid(id), "_hyper" if hyper else ""]


static func best(id: String, hyper: bool) -> int:
	return int(SV.d.get("stats", {}).get(rec_key(id, hyper), 0))


# Run end: the extra tickets for minutes survived (real minutes).
static func bonus_tickets(id: String, real_secs: float) -> int:
	var every: int = int(K[valid(id)]["ticket_every"])
	return 0 if every <= 0 else int(real_secs / (60.0 * every))
