extends SceneTree
# Contact sheet of every move's look: fires each move once in a quiet run (a few dummy enemies in front of the
# Pokémon), grabs the screen a moment later and tiles all of them, labelled, into docs/move_visuals.png.
# Used to compare all moves side by side (no two should read as a re-coloured copy of another).
# Needs a real window: powershell -File tools\capture_moves.ps1 [-Godot path\to\godot.exe]
# Uses a throw-away profile (Engine meta "no_save"); your save is never touched.
const MD = preload("res://scripts/moves_data.gd")
const OUT := "res://docs/move_visuals.png"
const CW := 240
const CH := 150
const COLS := 8


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _clear_fx(m) -> void:
	for layer in [m.pfx, m.pfx_low]:
		if layer == null:
			continue
		for k in ["parts", "sprs", "rings", "slashes", "beams"]:
			(layer.get(k) as Array).clear()
	for b in m.bullets:
		if is_instance_valid(b):
			b.queue_free()
	m.bullets.clear()
	for f in m.fields:
		if is_instance_valid(f):
			f.queue_free()
	m.fields.clear()


func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["settings"]["quality"] = 3
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_region = 0
	var ids: Array = MD.MOVES.keys()
	ids.sort()
	var rows: int = int(ceil(float(ids.size()) / float(COLS)))
	var sheet := Image.create(COLS * CW, rows * (CH + 18), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#141126"))
	var labels: Array = []
	for i in range(ids.size()):
		var id: String = String(ids[i])
		# a fresh run per move, so nothing a previous move left behind (orbits, fields, rings) shows up in this cell
		seed(7)
		var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(m)
		await _frames(20)
		for dd in ["wave", "rift", "meowth", "boss", "map", "eter"]:
			m.dir_done[dd] = true
		m.rift_check = 1.0e9
		m.player.invuln = 1.0e9
		for e in m.enemies:
			e.hp = 1.0e9
		while m.enemies.size() < 4:
			var en = m._spawn_one()
			en.hp = 1.0e9
		for j in range(m.enemies.size()):
			var en2 = m.enemies[j]
			en2.position = m.player.position + Vector2(62.0 + float(j % 2) * 34.0, -36.0 + float(j) * 24.0)
			en2.hp = 1.0e9
		_clear_fx(m)
		m.player.aim = 0.0
		m.aim_manual = true   # fire even if the dummies are out of reach (melee waits for a target otherwise)
		m.target = m.enemies[0]
		var mv: Dictionary = m._new_move(id, 3)
		m.player.moves = [mv]
		mv["t"] = 0.0
		m._tick_move(mv, 0.016)
		await _frames(6)
		var img: Image = root.get_viewport().get_texture().get_image()
		var vs: Vector2i = img.get_size()
		var cell: Image = img.get_region(Rect2i(vs.x / 2 - 200, vs.y / 2 - 140, 400, 250))
		cell.convert(Image.FORMAT_RGBA8)
		cell.resize(CW, CH, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(cell, Rect2i(0, 0, CW, CH), Vector2i((i % COLS) * CW, (i / COLS) * (CH + 18)))
		labels.append([Vector2i((i % COLS) * CW + 4, (i / COLS) * (CH + 18) + CH + 14), String(MD.MOVES[id].get("name", id))])
		m.queue_free()
		await _frames(2)
	# names go under each cell (drawn through a throw-away viewport so the PNG carries them)
	var vp := SubViewport.new()
	vp.size = sheet.get_size()
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(vp)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(sheet)
	vp.add_child(tr)
	for lb in labels:
		var l := Label.new()
		l.text = String(lb[1])
		l.position = Vector2(lb[0]) - Vector2(0, 14)
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color("#ffe9a8"))
		vp.add_child(l)
	await _frames(3)
	var outimg: Image = vp.get_texture().get_image()
	outimg.save_png(ProjectSettings.globalize_path(OUT))
	print("contact sheet: ", ids.size(), " moves -> ", OUT)
	quit()
