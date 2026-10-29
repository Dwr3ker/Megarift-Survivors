extends SceneTree
# Headless check of the keyboard bindings, the pause tabs (Tab / Select = summary, Esc / Start = options), the boss HP bar,
# the slower menu stick and the "run in progress" reminder.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e

func _new_run(SV, dex: int):
	SV.run_dex = dex
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(12):
		await process_frame
	for id in ["wave", "rift", "meowth", "boss", "map", "eter"]:
		m.dir_done[id] = true
	m.rift_check = 1.0e9
	m.jd.done = true
	return m

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var KB = load("res://scripts/keys.gd")
	var PAD = load("res://scripts/pad.gd")
	var RS = load("res://scripts/run_save.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	SV.d = SV.default_data()
	var had_real: bool = RS.exists()
	var real_text: String = FileAccess.get_file_as_string(RS.PATH) if had_real else ""
	RS.clear()
	# ---------- keyboard bindings ----------
	check("defaults: Tab = summary, Esc = options, Q / E = cycle", KB.key("summary") == KEY_TAB and KB.key("options") == KEY_ESCAPE and KB.key("prev") == KEY_Q and KB.key("next") == KEY_E)
	KB.set_key("zmove", KEY_F)
	check("a key can be rebound", KB.key("zmove") == KEY_F and KB.action_of(KEY_F) == "zmove" and KB.action_of(KEY_Z) == "")
	KB.set_key("dash", KEY_F)
	check("assigning a used key swaps the two actions", KB.key("dash") == KEY_F and KB.key("zmove") == KEY_SHIFT)
	KB.reset()
	check("reset restores the defaults", KB.key("dash") == KEY_SHIFT and KB.key("zmove") == KEY_Z)
	# ---------- gamepad: Select = summary, Start = options, Dynamax off Select ----------
	check("pad defaults: Select = summary, Start = options, Dynamax not on Select", PAD.btn("summary") == JOY_BUTTON_BACK and PAD.btn("pause") == JOY_BUTTON_START and PAD.btn("dynamax") != JOY_BUTTON_BACK)
	SV.d["settings"]["padmap"] = {"prev": 9, "next": 10, "pause": 6, "confirm": 0, "cancel": 1, "reroll": 3, "ban": 2, "swap": 8, "zmove": 7, "dynamax": 4, "dash": 1}
	PAD.apply()
	var mm: Dictionary = SV.d["settings"]["padmap"]
	check("an older saved map is migrated (summary on Select, Dynamax moved)", int(mm["summary"]) == JOY_BUTTON_BACK and int(mm["dynamax"]) != JOY_BUTTON_BACK, str(mm.get("dynamax")))
	SV.d["settings"].erase("padmap")
	check("the stick repeats slowly in menus", PAD.STICK_DELAY >= 0.5 and PAD.STICK_REPEAT >= 0.25)
	# ---------- pause tabs ----------
	var m = await _new_run(SV, 6)
	m._unhandled_input(_key(KEY_TAB))
	await process_frame
	await process_frame
	check("Tab opens the pause on the Build summary", m.paused and m.pause_ui.visible and m.pause_ui.tab == 0)
	m._unhandled_input(_key(KEY_ESCAPE))
	await process_frame
	check("Esc while on the summary switches to Options", m.paused and m.pause_ui.tab == 1)
	m._unhandled_input(_key(KEY_ESCAPE))
	await process_frame
	await process_frame
	check("Esc on Options resumes", not m.paused)
	m._unhandled_input(_key(KEY_ESCAPE))
	await process_frame
	await process_frame
	check("Esc in a run opens Options", m.paused and m.pause_ui.visible and m.pause_ui.tab == 1)
	m._unhandled_input(_key(KEY_TAB))
	await process_frame
	check("Tab while on Options switches to the summary", m.paused and m.pause_ui.tab == 0)
	m._unhandled_input(_key(KEY_TAB))
	await process_frame
	check("Tab on the summary resumes", not m.paused)
	# ---------- boss HP bar ----------
	check("no bar without a boss", m.hud.boss_max == 0.0)
	var b = m._spawn_boss({"at": 0.0, "dex": 150, "name": "Mewtwo", "hp": 2000.0, "spd": 50.0, "dmg": 20.0, "xp": 500.0, "behavior": "chase", "shotDmg": 10.0, "shotCd": 1.1, "range": 260.0})
	await process_frame
	await process_frame
	check("a boss fills the top bar", m.hud.boss_max > 0.0 and m.hud.boss_name == "Mewtwo", "%.0f %s" % [m.hud.boss_max, m.hud.boss_name])
	var vp := Vector2(1280, 720)
	var y0: float = m.hud.boss_bar_y(vp)
	m.hud.dyn_left = 10.0
	var y1: float = m.hud.boss_bar_y(vp)
	check("the bar sits below the Dynamax bar", y1 >= m.hud.DYN_BAR_Y + 22.0 and y1 > y0, "%.0f -> %.0f" % [y0, y1])
	m.hud.rift_notice = 2.0
	check("and below the rift notice", m.hud.boss_bar_y(vp) >= m.hud.notice_cy(vp) + 34.0)
	check("the banner stays under the bar", m.hud.banner_y(vp) >= m.hud.boss_bar_y(vp) + 40.0)
	m.hud.dyn_left = -1.0
	m.hud.rift_notice = -1.0
	b.dead = true
	await process_frame
	await process_frame
	check("the bar disappears when the boss dies", m.hud.boss_max == 0.0)
	m.queue_free()
	await process_frame
	# ---------- the run reminder ----------
	var m2 = await _new_run(SV, 6)
	m2.run_time = 400.0
	m2.player.level = 9
	check("setup: a run can be saved", RS.save(m2))
	m2.queue_free()
	await process_frame
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._ongoing_prompt()
	await process_frame
	check("the reminder opens when a run is waiting", is_instance_valid(menu.run_prompt))
	var btns: Array = menu.run_prompt.find_children("*", "Button", true, false)
	check("it offers Resume and Give up", btns.size() == 2, str(btns.size()))
	var gave := [false]
	menu.run_prompt.queue_free()
	await process_frame
	menu._ongoing_prompt(func(): gave[0] = true)
	await process_frame
	btns = menu.run_prompt.find_children("*", "Button", true, false)
	(btns[1] as Button).pressed.emit()
	await process_frame
	check("Give up removes the saved run and continues", not RS.exists() and bool(gave[0]))
	menu._ongoing_prompt()
	await process_frame
	check("no reminder without a saved run", not is_instance_valid(menu.run_prompt) or menu.run_prompt.is_queued_for_deletion())
	menu.queue_free()
	await process_frame
	# ---------- restore ----------
	RS.clear()
	if had_real:
		var rf := FileAccess.open(RS.PATH, FileAccess.WRITE)
		rf.store_string(real_text)
		rf.close()
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
