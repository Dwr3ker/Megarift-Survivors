extends SceneTree
# Headless check of the controller shortcuts in the Pokémon list: the left face button (X / Square / Y) chooses the highlighted
# Pokémon as partner, and Confirm on a text box opens the on-screen keyboard (Confirm or Back closes it).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _pad(menu, b: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = true
	e.device = 0
	menu._input(e)

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var PAD = load("res://scripts/pad.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.load_dex()
	for dx in [25, 26, 150]:
		SV.d["owned"][str(dx)] = {"n": 1, "shiny": false}
	SV.d["selected"] = 26
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(30):
		await process_frame
	for layout in [0, 1, 2]:
		SV.d["settings"]["pad"] = layout
		SV.d["settings"].erase("padmap")
		PAD.apply()
		var lname: String = ["Xbox", "PlayStation", "Nintendo"][layout]
		SV.d["selected"] = 26
		menu.dex_gen = 0
		menu._show("dex")
		for i in range(8):
			await process_frame
		check("%s: the left face button is button index 2 (X / Square / Y)" % lname, JOY_BUTTON_X == 2)
		var card: Button = menu.dex_cards[25]
		card.grab_focus()
		await process_frame
		_pad(menu, JOY_BUTTON_X)
		await process_frame
		check("%s: X on a highlighted Pokémon makes it the partner" % lname, int(SV.d["selected"]) == 25, str(SV.d["selected"]))
		# pressing it on the partner changes nothing
		_pad(menu, JOY_BUTTON_X)
		await process_frame
		check("%s: X on the current partner does nothing" % lname, int(SV.d["selected"]) == 25)
		# an unowned Pokémon cannot be chosen
		if menu.dex_cards.has(27):
			menu.dex_cards[27].grab_focus()
		await process_frame
		_pad(menu, JOY_BUTTON_X)
		await process_frame
		check("%s: an unowned Pokémon cannot be chosen" % lname, int(SV.d["selected"]) == 25)
	# ---------- the search box ----------
	var le: LineEdit = null
	for n in menu.screens["dex"].find_children("*", "LineEdit", true, false):
		le = n
	le.grab_focus()
	await process_frame
	_pad(menu, PAD.btn("confirm"))
	await process_frame
	check("Confirm on the search box opens the keyboard", menu.kb_le == le and le.is_editing())
	_pad(menu, JOY_BUTTON_X)
	await process_frame
	check("X does not choose a partner while the keyboard is open", int(SV.d["selected"]) == 25 and menu.kb_le == le)
	_pad(menu, PAD.btn("cancel"))
	await process_frame
	check("Back closes the keyboard and does not leave the list", menu.kb_le == null and menu.cur == "dex")
	le.grab_focus()
	await process_frame
	_pad(menu, PAD.btn("confirm"))
	await process_frame
	_pad(menu, PAD.btn("confirm"))
	await process_frame
	check("Confirm again closes it", menu.kb_le == null)
	# ---------- the team / co-op pickers keep their own behaviour ----------
	menu.dex_pick_coop = true
	menu._refresh_dex()
	await process_frame
	var cardc: Button = menu.dex_cards[150]
	cardc.grab_focus()
	await process_frame
	var before: int = int(SV.d["selected"])
	_pad(menu, JOY_BUTTON_X)
	await process_frame
	check("in a picker, X does not change the partner", int(SV.d["selected"]) == before)
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
