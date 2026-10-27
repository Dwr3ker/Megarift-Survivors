extends RefCounted
# Legendarios salvajes (al estilo Doofcraft): desde el minuto 30 aparecen legendarios sueltos entre los enemigos normales,
# mas duros que cualquier otro salvaje. Hasta 3 a la vez, cada vez mas a menudo, con mas dano y premio.
# Las curvas de aparicion, dano, velocidad, experiencia y tickets son las del balance publicado por Doofcraft
# (wildLegends). Su curva de vida se mide contra la vida de SU salvaje normal, asi que aqui la vida se calcula contra la
# del salvaje normal de este juego en ese minuto (ver HP_K) en vez de copiar el multiplicador x30.

const FROM := 1800.0          # minuto 30 (segundos de partida)
const MAX_ALIVE := 3
const RATE := [[30.0, 0.15], [45.0, 0.25], [60.0, 0.40], [90.0, 0.75]]   # legendarios por minuto de partida
const DMG := [[30.0, 1.5], [60.0, 1.8], [90.0, 2.5]]                      # multiplicador de dano
const SPD := [[30.0, 0.8], [90.0, 0.9]]                                   # multiplicador de velocidad
const HP_K := [[30.0, 4.0], [45.0, 3.5], [60.0, 3.0], [90.0, 2.5]]        # x la vida de un salvaje normal (calibrado a este juego)
const XP_K := 15.0            # experiencia = 15 x la de un salvaje normal
# Ticket x10 (Doofcraft: 25%): ya lo cubre el botin normal de jefe (~24%), asi que no se tira aparte.
const BASE_DMG := 48.0        # dano y velocidad base antes de las curvas (1,5 y 0,8 son los valores del minuto 30)
const BASE_SPD := 52.0


# Interpolacion lineal por tramos; fuera del rango se queda en el primer / ultimo valor.
static func curve(points: Array, x: float) -> float:
	if x <= float(points[0][0]):
		return float(points[0][1])
	for i in range(1, points.size()):
		var a: Array = points[i - 1]
		var b: Array = points[i]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(points[points.size() - 1][1])


static func rate(minute: float) -> float:
	return curve(RATE, minute)


static func dmg(minute: float) -> float:
	return BASE_DMG * curve(DMG, minute) / float(DMG[0][1])


static func speed(minute: float) -> float:
	return BASE_SPD * curve(SPD, minute) / float(SPD[0][1])


static func hp_k(minute: float) -> float:
	return curve(HP_K, minute)
