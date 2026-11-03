extends SceneTree
# Legendary Banners: 3 a week (same for everyone, new on Monday 00:00 Puerto Rico time), the featured legendary is the
# banner's only legendary, banner pity (1.5% up to pull 40, +5% a pull after, pull 60 guaranteed) is shared and kept,
# and a banner closes once its legendary is pulled. Also checks the page builds.
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
	# ---------- week ----------
	var mon := 1793592000   # 2026-11-02 04:00 UTC = Monday 00:00 in Puerto Rico
	check("the week turns over on Monday 00:00 Puerto Rico time", SV.week_id(mon) == SV.week_id(mon - 1) + 1 and SV.week_id(mon) == SV.week_id(mon + 6 * 86400 + 86399))
	check("time left reaches the next Monday", SV.week_left(mon) == 7 * 86400 and SV.week_left(mon + 86400) == 6 * 86400)
	var w: int = SV.week_id()
	var b: Array = SV.banner_dexes(w)
	var gens := {}
	var all_leg := true
	for dx in b:
		gens[int(SV.dex_by[dx]["gen"])] = true
		all_leg = all_leg and bool(SV.dex_by[dx].get("leg", false))
	check("3 featured legendaries a week, from 3 different generations", b.size() == 3 and gens.size() == 3 and all_leg, str(b))
	check("everyone gets the same banners (the week decides them)", SV.banner_dexes(w) == b)
	var changes := 0
	for k in range(1, 9):
		if SV.banner_dexes(w + k) != SV.banner_dexes(w + k - 1):
			changes += 1
	check("the banners change from week to week", changes >= 7)
	# ---------- pity ----------
	var br: int = SV.BANNER_BASE
	var feat: int = SV.banner_dex(br)
	var greg: int = SV.banner_region(br)
	check("a banner draws from its legendary's region", greg == int(SV.dex_by[feat]["gen"]))
	var runs := 1500
	var total := 0
	var worst := 0
	var other_leg := false
	var off_region := false
	for r in range(runs):
		SV.d["banners_claimed"] = {}
		SV.d["bpity"] = 0
		SV.d["tickets"] = 1000
		var n := 0
		while true:
			var got: Array = SV.pull(br, 1, "t1")
			n += 1
			var res: Dictionary = got[0]
			if int(SV.dex_by[int(res["dex"])]["gen"]) != greg:
				off_region = true
			if int(res["rarity"]) == 5:
				if int(res["dex"]) != feat:
					other_leg = true
				break
		total += n
		worst = maxi(worst, n)
	var avg: float = float(total) / float(runs)
	check("the featured legendary is always guaranteed by pull %d" % SV.BANNER_HARD, worst <= SV.BANNER_HARD, "worst %d" % worst)
	check("on average it takes about 30-36 pulls (a region averages about 50 for any legendary)", avg > 28.0 and avg < 38.0, "average %.1f" % avg)
	check("the banner's only legendary is the featured one", not other_leg)
	check("everything else comes from its region", not off_region)
	# ---------- closing, sharing, region pity ----------
	SV.d["banners_claimed"] = {}
	SV.d["bpity"] = 0
	SV.d["tickets"] = 1000
	SV.d["pity"] = {}
	while not SV.banner_claimed(br):
		SV.pull(br, 1, "t1")
	var t0: int = int(SV.d["tickets"])
	check("once claimed the banner closes (no pull, no ticket spent)", SV.pull(br, 1, "t1").is_empty() and int(SV.d["tickets"]) == t0)
	check("banner pulls never touch the region's own pity", int(SV.d["pity"].get(str(greg), 0)) == 0)
	SV.d["bpity"] = SV.BANNER_HARD - 1
	var g2: Array = SV.pull(SV.BANNER_BASE + 1, 1, "t1")
	check("pity is shared: pull 60 on another banner is its legendary", int(g2[0]["rarity"]) == 5 and int(g2[0]["dex"]) == SV.banner_dex(SV.BANNER_BASE + 1) and int(SV.d["bpity"]) == 0)
	SV.d["bpity"] = SV.BANNER_HARD - 1
	var g3: Array = SV.pull(SV.BANNER_BASE + 2, 10, "t1")
	var legs := 0
	for r in g3:
		if int(r["rarity"]) == 5 and int(r["dex"]) == SV.banner_dex(SV.BANNER_BASE + 2):
			legs += 1
	check("a ×10 that claims the banner still gives all 10 Pokémon", g3.size() == 10 and legs >= 1 and SV.banner_claimed(SV.BANNER_BASE + 2))
	check("a closed banner stays closed only for this week", not bool(SV.d["banners_claimed"].has("%d_%d" % [w + 1, SV.banner_dex(br)])))
	# ---------- page ----------
	SV.d = SV.default_data()
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	menu.gacha_region = SV.BANNER_BASE
	menu._show("gacha")
	for i in range(4):
		await process_frame
	var txt := ""
	for l in menu.gacha_box.find_children("*", "Label", true, false):
		txt += (l as Label).text + "\n"
	check("the banner page shows the featured legendary and its pity", txt.contains(L_name(SV, feat)) and txt.contains("/ %d" % SV.BANNER_HARD))
	var rail := ""
	for c in menu.gacha_rail.get_children():
		if c is Button:
			rail += (c as Button).text + "|"
	check("the rail lists the 3 banners before the regions", rail.begins_with("★ "), rail.substr(0, 80))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func L_name(SV, dx: int) -> String:
	return String(SV.dex_by[dx]["name"])
