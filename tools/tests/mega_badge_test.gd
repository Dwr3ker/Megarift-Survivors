extends SceneTree
# Collection cards: a Pokémon that can change form shows the item it uses (Mega Stone, orb, rusted sword / shield);
# Deoxys (no item) keeps its F badge; other Pokémon and unowned cards show nothing.
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

func stone(btn: Node) -> Texture2D:
	var r = btn.find_child("MegaStone", false, false)
	return (r as TextureRect).texture if r is TextureRect else null

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
	check("Charizard card: its Mega Stone icon", stone(c6) != null and badge_text(c6) == "")
	var c382 = menu._dex_card(SV.dex_by[382], true)
	check("Kyogre card: its orb icon", stone(c382) != null)
	var c888 = menu._dex_card(SV.dex_by[888], true)
	check("Zacian card: its rusted sword icon", stone(c888) != null)
	check("every item icon is its own picture (Charizard, Kyogre and Zacian differ)", stone(c6) != stone(c382) and stone(c382) != stone(c888))
	var c386 = menu._dex_card(SV.dex_by[386], true)
	check("Deoxys card: F (forme) badge", badge_text(c386) == "F", badge_text(c386))
	var c25 = menu._dex_card(SV.dex_by[25], true)
	check("Pikachu card: no badge or item", badge_text(c25) == "" and stone(c25) == null, badge_text(c25))
	var c6_locked = menu._dex_card(SV.dex_by[6], false)
	check("not owned (hidden): no badge or item", badge_text(c6_locked) == "" and stone(c6_locked) == null, badge_text(c6_locked))
	SV.d = snap
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
