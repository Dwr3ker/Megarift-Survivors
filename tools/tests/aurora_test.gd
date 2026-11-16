extends SceneTree
# Small features steps 61-63: the Aurora night event (docs/aurora.md). How often nights get one and when it starts;
# forcing it shows the banner, the sky and the HUD line; the bonus (shiny odds, XP) applies only while it shines; it
# waits hidden in the Tower / rifts; the medal.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var ACH = load("res://scripts/ach.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["owned"]["4"] = {"n": 1}
	SV.run_dex = 4
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	var a = m.aur
	var C: float = m.dn.CYCLE
	# ---- how often, and when ----
	var planned := 0
	var in_window := true
	var day_plans := 0
	for n in range(400):
		a.t = -1.0
		a.plan_at = -1.0
		m.run_time = n * C + 30.0   # daytime: never rolls
		a.update(0.0)
		if a.plan_at >= 0.0:
			day_plans += 1
		m.run_time = n * C + m.dn.P_DUSK + 1.0
		a.update(0.0)
		if a.plan_at >= 0.0:
			planned += 1
			var into: float = a.plan_at - (n * C + m.dn.P_DUSK)
			if into < a.START_MIN - 0.01 or into > a.START_MAX + 0.01:
				in_window = false
	check("no Aurora is planned in the day", day_plans == 0)
	check("about 40% of nights get one", planned >= 130 and planned <= 190, "%d / 400" % planned)
	check("it starts 20-100 s into the night", in_window)
	# a planned one actually starts when its time comes, only once per night
	a.t = -1.0
	a.night_seen = -1
	a.plan_at = -1.0
	a.count = 0
	m.run_time = 10.0 * C + m.dn.P_DUSK + 1.0
	seed(7)
	while a.plan_at < 0.0:
		a.night_seen = -1
		a.update(0.0)
	m.run_time = a.plan_at + 0.01
	a.update(0.0)
	check("a planned Aurora starts at its time", a.active() and a.count == 1, "t %.2f count %d plan %.1f rt %.1f night %s mode %s arena %s" % [a.t, a.count, a.plan_at, m.run_time, m.dn.is_night(), m.mode, m.arena])
	a.t = -1.0
	a.update(0.0)
	check("and doesn't come back the same night", not a.active() and a.plan_at < 0.0)
	# ---- forcing it ----
	m.run_time = 20.0 * C + m.dn.P_DUSK + 30.0
	var xp_off: float = _xp_gain(m, 10.0)
	var sh_off: float = a.shiny_k()
	m.dn.last_phase = "night"
	a.start()
	check("the banner says so", m.banner_text.contains("Aurora"), m.banner_text)   # read at once: other run messages can follow
	for i in range(3):
		await process_frame
	check("the Northern lights medal", bool(ACH.entry("aurora")["got"]))
	check("shiny odds x8 while it shines", a.shiny_k() == 8.0 and sh_off == 1.0)
	var xp_on: float = _xp_gain(m, 10.0)
	check("experience x1.25 while it shines", absf(xp_on / xp_off - 1.25) < 0.001, "%.3f" % (xp_on / xp_off))
	m.aur.t = 10.0
	m._process(0.05)
	check("the HUD shows it with the time left", m.hud.weather_text.contains("Aurora") and m.hud.weather_text.contains("40s"), m.hud.weather_text)
	check("the sky is drawn", a.sky.visible and a.level() > 0.9)
	check("the sky sits just above the night tint and under the HUD", m.ui_layer.get_children().find(a.sky) == m.ui_layer.get_children().find(m.dn.rect) + 1 and m.ui_layer.get_children().find(a.sky) < m.ui_layer.get_children().find(m.hud))
	m.dn.update(0.0)   # the same order as the run loop: day/night tint first, then the Aurora over it
	a.update(0.0)
	var nc: Color = m.dn.color_at(m.run_time)
	check("the night tint shifts toward teal and stays dark", m.dn.rect.color.g > nc.g + 0.01 and m.dn.rect.color.b < nc.b and m.dn.rect.color.a >= nc.a, "%s vs %s" % [m.dn.rect.color, m.dn.color_at(m.run_time)])
	# ---- waits in the Tower / rifts ----
	m.mode = "tower"
	var t0: float = a.t
	a.update(5.0)
	check("in the Tower it waits, hidden, with no bonus", a.t == t0 and not a.sky.visible and a.shiny_k() == 1.0 and a.xp_k() == 1.0)
	m.mode = "normal"
	# ---- it ends ----
	a.t = a.DUR - 0.05
	a.update(0.1)
	check("it ends after 50 s", not a.active() and a.t < 0.0 and m.banner_text.contains("fades"), m.banner_text)
	check("no bonus once it's over", a.shiny_k() == 1.0 and a.xp_k() == 1.0 and absf(_xp_gain(m, 10.0) - xp_off) < 0.001)
	a.update(0.0)
	check("the sky is gone", not a.sky.visible)
	print("RESULT: ", "PASS" if ok else "FAIL")
	m.queue_free()   # let the run close (and any rift map still baking finish) before quitting
	for i in range(3):
		await process_frame
	quit(0 if ok else 1)

func _xp_gain(m, amt: float) -> float:
	m.player.xp = 0.0
	m.player.xp_next = 1.0e12
	m._gain_xp(amt)
	return m.player.xp
