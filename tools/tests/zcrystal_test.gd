extends SceneTree
# Headless check: Z-Crystal level-up card (gating, odds, granting the Z-move for the run, 2-minute cooldown, mega interaction).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func make_run(SV, dex: int):
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	return m

func _init() -> void:
	var ZC = load("res://scripts/zcrystal.gd")
	var ZM = load("res://scripts/zmove.gd")
	var L = load("res://scripts/lang.gd")
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end
	var m = await make_run(SV, 6)
	m.z_type = ""
	m.z_crystal = false
	m.run_time = 800.0
	check("no Z-Crystal card before minute 15", ZC.card(m).is_empty())
	m.run_time = 1000.0
	var c: Dictionary = ZC.card(m)
	check("card after minute 15 for the partner's type", not c.is_empty() and String(c["ztype"]) == "fire" and String(c["icon"]) == "zc:fire", str(c.get("title", "")))
	check("card text names the Z-move", L.t(String(ZM.DEF["fire"]["name"])) in String(c["desc"]), String(c.get("desc", "")))
	var seen := 0
	for i in range(600):
		for x in m._offer():
			if String(x["cat"]) == "zcrystal": seen += 1
	check("shows up in real offers at roughly 10%", seen > 25 and seen < 100, "%d of 600" % seen)
	# gating
	m.z_type = "water"
	check("not offered when you already have a Z-move", ZC.card(m).is_empty())
	m.z_type = ""
	m.mode = "tower"
	check("not offered in Tower", ZC.card(m).is_empty())
	m.mode = "normal"
	m.mega_done = true
	check("not offered after a Mega Evolution", ZC.card(m).is_empty())
	m.mega_done = false
	# pick it through the real card flow
	m.pending_levels = 2
	m.cards.items = [c]
	m.choosing = true
	m._on_card_chosen(0)
	check("picking it grants the Fire Z-move for the run", m.z_type == "fire" and m.z_crystal and not m.z_used, m.z_type)
	check("choice closed and level-up consumed", not m.choosing and m.pending_levels == 1)
	check("the Z-move can be used (button ready)", m._z_can())
	# finish a Z-move: crystal Z recharges in 2 minutes
	m.z_used = true
	m.z_state = "fx"
	m.zfx = null
	m._z_fx(0.1)
	check("crystal Z cooldown is 120 s", absf(m.z_cd - 120.0) < 0.001 and m.z_state == "", str(m.z_cd))
	m._cooldowns(121.0)
	check("ready again after 2 minutes", not m.z_used and m._z_can())
	# a profile-unlocked Z keeps its own 4-minute cooldown
	m.z_crystal = false
	m.z_used = true
	m.z_state = "fx"
	m.zfx = null
	m._z_fx(0.1)
	check("profile-unlocked Z keeps the 240 s cooldown", absf(m.z_cd - 240.0) < 0.001, str(m.z_cd))
	# mega removes the Z-move and the card never comes back
	m.z_crystal = true
	m.z_type = "fire"
	m.run_time = 2000.0
	m._mega_start()
	check("Mega Evolution removes the Z-Crystal", m.z_type == "")
	check("no more Z-Crystal cards after a Mega", ZC.card(m).is_empty())
	SV.d = _guard
	SV.save()
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
