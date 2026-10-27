extends SceneTree
# Headless check: Mega rift curve and a Mega Rayquaza rift boss (stats, body, base dex kept for records).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	var MG = load("res://scripts/mega.gd")
	check("no mega rifts before minute 15", MG.rift_chance(14.9) == 0.0)
	check("5% at minute 15", absf(MG.rift_chance(15.0) - 0.05) < 1e-6)
	check("10% at minute 22.5", absf(MG.rift_chance(22.5) - 0.10) < 1e-6, str(MG.rift_chance(22.5)))
	check("15% at minute 30", absf(MG.rift_chance(30.0) - 0.15) < 1e-6)
	check("30% at minute 60", absf(MG.rift_chance(60.0) - 0.30) < 1e-6)
	check("capped after 60", absf(MG.rift_chance(120.0) - 0.30) < 1e-6)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	SV.run_dex = 6
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	m.run_time = 2000.0
	# pool: capable legendaries only when asked
	var capable_ok := true
	for i in range(60):
		var p: Dictionary = m._pick_legend(true)
		if not MG.is_capable(int(p["dex"])): capable_ok = false
	check("capable-only legend pick always capable", capable_ok)
	# baseline boss (normal rift) vs mega boss for Rayquaza (dex 384)
	var res := {}
	for mega in [false, true]:
		m._open_rift(384, false)
		m.rift_info["mega"] = mega
		m._arena_begin()
		var b = m.ainfo["boss"]
		res[mega] = {"hp": b.max_hp, "dmg": b.dmg, "xp": b.xp_val, "dex": b.dex, "base": b.base_dex, "name": b.enemy_name}
		m._arena_end(false)
		await process_frame
	check("normal boss keeps base body", int(res[false]["dex"]) == 384 and int(res[false]["base"]) == 0, str(res[false]))
	check("mega boss uses form sprite id", int(res[true]["dex"]) == 138401, str(res[true]))
	check("mega boss remembers base dex", int(res[true]["base"]) == 384)
	check("mega boss name", String(res[true]["name"]) == "Mega Rayquaza")
	check("mega boss HP x1.3", absf(float(res[true]["hp"]) / float(res[false]["hp"]) - 1.3) < 0.01, "%.3f" % (float(res[true]["hp"]) / float(res[false]["hp"])))
	check("mega boss damage x1.2", absf(float(res[true]["dmg"]) / float(res[false]["dmg"]) - 1.2) < 0.01)
	check("mega boss xp x1.2", absf(float(res[true]["xp"]) / float(res[false]["xp"]) - 1.2) < 0.01)
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
