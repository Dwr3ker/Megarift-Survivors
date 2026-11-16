extends RefCounted
# Aurora night event (docs/aurora.md). Some nights the sky lights up with ribbons of green and violet light for a
# short while: wild shinies are much more likely and experience is a bit higher until it fades. Runs on the run clock
# (run_time), so pausing freezes it; inside rifts, caves and the Tower it waits, hidden.

const CHANCE := 0.4          # chance per night
const START_MIN := 20.0      # seconds into the night it can begin...
const START_MAX := 100.0     # ...and the latest
const DUR := 50.0            # how long it shines
const FADE := 4.0            # fade in / out
const SHINY_K := 8.0         # wild shiny odds while it shines
const XP_K := 1.25           # experience while it shines
const TINT := Color(0.03, 0.12, 0.25, 0.46)   # the night tint shifts toward teal and stays dark

var m = null
var sky: Control = null
var t := -1.0                # seconds since it began; < 0 = not shining
var plan_at := -1.0          # run_time it begins tonight (-1 = no Aurora tonight)
var night_seen := -1         # which night (cycle index) was already rolled
var count := 0               # Auroras this run


func setup() -> void:
	sky = AuroraSky.new()
	sky.a = self
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.ui_layer.add_child(sky)
	m.ui_layer.move_child(sky, 1)   # just above the day/night tint, under the HUD


func _blocked() -> bool:
	return m.arena != null or m.mode == "tower"


func active() -> bool:
	return t >= 0.0 and t < DUR and not _blocked()


func left() -> float:
	return maxf(0.0, DUR - t) if t >= 0.0 else 0.0


# 0..1 brightness of the sky (fades in and out)
func level() -> float:
	if t < 0.0 or _blocked():
		return 0.0
	return clampf(minf(t / FADE, (DUR - t) / FADE), 0.0, 1.0)


func shiny_k() -> float:
	return SHINY_K if active() else 1.0


func xp_k() -> float:
	return XP_K if active() else 1.0


# Starts it now (tests and the forced roll both come through here).
func start() -> void:
	t = 0.0
	plan_at = -1.0
	count += 1
	m.ach_event("aurora", {})   # first: the Aurora's own line wins the banner
	m._say(m.L.t("Aurora! Shiny odds ×%d while it shines") % int(SHINY_K), 3.4)
	m.Aud.sfx("shiny")


func update(delta: float) -> void:
	if _blocked():
		if sky != null:
			sky.visible = false
		return   # waits: the clock only runs outside
	var rt: float = m.run_time
	var cyc: int = floori(rt / m.dn.CYCLE)
	var c: float = fposmod(rt, m.dn.CYCLE)
	if t < 0.0 and m.dn.is_night() and cyc != night_seen:
		night_seen = cyc
		plan_at = -1.0
		if randf() < CHANCE:
			var at: float = randf_range(START_MIN, START_MAX)
			plan_at = rt - (c - m.dn.P_DUSK) + at
	if t < 0.0 and plan_at >= 0.0 and rt >= plan_at and m.dn.is_night():
		start()
	if t >= 0.0:
		t += delta
		if t >= DUR:
			t = -1.0
			m._say(m.L.t("The Aurora fades."), 2.2)
	var lv: float = level()
	if sky != null:
		sky.visible = lv > 0.0
		if lv > 0.0:
			sky.queue_redraw()
	if lv > 0.0 and m.dn.rect != null:
		m.dn.rect.color = m.dn.rect.color.lerp(TINT, lv * 0.6)


# The ribbons: three curtains of light across the top of the screen, waving slowly, each column flickering on its own.
# Drawn in screen space, translucent, and only over the top ~40% of the screen, so nothing below is hidden.
class AuroraSky extends Control:
	var a = null
	const BANDS := [
		[Color("#5dffb0"), 0.08, 0.20, 0.0013, 0.21, 0.55],
		[Color("#7fe8ff"), 0.15, 0.15, 0.0021, -0.15, 0.50],
		[Color("#c38bff"), 0.05, 0.13, 0.0017, 0.11, 0.48],
	]

	func _draw() -> void:
		if a == null:
			return
		var lv: float = a.level()
		if lv <= 0.0:
			return
		var vp: Vector2 = size
		var tm: float = Time.get_ticks_msec() / 1000.0
		var q: int = clampi(int(a.m.quality), 0, 3)
		var step: float = [6.0, 6.0, 10.0, 16.0][q]
		for bi in range(BANDS.size()):
			var b: Array = BANDS[bi]
			var col: Color = b[0]
			var top_y: float = vp.y * float(b[1])
			var h: float = vp.y * float(b[2])
			var f: float = float(b[3])
			var sp: float = float(b[4])
			var al: float = float(b[5]) * lv
			var tops := PackedVector2Array()
			var bots := PackedVector2Array()
			var tcol := PackedColorArray()
			var bcol := PackedColorArray()
			var x := -step
			while x <= vp.x + step:
				var w: float = sin(x * f * 6.0 + tm * sp * 2.0 + bi) * 0.6 + sin(x * f * 2.3 - tm * sp * 1.3 + bi * 2.0) * 0.4
				var y: float = top_y + h + w * vp.y * 0.05   # the bright lower edge; the rays fade upward
				var flick: float = (0.6 + 0.4 * sin(x * 0.043 + tm * (1.1 + bi * 0.37)) * sin(x * 0.011 - tm * 0.6 + bi)) * (0.72 + 0.28 * sin(x * 0.9 + tm * 2.0 + bi))
				var hh: float = h * (0.75 + 0.35 * sin(x * 0.007 + tm * 0.4 + bi * 1.7))
				var px: float = floorf(x / 2.0) * 2.0   # pixel-snapped columns
				tops.append(Vector2(px, floorf(y / 2.0) * 2.0))
				bots.append(Vector2(px, floorf((y - hh) / 2.0) * 2.0))
				tcol.append(Color(col.r, col.g, col.b, al * clampf(flick, 0.15, 1.0)))
				bcol.append(Color(col.r, col.g, col.b, 0.0))
				x += step
			# one quad per column keeps the polygon simple even where the wave folds
			for i in range(tops.size() - 1):
				var pts := PackedVector2Array([tops[i], tops[i + 1], bots[i + 1], bots[i]])
				var cs := PackedColorArray([tcol[i], tcol[i + 1], bcol[i + 1], bcol[i]])
				draw_polygon(pts, cs)
			# a bright hem along the lower edge of the first ribbon, like the edge of a curtain
			if bi == 0:
				for i in range(tops.size() - 1):
					var c2: Color = tcol[i]
					c2.a *= 0.9
					draw_line(tops[i], tops[i + 1], Color(0.85, 1.0, 0.92, c2.a * 0.8), 2.0)
