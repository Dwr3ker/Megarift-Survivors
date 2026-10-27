extends SceneTree
# Headless check: Zacian/Zamazenta learn Metal Claw (Iron Head line) and Crowned Form converts it to the Behemoth move.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func run_case(dex: int, expect_id: String, expect_name: String) -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.run_dex = dex
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	m.run_time = 1900.0
	var seen := 0
	for i in range(400):
		for c in m._offer():
			if String(c["key"]) == "new:metal-claw": seen += 1
	check("%d is offered Metal Claw before crowning" % dex, seen > 0, "seen %d times in 400 offers" % seen)
	# give an evolved level-max Metal Claw, bonded, then crown
	var mc: Dictionary = m._new_move("metal-claw", m._max_lvl(m._new_move("metal-claw", 1)))
	m._evolve(mc)
	check("setup: Metal Claw evolved to Iron Head", bool(mc["evolved"]) and String(mc["name"]) == "Iron Head", String(mc["name"]))
	m.player.moves.append(mc)
	m.bond_ids = ["metal-claw"]
	var lvl: int = int(mc["lvl"])
	m._mega_start()
	await process_frame
	var found: Dictionary = {}
	for mv in m.player.moves:
		if String(mv["id"]) == expect_id: found = mv
	check("%d: Metal Claw became %s" % [dex, expect_id], not found.is_empty())
	var still := false
	for mv in m.player.moves:
		if String(mv["id"]) == "metal-claw": still = true
	check("%d: Metal Claw no longer present" % dex, not still)
	if not found.is_empty():
		check("%d: level kept" % dex, int(found["lvl"]) == lvl, "%d vs %d" % [int(found["lvl"]), lvl])
		check("%d: evolution kept (%s)" % [dex, expect_name], bool(found["evolved"]) and String(found["name"]) == expect_name, String(found["name"]))
	check("%d: bond follows the new move" % dex, m.bond_ids.has(expect_id) and not m.bond_ids.has("metal-claw"), str(m.bond_ids))
	check("%d: now Fairy/Steel or Fighting/Steel" % dex, m.player.types.has("steel"), str(m.player.types))
	m.queue_free()
	await process_frame

func _init() -> void:
	var SV0 = load("res://scripts/save_data.gd")
	SV0.ensure()
	var _guard: Dictionary = SV0.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	await run_case(888, "behemoth-blade", "Max Behemoth Blade")
	await run_case(889, "behemoth-bash", "Max Behemoth Bash")
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV0.d = _guard
	SV0.save()
	quit(0 if ok else 1)
