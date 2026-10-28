extends RefCounted
# Redeem codes for special unlocks (Settings > Account > Redeem code). The game is offline, so the table only stores the
# SHA-256 of each code (with a salt), not the codes themselves. Each code works once per save.
#   MEGARIFT     alpha tester gift: 10,000 coins, 25 tickets, 5 x10 tickets
#   STARTERPACK  every strong starter (see starters_data.gd STRONG)
#   MEGAPACK     every Pokémon that can Mega Evolve (+ 5,000 coins)
#   LEGENDS      every legendary Pokémon
#   UNLOCKALL    everything (testing): all Pokémon, upgrades, achievements, medals, Z-Crystals, recipes, tower floors
const SV = preload("res://scripts/save_data.gd")
const MG = preload("res://scripts/mega.gd")
const ST = preload("res://scripts/starters_data.gd")
const UNL = preload("res://scripts/unlock_all.gd")
const SALT := "megarift:"

const TABLE := {
	"d3e0f7ef5d8ca75a5d9d618728273c3b3dabe9f4e079aeb888d8919aa26b095a": "alpha",
	"ccff2b21521dce45c9f96c1815e4700b74845d144ceffc7c7bee245359b82a14": "starters",
	"369f1375d6aa82a6db1d7098f87d01222c148c259fc3ec09ac279645d1d2d52f": "megas",
	"bbc8941822cea37cde6bc58063482bb5e252d6260dc903b1620cf68951f3927e": "legends",
	"afcbf9b0e121bb9505fe535863f367a4f9c0ad0f5ab5a84c98a02add22e4311d": "all",
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
	match id:
		"alpha":
			d["coins"] = int(d["coins"]) + 10000
			d["tickets"] = int(d["tickets"]) + 25
			d["tickets10"] = int(d.get("tickets10", 0)) + 5
			msg = "Alpha tester gift: 10,000 coins, 25 tickets and 5 ×10 tickets."
		"starters":
			var n1 := _grant(d, ST.STRONG)
			msg = "Starter pack: %d new Pokémon." % n1
		"megas":
			var list: Array = []
			for p in SV.dex_list:
				if MG.is_capable(int(p["dex"])):
					list.append(int(p["dex"]))
			var n2 := _grant(d, list)
			d["coins"] = int(d["coins"]) + 5000
			msg = "Mega pack: %d new Pokémon and 5,000 coins." % n2
		"legends":
			var list2: Array = []
			for p in SV.dex_list:
				if bool(p.get("leg", false)):
					list2.append(int(p["dex"]))
			var n3 := _grant(d, list2)
			msg = "Legend pack: %d new Pokémon." % n3
		"all":
			UNL.apply(d, true)
			msg = "Everything unlocked."
	used[id] = int(Time.get_unix_time_from_system())
	d["codes_used"] = used
	return {"ok": true, "msg": msg}


static func _grant(d: Dictionary, dexes: Array) -> int:
	var added := 0
	for dx in dexes:
		var k := str(int(dx))
		if not (d["owned"] as Dictionary).has(k):
			d["owned"][k] = {"n": 1, "shiny": false}
			added += 1
	return added
