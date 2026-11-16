extends SceneTree
# Roadmap step 14: from minute 10 about 1 regular boss in 5 is a Tera boss. At half HP it Terastallizes into a type it
# didn't have: its type changes (and with it its weaknesses), it turns to crystal with the jewel above it. Once.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var TERA = load("res://scripts/tera.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	m.player.invuln = 1.0e9
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.jd.done = true
	# how often
	m.run_time = 300.0
	var early := 0
	for i in range(40):
		var b = m._spawn_boss(m.boss_run[0])
		if b.has_meta("tera_boss"):
			early += 1
		m.enemies.erase(b)
		b.queue_free()
	check("before minute 10: no Tera bosses", early == 0)
	m.run_time = 700.0
	var n := 0
	var ok_type := true
	for i in range(200):
		var b2 = m._spawn_boss(m.boss_run[mini(1, m.boss_run.size() - 1)])
		if b2.has_meta("tera_boss"):
			n += 1
			if b2.types.has(String(b2.get_meta("tera_boss"))):
				ok_type = false
		m.enemies.erase(b2)
		b2.queue_free()
	await process_frame
	check("from minute 10: about 1 boss in 5 (%d of 200)" % n, n >= 22 and n <= 60)
	check("its Tera type is always one it doesn't have", ok_type)
	# a Tera boss at half HP
	var e = m._spawn_boss(m.boss_run[mini(1, m.boss_run.size() - 1)])
	e.set_meta("tera_boss", "ice")
	e.position = m.player.position + Vector2(260, 0)
	var t0: Array = e.types.duplicate()
	e.hp = e.max_hp * 0.6
	await process_frame
	check("above half HP it hasn't changed", e.types == t0 and not e.has_meta("tera_done"))
	e.hp = e.max_hp * 0.45
	await process_frame
	check("at half HP it Terastallizes into Ice", e.types == ["ice"] and e.has_meta("tera_done"))
	await create_timer(0.6).timeout
	var cv = e.mat.get_shader_parameter("crystal")
	check("it turns to crystal", cv != null and float(cv) > 0.5)
	check("with the Ice jewel above it", e.get_children().any(func(c): return c.get_script() == TERA.Jewel and c.type == "ice"))
	check("its weaknesses change (Fire is now super effective)", m._types_mult("fire", e.types) > 1.5)
	var kids: int = e.get_children().size()
	e.hp = e.max_hp * 0.2
	await process_frame
	check("it happens only once", e.get_children().size() == kids)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
