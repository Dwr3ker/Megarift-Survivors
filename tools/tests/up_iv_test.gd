extends SceneTree
# Upgrades screen: Train IVs and Change nature work for the Pokémon picked there, like in the Pokémon list.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var IVS = load("res://scripts/ivs.gd")
	SV.ensure()
	SV.load_dex()
	SV.d = SV.default_data()
	SV.d["nick"] = "Ash"
	SV.d["coins"] = 99999
	SV.add_owned(6)
	SV.add_owned(25)
	SV.d["selected"] = 25
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("up")
	menu.up_dex = 6   # a Pokémon that is not the partner
	menu._refresh_up()
	for i in range(4):
		await process_frame
	var biv: Button = menu.screens["up"].find_child("UpTrainIVs", true, false)
	var bnat: Button = menu.screens["up"].find_child("UpNature", true, false)
	check("the Upgrades screen has Train IVs and Change nature", biv != null and bnat != null)
	IVS.info(6)
	var iv0: Array = (IVS.info(6)["iv"] as Array).duplicate()
	var c0: int = int(SV.d["coins"])
	biv.pressed.emit()
	await process_frame
	check("Train IVs opens the vitamin panel", menu.gacha_result.visible)
	var vit: Button = null
	for b in menu.gacha_result.find_children("*", "Button", true, false):
		if not (b as Button).disabled and (b as Button).text.contains("→"):
			vit = b
			break
	var vit_ok: bool = vit != null
	if vit_ok:
		vit.pressed.emit()   # the panel rebuilds itself, so this button is gone afterwards
		await process_frame
	var iv1: Array = IVS.info(6)["iv"]
	check("a vitamin raises one of that Pokémon's IVs", vit_ok and (int(iv1[0]) + int(iv1[1]) + int(iv1[2])) > (int(iv0[0]) + int(iv0[1]) + int(iv0[2])), "%s -> %s" % [iv0, iv1])
	check("the Upgrades screen stays on that Pokémon", menu.cur == "up" and menu.up_dex == 6)
	menu._iv_close("iv")
	await process_frame
	check("closing the panel returns to the Train IVs button", not menu.gacha_result.visible and menu.get_viewport().gui_get_focus_owner() != null and String(menu.get_viewport().gui_get_focus_owner().name) == "UpTrainIVs")
	var n0: String = String(IVS.info(6)["nat"])
	(menu.screens["up"].find_child("UpNature", true, false) as Button).pressed.emit()
	await process_frame
	var pickn: Button = null
	for b in menu.gacha_result.find_children("*", "Button", true, false):
		if not (b as Button).disabled and (b as Button).text.contains("\n"):
			pickn = b
			break
	var pick_ok: bool = pickn != null
	if pick_ok:
		pickn.pressed.emit()
		await process_frame
	check("Change nature sets a new nature for that Pokémon", pick_ok and String(IVS.info(6)["nat"]) != n0, "%s -> %s" % [n0, String(IVS.info(6)["nat"])])
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
