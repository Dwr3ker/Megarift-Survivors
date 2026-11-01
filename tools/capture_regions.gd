extends SceneTree
# Takes the snapshots shown on the region picker (menu.gd _region_picker): one in-game shot per region map,
# the region's starter surrounded by its wild Pokémon in the region's first biome, cropped from the middle of the
# screen (no HUD). Needs a real window: run with tools/capture_regions.ps1, which turns the PNGs into JPEGs.
# Uses a throw-away profile (Engine meta "no_save"); your save is never touched.
const OUT := "res://assets/regions/"


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["settings"]["quality"] = 3
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _frames(5)
	for k in range(0, SV.REGIONS.size() + 1):
		seed(1000 + k)
		SV.run_dex = int(SV.REGION_STARTER[k - 1]) if k > 0 else 25
		SV.run_mode = "normal"
		SV.run_hyper = false
		SV.run_region = k
		var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(m)
		await _frames(40)
		m.player.invuln = 1.0e6
		for i in range(9):
			var e = m._spawn_one()
			var a: float = float(i) / 9.0 * TAU + 0.4
			e.position = m.player.position + Vector2(cos(a) * 170.0, sin(a) * 95.0)
		await _frames(45)
		var img: Image = root.get_viewport().get_texture().get_image()
		var vs: Vector2i = img.get_size()
		img = img.get_region(Rect2i(vs.x / 2 - 320, vs.y / 2 - 180, 640, 360))
		img.save_png(ProjectSettings.globalize_path(OUT + "region_%d.png" % k))
		print("shot region ", k)
		m.queue_free()
		await _frames(3)
	print("DONE")
	quit(0)
