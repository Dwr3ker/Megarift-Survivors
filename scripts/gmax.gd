extends RefCounted
# Gigantamax: 32 Pokémon have a Gigantamax form. Beat a Gigantamax den whose boss is one of them and that species
# keeps the Gigantamax Factor (SV.d["gmax"]). In a run with it, Dynamax becomes Gigantamax: the Pokémon grows bigger,
# wears a storm crown, and every big Max wave (each third) is replaced by its own G-Max move, named on screen.
# The sprites are the normal ones (no Gigantamax sprites exist yet); the look comes from the size and the aura.
const VFX = preload("res://scripts/vfx.gd")
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")

const GROW := 1.9          # Dynamax is 1.6
const STAT_K := 1.4        # +40% to every stat (Dynamax +30%)
const DMG_K := 1.4
const TAKEN := 0.2857      # 1 - 1/1.4: defence +40%
const DEN_CHANCE := 0.35   # share of Dynamax dens (after the first one) that are Gigantamax dens
const BOSS_CAP := 0.28     # like a Z-Move: one G-Max move takes at most this share of a boss's HP
const GOLD := Color("#ffb347")
const CROWN := Color("#ff2f4f")

# kind: zone (lingering ground that hurts), storm (bolts on many enemies), heal, guard (you take less), coins,
#       frenzy (each G-Max move hits harder than the last), pull (drags enemies in), push (blows them away),
#       snipe (huge hits on the toughest enemies). st = status: [cc, burn, poison, slow].
const SPECIES := {
	3: {"move": "G-Max Vine Lash", "type": "grass", "kind": "zone", "st": ["", 0, 1, 0.2]},
	6: {"move": "G-Max Wildfire", "type": "fire", "kind": "zone", "st": ["", 3, 0, 0.0]},
	9: {"move": "G-Max Cannonade", "type": "water", "kind": "zone", "st": ["", 0, 0, 0.45]},
	12: {"move": "G-Max Befuddle", "type": "bug", "kind": "storm", "st": ["mix", 0, 1, 0.0]},
	25: {"move": "G-Max Volt Crash", "type": "electric", "kind": "storm", "st": ["para", 0, 0, 0.0]},
	52: {"move": "G-Max Gold Rush", "type": "normal", "kind": "coins", "st": ["conf", 0, 0, 0.0]},
	68: {"move": "G-Max Chi Strike", "type": "fighting", "kind": "frenzy", "st": ["", 0, 0, 0.0]},
	94: {"move": "G-Max Terror", "type": "ghost", "kind": "storm", "st": ["", 0, 0, 0.7]},
	99: {"move": "G-Max Foam Burst", "type": "water", "kind": "pull", "st": ["", 0, 0, 0.6]},
	131: {"move": "G-Max Resonance", "type": "ice", "kind": "guard", "st": ["freeze", 0, 0, 0.0]},
	133: {"move": "G-Max Cuddle", "type": "normal", "kind": "storm", "st": ["charm", 0, 0, 0.0]},
	143: {"move": "G-Max Replenish", "type": "normal", "kind": "heal", "st": ["", 0, 0, 0.0]},
	569: {"move": "G-Max Malodor", "type": "poison", "kind": "storm", "st": ["", 0, 3, 0.0]},
	809: {"move": "G-Max Meltdown", "type": "steel", "kind": "push", "st": ["para", 0, 0, 0.0]},
	812: {"move": "G-Max Drum Solo", "type": "grass", "kind": "snipe", "st": ["", 0, 0, 0.0]},
	815: {"move": "G-Max Fireball", "type": "fire", "kind": "snipe", "st": ["", 3, 0, 0.0]},
	818: {"move": "G-Max Hydrosnipe", "type": "water", "kind": "snipe", "st": ["", 0, 0, 0.3]},
	823: {"move": "G-Max Wind Rage", "type": "flying", "kind": "push", "st": ["", 0, 0, 0.0]},
	826: {"move": "G-Max Gravitas", "type": "psychic", "kind": "pull", "st": ["conf", 0, 0, 0.0]},
	834: {"move": "G-Max Stonesurge", "type": "water", "kind": "zone", "st": ["", 0, 0, 0.3], "shape": "rock"},
	839: {"move": "G-Max Volcalith", "type": "rock", "kind": "zone", "st": ["", 2, 0, 0.0]},
	841: {"move": "G-Max Tartness", "type": "grass", "kind": "storm", "st": ["conf", 0, 0, 0.3]},
	842: {"move": "G-Max Sweetness", "type": "grass", "kind": "heal", "st": ["", 0, 0, 0.0]},
	844: {"move": "G-Max Sandblast", "type": "ground", "kind": "zone", "st": ["", 0, 0, 0.5]},
	849: {"move": "G-Max Stun Shock", "type": "electric", "kind": "storm", "st": ["para", 0, 2, 0.0]},
	851: {"move": "G-Max Centiferno", "type": "fire", "kind": "zone", "st": ["", 3, 0, 0.0], "ring": true},
	858: {"move": "G-Max Smite", "type": "fairy", "kind": "storm", "st": ["conf", 0, 0, 0.0]},
	861: {"move": "G-Max Snooze", "type": "dark", "kind": "storm", "st": ["sleep", 0, 0, 0.0]},
	869: {"move": "G-Max Finale", "type": "fairy", "kind": "heal", "st": ["", 0, 0, 0.0]},
	879: {"move": "G-Max Steelsurge", "type": "steel", "kind": "zone", "st": ["", 0, 0, 0.0]},
	884: {"move": "G-Max Depletion", "type": "dragon", "kind": "storm", "st": ["", 0, 0, 0.6]},
	892: {"move": "G-Max One Blow", "type": "dark", "kind": "snipe", "st": ["", 0, 0, 0.0]},
}

var m
var spec: Dictionary = {}
var dex := 0
var zones: Array = []     # {p, r, t, tick}
var frenzy := 0
var guard_t := 0.0
var spent := {}           # boss cap per boss for each G-Max move


static func capable(d: int) -> bool:
	return SPECIES.has(d)


static func has_factor(sv_d: Dictionary, d: int) -> bool:
	return capable(d) and bool((sv_d.get("gmax", {}) as Dictionary).get(str(d), false))


static func grant(sv_d: Dictionary, d: int) -> bool:
	if not capable(d):
		return false
	if not sv_d.has("gmax"):
		sv_d["gmax"] = {}
	var had: bool = bool(sv_d["gmax"].get(str(d), false))
	sv_d["gmax"][str(d)] = true
	return not had


static func move_name(d: int) -> String:
	return L.t(String(SPECIES[d]["move"])) if capable(d) else ""


func setup(main, d: int) -> void:
	m = main
	dex = d
	spec = SPECIES[d]


func col(i: int = 3) -> Color:
	return VFX.pc(String(spec["type"]), i)


# Damage that respects a boss cap (a G-Max move can't melt a boss on its own) and applies the move's status.
func _strike(e, amount: float, from: Vector2, knock: float = 0.0, st_k: float = 1.0) -> void:
	if e == null or not is_instance_valid(e) or e.dead:
		return
	var st: Array = spec["st"]
	var cc: String = String(st[0])
	if cc == "mix":
		cc = ["para", "sleep", ""][randi() % 3]
	var d: Vector2 = (e.position - from).normalized()
	if d == Vector2.ZERO:
		d = Vector2.RIGHT
	var before: float = e.hp
	m._hit_enemy(e, amount, col(3), d, knock, String(spec["type"]), int(st[1]), int(st[2]), float(st[3]) * st_k, cc, 1.0 if cc != "" else 0.0)
	if e.boss:
		var key: String = str(e.get_instance_id())
		var room: float = maxf(0.0, BOSS_CAP * e.max_hp - float(spent.get(key, 0.0)))
		var lost: float = maxf(0.0, before - e.hp)
		if lost > room:
			e.hp = minf(e.max_hp, e.hp + (lost - room))
			lost = room
		spent[key] = float(spent.get(key, 0.0)) + lost


func _near(p: Vector2, r: float) -> Array:
	var l: Array = []
	for e in m.enemies:
		if is_instance_valid(e) and not e.dead and e.position.distance_to(p) <= r + e.radius * 0.5:
			l.append(e)
	return l


func _shape() -> String:
	return String(spec.get("shape", VFX.for_type(String(spec["type"]))["proj"]))


# The G-Max move: called on each big Max wave. base = the wave's damage.
func fire(base: float) -> void:
	spent.clear()
	var c: Vector2 = m.player.position
	var ty: String = String(spec["type"])
	m._say(move_name(dex), 1.8)   # the move's name, centre screen
	m.pfx.ring(c, 12.0, 300.0, CROWN, 0.5, 5.0)
	m.pfx.ring(c, 12.0, 220.0, GOLD, 0.45, 4.0)
	m.shake = maxf(m.shake, 7.0)
	Aud.sfx("legend")
	match String(spec["kind"]):
		"zone":
			var spots: Array = []
			if bool(spec.get("ring", false)):   # a ring of fire around you
				for i in range(6):
					spots.append(c + Vector2.from_angle(TAU * float(i) / 6.0) * 150.0)
			else:
				var l: Array = _near(c, 460.0)
				l.shuffle()
				for e in l.slice(0, 4):
					spots.append(e.position)
				while spots.size() < 4:
					spots.append(c + Vector2.from_angle(randf() * TAU) * randf_range(80.0, 300.0))
			for p in spots:
				zones.append({"p": p, "r": 70.0, "t": 6.0, "tick": 0.0, "dmg": base * 0.35})
				m.pfx.ring(p, 6.0, 70.0, col(3), 0.4, 4.0)
		"storm":
			var l2: Array = _near(c, 520.0)
			l2.shuffle()
			for e in l2.slice(0, 12):
				_bolt(e.position)
				_strike(e, base * 0.9, c, 40.0)
		"heal":
			var hp0: float = m.player.hp
			m.player.hp = minf(m.player.max_hp, m.player.hp + m.player.max_hp * 0.25)
			m.add_text(c + Vector2(0.0, -m.player.body_h - 6.0), "+%d" % roundi(m.player.hp - hp0), Color("#7dffb0"), 24)
			for i in range(3):
				m._spawn_orb(c + Vector2.from_angle(randf() * TAU) * 60.0, "heal", 0.0)
			for e in _near(c, 300.0):
				_strike(e, base * 0.6, c, 80.0)
		"guard":
			guard_t = 8.0
			for e in _near(c, 360.0):
				_strike(e, base * 0.8, c, 60.0)
		"coins":
			for i in range(10):
				m._spawn_orb(c + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 140.0), "coin", 10.0)
			for e in _near(c, 380.0):
				_strike(e, base * 0.8, c, 60.0)
		"frenzy":
			frenzy += 1
			for e in _near(c, 380.0):
				_strike(e, base * (0.8 + 0.25 * float(frenzy)), c, 120.0)
		"pull":
			for e in _near(c, 520.0):
				if not e.boss:
					e.position = e.position.lerp(c, 0.55)
				_strike(e, base * 0.9, c, 0.0)
			m.pfx.ring(c, 520.0, 30.0, col(3), 0.5, 5.0)
		"push":
			for e in _near(c, 420.0):
				_strike(e, base * 0.9, c, 520.0 if not e.boss else 120.0)
		"snipe":
			var l3: Array = _near(c, 700.0)
			l3.sort_custom(func(a, b): return a.hp > b.hp)
			for e in l3.slice(0, 3):
				_bolt(e.position)
				m.pfx.ring(e.position, 6.0, 90.0, GOLD, 0.35, 4.0)
				_strike(e, base * 3.2, c, 160.0)


func _bolt(p: Vector2) -> void:
	m.pfx.sp(_shape(), String(spec["type"]), p + Vector2(0.0, -40.0), {"v": Vector2(0.0, 300.0), "life": 0.16, "scale": 2.4, "fade": true})
	m.pfx.ring(p, 4.0, 46.0, col(3), 0.3, 3.0)
	m.pfx.burst(p, col(2), 6, 140.0)


# Every frame while Gigantamax (and after, until the zones it left fade).
func tick(delta: float) -> void:
	guard_t = maxf(0.0, guard_t - delta)
	for z in zones.duplicate():
		z["t"] = float(z["t"]) - delta
		z["tick"] = float(z["tick"]) - delta
		if float(z["t"]) <= 0.0:
			zones.erase(z)
			continue
		if float(z["tick"]) <= 0.0:
			z["tick"] = 0.5
			var p: Vector2 = z["p"]
			m.pfx.sp(_shape(), String(spec["type"]), p + Vector2(randf_range(-40.0, 40.0), randf_range(-14.0, 14.0)), {"life": 0.5, "scale": 1.5, "fade": true})
			m.pfx.ring(p, 20.0, float(z["r"]), col(2), 0.5, 3.0)
			for e in _near(p, float(z["r"])):
				_strike(e, float(z["dmg"]), p, 0.0, 0.5)


# Damage you take is cut while G-Max Resonance's veil is up.
func taken_k() -> float:
	return 0.6 if guard_t > 0.0 else 1.0
