extends SceneTree
# Headless check of move fusion: pairs, chained fusions up to 4 moves, the 4-move cap, and what the slot bar shows.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _evolved(m, id: String) -> Dictionary:
	var mv: Dictionary = m._new_move(id, 1)
	for i in range(m._max_lvl(mv) - 1):
		m._level_up_move(mv)
	mv["evolved"] = true
	return mv

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(20):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	m.jd.done = true
	var ids := ["flash-cannon", "hyper-voice", "rock-slide", "hail", "meteor-mash"]
	var mv: Array = []
	for id in ids:
		mv.append(_evolved(m, id))
	mv[4]["evolved"] = false   # the fifth is not evolved
	m.player.moves = mv.duplicate()
	# ---------- a normal pair ----------
	m.bond_ids = [ids[0], ids[1]]
	check("two evolved max-level bonded moves can fuse", m._fuse_ready())
	m._do_fuse()
	check("they become one move with two parts", m.player.moves.size() == 4 and (m.player.moves[0]["parts"] as Array).size() == 2, str(m.player.moves.size()))
	check("the bond is released after fusing", m.bond_ids.is_empty())
	m._refresh_slots()
	check("the slot bar shows both originals", m.slots.info.size() == 4 and (m.slots.info[0]["icons"] as Array).size() == 2 and int(m.slots.info[0]["n"]) == 2)
	# ---------- a fused move can fuse again (3 parts) ----------
	m.bond_ids = [String(m.player.moves[0]["id"]), ids[2]]
	check("a fusion and a plain move can fuse", m._fuse_ready())
	m._do_fuse()
	var f3: Dictionary = m.player.moves[0]
	check("three parts in one move, parts are not boosted twice", (f3["parts"] as Array).size() == 3 and m.player.moves.size() == 3)
	var d0: float = float(mv[0]["dmg"])
	check("every part got the fusion bonus exactly once", absf(float(f3["parts"][0]["dmg"]) - d0) < 0.001, "%.1f" % d0)
	# ---------- up to 4 ----------
	m.bond_ids = [String(f3["id"]), ids[3]]
	check("the fourth move can join", m._fuse_ready())
	m._do_fuse()
	var f4: Dictionary = m.player.moves[0]
	check("four parts in one move", (f4["parts"] as Array).size() == 4 and m.player.moves.size() == 2)
	m._refresh_slots()
	check("the slot bar shows all four", (m.slots.info[0]["icons"] as Array).size() == 4)
	# ---------- the cap ----------
	var extra: Dictionary = _evolved(m, "ice-beam")
	m.player.moves.append(extra)
	m.bond_ids = [String(f4["id"]), "ice-beam"]
	check("a fifth move cannot be added", not m._fuse_ready())
	m.bond_ids = []
	# ---------- a non evolved move cannot fuse ----------
	m.bond_ids = ["ice-beam", ids[4]]
	check("a move that is not evolved cannot fuse", not m._fuse_ready())
	# ---------- bonded fused move stays visible ----------
	m.bond_ids = [String(f4["id"]), ids[4]]
	m.player.slot = 0
	m._refresh_slots()
	var grp: Dictionary = m.slots.info[0]
	check("a fusion bonded with another move still shows every move", (grp["icons"] as Array).size() == 5 or (grp["icons"] as Array).size() == 4 + 1, str((grp["icons"] as Array).size()))
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	quit(0 if ok else 1)
