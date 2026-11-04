extends SceneTree
func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	seed(3)
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	for e in m.enemies:
		e.position += Vector2(9000, 9000)
	m.player.invuln = 1.0e9
	m.player.active = false
	m.SV.d["settings"]["fov"] = 100
	m._apply_fov()
	var c: Vector2 = m.player.position
	var rng := RandomNumberGenerator.new()
	var subs: Array = ["poison", "ice", "fire", "freeze", "shock", "sleep", "confuse"]
	for i in range(subs.size()):
		var props: Array = []
		var pos: Vector2 = c + Vector2(-540 + i * 180, 230 if i % 2 == 0 else -230)
		for k in range(40):
			if m._add_prop(props, [], "trap", pos + Vector2(float(k % 6) * 6.0, float(k / 6) * 6.0), 16.0, rng):
				break
		if not props.is_empty():
			props[0].sub = subs[i]
			m.chunks.values()[0]["props"].append(props[0])
	for i in range(40):
		await process_frame
	m.hud.modulate.a = 1.0
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
