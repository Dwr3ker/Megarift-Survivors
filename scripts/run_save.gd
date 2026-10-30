extends RefCounted
# Mid-run save: pause > "Save and quit" stores the run's progress in user://run_save.dat and the main menu offers "Resume run".
# What is kept: the clock, level, XP and HP, every move with its level / evolution / fusion, stat upgrades, items, bonds,
# rerolls, bans, collected coins and tickets, Mega / Forme / Plate / Z-Move state, the boss and event schedule, the Doom level
# and the map. What is not: the enemies, shots and pickups on screen (the world repopulates), and a run can only be saved in
# a Normal run (Hyper included) away from boss fights, rifts and other special encounters.
const SV = preload("res://scripts/save_data.gd")
const L = preload("res://scripts/lang.gd")
const FM = preload("res://scripts/forme.gd")
const KYU = preload("res://scripts/kyurem.gd")
const PL = preload("res://scripts/plates.gd")

const PATH := "user://run_save.dat"
const VERSION := 1

# Main-script variables stored by name.
const FIELDS := ["run_time", "kills", "coins", "tickets", "tickets10", "gcoins_run", "gold_gcoins_run", "run_bosses", "run_chests", "run_rifts",
	"run_dens", "run_dmg", "run_kills_by", "run_big", "run_meters", "reap_kills", "pending_levels", "stat_lv", "rerolls", "bans", "banned",
	"revives", "bonds", "bond_ids", "bond_first", "fused_once", "fused_away", "item", "item2", "item3", "mega_done", "plate", "plate_t", "forme",
	"forme_t", "kyurem", "z_type", "z_crystal", "z_used", "z_cd", "dyn_used", "dyn_cd", "dash_k", "mom_max", "doom_winds", "eter_kills", "eter_at",
	"eter_last", "cal_used", "cal_for", "dir_done", "dir_gap", "dir_warned", "dir_map", "dir_log", "boss_idx", "boss_run", "cast_run",
	"surge_t", "next_event_t", "thief_t", "thieves", "wl_acc", "mini_last", "mini_chk", "rift_miss", "rift_check", "biome_idx", "world_seed", "balls"]


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


# Why the run cannot be saved right now, as English text for L.t(); "" when it can.
static func block_reason(m) -> String:
	if m.mode != "normal":
		return "Only Normal runs can be saved and resumed."
	if m.player.dead or m.timeup or m.down:
		return "You can't save now."
	if m.arena != null or m.jd.active() or m.dir_finale or m._boss_alive() or m.cal != null or m.eter_prompt or m.choosing:
		return "You can't save during a boss fight, rift or other special event."
	return ""


static func capture(m) -> Dictionary:
	var f := {}
	for k in FIELDS:
		f[String(k)] = _copy(m.get(String(k)))
	var p = m.player
	return {"v": VERSION, "saved": int(Time.get_unix_time_from_system()), "mode": m.mode, "hyper": m.hyper, "dex": SV.run_dex,
		"mods": m.mods.duplicate(), "f": f, "mega": m._mega_on(),
		"p": {"level": p.level, "xp": p.xp, "xp_next": p.xp_next, "hp": p.hp, "max_hp": p.max_hp, "slot": p.slot, "pos": p.position,
			"moves": _copy(p.moves), "types": _copy(p.types)}}


static func _copy(v):
	if v is Dictionary or v is Array:
		return v.duplicate(true)
	return v


# True if the value holds only plain data (no objects), so it survives var_to_str.
static func plain(v) -> bool:
	if v is Object:
		return false
	if v is Dictionary:
		for k in v:
			if not plain(k) or not plain(v[k]):
				return false
	elif v is Array:
		for x in v:
			if not plain(x):
				return false
	return true


static func save(m) -> bool:
	if block_reason(m) != "":
		return false
	var snap: Dictionary = capture(m)
	if not plain(snap):
		push_warning("run_save: snapshot holds an object; not saved")
		return false
	var f := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(var_to_str(snap))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH + ".tmp"), ProjectSettings.globalize_path(PATH))
	return true


static func load_snap() -> Dictionary:
	if not exists():
		return {}
	var v = str_to_var(FileAccess.get_file_as_string(PATH))
	if v is Dictionary and int(v.get("v", 0)) == VERSION and v.has("f") and v.has("p"):
		return v
	return {}


# Short description for the menu button.
static func describe(snap: Dictionary) -> String:
	if snap.is_empty():
		return ""
	var t: int = int(float(snap["f"].get("run_time", 0.0)) / (2.0 if bool(snap.get("hyper", false)) else 1.0))
	var name := "#%d" % int(snap["dex"])
	if SV.dex_by.has(int(snap["dex"])):
		name = L.t(String(SV.dex_by[int(snap["dex"])]["name"]))
	return "%s · %02d:%02d · %s" % [name, t / 60, t % 60, L.t("Lv. %d") % int(snap["p"]["level"])]


# Called at the end of Main._ready on a freshly built run: puts the saved progress back.
static func apply(m, snap: Dictionary) -> void:
	var f: Dictionary = snap["f"]
	var p = m.player
	var pd: Dictionary = snap["p"]
	# the map first (same seed = same terrain)
	m.world_seed = int(f["world_seed"])
	m.biome_idx = int(f["biome_idx"])
	m.ground.setup(m.world_seed)
	m.ground.set_biome(m.biome_idx, true)
	m._update_world(0.0)
	m.ground.flush_bake()
	# body forms (they rebuild the sprite, types and Judgment): Mega, Forme, Plate
	m.mega_done = bool(f["mega_done"])
	if bool(snap.get("mega", false)):
		m._mega_start()
	if String(f["forme"]) != "":
		m.forme = ""
		FM.apply(m, String(f["forme"]))
	if String(f.get("kyurem", "")) != "":
		m.kyurem = ""
		KYU.apply(m, String(f["kyurem"]), true)
	if String(f["plate"]) != "normal":
		m.plate = "normal"
		PL.apply(m, String(f["plate"]))
	# then every stored value over whatever those set up
	for k in FIELDS:
		if f.has(String(k)):   # a field added in a later version is simply absent from an older saved run
			m.set(String(k), _copy(f[String(k)]))
	p.moves = _copy(pd["moves"])
	p.slot = int(pd["slot"])
	p.level = int(pd["level"])
	p.xp = float(pd["xp"])
	p.xp_next = float(pd["xp_next"])
	p.types = _copy(pd["types"])
	p.max_hp = float(pd["max_hp"])
	p.hp = float(pd["hp"])
	p.position = pd["pos"]
	m._arrange()
	p.invuln = 2.0
	m.resumed = true
	m._say(L.t("Run resumed"), 3.0)
