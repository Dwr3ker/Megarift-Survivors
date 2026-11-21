extends RefCounted
# The right stick scrolls lists everywhere in the menus (main menu screens, pop-ups, the pause screen): the list that holds
# the selected control, or else the biggest scrollable list on screen. Faster the further it is pushed.

const DEAD := 0.25
const SPEED := 1100.0   # pixels per second at full push


static var fake := 0.0   # tests: a pretend push (no controller in headless runs)


# The right stick's vertical push from any controller (0 inside the dead zone).
static func push() -> float:
	if fake != 0.0:
		return fake
	for pd in Input.get_connected_joypads():
		var y: float = Input.get_joy_axis(int(pd), JOY_AXIS_RIGHT_Y)
		if absf(y) > DEAD:
			return y
	return 0.0


static func step(sc: ScrollContainer, y: float, delta: float) -> void:
	sc.scroll_vertical += int(signf(y) * (absf(y) - DEAD) / (1.0 - DEAD) * SPEED * delta + signf(y))


static func _can_scroll(sc: ScrollContainer) -> bool:
	if not sc.is_visible_in_tree() or sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return false
	var vb: VScrollBar = sc.get_v_scroll_bar()
	return vb != null and vb.max_value - vb.page > 1.0


# The list to scroll under `root`: the one holding the focused control, else the biggest scrollable one.
static func target(root: Node, vp: Viewport) -> ScrollContainer:
	var f: Control = vp.gui_get_focus_owner()
	if f != null and root.is_ancestor_of(f):
		var n: Node = f.get_parent()
		while n != null and n != root.get_parent():
			if n is ScrollContainer and _can_scroll(n):
				return n
			n = n.get_parent()
	var best: ScrollContainer = null
	var area := 0.0
	for c in root.find_children("*", "ScrollContainer", true, false):
		var sc := c as ScrollContainer
		if _can_scroll(sc):
			var a: float = sc.size.x * sc.size.y
			if a > area:
				area = a
				best = sc
	return best


# One frame of right-stick scrolling under `root`; true if it scrolled.
static func tick(root: Node, vp: Viewport, delta: float) -> bool:
	var y: float = push()
	if y == 0.0 or root == null:
		return false
	var sc: ScrollContainer = target(root, vp)
	if sc == null:
		return false
	step(sc, y, delta)
	return true
