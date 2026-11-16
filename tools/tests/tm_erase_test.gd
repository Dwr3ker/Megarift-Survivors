extends SceneTree
# Small features step 65: erase a taught TM on the Upgrades screen. It asks first (Cancel keeps it), erasing goes back
# to the Pokémon's own starting move, the TM stays bought (teach another for free), and the controller reaches it.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var menu

func fk(key: String) -> Button:
	for b in menu.screens["up"].find_children("*", "Button", true, false):
		if b.has_meta("fk") and String(b.get_meta("fk")) == key and b.is_visible_in_tree():
			return b
	return null

func settle() -> void:
	for i in range(4):
		await process_frame

func press(a: String) -> void:
	var e := InputEventAction.new()
	e.action = a
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	var r := InputEventAction.new()
	r.action = a
	r.pressed = false
	Input.parse_input_event(r)
	await process_frame
	await process_frame

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.load_dex()
	SV.d = SV.default_data()
	SV.d["nick"] = "Ash"
	SV.add_owned(4)
	SV.d["selected"] = 4
	SV.d["pup"]["4"] = {"tm": 1}
	var own: String = SV.natural_start_of(4)
	var pool: Array = SV.tm_pool(4)
	var other: String = ""
	for id in pool:
		if String(id) != own:
			other = String(id)
			break
	check("nothing taught at first: no Erase button needed", SV.tm_taught(4) == "")
	SV.tm_set(4, other)
	check("teaching a TM changes the starting move", SV.start_move_of(4) == other and SV.tm_taught(4) == other, other)
	menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("up")
	menu.up_dex = 4
	menu.tm_open = true
	menu._refresh_up()
	await settle()
	var eb: Button = fk("tmerase")
	check("the TM panel shows what's taught and an Erase TM button", eb != null and menu.screens["up"].find_children("*", "Label", true, false).any(func(l): return String(l.text).begins_with("Taught: ")))
	eb.pressed.emit()
	await settle()
	check("Erase TM asks first", fk("tmerase_yes") != null and fk("tmerase_no") != null and SV.tm_taught(4) == other)
	check("the question names both moves", menu.screens["up"].find_children("*", "Label", true, false).any(func(l): return String(l.text).begins_with("Erase ") and String(l.text).contains("?")))
	check("focus lands on Cancel (the safe choice)", menu.get_viewport().gui_get_focus_owner() == fk("tmerase_no"))
	await press("ui_left")
	check("Left reaches Erase", menu.get_viewport().gui_get_focus_owner() == fk("tmerase_yes"))
	fk("tmerase_no").pressed.emit()
	await settle()
	check("Cancel keeps the TM", SV.tm_taught(4) == other and fk("tmerase") != null)
	fk("tmerase").pressed.emit()
	await settle()
	fk("tmerase_yes").pressed.emit()
	await settle()
	check("Erase goes back to the Pokémon's own starting move", SV.start_move_of(4) == own and SV.tm_taught(4) == "", SV.start_move_of(4))
	check("the Erase button is gone and the TM is still bought", fk("tmerase") == null and SV.up_level("tm", 4) == 1)
	check("a toast says so", String(menu.toast_lbl.text).contains("TM erased"), menu.toast_lbl.text)
	var b2: Button = fk("tm:" + other)
	b2.pressed.emit()
	await settle()
	check("another TM can be taught again for free", SV.tm_taught(4) == other)
	# controller: from the TM's Choose button, Down reaches Erase TM
	var ch: Button = fk("tmelegir")
	ch.grab_focus()
	await process_frame
	var seen := {}
	var found := false
	for i in range(12):
		await press("ui_down")
		var f = menu.get_viewport().gui_get_focus_owner()
		if f == fk("tmerase"):
			found = true
			break
	check("the controller reaches Erase TM", found)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
