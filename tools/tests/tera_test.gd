extends SceneTree
# Roadmap step 6: Terastallizing starts with your Tera type, lasts its full time, ends cleanly, and also ends when you
# faint, enter a rift and when the run ends. Beating a Legendary rift recharges the orb. No Dynamax while
# Terastallized. A saved run keeps the orb.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _run(SV):
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
	for id in ["wave", "rift", "meowth", "boss", "map"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var TERA = load("res://scripts/tera.gd")
	var RS = load("res://scripts/run_save.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["stats"]["dens"] = 1
	SV.set_tera_type(6, "water")
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	check("a saved run keeps the Tera Orb", RS.FIELDS.has("tera_pts") and RS.FIELDS.has("tera_used"))
	# start, full time, clean end
	var m = await _run(SV)
	m.run_time = 400.0
	m.tera_pts = TERA.NEED
	m._tera_start()
	check("it starts with your Tera type (Charizard set to Water)", m._tera_on() and m.tera_type_run == "water" and is_equal_approx(m.tera_t, TERA.DUR))
	check("no Dynamax while Terastallized", not m._dyn_can())
	check("the activation scene plays: a crystal shell, and you are protected", m.player.get_children().any(func(n): return n.get_script() == TERA.Shell) and m.player.invuln >= TERA.SCENE_LEN)
	check("the TERASTALLIZE banner shows", m.hud.tera_flash < 0.5 and m.hud.tera_word != "")
	await process_frame
	check("the MAX button is greyed (Tera on) while Terastallized", m.hud.dyn_btn == 4, str(m.hud.dyn_btn))
	var ck := InputEventKey.new()
	ck.keycode = KEY_C
	ck.pressed = true
	m._unhandled_input(ck)
	check("pressing it says why instead of nothing", m._blocked_t > 0 and not m._dyn_on())
	await create_timer(1.0).timeout
	var jw: Array = m.player.get_children().filter(func(n): return n.get_script() == TERA.Jewel)
	check("after the shell shatters: the jewel, in its Tera type", jw.size() == 1 and jw[0].type == "water")
	check("and the crystal look", float(m.player.mat.get_shader_parameter("crystal")) > 0.5)
	check("the clock runs at game speed (about 1 s gone)", m.tera_t > TERA.DUR - 1.4 and m.tera_t < TERA.DUR - 0.6, "%.2f" % m.tera_t)
	m.tera_t = 0.3
	await create_timer(0.6).timeout
	check("when time is up it ends cleanly", not m._tera_on() and m.tera_type_run == "" and m.tera_used)
	await process_frame
	check("the jewel is gone after Tera", m.player.get_children().filter(func(n): return n.get_script() == TERA.Jewel and not n.is_queued_for_deletion()).is_empty())
	await process_frame
	check("the button then says Used", m.hud.tera_btn == 3 and m.hud.tera_left == 0.0)
	check("once used it can't start again", not m._tera_can())
	# the other way round: TERA is greyed while Dynamaxed and says why
	m.tera_used = false
	m.tera_pts = TERA.NEED
	m.dyn_used = false
	m._dyn_start()
	await process_frame
	check("the TERA button is greyed (Max on) while Dynamaxed", m.hud.tera_btn == 4, str(m.hud.tera_btn))
	m._blocked_t = 0
	m._chords_tick({"tera": true})
	check("Y + RT while Dynamaxed says why and doesn't Terastallize", m._blocked_t > 0 and not m._tera_on())
	m._chords_tick({})
	m._dyn_stop()
	await process_frame
	await process_frame
	check("after Dynamax ends, TERA is ready again", m.hud.tera_btn == 2, str(m.hud.tera_btn))
	# step 7: moves of the Tera type hit harder while Terastallized (+50%, or +75% when it is one of your own types)
	m.tera_used = false
	m.tera_t = 0.0
	m.tera_type_run = ""
	m.perks["crit"] = 0.0
	var dummy = m._spawn_one()
	dummy.position = m.player.position + Vector2(500, 0)
	dummy.types = ["normal"]
	dummy.max_hp = 1.0e9
	dummy.hp = 1.0e9
	var hit := func(ty: String) -> float:
		var h0: float = dummy.hp
		m._hit_enemy(dummy, 100.0, Color.WHITE, Vector2.RIGHT, 0.0, ty, 0, 0, 0.0)
		return h0 - dummy.hp
	var w0: float = hit.call("water")
	var f0: float = hit.call("fire")
	var g0: float = hit.call("grass")
	m.tera_type_run = "water"   # Charizard (Fire/Flying) Terastallized into Water
	var w1: float = hit.call("water")
	var f1: float = hit.call("fire")
	var g1: float = hit.call("grass")
	check("Tera Water: Water moves deal +50%", absf(w1 / w0 - 1.5) < 0.01, "%.2f" % (w1 / w0))
	check("Tera Water: other moves are unchanged", absf(f1 / f0 - 1.0) < 0.01 and absf(g1 / g0 - 1.0) < 0.01)
	m.tera_type_run = "fire"    # Tera type is one of its own types
	var f2: float = hit.call("fire")
	check("Tera Fire on a Fire type: Fire moves deal +75%", absf(f2 / f0 - 1.75) < 0.01, "%.2f" % (f2 / f0))
	m.tera_type_run = ""
	check("after Tera ends, damage is back to normal", absf(hit.call("water") / w0 - 1.0) < 0.01)
	# step 8: while Terastallized you take hits as a pure Tera-type Pokémon
	var taken := func(ty: String) -> float:
		m.player.max_hp = 100000.0
		m.player.hp = 100000.0
		m.player.invuln = 0.0
		m._hurt_player(100.0, ty)
		return 100000.0 - m.player.hp
	m.tera_type_run = ""
	var rock0: float = taken.call("rock")
	var grass0: float = taken.call("grass")
	var norm0: float = taken.call("normal")
	m.tera_type_run = "water"   # Charizard (Fire/Flying) Terastallized into Water
	var rock1: float = taken.call("rock")
	var grass1: float = taken.call("grass")
	var norm1: float = taken.call("normal")
	check("Charizard is doubly weak to Rock normally (x1.6 on you)", rock0 > norm0 * 1.5, "%.0f vs %.0f" % [rock0, norm0])
	check("Tera Water: Rock becomes neutral", absf(rock1 - norm1) < 1.0, "%.0f vs %.0f" % [rock1, norm1])
	check("Tera Water: Grass goes from resisted to super effective", grass0 < norm0 and grass1 > norm1, "%.0f (was %.0f)" % [grass1, grass0])
	check("defensive types: Water alone while Terastallized", m._def_types() == ["water"])
	m.tera_type_run = ""
	check("after Tera: back to Fire/Flying", m._def_types() == m.player.types and absf(taken.call("rock") - rock0) < 1.0)
	# fainting
	m.tera_used = false
	m._tera_start()
	m.player.dead = true
	await process_frame
	await process_frame
	check("fainting ends it", not m._tera_on() and m.tera_type_run == "")
	m.queue_free()
	await process_frame
	# entering a rift ends it; beating the rift's legendary recharges the orb
	var r = await _run(SV)
	r.run_time = 400.0
	r.tera_pts = TERA.NEED
	r._tera_start()
	r._open_rift(-1, false)
	r.rift.position = r.player.position
	r.rift.t = 2.0
	var g := 0
	while r.arena == null and g < 600:
		g += 1
		await process_frame
	check("entering a rift ends it", r.arena != null and not r._tera_on())
	for i in range(10):
		await process_frame
	r._legend_down(r.ainfo["boss"])
	check("beating the Legendary rift recharges the orb", not r.tera_used and r._tera_ready())
	r.queue_free()
	await process_frame
	# the run ending
	var e = await _run(SV)
	e.run_time = 400.0
	e.tera_pts = TERA.NEED
	e._tera_start()
	e._finish_run()
	check("the run ending ends it", not e._tera_on() and e.tera_type_run == "")
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
