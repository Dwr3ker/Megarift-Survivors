extends SceneTree
# Roadmap step 12: how Tera combines with the other powers (docs/tera.md).
# Mega Evolution: works with Tera, in either order (the crystal look and jewel survive the new body).
# Z-Moves: work while Terastallized, and a Z-Move of the Tera type gets the Tera bonus.
# Dynamax / Gigantamax: never at the same time as Tera, in either order.
# Necrozma's and Kyurem's forms: work with Tera.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _run(SV, dex: int):
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.jd.done = true
	m.rift_check = 1.0e9
	m.player.invuln = 1.0e9
	m.run_time = 1900.0
	return m

func _crystal(m) -> bool:
	var v = m.player.mat.get_shader_parameter("crystal")
	return v != null and float(v) > 0.5

func _jewel(m, TERA) -> bool:
	return m.player.get_children().any(func(n): return n.get_script() == TERA.Jewel and not n.is_queued_for_deletion())

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var TERA = load("res://scripts/tera.gd")
	var GM = load("res://scripts/gmax.gd")
	var NZ = load("res://scripts/necrozma.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["stats"]["dens"] = 1
	SV.set_tera_type(6, "water")
	# ---- Tera, then Mega Evolution ----
	var m = await _run(SV, 6)
	m.tera_pts = TERA.NEED
	m._tera_start()
	await create_timer(1.0).timeout
	m._mega_start()
	await create_timer(0.6).timeout
	check("Tera then Mega: both on", m._tera_on() and m._mega_on())
	check("  the crystal look and jewel survive the Mega body", _crystal(m) and _jewel(m, TERA))
	check("  it still defends as Water", m._def_types() == ["water"])
	m.queue_free()
	await process_frame
	# ---- Mega Evolution, then Tera ----
	var m2 = await _run(SV, 6)
	m2._mega_start()
	await create_timer(0.4).timeout
	m2.tera_pts = TERA.NEED
	check("Mega then Tera: Tera can start", m2._tera_can())
	m2._tera_start()
	await create_timer(1.0).timeout
	check("  both on, crystal and jewel shown", m2._tera_on() and m2._mega_on() and _crystal(m2) and _jewel(m2, TERA))
	m2.queue_free()
	await process_frame
	# ---- Z-Move while Terastallized ----
	SV.set_tera_type(25, "electric")
	var z = await _run(SV, 25)
	z.z_type = "electric"
	z.z_used = false
	z.tera_pts = TERA.NEED
	z._tera_start()
	await create_timer(1.0).timeout
	check("Z-Move while Terastallized can start", z._z_can())
	z._z_start()
	var g := 0
	while z.z_state != "" and g < 900:
		g += 1
		await process_frame
	check("  the Z-Move plays out and Tera is still on", z.z_state == "" and z._tera_on())
	check("  a Z-Move of the Tera type gets the Tera bonus", is_equal_approx(TERA.mult(true), 1.75) and z.tera_type_run == "electric")
	z.queue_free()
	await process_frame
	# ---- Dynamax and Gigantamax: never together with Tera ----
	var d = await _run(SV, 6)
	d.tera_pts = TERA.NEED
	d._tera_start()
	check("Terastallized: Dynamax can't start", not d._dyn_can())
	d._tera_end("test")
	d.dyn_used = false
	d._dyn_start()
	check("Dynamaxed: Tera can't start", d._dyn_on() and not d._tera_can())
	d._dyn_stop()
	d.queue_free()
	await process_frame
	GM.grant(SV.d, 6)
	var gx = await _run(SV, 6)
	gx.dyn_used = false
	gx._dyn_start()
	gx.tera_pts = TERA.NEED
	check("Gigantamaxed: Tera can't start", gx.dyn.giga and not gx._tera_can())
	gx._dyn_stop()
	await process_frame
	check("after Gigantamax ends, Tera can start", gx._tera_can())
	gx.queue_free()
	await process_frame
	# ---- Necrozma's forms ----
	var n = await _run(SV, 800)
	n.tera_pts = TERA.NEED
	n._tera_start()
	await create_timer(1.0).timeout
	NZ.apply(n, "dusk")
	NZ.ultra(n)
	await create_timer(0.3).timeout
	check("Tera with Necrozma's fusion and Ultra Burst: crystal and jewel stay", n._tera_on() and _crystal(n) and _jewel(n, TERA))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
