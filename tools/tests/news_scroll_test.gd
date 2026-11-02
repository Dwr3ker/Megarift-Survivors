extends SceneTree
# "What's new" fits the screen: the release list and the article each scroll on their own (the long release list used to
# make the page taller than the screen, so the article could not scroll).
func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	menu.news_sel = 1
	menu._show("news")
	for i in range(6):
		await process_frame
	var vp: Vector2 = root.get_visible_rect().size
	var sc: ScrollContainer = menu.news_scroll
	var r: Rect2 = sc.get_global_rect()
	var bar: VScrollBar = sc.get_v_scroll_bar()
	print("viewport ", vp, " article rect ", r, " content ", menu.news_box.size.y, " scroll max ", bar.max_value - bar.page)
	var rail_sc = menu.news_rail.get_parent()
	print("rail rect ", rail_sc.get_global_rect(), " rail content ", menu.news_rail.size.y)
	var ok: bool = r.end.y <= vp.y + 1.0 and bar.max_value - bar.page > 10.0 and rail_sc.get_global_rect().end.y <= vp.y + 1.0
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit()
