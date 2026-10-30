extends SceneTree
# Headless check of the Dynamax / Z-Move visuals: the effect nodes are created and clean themselves up, the camera push-in decays,
# every type has a Max move name, and the visuals never change the gameplay numbers.
const PWF = preload("res://scripts/power_fx.gd")
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var ZM = load("res://scripts/zmove.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(14):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	m.jd.done = true
	check("every type has a Max move name", PWF.MAX_NAME.size() == 18 and ZM.ORDER.all(func(t): return PWF.MAX_NAME.has(t)))
	# ---------- Z-Move ----------
	var kids0: int = m.player.get_child_count()
	m.z_type = "fire"
	m._z_start()
	check("starting a Z-Move adds the gather effect to the Pokémon", m.player.get_child_count() == kids0 + 1)
	check("and pushes the camera in", m.zoom_punch >= 0.1)
	for i in range(8):
		await process_frame
	check("the camera zoom follows the push", absf(m.cam.zoom.x - m.cam_zoom * (1.0 + m.zoom_punch)) < 0.01)
	for i in range(2400):
		await process_frame
		if m.z_state == "":
			break
	for i in range(240):
		await process_frame
	check("the gather effect removes itself", m.player.get_child_count() <= kids0, "%d vs %d" % [m.player.get_child_count(), kids0])
	check("the camera push has eased back", m.zoom_punch < 0.01, str(m.zoom_punch))
	check("the Z-Move still finishes", m.z_state == "")
	# ---------- Dynamax ----------
	var g0: int = m.gfx.get_child_count()
	m.player.invuln = 0.0
	m._dyn_start()
	check("Dynamax adds a sky beam", m.fx.get_children().any(func(n): return n is PWF.SkyBeam))
	var hp_max: float = m.player.max_hp
	m.dyn.pulse = 0.0
	m.dyn.tick(0.016)
	check("a Max Wave adds a shockwave to the ground layer", m.gfx.get_children().any(func(n): return n is PWF.Shock))
	for i in range(200):
		await process_frame
	check("the beam and shockwaves clean themselves up", not m.fx.get_children().any(func(n): return n is PWF.SkyBeam))
	m.dyn.t = 0.01
	m.dyn.tick(0.05)
	check("the end of Dynamax adds the puff", m.gfx.get_children().any(func(n): return n is PWF.Shock))
	check("Dynamax still ends and gives its HP bonus back", not m.dyn.active and m.player.max_hp < hp_max)
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
