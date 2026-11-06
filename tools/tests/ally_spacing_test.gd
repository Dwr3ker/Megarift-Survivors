extends SceneTree
# A summoned legendary and a caught boss both follow you: each waits on its own spot and they never stand on top of
# each other (also while chasing the same enemy).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
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
	for e in m.enemies:
		e.position += Vector2(9000, 9000)
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	# the altar legendary and a caught boss, both right next to you
	var alt = m.Prop.new()
	alt.position = m.player.position + Vector2(5, 5)
	m._summon_legend(alt)
	m.alpha._make_ally({"dex": 150, "types": ["psychic"], "name": "Mewtwo", "pos": m.player.position + Vector2(-5, 5)})
	check("a summoned legendary and a caught ally both follow you", m.legend != null and m.allies_extra.size() == 1)
	for i in range(240):
		await process_frame
	var a = m.legend
	var b = m.allies_extra[0]
	var gap: float = a.position.distance_to(b.position)
	check("they wait on different spots, not on top of each other", gap > 70.0, "%.0f px apart" % gap)
	check("both stay close to you", a.position.distance_to(m.player.position) < 160.0 and b.position.distance_to(m.player.position) < 160.0)
	# both chase the same enemy: they still keep their distance
	var e = m._spawn_one()
	e.position = m.player.position + Vector2(300, 0)
	e.max_hp = 1.0e9
	e.hp = e.max_hp
	e.spd = 0.0
	for i in range(120):
		await process_frame
	gap = a.position.distance_to(b.position)
	check("chasing the same enemy they keep apart", gap >= m.ALLY_GAP - 4.0, "%.0f px apart" % gap)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
