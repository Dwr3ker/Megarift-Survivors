extends SceneTree
# Headless check of the rift schedule: first roll at 90 s, a check every 30 s, 20% +5% per miss (max 50%) that resets after a rift,
# no cutoff before the finale, and the check timer following the game clock in Hyper.
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

func clear_rift(m) -> void:
	if m.rift != null and is_instance_valid(m.rift):
		m.rift.queue_free()
	m.rift = null
	m._rift_drop_arena()
	m.rift_info = {}

# Fraction of n periodic checks that open a rift for a given miss streak and game time.
func rate_at(m, misses: int, game_time: float, n: int) -> float:
	var opened := 0
	for i in range(n):
		clear_rift(m)
		m.dir_done = {"rift": true}
		m.run_time = game_time
		m.rift_check = 0.0
		m.rift_miss = misses
		m._update_rift(0.01)
		if m.rift != null:
			opened += 1
			if game_time < 120.0 and m.rift_miss != 0: ok = false   # a rift resets the streak (a Dynamax den, possible from 120 s, has its own rules)
	clear_rift(m)
	return float(opened) / float(n)

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end
	var m = await make_run(SV, false)
	check("constants: 90 s start, 30 s checks, 20% base, +5% per miss, 50% cap", m.RIFT_START == 90.0 and m.RIFT_EVERY == 30.0 and absf(m.RIFT_CHANCE - 0.2) < 1e-9 and absf(m.RIFT_PITY - 0.05) < 1e-9 and absf(m.RIFT_CHANCE_MAX - 0.5) < 1e-9)
	check("director's rift milestone is at 90 s", m.DIR_MS[1][0] == "rift" and m.DIR_MS[1][1] == 90.0, str(m.DIR_MS[1]))
	check("the old minute-28 cutoff constant is gone", m.get("RIFT_END") == null)
	# --- before 90 s nothing happens
	m.dir_done = {"wave": true}
	m.dir_gap = 0.0
	m.run_time = 89.0
	m._update_director(0.1)
	check("no rift roll before 90 s", not m.dir_done.has("rift") and m.rift == null)
	# --- the first roll at 90 s: 20%, and a failure starts the pity streak
	var N := 120
	var opened := 0
	var streak_ok := true
	for i in range(N):
		clear_rift(m)
		m.dir_done = {"wave": true}
		m.dir_gap = 0.0
		m.rift_miss = 0
		m.run_time = 95.0
		m._update_director(0.1)
		if m.rift != null:
			opened += 1
		elif m.rift_miss != 1:
			streak_ok = false
		if not m.dir_done.has("rift"): ok = false
	check("first roll opens a rift about 20% of the time (not always)", opened > 8 and opened < 44, "%d of %d" % [opened, N])
	check("a failed first roll counts as the first miss", streak_ok)
	check("the roll re-arms the 30 s check", absf(m.rift_check - 30.0) < 0.001, str(m.rift_check))
	clear_rift(m)
	# --- periodic checks: chance = min(50%, 20% + 5% x misses); the Dynamax-den roll (5%) only starts at 120 s, so use 100 s here
	var r0: float = rate_at(m, 0, 100.0, 150)
	var r5: float = rate_at(m, 5, 100.0, 150)
	var r20: float = rate_at(m, 20, 100.0, 150)
	check("0 misses: ~20%", r0 > 0.10 and r0 < 0.32, "%.2f" % r0)
	check("5 misses: ~45% (20% + 5 x 5%)", r5 > 0.33 and r5 < 0.57, "%.2f" % r5)
	check("20 misses: capped at ~50% (not 100%)", r20 > 0.34 and r20 < 0.68, "%.2f" % r20)
	check("pity grows with the streak (0 < 5 misses)", r5 > r0 + 0.12, "%.2f vs %.2f" % [r0, r5])
	# --- no cutoff at minute 28: still rolling at 40 minutes (a Dynamax den may also open, so only a lower bound)
	var late: float = rate_at(m, 20, 2400.0, 150)
	check("rifts still appear after minute 28 (at 40:00)", late > 0.38, "%.2f" % late)
	# --- but not once the finale has started
	m.dir_finale = true
	var fin: float = rate_at(m, 20, 2400.0, 40)
	m.dir_finale = false
	check("no rifts during the Eternatus finale", fin == 0.0, "%.2f" % fin)
	# --- the timer
	m.dir_done = {"rift": true}
	m.rift_check = 12.0
	m._update_rift(1.0)
	check("the timer counts down in normal mode (12 -> 11)", absf(m.rift_check - 11.0) < 0.001 and m.rift == null, str(m.rift_check))
	var mh = await make_run(SV, true)
	mh.dir_done = {"rift": true}
	mh.rift_check = 10.0
	mh._update_rift(1.0)
	check("Hyper counts the check timer at 2x (10 -> 8)", absf(mh.rift_check - 8.0) < 0.001, str(mh.rift_check))
	SV.d = _guard
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
