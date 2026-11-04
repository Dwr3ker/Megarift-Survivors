extends SceneTree
# Entering a rift: a short pull-in (screen closes, camera pushes in, you can't be hit), then the arena opens with a
# flash and a banner naming the legendary. Saves a few frames when given an output path.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
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
	for e in m.enemies:
		e.position += Vector2(9000, 9000)
	m._open_rift(249, false)   # Lugia
	m.rift.t = 2.0
	m.player.position = m.rift.position + Vector2(10, 0)
	await process_frame
	await process_frame
	check("touching the rift starts the pull-in instead of teleporting", m.rift_in_t > 0.0 and m.arena == null, "%.2f" % m.rift_in_t)
	check("you can't be hit while being pulled in", m.player.invuln > 0.4)
	var shots: Array = []
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while m.arena == null and frames < 120:
		frames += 1
		if out != "" and m.rift_in_t < 0.15 and not FileAccess.file_exists(out + "_pull.png"):
			root.get_viewport().get_texture().get_image().save_png(out + "_pull.png")
		await process_frame
	check("the screen closes in and the camera pushes in on the way", m.hud.rift_iris >= 0.0 and frames > 5, "%d frames" % frames)
	check("after the pull the arena opens", m.arena != null and not m.ainfo.is_empty())
	check("the reveal and the banner start, and your Pokémon is back to normal size", m.rift_out_t > 0.0 and m.hud.rift_intro_t > 0.0 and m.hud.rift_intro_name != "" and m.player.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(m.player.rotation), m.hud.rift_intro_name)
	for i in range(6):
		await process_frame
	if out != "":
		root.get_viewport().get_texture().get_image().save_png(out + "_open.png")
	var wait := 0
	while m.hud.rift_intro_t > 1.6 and wait < 600:
		wait += 1
		await process_frame
	if out != "":
		root.get_viewport().get_texture().get_image().save_png(out + "_banner.png")
	while m.rift_out_t > 0.0 and wait < 600:
		wait += 1
		await process_frame
	check("the reveal ends on its own", m.rift_out_t == 0.0 and m.hud.rift_open < 0.0)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
