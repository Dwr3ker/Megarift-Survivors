extends SceneTree
# Headless check (compact cards show only the initial: M / P / C / F): the collection card shows a Mega/Primal/Crowned badge only for capable Pokemon.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func badge_text(btn: Node) -> String:
	for ch in btn.get_children():
		if ch is PanelContainer:
			for g in ch.get_children():
				if g is Label:
					return g.text
	return ""

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	# Pretend these are owned so the card shows its full face. The menu autosaves, so the real ownership is
	# snapshotted here and restored (and re-saved) at the end.
	var snap: Dictionary = SV.d.duplicate(true)   # whole save: the menu also marks "What's new" as seen
	for d in [6, 382, 888, 25, 386]:
		SV.d["owned"][str(d)] = {"shiny": false}
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	var c6 = menu._dex_card(SV.dex_by[6], true)
	check("Charizard card: M (mega) badge", badge_text(c6) == "M", badge_text(c6))
	var c382 = menu._dex_card(SV.dex_by[382], true)
	check("Kyogre card: P (primal) badge", badge_text(c382) == "P", badge_text(c382))
	var c888 = menu._dex_card(SV.dex_by[888], true)
	check("Zacian card: C (crowned) badge", badge_text(c888) == "C", badge_text(c888))
	var c386 = menu._dex_card(SV.dex_by[386], true)
	check("Deoxys card: F (forme) badge", badge_text(c386) == "F", badge_text(c386))
	var c25 = menu._dex_card(SV.dex_by[25], true)
	check("Pikachu card: no badge", badge_text(c25) == "", badge_text(c25))
	var c6_locked = menu._dex_card(SV.dex_by[6], false)
	check("not owned (hidden): no badge", badge_text(c6_locked) == "", badge_text(c6_locked))
	SV.d = snap
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
