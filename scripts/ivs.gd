extends RefCounted
# IVs and natures for every Pokémon you own (saved in SV.d["owned"][dex] as "iv": [hp, atk, spd] and "nat").
# This game has three stats, so natures are the six that map onto them (Defense stands in for HP) plus the
# neutral ones. An IV of 0..31 is worth -5%..+5% on its stat; a nature is +10% on one stat and -5% on another
# (a mild downside, so a random nature is never a real setback).
# A duplicate re-rolls each IV and keeps the better value, so pulling the same Pokémon again makes it stronger.
# Pokémon you don't own (a daily pick, a party Pokémon) are neutral: x1.0 on everything.
const SV = preload("res://scripts/save_data.gd")

const STATS := ["hp", "atk", "spd"]
const STAT_NAME := {"hp": "HP", "atk": "Attack", "spd": "Speed"}
# nature -> [stat raised, stat lowered]; "" = neutral
const NATURES := {
	"Lonely": ["atk", "hp"], "Bold": ["hp", "atk"], "Brave": ["atk", "spd"], "Timid": ["spd", "atk"],
	"Hasty": ["spd", "hp"], "Relaxed": ["hp", "spd"],
	"Hardy": ["", ""], "Docile": ["", ""], "Serious": ["", ""], "Bashful": ["", ""], "Quirky": ["", ""],
}
const IV_MAX := 31
const IV_SPAN := 0.10     # IV 0 = -5%, IV 31 = +5%
const NAT_UP := 0.10
const NAT_DOWN := 0.05
# Training without duplicates (Pokémon page): a vitamin raises one IV, a Mint sets any nature. Paid in coins.
const VITAMIN := {"hp": "HP Up", "atk": "Protein", "spd": "Carbos"}
const VIT_STEP := 3
const VIT_COST := 300
const MINT_COST := 1000


# The owned entry with IVs and a nature, rolled the first time they are needed (new catches and old saves).
static func info(dex: int) -> Dictionary:
	var own: Dictionary = SV.d.get("owned", {})
	if not own.has(str(dex)):
		return {}
	var e: Dictionary = own[str(dex)]
	if not (e.get("iv") is Array) or (e["iv"] as Array).size() != 3:
		e["iv"] = [randi_range(0, IV_MAX), randi_range(0, IV_MAX), randi_range(0, IV_MAX)]
	if not NATURES.has(String(e.get("nat", ""))):
		e["nat"] = String(NATURES.keys()[randi() % NATURES.size()])
	if not (e.get("nats") is Array):
		e["nats"] = [String(e["nat"])]   # natures this Pokémon has had: switching between them is free
	return e


static func _random_nature() -> String:
	return String(NATURES.keys()[randi() % NATURES.size()])


static func has_nature(dex: int, nat: String) -> bool:
	var e: Dictionary = info(dex)
	return not e.is_empty() and (e["nats"] as Array).has(nat)


# Multiplier for `stat` ("hp", "atk", "spd") of Pokémon `dex`: IV x nature. 1.0 when you don't own it.
static func mul(dex: int, stat: String) -> float:
	var e: Dictionary = info(dex)
	if e.is_empty():
		return 1.0
	var i: int = STATS.find(stat)
	var iv: float = float((e["iv"] as Array)[i])
	var k: float = 1.0 - IV_SPAN * 0.5 + IV_SPAN * iv / float(IV_MAX)
	var nat: Array = NATURES[String(e["nat"])]
	if String(nat[0]) == stat:
		k *= 1.0 + NAT_UP
	elif String(nat[1]) == stat:
		k *= 1.0 - NAT_DOWN
	return k


# A duplicate: each IV gets a fresh roll and keeps the higher one, and the duplicate's own nature is unlocked
# (switch to it for free on the Pokémon page). Returns how many IVs went up.
static func on_duplicate(dex: int) -> int:
	var e: Dictionary = info(dex)
	if e.is_empty():
		return 0
	var dn: String = _random_nature()
	if not (e["nats"] as Array).has(dn):
		(e["nats"] as Array).append(dn)
	var up := 0
	var ivs: Array = e["iv"]
	for i in range(3):
		var r: int = randi_range(0, IV_MAX)
		if r > int(ivs[i]):
			ivs[i] = r
			up += 1
	return up


# A vitamin: +VIT_STEP to one IV (up to IV_MAX) for VIT_COST coins. "" when done, else why not
# ("owned" not yours, "max" already 31, "coins" not enough).
static func train(dex: int, stat: String) -> String:
	var e: Dictionary = info(dex)
	if e.is_empty():
		return "owned"
	var i: int = STATS.find(stat)
	var ivs: Array = e["iv"]
	if i < 0 or int(ivs[i]) >= IV_MAX:
		return "max"
	if int(SV.d["coins"]) < VIT_COST:
		return "coins"
	SV.d["coins"] = int(SV.d["coins"]) - VIT_COST
	ivs[i] = mini(IV_MAX, int(ivs[i]) + VIT_STEP)
	SV.save()
	return ""


# Sets nature `nat`: free if this Pokémon already had it (from a duplicate or an earlier Mint), otherwise a Mint
# for MINT_COST coins, which unlocks it for good. "" when done, else "owned" / "same" / "coins".
static func set_nature(dex: int, nat: String) -> String:
	var e: Dictionary = info(dex)
	if e.is_empty() or not NATURES.has(nat):
		return "owned"
	if String(e["nat"]) == nat:
		return "same"
	var nats: Array = e["nats"]
	if not nats.has(nat):
		if int(SV.d["coins"]) < MINT_COST:
			return "coins"
		SV.d["coins"] = int(SV.d["coins"]) - MINT_COST
		nats.append(nat)
	e["nat"] = nat
	SV.save()
	return ""


# "+Speed, -Attack" / "neutral" for nature `n`, translated.
static func effect_text(n: String, L) -> String:
	var nat: Array = NATURES[n]
	if String(nat[0]) == "":
		return L.t("neutral")
	return "+%s, -%s" % [L.t(String(STAT_NAME[String(nat[0])])), L.t(String(STAT_NAME[String(nat[1])]))]


# "Timid (+Speed, -Attack)" or "Hardy (neutral)", already translated.
static func nature_text(dex: int, L) -> String:
	var e: Dictionary = info(dex)
	if e.is_empty():
		return ""
	var n: String = String(e["nat"])
	var nat: Array = NATURES[n]
	if String(nat[0]) == "":
		return L.t("%s (neutral)") % L.t(n)
	return L.t("%s (+%s, -%s)") % [L.t(n), L.t(String(STAT_NAME[String(nat[0])])), L.t(String(STAT_NAME[String(nat[1])]))]
