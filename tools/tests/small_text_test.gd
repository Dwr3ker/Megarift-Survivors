extends SceneTree
# Small text: at 15 px or less the pixel font is drawn at exactly 12 px (its grid) without the extra boldness.
var ok := true
func check(name: String, cond: bool, detail: String = "") -> void:
	print(("PASS  " if cond else "FAIL  ") + name + ("  " + detail if detail != "" else ""))
	if not cond: ok = false

func _init() -> void:
	Engine.set_meta("no_save", true)
	var PXF = load("res://scripts/pxfont.gd")
	var f: Font = PXF.get_font()
	var fs: Font = PXF.get_small()
	check("the small font is the same font without the extra boldness", fs is FontVariation and f is FontVariation and (fs as FontVariation).variation_embolden == 0.0 and (f as FontVariation).variation_embolden > 0.0)
	check("small sizes snap to the 12 px grid, larger ones are kept", PXF.px_size(9) == 12 and PXF.px_size(15) == 12 and PXF.px_size(16) == 16 and PXF.px_size(22) == 22)
	check("small text uses the thin font, large text the bold one", PXF.font_for(f, 10) == fs and PXF.font_for(f, 22) == f)
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	SV.d = SV.default_data()
	SV.d["nick"] = "Ash"
	var menu = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in range(10):
		await process_frame
	var l: Label = menu._label("Tiny", 10)
	var big: Label = menu._label("Big", 24)
	check("a small menu label is drawn at 12 px with the thin font", l.get_theme_font_size("font_size") == 12 and l.get_theme_font("font") == fs)
	check("a big menu label keeps its size and the bold font", big.get_theme_font_size("font_size") == 24 and not big.has_theme_font_override("font"))
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
