extends SceneTree
# Headless check: wild legendaries (curves, cap of 3, gating, stats vs normal wilds, Hyper pacing, payout).
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
	m.dir_done["map"] = true
	return m

func _init() -> void:
	var WL = load("res://scripts/wildleg.gd")
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	check("rate 0.15/min at 30", absf(WL.rate(30.0) - 0.15) < 1e-6)
	check("rate 0.20/min at 37.5", absf(WL.rate(37.5) - 0.20) < 1e-6, str(WL.rate(37.5)))
	check("rate 0.40/min at 60 and capped", absf(WL.rate(60.0) - 0.40) < 1e-6 and absf(WL.rate(90.0) - 0.75) < 1e-6)
	check("damage 48 at 30, 57.6 at 60", absf(WL.dmg(30.0) - 48.0) < 1e-6 and absf(WL.dmg(60.0) - 57.6) < 1e-4, "%.2f %.2f" % [WL.dmg(30.0), WL.dmg(60.0)])
	check("speed 52 at 30, 58.5 at 90", absf(WL.speed(30.0) - 52.0) < 1e-6 and absf(WL.speed(90.0) - 58.5) < 1e-4)
	var m = await make_run(SV, false)
	# nothing before minute 30
	m.run_time = 1700.0
	m._update_wildleg(1000.0)
	check("no wild legend before minute 30", m._wildleg_alive() == 0)
	m.run_time = 1900.0
	m.wl_acc = 0.0
	for i in range(30):
		m._update_wildleg(10.0)   # 300 s of game time at ~0.16/min -> ~0.8, not yet
	check("not yet after 300 s at ~0.16/min (acc %.2f)" % m.wl_acc, m._wildleg_alive() == 0 and m.wl_acc > 0.7 and m.wl_acc < 0.95)
	for i in range(10):
		m._update_wildleg(10.0)
	check("first one arrives at about 6-7 minutes of game time", m._wildleg_alive() == 1, "alive %d acc %.2f" % [m._wildleg_alive(), m.wl_acc])
	# cap of 3, distinct species
	for i in range(30):
		m._update_wildleg(100.0)
	var alive: Array = []
	for e in m.enemies:
		if is_instance_valid(e) and not e.dead and m._is_wildleg(e): alive.append(e)
	var dexes := {}
	for e in alive: dexes[e.dex] = true
	check("capped at 3 alive", alive.size() == 3, str(alive.size()))
	check("3 different legendaries", dexes.size() == 3, str(dexes.keys()))
	check("wild legends are not 'boss alive' (no horde damping)", not m._boss_alive())
	# stats vs a normal wild
	var e0 = alive[0]
	var norm: float = m._wl_norm_hp(m._dt())
	var m_t: float = m._dt() / 60.0
	check("legend HP = normal wild x%.1f" % WL.hp_k(m_t), absf(e0.max_hp / norm - WL.hp_k(m_t)) < 0.05, "%.0f vs normal %.0f" % [e0.max_hp, norm])
	check("legend is much tougher than a normal wild (>= 2.5x)", e0.max_hp >= 2.5 * norm)
	check("legend XP = 15x a normal wild", absf(e0.xp_val - 15.0 * m.XP_ENEMY * m.XP_K) < 1.0, str(e0.xp_val))
	check("legend speed/damage from the curves", absf(e0.spd - WL.speed(m_t)) < 0.5 and e0.dmg >= WL.dmg(m_t) * 0.99, "spd %.1f dmg %.1f" % [e0.spd, e0.dmg])
	# a boss alive blocks new legends
	for e in alive: e.dead = true
	m.enemies.clear()
	m.wl_acc = 1.2
	# payout
	var tickets10 := 0
	var coins := 0
	var N := 200
	var le = m._spawn_wildleg(144)
	for i in range(N):
		le.remove_meta("wl_paid")
		var before: int = m.orbs.size()
		m._drop(le)
		for k in range(before, m.orbs.size()):
			var o = m.orbs[k]
			if is_instance_valid(o) and o.kind == "ticket10": tickets10 += 1
			if is_instance_valid(o) and o.kind == "coin": coins += 1
	var frac: float = float(tickets10) / float(N)
	check("payout: ticket x10 about 25% of the time (normal boss loot)", absf(frac - 0.25) < 0.13, "%.3f" % frac)
	check("payout: coins dropped each time", coins >= 20 * N / 2, str(coins))
	# Hyper pacing: twice the accumulation per real second
	var mh = await make_run(SV, true)
	mh.run_time = 1900.0
	mh.wl_acc = 0.0
	mh._update_wildleg(10.0)
	check("Hyper accumulates 2x faster", absf(mh.wl_acc - 2.0 * 0.15 / 60.0 * 10.0) < 0.005, "%.3f" % mh.wl_acc)
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
