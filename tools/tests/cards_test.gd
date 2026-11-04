extends SceneTree
# Level-up card screen (v0.1.3 redesign): exact before -> after rows on move upgrades, badges, the build strip and the
# slot each card lights up, the "Level up! xN" chain with its tally, the deal-in grace, swipe and hold-for-details.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _touch(c, pos: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = down
	c._input(e)

func _drag(c, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.position = pos
	c._input(e)

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 4
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(20):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.player.invuln = 1.0e9
	var em: Dictionary = m.player.moves[0]
	# ---------- exact numbers and badges ----------
	var rows: Array = m._up_rows(em)
	var probe: Dictionary = em.duplicate(true)
	m._level_up_move(probe)
	var changed_ok := not rows.is_empty()
	for rw in rows:
		changed_ok = changed_ok and String(rw[1]) != String(rw[2])
	check("a move upgrade lists what changes, before -> after", changed_ok, str(rows))
	var bd: Array = m._card_badges(String(em["id"]), "up")
	var has_type := false
	for b in bd:
		has_type = has_type or String(b[0]).contains("+10%")
	check("a move of your type shows the type bonus badge", has_type, str(bd))
	# ---------- build strip ----------
	var picks: Array = [{"cat": "up", "id": String(em["id"])}, {"cat": "new", "id": "flamethrower"}, {"cat": "stat", "id": "atk"}]
	var b: Dictionary = m._card_build(picks)
	check("the strip lists your moves", (b["slots"] as Array).size() == m._slot_list().size())
	check("an upgrade lights up that move's slot, a new move the first empty slot, a stat nothing",
		int(picks[0]["slot_hl"]) == 0 and int(picks[1]["slot_hl"]) == m._slot_list().size() and int(picks[2]["slot_hl"]) == -1)
	# ---------- chain ----------
	m.pending_levels = 3
	while not m.cards.open:
		await process_frame
	check("three level-ups at once: Level up! ×3", m.cards.chain_total == 3 and m.cards.chain_taken.is_empty())
	check("cards ignore taps while they deal in", m.cards.age < m.cards.grace_now)
	while m.cards.age < m.cards.grace_now + 0.05:
		await process_frame
	var rs: Array = m.cards._rects()
	# swipe left moves to the next card
	var s0: int = m.cards.sel
	_touch(m.cards, (rs[0] as Rect2).get_center(), true)
	_drag(m.cards, (rs[0] as Rect2).get_center() - Vector2(120, 0))
	_touch(m.cards, (rs[0] as Rect2).get_center() - Vector2(120, 0), false)
	check("swiping left moves to the next card (without choosing)", m.cards.sel == posmod(s0 + 1, m.cards.items.size()) and m.cards.open)
	# hold for details
	_touch(m.cards, (rs[1] as Rect2).get_center(), true)
	for i in range(40):
		m.cards._process(1.0 / 60.0)
	check("holding a card opens its details", m.cards.detail_i == 1)
	_touch(m.cards, (rs[1] as Rect2).get_center(), false)
	check("letting go closes them without choosing", m.cards.detail_i == -1 and m.cards.open and m.pending_levels == 3)
	# a click (PC) chooses at once; the chain continues and remembers the pick
	var t0: String = L_t(m.cards.items[0]["title"])
	_touch(m.cards, (rs[0] as Rect2).get_center(), true)
	_touch(m.cards, (rs[0] as Rect2).get_center(), false)
	for i in range(3):
		await process_frame
	check("choosing continues the chain and lists the pick", m.pending_levels == 2 and m.cards.chain_taken.size() == 1, str(m.cards.chain_taken))
	while not m.cards.open:
		await process_frame
	check("the next pick of a chain deals in faster", m.cards.grace_now < m.cards.GRACE)
	m.cards.skip_pressed.emit()
	for i in range(3):
		await process_frame
	while not m.cards.open:
		await process_frame
	while m.cards.age < m.cards.grace_now + 0.05:
		await process_frame
	m.cards._pick(0)
	for i in range(3):
		await process_frame
	check("the chain ends and its tally clears", m.pending_levels == 0 and m.cards.chain_taken.is_empty() and m.cards.chain_total == 1)
	# ---------- reroll keeps the same screen ----------
	m.pending_levels = 1
	m.rerolls = 2
	while not m.cards.open:
		await process_frame
	var r_before: Array = m.cards._rects()
	var strip_before: bool = not m.cards.build.is_empty()
	m._on_reroll()
	await process_frame
	var r_after: Array = m.cards._rects()
	check("after a reroll the moves strip and Skip are still there", strip_before and not m.cards.build.is_empty() and m.cards.can_skip)
	check("after a reroll the cards keep their place and size", (r_before[0] as Rect2).is_equal_approx(r_after[0] as Rect2), "%s vs %s" % [r_before[0], r_after[0]])
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func L_t(s) -> String:
	return String(s)
