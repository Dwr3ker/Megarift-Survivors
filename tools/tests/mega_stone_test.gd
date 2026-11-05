extends SceneTree
# The Mega Stone rift: one try per run. Small chance from minute 15, due at minute 20; its boss calls minions; winning it
# gives the stone (Mega card at once); losing it means waiting for the minute-30 card. Other Mega rifts give a Legend Shard.
# Mega Evolution also shortens the dash cooldown.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _minions(m) -> int:
	var n := 0
	for e in m.enemies:
		if is_instance_valid(e) and not e.dead and bool(e.get_meta("minion", false)):
			n += 1
	return n

func _run(dex: int):
	var SV = load("res://scripts/save_data.gd")
	SV.d = SV.default_data()
	SV.run_dex = dex
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
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var MG = load("res://scripts/mega.gd")
	SV.ensure()
	SV.load_dex()
	check("no stone rift before minute 15", MG.stone_chance(14.9) == 0.0)
	check("a small chance from minute 15", absf(MG.stone_chance(15.0) - 0.10) < 0.001)
	check("rising toward minute 20", MG.stone_chance(19.0) > 0.2 and MG.stone_chance(19.0) < 0.3)
	check("due from minute 20", MG.stone_chance(20.0) == 1.0 and MG.STONE_FORCE == 1200.0)
	var m = await _run(6)   # Charizard
	m.run_time = 600.0
	check("no Mega card at minute 10 without the stone", MG.card(m).is_empty())
	# minute 20: the next rift check opens the stone rift for sure
	m.run_time = 1200.0
	m.dir_done["rift"] = true
	m.rift_check = 0.0
	m._update_rift(0.01)
	check("at minute 20 the Mega Stone rift opens", m.rift != null and bool(m.rift_info.get("mega", false)) and bool(m.rift_info.get("stone", false)))
	check("it is the one try: no more stone rifts after it", m.stone_tried and not MG.wants_stone(m))
	check("it has its own look in the overworld (Mega Stone portal with your stone above it)", String(m.rift.style) == "stone" and m.rift.stone_tex != null)
	m._arena_begin()
	var boss = m.ainfo["boss"]
	m.ainfo["t"] = 5.0
	m.minion_t = 0.0
	m._mega_minions(0.1, boss)
	check("the Mega rift boss calls minions of its type", _minions(m) == MG.MINION_N, str(_minions(m)))
	for i in range(4):
		m.minion_t = 0.0
		m._mega_minions(0.1, boss)
	check("never more than %d minions at once" % MG.MINION_CAP, _minions(m) == MG.MINION_CAP, str(_minions(m)))
	var pl0: int = m.pending_levels
	m._legend_down(boss)
	check("winning it gives the Mega Stone and a level-up for the Mega card", m.mega_stone and m.pending_levels == pl0 + 1)
	check("its minions leave with it", _minions(m) == 0)
	check("with the stone the Mega card is there at minute 20", not MG.card(m).is_empty())
	check("and it is always offered", m._offer().any(func(c): return String(c.get("cat", "")) == "mega"))
	m._arena_end(true)
	await process_frame
	# Mega Evolved: shorter dash cooldown
	m._dash_start()
	var cd_normal: float = m.dash_cd
	m.dash_cd = 0.0
	m.dash_left = 0.0
	m._mega_start()
	check("Mega Evolving uses the stone", not m.mega_stone and m.mega_done)
	m._dash_start()
	check("Mega Evolved: dash cooldown -30%", absf(m.dash_cd - cd_normal * MG.DASH_K) < 0.01, "%.2f vs %.2f" % [m.dash_cd, cd_normal])
	m.queue_free()
	await process_frame
	# losing the stone rift: no stone, no second try; the Mega card waits for minute 30
	var m2 = await _run(6)
	m2.run_time = 1250.0
	m2._open_rift(-1, false, true)
	check("the stone rift opens", bool(m2.rift_info.get("stone", false)))
	m2._arena_begin()
	m2._arena_end(false)
	await process_frame
	check("after losing it there is no stone and no second stone rift", not m2.mega_stone and not MG.wants_stone(m2))
	check("so no Mega card before minute 30", MG.card(m2).is_empty())
	m2.run_time = 1800.0
	check("and it comes at minute 30", not MG.card(m2).is_empty())
	# an ordinary Mega rift (not the stone rift) gives a Legend Shard
	m2.run_time = 1900.0
	m2._open_rift(384, false)
	m2.rift_info["mega"] = true
	m2._arena_begin()
	var ls0: int = m2.lshards_run
	m2._legend_down(m2.ainfo["boss"])
	check("an ordinary Mega rift gives a Legend Shard, not a stone", m2.lshards_run == ls0 + 1 and not m2.mega_stone)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
