extends SceneTree
# Headless check: the Hyper toggle in the Partida normal screen (save snapshotted and restored).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func hyper_btn(menu) -> Button:
	# the Hyper switch sits at the end of the difficulty row (steps 43-44)
	var b = menu.mp_opts.find_child("Diff_hyper", true, false)
	return b as Button

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
		var ds = menu.mp_opts.find_child("DiffSummary", true, false)
		check("the summary mentions Hyper", ds != null and "yper" in ds.text, ds.text if ds != null else "none")
	# other modes must not show the toggle
	menu._modes_select("daily")
	check("no Hyper toggle on Daily", hyper_btn(menu) == null)
	SV.d = snap
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
