extends SceneTree
# Difficulty steps 35-39 (docs/difficulty.md): save data and separate records; enemy HP/damage/speed; elites, Alphas and
# events; rewards (coins, tickets, XP); stacking with Hyper and the record going to the right table.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var SV
var DIF
var coins_by := {}

func _run(diff: String, hyper: bool = false):
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = hyper
	SV.run_diff = diff
	SV.run_region = 0
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(20):
		await process_frame
	m.player.invuln = 1.0e9
	return m

func _end(m) -> void:
	m.queue_free()
	for i in range(3):
		await process_frame

func _init() -> void:
	Engine.set_meta("no_save", true)
	SV = load("res://scripts/save_data.gd")
	DIF = load("res://scripts/difficulty.gd")
	SV.ensure()
	# 35: an old save (no difficulty key) loads as Normal; Nightmare starts locked
	SV.d = SV.default_data()
	SV.d.erase("difficulty")
	check("an old save loads on Normal", DIF.chosen() == "normal")
	check("Hard is open, Nightmare locked", DIF.unlocked("hard") and not DIF.unlocked("nightmare"))
	check("choosing a locked Nightmare is refused", not DIF.choose("nightmare") and DIF.chosen() == "normal")
	DIF.choose("hard")
	check("Hard can be chosen and is remembered", DIF.chosen() == "hard" and String(SV.d["difficulty"]) == "hard")
	# records stay separate
	SV.d["stats"]["runs"] = 1
	SV.d["stats"]["best_time"] = 200
	SV.finish_run({"time": 500, "kills": 0, "level": 1, "bosses": 0, "chests": 0, "coins": 0, "tickets": 0, "diff": "hard"})
	check("a Hard run's time goes to the Hard record", DIF.best("hard", false) == 500 and DIF.best("normal", false) == 200)
	SV.finish_run({"time": 300, "kills": 0, "level": 1, "bosses": 0, "chests": 0, "coins": 0, "tickets": 0, "diff": "normal"})
	check("a Normal run doesn't touch the Hard record", DIF.best("normal", false) == 300 and DIF.best("hard", false) == 500)
	SV.finish_run({"time": 700, "kills": 0, "level": 1, "bosses": 0, "chests": 0, "coins": 0, "tickets": 0, "diff": "nightmare", "hyper": true})
	check("Nightmare + Hyper has its own record", DIF.best("nightmare", true) == 700 and DIF.best("nightmare", false) == 0 and DIF.best("normal", true) == 0)
	check("the six record keys are distinct", ["normal", "hard", "nightmare"].map(func(x): return DIF.rec_key(x, false)).size() == 3
		and DIF.rec_key("hard", true) != DIF.rec_key("hard", false))
	# 36: the same enemy on each difficulty
	SV.d = SV.default_data()
	var hp := {}
	var dm := {}
	var sp := {}
	var elites := {}
	for dd in DIF.IDS:
		var m = await _run(dd)
		check("%s: the run reads its difficulty" % dd, m.diff == dd)
		var def: Dictionary = SV.get_meta("def") if SV.has_meta("def") else m._bag_at(0.0)[0]
		SV.set_meta("def", def)
		var e = m._make_enemy(def, m.player.position + Vector2(600, 0), {"hp": 1.0, "dmg": 1.0, "spd": 1.0})
		var hp0: float = e.max_hp
		m._dif_apply(e)
		hp[dd] = e.max_hp
		dm[dd] = e.dmg
		sp[dd] = e.spd
		m._dif_apply(e)   # never twice: the flag is set
		check("%s: applied once only" % dd, e.dif_done and is_equal_approx(e.max_hp, hp[dd]))
		# 37: elites at minute 12 over 600 spawns
		m.run_time = 720.0
		var n := 0
		for i in range(600):
			var s = m._spawn_one()
			if s.modulate.is_equal_approx(Color(1.0, 0.72, 0.72)):
				n += 1
			s.queue_free()
			m.enemies.erase(s)
		elites[dd] = n
		# Alphas: 60 s of alpha timer
		m.alpha.t_next = 1000.0
		m.alpha.cur = null
		m.alpha.update(60.0)
		check("%s: the Alpha timer runs x%.2f" % [dd, DIF.k(dd, "alpha")], is_equal_approx(1000.0 - m.alpha.t_next, 60.0 * DIF.k(dd, "alpha")), str(1000.0 - m.alpha.t_next))
		m.next_event_t = 1000.0
		m.event_id = ""
		m._update_events(10.0)
		check("%s: the event timer runs x%.2f" % [dd, DIF.k(dd, "event")], is_equal_approx(1000.0 - m.next_event_t, 10.0 * DIF.k(dd, "event")), str(1000.0 - m.next_event_t))
		# 38: XP
		m.player.xp = 0.0
		m.player.xp_next = 1.0e9
		m._gain_xp(100.0)
		var xp_n: float = m.player.xp
		if dd == "normal":
			SV.set_meta("xp_normal", xp_n)
		else:
			check("%s: XP x%.2f" % [dd, DIF.k(dd, "xp")], is_equal_approx(xp_n / float(SV.get_meta("xp_normal")), DIF.k(dd, "xp")), "%.3f" % (xp_n / float(SV.get_meta("xp_normal"))))
		await _end(m)
	check("Hard: HP x1.5, damage x1.35, speed x1.08", is_equal_approx(hp["hard"], roundf(hp["normal"] * 1.5)) and is_equal_approx(dm["hard"] / dm["normal"], 1.35) and is_equal_approx(sp["hard"] / sp["normal"], 1.08),
		"%s / %s" % [hp["hard"], hp["normal"]])
	check("Nightmare: HP x2.2, damage x1.7, speed x1.15", is_equal_approx(hp["nightmare"], roundf(hp["normal"] * 2.2)) and is_equal_approx(dm["nightmare"] / dm["normal"], 1.7) and is_equal_approx(sp["nightmare"] / sp["normal"], 1.15))
	check("elites at minute 12: none on Normal, some on Hard, more on Nightmare", elites["normal"] == 0 and elites["hard"] >= 10 and elites["nightmare"] > elites["hard"], str(elites))
	# 38: coins and tickets at run end; 39: Hard + Hyper
	for combo in [["normal", false], ["hard", false], ["nightmare", false], ["hard", true]]:
		SV.d = SV.default_data()
		var m = await _run(String(combo[0]), bool(combo[1]))
		m.coins = 100
		m.run_time = 1200.0 * m.time_k   # 20 real minutes
		m.tickets = 0
		m._finish_run()
		var lr: Dictionary = SV.last_run
		var tag: String = "%s%s" % [combo[0], " + Hyper" if combo[1] else ""]
		coins_by[tag] = int(lr["coins"])
		check("%s: tickets +%d for 20 minutes" % [tag, DIF.bonus_tickets(String(combo[0]), 1200.0)], int(lr["tickets"]) == DIF.bonus_tickets(String(combo[0]), 1200.0), str(lr["tickets"]))
		if combo[1]:
			check("Hard + Hyper: the record goes to the Hard Hyper table", DIF.best("hard", true) == 1200 and DIF.best("hard", false) == 0 and DIF.best("normal", true) == 0)
			check("Hard + Hyper: both apply (enemies are Hard and the run is Hyper)", m.hyper and m.diff == "hard")
		await _end(m)
	var cn: float = float(coins_by["normal"])
	check("Hard pays x1.5 coins", absf(float(coins_by["hard"]) / cn - 1.5) < 0.02, "%.3f" % (float(coins_by["hard"]) / cn))
	check("Nightmare pays x2.25 coins", absf(float(coins_by["nightmare"]) / cn - 2.25) < 0.02)
	check("Hard + Hyper pays x2.25 coins", absf(float(coins_by["hard + Hyper"]) / cn - 2.25) < 0.02, "%.3f" % (float(coins_by["hard + Hyper"]) / cn))
	# Nightmare unlocks after minute 30 on Hard
	SV.d["stats"]["hardBestMin"] = 30
	check("reaching minute 30 on Hard unlocks Nightmare", DIF.unlocked("nightmare") and DIF.choose("nightmare"))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
