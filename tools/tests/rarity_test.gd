extends SceneTree
# Headless check for rarity-tier stat cards (odds, bonus maths, card pick, caps).
var ok := true

func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	var RAR = load("res://scripts/rarity.gd")
	# 1. odds per minute
	for mn in [0.0, 10.0, 20.0, 40.0]:
		var w: Array = RAR.weights(mn)
		var cnt := [0, 0, 0, 0]
		var N := 40000
		for i in range(N):
			cnt[RAR.roll(mn)] += 1
		var worst := 0.0
		for t in range(4):
			worst = maxf(worst, absf(float(cnt[t]) / N * 100.0 - float(w[t])))
		check("odds at minute %d" % int(mn), worst < 1.0, "table=%s observed=%s worst dev %.2f pts" % [str(w), str(cnt), worst])
	# 2. bonus maths
	check("atk common = +10%", absf(RAR.value("atk", 1.0) - 10.0) < 0.001)
	check("atk legendary = +21%", absf(RAR.value("atk", 2.0) - 21.0) < 0.001)
	check("hp epic = +30", absf(RAR.value("hp", 1.5) - 30.0) < 0.001)
	check("cd rare ~ -10.0%", absf(RAR.value("cd", 1.25) - 9.9) < 0.1, str(RAR.value("cd", 1.25)))
	# 3. description rewriting keeps wording and decimal separator
	check("desc en", RAR.desc("+10% damage with all moves.", "atk", 2.0) == "+21% damage with all moves.", RAR.desc("+10% damage with all moves.", "atk", 2.0))
	check("desc fr decimal comma", RAR.desc("+0,9 de vie régénérée par seconde.", "rgn", 2.0) == "+1,8 de vie régénérée par seconde.", RAR.desc("+0,9 de vie régénérée par seconde.", "rgn", 2.0))
	# 4/5/6. in a real run
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	SV.run_dex = 6
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	m.run_time = 2400.0
	var seen := [0, 0, 0, 0]
	var bad_tag := 0
	var bad_legend := 0
	var stat_cards := 0
	for i in range(600):
		for c in m._offer():
			if String(c["cat"]) != "stat" or String(c["id"]) == "heal":
				continue
			stat_cards += 1
			var t: int = int(c.get("tier", 0))
			seen[t] += 1
			if t > 0 and String(c["tag"]) != RAR.NAMES[t]: bad_tag += 1
			if bool(c.get("legend", false)) != (t == 3): bad_legend += 1
	check("in-game offers contain all tiers", seen[1] > 0 and seen[2] > 0 and seen[3] > 0, str(seen))
	check("tier tags/legend flag consistent", bad_tag == 0 and bad_legend == 0)
	# pick a legendary Power card
	var a0: float = m._atk()
	var card := {"cat": "stat", "id": "atk", "mult": 2.0, "tier": 3, "title": "x", "desc": "x", "tag": "x", "color": Color.WHITE, "key": "k", "w": 1.0}
	m.cards.items = [card]
	m.choosing = true
	m._on_card_chosen(0)
	check("legendary Power = 2 levels", absf(m._lvf("atk") - 2.0) < 0.001, str(m._lvf("atk")))
	check("legendary Power damage x1.21", absf(m._atk() / a0 - 1.21) < 0.005, str(m._atk() / a0))
	var hp0: float = m.player.max_hp
	m.cards.items = [{"cat": "stat", "id": "hp", "mult": 1.5, "tier": 2, "title": "x", "desc": "x", "tag": "x", "color": Color.WHITE, "key": "k2", "w": 1.0}]
	m.choosing = true
	m._on_card_chosen(0)
	check("epic Vigor = +30 max HP", absf(m.player.max_hp - hp0 - 30.0) < 0.01, str(m.player.max_hp - hp0))
	# cap: Armor max is 12 levels (no overcap); Power may go to 125% of its 40 (Overcap, doom.gd)
	m.stat_lv["def"] = 11.5
	m.cards.items = [{"cat": "stat", "id": "def", "mult": 2.0, "tier": 3, "title": "x", "desc": "x", "tag": "x", "color": Color.WHITE, "key": "k3", "w": 1.0}]
	m.choosing = true
	m._on_card_chosen(0)
	check("level cap respected", absf(m._lvf("def") - 12.0) < 0.001, str(m._lvf("def")))
	m.stat_lv["atk"] = 49.5
	m.cards.items = [card]
	m.choosing = true
	m._on_card_chosen(0)
	check("Power stops at its overcap ceiling", absf(m._lvf("atk") - 50.0) < 0.001, str(m._lvf("atk")))
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
