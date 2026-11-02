extends SceneTree
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(20):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.player.invuln = 1.0e9
	m.dir_finale = true   # a "quiet" phase, like a boss or legendary fight
	check("the map items count as quiet during the fight", m.poi._quiet())
	var pp: Vector2 = m.player.position
	m.balls = 0
	var pouch = m.poi._mk("pouch", "", pp + Vector2(10, 0), 45.0)
	var pack = m.poi._mk("pack", "", pp + Vector2(30, 0), 45.0)
	var n0: int = m.poi.items.size()
	m.poi.pick_t = 0.0
	m.poi.pack_t = 0.0
	m.poi.update(0.016)
	check("a pouch you touch during the fight is picked up", not is_instance_valid(pouch) or pouch.done, "balls=%d" % m.balls)
	check("a parcel next to you shows the Open button during the fight", m.hud.act_txt != "", m.hud.act_txt)
	check("no new items spawn during the fight", m.poi.items.size() <= n0, "%d -> %d" % [n0, m.poi.items.size()])
	m.dir_finale = false
	m.balls = m.BALL_CAP
	var pouch2 = m.poi._mk("pouch", "", m.player.position + Vector2(-10, 0), 45.0)
	m.poi.update(0.016)
	check("a pouch with a full bag stays and says why", is_instance_valid(pouch2) and not pouch2.done and bool(pouch2.get_meta("told", false)))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
