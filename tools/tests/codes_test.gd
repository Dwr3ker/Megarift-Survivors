extends SceneTree
# Headless check of save codes: round trip, short size, tolerance for copy/paste damage, and clear errors.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.load_dex()
	var d: Dictionary = SV.default_data()
	d["coins"] = 9999999
	for p in SV.dex_list:
		d["owned"][str(int(p["dex"]))] = {"n": 3, "shiny": true}
		var m: Dictionary = {}
		for u in SV.UPGRADES:
			m[String(u["id"])] = int(u["max"])
		d["pup"][str(int(p["dex"]))] = m
	var json_len: int = JSON.stringify(d).length()
	var code: String = SV.encode_code(d)
	check("a big save becomes a short code", code.length() < json_len / 8 and code.begins_with("MRS1:"), "%d chars (json %d)" % [code.length(), json_len])
	var r: Dictionary = SV.decode_code(code)
	check("round trip keeps the save", bool(r["ok"]) and (r["data"] as Dictionary)["owned"].size() == d["owned"].size() and int(r["data"]["coins"]) == 9999999 and r["data"]["pup"].size() == d["pup"].size())
	# damage that copying adds
	var wrapped := ""
	for i in range(0, code.length(), 60):
		wrapped += code.substr(i, 60) + String.chr(10)
	check("line breaks inside the code are ignored", bool(SV.decode_code(wrapped)["ok"]))
	check("spaces, tabs and quotes around the code are ignored", bool(SV.decode_code("  " + String.chr(34) + code.insert(30, " ") + String.chr(34) + String.chr(9) + String.chr(13) + String.chr(10))["ok"]))
	check("non-breaking and zero-width spaces are ignored", bool(SV.decode_code(code.insert(40, String.chr(160)).insert(70, String.chr(8203)))["ok"]))
	# older formats
	var legacy: String = Marshalls.utf8_to_base64(JSON.stringify(d))
	check("the older plain base64 code still works", bool(SV.decode_code(legacy)["ok"]))
	check("raw JSON works", bool(SV.decode_code(JSON.stringify(d))["ok"]))
	var urlsafe: String = legacy.replace("+", "-").replace("/", "_").replace("=", "")
	check("URL-safe base64 without padding works", bool(SV.decode_code(urlsafe)["ok"]))
	# clear errors
	var e1: Dictionary = SV.decode_code("")
	check("empty clipboard: says so", not bool(e1["ok"]) and String(e1["error"]).contains("empty"), String(e1["error"]))
	var e2: Dictionary = SV.decode_code(code.substr(0, code.length() / 2))
	check("a cut-short code says it was cut short", not bool(e2["ok"]) and String(e2["error"]).contains("cut short"), String(e2["error"]))
	var e3: Dictionary = SV.decode_code("hello this is not a code")
	check("random text is rejected", not bool(e3["ok"]) and String(e3["error"]) != "", String(e3["error"]))
	var e4: Dictionary = SV.decode_code(JSON.stringify({"foo": 1}))
	check("JSON that is not a save is rejected", not bool(e4["ok"]) and String(e4["error"]).contains("not a Megarift save"), String(e4["error"]))
	var e5: Dictionary = SV.decode_code("MRS1:abc:AAAA")
	check("a bad header is reported", not bool(e5["ok"]) and String(e5["error"]).contains("header"), String(e5["error"]))
	# ---------- redeem codes ----------
	var CODES = load("res://scripts/codes.gd")
	var ST = load("res://scripts/starters_data.gd")
	var sv: Dictionary = SV.default_data()
	var r0: Dictionary = CODES.redeem("", sv)
	check("an empty code asks for one", not bool(r0["ok"]))
	var r1: Dictionary = CODES.redeem("nope-nope", sv)
	check("an unknown code is rejected", not bool(r1["ok"]) and String(r1["msg"]).contains("not valid"))
	var coins0: int = int(sv["coins"])
	var r2: Dictionary = CODES.redeem("mega rift", sv)
	check("MEGARIFT works whatever the spacing and case", bool(r2["ok"]) and int(sv["coins"]) == coins0 + 10000 and int(sv["tickets"]) >= 35)
	var r3: Dictionary = CODES.redeem("MEGARIFT", sv)
	check("a code works only once", not bool(r3["ok"]) and String(r3["msg"]).contains("already"))
	var r4: Dictionary = CODES.redeem("starter-pack", sv)
	var all_starters := true
	for dx in ST.STRONG:
		if not sv["owned"].has(str(int(dx))):
			all_starters = false
		if not SV.dex_by.has(int(dx)):
			all_starters = false
	check("STARTERPACK grants every strong starter (all exist in the Pokédex)", bool(r4["ok"]) and all_starters and ST.STRONG.size() == 12, str(r4["msg"]))
	var MG = load("res://scripts/mega.gd")
	var r5: Dictionary = CODES.redeem("MEGAPACK", sv)
	var mega_ok := true
	var mega_n := 0
	for p in SV.dex_list:
		if MG.is_capable(int(p["dex"])):
			mega_n += 1
			if not sv["owned"].has(str(int(p["dex"]))):
				mega_ok = false
	check("MEGAPACK grants every Mega-capable Pokémon", bool(r5["ok"]) and mega_ok and mega_n >= 35, "%d mega-capable" % mega_n)
	var r6: Dictionary = CODES.redeem("legends", sv)
	check("LEGENDS grants the legendaries", bool(r6["ok"]))
	var r7: Dictionary = CODES.redeem("Unlock All", sv)
	check("UNLOCKALL unlocks everything", bool(r7["ok"]) and sv["owned"].size() == SV.dex_list.size() and sv["ach"].size() > 200 and int(sv["pup"]["25"]["hp"]) == 10 and int(sv["coins"]) >= 9999999)
	check("the plain code words are not stored in the table", not str(CODES.TABLE).contains("MEGARIFT") and not str(CODES.TABLE).contains("UNLOCKALL"))
	# ---------- random codes ----------
	var sv2: Dictionary = SV.default_data()
	var gens_ok := true
	for g in range(1, 10):
		var before: int = sv2["owned"].size()
		var rl: Dictionary = CODES.redeem("legendary%d" % g, sv2)
		var got: int = int(CODES._random_reward("rleg:%d" % g, SV.default_data())["dex"])
		var is_leg: bool = bool(SV.dex_by[got].get("leg", false)) and int(SV.dex_by[got]["gen"]) == g
		if not bool(rl["ok"]) or sv2["owned"].size() != before + 1 or not is_leg:
			gens_ok = false
	check("LEGENDARY1..9 each give one legendary of that generation", gens_ok)
	check("a random code works only once", not bool(CODES.redeem("LEGENDARY3", sv2)["ok"]))
	var sv3: Dictionary = SV.default_data()
	var rs: Dictionary = CODES.redeem("shiny", sv3)
	var got_dex: int = -1
	for k in sv3["owned"]:
		got_dex = int(k)
	check("SHINY gives one shiny Pokémon and counts it", bool(rs["ok"]) and sv3["owned"].size() == 1 and bool(sv3["owned"][str(got_dex)]["shiny"]) and int(sv3["stats"]["shinies"]) == 1)
	var sv4: Dictionary = SV.default_data()
	for p in SV.dex_list:
		if int(p["gen"]) == 2:
			sv4["owned"][str(int(p["dex"]))] = {"n": 1, "shiny": false}
	var rg: Dictionary = CODES.redeem("shiny 2", sv4)
	var shiny_n := 0
	for k in sv4["owned"]:
		if bool(sv4["owned"][k]["shiny"]):
			shiny_n += 1
	check("SHINY2 turns one owned Gen 2 Pokémon shiny", bool(rg["ok"]) and shiny_n == 1 and sv4["owned"].size() == 100)
	var sv5: Dictionary = SV.default_data()
	var rsl: Dictionary = CODES.redeem("shinylegendary", sv5)
	var kd: int = int(CODES._random_reward("rshinyleg:0", SV.default_data())["dex"])
	check("SHINYLEGENDARY gives a shiny legendary", bool(rsl["ok"]) and sv5["owned"].size() == 1 and bool(SV.dex_by[kd].get("leg", false)))
	var sv6: Dictionary = SV.default_data()
	var rm: Dictionary = CODES.redeem("megarandom", sv6)
	var md := -1
	for k in sv6["owned"]:
		md = int(k)
	check("MEGARANDOM gives a Mega-capable Pokémon", bool(rm["ok"]) and MG.is_capable(md))
	var sv7: Dictionary = SV.default_data()
	for p in SV.dex_list:
		sv7["owned"][str(int(p["dex"]))] = {"n": 1, "shiny": true}
	var c0: int = int(sv7["coins"])
	var rd: Dictionary = CODES.redeem("legendary", sv7)
	check("with nothing new left a random code pays coins", bool(rd["ok"]) and int(sv7["coins"]) == c0 + CODES.DUPLICATE_COINS, str(rd["msg"]))
	check("messages are templates with arguments", String(rs["msg"]).contains("%s") and (rs["args"] as Array).size() == 1)
	# ---------- GIMME codes ----------
	var sg: Dictionary = SV.default_data()
	var rga: Dictionary = CODES.redeem("gimme all", sg)
	var n_sprites := 0
	for p in SV.dex_list:
		if SV.smeta.has(str(int(p["dex"]))):
			n_sprites += 1
	var any_shiny := false
	for k in sg["owned"]:
		if bool(sg["owned"][k]["shiny"]):
			any_shiny = true
	check("GIMMEALL gives every Pokémon with no upgrades, achievements or shinies", bool(rga["ok"]) and sg["owned"].size() == n_sprites and sg["pup"].is_empty() and not any_shiny and (not sg.has("ach") or sg["ach"].is_empty()), "%d owned of %d" % [sg["owned"].size(), n_sprites])
	check("GIMMEALL works only once", not bool(CODES.redeem("GIMMEALL", sg)["ok"]))
	var sp: Dictionary = SV.default_data()
	var rp: Dictionary = CODES.redeem("GIMMEPIKACHU", sp)
	check("GIMMEPIKACHU gives Pikachu", bool(rp["ok"]) and sp["owned"].has("25") and (rp["args"] as Array)[0] == "Pikachu", str(rp["msg"]))
	check("each GIMME code works once", not bool(CODES.redeem("gimme-pikachu", sp)["ok"]) and bool(CODES.redeem("GIMMEEEVEE", sp)["ok"]))
	check("a name that is not a Pokémon is rejected", not bool(CODES.redeem("GIMMEFOOBAR", sp)["ok"]) and not bool(CODES.redeem("GIMME", sp)["ok"]))
	var mm: Dictionary = CODES.redeem("GIMMEMRMIME", SV.default_data())
	check("names with punctuation work (Mr. Mime)", bool(mm["ok"]))
	var shinies := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(4000):
		var fresh: Dictionary = SV.default_data()
		if bool(CODES._gimme_reward("gimme:25", fresh, rng)["shiny"]):
			shinies += 1
	check("the shiny chance matches one gacha pull (1%)", shinies >= 15 and shinies <= 70, "%d shinies in 4000 (expected about %d)" % [shinies, int(4000.0 * SV.SHINY_PULL)])
	var dup: Dictionary = SV.default_data()
	dup["owned"]["25"] = {"n": 1, "shiny": false}
	var rd2: Dictionary = {}
	rng.seed = 7
	for i in range(50):
		var cp: Dictionary = dup.duplicate(true)
		rd2 = CODES._gimme_reward("gimme:25", cp, rng)
		if not bool(rd2["shiny"]):
			check("a duplicate pays the gacha refund", int(cp["coins"]) == int(dup["coins"]) + int(SV.REFUND[int(SV.dex_by[25]["rarity"]) - 1]), str(rd2["msg"]))
			break
	var already: Dictionary = SV.default_data()
	already["owned"]["25"] = {"n": 1, "shiny": true}
	var allfail := true
	for i in range(200):
		var cp2: Dictionary = already.duplicate(true)
		var r3x: Dictionary = CODES._gimme_reward("gimme:25", cp2, rng)
		if bool(r3x["shiny"]):
			allfail = false
	check("a shiny you already have is never given twice", allfail)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
