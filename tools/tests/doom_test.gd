extends SceneTree
# Headless check of the endgame (Doom): rules per level, Overcap cards, endgame cards, Eternatus' new attacks, achievements, HUD.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	var DM = load("res://scripts/doom.gd")
	var SV = load("res://scripts/save_data.gd")
	var PG = load("res://scripts/progress.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	# ---------- pure rules ----------
	check("roman numerals for the HUD", DM.roman(1) == "I" and DM.roman(3) == "III" and DM.roman(5) == "V" and DM.roman(12) == "12")
	check("elite chance is floored at 25% from Doom 1 only", DM.elite_chance(0, 0.1) == 0.1 and DM.elite_chance(1, 0.1) == 0.25 and DM.elite_chance(1, 0.3) == 0.3)
	check("enemy cap 64 -> 80 from Doom 2", DM.cap(64, 0) == 64 and DM.cap(64, 1) == 64 and DM.cap(64, 2) == 80 and DM.cap(64, 6) == 80)
	check("every rift is Mega from Doom 3", not DM.mega_rift(2) and DM.mega_rift(3))
	check("enemy damage +10% per level from Doom 5", DM.enemy_dmg_k(4) == 1.0 and absf(DM.enemy_dmg_k(5) - 1.1) < 0.001 and absf(DM.enemy_dmg_k(7) - 1.3) < 0.001)
	check("coins x(1 + 0.25 per level), max x2.5", DM.coin_k(0) == 1.0 and DM.coin_k(2) == 1.5 and DM.coin_k(6) == 2.5 and DM.coin_k(20) == 2.5)
	check("Mega bonus +10% per level, max +30%", DM.mega_atk_k(0) == 1.0 and absf(DM.mega_atk_k(2) - 1.2) < 0.001 and absf(DM.mega_atk_k(9) - 1.3) < 0.001)
	check("wild legendaries +1 per level, max +3", DM.wl_extra(0) == 0 and DM.wl_extra(2) == 2 and DM.wl_extra(9) == 3)
	# ---------- a real run ----------
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true   # keep the director (rifts, arena threads, an Eternatus) out of the hand-driven checks
	m.rift_check = 1.0e9
	m.jd.done = true
	check("spawner cap follows Doom", m._cap() == 64)
	m.eter_kills = 2
	check("spawner cap is 80 at Doom 2", m._cap() == 80)
	m.eter_kills = 0
	# --- Overcap
	check("Overcap ceilings: Power 40 -> 50, Armor stays 12", m._stat_cap("atk") == 50.0 and m._stat_cap("def") == 12.0 and m._stat_cap("spd") == 8.0)
	m.stat_lv["def"] = 12.0
	m.stat_lv["atk"] = 40.0
	m.player.level = 40
	var over_seen := false
	var def_seen := false
	var over_mult := 0.0
	for i in range(80):
		for c in m._offer():
			if String(c["cat"]) == "stat" and String(c["id"]) == "atk":
				over_seen = true
				over_mult = float(c["mult"])
			if String(c["cat"]) == "stat" and String(c["id"]) == "def":
				def_seen = true
	check("a capped Power still shows up, as a half-effect Overcap card", over_seen and over_mult == 0.5, "mult %s" % str(over_mult))
	check("a capped Armor (no overcap) is no longer offered", not def_seen)
	var pend: int = 3
	m.pending_levels = pend
	m.cards.items = [{"cat": "stat", "id": "atk", "mult": 0.5}]
	m._on_card_chosen(0)
	check("taking Overcap adds half a level", m._lvf("atk") == 40.5 and m.pending_levels == pend - 1, str(m._lvf("atk")))
	m.stat_lv["atk"] = 49.8
	m.cards.items = [{"cat": "stat", "id": "atk", "mult": 0.5}]
	m._on_card_chosen(0)
	check("Overcap never passes 125% of the cap", m._lvf("atk") == 50.0, str(m._lvf("atk")))
	var capped_seen := false
	for i in range(60):
		for c in m._offer():
			if String(c["cat"]) == "stat" and String(c["id"]) == "atk":
				capped_seen = true
	check("a fully overcapped stat is not offered again", not capped_seen)
	m.stat_lv["atk"] = 0.0
	m.stat_lv["def"] = 0.0
	# --- endgame cards
	check("no endgame cards before the first Eternatus", DM.card(m).is_empty())
	m.eter_kills = 1
	var seen := {}
	for i in range(60):
		var dc: Dictionary = DM.card(m)
		if not dc.is_empty():
			seen[String(dc["id"])] = true
	check("after Eternatus the three endgame cards can appear", seen.has("wind") and seen.has("drive") and seen.has("apex"), str(seen.keys()))
	var r0: int = m.revives
	m.pending_levels = 2
	m.cards.items = [DM.card(m)]
	m.cards.items[0]["id"] = "wind"
	m._on_card_chosen(0)
	check("Second Wind: +1 revive, one per Doom level", m.revives == r0 + 1 and m.doom_winds == 1 and m.pending_levels == 1)
	var still_wind := false
	for i in range(60):
		var dc2: Dictionary = DM.card(m)
		if not dc2.is_empty() and String(dc2["id"]) == "wind":
			still_wind = true
	check("Second Wind is not offered again at the same Doom level", not still_wind)
	for i in range(4):
		DM.apply(m, "drive")
	check("Overdrive stacks down to half the dash cooldown", m.dash_k == 0.5, str(m.dash_k))
	DM.apply(m, "apex")
	DM.apply(m, "apex")
	check("Apex Predator: +10 Momentum charges, capped", m.mom_max == 20.0)
	check("all three exhausted -> no card", DM.card(m).is_empty())
	m.dash_cd = 0.0
	m._dash_start()
	check("dash cooldown uses Overdrive", absf(m.dash_cd - m.DASH_CD * 0.5) < 0.001, str(m.dash_cd))
	# --- elites with traits and the swarm
	m.run_time = 3000.0
	var traits := 0
	var weak := 0
	m.eter_kills = 0
	var base_traits := 0
	for i in range(240):
		var e0 = m._spawn_one()
		var col: Color = e0.modulate
		if col.is_equal_approx(Color(0.62, 0.85, 1.0)) or col.is_equal_approx(Color(0.78, 0.8, 0.88)):
			base_traits += 1
		e0.dead = true
		m.enemies.erase(e0)
		e0.queue_free()
	m.eter_kills = 1
	for i in range(240):
		var e1 = m._spawn_one()
		var col1: Color = e1.modulate
		if col1.is_equal_approx(Color(0.62, 0.85, 1.0)) or col1.is_equal_approx(Color(0.78, 0.8, 0.88)):
			traits += 1
		e1.dead = true
		m.enemies.erase(e1)
		e1.queue_free()
	check("Doom 0: no elite traits", base_traits == 0, str(base_traits))
	check("Doom 1: about a quarter of spawns are elites with a trait", traits >= 30 and traits <= 95, "%d / 240" % traits)
	# --- HUD
	m.eter_kills = 2
	await process_frame
	await process_frame
	check("HUD shows the Doom level and the Overdrive dash bar", m.hud.doom == 2 and absf(m.hud.dash_max - m.DASH_CD * 0.5) < 0.001, "%d %s" % [m.hud.doom, str(m.hud.dash_max)])
	# --- summary line
	m.eter_kills = 2
	m._finish_run()
	check("run summary mentions the Eternatus count", String(SV.last_run.get("breakdown", "")).contains("2"), String(SV.last_run.get("breakdown", "")))
	var top_doom := 0
	for te in SV.d.get("top", []):
		top_doom = maxi(top_doom, int(te.get("doom", 0)))
	check("the local leaderboard keeps the Doom level of the run", top_doom == 2, str(top_doom))
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	menu._goals_records()
	var seen_doom := false
	var stack: Array = [menu.goals_box]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd is Label and String(nd.text).contains("DOOM II"):
			seen_doom = true
		stack.append_array(nd.get_children())
	check("the records list shows 'DOOM II' next to that run", seen_doom)
	menu.queue_free()
	# ---------- Eternatus learns new attacks ----------
	var m2 = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m2)
	await process_frame
	await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m2.dir_done[id] = true
	m2.rift_check = 1.0e9
	m2.jd.done = true
	m2.run_time = 3600.0
	m2.perks["def"] = 0.0
	m2.eter_kills = 0
	m2._spawn_eternatus()
	var x0 = m2.etx
	check("first Eternatus knows no Doom attacks", x0.doom == 0)
	m2.player.max_hp = 1000.0
	m2.player.hp = 1000.0
	m2.player.position = m2.dir_eter.position + Vector2(300.0, 0.0)
	x0.beam_cd = 999.0; x0.cannon_cd = 999.0; x0.ring_cd = 999.0; x0.meteor_cd = 999.0
	var t0: int = 0
	for i in range(40 * 60):
		x0.tick(1.0 / 60.0)
		m2.player.hp = 1000.0
		m2.player.position = m2.dir_eter.position + Vector2(300.0, 0.0)
	check("Doom 0: no Gravity Well ever starts", x0.well.is_empty() and x0.well_cd > 0.0 and not x0.done, "cd %.1f" % x0.well_cd)
	x0.stop()
	m2.etx = null
	m2.dir_eter.dead = true
	m2.enemies.erase(m2.dir_eter)
	m2.eter_kills = 1
	m2._spawn_eternatus()
	var x = m2.etx
	var e = m2.dir_eter
	check("second Eternatus reads the Doom level", x.doom == 1)
	check("no Well yet at spawn", x.well.is_empty())
	x.beam_cd = 999.0; x.cannon_cd = 999.0; x.ring_cd = 999.0; x.meteor_cd = 999.0
	x.well_cd = 0.0
	var steps: int = int((x.WELL_WINDUP / x.cadence() + x.WELL_PULL_T) * 60.0) + 6
	var min_d: float = 300.0
	for k in range(8):   # a prop may block one approach path: try the 8 compass directions
		m2.player.position = e.position + Vector2.from_angle(PI * 0.25 * float(k)) * 300.0
		m2.player.hp = 1000.0
		m2.player.invuln = 0.0
		x.well = {}
		x._start_well()
		if k == 0:
			check("the Well telegraphs first (charge phase)", not x.well.is_empty() and String(x.well["phase"]) == "charge")
		min_d = 300.0
		for i in range(steps):
			x._tick_well(1.0 / 60.0, m2.player.position)
			min_d = minf(min_d, m2.player.position.distance_to(e.position))
			m2.player.invuln = 0.0
		if min_d < 80.0:
			break
	check("standing still, the Well drags the player to the core and explodes for 30%", min_d < 80.0 and absf((1000.0 - m2.player.hp) - 300.0) < 1.0 and x.well.is_empty(), "min dist %.0f lost %.0f" % [min_d, 1000.0 - m2.player.hp])
	# walking away at 150 px/s beats the 110 px/s pull
	m2.player.hp = 1000.0
	m2.player.invuln = 0.0
	m2.player.position = e.position + Vector2(300.0, 0.0)
	x._start_well()
	for i in range(steps):
		x._tick_well(1.0 / 60.0, m2.player.position)
		m2.player.position += Vector2(150.0 / 60.0, 0.0)
	check("walking away beats the pull and takes no damage", m2.player.hp >= 999.0 and m2.player.position.distance_to(e.position) > 300.0, "hp %.0f dist %.0f" % [m2.player.hp, m2.player.position.distance_to(e.position)])
	# double beam: Doom 2 -> two sweeps, Doom 1 -> one
	var sweeps: Array = []
	for dm in [1, 2]:
		x.doom = dm
		x.beam = {}
		x.beam_cd = 999.0
		m2.player.position = e.position + Vector2(900.0, 0.0)   # out of the beam's reach
		x._start_beam()
		var n_sweep := 0
		var was_sweep := false
		for i in range(30 * 60):
			x._tick_beam(1.0 / 60.0, m2.player.position)
			var is_sweep: bool = (not x.beam.is_empty()) and String(x.beam["phase"]) == "sweep"
			if is_sweep and not was_sweep:
				n_sweep += 1
			was_sweep = is_sweep
			if x.beam.is_empty():
				break
		sweeps.append(n_sweep)
	check("Eternabeam sweeps once at Doom 1 and twice at Doom 2", sweeps == [1, 2], str(sweeps))
	# obelisks regrow from Doom 3
	for dm in [2, 3]:
		x.doom = dm
		for o in x.obelisks:
			o.dead = true
		x.regen_cd = x.OBELISK_REGEN
		x.well_cd = 1.0e9
		var alive0: int = x.alive_obelisks()
		for i in range(int((x.OBELISK_REGEN + 3.0) * 60.0)):
			x.tick(1.0 / 60.0)
			m2.player.hp = 1000.0
			m2.player.position = e.position + Vector2(900.0, 0.0)
		if dm == 2:
			check("Doom 2: dead obelisks stay dead", alive0 == 0 and x.alive_obelisks() == 0, str(x.alive_obelisks()))
		else:
			check("Doom 3: a dead obelisk comes back after 45 s", alive0 == 0 and x.alive_obelisks() >= 1, str(x.alive_obelisks()))
	# ---------- achievements ----------
	var ids := {}
	for a in PG.list():
		ids[String(a["id"])] = a
	check("new achievements exist", ids.has("time30") and ids.has("time60") and ids.has("eter1") and ids.has("eter2") and ids.has("eter3") and ids.has("eter5"))
	SV.d["stats"]["eterBestRun"] = 3
	SV.d["stats"]["eternatusKills"] = 3
	check("Doom achievements follow the best run", PG.value(ids["eter3"]) >= int(ids["eter3"]["goal"]) and PG.value(ids["eter5"]) < int(ids["eter5"]["goal"]))
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
