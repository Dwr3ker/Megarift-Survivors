extends RefCounted
# Eggs (docs/eggs.md): found in runs, kept in SV.d["eggs"], hatched in the incubator after walking far enough.
# An egg: {"id", "dex", "rarity", "look", "need" (metres), "steps" (metres walked while incubated), "slot" (-1 or 0..2)}.
const SV = preload("res://scripts/save_data.gd")

const MAX_EGGS := 12
const SLOTS := 3
const PER_RUN := 2
const DROP := {"boss": 0.15, "alpha": 0.30, "rescue": 0.15}
const NEED := {1: 1000.0, 2: 1500.0, 3: 2500.0, 4: 4000.0}   # metres to hatch, by rarity
const SHINY := 0.02
const IV_MIN := 20
# egg looks by the Pokémon's first type (a hint, not the answer)
const LOOKS := {"red": ["fire", "fighting", "dragon"], "blue": ["water", "ice", "flying"], "green": ["grass", "bug", "poison"],
	"yellow": ["electric", "normal", "fairy"], "brown": ["ground", "rock", "steel"], "purple": ["psychic", "ghost", "dark"]}
const LOOK_ORDER := ["red", "blue", "green", "yellow", "brown", "purple"]


static func eggs() -> Array:
	SV.ensure()
	if not (SV.d.get("eggs") is Array):
		SV.d["eggs"] = []
	return SV.d["eggs"]


static func look_of(type: String) -> String:
	for k in LOOKS:
		if (LOOKS[k] as Array).has(type):
			return String(k)
	return "yellow"


static func count() -> int:
	return eggs().size()


static func full() -> bool:
	return count() >= MAX_EGGS


static func by_id(id: int) -> Dictionary:
	for e in eggs():
		if int(e["id"]) == id:
			return e
	return {}


static func in_slot(slot: int) -> Dictionary:
	for e in eggs():
		if int(e.get("slot", -1)) == slot:
			return e
	return {}


static func incubated() -> Array:
	return eggs().filter(func(e): return int(e.get("slot", -1)) >= 0)


static func is_ready(e: Dictionary) -> bool:
	return not e.is_empty() and int(e.get("slot", -1)) >= 0 and float(e.get("steps", 0.0)) >= float(e.get("need", 1.0))


static func ready_eggs() -> Array:
	return incubated().filter(func(e): return is_ready(e))


# An egg for this Pokémon (dex and rarity), ready to store. Not stored yet.
static func make(dex: int, rarity: int, first_type: String) -> Dictionary:
	SV.d["egg_id"] = int(SV.d.get("egg_id", 0)) + 1
	var r: int = clampi(rarity, 1, 4)
	return {"id": int(SV.d["egg_id"]), "dex": dex, "rarity": r, "look": look_of(first_type), "need": float(NEED[r]), "steps": 0.0, "slot": -1}


# Stores an egg; it goes straight into a free incubator slot if there is one. False when the bag is full.
static func add(e: Dictionary) -> bool:
	if full():
		return false
	var free: int = free_slot()
	e["slot"] = free
	eggs().append(e)
	return true


static func free_slot() -> int:
	for s in range(SLOTS):
		if in_slot(s).is_empty():
			return s
	return -1


# Puts an egg in a slot (swapping with the egg already there, if any) or takes it out (slot -1).
static func place(id: int, slot: int) -> bool:
	var e: Dictionary = by_id(id)
	if e.is_empty() or slot < -1 or slot >= SLOTS:
		return false
	if slot >= 0:
		var other: Dictionary = in_slot(slot)
		if not other.is_empty() and int(other["id"]) != id:
			other["slot"] = int(e.get("slot", -1))
	e["slot"] = slot
	return true


# The distance walked in a run, credited to every incubated egg. Returns the eggs that just became ready.
static func credit(meters: float) -> Array:
	var now_ready: Array = []
	if meters <= 0.0:
		return now_ready
	for e in incubated():
		var was: bool = is_ready(e)
		e["steps"] = minf(float(e["need"]), float(e.get("steps", 0.0)) + meters)
		if not was and is_ready(e):
			now_ready.append(e)
	return now_ready


static func remove(id: int) -> void:
	var l: Array = eggs()
	for i in range(l.size()):
		if int(l[i]["id"]) == id:
			l.remove_at(i)
			return


# Hatches a ready egg (step 26): the Pokémon joins the collection. New: IVs each at least IV_MIN. Already owned: a gacha
# duplicate (coins back by rarity, IVs can rise; a new shiny of an owned Pokémon counts as new, an owned shiny pays x3).
# Shiny: SHINY plus the region's Shiny Charm. Returns {dex, name, new, shiny, refund, rarity, look} or {} if not ready.
static func hatch(id: int) -> Dictionary:
	var e: Dictionary = by_id(id)
	if not is_ready(e):
		return {}
	var dex: int = int(e["dex"])
	var rarity: int = clampi(int(e["rarity"]), 1, 4)
	var sp: Dictionary = SV.dex_by.get(dex, {})
	var region: int = int(sp.get("gen", 0))
	var sh_p: float = SHINY + (SV.CHARM_PULL if region > 0 and SV.shiny_charm(region) else 0.0)
	var shiny: bool = randf() < sh_p and bool(SV.smeta.get(str(dex), {}).get("sh", 0))
	var shiny_owned: bool = SV.owns(dex) and bool(SV.d["owned"][str(dex)].get("shiny", false))
	var was_new: bool = not SV.owns(dex)
	var refund := 0
	if shiny:
		if shiny_owned:
			refund = int(SV.REFUND[rarity - 1]) * 3
		else:
			was_new = true
	elif not was_new:
		refund = int(SV.REFUND[rarity - 1])
	if refund > 0:
		SV.d["coins"] = int(SV.d["coins"]) + refund
	var first_catch: bool = not SV.owns(dex)
	SV.add_owned(dex, shiny and not shiny_owned)
	if first_catch:   # a hatched Pokémon is well bred: every IV at least IV_MIN
		var IVS = load("res://scripts/ivs.gd")
		var inf: Dictionary = IVS.info(dex)
		inf["iv"] = [randi_range(IV_MIN, IVS.IV_MAX), randi_range(IV_MIN, IVS.IV_MAX), randi_range(IV_MIN, IVS.IV_MAX)]
	remove(id)
	var st: Dictionary = SV.d["stats"]
	st["eggsHatched"] = int(st.get("eggsHatched", 0)) + 1
	if shiny:
		st["eggShinies"] = int(st.get("eggShinies", 0)) + 1
	return {"dex": dex, "name": String(sp.get("name", "?")), "new": was_new, "shiny": shiny, "refund": refund, "rarity": rarity, "look": String(e["look"])}
