extends SceneTree
# Every move must look like itself: no two moves may share the same visual signature (kind, special pattern and every
# visual key from VFX.for_move except the palette), and every sprite, beam style and melee style they name must exist.
# This keeps type re-skins (the same attack drawn in another colour) from creeping back in.
const MD = preload("res://scripts/moves_data.gd")
const VFX = preload("res://scripts/vfx.gd")
const V2 = preload("res://scripts/vfx2.gd")
const PFX = preload("res://scripts/pfx.gd")

var fails := 0


func check(name: String, ok: bool, detail: String = "") -> void:
	print(("PASS  " if ok else "FAIL  ") + name + (("  " + detail) if detail != "" and not ok else ""))
	if not ok:
		fails += 1


static func signature(id: String) -> String:
	var m: Dictionary = MD.MOVES[id]
	var v: Dictionary = VFX.for_move(id, String(m["type"]))
	var keys: Array = v.keys()
	keys.sort()
	var parts: Array = [String(m["kind"]), String(m.get("pat", ""))]
	for k in keys:
		if String(k) != "pal":
			parts.append("%s=%s" % [k, v[k]])
	return "|".join(parts)


func _init() -> void:
	var by_sig := {}
	for id in MD.MOVES:
		var s: String = signature(String(id))
		if not by_sig.has(s):
			by_sig[s] = []
		by_sig[s].append(String(id))
	var clones: Array = []
	for s in by_sig:
		if (by_sig[s] as Array).size() > 1:
			clones.append(", ".join(by_sig[s]))
	check("every move has its own look (%d moves)" % MD.MOVES.size(), clones.is_empty(), "\n      same look: " + "\n      same look: ".join(clones))
	# every sprite a move names exists
	var missing: Array = []
	for id in MD.MOVES:
		var v: Dictionary = VFX.for_move(String(id), String(MD.MOVES[id]["type"]))
		for k in ["proj", "aura", "buff", "beam"]:
			if v.has(k):
				var sh: String = String(v[k])
				if not (VFX.META.has(sh) or V2.META.has(sh)) and sh != "lightning":
					missing.append("%s.%s=%s" % [id, k, sh])
		if v.has("melee") and not PFX.MELEE_STYLES.has(String(v["melee"])):
			missing.append("%s.melee=%s" % [id, v["melee"]])
		if v.has("bstyle") and not PFX.BEAM_STYLES.has(String(v["bstyle"])):
			missing.append("%s.bstyle=%s" % [id, v["bstyle"]])
	check("every sprite and style a move names exists", missing.is_empty(), str(missing))
	# every sprite can be drawn in every frame
	var bad: Array = []
	for sh in V2.META:
		for f in range(int(V2.META[sh][2])):
			var t: Texture2D = VFX.sprite(String(sh), "fire", f)
			if t == null or t.get_width() < 3:
				bad.append("%s#%d" % [sh, f])
	check("every new sprite renders", bad.is_empty(), str(bad))
	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit()
