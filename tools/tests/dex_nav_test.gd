extends SceneTree
# Headless check of the Pokémon list: the partner is highlighted on opening (even on a later page) and LB / RB step through the regions.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _pad(btn: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	return e

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var PAD = load("res://scripts/pad.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["owned"]["4"] = {"n": 1, "shiny": false}
	SV.d["owned"]["250"] = {"n": 1, "shiny": false}
	SV.d["selected"] = 250
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu.dex_gen = 0
	menu.dex_page = 0
	menu._show("dex")
	for i in range(6):
		await process_frame
	check("the partner's card exists on the opened page", menu.dex_cards.has(250), "page %d" % menu.dex_page)
	var fo: Control = menu.get_viewport().gui_get_focus_owner()
	check("the partner is highlighted when the list opens", fo != null and menu.dex_cards.has(250) and fo == menu.dex_cards[250])
	# the partner is in another region tab: the list falls back to All
	menu._show("main")
	menu.dex_gen = 1
	menu._show("dex")
	for i in range(6):
		await process_frame
	check("a region tab that hides the partner falls back to All", menu.dex_gen == 0 and menu.dex_cards.has(250))
	# LB / RB
	menu._input(_pad(PAD.btn("next")))
	await process_frame
	check("RB goes to the next region", menu.dex_gen == 1)
	menu._input(_pad(PAD.btn("next")))
	await process_frame
	check("RB again goes on (Johto)", menu.dex_gen == 2)
	menu._input(_pad(PAD.btn("prev")))
	menu._input(_pad(PAD.btn("prev")))
	await process_frame
	check("LB goes back to All", menu.dex_gen == 0)
	menu._input(_pad(PAD.btn("prev")))
	await process_frame
	check("LB from All wraps to the last region", menu.dex_gen == 9)
	menu._input(_pad(PAD.btn("next")))
	await process_frame
	check("RB from the last region wraps to All", menu.dex_gen == 0)
	var fo2: Control = menu.get_viewport().gui_get_focus_owner()
	check("focus stays on a card after changing region", fo2 != null and fo2 is Button)
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
