extends Control
# Crash reporter. A run drops a flag file when it starts and removes it when it ends normally. If the flag is still there at the next
# launch the run ended unexpectedly (crash, kill), and this screen shows the end of the previous session's log so it can be
# photographed or copied. Logging to file is switched on for mobile in project.godot (debug/file_logging).
const L = preload("res://scripts/lang.gd")
const FLAG := "user://run.flag"
const LOG_DIR := "user://logs"
const TAIL_LINES := 28


static func mark_run_start() -> void:
	if not OS.has_feature("mobile") and OS.get_environment("MEGARIFT_CRASH_TEST") == "":
		return   # desktop and headless tests never leave a flag behind
	var f := FileAccess.open(FLAG, FileAccess.WRITE)
	if f != null:
		f.store_string(str(Time.get_unix_time_from_system()))


static func mark_run_end() -> void:
	if FileAccess.file_exists(FLAG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FLAG))


# True when the previous run did not end normally. Clears the flag so the report shows once.
static func take_crash_flag() -> bool:
	if not FileAccess.file_exists(FLAG):
		return false
	mark_run_end()
	return true


# The newest rotated log (the previous session); godot.log is the current one.
static func previous_log_tail(lines: int = TAIL_LINES) -> String:
	var d := DirAccess.open(LOG_DIR)
	if d == null:
		return ""
	var names: Array = []
	for n in d.get_files():
		if n.begins_with("godot") and n.ends_with(".log") and n != "godot.log":
			names.append(n)
	if names.is_empty():
		return ""
	names.sort()
	var f := FileAccess.open(LOG_DIR + "/" + String(names[names.size() - 1]), FileAccess.READ)
	if f == null:
		return ""
	var all: PackedStringArray = f.get_as_text().split("\n")
	var keep: Array = []
	for ln in all:
		var t: String = ln.strip_edges()
		if t == "" or t.begins_with("at: ") or t.contains("Parameter \"t\" is null"):
			continue
		keep.append(t.substr(0, 160))
	return "\n".join(PackedStringArray(keep.slice(maxi(0, keep.size() - lines))))


var _text := ""


func build(log_text: String) -> void:
	_text = log_text
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 4000
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40.0
	panel.offset_right = -40.0
	panel.offset_top = 24.0
	panel.offset_bottom = -24.0
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = L.t("The last run ended unexpectedly")
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var sub := Label.new()
	sub.text = L.t("Please send a photo of this screen. The end of the log shows where it stopped ([run] lines show the run clock).")
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 16)
	box.add_child(sub)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(sc)
	var lbl := Label.new()
	lbl.text = log_text if log_text != "" else L.t("(no log was saved)")
	lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	sc.add_child(lbl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var close := Button.new()
	close.text = L.t("Close")
	close.custom_minimum_size = Vector2(200, 52)
	close.pressed.connect(queue_free)
	row.add_child(close)
	var copy := Button.new()
	copy.text = L.t("Copy log")
	copy.custom_minimum_size = Vector2(200, 52)
	copy.pressed.connect(func(): DisplayServer.clipboard_set(_text))
	row.add_child(copy)
	close.call_deferred("grab_focus")
