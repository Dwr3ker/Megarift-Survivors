extends SceneTree
# Headless check: the Hyper toggle in the Partida normal screen (save snapshotted and restored).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func hyper_btn(menu) -> Button:
	for c in menu.mp_opts.get_children():
		if c is Button and "yper" in c.text:
			return c
	return null

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var snap: Dictionary = SV.d.duplicate(true)
	SV.d["hyper"] = false
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	menu._modes_select("normal")
	var b: Button = hyper_btn(menu)
	check("Hyper toggle button exists on Partida normal", b != null)
	if b != null:
		check("shows OFF initially", "OFF" in b.text or "NO" in b.text, b.text)
		b.pressed.emit()
		await process_frame
		check("pressing turns Hyper on in the save data", bool(SV.d.get("hyper", false)))
		var b2: Button = hyper_btn(menu)
		check("button now shows ON", b2 != null and ("ON" in b2.text or "SÍ" in b2.text), b2.text if b2 != null else "none")
		check("description mentions Hyper", "yper" in menu.mp_stat.text, menu.mp_stat.text)
	# other modes must not show the toggle
	menu._modes_select("daily")
	check("no Hyper toggle on Daily", hyper_btn(menu) == null)
	SV.d = snap
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
