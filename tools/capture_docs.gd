extends SceneTree
# Takes the screenshots used by docs/Megarift-Survivors-features.pdf (see tools/make_features_pdf.py and docs/features.json).
# It needs a real window (not --headless): run it with tools/capture_docs.ps1, which then turns the PNGs into JPEGs and rebuilds the PDF.
# It never touches your save: everything runs on a throw-away profile (Engine meta "no_save").
const OUT := "res://docs/screens/"

var SV
var EVL = load("res://scripts/evolution.gd")
var KYU = load("res://scripts/kyurem.gd")
var FM = load("res://scripts/forme.gd")
var PL = load("res://scripts/plates.gd")
var PWF = load("res://scripts/power_fx.gd")
var UNL = load("res://scripts/unlock_all.gd")
var done: Array = []
var RS = load("res://scripts/run_save.gd")
var real_run: String = ""
var had_run := false


func _shot(name: String, region: Rect2i = Rect2i()) -> void:
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if region.size.x > 0:
		img = img.get_region(region)
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	done.append(name)
	print("shot ", name)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _run(dex: int, hyper: bool = false):
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = hyper
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await _frames(40)
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	m.jd.done = true
	m.player.invuln = 1.0e6
	return m


func _end(m) -> void:
	m.queue_free()
	await _frames(3)


func _enemies(m, n: int, from: float = 150.0) -> void:
	for i in range(n):
		var e = m._spawn_one()
		e.position = m.player.position + Vector2(from + float(i) * 22.0, -60.0 + float(i) * 18.0)


func _init() -> void:
	Engine.set_meta("no_save", true)
	SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	UNL.apply(SV.d, false)   # every Pokémon, no upgrades: the Pokémon list looks complete
	SV.d["coins"] = 12500
	SV.d["tickets"] = 40
	SV.d["settings"]["quality"] = 3
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	had_run = RS.exists()
	real_run = FileAccess.get_file_as_string(RS.PATH) if had_run else ""   # your saved run is put back at the end
	RS.clear()
	await _frames(5)

	# ---------- menus ----------
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _frames(40)
	SV.d["selected"] = 4
	menu._show("main")
	await _frames(20)
	await _shot("main_menu")
	menu.dex_gen = 1
	menu.dex_sel = 4
	menu._show("dex")
	await _frames(20)
	await _shot("pokemon_list_evolution_line_rarity_ball")
	menu.dex_sel = 6
	menu._dex_detail()
	await _frames(10)
	await _shot("pokemon_list_mega_capable")
	menu._show("layout")
	await _frames(20)
	await _shot("hud_layout_editor")
	menu.set_tab = 2
	menu._show("settings")
	await _frames(10)
	menu.set_tab = 2
	menu._refresh_settings()
	await _frames(10)
	await _shot("settings_controls")
	menu.queue_free()
	await _frames(3)

	# ---------- in-run: evolution ----------
	var m = await _run(4)
	m.player.level = 16
	m.pending_levels = 1
	m._open_cards()
	m.cards.age = 5.0
	await _frames(12)
	await _shot("evolution_card")
	m._on_card_chosen(0)
	await _frames(70)
	await _shot("evolved_charmeleon")
	await _end(m)

	# ---------- Mega Evolution ----------
	m = await _run(6)
	m.run_time = 1900.0
	m._mega_start()
	await _frames(150)
	await _enemies(m, 6)
	await _frames(40)
	await _shot("mega_charizard")
	await _end(m)

	# ---------- rarity cards ----------
	m = await _run(25)
	m.player.level = 12
	m.pending_levels = 1
	m._open_cards()
	m.cards.age = 5.0
	await _frames(12)
	await _shot("level_up_cards")
	await _end(m)

	# ---------- Dynamax ----------
	m = await _run(6)
	m.run_time = 400.0
	await _enemies(m, 8)
	m.player.invuln = 1.0e6
	m._dyn_start()
	await _frames(45)
	await _shot("dynamax_beam")
	await _frames(90)
	await _shot("dynamax_max_wave")
	await _end(m)

	# ---------- Z-Move ----------
	m = await _run(6)
	m.run_time = 400.0
	m.z_type = "fire"
	m._z_start()
	await _frames(48)
	await _shot("z_move_cinematic")
	await _end(m)

	# ---------- Kyurem ----------
	m = await _run(646)
	m.run_time = 1900.0
	await _enemies(m, 6)
	KYU.apply(m, "black")
	var g = m.player.moves[0]
	g["lvl"] = m._max_lvl(g)
	m._evolve(g)
	m.player.invuln = 1.0e6
	m.player.flash = 0.0
	await _frames(200)
	m._beam(m.player.moves[0])
	await _frames(2)
	await _shot("black_kyurem_freeze_shock")
	await _end(m)
	m = await _run(646)
	m.run_time = 1900.0
	await _enemies(m, 6)
	KYU.apply(m, "white")
	await _frames(200)
	await _shot("white_kyurem")
	await _end(m)

	# ---------- Deoxys formes and Arceus plates ----------
	m = await _run(386)
	m.run_time = 400.0
	FM.apply(m, "attack")
	await _frames(170)
	await _shot("deoxys_attack_forme")
	await _end(m)
	m = await _run(493)
	m.run_time = 400.0
	PL.apply(m, "fire")
	await _enemies(m, 5)
	await _frames(120)
	await _shot("arceus_fire_plate")
	await _end(m)

	# ---------- fusion bar ----------
	m = await _run(6)
	var ids := ["flash-cannon", "hyper-voice", "rock-slide", "hail"]
	var mv: Array = []
	for id in ids:
		var q: Dictionary = m._new_move(id, 1)
		for i in range(m._max_lvl(q) - 1):
			m._level_up_move(q)
		q["evolved"] = true
		mv.append(q)
	m.player.moves = mv.duplicate()
	m.bond_ids = [ids[0], ids[1]]
	m._do_fuse()
	m.bond_ids = [String(m.player.moves[0]["id"]), ids[2]]
	m._do_fuse()
	m.bond_ids = [String(m.player.moves[0]["id"]), ids[3]]
	m._do_fuse()
	await _frames(100)
	await _shot("fusion_four_moves")
	await _end(m)

	# ---------- boss fights ----------
	m = await _run(6)
	m.run_time = 900.0
	var b = m._spawn_boss({"at": 0.0, "dex": 150, "name": "Mewtwo", "hp": 2000.0, "spd": 50.0, "dmg": 20.0, "xp": 500.0, "behavior": "chase", "shotDmg": 10.0, "shotCd": 1.1, "range": 260.0})
	b.position = m.player.position + Vector2(190.0, -40.0)
	await _frames(40)
	await _shot("boss_hp_bar")
	await _end(m)
	m = await _run(6)
	m.run_time = 3600.0
	m._spawn_eternatus()
	await _frames(120)
	await _shot("eternamax_eternatus")
	await _end(m)

	# ---------- item swap and the saved-run reminder ----------
	m = await _run(6)
	SV.d["item_lock"] = false
	m.has_bag = true
	m.has_bag3 = true
	m.item = "leftovers"
	m.item2 = "choiceband"
	m.item3 = "quickclaw"
	m._offer_item()
	m.cards.age = 5.0
	await _frames(15)
	await _shot("item_swap_screen")
	await _end(m)

	# ---------- the saved-run reminder ----------
	m = await _run(6)
	m.run_time = 754.0
	m.player.level = 9
	RS.save(m)
	await _end(m)
	var menu2 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu2)
	await _frames(40)
	menu2._ongoing_prompt()
	await _frames(15)
	await _shot("resume_reminder")
	menu2.queue_free()
	await _frames(3)
	RS.clear()
	if had_run:
		var rf := FileAccess.open(RS.PATH, FileAccess.WRITE)
		rf.store_string(real_run)
		rf.close()
	print("DONE ", done.size(), " screenshots")
	quit(0)
