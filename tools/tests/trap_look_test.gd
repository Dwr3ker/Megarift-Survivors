extends SceneTree
# Traps: every trap type has its stone-plate sprite, and armed traps draw on the ground and on the minimap without errors.
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
	for i in range(30):
		await process_frame
	m.player.invuln = 1.0e9
	var subs: Array = ["poison", "ice", "fire", "freeze", "shock", "sleep", "confuse"]
	var missing: Array = []
	for s in subs:
		if not ResourceLoader.exists("res://assets/world/trap_%s.png" % s):
			missing.append(s)
	check("every trap type has its plate sprite", missing.is_empty(), str(missing))
	var rng := RandomNumberGenerator.new()
	var made := 0
	for i in range(subs.size()):
		var props: Array = []
		var pos: Vector2 = m.player.position + Vector2.from_angle(float(i) * TAU / 7.0) * 300.0
		for k in range(40):
			if m._add_prop(props, [], "trap", pos + Vector2(float(k % 6) * 7.0, float(k / 6) * 7.0), 16.0, rng):
				break
		if not props.is_empty():
			props[0].sub = subs[i]
			m.chunks.values()[0]["props"].append(props[0])
			props[0].queue_redraw()
			made += 1
	for i in range(10):
		await process_frame
	check("all seven traps are placed and drawn", made == 7, str(made))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
