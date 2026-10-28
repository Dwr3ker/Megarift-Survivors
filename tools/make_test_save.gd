extends SceneTree
# Builds a "everything unlocked" save for testing, from the game's own data tables, and checks that the game accepts it.
#   godot --headless --path . --script res://tools/make_test_save.gd
# Environment: OUT_DIR (default: the current directory). Writes:
#   megarift_test_save.json        full save (every Pokémon, every upgrade maxed on every Pokémon): drop in as save.json (PC)
#   megarift_test_save_lite.json   same without the per-Pokémon upgrades (small enough to paste on a phone)
#   megarift_test_save_code.txt    the lite save as an in-game "Paste save code" string
# It never touches your real save: it builds the data in memory and only reads the game's tables.

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	var PG = load("res://scripts/progress.gd")
	var MD = load("res://scripts/moves_data.gd")
	var TD = load("res://scripts/types_data.gd")
	var FUS = load("res://scripts/fusions.gd")
	var ACH = load("res://scripts/ach.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.load_dex()
	var now: int = int(Time.get_unix_time_from_system())
	var d: Dictionary = SV.default_data()
	d["coins"] = 9999999
	d["tickets"] = 999
	d["tickets10"] = 99
	d["gcoins"] = 999
	d["gold_coins"] = 99
	d["notes_seen"] = String(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	# every Pokémon, shiny
	var legends: Dictionary = {}
	for p in SV.dex_list:
		var k := str(int(p["dex"]))
		d["owned"][k] = {"n": 3, "shiny": true}
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
	# medals
	var medals: Dictionary = {}
	for m in ACH.LIST:
		medals[String(m[0])] = {"prog": int(m[4]), "got": true, "claimed": true, "set": []}
	d["medals"] = medals
	# tower floors
	var cl: Dictionary = {}
	for f in range(1, 61):
		cl[str(f)] = now
	d["tower"] = {"claimed": cl, "best": 60, "log": []}
	# statistics: generous values, then raise every stat an achievement counts to its goal
	var st: Dictionary = d["stats"]
	st["runs"] = 500
	st["kills"] = 250000
	st["best_time"] = 7200
	st["best_level"] = 120
	st["bosses"] = 1500
	st["chests"] = 800
	st["pulls"] = 3000
	st["shinies"] = SV.dex_list.size()
	st["total_time"] = 400000
	st["coins_total"] = 9999999
	st["rifts"] = 400
	st["dens"] = 50
	st["hyper_runs"] = 50
	st["hyper_best"] = 3600
	st["hyperRuns"] = 50
	st["hyperBestMin"] = 60
	st["hyperEternatus"] = 5
	st["eternatusKills"] = 20
	st["eterBestRun"] = 6
	st["calamityKills"] = 10
	st["judged"] = 1
	st["judgeTime"] = 900
	st["judgeBosses"] = 30
	st["towerBest"] = 60
	st["arceus"] = 1
	var computed := ["own", "shinies", "pulls", "bestMin", "bestLevel", "runs", "totalKills", "bossesTotal", "riftWins", "evoMoves", "itemsFound", "arenas", "typeVar", "legends", "leg"]
	SV.d = d
	for a in PG.list():
		var sname: String = String(a["stat"])
		if not computed.has(sname):
			st[sname] = maxi(int(st.get(sname, 0)), int(a["goal"]) + 1)
	var ach: Dictionary = {}
	for a in PG.list():
		ach[String(a["id"])] = now
	d["ach"] = ach
	var zmis: Dictionary = {}
	for zm in PG.zlist():
		zmis[String(zm["id"])] = now
		st["zcr_" + String(zm["type"])] = 1
	d["zmis"] = zmis
	# lite = no per-Pokémon upgrades
	var lite: Dictionary = d.duplicate(true)
	# full = every upgrade at its maximum on every Pokémon
	for p in SV.dex_list:
		var m: Dictionary = {}
		for u in SV.UPGRADES:
			m[String(u["id"])] = int(u["max"])
		d["pup"][str(int(p["dex"]))] = m
	# validation: the game's own import path must accept the code, and the numbers must add up
	var ok := true
	for variant in [["full", d], ["lite", lite]]:
		var code: String = Marshalls.utf8_to_base64(JSON.stringify(variant[1]))
		var parsed = JSON.parse_string(Marshalls.base64_to_utf8(code))
		var merged: Dictionary = SV._merge(SV.default_data(), parsed)
		SV.d = merged
		var n_own: int = SV.owned_count()
		var all_done := true
		for a in PG.list():
			if not (SV.d["ach"] as Dictionary).has(String(a["id"])):
				all_done = false
		var unmet := 0
		for a in PG.list():
			if PG.value(a) < int(a["goal"]):
				unmet += 1
				print("  unmet: ", a["id"], " stat=", a["stat"], " value=", PG.value(a), " goal=", a["goal"])
		var up_ok: bool = variant[0] == "lite" or SV.up_level("hp", 25) == 10
		print("%-5s code=%d chars  owned=%d/%d  achievements all marked=%s  goals not met by stats=%d  upgrades ok=%s" % [variant[0], code.length(), n_own, SV.dex_list.size(), str(all_done), unmet, str(up_ok)])
		if n_own != SV.dex_list.size() or not all_done or not up_ok:
			ok = false
	var out_dir: String = OS.get_environment("OUT_DIR") if OS.get_environment("OUT_DIR") != "" else "."
	DirAccess.make_dir_recursive_absolute(out_dir)
	var full_txt: String = JSON.stringify(d)
	var lite_txt: String = JSON.stringify(lite)
	FileAccess.open(out_dir + "/megarift_test_save.json", FileAccess.WRITE).store_string(full_txt)
	FileAccess.open(out_dir + "/megarift_test_save_lite.json", FileAccess.WRITE).store_string(lite_txt)
	FileAccess.open(out_dir + "/megarift_test_save_code.txt", FileAccess.WRITE).store_string(Marshalls.utf8_to_base64(lite_txt))
	print("wrote files to ", out_dir, "  full=", full_txt.length(), " bytes  lite=", lite_txt.length(), " bytes")
	SV.d = _guard   # the real save is untouched (nothing here calls save())
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
