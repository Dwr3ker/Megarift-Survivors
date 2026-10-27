extends SceneTree
# Headless Hyper-mode check. The save is snapshotted first and restored (and re-saved) at the end.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func make_run(SV, hyper: bool):
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = hyper
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	return m

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var snap: Dictionary = SV.d.duplicate(true)
	var res := {}
	for hy in [false, true]:
		var m = await make_run(SV, hy)
		check("hyper flag = %s" % str(hy), m.hyper == hy and absf(m.time_k - (2.0 if hy else 1.0)) < 0.001)
		var t0: float = m.run_time
		for i in range(20):
			m._process(0.1)
		var adv: float = m.run_time - t0
		# xp
		m.player.xp = 0.0
		m._gain_xp(10.0)   # small enough not to trigger a level-up
		var xp: float = m.player.xp
		# rift legend scaling at a fixed game clock
		m.run_time = 3000.0
		var hp: float = float(m._legend_def(384)["hp"])
		res[hy] = {"adv": adv, "xp": xp, "hp": hp, "hudt": m.hud.run_time, "m": m}
	check("run clock advances 2x in Hyper", absf(res[true]["adv"] / res[false]["adv"] - 2.0) < 0.05, "%.2f vs %.2f" % [res[true]["adv"], res[false]["adv"]])
	check("XP x1.3 in Hyper", absf(res[true]["xp"] / res[false]["xp"] - 1.3) < 0.01, "%.2f vs %.2f" % [res[true]["xp"], res[false]["xp"]])
	check("rift legend scales x1.6 (not x2) in Hyper", absf(float(res[true]["hp"]) - (3200.0 + 9.0 * 3000.0 * 0.8)) < 1.0, str(res[true]["hp"]))
	check("normal rift legend unchanged", absf(float(res[false]["hp"]) - (3200.0 + 9.0 * 3000.0)) < 1.0, str(res[false]["hp"]))
	# HUD clock shows real time: run_time (sim) / 2
	var mh = res[true]["m"]
	mh.run_time = 1800.0
	mh._process(0.0)
	check("HUD clock = real time (1800 sim s -> 900 s)", absf(mh.hud.run_time - 900.0) < 1.0, str(mh.hud.run_time))
	# mega cards at 15 real minutes
	var MG = load("res://scripts/mega.gd")
	mh.run_time = 1799.0
	check("no mega card before 15 real minutes", MG.card(mh).is_empty())
	mh.run_time = 1801.0
	check("mega card available from 15 real minutes", not MG.card(mh).is_empty())
	# run end: Hyper records and coin multiplier (rewards computed against an identical non-Hyper run)
	var coins := {}
	for hy in [false, true]:
		SV.d = snap.duplicate(true)
		var m2 = res[hy]["m"]
		m2.run_time = 1200.0 if not hy else 2400.0   # same real time: 1200 s
		m2.coins = 100
		m2.kills = 50
		m2.run_saved = false
		m2.player.dead = true
		m2._finish_run()
		var lr: Dictionary = SV.last_run
		coins[hy] = lr["coins"]
		if hy:
			check("Hyper run time stored as real seconds", int(lr["time"]) == 1200, str(lr["time"]))
			check("Hyper best recorded separately", int(SV.d["stats"].get("hyper_best", 0)) == 1200 and int(SV.d["stats"]["best_time"]) == int(snap["stats"]["best_time"]), str(SV.d["stats"].get("hyper_best", 0)))
			check("Hyper stats for achievements", int(SV.d["stats"].get("hyperRuns", 0)) == 1 and int(SV.d["stats"].get("hyperBestMin", 0)) == 20, str(SV.d["stats"].get("hyperBestMin", 0)))
	check("Hyper pays x1.5 coins", absf(float(coins[true]) / float(coins[false]) - 1.5) < 0.02, "%s vs %s" % [str(coins[true]), str(coins[false])])
	SV.d = snap
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
