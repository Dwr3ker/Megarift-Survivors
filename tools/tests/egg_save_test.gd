extends SceneTree
# Roadmap step 20: eggs are kept in the save (12 at most, 3 incubator slots), an old save without eggs still works,
# eggs go into a free slot, can be moved and taken out, and survive saving and loading.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var SV = load("res://scripts/save_data.gd")
	var EG = load("res://scripts/eggs.gd")
	SV.ensure()
	SV.d = SV.default_data()
	check("a new save has an empty egg bag", EG.count() == 0 and SV.d.has("eggs"))
	SV.d.erase("eggs")
	SV.d.erase("egg_id")
	check("an old save without eggs still works", EG.count() == 0 and EG.free_slot() == 0)
	var e1: Dictionary = EG.make(4, 2, "fire")
	check("an egg records its Pokémon, rarity, look and distance", int(e1["dex"]) == 4 and String(e1["look"]) == "red" and float(e1["need"]) == 1500.0)
	check("it goes into the first free incubator slot", EG.add(e1) and int(e1["slot"]) == 0)
	for i in range(3):
		EG.add(EG.make(7, 1, "water"))
	check("three slots, then eggs wait in the bag", EG.incubated().size() == 3 and int(EG.eggs()[3]["slot"]) == -1)
	var bag_id: int = int(EG.eggs()[3]["id"])
	check("an egg from the bag can take a slot (swapping the one there out)", EG.place(bag_id, 0) and int(EG.by_id(bag_id)["slot"]) == 0 and int(e1["slot"]) == -1)
	check("and be taken out again", EG.place(bag_id, -1) and EG.in_slot(0).is_empty())
	var back = JSON.parse_string(JSON.stringify(SV.d))
	SV.d = back
	check("eggs survive saving and loading", EG.count() == 4 and int(EG.by_id(bag_id)["dex"]) == 7)
	while not EG.full():
		EG.add(EG.make(1, 1, "grass"))
	check("the bag holds 12 at most", EG.count() == 12 and not EG.add(EG.make(1, 1, "grass")))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
