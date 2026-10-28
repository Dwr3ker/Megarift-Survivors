extends RefCounted
# Unlocks everything in a save dictionary, built from the game's own tables (used by the "everything" redeem code and by
# tools/make_test_save.gd): every Pokémon (shiny), every achievement, medal, Z-Crystal, fusion recipe, legendary and arena,
# tower floors 1-60, generous statistics and, optionally, every permanent upgrade maxed on every Pokémon.
const SV = preload("res://scripts/save_data.gd")
const PG = preload("res://scripts/progress.gd")
const MD = preload("res://scripts/moves_data.gd")
const TD = preload("res://scripts/types_data.gd")
const FUS = preload("res://scripts/fusions.gd")
const ACH = preload("res://scripts/ach.gd")

const COINS := 9999999
const COMPUTED := ["own", "shinies", "pulls", "bestMin", "bestLevel", "runs", "totalKills", "bossesTotal", "riftWins", "evoMoves", "itemsFound", "arenas", "typeVar", "legends", "leg"]


static func apply(d: Dictionary, with_upgrades: bool = true) -> void:
	SV.load_dex()
	var now: int = int(Time.get_unix_time_from_system())
	d["coins"] = maxi(int(d.get("coins", 0)), COINS)
	d["tickets"] = maxi(int(d.get("tickets", 0)), 999)
	d["tickets10"] = maxi(int(d.get("tickets10", 0)), 99)
	d["gcoins"] = maxi(int(d.get("gcoins", 0)), 999)
	d["gold_coins"] = maxi(int(d.get("gold_coins", 0)), 99)
	var legends: Dictionary = {}
	for p in SV.dex_list:
		var k := str(int(p["dex"]))
		d["owned"][k] = {"n": maxi(3, int((d["owned"].get(k, {}) as Dictionary).get("n", 0))), "shiny": true}
		if bool(p.get("leg", false)):
			legends[k] = 3
	d["legends"] = legends
	d["lshiny"] = legends.duplicate()
	var arenas: Dictionary = {}
	var types_done: Dictionary = {}
	for t in MD.TYPE_NAME.keys():
		arenas[String(t)] = 3
		types_done[String(t)] = true
	d["arenas"] = arenas
	d["type_done"] = types_done
	var fusions: Array = []
	for r in FUS.R:
		fusions.append(String(r[0]))
	d["fusions"] = fusions
	var evo: Dictionary = {}
	for id in MD.EVO.keys():
		evo[String(id)] = 1
	d["evoMoves"] = evo
	var items: Dictionary = {}
	for it in TD.ITEMS:
		items[String(it["id"])] = 1
	d["itemsFound"] = items
	var medals: Dictionary = {}
	for m in ACH.LIST:
		medals[String(m[0])] = {"prog": int(m[4]), "got": true, "claimed": true, "set": []}
	d["medals"] = medals
	var cl: Dictionary = {}
	for f in range(1, 61):
		cl[str(f)] = now
	d["tower"] = {"claimed": cl, "best": 60, "log": []}
	var st: Dictionary = d["stats"]
	var floors := {"runs": 500, "kills": 250000, "best_time": 7200, "best_level": 120, "bosses": 1500, "chests": 800, "pulls": 3000,
		"shinies": SV.dex_list.size(), "total_time": 400000, "coins_total": COINS, "rifts": 400, "dens": 50, "hyper_runs": 50,
		"hyper_best": 3600, "hyperRuns": 50, "hyperBestMin": 60, "hyperEternatus": 5, "eternatusKills": 20, "eterBestRun": 6,
		"calamityKills": 10, "judged": 1, "judgeTime": 900, "judgeBosses": 30, "towerBest": 60, "arceus": 1}
	for k in floors:
		st[k] = maxi(int(st.get(k, 0)), int(floors[k]))
	var ach: Dictionary = {}
	for a in PG.list():
		var sname: String = String(a["stat"])
		if not COMPUTED.has(sname):
			st[sname] = maxi(int(st.get(sname, 0)), int(a["goal"]) + 1)
		ach[String(a["id"])] = now
	d["ach"] = ach
	var zmis: Dictionary = {}
	for zm in PG.zlist():
		zmis[String(zm["id"])] = now
		st["zcr_" + String(zm["type"])] = 1
	d["zmis"] = zmis
	if with_upgrades:
		for p in SV.dex_list:
			var m: Dictionary = {}
			for u in SV.UPGRADES:
				m[String(u["id"])] = int(u["max"])
			d["pup"][str(int(p["dex"]))] = m
