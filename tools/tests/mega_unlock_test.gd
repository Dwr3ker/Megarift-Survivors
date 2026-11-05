extends SceneTree
# Mega Evolution follows the Pokémon you are now (a Charmander that became Charizard can Mega Evolve), and without a
# Mega Stone it still unlocks at minute 30 of run time (15 real minutes in Hyper), offered at every level-up until taken.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _run(dex: int, hyper: bool):
	var SV = load("res://scripts/save_data.gd")
	SV.d = SV.default_data()
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = hyper
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
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var MG = load("res://scripts/mega.gd")
	SV.ensure()
	SV.load_dex()
	var m = await _run(4, false)   # Charmander
	m.run_time = 1900.0
	check("a Charmander can't Mega Evolve", MG.card(m).is_empty() and not MG.wants_stone(m))
	m.cur_dex = 6   # it evolved into Charizard during the run
	check("once it is Charizard it can (Mega Stone and the card follow the Pokémon it is now)", not MG.card(m).is_empty() and String(MG.form_for(m._cur_dex())["item"]) == "Charizardite X")
	# a run started unevolved: Mega stays possible but rare, and the minute-30 card is not guaranteed
	check("a run started as Charmander gets no guaranteed Mega card at minute 30", MG.evo_start(m) and not MG.guaranteed(m))
	var seen := 0
	for i in range(60):
		if m._offer().any(func(c): return String(c.get("cat", "")) == "mega"):
			seen += 1
	check("it only turns up now and then (about 1 level-up in 8)", seen > 0 and seen < 30, "%d of 60" % seen)
	m.mega_told = false
	m._mega_unlock_tick()
	check("and there is no 'unlocked' message", not m.mega_told)
	m.run_time = 1250.0
	m.dir_done["rift"] = true
	m.rift_check = 0.0
	m._update_rift(0.01)
	check("its stone rift is never forced at minute 20", not bool(m.rift_info.get("stone", false)))
	m.queue_free()
	await process_frame
	# a run started as Charizard: guaranteed from minute 30
	var c = await _run(6, false)
	c.run_time = 1900.0
	var always := true
	for i in range(8):
		if not c._offer().any(func(q): return String(q.get("cat", "")) == "mega"):
			always = false
	check("started as Charizard: after minute 30 the Mega card is offered at every level-up until taken", always)
	c.mega_told = false
	c._mega_unlock_tick()
	check("and you are told it is unlocked", c.mega_told)
	c.run_time = 1700.0
	check("before minute 30 (and without the stone) it is not there yet", MG.card(c).is_empty())
	c.queue_free()
	await process_frame
	var h = await _run(6, true)
	check("Hyper runs the run clock twice as fast", absf(h.time_k - 2.0) < 0.01, str(h.time_k))
	h.run_time = 0.0
	for i in range(30):
		h._process(1.0 / 60.0)   # half a real second
		if h.choosing or h.cards.open:
			h.cards.hide_cards()
			h.choosing = false
	check("so minute 30 of run time comes at 15 real minutes in Hyper", absf(h.run_time - 1.0) < 0.05, "%.3f s of run time per 0.5 s" % h.run_time)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
