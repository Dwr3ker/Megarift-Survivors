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
	m.mega_told = true   # no "Mega Evolution unlocked" line in late-run shots
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
	SV.d["nick"] = "Ash"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	had_run = RS.exists()
	real_run = FileAccess.get_file_as_string(RS.PATH) if had_run else ""   # your saved run is put back at the end
	RS.clear()
	await _frames(5)
	if OS.get_cmdline_user_args().has("--new-only"):   # only the alpha.11 screens: `... --script res://tools/capture_docs.gd -- --new-only`
		await _shop_and_gacha()
		_finish()
		return
	if OS.get_cmdline_user_args().has("--hud-only"):
		await _hud_bits()
		_finish()
		return
	if OS.get_cmdline_user_args().has("--more-only"):   # only the screens added in 0.1.3: `... -- --more-only`
		await _more()
		await _four_three()
		_finish()
		return

	# ---------- menus ----------
	load("res://scripts/crash_report.gd").take_crash_flag()
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _frames(40)
	SV.d["selected"] = 4
	menu._show("main")
	await _frames(20)
	_hush(menu)
	await _shot("main_menu")
	menu.dex_gen = 1
	menu.dex_sel = 4
	menu._show("dex")
	await _frames(20)
	_hush(menu)
	await _shot("pokemon_list_evolution_line_rarity_ball")
	menu.dex_sel = 6
	menu._dex_detail()
	await _frames(10)
	_hush(menu)
	await _shot("pokemon_list_mega_capable")
	menu._show("layout")
	await _frames(20)
	_hush(menu)
	await _shot("hud_layout_editor")
	menu.set_tab = 2
	menu._show("settings")
	await _frames(10)
	menu.set_tab = 2
	menu._refresh_settings()
	await _frames(10)
	_hush(menu)
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
	await _frames(240)   # the evolution scene runs about 4 s
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
	load("res://scripts/crash_report.gd").take_crash_flag()
	var menu2 = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu2)
	await _frames(40)
	menu2._ongoing_prompt()
	await _frames(15)
	_hush(menu2)
	await _shot("resume_reminder")
	menu2.queue_free()
	await _frames(3)
	await _shop_and_gacha()
	await _more()
	await _hud_bits()
	await _four_three()
	_finish()


# ---------- alpha.11: item Skip card, Kecleon shop with a reservation, gacha completion bonus ----------
func _shop_and_gacha() -> void:
	var m = await _run(6)
	m.item = ""
	m._offer_item()
	m.cards.age = 5.0
	await _frames(15)
	await _shot("item_skip_card")
	m.cards.hide_cards()
	m.choosing = false
	m.coins = 640
	m.kec.reserved = "chrono"   # a shiny-Kecleon item, so it shows as the 4th card next to the golden offers
	m.kec.reserve_paid = m.kec.reserve_cost("chrono")
	m.kec.spawn(func(_p): return true, "gold")
	m.kec.open_ui()
	await _frames(15)
	await _shot("kecleon_shop_reserve")
	m.kec.close_ui()
	await _end(m)
	# evolution scene: white silhouettes swapping, then the reveal
	m = await _run(4)
	m.player.level = 16
	m.pending_levels = 1
	m._open_cards()
	m.cards.age = 5.0
	await _frames(12)
	m._on_card_chosen(0)
	var cine = m.evo_cine
	for st in [[1.4, "evolution_scene_morph"], [3.2, "evolution_scene_reveal"]]:
		while is_instance_valid(cine) and float(cine.t) < float(st[0]):
			await process_frame
		await _shot(String(st[1]))
	await _end(m)
	# buff badges beside the Pokémon: ATK x3, SPD x1, DEF x5
	m = await _run(25)
	for st in [["atk", 3], ["spd", 1], ["def", 5]]:
		var bf: Dictionary = m.player.buffs[String(st[0])]
		bf["t"] = 8.0
		bf["amount"] = 0.1
		bf["ts"] = []
		for j in range(int(st[1])):
			bf["ts"].append(7.5 - float(j))
		bf["n"] = int(st[1])
	await _frames(30)
	await _shot("buff_badges", Rect2i(440, 200, 400, 300))
	await _end(m)
	# gacha: drop about 40% of Kanto so the completion line shows a partial bonus
	load("res://scripts/crash_report.gd").take_crash_flag()
	var saved_owned: Dictionary = SV.d["owned"].duplicate(true)
	var i := 0
	for p in SV.region_pool(1):
		if i % 5 < 2:
			SV.d["owned"].erase(str(int(p["dex"])))
		i += 1
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _frames(40)
	menu.gacha_region = 1
	menu._show("gacha")
	await _frames(20)
	_hush(menu)
	await _shot("gacha_completion_bonus")
	SV.d["tickets"] = 56   # Max pull: 5 batches of 10, 6 tickets left over
	menu._confirm_max_pull("t1")
	await _frames(10)
	_hush(menu)
	await _shot("gacha_max_pull_confirm")
	menu._do_max_pull("t1")
	await _frames(20)
	_hush(menu)
	await _shot("gacha_max_pull")
	# Legend Pick: shards and the picker of legendaries you don't own (drop a few legendaries from the save first)
	menu.gacha_result.visible = false
	for p in SV.dex_list:
		if bool(p.get("leg", false)) and int(p["dex"]) % 3 == 0:
			SV.d["owned"].erase(str(int(p["dex"])))
	SV.d["lshards"] = 6
	menu._refresh_gacha()
	await _frames(10)
	_hush(menu)
	await _shot("gacha_legend_shards")
	menu._legend_picker()
	await _frames(15)
	_hush(menu)
	await _shot("legend_pick")
	menu.queue_free()
	await _frames(3)
	SV.d["owned"] = saved_owned


# ---------- the menus and features added or redrawn since alpha.6 (also: `-- --more-only`) ----------
func _new_card(m, nid: String) -> Dictionary:
	var MD = load("res://scripts/moves_data.gd")
	var nd: Dictionary = MD.MOVES[nid]
	return {"cat": "new", "id": nid, "key": "new:" + nid, "w": 10.0, "title": String(nd["name"]), "desc": m._move_desc(nd),
		"icon": "move:" + nid, "tag": String(MD.TYPE_NAME[String(nd["type"])]), "color": Color.html(String(MD.TYPE_COLOR[String(nd["type"])])),
		"badges": m._card_badges(nid, "new")}


func _show_cards(m, picks: Array, title: String) -> void:
	m.choosing = true
	m.cards.show_cards(picks, title)
	m.cards.can_skip = true
	m.cards.build = m._card_build(picks)
	m._card_preview_sprites()
	m.cards.age = 5.0
	await _frames(20)


func _quiet(m) -> void:
	for e in m.enemies:
		e.position += Vector2(9000, 9000)
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame


# A menu without leftovers from the test runs: no "last run ended unexpectedly" box (the script ends runs abruptly),
# no pending Shiny Charm or welcome toasts.
func _menu():
	load("res://scripts/crash_report.gd").take_crash_flag()
	var mn = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(mn)
	await _frames(40)
	_hush(mn)
	return mn


func _hush(mn) -> void:
	mn.toast_t = 0.0
	if mn.toast_lbl != null:
		mn.toast_lbl.text = ""
	mn.ach_t = 0.0
	if mn.ach_pop != null:
		mn.ach_pop.modulate.a = 0.0


func _more() -> void:
	var MG = load("res://scripts/mega.gd")
	var saved: Dictionary = SV.d.duplicate(true)
	# --- username prompt ---
	SV.d["nick"] = ""
	Engine.set_meta("force_name_prompt", true)
	var menu = await _menu()
	await _shot("username_prompt")
	menu._name_confirm("Ash")
	Engine.remove_meta("force_name_prompt")
	await _frames(5)
	_hush(menu)
	# --- Pokémon list: types, Mega Stones, filters, favorites, IVs and natures ---
	SV.d["selected"] = 6
	menu.dex_gen = 1
	menu.dex_show = 0
	menu.dex_grid_sz = 1
	menu.dex_sel = 6
	menu._show("dex")
	await _frames(20)
	menu.dex_sel = 6
	menu._refresh_dex()
	await _frames(10)
	_hush(menu)
	await _shot("pokemon_list_types")
	menu.dex_grid_sz = 0
	menu._refresh_dex()
	await _frames(12)
	_hush(menu)
	await _shot("pokemon_list_small_grid")
	menu.dex_grid_sz = 1
	menu._refresh_dex()
	await _frames(6)
	var to: OptionButton = menu.find_child("DexType", true, false)
	to.show_popup()
	await _frames(8)
	_hush(menu)
	await _shot("pokemon_list_type_filter")
	to.get_popup().hide()
	await _frames(4)
	menu.dex_gen = 0
	menu.dex_show = 4
	menu._refresh_dex()
	await _frames(12)
	_hush(menu)
	await _shot("pokemon_list_mega_stones")
	SV.d["dex_fav"] = {"6": true, "25": true, "150": true, "94": true, "149": true, "131": true}
	menu.dex_show = 0
	menu.dex_gen = 1
	menu.dex_sort = 4
	menu.dex_sel = 25
	menu._refresh_dex()
	await _frames(12)
	_hush(menu)
	await _shot("pokemon_list_favorites")
	menu.dex_sort = 0
	menu.dex_sel = 25
	menu._refresh_dex()
	await _frames(10)
	_hush(menu)
	await _shot("ivs_and_nature")
	SV.d["coins"] = 12500
	menu._iv_train_ui(25)
	await _frames(8)
	_hush(menu)
	await _shot("iv_training")
	menu._mint_ui(25)
	await _frames(8)
	_hush(menu)
	await _shot("nature_mint")
	menu.gacha_result.visible = false
	# --- Upgrades: nature, IVs, Train IVs and Change nature ---
	menu._show("up")
	await _frames(15)
	_hush(menu)
	await _shot("upgrades_ivs")
	# --- region picker, daily challenge, achievements ---
	SV.d["region_clear"] = {"1": true, "2": true, "3": true, "4": true, "5": true}
	menu._show("modes")
	await _frames(10)
	menu._region_picker()
	await _frames(15)
	_hush(menu)
	await _shot("region_map_picker")
	menu.gacha_result.visible = false
	menu._modes_select("daily")
	await _frames(25)
	_hush(menu)
	await _shot("daily_challenge")
	var PG = load("res://scripts/progress.gd")
	PG.check()
	PG.toasts.clear()
	menu.goals_tab = "a"
	menu.ach_cat = "regiones"
	menu._show("goals")
	await _frames(10)
	menu.goals_tab = "a"
	menu.ach_cat = "regiones"
	menu._refresh_goals()
	await _frames(15)
	_hush(menu)
	await _shot("achievements_regions")
	# --- Gacha: Legendary Banner, a locked region banner, the Shiny Charm line ---
	menu.gacha_region = SV.BANNER_BASE
	menu._show("gacha")
	await _frames(20)
	_hush(menu)
	await _shot("legendary_banners")
	menu.gacha_region = 1
	menu._refresh_gacha()
	await _frames(15)
	_hush(menu)
	await _shot("gacha_shiny_charm")
	SV.d["region_clear"] = {"1": true}
	SV.d["regions_open"] = []
	menu.gacha_region = 3
	menu._refresh_gacha()
	await _frames(15)
	_hush(menu)
	await _shot("gacha_locked_banner")
	menu.queue_free()
	await _frames(3)
	SV.d = saved.duplicate(true)
	SV.d["nick"] = "Ash"

	# --- level-up cards: move previews, the Mega card with its stone ---
	var m = await _run(25)
	await _quiet(m)
	await _show_cards(m, [_new_card(m, "ember"), _new_card(m, "hydro-pump"), _new_card(m, "flamethrower")], "Level 5 - choose an upgrade")
	await _shot("move_previews")
	m.cards.hide_cards()
	m.choosing = false
	await _show_cards(m, [_new_card(m, "fire-spin"), _new_card(m, "rock-slide"), _new_card(m, "thunderbolt")], "Level 8 - choose an upgrade")
	await _shot("move_previews_2")
	await _end(m)
	m = await _run(6)
	await _quiet(m)
	m.run_time = 1900.0
	await _show_cards(m, [{"cat": "stat", "id": "atk", "title": "Power", "desc": "+10% damage with every move.", "icon": "fist", "tag": "", "color": Color("#ffb86b")}, MG.card(m),
		{"cat": "stat", "id": "spd", "title": "Sprint", "desc": "+7% movement speed.", "icon": "boot", "tag": "", "color": Color("#6bd66b")}], "Level 30 - choose an upgrade")
	m.cards.sel = 1
	await _frames(10)
	await _shot("mega_card_stone")
	await _end(m)

	# --- fusion: the Fuse / Keep both card, and the move bar with a bonded pair and the Fusion Move ---
	m = await _run(6)
	await _quiet(m)
	for id in ["water-gun", "vine-whip", "gust", "bite"]:
		m.player.moves.append(m._new_move(id, 1))
	var ids: Array = m.player.moves.map(func(q): return String(q["id"]))
	for mv in m.player.moves:
		if [ids[3], ids[4]].has(String(mv["id"])):
			mv["evolved"] = true
			mv["lvl"] = m._max_lvl(mv)
	m.bond_ids = [ids[1], ids[2], ids[3], ids[4]]
	m._offer_fuse()
	m.cards.age = 5.0
	await _frames(20)
	await _shot("fuse_choice_card")
	m.cards.hide_cards()
	m.choosing = false
	m._do_fuse()
	m.bond_ids = [ids[1], ids[2]]
	await _frames(30)
	await _shot("move_bar_bonds", Rect2i(340, 600, 600, 120))
	await _end(m)

	# --- the Mega Stone rift: overworld look, the rift entrance, the fight with minions ---
	m = await _run(6)
	await _quiet(m)
	m.player.active = false
	m.run_time = 1250.0
	m._open_rift(-1, false, true)
	m.rift.position = m.player.position + Vector2(200, 60)
	await _frames(80)
	await _shot("mega_stone_rift")
	m.rift.t = 2.0
	m.player.active = true
	m.player.position = m.rift.position + Vector2(10, 0)
	var guard := 0
	while m.rift_in_t <= 0.0 and guard < 60:
		guard += 1
		await process_frame
	while m.rift_in_t > 0.12 and guard < 400:
		guard += 1
		await process_frame
	await _shot("rift_entry_pull")
	while (m.hud.rift_intro_t <= 0.0 or m.hud.rift_intro_t > 1.6) and guard < 1200:
		guard += 1
		await process_frame
	await _shot("rift_intro_banner")
	m.player.invuln = 1.0e6
	m.minion_t = 0.0
	m.ainfo["t"] = 5.0
	var boss = m.ainfo.get("boss")
	if boss != null:
		m._mega_minions(0.1, boss)
		m.minion_t = 0.0
		m._mega_minions(0.1, boss)
	await _frames(70)
	await _shot("mega_rift_minions")
	await _end(m)

	# --- region maps ---
	for rg in [[3, "region_map_hoenn", 258], [6, "region_map_kalos", 656]]:
		SV.run_region = int(rg[0])
		m = await _run(int(rg[2]))
		await _enemies(m, 6)
		await _frames(60)
		await _shot(String(rg[1]))
		await _end(m)
	SV.run_region = 0

	# --- pickups and chests ---
	m = await _run(25)
	await _quiet(m)
	m.player.invuln = 1.0e9
	var c: Vector2 = m.player.position
	var rng := RandomNumberGenerator.new()
	m._alt_legend = false
	for cs in [[Vector2(-330, -110), "", false], [Vector2(-230, -110), "big", false], [Vector2(-120, -110), "", true]]:
		var props: Array = []
		for k in range(30):
			if m._add_prop(props, [], "chest", c + cs[0] + Vector2(float(k % 5) * 4.0, float(k / 5) * 4.0), 20.0, rng):
				break
		if not props.is_empty():
			props[0].sub = String(cs[1])
			props[0].used = bool(cs[2])
	var kinds: Array = [["pouch", ""], ["potion", ""], ["xp", ""], ["pack", ""], ["pack", "rare"], ["crate", "medical"], ["crate", "resource"], ["crate", "rare"], ["crate", "golden"]]
	for i in range(kinds.size()):
		m.poi._mk(String(kinds[i][0]), String(kinds[i][1]), c + Vector2(-330 + i * 82, 100 + (i % 2) * 6), 999.0)
	for i in range(6):
		var o = m._spawn_orb(c + Vector2(40 + i * 46, -110), ["coin", "ticket", "ticket10", "item", "heal", "magnet"][i], 1.0)
		o.vel = Vector2.ZERO
	for i in range(40):
		for o in m.orbs:
			o.vel = Vector2.ZERO
		await process_frame
	await _shot("pickups")
	await _end(m)

	# --- traps ---
	m = await _run(25)
	await _quiet(m)
	m.player.active = false
	var subs: Array = ["poison", "ice", "fire", "freeze", "shock", "sleep", "confuse"]
	c = m.player.position
	for i in range(subs.size()):
		var tp: Array = []
		var pos: Vector2 = c + Vector2(-540 + i * 180, 230 if i % 2 == 0 else -230)
		for k in range(40):
			if m._add_prop(tp, [], "trap", pos + Vector2(float(k % 6) * 6.0, float(k / 6) * 6.0), 16.0, rng):
				break
		if not tp.is_empty():
			tp[0].sub = subs[i]
			m.chunks.values()[0]["props"].append(tp[0])
	await _frames(40)
	await _shot("traps")
	await _end(m)
	SV.d = saved.duplicate(true)


# ---------- attack warnings, the buff chip, allies on their own spots (also: `-- --hud-only`) ----------
func _hud_bits() -> void:
	var m = await _run(887)
	await _quiet(m)
	m.player.active = false
	var c: Vector2 = m.player.position
	var hs: Array = [m._hazard_zone(c + Vector2(-260, 40), 110.0, 30.0, 0.0, "fire", Color("#ff7b3d")),
		m._hazard_beam(c + Vector2(-380, -150), 0.2, 300.0, 30.0, 30.0, 0.0, "psychic", Color("#ff6bd6"))]
	var a1 = m._hazard_zone(c + Vector2(280, 40), 180.0, 30.0, 0.0, "water", Color("#5aa0ff"))
	m._ally_hz(a1, 50.0)
	var a2 = m._hazard_beam(c + Vector2(120, -170), -0.1, 300.0, 30.0, 30.0, 0.0, "water", Color("#5aa0ff"))
	m._ally_hz(a2, 50.0)
	hs.append(a1)
	hs.append(a2)
	for h in hs:
		h.t = 15.0
	await _frames(30)
	await _shot("attack_warnings")
	await _end(m)
	# the buff chip beside the stats panel
	m = await _run(6)
	await _quiet(m)
	var bf: Dictionary = m.player.buffs["atk"]
	bf["t"] = 30.0
	bf["amount"] = 0.1
	bf["ts"] = [29.0, 28.0, 27.0, 26.0, 25.0, 24.0]
	bf["n"] = 6
	m.power_kind = "fury"
	m.power_t = 25.0
	await _frames(30)
	await _shot("buff_chip")
	# a summoned legendary and a caught ally on their own spots
	var alt = m.Prop.new()
	alt.position = m.player.position + Vector2(5, 5)
	m._summon_legend(alt)
	m.alpha._make_ally({"dex": 150, "types": ["psychic"], "name": "Mewtwo", "pos": m.player.position + Vector2(-5, 5)})
	await _frames(200)
	m.join_t = -1.0   # the "has joined you" banner is done
	m.hud.join_t = -1.0
	m._say("", 0.1)
	await _frames(30)
	await _shot("allies_spots")
	await _end(m)


# ---------- 4:3 screens (run last: the window size changes) ----------
func _four_three() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1024, 768))
	await _frames(20)
	SV.d["selected"] = 6
	var menu = await _menu()
	menu._show("main")
	await _frames(20)
	_hush(menu)
	await _shot("main_menu_4x3")
	menu.dex_gen = 1
	menu.dex_grid_sz = 2
	menu._show("dex")
	await _frames(25)
	_hush(menu)
	await _shot("pokemon_list_4x3")
	menu.queue_free()
	await _frames(3)
	var m = await _run(6)
	await _quiet(m)
	m.player.level = 12
	m.pending_levels = 1
	m._open_cards()
	m.cards.age = 5.0
	await _frames(15)
	await _shot("level_up_cards_4x3")
	await _end(m)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _frames(10)


func _finish() -> void:
	RS.clear()
	if had_run:
		var rf := FileAccess.open(RS.PATH, FileAccess.WRITE)
		rf.store_string(real_run)
		rf.close()
	print("DONE ", done.size(), " screenshots")
	quit(0)
