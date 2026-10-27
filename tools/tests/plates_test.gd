extends SceneTree
# Headless check: Arceus starts with Judgment; type plates (gating, flow, type/body/move change, STAB, move pool, sprites).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func make_run(SV, dex: int):
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	return m

func judgment(m) -> Dictionary:
	for mv in m.player.moves:
		if String(mv["id"]) == "judgment": return mv
	return {}

func move_pool(m) -> Dictionary:
	var seen := {}
	for i in range(300):
		for c in m._offer():
			if String(c["cat"]) == "new": seen[String(c["id"])] = String(m.MD.MOVES[String(c["id"])]["type"])
	return seen

func _init() -> void:
	var PL = load("res://scripts/plates.gd")
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end
	# --- other Pokemon unaffected
	var mc = await make_run(SV, 6)
	check("Charizard keeps its own starting move (Ascuas)", String(mc.player.moves[0]["id"]) == "ember", String(mc.player.moves[0]["id"]))
	mc.run_time = 1000.0
	check("Charizard never gets a plate card", PL.card(mc).is_empty())
	mc.queue_free()
	await process_frame
	# --- Arceus
	var m = await make_run(SV, 493)
	var j: Dictionary = judgment(m)
	check("Arceus starts with Judgment", not j.is_empty() and m.player.moves[0] == j, String(m.player.moves[0]["id"]))
	check("Judgment is a normal-type homing projectile", String(j["type"]) == "normal" and String(j["kind"]) == "projectile" and float(j["homing"]) >= 4.0)
	check("Arceus is Normal at the start", m.player.types == ["normal"])
	m.run_time = 200.0
	check("no plate card before minute 5", PL.card(m).is_empty())
	m.run_time = 400.0
	var c: Dictionary = PL.card(m)
	check("plate card after minute 5", not c.is_empty() and String(c["cat"]) == "plate" and String(c["ptype"]) != "normal", String(c.get("title", "")))
	var seen := 0
	for i in range(500):
		for x in m._offer():
			if String(x["cat"]) == "plate": seen += 1
	check("shows up in real offers at roughly 15%", seen > 30 and seen < 130, "%d of 500" % seen)
	var pool_before: Dictionary = move_pool(m)
	# --- pick a Fire plate through the real card flow
	m.pending_levels = 2
	var card := {"cat": "plate", "id": "plate", "key": "plate:fire", "ptype": "fire", "title": "x", "desc": "x", "tag": "x", "color": Color.WHITE, "w": 1.0}
	m.cards.items = [card]
	m.choosing = true
	m._on_card_chosen(0)
	check("Fire plate: Arceus is Fire type", m.player.types == ["fire"], str(m.player.types))
	check("Fire plate: Judgment turns Fire", String(judgment(m)["type"]) == "fire")
	check("Fire plate: body is the Fire form (149306)", m.player.dex == 149306, str(m.player.dex))
	check("choice closed and the level-up consumed", not m.choosing and m.pending_levels == 1)
	check("plate bookkeeping", m.plate == "fire" and m.plate_t == m.run_time)
	check("another plate cannot be offered right away (cooldown)", PL.card(m).is_empty())
	# --- the plate must not change which moves are offered
	var pool_after: Dictionary = move_pool(m)
	var types_after := {}
	for id in pool_after: types_after[pool_after[id]] = true
	check("offered move types stay Normal after the plate", types_after.keys() == ["normal"], str(types_after.keys()))
	check("same move pool before and after", pool_before.keys().size() > 0 and pool_after.keys().size() > 0 and (pool_after.keys().all(func(k): return pool_before.has(k)) or pool_before.keys().all(func(k): return pool_after.has(k))))
	# --- STAB on the new type
	var e = null
	for i in range(1200):
		await process_frame
		for en in m.enemies:
			if not en.dead and en.shield <= 0.0 and not en.boss:
				e = en
				break
		if e != null: break
	m.perks["crit"] = 0.0
	var res := {}
	for mt in ["fire", "water"]:
		e.max_hp = 1.0e9; e.hp = 1.0e9
		m._hit_enemy(e, 100.0, Color.WHITE, Vector2.ZERO, 0.0, mt, 0, 0, 0.0)
		res[mt] = (1.0e9 - e.hp) / (100.0 * m._type_mult(mt, e))
	check("Judgment as Fire gets STAB (+10%)", absf(res["fire"] / res["water"] - 1.1) < 0.01, "%.3f" % (res["fire"] / res["water"]))
	# --- switching and the blank plate
	m.run_time += 60.0
	var c2: Dictionary = PL.card(m)
	check("a different plate is offered after the cooldown", not c2.is_empty() and String(c2["ptype"]) != "fire")
	PL.apply(m, "normal")
	check("Blank Plate: back to Normal and the base body", m.player.types == ["normal"] and m.player.dex == 493 and String(judgment(m)["type"]) == "normal", "%s %d" % [str(m.player.types), m.player.dex])
	PL.apply(m, "ghost")
	check("Ghost plate: body is the Ghost form", m.player.dex == 100000 + 493 * 100 + 8, str(m.player.dex))
	# --- Judgment evolves
	var jm: Dictionary = judgment(m)
	jm["lvl"] = m._max_lvl(jm)
	m._evolve(jm)
	check("Judgment evolves to Max Judgment", bool(jm["evolved"]) and String(jm["name"]) == "Max Judgment", String(jm["name"]))
	# --- every plate has complete sprite sets
	var bad := 0
	for p in PL.list():
		var fid: int = int(p["form"])
		if not SV.smeta.has(str(fid)): bad += 1; print("no meta ", p["id"]); continue
		for a in ["Idle", "Walk", "Attack", "Shoot", "Charge", "Hurt", "Faint"]:
			if load("res://assets/pokemon/%d/%s.png" % [fid, a]) == null: bad += 1
	check("all 18 plates have complete sprites", PL.list().size() == 18 and bad == 0, "bad=%d" % bad)
	SV.d = _guard
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
