extends SceneTree
# Headless check of the second late boss (Mega Calamity): schedule, spawn, attacks, phases, reward, no repeats.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var CAL = load("res://scripts/calamity.gd")
	var SV = load("res://scripts/save_data.gd")
	var PG = load("res://scripts/progress.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)   # the real save is restored at the end (runs write to it)
	SV.d = SV.default_data()   # tests start from a clean profile, whatever save the player has
	# ---------- schedule ----------
	check("15 min before the next Eternatus (minute 75 for the minute-90 one)", CAL.due_at(5400.0, 3600.0) == 4500.0, str(CAL.due_at(5400.0, 3600.0)))
	check("never sooner than 8 min after the last Eternatus", CAL.due_at(5400.0, 4300.0) == 4780.0, str(CAL.due_at(5400.0, 4300.0)))
	check("skipped when it would land within 2 min of the next Eternatus", CAL.due_at(5400.0, 5000.0) < 0.0)
	# ---------- a real run ----------
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true   # keep the director (rifts, arena threads, an Eternatus) out of the hand-driven checks
	m.rift_check = 1.0e9
	m.jd.done = true
	var pool: Array = CAL.pool(m)
	check("the pool has Mega/Primal/Crowned legendaries with sprites", pool.size() >= 3, str(pool.size()))
	m.player.max_hp = 1000.0
	m.player.hp = 1000.0
	m.eter_at = 5400.0
	m.eter_last = 3600.0
	m.run_time = 4500.0
	m.eter_kills = 0
	m._update_calamity(0.1)
	check("no Calamity before the first Eternatus is beaten", m.cal == null)
	m.eter_kills = 1
	m.run_time = 4400.0
	m._update_calamity(0.1)
	check("none before its time", m.cal == null)
	m.run_time = 4500.0
	m._update_calamity(0.1)
	check("it arrives at minute 75", m.cal != null and m.cal_for == 5400.0)
	var c = m.cal
	var b = c.boss
	check("it is a boss flagged 'calamity' wearing a Mega/Primal/Crowned body", b.boss and b.has_meta("enc") and String(b.get_meta("enc")) == "calamity" and b.dex >= 100000, "%s dex %d" % [b.enemy_name, b.dex])
	check("it counts as a boss alive (the horde backs off)", m._boss_alive())
	check("its HP is sturdy but below Eternatus", b.max_hp > 20000.0 and b.max_hp < m.ETX.boss_hp(4500.0) * 0.6, "%.0f vs Eternatus %.0f" % [b.max_hp, m.ETX.boss_hp(4500.0)])
	var first_dex: int = int(b.base_dex)
	m._update_calamity(0.1)
	check("only one per cycle", m.cal == c)
	# ---------- attacks ----------
	m.player.position = b.position + Vector2(400.0, 0.0)
	var z0: int = m.hazards.size()
	c.stomp_cd = 0.0
	c.barrage_cd = 999.0
	c.tick(0.016)
	check("Stomp: one telegraphed zone of 25% max HP on the boss", m.hazards.size() == z0 + 1 and absf(m.hazards[m.hazards.size() - 1].pct - 0.25) < 0.001 and c.stats["stomps"] == 1)
	z0 = m.hazards.size()
	c.stomp_cd = 999.0
	c.barrage_cd = 0.0
	c.tick(0.016)
	var bz: int = m.hazards.size() - z0
	check("Barrage: 3 zones of 20% near the player (phase 1, Doom 1)", bz == 3 and absf(m.hazards[m.hazards.size() - 1].pct - 0.2) < 0.001, str(bz))
	var cad1: float = c.cadence()
	b.hp = b.max_hp * 0.4
	c.tick(0.016)
	check("it enrages at 50% HP and acts 40% faster", c.phase == 2 and absf(c.cadence() / cad1 - 1.4) < 0.01, "%d %.2f" % [c.phase, c.cadence() / cad1])
	m.eter_kills = 3
	check("every Doom level makes it 15% faster", absf(c.cadence() - 1.45 * 1.4) < 0.01, str(c.cadence()))
	m.eter_kills = 1
	# ---------- zone damage is a percentage of max HP ----------
	m.player.hp = 1000.0
	m.player.invuln = 0.0
	m.player.position = b.position
	var dmg_keep: float = b.dmg
	b.dmg = 0.0   # isolate the zone from the boss's contact damage
	var hz = m._hazard_zone(b.position, 150.0, 0.0, 0.0, "rock", Color.WHITE)
	hz.pct = 0.25
	for i in range(40):
		await process_frame
		if hz.hit:
			break
	b.dmg = dmg_keep
	check("a Stomp that connects costs 25% of max HP", hz.hit and absf((1000.0 - m.player.hp) - 250.0) <= 2.0, "hp %.0f hit=%s" % [m.player.hp, str(hz.hit)])
	# ---------- reward ----------
	m.player.hp = 1000.0
	m.player.position = b.position + Vector2(500.0, 0.0)
	var o0: int = m.orbs.size()
	var k0: int = int(SV.d["stats"].get("calamityKills", 0))
	m._damage_enemy(b, b.max_hp * 2.0)
	for i in range(4):
		await process_frame
	var tk := 0
	var t10 := 0
	for o in m.orbs:
		if is_instance_valid(o) and o.kind == "ticket":
			tk += 1
		if is_instance_valid(o) and o.kind == "ticket10":
			t10 += 1
	check("killing it drops 4 tickets, a x10 ticket and counts as a Calamity kill", tk >= 4 and t10 >= 1 and int(SV.d["stats"].get("calamityKills", 0)) == k0 + 1, "tickets %d x10 %d" % [tk, t10])
	check("the controller is released after the kill", m.cal == null)
	check("the same legendary is not used twice", m.cal_used.has(first_dex))
	# ---------- next cycle ----------
	m.eter_at = 7200.0
	m.eter_last = 5400.0
	m.run_time = 6300.0
	m._update_calamity(0.1)
	check("the next cycle spawns a different legendary", m.cal != null and int(m.cal.boss.base_dex) != first_dex and m.cal_for == 7200.0)
	m.cal.boss.dead = true
	# ---------- achievements ----------
	var found := false
	for a in PG.list():
		if String(a["id"]) == "cal1":
			found = true
	check("the Calamity achievement exists", found)
	print("RESULT: ", "PASS" if ok else "FAIL")
	SV.d = _guard
	SV.save()
	quit(0 if ok else 1)
