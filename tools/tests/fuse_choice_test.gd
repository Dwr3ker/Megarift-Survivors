extends SceneTree
# Fusion is a choice: a ready pair shows Fuse / Keep both (never fuses on its own); a kept pair is not asked again.
# One Fusion Move per run: after it exists, only a pair that includes it can fuse (it grows up to FUSE_MAX moves).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _ids(arr: Array) -> Array:
	return arr.map(func(m): return String(m["id"]))

func _maxed(m, ids: Array) -> void:
	for mv in m.player.moves:
		if ids.has(String(mv["id"])):
			mv["evolved"] = true
			mv["lvl"] = m._max_lvl(mv)

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
	for e in m.enemies:
		e.position += Vector2(9000, 9000)
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	for id in ["ember", "water-gun", "vine-whip", "gust", "bite"]:
		if not _ids(m.player.moves).has(id):
			m.player.moves.append(m._new_move(id, 1))
	var ids: Array = _ids(m.player.moves)
	m.bond_ids = [ids[0], ids[1], ids[2], ids[3]]   # two pairs
	_maxed(m, [ids[0], ids[1]])
	m.pending_levels = 0
	for i in range(4):
		await process_frame
	check("a ready pair asks first instead of fusing on its own", m.cards.open and String(m.cards.items[0]["cat"]) == "fuse" and not m._has_fusion())
	# Keep both
	var keep_i: int = 0 if String(m.cards.items[0]["id"]) == "no" else 1
	m._on_card_chosen(keep_i)
	for i in range(4):
		await process_frame
	check("Keep both keeps the two moves and is not asked again", not m._has_fusion() and not m.cards.open and m.fuse_declined.has("%s+%s" % [ids[0], ids[1]]) and m._fuse_pair().is_empty())
	# the second pair becomes ready: it is offered, and Fuse fuses it
	_maxed(m, [ids[2], ids[3]])
	for i in range(4):
		await process_frame
	check("another ready pair is offered", m.cards.open and String(m.cards.items[0]["cat"]) == "fuse")
	var fuse_i: int = 0 if String(m.cards.items[0]["id"]) == "yes" else 1
	m._on_card_chosen(fuse_i)
	for i in range(3):
		await process_frame
	check("Fuse makes the run's Fusion Move (the pair becomes one move)", m._has_fusion() and not _ids(m.player.moves).has(ids[3]))
	# a new pair of other moves, both ready: it may not start a second Fusion Move
	m.fuse_declined.clear()
	_maxed(m, [ids[4]])
	var other: String = String(m.player.moves.filter(func(q): return not bool(q.get("fused", false)) and String(q["id"]) != ids[4])[0]["id"])
	m.bond_ids = [ids[0], ids[1]]
	m.fuse_declined.append("%s+%s" % [ids[0], ids[1]])
	m.bond_ids.append(other)
	m.bond_ids.append(ids[4])
	_maxed(m, [other])
	check("a pair without the Fusion Move can't start a second one", m._fuse_pair().is_empty())
	# a pair with the Fusion Move can grow it
	var fid: String = String(m.player.moves.filter(func(q): return bool(q.get("fused", false)))[0]["id"])
	m.bond_ids = [fid, ids[4]]
	var fp: Array = m._fuse_pair()
	check("the Fusion Move can take in another move (chained fusion)", fp.size() == 2 and _ids(fp).has(fid) and _ids(fp).has(ids[4]), str(_ids(fp)))
	m._refresh_slots()
	var fused_slots: int = m.slots.info.filter(func(it): return bool(it.get("fused", false))).size()
	var bonded_slots: int = m.slots.info.filter(func(it): return bool(it.get("bonded", false))).size()
	check("the move bar marks the Fusion Move and bonded pairs", fused_slots == 1 and bonded_slots >= 1, "%d fused, %d bonded" % [fused_slots, bonded_slots])
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
