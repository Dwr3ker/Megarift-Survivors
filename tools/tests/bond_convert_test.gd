extends SceneTree
# Bonds are pairs of 2 moves; you can keep making pairs while 2 moves are free. Fusion uses the first pair whose two moves
# are evolved and at max level, and the other pairs stay. A bond that can never be used becomes a free upgrade.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _ids(g: Array) -> Array:
	var out: Array = []
	for m in g:
		out.append(String(m["id"]))
	return out

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
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
	m.pending_levels = 0
	# one move only: nothing to pair yet, the bond is kept
	m.bonds = 1
	m._offer_bond(true)
	check("with one move the bond is saved for later", m.bonds == 1 and m.pending_levels == 0 and not m.choosing)
	# five moves: make two pairs through the cards, as a player would
	for id in ["swords-dance", "hyper-voice", "agility", "hex"]:
		m.player.moves.append(m._new_move(id, 1))
	var ids: Array = _ids(m.player.moves)
	m.bonds = 2
	m._offer_bond(true)
	check("a bond asks for the first move of a pair", m.choosing and m.cards.open)
	m._bond_pick(String(ids[0]))
	m._bond_pick(String(ids[1]))
	check("picking two moves makes a pair", m.bond_ids == [ids[0], ids[1]] and m.bonds == 1, str(m.bond_ids))
	m._offer_bond(true)
	check("with 2 or more free moves another pair can be made", m.choosing)
	m._bond_pick(String(ids[2]))
	m._bond_pick(String(ids[3]))
	check("the second pair is added, the first one stays", m.bond_ids == [ids[0], ids[1], ids[2], ids[3]] and m.bonds == 0, str(m.bond_ids))
	var sl: Array = m._slot_list()
	check("each pair shares one slot (5 moves -> 3 slots)", sl.size() == 3 and _ids(sl[0]) == [ids[0], ids[1]] and _ids(sl[1]) == [ids[2], ids[3]] and _ids(sl[2]) == [ids[4]], str(sl.map(func(g): return _ids(g))))
	check("no pair ever holds more than 2 moves", sl.all(func(g): return (g as Array).size() <= 2))
	# only one free move left and all slots in use: the bond can never be used
	m.pending_levels = 0
	m.bonds = 1
	var cap: int = m._max_moves()
	var MDS = load("res://scripts/moves_data.gd")
	var spare: Array = []
	for k in MDS.MOVES:
		if not _ids(m.player.moves).has(String(k)) and not String(k).contains("-evo"):
			spare.append(String(k))
	var guard := 0
	while m._slot_list().size() < cap and guard < 20 and not spare.is_empty():
		guard += 1
		m.player.moves.append(m._new_move(String(spare.pop_front()), 1))
		if m._bond_options().size() > 0:   # keep at most one free move: pair the newest two loose ones
			var lo: Array = m._bond_options()["loose"]
			if lo.size() >= 2:
				m.bond_ids.append(String(lo[0]["id"]))
				m.bond_ids.append(String(lo[1]["id"]))
	if m._bond_options().is_empty():
		m._offer_bond(true)
		check("no free pair and no room for a move: the bond becomes a free upgrade", m.bonds == 0 and m.pending_levels == 1, "bonds %d pending %d" % [m.bonds, m.pending_levels])
	else:
		print("SKIP  free-upgrade case (the move cap leaves 2 free moves)")
	# fusion: the SECOND pair is ready (evolved, max level); the first is not. Only the second fuses, the first stays.
	for mv in m.player.moves:
		if String(mv["id"]) == String(ids[2]) or String(mv["id"]) == String(ids[3]):
			mv["evolved"] = true
			mv["lvl"] = m._max_lvl(mv)
	var fp: Array = m._fuse_pair()
	check("fusion picks the first pair whose moves are evolved and maxed", fp.size() == 2 and _ids(fp) == [ids[2], ids[3]], str(_ids(fp)))
	m._do_fuse()
	var prs: Array = m._bond_pairs()
	check("after fusing, the other pairs are still bonded and the fused pair is gone", prs.has([String(ids[0]), String(ids[1])]) and not m.bond_ids.has(ids[2]) and not m.bond_ids.has(ids[3]), str(m.bond_ids))
	# an older saved run (one flat pair) reads the same
	check("an old save's bond list is one pair", m._bond_pairs_of(["a", "b"]) == [["a", "b"]])
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
