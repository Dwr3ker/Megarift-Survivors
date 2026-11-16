extends RefCounted
# Paths around walls on the open map. A breadth-first walk over the tile grid from the player's tile, up to R tiles out,
# gives every reachable tile its walking distance (in steps) to you. Pokémon that walk to you (enemies, your co-op
# partner) use it only when walls are in the way: if their walking distance is longer than the straight line,
# they head for the neighbouring tile that is one step closer, so they go around the wall instead of pushing into it.
# Rebuilt when you step onto another tile, at most every REBUILD seconds. Not used inside rifts (small round arenas).

const R := 22                # tiles out from you (the screen is about 27 x 15 tiles)
const REBUILD := 0.4
const W := 2 * R + 1
const UNSEEN := -1

var m = null
var origin := Vector2i(1 << 30, 0)   # the player's tile when it was built
var dist := PackedInt32Array()
var wait := 0.0
var builds := 0                       # for tests


func _init() -> void:
	dist.resize(W * W)
	dist.fill(UNSEEN)


func _wall(tx: int, ty: int) -> bool:
	return m.ground.terrain(tx, ty) == 1   # tileworld.WALL


func update(delta: float) -> void:
	wait -= delta
	if m.arena != null or m.ground == null or m.player == null:
		return
	var pt: Vector2i = m.ground.tile_of(m.player.position)
	if pt == origin or wait > 0.0:
		return
	build(pt)


func build(pt: Vector2i) -> void:
	wait = REBUILD
	origin = pt
	builds += 1
	dist.fill(UNSEEN)
	var q := PackedInt32Array()
	var c0: int = R * W + R
	dist[c0] = 0
	q.append(c0)
	var head := 0
	while head < q.size():
		var c: int = q[head]
		head += 1
		var cx: int = c % W
		var cy: int = c / W
		var nd: int = dist[c] + 1
		for k in range(4):
			var nx: int = cx + (1 if k == 0 else (-1 if k == 1 else 0))
			var ny: int = cy + (1 if k == 2 else (-1 if k == 3 else 0))
			if nx < 0 or ny < 0 or nx >= W or ny >= W:
				continue
			var ni: int = ny * W + nx
			if dist[ni] != UNSEEN:
				continue
			if _wall(origin.x + nx - R, origin.y + ny - R):
				dist[ni] = -2   # wall: never a step
				continue
			dist[ni] = nd
			q.append(ni)


func steps_at(t: Vector2i) -> int:
	var lx: int = t.x - origin.x + R
	var ly: int = t.y - origin.y + R
	if lx < 0 or ly < 0 or lx >= W or ly >= W:
		return UNSEEN
	return dist[ly * W + lx]


const TS := 48.0
const LOOK := 3              # aim at the tile this many steps along the path (smoother than the next tile)


# True when the straight line from pos to the player (or to `goal`) crosses a wall tile (a little wider than a Pokémon).
func blocked(pos: Vector2, goal: Vector2 = Vector2.INF) -> bool:
	var to: Vector2 = (m.player.position if goal == Vector2.INF else goal) - pos
	var n: int = maxi(1, ceili(to.length() / (TS * 0.5)))
	var side: Vector2 = Vector2(-to.y, to.x).normalized() * TS * 0.3
	for i in range(1, n):
		var q: Vector2 = pos + to * (float(i) / float(n))
		for off in [Vector2.ZERO, side, -side]:
			if steps_at(m.ground.tile_of(q + off)) == -2:
				return true
	return false


# Direction to walk from pos toward the player around walls, or ZERO when the straight line is clear (or pos is outside
# the field: the caller walks straight, as before).
func dir_for(pos: Vector2) -> Vector2:
	if m.arena != null or origin.x == (1 << 30):
		return Vector2.ZERO
	var t: Vector2i = m.ground.tile_of(pos)
	var s: int = steps_at(t)
	if s <= 0 or not blocked(pos):
		return Vector2.ZERO
	var cur: Vector2i = t
	var path: Array = []
	for step in range(LOOK):
		var best := Vector2i.ZERO
		var bs: int = steps_at(cur)
		for k in range(8):
			var d := Vector2i([1, -1, 0, 0, 1, 1, -1, -1][k], [0, 0, 1, -1, 1, -1, 1, -1][k])
			var ns: int = steps_at(cur + d)
			if ns < 0 or ns >= bs:
				continue
			if d.x != 0 and d.y != 0 and (steps_at(cur + Vector2i(d.x, 0)) < 0 or steps_at(cur + Vector2i(0, d.y)) < 0):
				continue   # no cutting a wall corner diagonally
			bs = ns
			best = d
		if best == Vector2i.ZERO:
			break
		cur += best
		path.append(cur)
		if bs == 0:
			break
	if path.is_empty():
		return Vector2.ZERO
	# aim at the farthest of those tiles you can see in a straight line (no cutting a wall corner); else the next one
	var aim: Vector2i = path[0]
	for i in range(path.size() - 1, 0, -1):
		var g := Vector2((float(path[i].x) + 0.5) * TS, (float(path[i].y) + 0.5) * TS)
		if not blocked(pos, g):
			aim = path[i]
			break
	var goal := Vector2((float(aim.x) + 0.5) * TS, (float(aim.y) + 0.5) * TS)
	return (goal - pos).normalized()
