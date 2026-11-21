extends SceneTree
# Challenges #73 and #74 were waiting on Weapon slots (removed in 0.1.3) and always showed "Coming soon". Now #73 is
# "fill all 4 move slots and defeat 600" and #74 (Expert, Golden Gachapon Coin) "evolve 4 moves and defeat 1,200";
# both are playable and complete on those goals.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _done(CH, d: Dictionary, m: Dictionary) -> bool:
	return CH.lines(d, m).all(func(l): return bool(l[3]))

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	var CH = load("res://scripts/challenges.gd")
	var c73: Dictionary = CH.by_id(73)
	var c74: Dictionary = CH.by_id(74)
	check("#73 and #74 are playable (not Coming soon)", CH.available(c73) and CH.available(c74))
	check("#74 still gives a Golden Gachapon Coin", bool(c74["gold"]))
	var m: Dictionary = CH.new_metrics()
	m["equipped"] = 3
	m["kills"] = 700
	check("#73: three moves isn't enough", not _done(CH, c73, m))
	m["equipped"] = 4
	check("#73: four moves and 600 defeated completes it", _done(CH, c73, m))
	m["evolves"] = 3
	m["kills"] = 1300
	check("#74: three evolutions isn't enough", not _done(CH, c74, m))
	m["evolves"] = 4
	check("#74: four evolutions and 1,200 defeated completes it", _done(CH, c74, m))
	check("no challenge needs Weapon slots any more", CH.all().all(func(d): return not (d["req"] as Dictionary).has("slot_buys") and not (d["req"] as Dictionary).has("slots6")))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
