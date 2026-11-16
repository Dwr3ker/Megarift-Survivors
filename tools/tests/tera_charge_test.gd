extends SceneTree
# Roadmap step 4: the Tera Orb fills from defeats during a run: +1 per defeat, +10 per boss, full at 300, then it
# stops; it doesn't charge once used, nor in Tower mode.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _kill(m, boss: bool = false) -> void:
	var e = m._spawn_one()
	e.position = m.player.position + Vector2(400, 0)
	e.boss = boss
	m._damage_enemy(e, e.hp + e.shield + 10.0, Color.WHITE)

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var TERA = load("res://scripts/tera.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	m.player.invuln = 1.0e9
	m.tera_pts = 0.0
	check("the orb starts empty", m.tera_pts == 0.0 and not m._tera_ready())
	_kill(m)
	check("one defeat adds 1", is_equal_approx(m.tera_pts, 1.0), str(m.tera_pts))
	_kill(m, true)
	check("a boss adds 10", is_equal_approx(m.tera_pts, 11.0), str(m.tera_pts))
	var n := 0
	var at_half := -1
	while not m._tera_ready() and n < 400:
		_kill(m)
		n += 1
		if at_half < 0 and m.tera_pts >= TERA.NEED * 0.5:
			at_half = n
	check("it fills to full after 300 points", m._tera_ready() and is_equal_approx(m.tera_pts, TERA.NEED), "%d more defeats" % n)
	check("the meter rises steadily (half-way after about half the defeats)", at_half > 120 and at_half < 160, str(at_half))
	_kill(m)
	check("it stops at full", is_equal_approx(m.tera_pts, TERA.NEED))
	m.tera_used = true
	m.tera_pts = 0.0
	_kill(m)
	check("once used, it doesn't charge", m.tera_pts == 0.0 and not m._tera_ready())
	m.tera_used = false
	m.mode = "tower"
	_kill(m)
	check("Tower mode has no Tera", m.tera_pts == 0.0 and not m._tera_ready())
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
