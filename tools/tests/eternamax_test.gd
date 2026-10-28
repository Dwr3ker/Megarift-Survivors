extends SceneTree
# Headless check: Eternamax Eternatus finale (spawn, obelisks, every attack's damage, healing, phases, win).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var ETX = load("res://scripts/eternamax.gd")
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	SV.d = SV.default_data()   # tests start from a clean profile, whatever save the player has
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	m.run_time = 3600.0
	for id0 in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id0] = true   # keep the director (rifts, arena threads, a second Eternatus) out of the hand-driven checks
	m.rift_check = 1.0e9
	m.perks["def"] = 0.0
	m._spawn_eternatus()
	var e = m.dir_eter
	var x = m.etx
	check("controller created and boss flagged", x != null and e != null and e.has_meta("enc"))
	check("boss wears the Eternamax body", e.dex == 189001 and e.enemy_name == "Eternamax Eternatus", "%d %s" % [e.dex, e.enemy_name])
	check("boss HP = 12 x (3200 + 9t)", absf(e.max_hp - (12.0 * (3200.0 + 9.0 * 3600.0))) < 1.0, str(e.max_hp))
	check("boss is scripted (no stock AI, no contact damage)", bool(e.def.get("scripted", false)) and e.dmg == 0.0)
	check("3 obelisks at 12.5% HP each", x.alive_obelisks() == 3 and absf(x.obelisks[0].max_hp / e.max_hp - 0.125) < 0.001, "%d" % x.alive_obelisks())
	check("boss counts as 'boss alive' (horde damping), obelisks do not", m._boss_alive() and not x.obelisks[0].boss)
	# a sturdy test player: 1000 max HP, no armor, no i-frames
	m.player.max_hp = 1000.0
	m.player.hp = 1000.0
	m.player.invuln = 0.0
	m.player.position = e.position + Vector2(500.0, 0.0)
	var pp: Vector2 = m.player.position
	# --- cannon: lock on the player and explode
	x.cannons.clear()
	x.cannons.append({"pos": pp, "t": 0.0, "hit": false})
	var hp0: float = m.player.hp
	for i in range(int((x.CANNON_TRACK + x.CANNON_LOCK + 0.2) * 60.0)):
		x.tick(1.0 / 60.0)
		m.player.position = pp
		if m.player.hp < hp0: break
	check("cannon deals 30% of max HP", absf((hp0 - m.player.hp) - 300.0) < 1.0, "lost %.0f" % (hp0 - m.player.hp))
	# --- rings: one hit outside the gap, none inside it
	m.player.hp = 1000.0; m.player.invuln = 0.0
	x.cannons.clear(); x.beam = {}; x.rings.clear(); x.ring_queue.clear()
	var origin: Vector2 = e.position
	var ang: float = (pp - origin).angle()
	var dist: float = pp.distance_to(origin)
	x.rings.append({"r": dist - 40.0, "gaps": [ang + PI], "hit": false, "origin": origin})
	for i in range(30):
		x._tick_rings(1.0 / 60.0, pp)
	check("ring outside its gap deals 15%", absf((1000.0 - m.player.hp) - 150.0) < 1.0, "lost %.0f" % (1000.0 - m.player.hp))
	m.player.hp = 1000.0; m.player.invuln = 0.0
	x.rings.clear()
	x.rings.append({"r": dist - 40.0, "gaps": [ang], "hit": false, "origin": origin})
	for i in range(30):
		x._tick_rings(1.0 / 60.0, pp)
	check("standing in the gap is safe", m.player.hp >= 999.0, "hp %.0f" % m.player.hp)
	# --- beam sweep hits once for 60%, and i-frames dodge it
	for dodge in [false, true]:
		m.player.hp = 1000.0
		x.rings.clear()
		x.beam = {"phase": "sweep", "t": 0.0, "aim": ang, "dir": 1.0, "hit": false, "ang": ang - PI * 0.5, "origin": origin}
		for i in range(int(4.0 * 60.0)):
			m.player.invuln = 5.0 if dodge else 0.0
			x._tick_beam(1.0 / 60.0, pp)
			m.player.position = pp
			if x.beam.is_empty(): break
		var lost: float = 1000.0 - m.player.hp
		if dodge:
			check("i-frames (dash) dodge the Eternabeam", lost < 1.0, "lost %.0f" % lost)
		else:
			check("Eternabeam deals 60% once per sweep", absf(lost - 600.0) < 1.0, "lost %.0f" % lost)
	# --- meteors and pools
	var z0: int = m.hazards.size()
	x._start_meteors()
	check("meteors: 5-8 danger zones", m.hazards.size() - z0 >= 5 and m.hazards.size() - z0 <= 8, str(m.hazards.size() - z0))
	m.player.hp = 1000.0; m.player.invuln = 0.0
	x.pools.clear()
	x.pools.append({"pos": pp, "delay": 0.0, "t": 0.0, "tick": 0.0})
	x._tick_pools(0.1, pp)
	check("standing in a pool costs 4%", absf((1000.0 - m.player.hp) - 40.0) < 1.0, "lost %.0f" % (1000.0 - m.player.hp))
	# --- tail: stay close for 3 s
	m.player.position = e.position + Vector2(80.0, 0.0)
	x.close_t = 0.0; x.tail_cd = 0.0
	var t0: int = x.stats["tails"]
	for i in range(int(3.3 * 60.0)):
		x.tick(1.0 / 60.0)
		m.player.position = e.position + Vector2(80.0, 0.0)
		m.player.hp = 1000.0
	check("staying close for 3 s triggers the tail slam", x.stats["tails"] > t0)
	# --- obelisk healing
	m.player.position = e.position + Vector2(500.0, 0.0)
	x.cannons.clear(); x.beam = {}; x.rings.clear(); x.ring_queue.clear(); x.pools.clear()
	x.beam_cd = 999.0; x.cannon_cd = 999.0; x.ring_cd = 999.0; x.meteor_cd = 999.0
	e.hp = e.max_hp * 0.6
	var h0: float = e.hp
	for i in range(600):
		x.tick(1.0 / 60.0)
		m.player.hp = 1000.0
	check("3 obelisks heal the boss (~1.2%/s)", absf((e.hp - h0) / e.max_hp - 0.12) < 0.01, "%.3f" % ((e.hp - h0) / e.max_hp))
	for o in x.obelisks:
		o.dead = true
	h0 = e.hp
	for i in range(300):
		x.tick(1.0 / 60.0)
		m.player.hp = 1000.0
	check("no healing once the obelisks are dead", absf(e.hp - h0) < 1.0)
	# --- phases
	e.hp = e.max_hp * 0.49
	x.tick(0.016)
	check("phase 2 at 50% HP", x.phase == 2)
	e.hp = e.max_hp * 0.24
	x.tick(0.016)
	check("enrage at 25% HP", x.enraged)
	check("cadence rises with phase and enrage", x.cadence() > ETX.curve(ETX.CAD_CURVE, 60.0) * 1.1)
	# --- the schedule really fires every attack over time
	var m2 = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m2)
	await process_frame
	m2.run_time = 3600.0
	m2._spawn_eternatus()
	var x2 = m2.etx
	m2.player.max_hp = 1.0e9
	m2.player.hp = 1.0e9
	for i in range(int(120.0 * 60.0)):
		x2.tick(1.0 / 60.0)
		m2.player.hp = 1.0e9
		m2.player.invuln = 0.0
	var s: Dictionary = x2.stats
	check("120 s fight fires every attack type", s["beams"] >= 3 and s["cannons"] >= 8 and s["rings"] >= 6 and s["meteors"] >= 10 and s["tails"] >= 0, str(s))
	# --- win
	for id in ["wave", "rift", "meowth", "boss", "map"]:
		m2.dir_done[id] = true   # only the Eternatus milestone is left for the director
	m2.dir_done["eter"] = true   # what the director records when it spawns him (the test spawned him by hand)
	m2.rift_check = 1.0e9        # no stray rift (and its arena thread) while the test runs
	m2.jd.done = true            # the Judgment arc (minute 30) already played in a real run; keep its cinematic out of the way
	var boss2 = m2.dir_eter
	var c0: int = m2.coins
	var t0b: int = m2.tickets
	var p0: int = m2.tickets10
	m2._damage_enemy(boss2, boss2.max_hp * 2.0)
	await process_frame
	await process_frame
	await process_frame
	check("killing Eternatus stops the controller but does not end the run yet", m2.etx == null and not m2.timeup and not m2.player.dead, "timeup=%s etx=%s" % [str(m2.timeup), str(m2.etx)])
	check("the choice screen opens with two cards", m2.cards.open and m2.choosing and m2.cards.items.size() == 2 and String(m2.cards.items[0]["id"]) == "go" and String(m2.cards.items[1]["id"]) == "end")
	check("first kill pays 1500 coins, 10 tickets and 2 x10 tickets right away", m2.coins - c0 == 1500 and m2.tickets - t0b == 10 and m2.tickets10 - p0 == 2, "%d %d %d" % [m2.coins - c0, m2.tickets - t0b, m2.tickets10 - p0])
	check("the world is frozen while the choice is open", m2.choosing)
	# --- keep going: heal, schedule the next Eternatus 30 game-minutes after the first
	m2.player.hp = 5.0
	m2._on_card_chosen(0)
	check("keep fighting: run goes on, healed, finale lifted", not m2.timeup and not m2.player.dead and m2.player.hp == m2.player.max_hp and not m2.dir_finale and not m2.choosing)
	check("next Eternatus is scheduled at minute 90 (Normal)", m2.eter_at == 5400.0 and not m2.dir_done.has("eter"), str(m2.eter_at))
	m2.run_time = 4000.0
	m2._update_director(0.1)
	check("Eternatus does not return early", m2.dir_eter == null and not m2.dir_finale)
	m2.run_time = 5400.0
	m2.dir_gap = 0.0
	m2._update_director(0.1)
	check("Eternatus returns at minute 90 and stronger", m2.dir_eter != null and m2.dir_finale and m2.etx != null and m2.dir_eter.max_hp > boss2.max_hp, "%s" % str(m2.dir_eter))
	# --- second kill pays less, then end the run with a victory
	var boss3 = m2.dir_eter
	c0 = m2.coins
	t0b = m2.tickets
	p0 = m2.tickets10
	m2._damage_enemy(boss3, boss3.max_hp * 2.0)
	await process_frame
	await process_frame
	await process_frame
	check("second kill pays 1000 coins, 5 tickets and 1 x10 ticket", m2.coins - c0 == 1000 and m2.tickets - t0b == 5 and m2.tickets10 - p0 == 1 and m2.eter_kills == 2, "%d %d %d" % [m2.coins - c0, m2.tickets - t0b, m2.tickets10 - p0])
	check("best Eternatus count of the run is saved for the Doom achievements", int(SV.d["stats"].get("eterBestRun", 0)) == 2 and m2.eter_kills == 2)
	check("the choice screen opens again", m2.cards.open and m2.choosing, "open=%s choosing=%s prompt=%s lv=%d paused=%s ret=%s arena=%s dead=%s items=%d" % [str(m2.cards.open), str(m2.choosing), str(m2.eter_prompt), m2.pending_levels, str(m2.paused), str(m2.ret_cd), str(m2.arena), str(m2.player.dead), m2.cards.items.size()])
	m2._on_card_chosen(1)
	check("end the run: victory screen, run over, not a defeat", m2.timeup and m2.player.dead and not m2.choosing)
	await process_frame   # the run is banked on the next frame; let it happen before the real save is restored below
	await process_frame
	check("the run was banked as a win (not a defeat)", m2.run_saved and not bool(SV.last_run.get("dead", true)), str(SV.last_run.get("dead", "?")))
	# --- Hyper schedule: 30 min first, then every 15 real minutes (the game clock runs x2)
	m2.time_k = 2.0
	m2.run_time = 3600.0
	m2.eter_at = 3600.0
	check("Hyper: next Eternatus 15 real minutes later (clock minute 45)", int(m2._next_eter_at() / m2.time_k / 60.0) == 45, str(m2._next_eter_at()))
	m2.run_time = 5600.0
	check("late kill pushes the next one to at least 10 game-minutes away", m2._next_eter_at() >= 5600.0 + 600.0, str(m2._next_eter_at()))
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
