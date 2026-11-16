extends SceneTree
# Eggs step 26: hatching. A ready egg only; new Pokémon get IVs >= 20; owned ones act as gacha duplicates (coins by
# rarity, IVs can rise); shiny about 2% over 1000 hatches; the egg leaves the bag; stats count hatches.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _ready_egg(EG, dex: int, rarity: int, ty: String) -> int:
	var e: Dictionary = EG.make(dex, rarity, ty)
	e["slot"] = 0
	e["steps"] = e["need"]
	EG.eggs().append(e)
	return int(e["id"])

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var EG = load("res://scripts/eggs.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.load_dex()
	var e0: Dictionary = EG.make(1, 1, "grass")
	EG.add(e0)
	check("an egg that isn't ready doesn't hatch", EG.hatch(int(e0["id"])).is_empty() and EG.count() == 1)
	EG.remove(int(e0["id"]))
	# new Pokémon: IVs >= 20 every time
	var low := 0
	var news := 0
	var cands: Array = []
	for p in SV.dex_list:
		if int(p["rarity"]) <= 4 and not bool(p.get("leg", false)) and SV.smeta.has(str(int(p["dex"]))):
			cands.append(int(p["dex"]))
	for i in range(200):
		var dex: int = cands[i]
		var r: Dictionary = EG.hatch(_ready_egg(EG, dex, 1, "normal"))
		if bool(r.get("new", false)):
			news += 1
			for v in SV.d["owned"][str(dex)]["iv"]:
				if int(v) < EG.IV_MIN:
					low += 1
	check("200 new Pokémon hatched, all owned", news == 200, str(news))
	check("each hatched new Pokémon has every IV >= 20", low == 0, "%d low IVs" % low)
	check("the egg leaves the bag", EG.count() == 0)
	# duplicates: coins back by rarity (Rare = 60)
	SV.d["coins"] = 0
	var r2: Dictionary = EG.hatch(_ready_egg(EG, cands[0], 3, "normal"))
	check("an owned Pokémon is a duplicate with the gacha refund", not bool(r2["new"]) and (r2["refund"] == 60 or (r2["shiny"] and r2["refund"] in [0, 180])), str(r2))
	check("the coins are paid", int(SV.d["coins"]) == int(r2["refund"]))
	check("the duplicate count goes up", int(SV.d["owned"][str(cands[0])]["n"]) >= 2)
	# shiny rate: about 2% (no charms in a fresh save)
	var shiny_dex: int = -1
	for dx in cands:
		if bool(SV.smeta[str(dx)].get("sh", 0)):
			shiny_dex = dx
			break
	var sh := 0
	for i in range(3000):
		if bool(EG.hatch(_ready_egg(EG, shiny_dex, 1, "normal"))["shiny"]):
			sh += 1
	check("shiny about 2% of 3000 hatches", sh >= 35 and sh <= 90, "%d (%.1f%%)" % [sh, 100.0 * sh / 3000.0])
	check("hatches are counted", int(SV.d["stats"].get("eggsHatched", 0)) == 3201, str(SV.d["stats"].get("eggsHatched", 0)))
	check("shiny hatches are counted", int(SV.d["stats"].get("eggShinies", 0)) >= sh)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
