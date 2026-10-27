extends RefCounted
# Cristal Z como carta de nivel (al estilo Doofcraft): desde el minuto 15, una subida de nivel puede ofrecer el Cristal Z del
# tipo de tu Pokemon y desbloquea su Movimiento Z durante esta partida (aunque no lo tengas desbloqueado en tu perfil),
# con recarga de 2 minutos. Los Pokemon megaevolucionados no pueden usar Movimientos Z (mega.gd quita el cristal).
# Cifras de Doofcraft (zMove): fromMinute 15, offerChance 0,1, cooldownSeconds 120.
const L = preload("res://scripts/lang.gd")
const ZM = preload("res://scripts/zmove.gd")
const MD = preload("res://scripts/moves_data.gd")

const FROM_TIME := 900.0     # minuto 15 (segundos de partida)
const CHANCE := 0.10         # por subida de nivel
const COOLDOWN := 120.0      # recarga del Movimiento Z desbloqueado con esta carta


# Carta del cristal: solo si aun no tienes Movimiento Z en la partida, no has megaevolucionado y ya pasaron 15 minutos.
static func card(main) -> Dictionary:
	if main.z_type != "" or main.mega_done or main.mode == "tower" or main.mode == "team" or main.banned.has("zcrystal"):
		return {}
	if main.run_time < FROM_TIME or main.player.dead or main.player.types.is_empty():
		return {}
	var ty: String = String(main.player.types[0])
	if not ZM.DEF.has(ty):
		return {}
	var col: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#ffffff")))
	return {"cat": "zcrystal", "id": "zcrystal", "key": "zcrystal:" + ty, "w": 1.0, "ztype": ty,
		"title": L.t("%s Z-Crystal") % L.t(String(MD.TYPE_NAME[ty])),
		"desc": L.t("Unlocks your Z-Move for this run: %s. Recharges in 2 minutes.") % L.t(String(ZM.DEF[ty]["name"])),
		"icon": "zc:" + ty, "tag": L.t("UNIQUE"), "color": col}


# Concede el Movimiento Z de ese tipo para el resto de la partida.
static func apply(main, type: String) -> void:
	if not ZM.DEF.has(type):
		return
	main.z_type = type
	main.z_crystal = true
	main.z_used = false
	main.z_cd = 0.0
	main.add_text(main.player.position + Vector2(0.0, -main.player.body_h - 24.0), L.t(String(ZM.DEF[type]["name"])), Color.html(String(MD.TYPE_COLOR.get(type, "#ffffff"))), 22)
	main._say(L.t("You got the Z-Crystal! Use the Z button, the Z key or your controller's Z button"), 3.2)
