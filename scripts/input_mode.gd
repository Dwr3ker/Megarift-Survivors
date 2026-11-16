extends RefCounted
# Which input you are using right now: "kb" (keyboard and mouse), "pad" (a controller) or "touch". The HUD and menus
# show the matching hints (keys, controller buttons or nothing) and switch as soon as you use another one or plug in /
# unplug a controller.

static var mode := ""
static var _pads := -1   # controllers connected the last time we looked


# Plugging a controller in switches to "pad", unplugging the last one switches back. This is checked by counting the
# controllers each time it's asked, not with a signal: a callback from a static script on Input's signal made the
# game crash when it closed (the script is freed before Input lets go of it).
static func current() -> String:
	var n: int = Input.get_connected_joypads().size()
	if mode == "":
		mode = "pad" if n > 0 else ("touch" if OS.has_feature("mobile") else "kb")
	elif _pads >= 0 and n != _pads:
		if n > _pads:
			mode = "pad"
		elif n == 0 and mode == "pad":
			mode = "touch" if OS.has_feature("mobile") else "kb"
	_pads = n
	return mode


static func is_pad() -> bool:
	return current() == "pad"


static func is_kb() -> bool:
	return current() == "kb"


# Feed every input event; returns true when the mode changed.
static func feed(ev: InputEvent) -> bool:
	var was: String = current()
	var now: String = was
	if ev is InputEventKey and ev.pressed:
		now = "kb"
	elif ev is InputEventMouseButton and ev.pressed and ev.device != InputEvent.DEVICE_ID_EMULATION:
		now = "kb"
	elif ev is InputEventMouseMotion and ev.device != InputEvent.DEVICE_ID_EMULATION and (ev as InputEventMouseMotion).relative.length() > 6.0:
		now = "kb"
	elif ev is InputEventJoypadButton and ev.pressed:
		now = "pad"
	elif ev is InputEventJoypadMotion and absf((ev as InputEventJoypadMotion).axis_value) > 0.5:
		now = "pad"
	elif ev is InputEventScreenTouch and ev.pressed and ev.device != InputEvent.DEVICE_ID_EMULATION:
		now = "touch"   # a real finger; the touch Godot makes from every mouse click (emulate_touch_from_mouse) is ignored
	mode = now
	return now != was
