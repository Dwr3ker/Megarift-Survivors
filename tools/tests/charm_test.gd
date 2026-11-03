extends SceneTree
# Shiny Charm: owning every Pokemon of a region earns that region's charm, which only boosts that region: wild shinies x3,
# its rift legendaries x2 and +1% on its gacha (banners drawing from it too). Announced once.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.load_dex()
	SV.d = SV.default_data()
	SV.d["owned"] = {}
	check("no charm before the region is complete", not SV.shiny_charm(1) and SV.new_charms().is_empty())
	var before: float = SV.shiny_pull(1)
	var pool: Array = SV.region_pool(1)
	for i in range(pool.size() - 1):
		SV.add_owned(int(pool[i]["dex"]))
	check("one Pokémon short: still no charm", not SV.shiny_charm(1))
	SV.add_owned(int(pool[pool.size() - 1]["dex"]))
	check("owning every Pokémon of Kanto earns the Kanto charm", SV.shiny_charm(1))
	check("only for that region", not SV.shiny_charm(2) and SV.charm_gens().keys() == [1])
	check("gacha shiny chance +1% on that region", absf(SV.shiny_pull(1) - (SV.SHINY_PULL_DONE + SV.CHARM_PULL)) < 0.0001, "%.3f -> %.3f" % [before, SV.shiny_pull(1)])
	check("other regions keep their odds", absf(SV.shiny_pull(2) - SV.SHINY_PULL) < 0.0001)
	var first: Array = SV.new_charms()
	check("the new charm is announced once", first == [1] and SV.new_charms().is_empty())
	# a banner whose legendary is from Kanto uses Kanto's shiny chance (charm included)
	var kb := -1
	for w in range(SV.week_id(), SV.week_id() + 60):
		var bd: Array = SV.banner_dexes(w)
		for k in range(bd.size()):
			if int(SV.dex_by[int(bd[k])]["gen"]) == 1:
				kb = k
		if kb >= 0:
			break
	check("a Kanto banner shares the Kanto charm (it pulls with Kanto's shiny odds)", kb >= 0)
	# ---------- in a run ----------
	SV.run_dex = 25
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(10):
		await process_frame
	var g2 := 0
	for p in SV.region_pool(2):
		g2 = int(p["dex"])
		break
	check("in a run, wild Kanto Pokémon are shiny ×3 as often", absf(m._charm_k(25) - 3.0) < 0.001)
	check("wild Pokémon from other regions are unchanged", absf(m._charm_k(g2) - 1.0) < 0.001)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
