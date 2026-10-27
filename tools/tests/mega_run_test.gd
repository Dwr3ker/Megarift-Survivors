extends SceneTree
# Headless run test: Charizard run, jump to minute 31, take the mega card, check multipliers/body/type/Z.
func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	SV.run_dex = 6
	var packed: PackedScene = load("res://scenes/main.tscn")
	var m = packed.instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	var ok := true
	var atk0: float = m._atk(); var spd0: float = m._spd(); var cd0: float = m._cd_mul(); var hp0: float = m.player.max_hp
	var z0: String = m.z_type
	print("before: dex=%d hp=%.0f types=%s z=%s" % [m.player.dex, hp0, str(m.player.types), z0])
	m.run_time = 1900.0
	var MG = load("res://scripts/mega.gd")
	var c: Dictionary = MG.card(m)
	print("card: ", c.get("title", "NONE"), " | ", c.get("desc", ""))
	if c.is_empty(): ok = false
	var cnt := 0
	for i in range(400):
		for pk in m._offer():
			if String(pk["cat"]) == "mega": cnt += 1
	print("mega card in %d of 400 offers (expect ~48 at 12%%)" % cnt)
	m._mega_start()
	await process_frame
	var r_atk: float = m._atk() / atk0; var r_spd: float = m._spd() / spd0; var r_cd: float = m._cd_mul() / cd0; var r_hp: float = m.player.max_hp / hp0
	print("after: dex=%d hp ratio=%.2f atk=%.2f spd=%.2f cd=%.2f types=%s z='%s' invuln=%.1f" % [m.player.dex, r_hp, r_atk, r_spd, r_cd, str(m.player.types), m.z_type, m.player.invuln])
	if m.player.dex != 100601 or absf(r_atk - 1.3) > 0.01 or absf(r_spd - 1.1) > 0.01 or absf(r_cd - 0.9) > 0.01 or absf(r_hp - 1.3) > 0.01 or m.z_type != "": ok = false
	print("second card offered after mega: ", not MG.card(m).is_empty(), " (expect false)")
	for i in range(30): await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
