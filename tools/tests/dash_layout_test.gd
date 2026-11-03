extends SceneTree
var ok := true
func check(n: String, c: bool, d: String = "") -> void:
	print(("PASS  " if c else "FAIL  ") + n + ("  " + d if d != "" else ""))
	if not c: ok = false
func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	var HL = load("res://scripts/hud_layout.gd")
	check("the Dash button is in the HUD layout editor", HL.IDS.has("dash"))
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(10):
		await process_frame
	var r0: Rect2 = m.hud.dash_rect()
	HL.set_el("dash", Vector2(-400, -150), 130)
	var r1: Rect2 = m.hud.dash_rect()
	check("moving it moves the real button", r1.position.distance_to(r0.position + Vector2(-400, -150)) < 1.0, "%s -> %s" % [r0, r1])
	check("resizing it resizes the real button (and its tap area)", absf(r1.size.x - 130.0) < 0.5)
	HL.set_el("dash", Vector2(5000, 5000), 100)
	var r2: Rect2 = m.hud.dash_rect()
	var vp: Vector2 = m.hud.get_viewport_rect().size
	check("it can't be dragged off screen", r2.end.x <= vp.x + 0.5 and r2.end.y <= vp.y + 0.5)
	HL.reset_el("dash")
	check("reset puts it back", m.hud.dash_rect() == r0)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
