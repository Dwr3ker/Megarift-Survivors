extends SceneTree
# Headless check of the HUD layout: data model, presets, migration, the run HUD obeying it, and the editor.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)   # nothing here may write the real save
	var SV = load("res://scripts/save_data.gd")
	var HL = load("res://scripts/hud_layout.gd")
	SV.ensure()
	var _guard: Dictionary = SV.d.duplicate(true)
	# ---------- migration from the old per-element sliders ----------
	SV.d["settings"].erase("hud_layout")
	SV.d["settings"]["hud_plate"] = 130
	SV.d["settings"]["hud_radar"] = 80
	check("old size sliders migrate into the layout", HL.scale_of("plate") == 1.3 and HL.scale_of("radar") == 0.8 and HL.scale_of("stats") == 1.0)
	check("a fresh layout has no offsets", HL.offset("plate") == Vector2.ZERO and HL.offset("skills") == Vector2.ZERO)
	# ---------- editing ----------
	HL.set_el("stats", Vector2(-120.0, 60.0), 85)
	check("moving and sizing an element is stored", HL.offset("stats") == Vector2(-120.0, 60.0) and HL.scale_of("stats") == 0.85)
	HL.set_el("stats", Vector2(99999.0, -99999.0), 500)
	check("offsets and sizes are clamped", absf(HL.offset("stats").x) <= HL.MAX_OFF and absf(HL.offset("stats").y) <= HL.MAX_OFF and HL.scale_of("stats") == 1.5)
	HL.set_el("stats", Vector2(-120.0, 60.0), 85)
	HL.set_show_map(false)
	check("the radar can be turned off", not HL.show_map() and not HL.is_default())
	# ---------- presets ----------
	check("an empty preset name is refused", not HL.save_preset("   "))
	check("saving a preset works", HL.save_preset("Streamer") and HL.preset_names() == ["Streamer"] and HL.active_preset() == "Streamer")
	HL.reset_all()
	check("reset all restores the defaults and the radar", HL.is_default() and HL.show_map() and HL.offset("stats") == Vector2.ZERO)
	check("loading a preset restores layout, radar and sizes", HL.load_preset("Streamer") and HL.offset("stats") == Vector2(-120.0, 60.0) and HL.scale_of("stats") == 0.85 and not HL.show_map())
	for i in range(HL.MAX_PRESETS + 2):
		HL.save_preset("P%d" % i)
	check("the preset list is capped", HL.presets().size() <= HL.MAX_PRESETS)
	check("deleting a preset works", HL.delete_preset("Streamer") and not HL.presets().has("Streamer"))
	check("a missing preset cannot be loaded", not HL.load_preset("nope"))
	HL.reset_all()
	# ---------- the run HUD follows the layout ----------
	SV.run_dex = 6
	SV.run_mode = "normal"
	SV.run_hyper = false
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	for i in range(15):
		await process_frame
	var pos0: Vector2 = m.mini.position
	var slots0: Vector2 = m.slots.position
	HL.set_el("radar", Vector2(200.0, 40.0), 100)
	HL.set_el("skills", Vector2(-80.0, -30.0), 100)
	HL.set_el("stats", Vector2(-50.0, 20.0), 100)
	for i in range(4):
		await process_frame
	check("the radar moves with its offset", m.mini.position.is_equal_approx(pos0 + Vector2(200.0, 40.0)), str(m.mini.position - pos0))
	check("the move bar moves with its offset", m.slots.position.is_equal_approx(slots0 + Vector2(-80.0, -30.0)))
	check("the HUD gets the offsets", m.hud.off_stats == Vector2(-50.0, 20.0))
	HL.set_show_map(false)
	for i in range(4):
		await process_frame
	check("turning the radar off hides it", not m.mini.visible and not m.hud.show_map)
	HL.set_show_map(true)
	HL.set_el("counters", Vector2(0.0, 0.0), 130)
	for i in range(4):
		await process_frame
	check("sizes reach the HUD", absf(m.hud.sc_cnt - 1.3) < 0.01, str(m.hud.sc_cnt))
	HL.reset_all()
	m.queue_free()
	await process_frame
	# ---------- the editor screen ----------
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(20):
		await process_frame
	menu._show("layout")
	for i in range(8):
		await process_frame
	var ed = menu.layout_ed
	check("the layout screen exists with a stage and six element buttons", ed != null and ed.stage != null and ed.el_btns.size() == 6)
	ed._select("items")
	ed._nudge(Vector2(40.0, 24.0))
	check("nudging moves the selected element", HL.offset("items") == Vector2(40.0, 24.0), str(HL.offset("items")))
	ed._resize(20)
	check("resizing changes its size", HL.scale_of("items") == 1.2)
	ed._nudge(Vector2(-99999.0, 99999.0))
	var r: Rect2 = ed._box("items")
	check("an element cannot be pushed fully off screen", r.end.x > 0.0 and r.position.y < ed._vp.y)
	ed.name_in.text = "Mine"
	ed._save_preset()
	check("the editor saves a preset", HL.presets().has("Mine"))
	HL.reset_all()
	ed.refresh()
	for pi in range(ed.preset_pick.item_count):
		if ed.preset_pick.get_item_text(pi) == "Mine":
			ed.preset_pick.select(pi)
	ed._load_preset()
	check("the editor loads it back", HL.offset("items") != Vector2.ZERO)
	# settings screen: the per-element sliders are gone, the editor button is there
	menu.set_tab = 1
	menu._refresh_settings()
	for i in range(3):
		await process_frame
	var found_btn := false
	var found_slider := false
	for n in menu.screens["settings"].find_children("*", "Button", true, false):
		if (n as Button).text == "Edit HUD layout":
			found_btn = true
	check("Settings > Graphics has the Edit HUD layout button", found_btn)
	menu.queue_free()
	await process_frame
	SV.d = _guard
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
