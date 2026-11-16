extends SceneTree
# Roadmap step 13: Tera in each mode (docs/tera.md). Normal, Hyper, Daily, Rifts, Rush, Type survival, Party and Team
# have it; Tower doesn't. In Team mode the Tera type is the Pokémon you control, and switching ends Tera.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _run(SV, mode: String, hyper: bool = false):
	SV.run_mode = mode
	SV.run_hyper = hyper
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	m.player.invuln = 1.0e9
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var TERA = load("res://scripts/tera.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.run_dex = 6
	SV.set_tera_type(6, "water")
	SV.set_tera_type(25, "fire")
	for md in [["normal", false], ["normal", true], ["daily", false], ["rifts", false], ["rush", false], ["type", false], ["party", false]]:
		var m = await _run(SV, String(md[0]), bool(md[1]))
		var nm: String = String(md[0]) + (" (Hyper)" if md[1] else "")
		m.tera_pts = TERA.NEED
		await process_frame
		check("%s: the TERA button shows and Tera starts" % nm, m.hud.tera_btn == 2 and m._tera_can(), "btn %d" % m.hud.tera_btn)
		m.queue_free()
		await process_frame
	var t = await _run(SV, "tower")
	t.tera_pts = TERA.NEED
	await process_frame
	check("Tower: no Tera (no button, can't start)", t.hud.tera_btn == 0 and not t._tera_can())
	t.queue_free()
	await process_frame
	# Team mode
	SV.d["owned"] = {"6": {"n": 1}, "25": {"n": 1}}
	SV.d["team"] = [6, 25]
	SV.d["selected"] = 6
	var tm = await _run(SV, "team")
	check("Team mode: a team of two", tm.team.size() == 2, str(tm.team.size()))
	tm.tera_pts = TERA.NEED
	tm._tera_start()
	check("Team: the Tera type is the Pokémon you control (Charizard: Water)", tm.tera_type_run == "water")
	tm.swap_cd = 0.0
	tm._swap_team(1)
	await process_frame
	check("Team: switching ends Tera", tm.team_cur == 1 and not tm._tera_on())
	check("Team: one orb for the team (used)", tm.tera_used and not tm._tera_can())
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
