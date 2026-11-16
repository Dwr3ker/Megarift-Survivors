extends SceneTree
# Move slots and full fusions (docs/endgame_moves.md): 4 move slots always (the Weapon slots upgrade is gone and refunded
# once), and a full 4-move fusion can't be bonded (old bonds like that are undone on resume and the bond given back).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var m

func mv(id: String) -> Dictionary:
	var x: Dictionary = m._new_move(id, 1)
	while int(x["lvl"]) < m._max_lvl(x):
		m._level_up_move(x)
	x["evolved"] = true
	return x

func fusion(n: int) -> Dictionary:
	var parts: Array = []
	for id in ["confusion", "psycho-cut", "dream-eater", "psychic"].slice(0, n):
		parts.append(mv(id))
	var f: Dictionary = (parts[0] as Dictionary).duplicate(true)
	f["parts"] = parts
	f["fused"] = true
	f["evolved"] = true
	return f

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	# ---- Weapon slots refund ----
	SV.d["coins"] = 0
	SV.d["pup"] = {"25": {"wslot": 2, "hp": 1}, "6": {"wslot": 1}}
	SV._migrate_wslot()
	var want: int = SV.wslot_cost(0) * 2 + SV.wslot_cost(1)
	check("Weapon slots levels are refunded in full", int(SV.d["coins"]) == want and int(SV.d["wslot_refund"]) == want, "%d (%d + %d per level)" % [int(SV.d["coins"]), SV.wslot_cost(0), SV.wslot_cost(1)])
	check("and removed, once (other upgrades kept)", not SV.d["pup"]["25"].has("wslot") and int(SV.d["pup"]["25"]["hp"]) == 1)
	SV._migrate_wslot()
	check("a second load pays nothing more", int(SV.d["coins"]) == want)
	check("the upgrade is gone from the shop", SV.UPGRADES.all(func(u): return String(u["id"]) != "wslot"))
	# ---- a run ----
	SV.d["owned"]["150"] = {"n": 1, "shiny": false}
	SV.run_dex = 150
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	check("4 move slots", m._max_moves() == 4)
	m.slot_cap = 6
	check("a run saved with 6 slots keeps them", m._max_moves() == 6)
	m.slot_cap = 0
	# ---- bonds and fusions ----
	var f4: Dictionary = fusion(4)
	var sd: Dictionary = m._new_move("swords-dance", 1)
	m.player.moves = [f4, mv("hypnosis"), mv("shadow-ball"), sd]
	m.bond_ids = []
	var loose: Array = m._bond_options().get("loose", [])
	check("a full fusion can't be bonded (other moves, buffs included, still can)", loose.size() == 3 and not loose.has(f4) and loose.has(sd), str(loose.size()))
	var f2: Dictionary = fusion(2)
	m.player.moves = [f2, mv("hypnosis"), mv("shadow-ball")]
	check("a fusion with room can still be bonded", (m._bond_options().get("loose", []) as Array).has(f2))
	m.player.moves = [f4, mv("hypnosis"), mv("shadow-ball"), sd]
	m.bond_ids = ["confusion", "swords-dance", "hypnosis", "shadow-ball"]
	m.bonds = 0
	var dropped: int = m._fix_bonds(true)
	check("an old bond with a full fusion is undone and given back", dropped == 1 and m.bonds == 1 and m.bond_ids == ["hypnosis", "shadow-ball"], str(m.bond_ids))
	m.bond_ids = ["hypnosis", "swords-dance"]
	check("a bond with a buff is kept", m._fix_bonds(true) == 0 and m.bond_ids == ["hypnosis", "swords-dance"])
	m.queue_free()
	for i in range(3):
		await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
