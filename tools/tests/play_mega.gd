extends SceneTree
# Windowed hand-test launcher: starts a normal run directly (skips menus) with a chosen Pokemon.
#   godot --path . --script res://tools/tests/play_mega.gd -- 6 [hyper]   (dex number, default 6 = Charizard; optional Hyper mode)
func _init() -> void:
	var SV = load("res://scripts/save_data.gd")
	SV.ensure()
	var args := OS.get_cmdline_user_args()
	SV.run_dex = int(args[0]) if args.size() > 0 else 6
	SV.run_hyper = args.size() > 1 and String(args[1]) == "hyper"
	var m = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(m)
	var k := Node.new()
	k.set_script(load("res://tools/tests/play_mega_keys.gd"))
	k.m = m
	root.add_child(k)
