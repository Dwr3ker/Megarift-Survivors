extends RefCounted
# Misiones, logros y titulos (progress.js + achievements.js + missions.js).
# Datos en SV.d: ach{id: t}, missions{...}, evoMoves{}, itemsFound{}, title, stats.*

const SV = preload("res://scripts/save_data.gd")
const MD = preload("res://scripts/moves_data.gd")
const TD = preload("res://scripts/types_data.gd")

const CATS := [["coleccion", "Collection"], ["supervivencia", "Survival"], ["combate", "Combat"], ["tipos", "By type"],
	["grietas", "Rifts"], ["legendaries", "Legendaries"], ["regiones", "Regions"], ["modos", "Game modes"], ["otros", "Missions & more"]]

static var toasts: Array = []
static var _list: Array = []
static var _by: Dictionary = {}
static var ach_t := 0.0


# ---------------- logros ----------------
static func _a(id: String, cat: String, tier: int, name: String, desc: String, stat: String, goal: int, reward: Dictionary, title: String = "", arg = null) -> Dictionary:
	return {"id": id, "cat": cat, "tier": tier, "name": name, "desc": desc, "stat": stat, "goal": goal, "reward": reward, "title": title, "dex": 0, "arg": arg}


static func name_of(a: Dictionary) -> String:
	var n: String = L_t(String(a["name"]))
	if a["arg"] != null and String(a["name"]).contains("%"):
		return n % (L_t(a["arg"]) if a["arg"] is String else a["arg"])
	return n


static func desc_of(a: Dictionary) -> String:
	var n: String = L_t(String(a["desc"]))
	if a["arg"] != null and String(a["desc"]).contains("%"):
		return n % (L_t(a["arg"]) if a["arg"] is String else a["arg"])
	return n


static func list() -> Array:
	if not _list.is_empty():
		return _list
	SV.load_dex()
	var L2: Array = []
	var ndex: int = SV.dex_list.size()
	# colección
	L2.append(_a("own1", "coleccion", 1, "First partner", "Own 1 Pokémon.", "own", 1, {"coins": 100}))
	L2.append(_a("own10", "coleccion", 1, "Small team", "Own 10 Pokémon.", "own", 10, {"t1": 2}))
	L2.append(_a("own50", "coleccion", 2, "Collector", "Own 50 Pokémon.", "own", 50, {"t1": 5}, "Collector"))
	L2.append(_a("own100", "coleccion", 2, "A hundred friends", "Own 100 Pokémon.", "own", 100, {"t10": 1}))
	L2.append(_a("own250", "coleccion", 3, "Pokémon Master", "Own 250 Pokémon.", "own", 250, {"t10": 2}, "Pokémon Master"))
	L2.append(_a("own500", "coleccion", 3, "Encyclopedia", "Own 500 Pokémon.", "own", 500, {"t10": 3}))
	L2.append(_a("ownAll", "coleccion", 3, "Pokémon Professor", "Own all %d Pokémon in the game.", "own", ndex, {"t10": 10}, "Pokémon Professor", ndex))
	L2.append(_a("shiny1", "coleccion", 1, "Something shines", "Get 1 shiny.", "shinies", 1, {"t1": 3}, "Brilliant"))
	L2.append(_a("shiny5", "coleccion", 2, "An eye for shine", "Get 5 shinies.", "shinies", 5, {"t10": 1}))
	L2.append(_a("shiny20", "coleccion", 3, "Shiny hunter", "Get 20 shinies.", "shinies", 20, {"t10": 2}, "Shiny hunter"))
	L2.append(_a("pulls100", "coleccion", 2, "Slot machine", "Make 100 gacha pulls.", "pulls", 100, {"t10": 1}, "Lucky"))
	# supervivencia
	L2.append(_a("time5", "supervivencia", 1, "Warming up", "Survive 5 minutes.", "bestMin", 5, {"coins": 200}))
	L2.append(_a("time10", "supervivencia", 2, "Hard to beat", "Survive 10 minutes.", "bestMin", 10, {"t1": 4}))
	L2.append(_a("time15", "supervivencia", 2, "Tough", "Survive 15 minutes.", "bestMin", 15, {"t10": 1}))
	L2.append(_a("time20", "supervivencia", 3, "Survivor", "Survive 20 minutes.", "bestMin", 20, {"t10": 2}, "Survivor"))
	L2.append(_a("time30", "supervivencia", 3, "Marathon", "Survive 30 minutes.", "bestMin", 30, {"coins": 2000, "t10": 2}))
	L2.append(_a("time60", "supervivencia", 3, "To the End", "Survive 60 minutes.", "bestMin", 60, {"coins": 5000, "t10": 3}, "To the End"))
	L2.append(_a("lvl20", "supervivencia", 1, "Growing up", "Reach level 15 in a run.", "bestLevel", 15, {"t1": 2}))
	L2.append(_a("lvl40", "supervivencia", 3, "Unstoppable", "Reach level 30 in a run.", "bestLevel", 30, {"t10": 1}, "Unstoppable"))
	L2.append(_a("judge", "supervivencia", 2, "The Judgment", "Reach the Judgment of Arceus (minute 30).", "judged", 1, {"t10": 1}, "Judged"))
	L2.append(_a("judge60", "supervivencia", 3, "Before the Creator", "Survive 1 minute against Arceus.", "judgeTime", 60, {"t10": 2}, "Chosen of Arceus"))
	L2.append(_a("judgeBoss", "supervivencia", 3, "Divine challenge", "Defeat 3 legendaries against Arceus in a single run.", "judgeBosses", 3, {"t10": 2}))
	L2.append(_a("runs50", "supervivencia", 2, "Explorer", "Play 50 runs.", "runs", 50, {"t10": 1}, "Explorer"))
	# combate
	L2.append(_a("kills1k", "combate", 1, "First battles", "Defeat 1,000 Pokémon.", "totalKills", 1000, {"t1": 2}))
	L2.append(_a("kills10k", "combate", 2, "Veteran", "Defeat 10,000 Pokémon.", "totalKills", 10000, {"t10": 1}, "Veteran"))
	L2.append(_a("kills100k", "combate", 3, "Living legend", "Defeat 100,000 Pokémon.", "totalKills", 100000, {"t10": 3}, "Living legend"))
	L2.append(_a("boss1", "combate", 1, "Giant slayer", "Defeat a boss.", "bossesTotal", 1, {"t1": 2}))
	L2.append(_a("boss25", "combate", 2, "Boss hunter", "Defeat 25 bosses.", "bossesTotal", 25, {"t10": 1}, "Boss hunter"))
	L2.append(_a("boss10", "combate", 1, "Boss hunter apprentice", "Defeat 10 bosses.", "bossesTotal", 10, {"t1": 3}))
	L2.append(_a("boss100", "combate", 3, "Terror of bosses", "Defeat 100 bosses.", "bossesTotal", 100, {"t10": 2}))
	L2.append(_a("boss250", "combate", 3, "Scourge of bosses", "Defeat 250 bosses.", "bossesTotal", 250, {"t10": 3}))
	L2.append(_a("boss500", "combate", 3, "Boss executioner", "Defeat 500 bosses.", "bossesTotal", 500, {"t10": 5}, "Boss executioner"))
	L2.append(_a("boss1000", "combate", 3, "King of bosses", "Defeat 1,000 bosses.", "bossesTotal", 1000, {"t10": 10}, "King of bosses"))
	L2.append(_a("evo1", "combate", 1, "Evolution", "Evolve a move.", "evolutions", 1, {"t1": 3}))
	L2.append(_a("evo25", "combate", 2, "Evolutionist", "Evolve 25 moves.", "evolutions", 25, {"t10": 1}, "Evolutionist"))
	var evo_total: int = MD.EVO.size()
	L2.append(_a("evoAll", "combate", 3, "Move master", "Evolve all %d different moves.", "evoMoves", evo_total, {"t10": 3}, "Move master", evo_total))
	L2.append(_a("items5", "combate", 1, "Full bag", "Find 5 different items.", "itemsFound", 5, {"t1": 3}))
	L2.append(_a("itemsAll", "combate", 2, "Item collector", "Find all %d items.", "itemsFound", TD.ITEMS.size(), {"t10": 1}, "Antiquarian", TD.ITEMS.size()))
	# por tipo: Pokemon derrotados de cada tipo (los de doble tipo cuentan para los dos)
	for tk in MD.TYPE_NAME.keys():
		var tn: String = String(MD.TYPE_NAME[tk])
		L2.append(_a("tk250_" + String(tk), "tipos", 1, "%s-type tracker", "Defeat 250 %s-type Pokémon.", "tk_" + String(tk), 250, {"coins": 300, "t1": 2}, "", tn))
		L2.append(_a("tk1000_" + String(tk), "tipos", 2, "%s-type hunter", "Defeat 1,000 %s-type Pokémon.", "tk_" + String(tk), 1000, {"coins": 1000, "t1": 3, "t10": 1}, "", tn))
		L2.append(_a("tk5000_" + String(tk), "tipos", 3, "%s-type master", "Defeat 5,000 %s-type Pokémon.", "tk_" + String(tk), 5000, {"coins": 3000, "t10": 3}, "", tn))
	# grietas
	L2.append(_a("rift1", "grietas", 1, "The other side", "Win your first rift battle.", "riftWins", 1, {"t1": 3}, "Brave"))
	L2.append(_a("rift10", "grietas", 2, "Rift jumper", "Win 10 rift battles.", "riftWins", 10, {"t10": 1}))
	L2.append(_a("arenas", "grietas", 3, "Rift traveler", "Win in all 18 arenas (one per type).", "arenas", 18, {"t10": 2}, "Rift traveler"))
	# legendarios (contadores)
	var legs: Array = []
	for p in SV.dex_list:
		if bool(p.get("leg", false)) and SV.smeta.has(str(int(p["dex"]))):
			legs.append(p)
	L2.append(_a("leg10", "legendaries", 2, "Legend hunter", "Defeat 10 different legendaries.", "legends", 10, {"t10": 1}, "Legend hunter"))
	L2.append(_a("leg30", "legendaries", 3, "Myth tamer", "Defeat 30 different legendaries.", "legends", 30, {"t10": 2}))
	L2.append(_a("legAll", "legendaries", 3, "Legend", "Defeat all %d legendaries.", "legends", legs.size(), {"t10": 5}, "Legend", legs.size()))
	# misiones y mas
	L2.append(_a("mis10", "otros", 1, "Reliable", "Complete 10 missions.", "missionsDone", 10, {"t1": 3}))
	L2.append(_a("mis50", "otros", 2, "Steady", "Complete 50 missions.", "missionsDone", 50, {"t10": 1}, "Steady"))
	L2.append(_a("mis200", "otros", 3, "Tireless", "Complete 200 missions.", "missionsDone", 200, {"t10": 3}))
	L2.append(_a("group1", "otros", 1, "In good company", "Play a group game.", "groupRuns", 1, {"t1": 2}))
	L2.append(_a("group10", "otros", 2, "Loyal partner", "Play 10 group games.", "groupRuns", 10, {"t10": 1}, "Loyal partner"))
	# modos de juego (premios segun dificultad)
	L2.append(_a("daily1", "modos", 1, "Today's challenge", "Play a Daily Challenge.", "dailyPlays", 1, {"coins": 150, "t1": 2}))
	L2.append(_a("daily7", "modos", 2, "Daily routine", "Play 7 Daily Challenges.", "dailyPlays", 7, {"coins": 500, "t1": 5}))
	L2.append(_a("daily30", "modos", 3, "Loyal to the challenge", "Play 30 Daily Challenges.", "dailyPlays", 30, {"coins": 2000, "t1": 3, "t10": 2}, "Loyal to the challenge"))
	L2.append(_a("dailyMin10", "modos", 2, "Challenge cleared", "Survive 10 minutes in a Daily Challenge.", "dailyBestMin", 10, {"coins": 1000, "t10": 1}))
	L2.append(_a("dailyMin20", "modos", 3, "Champion of the day", "Survive 20 minutes in a Daily Challenge.", "dailyBestMin", 20, {"coins": 2500, "t10": 2}, "Champion of the day"))
	L2.append(_a("rush3", "modos", 1, "Boss warm-up", "Defeat 3 bosses in the Boss Rush.", "rushBest", 3, {"coins": 400, "t1": 3}))
	L2.append(_a("rush6", "modos", 2, "Boss barrage", "Defeat 6 bosses in the Boss Rush.", "rushBest", 6, {"coins": 1200, "t10": 1}))
	L2.append(_a("rush10", "modos", 3, "Boss crusher", "Defeat 10 bosses in the Boss Rush.", "rushBest", 10, {"coins": 3000, "t1": 2, "t10": 2}))
	L2.append(_a("rush15", "modos", 3, "Rush King", "Defeat 15 bosses in the Boss Rush.", "rushBest", 15, {"coins": 6000, "t1": 3, "t10": 4}, "Rush King"))
	L2.append(_a("rushRuns25", "modos", 2, "Record hunter", "Play 25 Boss Rushes.", "rushRuns", 25, {"coins": 1500, "t10": 1}))
	L2.append(_a("mod1", "modos", 1, "With a twist", "Survive 5 minutes with a modifier active.", "mn1", 5, {"coins": 300, "t1": 3}))
	L2.append(_a("mod3", "modos", 2, "Double trouble", "Survive 8 minutes with 3 modifiers.", "mn3", 8, {"coins": 1200, "t10": 1}))
	L2.append(_a("mod4", "modos", 3, "Without a net", "Survive 10 minutes with 4 modifiers.", "mn4", 10, {"coins": 3000, "t1": 2, "t10": 2}, "Without a net"))
	L2.append(_a("modAll", "modos", 3, "Masochist", "Survive 5 minutes with all 6 modifiers.", "mn6", 5, {"coins": 6000, "t1": 3, "t10": 4}, "Masochist"))
	L2.append(_a("noheal10", "modos", 2, "No heals", "Survive 10 minutes with “No healing”.", "mb_nohealing", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("frail10", "modos", 2, "Glass", "Survive 10 minutes with “Fragile”.", "mb_frail", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("horde10", "modos", 2, "Among the crowd", "Survive 10 minutes with “Horde”.", "mb_horde", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("type1", "modos", 1, "Specialist", "Survive 5 minutes in Survival by Type.", "typeBestMin", 5, {"coins": 300, "t1": 3}))
	L2.append(_a("type10", "modos", 2, "Type expert", "Survive 10 minutes in Survival by Type.", "typeBestMin", 10, {"coins": 1200, "t10": 1}))
	L2.append(_a("typeVar9", "modos", 3, "All-rounder", "Survive 10 minutes in 9 different types of Survival by Type.", "typeVar", 9, {"coins": 3000, "t1": 3, "t10": 2}))
	L2.append(_a("typeAll", "modos", 3, "Type Master", "Survive 10 minutes in all 18 types of Survival by Type.", "typeVar", 18, {"coins": 8000, "t1": 5, "t10": 5}, "Type Master"))
	L2.append(_a("team1", "modos", 1, "Better together", "Play a run in Team Mode.", "teamRuns", 1, {"coins": 150, "t1": 2}))
	L2.append(_a("team10", "modos", 2, "Perfect relay", "Survive 10 minutes in Team Mode.", "teamBestMin", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("team20", "modos", 3, "Team leader", "Survive 20 minutes in Team Mode.", "teamBestMin", 20, {"coins": 3500, "t1": 2, "t10": 2}, "Team leader"))
	L2.append(_a("hyperMin30", "modos", 2, "Fast forward", "Survive 30 minutes in Hyper mode.", "hyperBestMin", 30, {"coins": 4000, "t10": 2}))
	L2.append(_a("hyperEter", "modos", 3, "Hyper Darkest Day", "Defeat Eternatus in Hyper mode.", "hyperEternatus", 1, {"coins": 6000, "t10": 3}, "Hyper"))
	L2.append(_a("eter1", "modos", 3, "Darkest Day", "Defeat Eternatus.", "eternatusKills", 1, {"coins": 4000, "t10": 2}))
	L2.append(_a("eter2", "modos", 3, "The Return", "Defeat Eternatus 2 times in a single run.", "eterBestRun", 2, {"coins": 6000, "t10": 3}))
	L2.append(_a("eter3", "modos", 3, "Endless", "Defeat Eternatus 3 times in a single run (Doom III).", "eterBestRun", 3, {"coins": 9000, "t10": 4}, "Endless"))
	L2.append(_a("eter5", "modos", 3, "Eternal", "Defeat Eternatus 5 times in a single run (Doom V).", "eterBestRun", 5, {"coins": 15000, "t10": 6}, "Eternal"))
	L2.append(_a("cal1", "modos", 3, "Calamity Breaker", "Defeat a Mega Calamity.", "calamityKills", 1, {"coins": 3000, "t10": 2}))
	L2.append(_a("rifts3", "modos", 1, "Against the clock", "Win 3 rifts in a Rift Time Attack.", "riftsBest", 3, {"coins": 500, "t1": 3}))
	L2.append(_a("rifts5", "modos", 2, "Rift corridor", "Win 5 rifts in a Rift Time Attack.", "riftsBest", 5, {"coins": 1500, "t10": 1}))
	L2.append(_a("rifts8", "modos", 3, "Time-attack hunter", "Win 8 rifts in a Rift Time Attack.", "riftsBest", 8, {"coins": 3500, "t1": 3, "t10": 2}, "Time-attack hunter"))
	L2.append(_a("riftsRuns10", "modos", 2, "Always in a hurry", "Play 10 Rift Time Attacks.", "riftsRuns", 10, {"coins": 1500, "t10": 1}))
	L2.append(_a("tower5", "modos", 1, "First floors", "Clear floor 5 of the Tower.", "towerBest", 5, {"coins": 800, "t1": 3, "t10": 1}))
	L2.append(_a("tower10", "modos", 2, "Climbing", "Clear floor 10 of the Tower.", "towerBest", 10, {"coins": 2000, "t1": 4, "t10": 2}))
	L2.append(_a("tower15", "modos", 3, "Almost at the top", "Clear floor 15 of the Tower.", "towerBest", 15, {"coins": 4000, "t1": 5, "t10": 3}))
	L2.append(_a("tower20", "modos", 3, "Climber", "Clear floor 20 of the Tower.", "towerBest", 20, {"coins": 7000, "t1": 6, "t10": 4}, "Climber"))
	L2.append(_a("tower30", "modos", 3, "Master of the Tower", "Reach floor 30 of the Tower.", "towerBest", 29, {"coins": 15000, "t1": 10, "t10": 8}, "Master of the Tower"))
	L2.append(_a("tower60", "modos", 3, "Top of the Tower", "Reach floor 60 of the Tower.", "towerBest", 59, {"coins": 30000, "t1": 15, "t10": 12}, "Top of the Tower"))
	L2.append(_a("towerArceus", "modos", 3, "Arceus Conqueror", "Defeat Arceus, the final boss on floor 60 of the Tower.", "arceus", 1, {"coins": 30000, "t1": 15, "t10": 15}, "Arceus Conqueror"))
	L2.append(_a("towerRuns10", "modos", 2, "Tower apprentice", "Play the Tower 10 times.", "towerRuns", 10, {"coins": 1200, "t10": 1}))
	# 0.1.1 features: region maps, IVs and natures, Legend Shards, daily medals, Kecleon reservations, Max pull
	for k in range(1, SV.REGIONS.size() + 1):
		L2.append(_a("region%d" % k, "regiones", 3 if k == SV.REGIONS.size() else 2, "Champion of %s", "Defeat Arceus on the %s map.", "rclear%d" % k, 1,
			{"coins": 1000 * k, "t10": 1 + k / 3}, "", SV.REGIONS[k - 1]))
	L2.append(_a("regions3", "regiones", 2, "Region hopper", "Clear 3 region maps (defeat Arceus on each).", "regionsCleared", 3, {"coins": 3000, "t10": 2}))
	L2.append(_a("regions9", "regiones", 3, "World Champion", "Clear all 9 region maps.", "regionsCleared", 9, {"coins": 20000, "t10": 10}, "World Champion"))
	L2.append(_a("ivPerfect1", "coleccion", 2, "Perfect specimen", "Own a Pokémon with 31 in all three IVs.", "perfectIVs", 1, {"t10": 1}, "Perfectionist"))
	L2.append(_a("ivPerfect10", "coleccion", 3, "Flawless squad", "Own 10 Pokémon with 31 in all three IVs.", "perfectIVs", 10, {"t10": 3}))
	L2.append(_a("natures11", "coleccion", 2, "Nature's palette", "Unlock all 11 natures on one Pokémon.", "natureMax", 11, {"t10": 2}))
	L2.append(_a("vitamins25", "coleccion", 1, "Personal trainer", "Use 25 vitamins.", "vitamins", 25, {"t1": 5}))
	L2.append(_a("mint1", "coleccion", 1, "Fresh breath", "Buy a Mint.", "mints", 1, {"coins": 500}))
	L2.append(_a("shards5", "coleccion", 1, "Shard collector", "Earn 5 Legend Shards.", "lshardsTotal", 5, {"t1": 3}))
	L2.append(_a("shards25", "coleccion", 2, "Shard hoarder", "Earn 25 Legend Shards.", "lshardsTotal", 25, {"t10": 2}))
	L2.append(_a("legendPick1", "coleccion", 2, "Hand-picked legend", "Pick a legendary with Legend Shards.", "legendPicks", 1, {"t10": 1}))
	L2.append(_a("legendPick5", "coleccion", 3, "Legend curator", "Pick 5 legendaries with Legend Shards.", "legendPicks", 5, {"t10": 3}, "Legend curator"))
	L2.append(_a("maxPull1", "coleccion", 1, "All in", "Do a Max pull.", "maxPulls", 1, {"t1": 3}))
	L2.append(_a("dailyGold1", "modos", 2, "Golden day", "Win a Gold medal in the Daily Challenge.", "dailyGolds", 1, {"coins": 1500, "t10": 1}))
	L2.append(_a("dailyGold10", "modos", 3, "Gold standard", "Win 10 Gold medals in the Daily Challenge.", "dailyGolds", 10, {"coins": 6000, "t10": 3}, "Gold standard"))
	L2.append(_a("dailyStreak7", "modos", 2, "Week of medals", "Earn a Daily Challenge medal 7 days in a row.", "dailyStreakBest", 7, {"coins": 3000, "t10": 2}))
	L2.append(_a("reserve1", "otros", 1, "Layaway", "Reserve an item at Kecleon's shop.", "reservations", 1, {"coins": 500}))
	L2.append(_a("reserve10", "otros", 2, "Regular customer", "Reserve 10 items at Kecleon's shop.", "reservations", 10, {"t10": 1}))
	# uno por legendario
	for p in legs:
		var a: Dictionary = _a("leg_%d" % int(p["dex"]), "legendaries", 2, "Defeat %s", "Defeat %s in a rift.", "leg", 1, {"t1": 1}, "", String(p["name"]))
		a["dex"] = int(p["dex"])
		L2.append(a)
	_list = L2
	for a in _list:
		_by[String(a["id"])] = a
	return _list


static func is_multi(a: Dictionary) -> bool:
	return false   # el Modo Cooperativo ya cuenta como partida en grupo


static func stat(name: String) -> int:
	var s: Dictionary = SV.d["stats"]
	match name:
		"own":
			return SV.owned_count()
		"shinies":
			return int(s.get("shinies", 0))
		"pulls":
			return int(s.get("pulls", 0))
		"bestMin":
			return int(s.get("best_time", 0)) / 60
		"bestLevel":
			return int(s.get("best_level", 0))
		"runs":
			return int(s.get("runs", 0))
		"totalKills":
			return int(s.get("kills", 0))
		"bossesTotal":
			return int(s.get("bosses", 0))
		"riftWins":
			return int(s.get("rifts", 0))
		"evoMoves":
			return (SV.d.get("evoMoves", {}) as Dictionary).size()
		"itemsFound":
			return (SV.d.get("itemsFound", {}) as Dictionary).size()
		"arenas":
			return (SV.d.get("arenas", {}) as Dictionary).size()
		"typeVar":
			return (SV.d.get("type_done", {}) as Dictionary).size()
		"legends":
			return (SV.d.get("legends", {}) as Dictionary).size()
		"regionsCleared":
			var n := 0
			for k in range(1, SV.REGIONS.size() + 1):
				if SV.region_cleared(k):
					n += 1
			return n
		"perfectIVs", "natureMax":
			var best := 0
			var full := 0
			for key in (SV.d.get("owned", {}) as Dictionary):
				var e: Dictionary = SV.d["owned"][key]
				if e.get("iv") is Array and (e["iv"] as Array).size() == 3 and int(e["iv"][0]) >= 31 and int(e["iv"][1]) >= 31 and int(e["iv"][2]) >= 31:
					full += 1
				if e.get("nats") is Array:
					best = maxi(best, (e["nats"] as Array).size())
			return full if name == "perfectIVs" else best
	if name.begins_with("rclear"):
		return 1 if SV.region_cleared(int(name.substr(6))) else 0
	return int(s.get(name, 0))


static func value(a: Dictionary) -> int:
	if String(a["stat"]) == "leg":
		return 1 if (SV.d.get("legends", {}) as Dictionary).has(str(int(a["dex"]))) else 0
	return stat(String(a["stat"]))


static func done(a: Dictionary) -> bool:
	return (SV.d.get("ach", {}) as Dictionary).has(String(a["id"]))


static func grant(r: Dictionary) -> void:
	SV.d["coins"] = int(SV.d["coins"]) + int(r.get("coins", 0))
	SV.d["tickets"] = int(SV.d["tickets"]) + int(r.get("t1", 0))
	SV.d["tickets10"] = int(SV.d.get("tickets10", 0)) + int(r.get("t10", 0))


static var off := false   # Modo Fiesta: no cuenta para logros ni estadisticas


static func check() -> Array:
	var got: Array = []
	if off:
		return got
	if not SV.d.has("ach"):
		SV.d["ach"] = {}
	var ach: Dictionary = SV.d["ach"]
	for a in list():
		if ach.has(String(a["id"])):
			continue
		if value(a) < int(a["goal"]):
			continue
		ach[String(a["id"])] = int(Time.get_unix_time_from_system())
		grant(a["reward"])
		got.append(a)
		toasts.append({"title": "Achievement: %s!", "arg": name_of(a), "sub": "New title: %s" if String(a["title"]) != "" else "", "subarg": L_t(String(a["title"])), "tier": int(a["tier"]), "dex": int(a["dex"])})
	zcheck()
	if not got.is_empty():
		SV.save()
	return got


# ---------------- misiones de Cristales Z ----------------
# Una mision por tipo: al completarla se desbloquea el movimiento Z de ese tipo (igual que el cristal del gacha).
const ZMIS := [
	["normal", "Defeat 1,500 Pokémon in total.", "totalKills", 1500],
	["fire", "Survive 8 minutes in a run.", "bestMin", 8],
	["water", "Play 15 runs.", "runs", 15],
	["electric", "Reach level 25 in a run.", "bestLevel", 25],
	["grass", "Open 25 chests.", "chests", 25],
	["ice", "Make 30 pulls in the gacha.", "pulls", 30],
	["fighting", "Defeat 10 bosses.", "bossesTotal", 10],
	["poison", "Evolve 10 moves.", "evolutions", 10],
	["ground", "Get 30 Pokémon.", "own", 30],
	["flying", "Play 5 Daily Challenges.", "dailyPlays", 5],
	["psychic", "Find 10 different items.", "itemsFound", 10],
	["bug", "Defeat 4 bosses in Boss Rush.", "rushBest", 4],
	["rock", "Clear floor 8 of the Tower.", "towerBest", 8],
	["ghost", "Win 5 fights in rifts.", "riftWins", 5],
	["dragon", "Survive 12 minutes in a run.", "bestMin", 12],
	["dark", "Defeat 3 different legendaries.", "legends", 3],
	["steel", "Survive 8 minutes in Type Survival.", "typeBestMin", 8],
	["fairy", "Survive 8 minutes in Team Mode.", "teamBestMin", 8],
]
const ZMIS_COINS := 500


static func zlist() -> Array:
	var out: Array = []
	for z in ZMIS:
		out.append({"id": "zc_" + String(z[0]), "type": String(z[0]), "desc": String(z[1]), "stat": String(z[2]), "goal": int(z[3])})
	return out


static func zdone(zm: Dictionary) -> bool:
	return (SV.d.get("zmis", {}) as Dictionary).has(String(zm["id"])) or int((SV.d["stats"] as Dictionary).get("zcr_" + String(zm["type"]), 0)) >= 1


static func zcheck() -> void:
	if off:
		return
	if not SV.d.has("zmis"):
		SV.d["zmis"] = {}
	var ZM = load("res://scripts/zmove.gd")
	var any := false
	for zm in zlist():
		if (SV.d["zmis"] as Dictionary).has(String(zm["id"])):
			continue
		if stat(String(zm["stat"])) < int(zm["goal"]):
			continue
		var t: String = String(zm["type"])
		SV.d["zmis"][String(zm["id"])] = int(Time.get_unix_time_from_system())
		SV.d["stats"]["zcr_" + t] = 1
		SV.d["coins"] = int(SV.d["coins"]) + ZMIS_COINS
		toasts.append({"title": "Z-Crystal: %s!", "arg": String(ZM.DEF[t]["name"]), "sub": "", "subarg": "", "tier": 3, "dex": 0})
		any = true
	if any:
		SV.save()


static func titles() -> Array:
	var out: Array = []
	var ach: Dictionary = SV.d.get("ach", {})
	for a in list():
		if String(a["title"]) != "" and ach.has(String(a["id"])):
			out.append(String(a["title"]))
	return out


# ---------------- misiones ----------------
const DAILY := [
	{"id": "kill", "ev": "kill", "goals": [300, 500, 800], "reward": {"t1": 2, "coins": 150}},
	{"id": "killType", "ev": "kill", "param": "type", "goals": [30, 50, 80], "reward": {"t1": 2, "coins": 200}},
	{"id": "survive", "ev": "runEnd", "mode": "max", "val": "min", "goals": [5, 7, 9], "reward": {"t1": 3, "coins": 200}},
	{"id": "level", "ev": "runEnd", "mode": "max", "val": "level", "goals": [8, 12, 15], "reward": {"t1": 2, "coins": 200}},
	{"id": "boss", "ev": "kill", "match": "boss", "goals": [1, 2], "reward": {"t1": 3, "coins": 250}},
	{"id": "chest", "ev": "chest", "goals": [1, 2], "reward": {"t1": 2, "coins": 200}},
	{"id": "coins", "ev": "runEnd", "val": "coins", "goals": [100, 200, 300], "reward": {"t1": 2, "coins": 150}},
	{"id": "playType", "ev": "runEnd", "param": "type", "mode": "max", "val": "min", "goals": [3], "reward": {"t1": 3, "coins": 200}},
	{"id": "item", "ev": "item", "goals": [1], "reward": {"t1": 2, "coins": 150}},
	{"id": "evolve", "ev": "evolve", "goals": [1], "reward": {"t1": 3, "coins": 250}},
	{"id": "mDaily", "ev": "runEnd", "req": "daily", "goals": [1], "reward": {"t1": 3, "coins": 250}},
	{"id": "mRush", "ev": "runEnd", "req": "rush", "mode": "max", "val": "bosses", "goals": [2, 4], "reward": {"t1": 3, "coins": 300}},
	{"id": "mMods", "ev": "runEnd", "req": "mods1", "mode": "max", "val": "min", "goals": [4, 6], "reward": {"t1": 3, "coins": 300}},
	{"id": "mType", "ev": "runEnd", "req": "type", "mode": "max", "val": "min", "goals": [4, 6], "reward": {"t1": 3, "coins": 300}},
	{"id": "mTeam", "ev": "runEnd", "req": "team", "mode": "max", "val": "min", "goals": [5, 8], "reward": {"t1": 3, "coins": 300}},
	{"id": "mTower", "ev": "runEnd", "req": "tower", "mode": "max", "val": "floor", "goals": [2, 3], "reward": {"t1": 3, "coins": 350}},
	{"id": "mRifts", "ev": "runEnd", "req": "rifts", "mode": "max", "val": "rifts", "goals": [2, 3], "reward": {"t1": 3, "coins": 350}},
]
const WEEKLY := [
	{"id": "wkill", "ev": "kill", "goals": [4000, 6000], "reward": {"t10": 1, "coins": 800}},
	{"id": "wrift", "ev": "rift", "goals": [1, 2], "reward": {"t10": 1, "coins": 1000}},
	{"id": "wboss", "ev": "kill", "match": "boss", "goals": [4, 6], "reward": {"t10": 1, "coins": 900}},
	{"id": "wsurvive", "ev": "runEnd", "mode": "max", "val": "min", "goals": [12, 15], "reward": {"t10": 1, "coins": 1000}},
	{"id": "wevolve", "ev": "evolve", "goals": [3, 5], "reward": {"t10": 1, "coins": 900}},
	{"id": "wdaily", "ev": "missionDone", "match": "daily", "goals": [8, 12], "reward": {"t10": 1, "coins": 800}},
	{"id": "wDailyCh", "ev": "runEnd", "req": "daily", "goals": [3, 5], "reward": {"t1": 3, "t10": 1, "coins": 1000}},
	{"id": "wRush", "ev": "runEnd", "req": "rush", "mode": "max", "val": "bosses", "goals": [6, 9], "reward": {"t1": 3, "t10": 1, "coins": 1100}},
	{"id": "wType", "ev": "runEnd", "req": "type", "mode": "max", "val": "min", "goals": [8, 12], "reward": {"t1": 3, "t10": 1, "coins": 1100}},
	{"id": "wTeam", "ev": "runEnd", "req": "team", "mode": "max", "val": "min", "goals": [10, 15], "reward": {"t1": 3, "t10": 1, "coins": 1200}},
	{"id": "wTower", "ev": "runEnd", "req": "tower", "mode": "max", "val": "floor", "goals": [6, 9], "reward": {"t1": 4, "t10": 1, "coins": 1300}},
	{"id": "wRifts", "ev": "runEnd", "req": "rifts", "mode": "max", "val": "rifts", "goals": [5, 7], "reward": {"t1": 4, "t10": 1, "coins": 1300}},
	{"id": "wMods", "ev": "runEnd", "req": "mods3", "mode": "max", "val": "min", "goals": [6, 8], "reward": {"t1": 3, "t10": 1, "coins": 1200}},
]


static func def_of(id: String) -> Dictionary:
	for d in DAILY:
		if String(d["id"]) == id:
			return d
	for d in WEEKLY:
		if String(d["id"]) == id:
			return d
	return {}


static func mission_text(m: Dictionary) -> String:
	var n: int = int(m["goal"])
	var tn: String = String(MD.TYPE_NAME.get(String(m.get("param", "")), ""))
	var nn: String = _thousands(n)
	match String(m["id"]):
		"kill", "wkill":
			return L_t("Defeat %s Pokémon") % nn
		"killType":
			return L_t("Defeat %s %s-type Pokémon") % [nn, L_t(tn)]
		"survive", "wsurvive":
			return L_t("Survive %s minutes in a run") % nn
		"level":
			return L_t("Reach level %s in a run") % nn
		"boss":
			return L_t("Defeat a boss") if n == 1 else L_t("Defeat %s bosses") % nn
		"wboss":
			return L_t("Defeat %s bosses") % nn
		"chest":
			return L_t("Open a locked chest") if n == 1 else L_t("Open %s locked chests") % nn
		"coins":
			return L_t("Collect %s coins in your runs") % nn
		"playType":
			return L_t("Survive %s minutes with a %s-type Pokémon") % [nn, L_t(tn)]
		"item":
			return L_t("Find a held item")
		"evolve":
			return L_t("Evolve a move")
		"wrift":
			return L_t("Win a rift battle") if n == 1 else L_t("Win %s rift fights") % nn
		"wevolve":
			return L_t("Evolve %s moves") % nn
		"wdaily":
			return L_t("Complete %s daily missions") % nn
		"mDaily":
			return L_t("Play the Daily Challenge")
		"mRush":
			return L_t("Defeat %s bosses in the Boss Rush") % nn
		"mMods":
			return L_t("Survive %s minutes with any modifier active") % nn
		"wDailyCh":
			return L_t("Play %s Daily Challenges") % nn
		"wRush":
			return L_t("Defeat %s bosses in a single Boss Rush run") % nn
		"mType":
			return L_t("Survive %s minutes in Survival by Type") % nn
		"mTeam":
			return L_t("Survive %s minutes in Team Mode") % nn
		"mTower":
			return L_t("Clear %s floors of the Tower") % nn
		"wTower":
			return L_t("Clear %s floors of the Tower in a single run") % nn
		"mRifts":
			return L_t("Win %s rifts in the Rift Time Attack") % nn
		"wType":
			return L_t("Survive %s minutes in Survival by Type") % nn
		"wTeam":
			return L_t("Survive %s minutes in Team Mode") % nn
		"wRifts":
			return L_t("Win %s rifts in a single Rift Time Attack") % nn
		"wMods":
			return L_t("Survive %s minutes with 3 or more modifiers") % nn
	return String(m["id"])


static func L_t(s: String) -> String:
	var L = load("res://scripts/lang.gd")
	return L.t(s)


static func _thousands(n: int) -> String:
	var s: String = str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return out


# Fecha en Espana (UTC+1, +2 en verano).
static func _last_sunday(year: int, month: int) -> int:
	var d: int = 31 if month != 4 and month != 6 and month != 9 and month != 11 else 30
	while true:
		var t: int = int(Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": d, "hour": 1, "minute": 0, "second": 0}))
		var wd: int = int(Time.get_datetime_dict_from_unix_time(t)["weekday"])
		if wd == 0:
			return t
		d -= 1
	return 0


# Reloj unico del juego: hora de Puerto Rico (UTC-4 todo el ano, sin horario de verano).
static func pr_now() -> int:
	return int(Time.get_unix_time_from_system()) - 4 * 3600


static func madrid_now() -> int:
	return pr_now()


static func period_ids() -> Dictionary:
	var t: int = madrid_now()
	var dd: Dictionary = Time.get_datetime_dict_from_unix_time(t)
	var day: String = "%04d-%02d-%02d" % [int(dd["year"]), int(dd["month"]), int(dd["day"])]
	var wd: int = (int(dd["weekday"]) + 6) % 7      # lunes = 0
	var mon: Dictionary = Time.get_datetime_dict_from_unix_time(t - wd * 86400)
	var week: String = "%04d-%02d-%02d" % [int(mon["year"]), int(mon["month"]), int(mon["day"])]
	return {"d": day, "w": week}


static func _rng_state(seed_str: String) -> int:
	var h: int = 2166136261
	for i in range(seed_str.length()):
		h = (h ^ seed_str.unicode_at(i)) & 0xFFFFFFFF
		h = (h * 16777619) & 0xFFFFFFFF
	return h


static func _rand(st: Array) -> float:
	st[0] = (int(st[0]) + 0x6D2B79F5) & 0xFFFFFFFF
	var t: int = int(st[0])
	t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF
	t = (t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF)) & 0xFFFFFFFF
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


static func _make(def: Dictionary, st: Array) -> Dictionary:
	var goals: Array = def["goals"]
	var goal: int = int(goals[int(_rand(st) * goals.size())])
	var param := ""
	if String(def.get("param", "")) == "type":
		var keys: Array = MD.TYPE_NAME.keys()
		param = String(keys[int(_rand(st) * keys.size())])
	return {"id": String(def["id"]), "goal": goal, "param": param, "prog": 0, "claimed": false, "told": false}


static func _pick_set(defs: Array, n: int, st: Array, avoid: Array = []) -> Array:
	var pool: Array = []
	for d in defs:
		if not avoid.has(String(d["id"])):
			pool.append(d)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var i: int = int(_rand(st) * pool.size())
		var d: Dictionary = pool[i]
		pool.remove_at(i)
		out.append(_make(d, st))
	return out


static var ens_t := -100.0


static func ensure() -> void:
	var nowt: float = Time.get_ticks_msec() / 1000.0
	if nowt - ens_t < 5.0 and SV.d.has("missions"):
		return
	ens_t = nowt
	if not SV.d.has("missions"):
		SV.d["missions"] = {}
	var M: Dictionary = SV.d["missions"]
	var ids: Dictionary = period_ids()
	var key: String = str(int(SV.d.get("created", 0)))
	if String(M.get("day", "")) != String(ids["d"]):
		M["day"] = ids["d"]
		M["rerolled"] = false
		M["daily"] = _pick_set(DAILY, 3, [_rng_state(String(ids["d"]) + key)])
	if String(M.get("week", "")) != String(ids["w"]):
		M["week"] = ids["w"]
		M["weekly"] = _pick_set(WEEKLY, 2, [_rng_state(String(ids["w"]) + key)])


static func m_done(m: Dictionary) -> bool:
	return int(m["prog"]) >= int(m["goal"])


static func _advance(lst: Array, kind: String, d: Dictionary) -> void:
	for m in lst:
		if bool(m["claimed"]) or m_done(m):
			continue
		var def: Dictionary = def_of(String(m["id"]))
		if def.is_empty() or String(def["ev"]) != kind:
			continue
		var mt: String = String(def.get("match", ""))
		if mt == "boss" and not bool(d.get("boss", false)):
			continue
		if mt == "daily" and not bool(d.get("daily", false)):
			continue
		var rq: String = String(def.get("req", ""))
		if rq != "":
			var md: String = String(d.get("mode", "normal"))
			var nm: int = int(d.get("nmods", 0))
			if (rq in ["daily", "rush", "type", "team", "rifts", "tower"] and md != rq) or (rq == "mods1" and nm < 1) or (rq == "mods3" and nm < 3):
				continue
		if String(def.get("param", "")) == "type":
			var types: Array = d.get("types", [])
			if not types.has(String(m["param"])):
				continue
		var v: int = 1
		match String(def.get("val", "")):
			"min":
				v = int(float(d.get("time", 0.0)) / 60.0)
			"level":
				v = int(d.get("level", 0))
			"coins":
				v = int(d.get("coins", 0))
			"bosses":
				v = int(d.get("bosses", 0))
			"rifts":
				v = int(d.get("rifts", 0))
			"floor":
				v = int(d.get("floor", 0))
		if String(def.get("mode", "")) == "max":
			m["prog"] = maxi(int(m["prog"]), v)
		else:
			m["prog"] = int(m["prog"]) + v
		if m_done(m) and not bool(m["told"]):
			m["told"] = true
			toasts.append({"title": "Mission complete: %s", "arg": mission_text(m), "sub": "Claim your reward in Missions", "subarg": "", "tier": 2, "dex": 0})
			SV.save()


static func claim(m: Dictionary, weekly: bool) -> bool:
	if bool(m["claimed"]) or not m_done(m):
		return false
	m["claimed"] = true
	grant(def_of(String(m["id"]))["reward"])
	var s: Dictionary = SV.d["stats"]
	s["missionsDone"] = int(s.get("missionsDone", 0)) + 1
	SV.save()
	event("missionDone", {"daily": not weekly})
	return true


static func reroll(i: int) -> bool:
	ensure()
	var M: Dictionary = SV.d["missions"]
	var dl: Array = M["daily"]
	if i < 0 or i >= dl.size() or bool(M.get("rerolled", false)) or bool(dl[i]["claimed"]):
		return false
	var avoid: Array = []
	for x in dl:
		avoid.append(String(x["id"]))
	var st: Array = [_rng_state(String(M["day"]) + "cambio" + str(Time.get_ticks_usec()))]
	var n: Array = _pick_set(DAILY, 1, st, avoid)
	if n.is_empty():
		return false
	dl[i] = n[0]
	M["rerolled"] = true
	SV.save()
	return true


static func pending() -> int:
	ensure()
	var M: Dictionary = SV.d["missions"]
	var c := 0
	for m in (M["daily"] as Array) + (M["weekly"] as Array):
		if m_done(m) and not bool(m["claimed"]):
			c += 1
	return c


static func event(kind: String, d: Dictionary = {}) -> void:
	if off:
		return
	ensure()
	var s: Dictionary = SV.d["stats"]
	match kind:
		"evolve":
			s["evolutions"] = int(s.get("evolutions", 0)) + 1
			var em: Dictionary = SV.d.get("evoMoves", {})
			if not em.has(String(d.get("move", ""))):
				em[String(d.get("move", ""))] = int(Time.get_unix_time_from_system())
			SV.d["evoMoves"] = em
		"kill":
			for tkt in d.get("types", []):
				var tkk: String = "tk_" + String(tkt)
				s[tkk] = int(s.get(tkk, 0)) + 1
		"item":
			var it: Dictionary = SV.d.get("itemsFound", {})
			if not it.has(String(d.get("id", ""))):
				it[String(d.get("id", ""))] = int(Time.get_unix_time_from_system())
			SV.d["itemsFound"] = it
	var M: Dictionary = SV.d["missions"]
	_advance(M["daily"], kind, d)
	_advance(M["weekly"], kind, d)
	if kind != "kill" or bool(d.get("boss", false)) or int(d.get("legend", 0)) > 0:
		check()
	elif Time.get_ticks_msec() / 1000.0 - ach_t > 1.0:
		ach_t = Time.get_ticks_msec() / 1000.0
		check()
