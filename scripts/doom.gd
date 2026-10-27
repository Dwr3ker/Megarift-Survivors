extends RefCounted
# Doom: la escalada del final de la Partida normal. El nivel de Doom es el numero de veces que has derrotado a Eternatus
# en esta partida (main.eter_kills). Cada nivel suma una regla nueva, no solo numeros:
#   1+  los elites salen mas (25 % minimo) y llevan una caracteristica (Veloz o Blindado) + cartas de final de partida
#   2+  el limite de enemigos sube de 64 a 80 (los extras son mas debiles)  ·  Eternatus: doble Eternarrayo
#   3+  todas las Grietas traen legendario Mega / Primigenio / Corona        ·  Eternatus: los obeliscos reaparecen
#   5+  los enemigos pegan un 10 % mas por nivel
# Eternatus (eternamax.gd): 1+ Pozo gravitatorio. Los legendarios salvajes simultaneos suben +1 por nivel (hasta +3).
# Las monedas recogidas valen x(1 + 0,25 por nivel), hasta x2,5; el premio de Eternatus es fijo (main.ETER_PAY_*).
const L = preload("res://scripts/lang.gd")

const ELITE_FLOOR := 0.25
const CAP_BONUS := 16
const CAP_FROM := 2
const SWARM_HP_K := 0.6          # vida de los enemigos que pasan del limite normal de 64
const MEGA_RIFT_FROM := 3
const DMG_FROM := 5
const DMG_STEP := 0.10
const COIN_STEP := 0.25
const COIN_MAX := 2.5
const MEGA_ATK_STEP := 0.10      # los Pokemon megaevolucionados ganan +10 % de dano por nivel de Doom...
const MEGA_ATK_TIERS := 3        # ...hasta +30 %
const WL_EXTRA_MAX := 3
const CARD_CHANCE := 0.12        # por subida de nivel, desde el primer Eternatus
const AFFIX_SWIFT_SPD := 1.25
const AFFIX_ARMOR_HP := 1.4

# Sobrecarga: cuando una mejora llega a su maximo, sigue saliendo con medio efecto hasta un 125 % del tope.
const OVERCAP := ["atk", "cd", "mag", "xp", "size"]
const OVERCAP_K := 1.25
const OVERCAP_STEP := 0.5

const DASH_K_MIN := 0.5          # Sobremarcha: enfriamiento del dash -20 % por carta, hasta la mitad
const DASH_K_STEP := 0.8
const APEX_ADD := 5.0            # Depredador: +5 cargas de Impulso por carta, 2 cartas
const APEX_MAX := 10.0

const COLOR := Color("#ff6b8a")


static func roman(d: int) -> String:
	var names := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	return String(names[d]) if d < names.size() else str(d)


static func elite_chance(d: int, base: float) -> float:
	return maxf(base, ELITE_FLOOR) if d >= 1 else base


static func cap(base: int, d: int) -> int:
	return base + (CAP_BONUS if d >= CAP_FROM else 0)


static func mega_rift(d: int) -> bool:
	return d >= MEGA_RIFT_FROM


static func enemy_dmg_k(d: int) -> float:
	return 1.0 + DMG_STEP * float(maxi(0, d - DMG_FROM + 1))


static func coin_k(d: int) -> float:
	return minf(COIN_MAX, 1.0 + COIN_STEP * float(d))


static func mega_atk_k(d: int) -> float:
	return 1.0 + MEGA_ATK_STEP * float(mini(d, MEGA_ATK_TIERS))


static func wl_extra(d: int) -> int:
	return mini(d, WL_EXTRA_MAX)


# Caracteristica de un elite de Doom: Veloz (+25 % velocidad, azul) o Blindado (+40 % vida, gris acero).
static func affix(e) -> void:
	if randf() < 0.5:
		e.spd *= AFFIX_SWIFT_SPD
		e.modulate = Color(0.62, 0.85, 1.0)
	else:
		e.max_hp = roundf(e.max_hp * AFFIX_ARMOR_HP)
		e.hp = e.max_hp
		e.modulate = Color(0.78, 0.8, 0.88)


# Carta de final de partida: desde el primer Eternatus, una de tres mejoras unicas (cada una con su limite).
static func card(main) -> Dictionary:
	if main.eter_kills < 1 or main.player.dead or main.mode != "normal":
		return {}
	var opts: Array = []
	if main.doom_winds < main.eter_kills:
		opts.append("wind")
	if main.dash_k > DASH_K_MIN + 0.001:
		opts.append("drive")
	if main.mom_max < main.MOM_MAX + APEX_MAX - 0.001:
		opts.append("apex")
	if opts.is_empty():
		return {}
	var id: String = String(opts[randi() % opts.size()])
	var title := ""
	var desc := ""
	var icon := "star"
	match id:
		"wind":
			title = L.t("Second Wind")
			desc = L.t("You gain a second chance: if you fall, you come back at full health. One per Doom level.")
			icon = "revive"
		"drive":
			title = L.t("Overdrive")
			desc = L.t("Dash cooldown -20% (down to half).")
			icon = "boot"
		"apex":
			title = L.t("Apex Predator")
			desc = L.t("Momentum: +5 max charges (+10% more damage).")
			icon = "fist"
	return {"cat": "doomcard", "id": id, "key": "doom:" + id, "w": 1.0, "title": title, "desc": desc,
		"icon": icon, "tag": L.t("ENDGAME"), "color": COLOR}


static func apply(main, id: String) -> void:
	match id:
		"wind":
			main.revives += 1
			main.doom_winds += 1
		"drive":
			main.dash_k = maxf(DASH_K_MIN, main.dash_k * DASH_K_STEP)
		"apex":
			main.mom_max += APEX_ADD
	main.add_text(main.player.position + Vector2(0.0, -main.player.body_h - 24.0), L.t("Endgame upgrade!"), COLOR, 22)
