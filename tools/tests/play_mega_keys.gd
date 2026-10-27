extends Node
# Debug keys for hand-testing Mega Evolution (not part of the game).
#   F9  = jump the run clock to 31:00      F10 = open the level-up cards (mega card = 12% chance each time)
#   F11 = force the mega card to be taken  (only works once per run)
#   F7  = open the Deoxys Forme choice directly (needs a Deoxys run: -- 386)
#   F4  = Z-Crystal: grant your type's Z-move now (clock jumps to 15:00 if earlier)
#   F5  = Arceus: apply a random plate now (needs an Arceus run: -- 493)
#   F6  = start the Eternamax Eternatus fight now (clock jumps to 60:00)
#   F8  = spawn a wild legendary now (also sets the clock to 31:00 if earlier)
var m

func _input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	match e.keycode:
		KEY_F9:
			m.run_time = 1860.0
			m.add_text(m.player.position + Vector2(0, -60), "clock -> 31:00", Color.WHITE, 20)
		KEY_F10:
			if not m.choosing:
				m._open_cards()
		KEY_F4:
			var ZC = load("res://scripts/zcrystal.gd")
			m.run_time = maxf(m.run_time, 960.0)
			m.z_type = ""
			var zc: Dictionary = ZC.card(m)
			if not zc.is_empty():
				ZC.apply(m, String(zc["ztype"]))
		KEY_F5:
			var PL = load("res://scripts/plates.gd")
			var opts: Array = PL.list().filter(func(p): return String(p["type"]) != m.plate)
			PL.apply(m, String(opts[randi() % opts.size()]["type"]))
		KEY_F6:
			if m.etx == null:
				m.run_time = maxf(m.run_time, 3600.0)
				m.dir_done["map"] = true
				m._spawn_eternatus()
		KEY_F7:
			var FM = load("res://scripts/forme.gd")
			m.choosing = true
			m.cards.show_cards(FM.picks(m), "Elige una Forma", "¡Cambio de Forma!", false)
		KEY_F8:
			m.run_time = maxf(m.run_time, 1860.0)
			m.dir_done["map"] = true
			m._spawn_wildleg()
		KEY_F11:
			if not m.mega_done:
				m.run_time = maxf(m.run_time, 1860.0)
				m._mega_start()
