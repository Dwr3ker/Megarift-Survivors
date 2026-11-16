extends Node2D
# Wardrobe in runs (docs/wardrobe.md): the equipped trail and aura of the Pokémon you control. This node sits right above
# the ground and under every other layer (ground effects with the attack warnings, attacks, Pokémon), so a cosmetic can
# never hide a warning. The trail drops a particle every few pixels you move and they fade out in under a second, so it
# fades away when you stand still. The Effects quality setting thins the particles out.
const WR = preload("res://scripts/wardrobe.gd")

const LIFE := 0.9
const SPACING := 14.0   # pixels moved per particle (High quality)
const CAP := 64

var m   # main
var trail := ""
var aura := ""
var bits: Array = []   # [pos, born, seed]
var t := 0.0
var _last := Vector2.INF
var _seed := 0
var _q := 1.0          # particle density from the Effects quality setting
var spawned := 0       # for the test


func setup(main) -> void:
	m = main
	trail = WR.equipped("trail")
	aura = WR.equipped("aura")
	_q = [1.0, 1.0, 0.6, 0.35][clampi(int(main.quality), 0, 3)]
	z_index = 0


func _process(delta: float) -> void:
	t += delta
	var p = m.player if m != null else null
	if p == null or not is_instance_valid(p):
		return
	var feet: Vector2 = p.position
	if trail != "" and not bool(p.dead):
		if _last == Vector2.INF:
			_last = feet
		var step: float = SPACING / _q
		var moved: float = _last.distance_to(feet)
		if moved > 300.0:   # a teleport (rift, cave): start again there
			_last = feet
		while _last.distance_to(feet) >= step:
			_last = _last.move_toward(feet, step)
			_seed += 1
			bits.append([_last + Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0)), t, _seed])
			spawned += 1
		while bits.size() > CAP:
			bits.pop_front()
	while not bits.is_empty() and t - float(bits[0][1]) > LIFE:
		bits.pop_front()
	queue_redraw()


func _draw() -> void:
	var p = m.player if m != null else null
	if p != null and is_instance_valid(p) and aura != "" and not bool(p.dead):
		var w: float = maxf(16.0, float(p.radius) * 1.25)
		WR.draw_aura(self, aura, p.position, w, t, _q)
	for b in bits:
		WR.draw_trail_bit(self, trail, b[0], clampf((t - float(b[1])) / LIFE, 0.0, 1.0), int(b[2]), 1.3)
