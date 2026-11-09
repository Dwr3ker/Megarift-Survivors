extends SceneTree
# Gigantamax: a Gigantamax den grants its Pokémon the Gigantamax Factor; with it, Dynamax becomes Gigantamax (bigger,
# storm crown, G-MAX button and banner) and the big waves are the Pokémon's own G-Max move. All 32 moves work.
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
	var GM = load("res://scripts/gmax.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["stats"]["dens"] = 1
	check("32 Pokémon can Gigantamax", GM.SPECIES.size() == 32)
	# ---- a Gigantamax den gives the Factor ----
	var m = await _run(SV, 6)
	m.run_time = 400.0
	var tries := 0
	while tries < 200:
		tries += 1
		m._open_rift(-1, true)
		if m.rift != null and bool(m.rift_info.get("gmax", false)):
			break
		if m.rift != null:
			m.rift.queue_free()
			m.rift = null
			m._rift_drop_arena()
	check("some dens are Gigantamax dens", m.rift != null and bool(m.rift_info.get("gmax", false)), "%d tries" % tries)
	var gdex: int = int(m.rift_info["dex"])
	check("its boss can Gigantamax", GM.capable(gdex), str(gdex))
	m.rift.position = m.player.position
	m.rift.t = 2.0
	m.rift_check = 0.0
	var g := 0
	while m.arena == null and g < 600:
		g += 1
		m.rift_check = 1.0e9
		await process_frame
	check("you enter the Gigantamax den", m.arena != null and bool(m.ainfo.get("gmax", false)))
	var boss = m.ainfo.get("boss")
	var DYN = load("res://scripts/dynamax.gd")
	check("the boss wears the storm crown", boss != null and boss.get_children().any(func(c): return c.get_script() == DYN.Crown))
	m._legend_down(boss)
	check("beating it grants the Gigantamax Factor", GM.has_factor(SV.d, gdex))
	m.queue_free()
	await process_frame
	# ---- Gigantamax in a run ----
	GM.grant(SV.d, 6)
	var r = await _run(SV, 6)
	r.run_time = 400.0
	check("the button says G-MAX", r.hud.dyn_gmax)
	for i in range(8):
		var e = r._spawn_one()
		e.position = r.player.position + Vector2.from_angle(float(i)) * 120.0
		e.hp = 1.0e7
		e.max_hp = 1.0e7
		e.spd = 0.0
	r._dyn_start()
	await create_timer(2.0).timeout
	check("Dynamax becomes Gigantamax", r.dyn.giga and r.hud.dyn_word == "GIGANTAMAX")
	check("it grows bigger than Dynamax", r.player.scale.x > 1.75, str(r.player.scale))
	var DYN2 = load("res://scripts/dynamax.gd")
	check("its stats are higher than Dynamax's (+40% vs +30%)", r.dyn.dmg_k > DYN2.DMG_K and r.dyn.stat_k > DYN2.STAT_K and r.dyn.taken > DYN2.TAKEN)
	r.dyn.n = 2
	r.dyn.pulse = 0.0
	var hp0: float = 0.0
	for e in r.enemies:
		hp0 += e.hp
	for i in range(30):
		await process_frame
	var hp1: float = 0.0
	var burned := 0
	for e in r.enemies:
		hp1 += e.hp
		if e.burn > 0:
			burned += 1
	check("the big wave is G-Max Wildfire: it hurts and burns", hp1 < hp0 and burned > 0, "burned %d" % burned)
	check("it leaves burning ground", r.dyn.gm.zones.size() > 0)
	# every G-Max move runs
	var bad: Array = []
	for d in GM.SPECIES:
		var gm = GM.new()
		gm.setup(r, d)
		gm.fire(80.0)
		for i in range(4):
			gm.tick(0.3)
	check("all 32 G-Max moves run", bad.is_empty())
	r.queue_free()
	await process_frame
	# ---- no Factor: plain Dynamax ----
	SV.d["gmax"] = {}
	var p = await _run(SV, 6)
	p.run_time = 400.0
	p._dyn_start()
	await process_frame
	var DYN3 = load("res://scripts/dynamax.gd")
	check("without the Factor it is a plain Dynamax", not p.dyn.giga and p.hud.dyn_word == "DYNAMAX" and not p.hud.dyn_gmax and p.dyn.dmg_k == DYN3.DMG_K)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
