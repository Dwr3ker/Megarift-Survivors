extends SceneTree
# Mega rifts: they come early while your Pokémon could still earn its Mega Stone, the boss calls minions, and beating it
# gives the stone (the Mega card comes at once, no minute-30 wait). Mega Evolution also shortens the dash cooldown.
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

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var MG = load("res://scripts/mega.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 6   # Charizard: can Mega Evolve
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	m.player.invuln = 1.0e9
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	m.run_time = 600.0   # minute 10
	check("Mega rifts can come early while the stone can be earned", MG.wants_stone(m) and MG.stone_chance(10.0) > 0.2 and MG.rift_chance(10.0) == 0.0)
	check("no Mega card at minute 10 without the stone", MG.card(m).is_empty())
	# a Mega rift
	m._open_rift(384, false)
	m.rift_info["mega"] = true
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
	check("beating it gives the Mega Stone and a level-up for the Mega card", m.mega_stone and m.pending_levels == pl0 + 1)
	check("its minions leave with it", _minions(m) == 0)
	check("with the stone the Mega card is there at minute 10", not MG.card(m).is_empty())
	var offered: Array = m._offer()
	check("and it is always offered", offered.any(func(c): return String(c.get("cat", "")) == "mega"))
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
	# a Pokémon that can't Mega Evolve gets a Legend Shard from a Mega rift instead
	var ls0: int = m.lshards_run
	m.mega_done = true
	m._mega_stone_reward(Vector2.ZERO)
	check("without a stone to earn, a Mega rift gives a Legend Shard", m.lshards_run == ls0 + 1)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
