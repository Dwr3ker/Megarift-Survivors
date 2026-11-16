extends SceneTree
# Wardrobe step 52: an old save loads (free items owned, nothing equipped, Classic frame); equip and read back; only owned
# items of the right kind can be equipped; achievements and medals unlock their items; the gacha roll gives gacha-only items.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var WR = load("res://scripts/wardrobe.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.d.erase("wardrobe")
	check("an old save loads: the free items are owned", WR.owns("sparkle") and WR.owns("glow") and WR.owns("classic"))
	check("nothing equipped, Classic frame", WR.equipped("trail") == "" and WR.equipped("aura") == "" and WR.equipped("frame") == "classic")
	check("18 items, 8 trails, 6 auras, 4 frames", WR.ORDER.size() == 18 and WR.ORDER.filter(func(i): return WR.kind_of(i) == "trail").size() == 8
		and WR.ORDER.filter(func(i): return WR.kind_of(i) == "aura").size() == 6 and WR.ORDER.filter(func(i): return WR.kind_of(i) == "frame").size() == 4)
	check("equip an owned trail", WR.equip("trail", "sparkle") and WR.equipped("trail") == "sparkle")
	check("can't equip an item you don't own", not WR.equip("trail", "flame") and WR.equipped("trail") == "sparkle")
	check("can't equip an item of another kind", not WR.equip("aura", "sparkle"))
	var js: String = JSON.stringify(SV.d)
	SV.d = JSON.parse_string(js)
	check("it reads back after saving", WR.equipped("trail") == "sparkle")
	SV.d["ach"] = {"time10": 1}
	SV.d["medals"] = {"rescue1": {"prog": 1, "got": true, "claimed": false, "set": []}, "alpha": {"prog": 0, "got": false}}
	var got: Array = WR.sync()
	check("achievements and medals unlock their items", got.has("flame") and got.has("bubble") and not WR.owns("leaf"), str(got))
	check("new unlocks are marked new", (WR.data()["new"] as Array).has("flame"))
	check("syncing again unlocks nothing twice", WR.sync().is_empty())
	var g: String = WR.gacha_roll(true)
	check("the gacha roll gives a gacha-only item", ["rainbow", "shadow", "neon"].has(g) and WR.owns(g), g)
	WR.gacha_roll(true)
	WR.gacha_roll(true)
	check("once all three are owned, the gacha gives none", WR.gacha_roll(true) == "")
	check("taking the trail off", WR.equip("trail", "") and WR.equipped("trail") == "")
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
