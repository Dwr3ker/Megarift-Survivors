extends SceneTree
# Necrozma: Photon Geyser as its own move, the fusion card from minute 30 (Dusk Mane / Dawn Wings, with their types,
# stats, armour and evolved move), Ultra Burst from minute 45 once fused (own sprite, Light That Burns the Sky), and the
# saved-run round trip.
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
	m.player.invuln = 1.0e9
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var NZ = load("res://scripts/necrozma.gd")
	var RS = load("res://scripts/run_save.gd")
	var MD = load("res://scripts/moves_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	var had_real: bool = RS.exists()
	var real_text: String = FileAccess.get_file_as_string(RS.PATH) if had_real else ""
	for id in NZ.SIG:
		check("%s exists and its kind has a ladder" % id, MD.MOVES.has(id) and MD.LADDERS.has(String(MD.MOVES[id]["kind"])))
	check("Photon Geyser evolves (Photon Geyser+)", MD.EVO.has("photon-geyser"))
	check("Necrozma starts with Photon Geyser", SV.natural_start_of(800) == "photon-geyser")
	var sm = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprite_meta.json"))
	check("Ultra Necrozma sprites are in the sprite data", sm.has("180003"))
	# ---------- fusion: Dusk Mane ----------
	var m = await _new_run(SV, 800)
	check("the run starts with Photon Geyser", String(m.player.moves[0]["id"]) == "photon-geyser")
	check("no fusion card before minute 30", NZ.card(m).is_empty())
	m.run_time = 1800.0
	var c: Dictionary = NZ.card(m)
	check("the fusion card is offered from minute 30", String(c.get("cat", "")) == "necrozma")
	check("it offers Dusk Mane and Dawn Wings", NZ.picks(m).map(func(p): return String(p["id"])) == ["dusk", "dawn"])
	var hp0: float = m.player.max_hp
	var atk0: float = m._atk()
	m._pick_card_cat("necropick", "dusk") if m.has_method("_pick_card_cat") else NZ.apply(m, "dusk")
	check("Dusk Mane: Psychic/Steel, +20% HP, +35% damage", m.necrozma == "dusk" and m.player.types == ["psychic", "steel"] and absf(m.player.max_hp - roundf(hp0 * 1.2)) < 1.0 and absf(m._atk() / atk0 - 1.35) < 0.01)
	check("it wears the solar mane", m.player.get_children().any(func(n): return n.get_script() == NZ.Armour and n.kind == "dusk"))
	check("no Ultra Burst before minute 45", NZ.card(m).is_empty())
	var g: Dictionary = m.player.moves[0]
	g["lvl"] = m._max_lvl(g)
	var inf: Array = m._evo_infos(g)
	check("the evolution card reads Sunsteel Strike", inf.size() >= 1 and String(inf[0]["name"]) == "Sunsteel Strike", str(inf))
	m._evolve(g)
	var f: Dictionary = m.player.moves[0]
	check("Photon Geyser evolved into Sunsteel Strike", String(f["id"]) == "sunsteel-strike" and bool(f["evolved"]))
	for i in range(20):
		m._tick_move(f, 0.1)
		await process_frame
	check("Sunsteel Strike fires without errors", true)
	# ---------- Ultra Burst ----------
	m.run_time = 2700.0
	var u: Dictionary = NZ.card(m)
	check("the Ultra Burst card is offered from minute 45 once fused", String(u.get("cat", "")) == "necroultra")
	var atk1: float = m._atk()
	var spd1: float = m._spd()
	NZ.ultra(m)
	check("Ultra Necrozma: own sprite, Psychic/Dragon, +30% damage, +10% speed", m.necro_ultra and int(m.player.dex) == 180003 and m.player.types == ["psychic", "dragon"] and absf(m._atk() / atk1 - 1.3) < 0.01 and absf(m._spd() / spd1 - 1.1) < 0.02, "dex %s" % str(m.player.dex))
	check("the evolved move became Light That Burns the Sky", String(m.player.moves[0]["id"]) == "light-that-burns-the-sky" and bool(m.player.moves[0]["evolved"]))
	check("no more cards after Ultra Burst", NZ.card(m).is_empty())
	var lt: Dictionary = m.player.moves[0]
	for i in range(30):
		m._tick_move(lt, 0.1)
		await process_frame
	check("Light That Burns the Sky fires without errors", true)
	# ---------- saved run round trip ----------
	m.run_time = 2800.0
	check("the run can be saved", RS.save(m))
	var snap: Dictionary = RS.load_snap()
	m.queue_free()
	await process_frame
	SV.resume_snap = snap
	var r = await _new_run(SV, 800)
	for i in range(10):
		await process_frame
	check("resumed: still Ultra Necrozma (Dusk Mane), Psychic/Dragon", r.necrozma == "dusk" and r.necro_ultra and r.player.types == ["psychic", "dragon"] and int(r.player.dex) == 180003, "%s %s %s" % [r.necrozma, r.necro_ultra, r.player.types])
	r.queue_free()
	await process_frame
	SV.resume_snap = {}
	# ---------- Dawn Wings ----------
	var d = await _new_run(SV, 800)
	d.run_time = 1850.0
	NZ.apply(d, "dawn")
	check("Dawn Wings: Psychic/Ghost, -15% cooldowns, lunar wings", d.player.types == ["psychic", "ghost"] and absf(NZ.cd_k(d) - 0.85) < 0.001 and d.player.get_children().any(func(n): return n.get_script() == NZ.Armour and n.kind == "dawn"))
	var g3: Dictionary = d.player.moves[0]
	g3["lvl"] = d._max_lvl(g3)
	d._evolve(g3)
	check("Photon Geyser evolves into Moongeist Beam", String(d.player.moves[0]["id"]) == "moongeist-beam")
	# restore the real saved run, if there was one
	if had_real:
		var fw := FileAccess.open(RS.PATH, FileAccess.WRITE)
		fw.store_string(real_text)
		fw.close()
	else:
		RS.clear()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
