extends SceneTree
# Small features step 65a: branching evolutions show the stone or item each choice uses (evo_items.gd). Every species
# with more than one evolution has an entry for each branch, every item icon draws, Eevee's 8 cards show their stones
# (narrow cards: just the item, the bonus in the heading), Applin's 3 show item and bonus, and keys 4-9 pick cards 4-9.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var EVO = load("res://scripts/evolution.gd")
	var EVI = load("res://scripts/evo_items.gd")
	var IC = load("res://scripts/icons.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	# ---- data ----
	var f := FileAccess.open("res://data/evolutions.json", FileAccess.READ)
	var js: Dictionary = JSON.parse_string(f.get_as_text())
	var missing: Array = []
	var nbranch := 0
	for k in js:
		var to: Array = js[k].get("to", [])
		if to.size() > 1:
			nbranch += 1
			for c in to:
				if not EVI.has(int(c)):
					missing.append(int(c))
	check("every branching evolution (%d species) has an item or condition for each branch" % nbranch, missing.is_empty(), str(missing))
	var bad_lv: Array = []
	for d in EVI.BY_DEX:
		if EVI.label(int(d)).contains("%") or EVI.label(int(d)).contains("Level 0"):
			bad_lv.append(int(d))
	check("every \"Level %d\" has its level", bad_lv.is_empty(), str(bad_lv))
	check("labels read well", EVI.label(136) == "Fire Stone" and EVI.label(186) == "King's Rock (trade)" and EVI.label(106) == "Level 20 (Attack higher)" and EVI.label(197) == "Friendship (night)", "%s | %s | %s" % [EVI.label(186), EVI.label(106), EVI.label(197)])
	# ---- icons ----
	var sigs := {}
	var bad_ic: Array = []
	for id in EVI.all_ids():
		var img: Image = IC.image("evoitem:" + String(id))
		if img == null or img.get_width() != 16 or img.get_height() != 16:
			bad_ic.append(id)
			continue
		var used := 0
		for y in range(16):
			for x in range(16):
				if img.get_pixel(x, y).a > 0.0:
					used += 1
		if used < 40:
			bad_ic.append(id)
		sigs[img.get_data().hex_encode().md5_text()] = true
	check("every item icon is a 16 x 16 picture", bad_ic.is_empty(), str(bad_ic))
	check("each item has its own picture", sigs.size() == EVI.all_ids().size(), "%d / %d" % [sigs.size(), EVI.all_ids().size()])
	# ---- in a run: Eevee ----
	SV.d["owned"]["133"] = {"n": 1}
	SV.run_dex = 133
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	var picks: Array = EVO.picks(m)
	check("Eevee gets 8 choices", picks.size() == 8, str(picks.size()))
	var by: Dictionary = {}
	for p in picks:
		by[String(p["id"])] = p
	check("each shows its stone (Flareon: Fire Stone, Glaceon: Ice Stone...)", String(by["136"]["icon"]) == "evoitem:fire" and String(by["136"]["desc"]) == "Fire Stone" and String(by["471"]["icon"]) == "evoitem:ice" and String(by["134"]["desc"]) == "Water Stone")
	check("Espeon and Umbreon show Friendship (day / night)", String(by["196"]["desc"]).contains("day") and String(by["197"]["desc"]).contains("night") and String(by["196"]["icon"]) == "evoitem:friend")
	check("with 8 narrow cards the bonus goes in the heading", EVO.pick_heading(m).contains("damage") and not String(by["136"]["desc"]).contains("damage"))
	m.choosing = true
	m.cards.show_cards(picks, EVO.pick_heading(m), "Evolution!", false)
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:   # past the cards' grace time
		await process_frame
	var got := []
	m.cards.chosen.connect(func(i): got.append(i))
	var e := InputEventKey.new()
	e.keycode = KEY_8
	e.pressed = true
	m.cards._input(e)
	await process_frame
	check("the 8 key picks the 8th card", got.has(7), str(got))
	m.queue_free()
	for i in range(3):
		await process_frame
	# ---- Applin: 3 wide cards keep the bonus ----
	SV.d["owned"]["840"] = {"n": 1}
	SV.run_dex = 840
	m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	var ap: Array = EVO.picks(m)
	check("Applin's 3 cards show the apple and the bonus", ap.size() == 3 and ap.all(func(p): return String(p["desc"]).begins_with("Evolves with: ") and String(p["desc"]).contains("Apple") and String(p["desc"]).contains("damage")) and EVO.pick_heading(m) == "Choose an evolution", str(ap.map(func(p): return p["desc"])))
	m.queue_free()
	for i in range(3):
		await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
