extends SceneTree
# Telegraphed hazards (lava, strikes, traps, meteorites...) hit through the short invulnerability after a hit or a
# dash, but no longer cancel longer protection: transforming, reviving, entering or leaving a rift. They used to set
# the invulnerability to 0 before hitting.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	while m.cards.open or m.choosing:
		m.cards.hide_cards()
		m.choosing = false
		m.pending_levels = 0
		await process_frame
	for e in m.enemies:
		e.position += Vector2(9000, 9000)
		e.spd = 0.0
	m.player.max_hp = 1000.0
	var cases := [[2.6, false, "transforming (2.6 s)"], [2.5, false, "reviving (2.5 s)"], [1.5, false, "back from a rift (1.5 s)"], [0.45, true, "just hit (0.45 s)"], [0.25, true, "dashing (0.25 s)"], [0.0, true, "no protection"]]
	for c in cases:
		m.player.hp = 1000.0
		m.player.invuln = float(c[0])
		m._hurt_player(100.0, "", false, true)
		var hurt: bool = m.player.hp < 1000.0
		check("a hazard while %s: %s" % [c[2], "hits" if c[1] else "blocked"], hurt == bool(c[1]), "hp %.0f" % m.player.hp)
		if not c[1]:
			check("  and the protection is still there", m.player.invuln >= float(c[0]) - 0.01, "%.2f" % m.player.invuln)
	m.player.hp = 1000.0
	m.player.invuln = 0.3
	m._hurt_player(100.0)
	check("ordinary hits still respect any invulnerability", m.player.hp == 1000.0)
	# a real telegraphed strike landing on you right after a transformation
	m.player.hp = 1000.0
	m.player.invuln = 2.6
	m._hazard_zone(m.player.position, 80.0, 0.2, 150.0, "fire", Color.RED)
	await create_timer(0.6).timeout
	check("a real strike doesn't cut a transformation's protection short", m.player.hp == 1000.0 and m.player.invuln > 1.5, "hp %.0f invuln %.2f" % [m.player.hp, m.player.invuln])
	m.player.invuln = 0.0
	m._hazard_zone(m.player.position, 80.0, 0.2, 150.0, "fire", Color.RED)
	await create_timer(0.6).timeout
	check("without protection the strike still hits", m.player.hp < 1000.0, "hp %.0f" % m.player.hp)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
