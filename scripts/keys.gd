extends RefCounted
# Keyboard bindings for PC. Each in-run action has one key (Settings > Controls > Keyboard); a few keys are fixed
# (Enter / Space confirm, Backspace / X back, P also opens Options). Stored in settings["keymap"] as action -> keycode.

const SV = preload("res://scripts/save_data.gd")

const ACTIONS := ["options", "summary", "prev", "next", "zmove", "dynamax", "dash", "swap", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6"]
const LABELS := {
	"options": "Options (pause)",
	"summary": "Build summary",
	"prev": "Previous move",
	"next": "Next move",
	"zmove": "Z-Move",
	"dynamax": "Dynamax",
	"dash": "Dash",
	"swap": "Switch Pokémon (Team Mode)",
	"slot1": "Select move 1", "slot2": "Select move 2", "slot3": "Select move 3",
	"slot4": "Select move 4", "slot5": "Select move 5", "slot6": "Select move 6",
}


static func defaults() -> Dictionary:
	return {"options": KEY_ESCAPE, "summary": KEY_TAB, "prev": KEY_Q, "next": KEY_E, "zmove": KEY_Z, "dynamax": KEY_C, "dash": KEY_SHIFT, "swap": KEY_R,
		"slot1": KEY_1, "slot2": KEY_2, "slot3": KEY_3, "slot4": KEY_4, "slot5": KEY_5, "slot6": KEY_6}


static func key(action: String) -> int:
	SV.ensure()
	var m = SV.d["settings"].get("keymap", {})
	if m is Dictionary and m.has(action):
		return int(m[action])
	return int(defaults()[action])


# The action a key is bound to, or "" when it is not bound.
static func action_of(code: int) -> String:
	for a in ACTIONS:
		if key(a) == code:
			return a
	return ""


# Binds a key to an action; if another action had that key, the two swap.
static func set_key(action: String, code: int) -> void:
	SV.ensure()
	var cur := {}
	for a in ACTIONS:
		cur[a] = key(a)
	var old: int = int(cur[action])
	for a in ACTIONS:
		if a != action and int(cur[a]) == code:
			cur[a] = old
	cur[action] = code
	SV.d["settings"]["keymap"] = cur
	SV.save()


static func reset() -> void:
	SV.ensure()
	SV.d["settings"]["keymap"] = defaults()
	SV.save()


static func key_name(code: int) -> String:
	return OS.get_keycode_string(code)
