extends SceneTree
# Headless check: every mega form has sprite metadata, all 7 sheets load, and the data file parses.
func _init() -> void:
	var MG = load("res://scripts/mega.gd")
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var bad := 0
	var f := FileAccess.open("res://data/megas.json", FileAccess.READ)
	var arr: Array = JSON.parse_string(f.get_as_text())
	for e in arr:
		var fid: int = int(e["form"])
		if not SV.smeta.has(str(fid)):
			print("NO META ", e["name"]); bad += 1; continue
		if MG.form_for(int(e["dex"])).is_empty():
			print("NO FORM_FOR ", e["name"]); bad += 1
		for a in ["Idle", "Walk", "Attack", "Shoot", "Charge", "Hurt", "Faint"]:
			var p := "res://assets/pokemon/%d/%s.png" % [fid, a]
			if load(p) == null:
				print("NO SHEET ", p); bad += 1
	print("forms: %d  problems: %d" % [arr.size(), bad])
	quit(1 if bad > 0 else 0)
