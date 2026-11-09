extends RefCounted
# Hovering a button with the mouse: it grows a little and brightens, so it is obvious what you are pointing at
# (the slightly lighter blue of the hover style alone was too subtle). Works on every button, whatever its style.
# The controller / keyboard keep the gold focus ring; this is for the mouse.

const GROW := 1.05
const BRIGHT := Color(1.18, 1.18, 1.18)
const T_IN := 0.08
const T_OUT := 0.12


# Every button already under `root` and every one added later.
static func hook(root: Node) -> void:
	if OS.has_feature("mobile"):
		return   # a tap counts as a hover on a touch screen and would leave the button grown
	var tree: SceneTree = root.get_tree()
	_scan(root)
	var cb := func(n: Node):
		if n is BaseButton and root.is_ancestor_of(n):
			attach(n)
	tree.node_added.connect(cb)
	root.tree_exiting.connect(func():
		if tree.node_added.is_connected(cb):
			tree.node_added.disconnect(cb))


static func _scan(n: Node) -> void:
	if n is BaseButton:
		attach(n)
	for c in n.get_children():
		_scan(c)


static func attach(b: BaseButton) -> void:
	if b.has_meta("hover_fx"):
		return
	b.set_meta("hover_fx", true)
	b.mouse_entered.connect(func(): _on(b, true))
	b.mouse_exited.connect(func(): _on(b, false))
	b.tree_exiting.connect(func(): _on(b, false, true))


static func _on(b: BaseButton, enter: bool, now: bool = false) -> void:
	if not is_instance_valid(b):
		return
	if b.has_meta("hover_tw"):   # (get_meta with a null default still logs an error when the key is missing)
		var tw0 = b.get_meta("hover_tw")
		if tw0 != null and is_instance_valid(tw0):
			(tw0 as Tween).kill()
	if enter:
		if b.disabled or not b.is_visible_in_tree():
			return
		if not b.has_meta("hover_base"):
			b.set_meta("hover_base", [b.scale, b.self_modulate])
		b.pivot_offset = b.size * 0.5
		var base: Array = b.get_meta("hover_base")
		var tw: Tween = b.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", (base[0] as Vector2) * GROW, T_IN)
		tw.tween_property(b, "self_modulate", (base[1] as Color) * BRIGHT, T_IN)
		b.set_meta("hover_tw", tw)
		b.z_index = maxi(b.z_index, 1) if b.z_as_relative else b.z_index   # draw over its neighbours while grown
	else:
		if not b.has_meta("hover_base"):
			return
		var base2: Array = b.get_meta("hover_base")
		b.remove_meta("hover_base")
		if b.z_index == 1:
			b.z_index = 0
		if now or not b.is_inside_tree():
			b.scale = base2[0]
			b.self_modulate = base2[1]
			return
		var tw2: Tween = b.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw2.tween_property(b, "scale", base2[0], T_OUT)
		tw2.tween_property(b, "self_modulate", base2[1], T_OUT)
		b.set_meta("hover_tw", tw2)
