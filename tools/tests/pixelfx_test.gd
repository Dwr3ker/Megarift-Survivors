extends SceneTree
# pixelfx effects in the game: the sprite sheets load and match their frame data, enemies show the overhead status effect
# for sleep / paralysis / confusion (and nothing otherwise), one-shot effects end on their own, and rare XP (bosses,
# legendaries, Eternatus) is an animated orb that still counts as experience.
const SHX = preload("res://scripts/sheetfx.gd")
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
	# ---------- sheets ----------
	var bad: Array = []
	for id in SHX.META:
		var m: Dictionary = SHX.META[id]
		var tx: Texture2D = SHX.tex(String(id))
		var rows: int = int(ceil(float(m["frames"]) / float(m["cols"])))
		if tx == null or tx.get_width() < int(m["cols"]) * int(m["w"]) or tx.get_height() < rows * int(m["h"]):
			bad.append(id)
	check("every effect sheet loads and holds all its frames", bad.is_empty(), str(bad))
	check("the pixelfx licence ships with the sheets", FileAccess.file_exists("res://assets/fx/pixelfx/LICENSE.txt"))
	# ---------- run ----------
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(20):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.player.invuln = 1.0e9
	var e = m._spawn_one()
	e.hp = 1.0e9
	e.max_hp = 1.0e9
	e.position = m.player.position + Vector2(200, 0)
	check("an enemy without a status has no overhead effect", e.status_over == null)
	e.sleep_t = 3.0
	for i in range(3):
		await process_frame
	check("asleep: the Zzz effect shows above it", e.status_over != null and e.status_over.visible and e.status_over.id == "sleep")
	e.sleep_t = 0.0
	e.para_t = 3.0
	for i in range(2):
		await process_frame
	check("paralysed: circling stars", e.status_over.id == "paralysis" and e.status_over.visible)
	e.para_t = 0.0
	e.conf_t = 3.0
	for i in range(2):
		await process_frame
	check("confused: the spiral", e.status_over.id == "confused" and e.status_over.visible)
	e.conf_t = 0.0
	for i in range(2):
		await process_frame
	check("the effect hides when the status ends", not e.status_over.visible and e.status_over.id == "")
	# ---------- one-shots ----------
	m.pfx.sheet("crit_hit", m.player.position, 1.2)
	var mine: Dictionary = m.pfx.sheets[m.pfx.sheets.size() - 1]
	check("a critical-hit spark starts", String(mine["id"]) == "crit_hit")
	for i in range(int(SHX.duration("crit_hit") * 60.0) + 10):
		m.pfx._process(1.0 / 60.0)   # step the effect layer itself (the run may be paused on a level-up card)
	check("and removes itself when it has played", not m.pfx.sheets.has(mine))   # (the run keeps making its own crits meanwhile)
	for i in range(20):
		m.pfx.sheet("collect_burst", m.player.position, 1.5)
	check("one-shot effects are capped", m.pfx.sheets.size() <= m.pfx.MAX_SHEETS)
	# ---------- rare XP ----------
	var o = m._spawn_orb(m.player.position + Vector2(500, 0), "xpRare", 50.0)
	await process_frame
	check("rare XP is an animated orb (it redraws every frame)", o.is_processing())
	var o2 = m._spawn_orb(m.player.position + Vector2(520, 0), "xpBig", 50.0)
	await process_frame
	check("normal big crystals stay still (no per-frame redraw)", not o2.is_processing())
	var xp0: float = float(m.player.xp) if "xp" in m.player else float(m.xp)
	m._collect("xpRare", 50.0)
	var xp1: float = float(m.player.xp) if "xp" in m.player else float(m.xp)
	check("rare XP still gives experience", xp1 > xp0 or m.player.level > 1, "%s -> %s" % [xp0, xp1])
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
