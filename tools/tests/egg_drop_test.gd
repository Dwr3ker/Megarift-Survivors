extends SceneTree
# Eggs step 21: eggs drop in runs (boss / Alpha / rescue), at most 2 a run, never past a full bag; walking over one picks
# it up ("Egg found!"); eggs picked up go to the bag when the run ends; the contents follow the rules (first stage,
# not legendary, rarity 1-4, from the map's region).
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var EG = load("res://scripts/eggs.gd")
	var EVL = load("res://scripts/evolution.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(30):
		await process_frame
	m.player.invuln = 1.0e9
	var o = m._egg_try("boss", m.player.position + Vector2(300, 0), true)
	check("a forced drop makes an egg on the ground", o != null and o.kind == "egg" and m.orbs.has(o))
	var eg: Dictionary = m.egg_pend.get(int(o.value), {}) if o != null else {}
	check("the egg's contents are decided at the drop", not eg.is_empty() and int(eg["dex"]) > 0)
	var p: Dictionary = SV.dex_by.get(int(eg.get("dex", 0)), {})
	check("first stage, not legendary, rarity 1-4", EVL.stage_of(int(eg["dex"])) == 1 and not bool(p.get("leg", false)) and int(p.get("rarity", 9)) <= 4,
		"dex %d rarity %d" % [int(eg["dex"]), int(p.get("rarity", 9))])
	check("its look follows the first type", String(eg["look"]) == EG.look_of(String(p["types"][0])), String(eg["look"]))
	o.position = m.player.position
	for i in range(3):
		await process_frame
	check("walking over it picks it up", m.eggs_run.size() == 1 and m.egg_pend.is_empty() and not m.orbs.has(o))
	check("not in the bag before the run ends", EG.count() == 0)
	var o2 = m._egg_try("rescue", m.player.position + Vector2(300, 0), true)
	var o3 = m._egg_try("alpha", m.player.position + Vector2(300, 0), true)
	check("at most 2 eggs a run", o2 != null and o3 == null, str(m.egg_drops))
	# chance: with the per-run cap lifted, about 15% of boss rolls drop
	var hits := 0
	for i in range(2000):
		m.egg_drops = 0
		m.egg_pend.clear()
		if m._egg_try("boss", Vector2.ZERO) != null:
			hits += 1
	check("bosses drop an egg about 15% of the time", hits > 220 and hits < 380, "%d / 2000" % hits)
	for x in m.orbs.duplicate():
		if x.kind == "egg":
			m.orbs.erase(x)
			x.queue_free()
	m.egg_pend.clear()
	# region maps: the egg comes from the map's region
	m.region = 3
	var same := 0
	for i in range(40):
		var sp: Dictionary = m._egg_species()
		if int(sp.get("gen", 0)) == 3:
			same += 1
	check("on a region map the Pokémon comes from that region", same == 40, "%d / 40" % same)
	m.region = 0
	# a full bag stops drops
	m.egg_drops = 0
	for i in range(EG.MAX_EGGS):
		SV.d["eggs"].append(EG.make(1, 1, "grass"))
	check("a full bag gets no egg", m._egg_try("boss", Vector2.ZERO, true) == null)
	SV.d["eggs"] = []
	# the run ends: the picked-up egg goes into the bag (and into an incubator slot)
	m._finish_run()
	check("at run end the egg is in the bag", EG.count() == 1 and int(EG.eggs()[0]["id"]) == int(eg["id"]), str(EG.count()))
	check("it went into a free incubator slot", int(EG.eggs()[0]["slot"]) == 0)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
