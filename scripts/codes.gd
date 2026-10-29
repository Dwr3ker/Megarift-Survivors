extends RefCounted
# Redeem codes for special unlocks (Settings > Account > Redeem code). The game is offline, so the table only stores the
# SHA-256 of each code (with a salt), not the codes themselves. Each code works once per save.
#   MEGARIFT     alpha tester gift: 10,000 coins, 25 tickets, 5 x10 tickets
#   STARTERPACK  every strong starter (see starters_data.gd STRONG)
#   MEGAPACK     every Pokémon that can Mega Evolve (+ 5,000 coins)
#   LEGENDS      every legendary Pokémon
#   UNLOCKALL    everything (testing): all Pokémon, upgrades, achievements, medals, Z-Crystals, recipes, tower floors
# Random codes (each works once per save; they prefer a Pokémon you do not have yet and pay coins when there is none left):
#   LEGENDARY, LEGENDARY1..LEGENDARY9   a random legendary (any generation / that generation)
#   SHINY, SHINY1..SHINY9               a random shiny (any generation / that generation); owned Pokémon turn shiny
#   SHINYLEGENDARY                      a random shiny legendary
#   MEGARANDOM                          a random Pokémon that can Mega Evolve
const SV = preload("res://scripts/save_data.gd")
const MG = preload("res://scripts/mega.gd")
const ST = preload("res://scripts/starters_data.gd")
const UNL = preload("res://scripts/unlock_all.gd")
const SALT := "megarift:"
const DUPLICATE_COINS := 2000   # paid by a random code when there is nothing new left to give

const TABLE := {
	"d3e0f7ef5d8ca75a5d9d618728273c3b3dabe9f4e079aeb888d8919aa26b095a": "alpha",
	"ccff2b21521dce45c9f96c1815e4700b74845d144ceffc7c7bee245359b82a14": "starters",
	"369f1375d6aa82a6db1d7098f87d01222c148c259fc3ec09ac279645d1d2d52f": "megas",
	"bbc8941822cea37cde6bc58063482bb5e252d6260dc903b1620cf68951f3927e": "legends",
	"afcbf9b0e121bb9505fe535863f367a4f9c0ad0f5ab5a84c98a02add22e4311d": "all",
	"3978f9257ec4d3e0662a0f31a340cabc64922eafca56960514571e660a352683": "rleg:0",
	"aa5c877db58a59d2790aea958c2273a5f9a951de5ca2bfec35ce1e2c0b47f7d4": "rshiny:0",
	"147f6a80b1ecb8f77ed36865e71c2c9cf7e9c170df060e586e8143fb8113e569": "rshinyleg:0",
	"9d12d2bfd546da099a4d0fbe6d1e539abea81239d7f1ceed3f58336f26c203f5": "rmega:0",
	"72454704b7ef2edeed9386e67cf5aed5dce05cdb50607b5966f05fa9615f954e": "rleg:1",
	"595e968ec5e117fd5312e9e1ccb4edaa53fb312e65092c7350c9717ff25b910f": "rshiny:1",
	"c318fdfee1b21797b5716e81b1433bd58e01c2397dfc83631eb0e1530af553b5": "rleg:2",
	"2b3f61bd4563d56cd982af724a6eb1687838ac427b0537920aaddcef7ce1fb05": "rshiny:2",
	"9e89e555be7e17108f3d8b21d887be2678299f0966d3a744ebb0441f99f370b4": "rleg:3",
	"eec7c7d9439830ef5dcd4a9f8d74b9ec82e84185a83d289c50e1f5697643b8ff": "rshiny:3",
	"82b0e802876999a7568c9814f956410ac01969d4649da9167dfd1a83a24749f1": "rleg:4",
	"1a84828523cd303b7130d597983b6ccddcb39773eb6829eee4d2c057654f7a9e": "rshiny:4",
	"750e5d4ed2de283ee56c46ea37790c1b567cd23cfb8646893f40114e28af1230": "rleg:5",
	"0894572e903c948ea62224b8d989a3ac14ff6ed36490aede26109852023ef6cd": "rshiny:5",
	"d57f5b89ddaf817afc9cbdead76649c74b9edbc08830f6b96878a47496cdf1cf": "rleg:6",
	"b30350e13ef254a3f662b3e02c0a9a7eeeb41ea252e2cc1b339428e717199511": "rshiny:6",
	"6a04a91966c99d7f3d3337944044daa395d9e054dcc2a3a69a200cf71a76cce6": "rleg:7",
	"c5fa5fbbd772281994bb182e6ca9ae7c24ed364222154abd92e059156cf47e73": "rshiny:7",
	"6a4fc6f11a8562def55b5d05e005ea3a03314b1090b9ace4da9a698c56a1f7b2": "rleg:8",
	"a8a3f6b0d2daef40668eaa1cf03f0a0edac2db2b27264937dbf8a96d1f303f44": "rshiny:8",
	"0cbf793d4abb9deb94a475bc31213368daa30b31700c7fece3ed82137ff05eb8": "rleg:9",
	"dce4558e6b6f6e0a1dcf8421dcfca3f6c6ab677e7f9fca5108b1b0c95ab84c95": "rshiny:9",
}


# Letters and digits only, upper case: "mega-rift", "Mega Rift" and "MEGARIFT" are the same code.
static func normalize(text: String) -> String:
	var out := ""
	for ch in text.to_upper():
		var c: int = ch.unicode_at(0)
		if (c >= 48 and c <= 57) or (c >= 65 and c <= 90):
			out += ch
	return out


static func hash_of(text: String) -> String:
	return (SALT + normalize(text)).sha256_text()


# Applies the code to `d` (the save dictionary). Returns {"ok": bool, "msg": String}; msg is English text for L.t().
static func redeem(text: String, d: Dictionary) -> Dictionary:
	var n: String = normalize(text)
	if n == "":
		return {"ok": false, "msg": "Type a code first."}
	var id: String = String(TABLE.get(hash_of(n), ""))
	if id == "":
		return {"ok": false, "msg": "That code is not valid."}
	var used: Dictionary = d.get("codes_used", {})
	if used.has(id):
		return {"ok": false, "msg": "You already used that code."}
	SV.load_dex()
	var msg := ""
	var args: Array = []
	match id:
		"alpha":
			d["coins"] = int(d["coins"]) + 10000
			d["tickets"] = int(d["tickets"]) + 25
			d["tickets10"] = int(d.get("tickets10", 0)) + 5
			msg = "Alpha tester gift: 10,000 coins, 25 tickets and 5 ×10 tickets."
		"starters":
			msg = "Starter pack: %d new Pokémon."
			args = [_grant(d, ST.STRONG)]
		"megas":
			var list: Array = []
			for p in SV.dex_list:
				if MG.is_capable(int(p["dex"])):
					list.append(int(p["dex"]))
			d["coins"] = int(d["coins"]) + 5000
			msg = "Mega pack: %d new Pokémon and 5,000 coins."
			args = [_grant(d, list)]
		"legends":
			var list2: Array = []
			for p in SV.dex_list:
				if bool(p.get("leg", false)):
					list2.append(int(p["dex"]))
			msg = "Legend pack: %d new Pokémon."
			args = [_grant(d, list2)]
		"all":
			UNL.apply(d, true)
			msg = "Everything unlocked."
		_:
			var rr: Dictionary = _random_reward(id, d)
			msg = String(rr["msg"])
			args = rr["args"]
	used[id] = int(Time.get_unix_time_from_system())
	d["codes_used"] = used
	return {"ok": true, "msg": msg, "args": args}


# "rleg:3" = a random legendary of generation 3 (0 = any generation); "rshiny", "rshinyleg" and "rmega" work the same way.
# Prefers a Pokémon that would be new (for shiny codes: one that is not shiny yet). With nothing new left it pays coins.
static func _random_reward(id: String, d: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var parts: PackedStringArray = id.split(":")
	var kind: String = parts[0]
	var gen: int = int(parts[1]) if parts.size() > 1 else 0
	var pool: Array = []
	var fresh: Array = []
	for p in SV.dex_list:
		if gen > 0 and int(p["gen"]) != gen:
			continue
		var dx: int = int(p["dex"])
		if (kind == "rleg" or kind == "rshinyleg") and not bool(p.get("leg", false)):
			continue
		if kind == "rmega" and not MG.is_capable(dx):
			continue
		pool.append(dx)
		var own = (d["owned"] as Dictionary).get(str(dx), null)
		var shiny_kind: bool = kind == "rshiny" or kind == "rshinyleg"
		if own == null or (shiny_kind and not bool(own.get("shiny", false))):
			fresh.append(dx)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if fresh.is_empty():
		d["coins"] = int(d["coins"]) + DUPLICATE_COINS
		return {"msg": "You already have all of those: %d coins instead.", "args": [DUPLICATE_COINS]}
	var dex: int = int(fresh[rng.randi() % fresh.size()])
	var shiny: bool = kind == "rshiny" or kind == "rshinyleg"
	var key := str(dex)
	if (d["owned"] as Dictionary).has(key):
		if shiny:
			d["owned"][key]["shiny"] = true
	else:
		d["owned"][key] = {"n": 1, "shiny": shiny}
	if shiny:
		d["stats"]["shinies"] = int(d["stats"].get("shinies", 0)) + 1
	var nm: String = String(SV.dex_by[dex]["name"]) if SV.dex_by.has(dex) else "#%d" % dex
	return {"msg": "Shiny %s joins you!" if shiny else "%s joins you!", "args": [nm], "dex": dex}


static func _grant(d: Dictionary, dexes: Array) -> int:
	var added := 0
	for dx in dexes:
		var k := str(int(dx))
		if not (d["owned"] as Dictionary).has(k):
			d["owned"][k] = {"n": 1, "shiny": false}
			added += 1
	return added
