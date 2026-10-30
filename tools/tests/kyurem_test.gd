extends SceneTree
# Headless check of Kyurem: Glaciate as its own move, the DNA Splicers card from minute 30, the Black / White fusion,
# Glaciate evolving into Freeze Shock / Ice Burn (or Glaciate+ without the fusion), and the saved-run round trip.
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
	var KYU = load("res://scripts/kyurem.gd")
	var RS = load("res://scripts/run_save.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	var had_real: bool = RS.exists()
	var real_text: String = FileAccess.get_file_as_string(RS.PATH) if had_real else ""
	# ---------- data ----------
	var MD = load("res://scripts/moves_data.gd")
	for id in ["glaciate", "freeze-shock", "ice-burn-white"]:
		check("%s exists and its kind has a ladder" % id, MD.MOVES.has(id) and MD.LADDERS.has(String(MD.MOVES[id]["kind"])))
	check("Glaciate evolves (Glaciate+)", MD.EVO.has("glaciate") and String(MD.EVO["glaciate"][0]) == "Glaciate+")
	check("Kyurem starts with Glaciate", SV.natural_start_of(646) == "glaciate")
	check("Freeze Shock paralyses and Ice Burn burns", String(MD.MOVES["freeze-shock"]["cc"]) == "para" and int(MD.MOVES["ice-burn-white"]["burn"]) == 1)
	var sm = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprite_meta.json"))
	check("Black and White Kyurem sprites are in the sprite data", sm.has("164601") and sm.has("164602"))
	# ---------- a Kyurem run ----------
	var m = await _new_run(SV, 646)
	check("the run starts with Glaciate", m.player.moves.size() == 1 and String(m.player.moves[0]["id"]) == "glaciate")
	check("no DNA Splicers card before minute 30", KYU.card(m).is_empty())
	m.run_time = 1800.0
	var c: Dictionary = KYU.card(m)
	check("the card is offered from minute 30", not c.is_empty() and String(c["cat"]) == "kyurem" and String(c["tag"]) != "")
	var pk: Array = KYU.picks(m)
	check("it offers Black and White Kyurem", pk.size() == 2 and String(pk[0]["id"]) == "black" and String(pk[1]["id"]) == "white")
	# ---------- Glaciate evolves into Freeze Shock after the fusion (Black) ----------
	var hp0: float = m.player.max_hp
	var atk0: float = m._atk()
	KYU.apply(m, "black")
	check("Black Kyurem: new body, +20% HP, +40% damage", m.kyurem == "black" and absf(m.player.max_hp - roundf(hp0 * 1.2)) < 1.0 and absf(m._atk() / atk0 - 1.4) < 0.01, "%.0f -> %.0f" % [hp0, m.player.max_hp])
	check("the card is gone once fused", KYU.card(m).is_empty())
	var g: Dictionary = m.player.moves[0]
	g["lvl"] = m._max_lvl(g)
	var inf: Array = m._evo_infos(g)
	check("the evolution card reads Freeze Shock", inf.size() == 1 and String(inf[0]["name"]) == "Freeze Shock", str(inf))
	m._evolve(g)
	var f: Dictionary = m.player.moves[0]
	check("Glaciate evolved into Freeze Shock (evolved, level kept)", String(f["id"]) == "freeze-shock" and bool(f["evolved"]) and int(f["lvl"]) == m._max_lvl(f) and String(f["name"]) == "Freeze Shock")
	check("it paralyses and is a beam", String(f["kind"]) == "beam" and String(f["cc"]) == "para")
	for i in range(30):
		m._tick_move(f, 0.1)
		await process_frame
	check("the evolved lance fires without errors", true)
	m.queue_free()
	await process_frame
	# ---------- already evolved when fusing (White) ----------
	var m2 = await _new_run(SV, 646)
	var g2: Dictionary = m2.player.moves[0]
	g2["lvl"] = m2._max_lvl(g2)
	m2._evolve(g2)
	check("without the fusion it evolves into Glaciate+", String(m2.player.moves[0]["name"]) == "Glaciate+" and String(m2.player.moves[0]["id"]) == "glaciate")
	m2.run_time = 1900.0
	m2.bond_ids = []
	KYU.apply(m2, "white")
	var w: Dictionary = m2.player.moves[0]
	check("fusing turns an evolved Glaciate+ into Ice Burn", String(w["id"]) == "ice-burn-white" and String(w["name"]) == "Ice Burn" and bool(w["evolved"]), String(w["name"]))
	check("White Kyurem: burn and -15% cooldowns", int(w["burn"]) == 1 and absf(m2._cd_mul_raw() / pow(0.92, m2._lvf("cd")) - 0.85) < 0.2)
	for i in range(30):
		m2._tick_move(w, 0.1)
		await process_frame
	check("Ice Burn fires without errors", true)
	# ---------- saved run keeps the form ----------
	check("a Kyurem run can be saved", RS.save(m2), RS.block_reason(m2))
	var snap: Dictionary = RS.load_snap()
	m2.queue_free()
	await process_frame
	SV.resume_snap = snap
	var m3 = await _new_run(SV, int(snap["dex"]))
	check("the resumed run is still White Kyurem with Ice Burn", m3.kyurem == "white" and String(m3.player.moves[0]["id"]) == "ice-burn-white", str(m3.kyurem))
	m3.queue_free()
	await process_frame
	# ---------- another Pokémon never gets the card ----------
	var m4 = await _new_run(SV, 6)
	m4.run_time = 2000.0
	check("other Pokémon get no DNA Splicers card", KYU.card(m4).is_empty())
	m4.queue_free()
	await process_frame
	RS.clear()
	if had_real:
		var rf := FileAccess.open(RS.PATH, FileAccess.WRITE)
		rf.store_string(real_text)
		rf.close()
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
