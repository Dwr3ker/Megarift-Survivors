extends SceneTree
# Builds a "everything unlocked" save for testing, from the game's own data tables, and checks that the game accepts it.
#   godot --headless --path . --script res://tools/make_test_save.gd
# Environment: OUT_DIR (default: the current directory). Writes:
#   megarift_test_save.json        full save (every Pokémon, every upgrade maxed on every Pokémon): drop in as save.json (PC)
#   megarift_test_save_lite.json   same without the per-Pokémon upgrades (small enough to paste on a phone)
#   megarift_test_save_code.txt    the FULL save as an in-game "Paste save code" string (short, compressed)
# It never touches your real save: it builds the data in memory and only reads the game's tables.

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may ever write the real save
	var SV = load("res://scripts/save_data.gd")
	var PG = load("res://scripts/progress.gd")
	var MD = load("res://scripts/moves_data.gd")
	var TD = load("res://scripts/types_data.gd")
	var FUS = load("res://scripts/fusions.gd")
	var ACH = load("res://scripts/ach.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.load_dex()
	var UNL = load("res://scripts/unlock_all.gd")
	var d: Dictionary = SV.default_data()
	d["notes_seen"] = String(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	SV.d = d
	UNL.apply(d, false)
	var lite: Dictionary = d.duplicate(true)
	UNL.apply(d, true)
	# validation: the game's own import path must accept the code, and the numbers must add up
	var ok := true
	for variant in [["full", d], ["lite", lite]]:
		var code: String = SV.encode_code(variant[1])
		var res: Dictionary = SV.decode_code(code)
		var merged: Dictionary = SV._merge(SV.default_data(), res["data"])
		SV.d = merged
		var n_own: int = SV.owned_count()
		var all_done := true
		for a in PG.list():
			if not (SV.d["ach"] as Dictionary).has(String(a["id"])):
				all_done = false
		var unmet := 0
		for a in PG.list():
			if PG.value(a) < int(a["goal"]):
				unmet += 1
				print("  unmet: ", a["id"], " stat=", a["stat"], " value=", PG.value(a), " goal=", a["goal"])
		var up_ok: bool = variant[0] == "lite" or SV.up_level("hp", 25) == 10
		print("%-5s code=%d chars  owned=%d/%d  achievements all marked=%s  goals not met by stats=%d  upgrades ok=%s" % [variant[0], code.length(), n_own, SV.dex_list.size(), str(all_done), unmet, str(up_ok)])
		if n_own != SV.dex_list.size() or not all_done or not up_ok:
			ok = false
	var out_dir: String = OS.get_environment("OUT_DIR") if OS.get_environment("OUT_DIR") != "" else "."
	DirAccess.make_dir_recursive_absolute(out_dir)
	var full_txt: String = JSON.stringify(d)
	var lite_txt: String = JSON.stringify(lite)
	FileAccess.open(out_dir + "/megarift_test_save.json", FileAccess.WRITE).store_string(full_txt)
	FileAccess.open(out_dir + "/megarift_test_save_lite.json", FileAccess.WRITE).store_string(lite_txt)
	FileAccess.open(out_dir + "/megarift_test_save_code.txt", FileAccess.WRITE).store_string(SV.encode_code(d))
	print("wrote files to ", out_dir, "  full=", full_txt.length(), " bytes  lite=", lite_txt.length(), " bytes")
	SV.d = _guard   # the real save is untouched (nothing here calls save())
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
