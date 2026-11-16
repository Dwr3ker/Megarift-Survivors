extends SceneTree
# Wardrobe steps 53, 55, 56 and 59 in a run: the trail follows movement and fades when you stand still; the Effects
# quality setting thins it; the cosmetics layer is under the ground effects (attack warnings), attacks and Pokémon;
# the HUD gets the equipped frame; Team mode works too.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

var SV
var WR

func _run(mode: String, quality: int):
	SV.d["settings"]["quality"] = quality
	SV.run_dex = 4
	SV.run_mode = mode
	SV.run_hyper = false
	SV.run_diff = "normal"
	SV.run_region = 0
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(25):
		await process_frame
	m.player.invuln = 1.0e9
	return m

func _walk(m, n: int) -> void:
	for i in range(n):
		m.player.position += Vector2(6.0, 0.0)
		await process_frame

func _init() -> void:
	Engine.set_meta("no_save", true)
	SV = load("res://scripts/save_data.gd")
	WR = load("res://scripts/wardrobe.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	for d in [4, 7, 1]:
		SV.d["owned"][str(d)] = {"n": 1}
	SV.d["team"] = [4, 7]
	for id in WR.ORDER:
		WR.unlock(id)
	WR.equip("trail", "flame")
	WR.equip("aura", "ripple")
	WR.equip("frame", "gold")
	var m = await _run("normal", 0)
	check("the run reads the equipped trail and aura", m.cos_fx.trail == "flame" and m.cos_fx.aura == "ripple")
	check("the HUD gets the equipped frame", m.hud.frame_style == "gold")
	var kids: Array = m.get_children()
	check("the cosmetics layer is right above the ground, under the warnings, attacks and Pokémon",
		kids.find(m.cos_fx) == kids.find(m.ground) + 1 and kids.find(m.cos_fx) < kids.find(m.gfx) and kids.find(m.cos_fx) < kids.find(m.mfx) and kids.find(m.cos_fx) < kids.find(m.world))
	m.cos_fx.spawned = 0
	await _walk(m, 50)   # 300 px
	var high: int = m.cos_fx.spawned
	check("moving drops a trail (about one particle per 14 px)", high >= 18 and high <= 24, str(high))
	check("particles are on screen", not m.cos_fx.bits.is_empty())
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1300:
		await process_frame
	check("standing still, the trail fades away", m.cos_fx.bits.is_empty(), str(m.cos_fx.bits.size()))
	m.queue_free()
	await process_frame
	var m2 = await _run("normal", 3)
	m2.cos_fx.spawned = 0
	await _walk(m2, 50)
	check("Effects quality Low thins the trail out (about a third)", m2.cos_fx.spawned < high * 0.5 and m2.cos_fx.spawned > 0, "%d vs %d" % [m2.cos_fx.spawned, high])
	m2.queue_free()
	await process_frame
	# nothing equipped: no layer work at all
	WR.equip("trail", "")
	WR.equip("aura", "")
	var m3 = await _run("normal", 0)
	await _walk(m3, 20)
	check("nothing equipped: no particles", m3.cos_fx.bits.is_empty() and m3.cos_fx.trail == "")
	m3.queue_free()
	await process_frame
	# Team mode: the cosmetics follow whichever Pokémon you control
	WR.equip("trail", "star")
	var m4 = await _run("team", 0)
	await _walk(m4, 20)
	var before: int = m4.cos_fx.spawned
	var dex0: int = int(m4._cur_dex())
	m4._swap_team(1)
	for i in range(10):
		await process_frame
	check("Team mode: the swap happened", int(m4._cur_dex()) != dex0, "%d -> %d" % [dex0, int(m4._cur_dex())])
	await _walk(m4, 20)
	check("Team mode: the trail keeps following the Pokémon you control", m4.cos_fx.spawned > before and m4.cos_fx.trail == "star", "%d -> %d" % [before, m4.cos_fx.spawned])
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
