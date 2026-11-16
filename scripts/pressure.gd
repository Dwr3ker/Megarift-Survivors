extends RefCounted
# Pressure (docs/late_challenge.md): keeps a maxed-out Pokémon busy in Normal runs. It rises (p, 0 to 5) when you are
# clearly overpowered: the screen is full and you barely take damage (under UNTOUCHED of your max HP in 20 s), or regular
# enemies die almost as soon as they appear. Then new spawns come faster, more at once and tougher. Tougher waves live
# longer and reach you, which stops it rising, and taking heavy damage brings it back down.
# Only in Normal runs with Adaptive difficulty on, from minute 5, outside rifts. Old spawns are never changed.

const P_MAX := 5.0
const FROM := 300.0          # run seconds before it can start
const FAST := 3.5            # median lifetime (s) below this: you're overpowered
const SLOW := 7.0            # median lifetime above this: back off
const UP := 0.03             # p per second while overpowered
const DOWN := 0.05           # p per second when backing off
const N := 30                # kills the median is taken over
const HURT := 0.3            # losing this share of max HP within 10 s backs off
const UNTOUCHED := 0.05      # losing less than this share in 20 s with the screen full: you're overpowered
const FULL := 0.85           # "the screen is full": this share of the alive limit
const CAP_K := 16.0          # extra alive enemies per point of p...
const CAP_MAX := 32          # ...up to this many
const CAP_LOW := 16          # Effects quality Low: at most this many extra
const HP_K := 1.5            # new-enemy HP ×(1 + HP_K·p)
const DMG_K := 0.2           # new-enemy damage ×(1 + DMG_K·p)
const ELITE_K := 0.10        # elite chance + ELITE_K·p
const SURGE_K := 0.5         # surge size ×(1 + SURGE_K·p)

var m = null
var p := 0.0
var lives: Array = []        # lifetimes of the last N regular kills
var tick_t := 0.0
var hurt: Array = []         # [run_time, hp lost] in the last 20 s
var since := 0.0             # seconds Pressure has been watching (the 20-s window needs to fill first)


func active() -> bool:
	return m._rift_scaling() and m.arena == null and m.run_time >= FROM   # Normal run, Adaptive on, outside rifts


# A regular enemy died: remember how long it lived.
func note_kill(e) -> void:
	if not active() or e.boss or e.legend or e.behavior == "thief" or bool(e.get_meta("minion", false)) or e.born < 0.0:
		return
	lives.append(maxf(0.0, m.run_time - e.born))
	if lives.size() > N:
		lives.pop_front()


# Damage you just took (from main._hurt_player, as it lands).
func note_hurt(d: float) -> void:
	hurt.append([m.run_time, d])


func median() -> float:
	if lives.size() < 8:
		return (FAST + SLOW) * 0.5   # not enough kills yet: neutral
	var s: Array = lives.duplicate()
	s.sort()
	return float(s[s.size() / 2])


func update(delta: float) -> void:
	if m.player == null:
		return
	while not hurt.is_empty() and float(hurt[0][0]) < m.run_time - 20.0:
		hurt.pop_front()
	if not active():
		if not m._rift_scaling():
			p = 0.0   # another mode or Adaptive off: none (inside a rift it just waits)
		return
	tick_t += delta
	if tick_t < 1.0:
		return
	var dt: float = tick_t
	tick_t = 0.0
	since += dt
	var lost10 := 0.0
	var lost20 := 0.0
	for h in hurt:
		lost20 += float(h[1])
		if float(h[0]) >= m.run_time - 10.0:
			lost10 += float(h[1])
	var mh: float = maxf(1.0, m.player.max_hp)
	var full: bool = m.enemies.size() >= int(float(m._cap()) * FULL)
	var untouched: bool = since >= 20.0 and full and lost20 < mh * UNTOUCHED
	var md: float = median()
	if lost10 > mh * HURT or (md > SLOW and not untouched):
		p = maxf(0.0, p - DOWN * dt)
	elif (untouched or md < FAST) and m.player.hp > mh * 0.6:
		p = minf(P_MAX, p + UP * dt)


func spawn_k() -> float:
	return 1.0 + p


func cap_add() -> int:
	var add: int = mini(CAP_MAX, roundi(CAP_K * p))
	if int(m.quality) == 3 or (int(m.quality) == 0 and m.q_auto < 0.5):   # Low (or Auto running low)
		add = mini(add, CAP_LOW)
	return add


func hp_k() -> float:
	return 1.0 + HP_K * p


# Knockback taken by enemies spawned now: constant pushes from strong area attacks kept them from ever reaching you.
func knock_k() -> float:
	return 1.0 / (1.0 + p)


func dmg_k() -> float:
	return 1.0 + DMG_K * p


func elite_add() -> float:
	return ELITE_K * p


func surge_k() -> float:
	return 1.0 + SURGE_K * p
