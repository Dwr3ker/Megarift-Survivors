extends SceneTree
# A rift that opens on top of a paid chest (or any other map button): once you are inside, the chest's price button
# is gone and Space dashes again. It used to stay stuck on screen for the whole fight.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 6
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
	for e in m.enemies:
		e.position += Vector2(9000, 9000)
	# a paid chest right where the rift opens
	var ch = m.Prop.new()
	ch.kind = "chest"
	ch.sub = "paid"
	ch.position = m.player.position + Vector2(20, 0)
	var c: Vector2i = m._chunk_of(ch.position)
	if not m.chunks.has(c):
		m.chunks[c] = {"props": []}
	m.chunks[c]["props"].append(ch)
	m.world.add_child(ch)
	m._spawn_orb(m.player.position + Vector2(10, 0), "ball", 1.0)
	await process_frame
	await process_frame
	check("next to the chest its price button shows", m.hud.act_txt != "", "'%s'" % m.hud.act_txt)
	m._open_rift(-1, false)
	m.rift.position = m.player.position
	m.rift.t = 2.0
	var g := 0
	while m.arena == null and g < 600:
		g += 1
		await process_frame
	for i in range(10):
		await process_frame
	check("you are inside the rift", m.arena != null)
	check("the chest's button is gone inside the rift", m.hud.act_txt == "", "'%s'" % m.hud.act_txt)
	check("and no map marker is left on screen", m.hud.poi_marks.is_empty())
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
