extends SceneTree
# A region's banner stays shut until the region is unlocked (clear the region before it); Legendary Banners stay open.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.load_dex()
	SV.d = SV.default_data()
	SV.d["nick"] = "Ash"
	SV.d["tickets"] = 200
	check("Kanto is open, Johto is not, on a new save", SV.banner_open(1) and not SV.banner_open(2))
	var p0: int = int(SV.d["stats"]["pulls"])
	check("pulling on a locked region gives nothing", SV.pull(2, 1, "t1").is_empty() and int(SV.d["stats"]["pulls"]) == p0 and int(SV.d["tickets"]) == 200)
	check("pulling on Kanto works", SV.pull(1, 1, "t1").size() == 1)
	check("Legendary Banners are always open", SV.banner_open(SV.BANNER_BASE) and SV.pull(SV.BANNER_BASE, 1, "t1").size() == 1)
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu.gacha_region = 5
	menu._show("gacha")
	for i in range(6):
		await process_frame
	check("opening the Gacha on a locked region moves to the newest open one", menu.gacha_region == 1, str(menu.gacha_region))
	menu.gacha_region = 2
	menu._refresh_gacha()
	await process_frame
	check("a locked banner says how to open it", menu.find_child("BannerLocked", true, false) != null)
	var t0: int = int(SV.d["tickets"])
	menu._do_pull(1, "t1")
	menu._do_max_pull("t1")
	await process_frame
	check("its pull buttons do nothing", int(SV.d["tickets"]) == t0)
	SV.d["region_clear"] = {"1": true}
	check("clearing Kanto opens Johto's banner", SV.banner_open(2) and SV.pull(2, 1, "t1").size() == 1)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
