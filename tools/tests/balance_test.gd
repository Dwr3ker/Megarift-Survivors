extends SceneTree
# Headless balance check: STAB +10%, momentum, speed cap.
func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	SV.run_dex = 6   # Charizard: fire / flying
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	var ok := true
	var e = null
	for i in range(1200):
		await process_frame
		for c in m.enemies:
			if not c.dead and c.shield <= 0.0 and not c.boss:
				e = c
				break
		if e != null:
			break
	if e == null:
		print("no enemy spawned"); quit(1); return
	m.perks["crit"] = 0.0
	var res := {}
	for mt in ["fire", "water"]:
		e.max_hp = 1.0e9; e.hp = 1.0e9
		m._hit_enemy(e, 100.0, Color.WHITE, Vector2.ZERO, 0.0, mt, 0, 0, 0.0)
		res[mt] = (1.0e9 - e.hp) / (100.0 * m._type_mult(mt, e))
	var stab: float = res["fire"] / res["water"]
	print("STAB ratio (own type / other type): %.3f (expect 1.10)" % stab)
	if absf(stab - 1.1) > 0.01: ok = false
	var a0: float = m._atk()
	m.mom = 10.0
	var a1: float = m._atk()
	print("momentum 10 stacks: atk x%.3f (expect 1.200)" % (a1 / a0))
	if absf(a1 / a0 - 1.2) > 0.005: ok = false
	m.mom_t = 3.0
	m._cooldowns(0.5)
	print("after 0.5 s decay past grace: mom=%.1f (expect 7.0)" % m.mom)
	if absf(m.mom - 7.0) > 0.01: ok = false
	m.mom_t = 0.5
	m._cooldowns(0.5)
	print("within grace: mom=%.1f (expect 7.0)" % m.mom)
	if absf(m.mom - 7.0) > 0.01: ok = false
	m.stat_lv["spd"] = 40
	var cap: float = m.base_spd * 2.5
	print("speed with huge sprint: %.1f, cap %.1f" % [m._spd(), cap])
	if m._spd() > cap + 0.01: ok = false
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
