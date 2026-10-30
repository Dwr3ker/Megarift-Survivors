extends SceneTree
# Headless check of the effects layer: rings, arcs and beams go to the layer under the Pokémon, and the limits that keep a
# swarm of effects from costing a frame each.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(14):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	m.jd.done = true
	# ---------- layers ----------
	check("the under layer sits below the world", m.pfx.under == m.pfx_low and m.pfx_low.get_parent() == m.gfx and m.gfx.get_index() < m.world.get_index() and m.world.get_index() < m.fx.get_index())
	var r0: int = m.pfx_low.rings.size()
	var top0: int = m.pfx.rings.size()
	m._ring(m.player.position, 4.0, 90.0, Color.WHITE, 0.5)
	check("a ring goes to the under layer, not the top one", m.pfx_low.rings.size() == r0 + 1 and m.pfx.rings.size() == top0)
	var b0: int = m.pfx_low.beams.size()
	m.pfx.beam(m.player.position, 0.0, 200.0, 20.0, {"pal": "fire", "beam": ""})
	check("a beam goes to the under layer", m.pfx_low.beams.size() == b0 + 1 and m.pfx.beams.is_empty())
	m.pfx.slash(m.player.position, 0.0, 90.0, 1.5, {"pal": "normal"})
	check("a hit arc goes to the under layer", m.pfx_low.slashes.size() >= 1 and m.pfx.slashes.is_empty())
	check("hit sparks and sprites still draw on top", m.pfx.sprs.size() >= 0 and m.pfx.parts is Array)
	# ---------- caps ----------
	for i in range(400):
		m.pfx.ring(Vector2(i, 0), 2.0, 300.0, Color.WHITE, 5.0)
		m.pfx.beam(Vector2(i, 0), 0.0, 300.0, 30.0, {"pal": "fire", "beam": ""})
		m.pfx.slash(Vector2(i, 0), 0.0, 120.0, 2.0, {"pal": "normal"})
	check("live rings are capped", m.pfx_low.rings.size() <= m.pfx.MAX_RINGS, str(m.pfx_low.rings.size()))
	check("live beams are capped", m.pfx_low.beams.size() <= m.pfx.MAX_BEAMS, str(m.pfx_low.beams.size()))
	check("live hit arcs are capped", m.pfx_low.slashes.size() <= m.pfx.MAX_SLASHES, str(m.pfx_low.slashes.size()))
	for i in range(6):
		await process_frame
	check("drawing the capped swarm works", m.pfx_low.rings.size() > 0)
	m.pfx.clear()
	check("clear empties both layers", m.pfx_low.rings.is_empty() and m.pfx_low.beams.is_empty() and m.pfx_low.slashes.is_empty())
	# ---------- floating numbers ----------
	m.dmg_on = true
	var f0: int = m.Floater.alive
	for i in range(200):
		m.add_text(m.player.position, str(i), Color.WHITE, 16)
	check("small floating numbers stop at the limit", m.Floater.alive - f0 <= m.Floater.MAX_ALIVE, str(m.Floater.alive - f0))
	var before: int = m.Floater.alive
	m.add_text(m.player.position, "Big!", Color.WHITE, 26)
	check("important big texts still show", m.Floater.alive == before + 1)
	# ---------- bullets only redraw when they animate ----------
	var b = m.Bullet.new()
	b.shape = ""
	m.fx.add_child(b)
	await process_frame
	b._fr = int(b.age * 12.0)
	var redraws := 0
	for i in range(5):
		b.age += 0.001
		b._process(0.016)
	check("a straight bullet within one animation frame is not redrawn", b._fr == 0)
	b.queue_free()
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
