extends RefCounted
# On-run HUD layout: every element has an offset (virtual pixels, from its default spot) and a size (percent). Layouts are saved
# in settings["hud_layout"]; named presets (layout + radar/stats visibility) in settings["hud_presets"]. The per-element sizes that
# used to be sliders in Settings live here now. Older saves are migrated from the hud_plate / hud_radar / ... settings.
const SV = preload("res://scripts/save_data.gd")

const IDS := ["plate", "radar", "stats", "items", "counters", "skills"]
const NAMES := {"plate": "Health plate", "radar": "Radar", "stats": "Stats panel", "items": "Item list", "counters": "Resource counters", "skills": "Move bar"}
const OLD_KEYS := {"plate": "hud_plate", "radar": "hud_radar", "stats": "hud_stats", "items": "hud_items", "counters": "hud_counters", "skills": "hud_skills"}
const S_MIN := 60
const S_MAX := 150
const MAX_OFF := 700.0
const MAX_PRESETS := 8


static func _st() -> Dictionary:
	SV.ensure()
	return SV.d["settings"]


static func _fresh() -> Dictionary:
	var out := {}
	for id in IDS:
		out[id] = {"x": 0.0, "y": 0.0, "s": 100}
	return out


# id -> {"x": float, "y": float, "s": int}. Created (and migrated from the old size sliders) on first use.
static func layout() -> Dictionary:
	var st: Dictionary = _st()
	if not (st.get("hud_layout") is Dictionary):
		var lay := _fresh()
		for id in IDS:
			lay[id]["s"] = clampi(int(st.get(OLD_KEYS[id], 100)), S_MIN, S_MAX)
		st["hud_layout"] = lay
	var cur: Dictionary = st["hud_layout"]
	for id in IDS:   # tolerate a layout from an older version
		if not (cur.get(id) is Dictionary):
			cur[id] = {"x": 0.0, "y": 0.0, "s": 100}
	return cur


static func offset(id: String) -> Vector2:
	var e: Dictionary = layout()[id]
	return Vector2(float(e["x"]), float(e["y"]))


static func scale_of(id: String) -> float:
	return clampf(float(int((layout()[id] as Dictionary)["s"])) / 100.0, float(S_MIN) / 100.0, float(S_MAX) / 100.0)


static func set_el(id: String, off: Vector2, size_pct: int) -> void:
	var e: Dictionary = layout()[id]
	e["x"] = clampf(off.x, -MAX_OFF, MAX_OFF)
	e["y"] = clampf(off.y, -MAX_OFF, MAX_OFF)
	e["s"] = clampi(size_pct, S_MIN, S_MAX)


static func reset_el(id: String) -> void:
	layout()[id] = {"x": 0.0, "y": 0.0, "s": 100}


static func reset_all() -> void:
	_st()["hud_layout"] = _fresh()
	set_show_map(true)


static func show_map() -> bool:
	return bool(_st().get("show_map", true))


static func set_show_map(on: bool) -> void:
	_st()["show_map"] = on


static func is_default() -> bool:
	for id in IDS:
		var e: Dictionary = layout()[id]
		if float(e["x"]) != 0.0 or float(e["y"]) != 0.0 or int(e["s"]) != 100:
			return false
	return show_map()


# ---- presets ----
static func presets() -> Dictionary:
	var st: Dictionary = _st()
	if not (st.get("hud_presets") is Dictionary):
		st["hud_presets"] = {}
	return st["hud_presets"]


static func preset_names() -> Array:
	var names: Array = presets().keys()
	names.sort()
	return names


static func active_preset() -> String:
	return String(_st().get("hud_preset", ""))


static func clean_name(raw: String) -> String:
	return raw.strip_edges().substr(0, 20)


# Saves the current layout (and radar / stats visibility) under `pname`. Returns false if the name is empty or the list is full.
static func save_preset(pname: String) -> bool:
	var n: String = clean_name(pname)
	if n == "":
		return false
	var all: Dictionary = presets()
	if not all.has(n) and all.size() >= MAX_PRESETS:
		return false
	all[n] = {"layout": layout().duplicate(true), "show_map": show_map(), "stats_box": bool(_st().get("stats_box", true))}
	_st()["hud_preset"] = n
	return true


static func load_preset(pname: String) -> bool:
	var all: Dictionary = presets()
	if not all.has(pname):
		return false
	var p: Dictionary = all[pname]
	var lay: Dictionary = (p["layout"] as Dictionary).duplicate(true)
	for id in IDS:
		if not (lay.get(id) is Dictionary):
			lay[id] = {"x": 0.0, "y": 0.0, "s": 100}
	_st()["hud_layout"] = lay
	set_show_map(bool(p.get("show_map", true)))
	_st()["stats_box"] = bool(p.get("stats_box", true))
	_st()["hud_preset"] = pname
	return true


static func delete_preset(pname: String) -> bool:
	var all: Dictionary = presets()
	if not all.has(pname):
		return false
	all.erase(pname)
	if active_preset() == pname:
		_st()["hud_preset"] = ""
	return true


# ---- default boxes (virtual pixels) used by the editor to draw each element where it sits by default ----
static func default_rect(id: String, vp: Vector2, ins: Vector4, team_rows: int = 0) -> Rect2:
	match id:
		"plate":
			return Rect2(12.0 + ins.x, 16.0 + ins.y, 232.0, 82.0)
		"radar":
			return Rect2(12.0 + ins.x, 16.0 + ins.y + 90.0, 232.0, 196.0)
		"stats":
			var k: float = clampf(vp.x / 1280.0, 0.72, 1.0)
			return Rect2(vp.x - 282.0 * k - 14.0 - ins.z, 134.0 + ins.y, 282.0 * k, 182.0 * k)
		"items":
			return Rect2(16.0 + ins.x, 16.0 + ins.y + 90.0 + 196.0 + 14.0, 232.0, 142.0)
		"counters":
			return Rect2(vp.x * 0.5 - 190.0, 66.0, 380.0, 40.0)
		"skills":
			return Rect2(vp.x * 0.5 - 215.0, vp.y - 14.0 - ins.w - 70.0, 430.0, 70.0)
	return Rect2()
