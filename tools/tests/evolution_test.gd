extends SceneTree
# Headless check of in-run evolution: the chain data, the evolution card, applying an evolution (body, stats, heal, bonus),
# choosing between branches (Eevee), the saved-run round trip, and the balance between starting unevolved and fully evolved.
const EVL = preload("res://scripts/evolution.gd")
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _new_run(SV, dex: int):
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(14):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	m.jd.done = true
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var RS = load("res://scripts/run_save.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.load_dex()
	var had_real: bool = RS.exists()
	var real_text: String = FileAccess.get_file_as_string(RS.PATH) if had_real else ""
	RS.clear()
	# ---------- data ----------
	check("Charmander -> Charmeleon -> Charizard", EVL.evolves_to(4) == [5] and EVL.evolves_to(5) == [6] and EVL.evolves_to(6).is_empty() and EVL.line_len(6) == 3 and EVL.stage_of(5) == 2)
	check("Eevee has several evolutions", EVL.evolves_to(133).size() >= 5 and EVL.line_len(133) == 2)
	check("a Pokémon with no line does not evolve", EVL.level_for(150) == 0 and EVL.line_len(150) == 1 and EVL.start_progress(150) == 1.0)
	check("the card level depends on the stage", EVL.level_for(4) > 0 and EVL.level_for(5) > EVL.level_for(4) and EVL.level_for(6) == 0)
	var bad := 0
	for k in EVL._data:
		for c in EVL._data[k]["to"]:
			if not SV.dex_by.has(int(c)) or not SV.smeta.has(str(int(c))):
				bad += 1
	check("every evolution target exists with a sprite", bad == 0, str(bad))
	# ---------- a Charmander run ----------
	var m = await _new_run(SV, 4)
	check("the run starts as Charmander", m._cur_dex() == 4 and EVL.card(m).is_empty())
	var need: int = EVL.level_for(4)
	m.player.level = need - 1
	check("no card before the level", EVL.card(m).is_empty())
	m.player.level = need
	var c: Dictionary = EVL.card(m)
	check("the card appears at the level", not c.is_empty() and String(c["cat"]) == "evolve")
	var picks: Array = m._offer()
	check("it is always among the offered cards", picks.any(func(x): return String(x["cat"]) == "evolve"))
	var hp0: float = m.player.max_hp
	var atk0: float = m._atk()
	var spd0: float = m._spd()
	m.player.hp = hp0 * 0.3
	EVL.apply(m, 5)
	check("Charmander became Charmeleon", m._cur_dex() == 5 and m.player.dex == 5 and m._pdex() == 4 and m.player.types == m._dex_by[5]["types"])
	check("evolving fully heals", absf(m.player.hp - m.player.max_hp) < 0.5)
	check("max HP rises with the stage and the surge", m.player.max_hp > hp0, "%.0f -> %.0f" % [hp0, m.player.max_hp])
	check("damage and speed rise", m._atk() > atk0 * 1.05 and m._spd() > spd0, "%.2f -> %.2f" % [atk0, m._atk()])
	check("it can evolve again later", EVL.level_for(5) > need and EVL.card(m).is_empty())
	m.player.level = EVL.level_for(5)
	check("the second card appears", not EVL.card(m).is_empty())
	EVL.apply(m, 6)
	check("Charizard is the last stage", m._cur_dex() == 6 and EVL.level_for(6) == 0 and m.evo_steps == 2)
	m.run_time = 2000.0
	check("an evolved starter cannot Mega Evolve (that needs starting as the Mega-capable Pokémon)", load("res://scripts/mega.gd").card(m).is_empty())
	# ---------- a saved run keeps the evolution ----------
	check("a run can be saved", RS.save(m), RS.block_reason(m))
	var snap: Dictionary = RS.load_snap()
	var evo_dmg: float = m.evo_dmg
	m.queue_free()
	await process_frame
	SV.resume_snap = snap
	var m2 = await _new_run(SV, int(snap["dex"]))
	check("the resumed run is still Charizard with its bonuses", m2._cur_dex() == 6 and m2.player.dex == 6 and absf(m2.evo_dmg - evo_dmg) < 0.0001 and m2.evo_steps == 2)
	m2.queue_free()
	await process_frame
	# ---------- Eevee: several forms ----------
	var m3 = await _new_run(SV, 133)
	m3.player.level = EVL.level_for(133)
	check("Eevee gets the card", not EVL.card(m3).is_empty())
	check("and picks between several evolutions", EVL.picks(m3).size() >= 5)
	EVL.apply(m3, 134)
	check("Eevee became Vaporeon", m3._cur_dex() == 134)
	m3.queue_free()
	await process_frame
	# ---------- fully evolved start: seasoned ----------
	var m4 = await _new_run(SV, 6)
	check("Charizard starts fully evolved: no card, seasoned bonus grows with level", EVL.card(m4).is_empty() and EVL.seasoned(6, 1)["dmg"] < EVL.seasoned(6, 40)["dmg"])
	var hp_a: float = m4.player.max_hp
	m4.player.level = 40
	EVL.tick(m4)
	check("the seasoned bonus raises max HP and damage", m4.player.max_hp > hp_a and m4.seas_dmg > 0.0, "%.0f -> %.0f" % [hp_a, m4.player.max_hp])
	var hp_b: float = m4.player.max_hp
	m4.seas_level_seen = -1
	EVL.tick(m4)
	check("it is never applied twice", absf(m4.player.max_hp - hp_b) < 0.5)
	m4.queue_free()
	await process_frame
	# ---------- balance: unevolved start vs fully evolved start ----------
	var levels := [1, 8, 16, 25, 34, 40, 50, 60]
	var lines := [[4, 5, 6], [1, 2, 3], [7, 8, 9], [246, 247, 248], [447, 448], [133, 134]]
	var worst_early := 99.0
	var worst_late := -99.0
	var best_late := 99.0
	for ln in lines:
		var first: int = int(ln[0])
		var last: int = int(ln[ln.size() - 1])
		var out := ""
		for lv in levels:
			var pf: float = _power(SV, first, int(lv), true)
			var pl: float = _power(SV, last, int(lv), false)
			if lv == 1:
				worst_early = minf(worst_early, pl / pf)
			if lv == 60:
				worst_late = maxf(worst_late, pf / pl)
				best_late = minf(best_late, pf / pl)
			out += " L%d:%.2f" % [lv, pf / pl]
		print("      ", SV.dex_by[first]["name"], " (unevolved / evolved power)", out)
	check("early game: the evolved start is clearly stronger (at least +15% power)", worst_early >= 1.15, "%.2f" % worst_early)
	check("late game: the unevolved start leads, but only by a few percent (1% to 10%)", worst_late <= 1.10 and best_late >= 1.01, "%.3f to %.3f" % [best_late, worst_late])
	RS.clear()
	if had_real:
		var rf := FileAccess.open(RS.PATH, FileAccess.WRITE)
		rf.store_string(real_text)
		rf.close()
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

# Rough power index of a run's Pokémon at a player level: HP x damage x speed^0.5, with the stage the unevolved start has
# reached by then (cards at EVL.LEVELS) and the surge / seasoned bonus it has earned.
func _power(SV, start: int, lv: int, unevolved: bool) -> float:
	var d: int = start
	var dmg_b := 0.0
	var hp_b := 0.0
	var spd_b := 0.0
	if unevolved:
		var cur: int = start
		while EVL.level_for(cur) > 0 and lv >= EVL.level_for(cur):
			var to: Array = EVL.evolves_to(cur)
			var share: float = EVL.step_share(cur)
			dmg_b += EVL.SURGE_DMG * share
			hp_b += EVL.SURGE_HP * share
			spd_b += EVL.SURGE_SPD * share
			cur = int(to[0])
		d = cur
	else:
		var s: Dictionary = EVL.seasoned(start, lv)
		dmg_b = float(s["dmg"])
		hp_b = float(s["hp"])
		spd_b = float(s["spd"])
	var p: Dictionary = SV.dex_by[d]
	return float(p["hp"]) * (1.0 + hp_b) * float(p["atk"]) * (1.0 + dmg_b) * pow(float(p["spd"]) * (1.0 + spd_b), 0.5)
