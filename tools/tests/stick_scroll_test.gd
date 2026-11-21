extends SceneTree
# Right stick scrolls the list you are in, in every menu (stick_scroll.gd); the Upgrades screen lights up the row you point
# at or are on; the move bar shows every move's upgrades in a fused or bonded slot.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var SSC = load("res://scripts/stick_scroll.gd")
	SV.ensure()
	SV.load_dex()
	SV.d = SV.default_data()
	SV.d["nick"] = "Ash"
	SV.d["coins"] = 20000
	SV.add_owned(4)
	SV.d["selected"] = 4
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	# ---- right stick in the menus ----
	var scrolled := 0
	for scr in ["settings", "up", "lexicon", "profile", "goals"]:
		menu._show(scr)
		for i in range(6):
			await process_frame
		var sc: ScrollContainer = SSC.target(menu.screens[scr], menu.get_viewport())
		if sc == null:
			print("SKIP  %s: everything fits on screen here, nothing to scroll" % scr)
			continue
		scrolled += 1
		sc.scroll_vertical = 0
		SSC.fake = 0.9
		for i in range(10):
			menu._stick_scroll(1.0 / 30.0)
		SSC.fake = 0.0
		var room: int = int(sc.get_v_scroll_bar().max_value - sc.get_v_scroll_bar().page)
		check("%s: the right stick scrolls it down" % scr, sc.scroll_vertical > 50 or (sc.scroll_vertical > 0 and sc.scroll_vertical >= room - 1), "%d of %d" % [sc.scroll_vertical, room])
	check("at least two menu screens were scrolled", scrolled >= 2, str(scrolled))
	# the list that holds the focused control wins
	menu._show("up")
	for i in range(6):
		await process_frame
	var some: Control = null
	for b in menu.screens["up"].find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and b.has_meta("fk") and String(b.get_meta("fk")).begins_with("u:"):
			some = b
			break
	some.grab_focus()
	await process_frame
	var owner_sc: ScrollContainer = SSC.target(menu.screens["up"], menu.get_viewport())
	check("it scrolls the list holding the selected control", owner_sc != null and owner_sc.is_ancestor_of(some))
	menu._show("layout")
	for i in range(4):
		await process_frame
	SSC.fake = 0.9
	var lay_sc: ScrollContainer = SSC.target(menu.screens["layout"], menu.get_viewport())
	var before: int = lay_sc.scroll_vertical if lay_sc != null else 0
	menu._stick_scroll(0.2)
	SSC.fake = 0.0
	check("the HUD layout editor keeps the right stick for moving boxes", lay_sc == null or lay_sc.scroll_vertical == before)
	# ---- Upgrades: the row lights up ----
	menu._show("up")
	for i in range(6):
		await process_frame
	var card: PanelContainer = menu.screens["up"].find_child("UpRow_atk", true, false)
	var base_sb: StyleBox = card.get_theme_stylebox("panel")
	var pb: Button = null
	for b in card.find_children("*", "Button", true, false):
		pb = b
	pb.mouse_entered.emit()
	check("pointing at a price lights up its row", card.get_theme_stylebox("panel") != base_sb)
	pb.mouse_exited.emit()
	check("and back when the mouse leaves", card.get_theme_stylebox("panel") == base_sb)
	pb.grab_focus()
	await process_frame
	check("the row you are on with a controller lights up too", card.get_theme_stylebox("panel") != base_sb)
	var hov: StyleBox = pb.get_theme_stylebox("hover")
	var nor: StyleBox = pb.get_theme_stylebox("normal")
	check("the price button's hover look differs from its normal look", hov != nor and hov is StyleBoxFlat and (hov as StyleBoxFlat).border_color == Color.WHITE)
	menu.queue_free()
	await process_frame
	# ---- in a run: pause screen scrolls, and the move bar ----
	SV.d["owned"]["150"] = {"n": 1, "shiny": false}
	SV.run_dex = 150
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	var mk := func(id: String, lv: int, evo: bool) -> Dictionary:
		var x: Dictionary = m._new_move(id, 1)
		while int(x["lvl"]) < lv:
			m._level_up_move(x)
		if evo:
			m._evolve(x)
		return x
	var parts: Array = [mk.call("confusion", 5, true), mk.call("psycho-cut", 5, true), mk.call("dream-eater", 5, true), mk.call("psychic", 5, true)]
	var f: Dictionary = (parts[0] as Dictionary).duplicate(true)
	f["parts"] = parts
	f["fused"] = true
	m.player.moves = [f, mk.call("psybeam", 2, false), mk.call("hypnosis", 4, false), mk.call("shadow-ball", 3, false)]
	m.bond_ids = ["psybeam", "hypnosis"]
	m._refresh_slots()
	var info: Array = m.slots.info
	check("a fused slot shows each of its 4 moves' upgrades", (info[0]["plv"] as Array).size() == 4 and (info[0]["plv"] as Array).all(func(q): return int(q[0]) == int(q[1]) and bool(q[2])))
	check("a bonded pair shows both moves' levels (2 and 4)", (info[1]["plv"] as Array).size() == 2 and int(info[1]["plv"][0][0]) == 2 and int(info[1]["plv"][1][0]) == 4)
	check("a single move keeps one row", (info[2]["plv"] as Array).size() == 1 and int(info[2]["lvl"]) == 3)
	m.paused = true
	m.pause_ui.visible = true
	m.pause_ui.show_summary(m.pause_summary())
	for i in range(6):
		await process_frame
	var psc: ScrollContainer = SSC.target(m.pause_ui, m.get_viewport())
	if psc != null:
		psc.scroll_vertical = 0
		SSC.fake = 0.9
		for i in range(10):
			m.pause_ui._process(1.0 / 30.0)
		SSC.fake = 0.0
	var proom: int = int(psc.get_v_scroll_bar().max_value - psc.get_v_scroll_bar().page) if psc != null else 0
	check("the pause screen scrolls with the right stick", psc != null and (psc.scroll_vertical > 50 or (psc.scroll_vertical > 0 and psc.scroll_vertical >= proom - 1)), "%d of %d" % [psc.scroll_vertical, proom] if psc != null else "no list")
	m.queue_free()
	for i in range(3):
		await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
