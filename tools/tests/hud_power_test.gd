extends SceneTree
# The D-pad only moves your Pokémon (it no longer also picks moves 1-4), and the power buttons (Z-Move, MAX, the action
# button) never sit on the stats panel, on 16:9, 16:10 and 4:3 screens.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var PAD = load("res://scripts/pad.gd")
	SV.ensure()
	SV.d = SV.default_data()
	# an old save that still has the D-pad on moves 1-4
	SV.d["settings"]["padmap"] = PAD.defaults()
	SV.d["settings"]["padmap"]["slot1"] = JOY_BUTTON_DPAD_UP
	SV.d["settings"]["padmap"]["slot2"] = JOY_BUTTON_DPAD_RIGHT
	SV.d["settings"]["dpad_moves_only"] = false
	PAD.apply()
	check("old saves: the D-pad no longer picks moves", PAD.btn("slot1") == PAD.NONE and PAD.btn("slot2") == PAD.NONE)
	check("new saves: no D-pad on moves", int(PAD.defaults()["slot3"]) == PAD.NONE)
	check("an unset action shows Not set", PAD.btn_name(PAD.NONE) != "" and not PAD.btn_name(PAD.NONE).contains("-1"))
	SV.d["stats"]["dens"] = 1
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	m.player.moves.append(m._new_move("ember", 1))
	m._set_active(1)
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_DPAD_UP
	ev.pressed = true
	m._unhandled_input(ev)
	await process_frame
	check("D-pad up in a run keeps the selected move", m.player.slot == 1, str(m.player.slot))
	m.run_time = 400.0
	m.set_process(false)   # keep the test's button flags (the run refreshes them each frame)
	for sz in [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1024, 768), Vector2i(1920, 1080)]:
		root.size = sz
		for i in range(4):
			await process_frame
		var h = m.hud
		h.z_btn = 2   # both power buttons shown (the run would set these when they unlock)
		h.dyn_btn = 2
		var st := Rect2(h.stats_left, h.stats_top, h.stats_right - h.stats_left, h.stats_bottom - h.stats_top)
		var vp: Vector2 = h.get_viewport_rect().size
		var rs: Array = [h.z_rect(), h.dyn_rect(), h.power_rect(2), h.power_rect(3)]
		var clear := true
		var on := true
		for r in rs:
			if (r as Rect2).intersects(st):
				clear = false
			if r.position.x < 0.0 or r.position.y < 0.0 or r.end.x > vp.x or r.end.y > vp.y:
				on = false
		var apart: bool = not rs[0].intersects(rs[1]) and not rs[1].intersects(rs[2]) and not rs[0].intersects(rs[2]) and not rs[2].intersects(rs[3])
		var dash_ok: bool = rs.all(func(r): return not (r as Rect2).intersects(h.dash_rect()))
		check("%dx%d: power buttons clear of the stats panel, on screen, apart" % [sz.x, sz.y], clear and on and apart and dash_ok, "stats %s z %s max %s" % [st, rs[0], rs[1]])
	# players can move and resize the Z-Move, MAX and TERA buttons in the HUD layout editor
	var HL = load("res://scripts/hud_layout.gd")
	root.size = Vector2i(1280, 720)
	for i in range(4):
		await process_frame
	var h2 = m.hud
	h2.z_btn = 2
	h2.dyn_btn = 2
	h2.tera_btn = 2
	check("the layout editor lists the three buttons", HL.IDS.has("zmove") and HL.IDS.has("dynamax") and HL.IDS.has("tera"))
	var vp2: Vector2 = h2.get_viewport_rect().size
	var ins2: Vector4 = m.DSP.insets(m.get_tree())
	var d_t: Rect2 = HL.default_rect("tera", vp2, ins2)
	HL.set_el("tera", Vector2(-600.0, -40.0), 130)
	var tr2: Rect2 = h2.tera_rect()
	check("a moved TERA button sits where the player put it", tr2.position.distance_to(d_t.position + Vector2(-600.0, -40.0)) < 1.0, "%s vs %s" % [tr2.position, d_t.position + Vector2(-600.0, -40.0)])
	check("and at the player's size", is_equal_approx(tr2.size.x, 130.0))
	check("the other power buttons keep clear of it", not h2.z_rect().intersects(tr2) and not h2.dyn_rect().intersects(tr2))
	HL.set_el("zmove", Vector2(-300.0, 0.0), 80)
	var zr2: Rect2 = h2.z_rect()
	check("Z-Move moves and shrinks too", is_equal_approx(zr2.size.x, 80.0) and not zr2.intersects(h2.dyn_rect()))
	HL.reset_el("tera")
	HL.reset_el("zmove")
	check("reset: back to the automatic spots", not HL.moved("tera") and h2.tera_rect().size.x == 100.0)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
