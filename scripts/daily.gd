extends RefCounted
# Daily Challenge (Megarift's own take): every day is one of three formats, picked by the date, the same for everyone.
#   Medal Rift  - one Pokémon with two rules; score points for Bronze / Silver / Gold.
#   Draft Day   - choose 1 of 3 Pokémon, each with its own rule; same points and medals, a best score per pick.
#   Gauntlet    - one Pokémon; a new rule is added every 5 minutes (4 stages); survive 20 minutes to clear it.
# Unlimited tries, the best of the day counts. Each medal pays once per day, and a streak of days with a medal
# pays extra coins, with a purple ticket every 7th day.
const SV = preload("res://scripts/save_data.gd")

const FORMATS := ["medals", "draft", "gauntlet"]
const NAMES := {"medals": "Medal Rift", "draft": "Draft Day", "gauntlet": "Gauntlet"}
const POINTS_BOSS := 300
const POINTS_SEC := 5
const TARGETS := [3000, 8000, 15000]          # points for Bronze / Silver / Gold (Medal Rift and Draft Day)
const STAGE_T := 300.0                        # Gauntlet: a new rule every 5 minutes
const STAGES := 4
const GAUNTLET_GOLD := 1200.0                 # survive 20 minutes to clear all 4 stages
const MEDAL_NAMES := ["", "Bronze", "Silver", "Gold"]
# rules that take effect at any moment, so the Gauntlet can add them mid-run ("frail" only acts when the run starts)
const LIVE_MODS := ["fast", "horde", "tank", "hard", "nohealing", "slow", "brainy", "glass", "rich", "plague"]

# same names as the menu's modifier list (menu.gd MOD_INFO), so they share its translations
const MOD_NAME := {"fast": "Fast", "horde": "Horde", "tank": "Tough", "hard": "Heavy hitters", "frail": "Fragile", "nohealing": "No healing",
	"slow": "Heavy", "brainy": "Bright mind", "glass": "Glass cannon", "rich": "Gold rush", "plague": "Plague"}

static var pick := 0   # Draft Day: the pick chosen in the menu (0..2)


# 20261031 -> days since 1970 (so the three formats take turns day after day)
static func day_index(sd: int) -> int:
	var s := "%04d-%02d-%02d" % [sd / 10000, (sd / 100) % 100, sd % 100]
	return int(Time.get_unix_time_from_datetime_string(s) / 86400)


static func format_of(sd: int) -> String:
	return String(FORMATS[posmod(day_index(sd), FORMATS.size())])


static func _rng(sd: int, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(sd * 1000 + salt)
	return r


# n different entries of `from`, the same for every player on that day
static func _pick_n(sd: int, salt: int, from: Array, n: int) -> Array:
	var pool: Array = from.duplicate()
	var r := _rng(sd, salt)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		out.append(pool.pop_at(r.randi_range(0, pool.size() - 1)))
	return out


static func _dex_pool() -> Array:
	var pool: Array = []
	for p in SV.dex_list:
		if not bool(p.get("leg", false)) and SV.smeta.has(str(int(p["dex"]))):
			pool.append(int(p["dex"]))
	return pool if not pool.is_empty() else [25]


# Today's setup: {"fmt", "picks": [{"dex", "mods"}...]}; Medal Rift and Gauntlet have one pick, Draft Day three.
# Gauntlet's "mods" are its four stages in order.
static func setup(sd: int) -> Dictionary:
	var fmt := format_of(sd)
	var picks: Array = []
	match fmt:
		"medals":
			picks.append({"dex": SV.daily_dex(sd), "mods": _pick_n(sd, 1, SV.MOD_IDS, 2)})
		"draft":
			var dexes: Array = _pick_n(sd, 2, _dex_pool(), 3)
			var rules: Array = _pick_n(sd, 3, SV.MOD_IDS, 3)
			for i in range(dexes.size()):
				picks.append({"dex": int(dexes[i]), "mods": [String(rules[i])]})
		"gauntlet":
			picks.append({"dex": SV.daily_dex(sd), "mods": _pick_n(sd, 4, LIVE_MODS, STAGES)})
	return {"fmt": fmt, "picks": picks}


static func current_pick(sd: int) -> Dictionary:
	var st: Dictionary = setup(sd)
	var ps: Array = st["picks"]
	return ps[clampi(pick, 0, ps.size() - 1)] if String(st["fmt"]) == "draft" else ps[0]


# Rules active at the start of the run (the Gauntlet starts with its first stage only).
static func start_mods(sd: int) -> Array:
	var p: Dictionary = current_pick(sd)
	var ms: Array = p["mods"]
	return [ms[0]] if format_of(sd) == "gauntlet" else ms.duplicate()


static func points(kills: int, bosses: int, secs: float) -> int:
	return kills + POINTS_BOSS * bosses + POINTS_SEC * int(secs)


# 0 none, 1 Bronze, 2 Silver, 3 Gold
static func medal_for(fmt: String, score: int, secs: float) -> int:
	if fmt == "gauntlet":
		if secs >= GAUNTLET_GOLD:
			return 3
		if secs >= STAGE_T * 2.0:
			return 2
		if secs >= STAGE_T:
			return 1
		return 0
	var m := 0
	for i in range(TARGETS.size()):
		if score >= int(TARGETS[i]):
			m = i + 1
	return m


# The day's record (reset when the date changes).
static func state(sd: int) -> Dictionary:
	var s: Dictionary = SV.d.get("daily2", {})
	if int(s.get("date", 0)) != sd:
		var keep_streak: int = int(s.get("streak", 0))
		var keep_last: int = int(s.get("streak_date", 0))
		s = {"date": sd, "fmt": format_of(sd), "best": 0, "best_secs": 0, "picks": {}, "medal": 0, "streak": keep_streak, "streak_date": keep_last}
		SV.d["daily2"] = s
	return s


# Current streak as the player sees it today (it is broken if yesterday had no medal and today has none yet).
static func streak_now(sd: int) -> int:
	var s: Dictionary = state(sd)
	var last: int = int(s.get("streak_date", 0))
	if last == sd or (last > 0 and day_index(sd) - day_index(last) == 1):
		return int(s.get("streak", 0))
	return 0


# Records a finished daily run and pays the medals reached for the first time today.
# Returns {"score", "medal", "best", "new_best", "rewards": [text...], "tickets", "tickets10", "coins"}.
static func record(sd: int, kills: int, bosses: int, secs: float) -> Dictionary:
	var s: Dictionary = state(sd)
	var fmt: String = String(s["fmt"])
	var score: int = int(secs) if fmt == "gauntlet" else points(kills, bosses, secs)
	var medal: int = medal_for(fmt, score, secs)
	var out := {"score": score, "medal": medal, "new_best": score > int(s["best"]), "rewards": [], "tickets": 0, "tickets10": 0, "coins": 0}
	s["best"] = maxi(int(s["best"]), score)
	s["best_secs"] = maxi(int(s["best_secs"]), int(secs))
	if fmt == "draft":
		var pk: Dictionary = s["picks"]
		pk[str(pick)] = maxi(int(pk.get(str(pick), 0)), score)
	var had: int = int(s["medal"])
	if medal > had:
		for mm in range(had + 1, medal + 1):
			match mm:
				1:
					out["tickets"] = int(out["tickets"]) + 1
				2:
					out["tickets"] = int(out["tickets"]) + 3
				3:
					out["tickets10"] = int(out["tickets10"]) + 1
		if had == 0:   # first medal today: the streak grows (or starts again)
			var last: int = int(s.get("streak_date", 0))
			var st: int = int(s.get("streak", 0)) + 1 if last > 0 and day_index(sd) - day_index(last) == 1 else 1
			s["streak"] = st
			s["streak_date"] = sd
			out["coins"] = 50 * mini(st, 6)
			if st % 7 == 0:
				out["tickets10"] = int(out["tickets10"]) + 1
		s["medal"] = medal
		SV.d["tickets"] = int(SV.d["tickets"]) + int(out["tickets"])
		SV.d["tickets10"] = int(SV.d.get("tickets10", 0)) + int(out["tickets10"])
		SV.d["coins"] = int(SV.d["coins"]) + int(out["coins"])
	out["best"] = int(s["best"])
	out["streak"] = int(s.get("streak", 0))
	SV.d["daily2"] = s
	return out
