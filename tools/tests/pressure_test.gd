extends SceneTree
# Late-run Pressure (docs/late_challenge.md): when regular enemies die almost as soon as they appear, p rises and new
# spawns come faster, more at once and tougher; slow kills or heavy damage bring it back down. Only in Normal runs with
# Adaptive difficulty on, from minute 5, outside rifts.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var m
var SV

func kills(n: int, life: float) -> void:
	for i in range(n):
		var e = m._spawn_one(randf() * TAU)
		if e == null:
			continue
		e.born = m.run_time - life
		m.pressure.note_kill(e)
		e.dead = true
		e.queue_free()
		m.enemies.erase(e)

func tick(secs: int) -> void:
	for i in range(secs):
		m.pressure.update(1.0)

func _init() -> void:
	Engine.set_meta("no_save", true)
	SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	SV.d["owned"]["150"] = {"n": 1, "shiny": false}
	SV.run_dex = 150
	SV.run_mode = "normal"
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	m.set_process(false)   # the test drives the clock
	var pr = m.pressure
	m.run_time = 200.0
	kills(30, 0.5)
	tick(30)
	check("nothing before minute 5", pr.p == 0.0)
	m.run_time = 600.0
	kills(30, 1.0)
	tick(33)
	check("enemies dying at once: p rises (about 1 in 33 s)", absf(pr.p - 1.0) < 0.05, "%.2f" % pr.p)
	check("spawn rate x2, surges x1.5", absf(pr.spawn_k() - 2.0) < 0.1 and absf(pr.surge_k() - 1.5) < 0.05)
	m.quality = 1
	check("16 more enemies alive at p = 1", m._cap() == 64 + 16, str(m._cap()))
	check("tougher: HP x2.5, damage x1.2, elites +10%", absf(pr.hp_k() - 2.5) < 0.1 and absf(pr.dmg_k() - 1.2) < 0.02 and absf(pr.elite_add() - 0.1) < 0.01)
	tick(34)
	check("at p = 2: 96 alive", m._cap() == 96, str(m._cap()))
	tick(200)
	check("it stops at 5 (HP x8.5, damage x2)", pr.p == 5.0 and absf(pr.hp_k() - 8.5) < 0.01 and absf(pr.dmg_k() - 2.0) < 0.01)
	check("never more than 32 extra", m._cap() == 96, str(m._cap()))
	m.quality = 3
	check("Effects quality Low: at most 16 extra", m._cap() == 80, str(m._cap()))
	m.quality = 1
	# new spawns really get the HP
	pr.p = 0.0
	seed(42)
	var e0 = m._spawn_one(1.0)
	var h0: float = e0.max_hp
	pr.p = 1.0
	seed(42)
	var e1 = m._spawn_one(1.0)
	var r: float = e1.max_hp / h0
	check("a new enemy has 2.5x HP at p = 1 (5.5x if it rolled elite)", absf(r - 2.5) < 0.05 or absf(r - 5.5) < 0.1, "%.2f" % r)
	# backs off
	pr.p = 1.0
	pr.lives.clear()
	kills(30, 12.0)
	tick(10)
	check("slow kills: p falls", pr.p < 0.6, "%.2f" % pr.p)
	pr.p = 1.0
	pr.lives.clear()
	kills(30, 1.0)
	m.player.hp = m.player.max_hp
	m.player.invuln = 0.0
	m._hurt_player(m.player.max_hp * 0.5 / maxf(0.2, 1.0 - m._reduction()), "", true)
	m.player.hp = m.player.max_hp   # healed back at once: the hit still counts
	tick(5)
	check("taking a big hit (even if healed at once): p falls", pr.p < 1.0, "%.2f" % pr.p)
	m.player.invuln = 1.0e9
	m.player.hp = m.player.max_hp
	# the screen full and you barely take damage: rises even if enemies live long
	pr.p = 0.0
	pr.lives.clear()
	kills(30, 12.0)
	pr.hurt.clear()
	pr.since = 0.0
	while m.enemies.size() < int(m._cap() * 0.9):
		m._spawn_one(randf() * TAU)
	tick(19)
	check("not before the 20-s window has filled", pr.p == 0.0)
	for i in range(31):   # the spawner keeps the screen full as the limit grows
		while m.enemies.size() < int(m._cap() * 0.9):
			m._spawn_one(randf() * TAU)
		tick(1)
	check("full screen, barely touched: p rises", pr.p > 0.5, "%.2f" % pr.p)
	# off
	pr.p = 1.0
	m.arena = Node2D.new()
	tick(5)
	check("inside a rift it waits", pr.p == 1.0)
	m.arena.free()
	m.arena = null
	SV.d["settings"]["adaptive"] = false
	tick(1)
	check("Adaptive difficulty off: none", pr.p == 0.0 and m._cap() == 64)
	SV.d["settings"]["adaptive"] = true
	pr.p = 1.0
	m.mode = "team"
	tick(1)
	check("other modes: none", pr.p == 0.0)
	m.mode = "normal"
	m.queue_free()
	for i in range(3):
		await process_frame
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
