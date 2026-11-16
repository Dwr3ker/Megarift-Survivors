extends SceneTree
# Rift legendaries for strong builds (docs/late_challenge.md): a longer fight, but stronger is still faster. A weak build keeps
# the usual HP; a strong one gets a floor from its recent damage; the fight calibrates at 4 s and 10 s on the boss's real
# damage taken so it lasts about 30 s in total (only up); its hits take at least 8% of your max HP after Defense.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var m

func fake_dps(dps: float) -> void:
	m.dmg_hist = []
	for i in range(21):
		m.dmg_hist.append({"x": dps * float(i)})

func open_fight():
	m.rift_check = 999.0
	m._open_rift(144)   # Articuno
	m._arena_begin()
	return m.ainfo["boss"]

func leave() -> void:
	m._arena_end(true)
	for i in range(3):
		await process_frame

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["owned"]["150"] = {"n": 1, "shiny": false}
	SV.run_dex = 150
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	m.set_process(false)
	m.run_time = 1200.0
	var usual: float = float(m._legend_def(144)["hp"])
	# weak build
	fake_dps(100.0)
	var b = open_fight()
	check("a weak build keeps the usual HP", absf(b.max_hp - usual) < 1.0, "%d vs %d" % [b.max_hp, usual])
	await leave()
	# strong build: the start floor
	fake_dps(11000.0)
	check("recent damage per second is read from the last 20 s", absf(m._recent_dps() - 11000.0) < 1.0, "%.0f" % m._recent_dps())
	b = open_fight()
	check("11,000 DPS: a small start floor, 2.5 s of that damage", absf(b.max_hp - 27500.0) < 1.0, "%d" % b.max_hp)
	check("the soft rule: 10 s -> ~27 s, 1.5 s -> ~22 s, 0.5 s -> ~20 s, 40 s unchanged",
		absf(m._rift_target(10.0) - 26.9) < 0.2 and absf(m._rift_target(1.5) - 22.2) < 0.2 and absf(m._rift_target(0.5) - 19.9) < 0.2 and m._rift_target(40.0) == 40.0)
	var hit: float = m.player.max_hp * 0.08 / maxf(0.2, 1.0 - m._reduction())
	check("its hits take at least 8% of your HP after Defense", b.dmg >= hit - 0.01, "%.1f vs %.1f" % [b.dmg, hit])
	# calibration on the real single-target damage, measured from the first hit (here at 0.5 s)
	m.ainfo["t1"] = 0.5
	var expect := func(rate: float, t: float) -> float:
		var taken: float = rate * (t - 0.5)
		return taken + rate * (m._rift_target(usual / rate) - t)
	m.ainfo["t"] = 0.75
	b.hp = b.max_hp - 0.25 * 20000.0
	m._rift_calibrate(b)
	var w1: float = m._rift_target(usual / 20000.0)
	check("first check at 0.75 s: 20,000 real DPS -> a %.1f s fight" % w1, int(m.ainfo["cal"]) == 1 and absf(b.max_hp - expect.call(20000.0, 0.75)) < 2.0, "%d" % b.max_hp)
	m.ainfo["t"] = 1.5
	b.hp = b.max_hp - 1.0 * 20000.0
	var before: float = b.max_hp
	m._rift_calibrate(b)
	check("same rate at 1.5 s: no change", absf(b.max_hp - before) < 2.0)
	m.ainfo["t"] = 4.0
	b.hp = b.max_hp - 3.5 * 20000.0
	m._rift_calibrate(b)
	m.ainfo["t"] = 10.0
	b.hp = b.max_hp - 9.5 * 25000.0
	m._rift_calibrate(b)
	var w2: float = m._rift_target(usual / 25000.0)
	check("stronger by 10 s: raised again, and the target is shorter (%.1f s)" % w2, absf(b.max_hp - expect.call(25000.0, 10.0)) < 2.0 and w2 < w1, "%d" % b.max_hp)
	m.ainfo["t"] = 20.0
	var mh: float = b.max_hp
	m._rift_calibrate(b)
	check("no more after the fourth check", b.max_hp == mh)
	await leave()
	# a build that only scratches it: never lowered
	fake_dps(0.0)
	b = open_fight()
	var h0: float = b.max_hp
	m.ainfo["t1"] = 0.5
	m.ainfo["t"] = 0.75
	b.hp = h0 - 100.0   # 400 per second: it would take 35 s, longer than 30
	m._rift_calibrate(b)
	check("a slow fight (over 30 s) is left alone", b.max_hp == h0 and absf(b.hp - (h0 - 100.0)) < 0.01)
	await leave()
	# Adaptive off: usual numbers
	SV.d["settings"]["adaptive"] = false
	fake_dps(11000.0)
	b = open_fight()
	check("Adaptive difficulty off: the usual HP", absf(b.max_hp - usual) < 1.0)
	await leave()
	SV.d["settings"]["adaptive"] = true
	m.queue_free()
	for i in range(3):
		await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
