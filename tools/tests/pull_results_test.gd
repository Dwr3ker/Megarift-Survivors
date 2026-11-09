extends SceneTree
# Pull results: big Pokémon sized from the screen, all the same size, the Max pull list scrolls with the right stick.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["nick"] = "Tester"
	SV.d["owned"]["25"] = {"n": 1}
	SV.d["tickets"] = 500
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("gacha")
	for i in range(5):
		await process_frame
	var r10: Array = SV.pull(menu.gacha_region, 10, "t1")
	menu._show_pulls(r10)
	for i in range(5):
		await process_frame
	var pvs: Array = menu.gacha_result.find_children("*", "Control", true, false).filter(func(n): return n.get_script() == menu.Preview)
	check("x10: ten Pokémon", pvs.size() == 10, str(pvs.size()))
	check("x10: bigger than before (150x110)", pvs.size() > 0 and pvs[0].size.x > 150.0, str(pvs[0].size) if pvs.size() > 0 else "")
	check("x10: every Pokémon sized by its body", pvs.all(func(p): return p.fit > 0.0))
	var okb: Button = menu.gacha_result.find_children("*", "Button", true, false).back()
	var vp: Vector2 = menu.get_viewport_rect().size
	check("x10: Accept fits on screen", okb.get_global_rect().end.y <= vp.y + 1.0, "%.0f / %.0f" % [okb.get_global_rect().end.y, vp.y])
	var big: Array = []
	for i in range(5):
		big.append_array(SV.pull(menu.gacha_region, 10, "t1"))
	menu._show_batch(big, [])
	for i in range(5):
		await process_frame
	var sc: ScrollContainer = menu.gacha_result.find_children("*", "ScrollContainer", true, false)[0]
	var cell_pv = sc.find_children("*", "Control", true, false).filter(func(n): return n.get_script() == menu.Preview)[0]
	check("Max pull: bigger than before (106x80)", cell_pv.size.x > 106.0 and cell_pv.size.y > 80.0, str(cell_pv.size))
	check("Max pull: the list is longer than the box", sc.get_v_scroll_bar().max_value > sc.size.y)
	var y0: int = sc.scroll_vertical
	for i in range(20):
		menu._results_scroll(1.0, 0.016)
	await process_frame
	check("right stick down scrolls the list", sc.scroll_vertical > y0, "%d -> %d" % [y0, sc.scroll_vertical])
	var y1: int = sc.scroll_vertical
	for i in range(10):
		menu._results_scroll(-1.0, 0.016)
	await process_frame
	check("right stick up scrolls back", sc.scroll_vertical < y1)
	var okb2: Button = menu.gacha_result.find_children("*", "Button", true, false).back()
	check("Max pull: Accept fits on screen", okb2.get_global_rect().end.y <= vp.y + 1.0)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
