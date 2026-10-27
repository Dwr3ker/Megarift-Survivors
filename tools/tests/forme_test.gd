extends SceneTree
# Headless check: Deoxys Forme Change card (gating, two-step pick, per-forme effects, switching, cooldown).
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

func pick(m, card: Dictionary) -> void:
	m.cards.items = [card]
	m.choosing = true
	m._on_card_chosen(0)

func pick_forme(m, key: String) -> void:
	for i in range(m.cards.items.size()):
		if String(m.cards.items[i]["id"]) == key:
			m._on_card_chosen(i)
			return

func _init() -> void:
	var FM = load("res://scripts/forme.gd")
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	# not offered to others
	var mc = await make_run(SV, 6)
	mc.run_time = 1000.0
	check("Charizard is never offered the Forme card", FM.card(mc).is_empty())
	mc.queue_free()
	await process_frame
	var m = await make_run(SV, 386)
	m.run_time = 200.0
	check("no Forme card before minute 5", FM.card(m).is_empty())
	m.run_time = 400.0
	var c: Dictionary = FM.card(m)
	check("Forme card available after minute 5", not c.is_empty() and String(c["cat"]) == "forme", String(c.get("title", "")))
	var seen := 0
	for i in range(500):
		for x in m._offer():
			if String(x["cat"]) == "forme": seen += 1
	check("shows up in real offers at roughly 12%", seen > 20 and seen < 120, "%d of 500 offers" % seen)
	# baselines
	var atk0: float = m._atk(); var spd0: float = m._spd(); var red0: float = m._reduction()
	var pend0 := 2
	m.pending_levels = pend0
	pick(m, c)
	check("picking the card opens a 3-way choice (still choosing)", m.choosing and m.cards.items.size() == 3 and String(m.cards.items[0]["cat"]) == "formepick", str(m.cards.items.size()))
	check("level-up not consumed until a forme is chosen", m.pending_levels == pend0)
	pick_forme(m, "attack")
	check("Attack Forme: body is 138601, forme set", m.forme == "attack" and m.player.dex == 138601, "%s %d" % [m.forme, m.player.dex])
	check("Attack Forme: damage x1.3 only", absf(m._atk() / atk0 - 1.3) < 0.005 and absf(m._spd() / spd0 - 1.0) < 0.001 and absf(m._reduction() - red0) < 0.001)
	check("choice closed and level consumed", not m.choosing and m.pending_levels == pend0 - 1)
	check("i-frames during the change", m.player.invuln >= 2.7, str(m.player.invuln))
	# cooldown before switching
	check("cannot switch right away (cooldown)", FM.card(m).is_empty())
	m.run_time += 95.0
	var c2: Dictionary = FM.card(m)
	check("can switch after the cooldown", not c2.is_empty())
	pick(m, c2)
	var ids: Array = []
	for x in m.cards.items: ids.append(String(x["id"]))
	check("switch offers only the other two formes", ids.size() == 2 and not ids.has("attack"), str(ids))
	pick_forme(m, "defense")
	check("Defense Forme: body 138602, damage back to x1", m.player.dex == 138602 and absf(m._atk() / atk0 - 1.0) < 0.005, "%d %.3f" % [m.player.dex, m._atk() / atk0])
	check("Defense Forme: damage taken -23%", absf(m._reduction() - red0 - 0.2308) < 0.001, "%.4f" % (m._reduction() - red0))
	m.run_time += 95.0
	pick(m, FM.card(m))
	pick_forme(m, "speed")
	check("Speed Forme: body 138603, speed x1.3, defense bonus gone", m.player.dex == 138603 and absf(m._spd() / spd0 - 1.3) < 0.005 and absf(m._reduction() - red0) < 0.001, "%d spd x%.3f" % [m.player.dex, m._spd() / spd0])
	check("later offers chance is lower after the first change", FM.chance(m) < FM.CHANCE_FIRST)
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
