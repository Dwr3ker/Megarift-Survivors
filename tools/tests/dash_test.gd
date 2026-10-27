extends SceneTree
# Headless dash check: distance, once-per-enemy damage, i-frames, cooldown, input paths and blocks.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	SV.run_dex = 6
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	var e = null
	for i in range(1200):
		await process_frame
		for c in m.enemies:
			if not c.dead and c.shield <= 0.0 and not c.boss:
				e = c
				break
		if e != null: break
	if e == null:
		print("no enemy"); quit(1); return
	m.perks["crit"] = 0.0
	m.player.invuln = 0.0
	m.mom = 0.0
	# --- dash to the right with an enemy in the path
	var p0: Vector2 = m.player.position
	m.dash_last = Vector2.RIGHT
	e.max_hp = 1.0e9; e.hp = 1.0e9
	e.position = p0 + Vector2(60.0, 0.0)
	check("can dash at start", m._dash_can())
	m._dash_start()
	check("cooldown set to 3 s", absf(m.dash_cd - 3.0) < 0.001, str(m.dash_cd))
	check("i-frames >= 0.25 s", m.player.invuln >= 0.25 - 0.001, str(m.player.invuln))
	check("cannot dash again during cooldown", not m._dash_can())
	var frames := 0
	while m.dash_left > 0.0 and frames < 60:
		m._update_player(1.0 / 60.0)
		frames += 1
	var moved: float = (m.player.position - p0).length()
	check("distance ~96", absf(moved - 96.0) < 3.0, "moved %.1f in %d frames" % [moved, frames])
	check("direction was right", absf((m.player.position - p0).normalized().dot(Vector2.RIGHT) - 1.0) < 0.05)
	var lost: float = 1.0e9 - e.hp
	var exp: float = 25.0 * (1.0 + 0.05 * float(m.player.level)) * maxf(1.0, m._atk() / m.base_atk) * m._type_mult("normal", e)
	check("enemy hit exactly once for dash damage", absf(lost - exp) < exp * 0.02 + 0.5, "lost %.1f expected %.1f" % [lost, exp])
	m._dash_hit_along(p0, m.player.position)
	check("same dash cannot hit twice", absf((1.0e9 - e.hp) - lost) < 0.001)
	# --- cooldown recovery
	m._cooldowns(3.1)
	check("dash ready after 3 s", m._dash_can())
	# --- input paths
	var ev := InputEventKey.new()
	ev.keycode = KEY_SHIFT
	ev.pressed = true
	m._unhandled_input(ev)
	check("Shift key starts a dash", m.dash_left > 0.0)
	m.dash_left = 0.0; m.dash_cd = 0.0
	var sp := InputEventKey.new()
	sp.keycode = KEY_SPACE
	sp.pressed = true
	m.hud.act_txt = ""
	m._unhandled_input(sp)
	check("Space (no interaction nearby) starts a dash", m.dash_left > 0.0)
	m.dash_left = 0.0; m.dash_cd = 0.0
	m.hud.act_txt = "Abrir"
	m._unhandled_input(sp)
	check("Space with an interaction prompt does not dash", m.dash_left <= 0.0)
	# --- blocks
	m.hud.act_txt = ""
	m.choosing = true
	check("blocked while choosing a card", not m._dash_can())
	m.choosing = false
	m.paused = true
	check("blocked while paused", not m._dash_can())
	m.paused = false
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
