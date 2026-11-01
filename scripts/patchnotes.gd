extends RefCounted
# Novedades de cada version, como la pestaña "What's new" del original: lista de versiones (la mas nueva arriba) con
# titulo, fecha y secciones Nuevo / Cambios / Arreglos. Van dentro del juego (sin internet) y traducidas con L.t.
# PARA CADA ACTUALIZACION (cada alpha incluida): anade una entrada NUEVA ARRIBA del todo en ENTRIES (ver = mismo numero que
# application/config/version, p. ej. 0.1.0-alpha.12), escribe sus lineas en ingles y anade sus traducciones a los 11 idiomas.

const SV = preload("res://scripts/save_data.gd")
const UPD = preload("res://scripts/updater.gd")

const ENTRIES := [
	{
		"ver": "0.1.2",
		"date": "2026-11-01",
		"title": "Megarift Survivors 0.1.2: defeat Arceus to unlock regions, new achievements",
		"new": [
			"New achievements for the new features: a Regions tab (Champion of each region, Region hopper, World Champion), plus perfect IVs, all natures, vitamins, Mints, Legend Shards, Legend Picks, Max pull, daily Gold medals and streaks, and Kecleon reservations.",
		],
		"changes": [
			"Regions now unlock by defeating Arceus (the Judgment at minute 30) on the previous region, not just by surviving 30 minutes. Regions you already unlocked stay open, and the region picker shows which maps you have cleared.",
		],
		"fixes": [
		],
	},
	{
		"ver": "0.1.1",
		"date": "2026-11-01",
		"title": "Megarift Survivors 0.1.1: region maps, IVs and natures, Legend Shards",
		"new": [
			"Region maps: after Play on a Normal run you choose Kanto, Johto, Hoenn, Sinnoh, Unova, Kalos, Alola, Galar, Paldea or every region. Each region has its own two biomes and its own wild Pokémon, bosses and legendaries. Kanto is open; each next region unlocks by surviving 30 minutes on the previous one, and players who already beat Eternatus start with every region open.",
			"IVs and natures: every Pokémon you own has IVs (HP, Attack, Speed) and a nature that change its stats in a run. Duplicates raise its IVs and unlock their own nature; vitamins (HP Up, Protein, Carbos) and Mints are on the Pokémon page.",
			"Legend Shards: every legendary duplicate from the gacha and every Eternatus defeat gives one, and 5 shards pick any legendary you don't own (Gacha > Legend Pick).",
			"Move previews: when a level-up card offers a new move, it shows a small looping animation of how the move attacks.",
		],
		"changes": [
			"The Gacha page fits on one screen: the six pull buttons are in two rows of three.",
			"Item screen: \"Not this run\" replaces \"Never offer again\". The item comes back next run, and items blocked forever by the old button are available again.",
		],
		"fixes": [
			"Pickups are no longer missed: the reach grows with your Pokémon's size, a fast step or a dash can't skip over them, and pulled pickups always keep up with you.",
		],
	},
	{
		"ver": "0.1.0",
		"date": "2026-10-31",
		"title": "Megarift Survivors 0.1.0: daily formats, evolution scene, Kecleon reservations and Max pull",
		"new": [
			"Daily Challenge rework: every day is one of three formats, the same for everyone. Medal Rift: one Pokémon with two rules, score points. Draft Day: choose 1 of 3 Pokémon, each with its own rule. Gauntlet: a new rule joins every 5 minutes; survive 20 minutes. Bronze, Silver and Gold medals pay tickets and a purple ticket once a day, and a streak of days with a medal pays bonus coins, with a purple ticket every 7th day.",
			"Evolution scene: evolving now plays like the main games. The world pauses, light gathers into your Pokémon, its white silhouette swaps between the old and new form faster and faster, and a flash reveals the new Pokémon.",
			"Kecleon shop redesign: offers are cards with an icon, the price, how many you own and a bar showing how long Kecleon stays. Reserve: pay 30% to hold an item you can't afford yet, and the next Kecleon brings it for the rest.",
			"Max pull: spend every gold ticket in batches of 10, or every purple ticket, in one go (after a confirmation), with a summary of the new Pokémon and shinies.",
			"Gacha completion bonus: the more of a region you own, the likelier its missing Pokémon (up to ×3) and shinies (from 1% up to 5% at 100%).",
			"Buff badges: Attack, Speed, Defense and Regen boosts show beside your Pokémon, with one arrow per stack and a ring for the time left.",
		],
		"changes": [
			"Items cycle: every item is offered once before any repeats, and after 2 chests without an item the next one always has one. The item screen has a Skip card when you carry nothing.",
			"Pokémon list: bigger Pokémon on the cards, a bigger favourite heart that no longer touches the edge, and the top face button (Y / Triangle / X) marks the highlighted Pokémon as a favourite.",
			"Update notice: the game now finds test builds (alphas) on GitHub and offers the right download for Android or Windows. The version label shows the alpha number.",
			"Effects and particles on Auto come back up when the game runs smoothly again, instead of staying low for the rest of the run.",
			"What's new now lists every alpha.",
		],
		"fixes": [
			"Save and quit now keeps your Kecleon purchases (they were lost when you resumed a run).",
		],
	},
	{
		"ver": "0.1.0-alpha.10",
		"date": "2026-10-30",
		"title": "Alpha 10: controller shortcuts in the Pokémon list",
		"new": [
		],
		"changes": [
			"Controller in the Pokémon list: the left face button (X on Xbox, Square on PlayStation, Y on Nintendo) makes the highlighted Pokémon your partner, so you no longer have to navigate down to Choose. Confirm on a text box (like the search box) now opens the on-screen keyboard, and Confirm or Back closes it.",
		],
		"fixes": [
		],
	},
	{
		"ver": "0.1.0-alpha.9",
		"date": "2026-10-30",
		"title": "Alpha 9: in-run evolution, Dynamax and Z-Move visuals, new codes",
		"new": [
			"In-run evolution: Pokémon that can evolve (Charmander, Charmeleon, Eevee...) get a guaranteed Evolution card when they reach their level (Lv. 16 and 34 in three-stage lines, Lv. 20 in two-stage lines). Evolving brings the next stage's stats, a full heal and a permanent damage, HP and speed bonus. Starting unevolved is weaker early but scales further; starting fully evolved is stronger early and earns a Seasoned bonus that grows with your level (about 5% behind in the very late game), and only a run that starts as the Mega-capable Pokémon can Mega Evolve. The Pokémon list shows each Pokémon's evolution line.",
			"New redeem codes: GIMMEALL gives every Pokémon with no upgrades, and GIMME followed by a Pokémon's name (for example GIMMEPIKACHU) gives that Pokémon with the same shiny chance as a gacha pull; a duplicate pays the gacha refund. Each works once.",
		],
		"changes": [
			"Dynamax and Z-Moves look better: Z-Moves gather energy into your Pokémon during the cinematic (motes, turning rune rings and a camera push-in, with the banner moved up so it no longer covers it); Dynamax drops a beam of light on your Pokémon, each Max Wave is a real shockwave, the big ones show the name of the type's Max move, and it ends in a puff of red mist.",
			"Save and resume: a resumed run keeps the permanent upgrades (and the Adaptive difficulty and Mono-type settings) it was saved with, so you can no longer leave a run, buy upgrades and come back stronger.",
		],
		"fixes": [
			"The Poké Ball on a Pokémon's page now shows its rarity: a different ball from Common to Legendary.",
			"Kecleon shop with a controller: Confirm now buys the highlighted item and Back / Start close the shop on any button layout (Xbox, PlayStation, Nintendo or a custom map); the shop opens on the first item you can afford and says Not enough coins when you press Confirm on one you can't; Android's Back button closes the shop instead of pausing behind it.",
		],
	},
	{
		"ver": "0.1.0-alpha.8",
		"date": "2026-10-30",
		"title": "Alpha 8: Kyurem DNA Splicers, effects and performance",
		"new": [
			"Kyurem: DNA Splicers, a unique level-up card from minute 30, fuses Kyurem into Black Kyurem (+40% damage) or White Kyurem (+25% damage, -15% cooldowns), both with +20% HP. Kyurem now starts with its own move, Glaciate, a freezing wind. When Glaciate evolves it becomes Glaciate+, or Black Kyurem's Freeze Shock (a colossal electrified lance that paralyses) or White Kyurem's Ice Burn (a vast blaze of white fire that burns).",
		],
		"changes": [
			"Effects: rings, hit arcs and beams now come out from under the Pokémon instead of covering it.",
			"Performance: fewer draw calls with lots of effects: limits on live rings, beams and hit arcs, lighter big rings and beams, bullets redraw only when they animate, and a cap on floating damage numbers.",
			"Pokémon list: it opens on the page with your partner, highlighted. With a gamepad, LB and RB step through the region tabs (All, Kanto … Paldea).",
		],
		"fixes": [
			"Run HUD: the revive hearts no longer overlap each other or the ability name.",
		],
	},
	{
		"ver": "0.1.0-alpha.7",
		"date": "2026-10-29",
		"title": "Alpha 7: run reminder, keyboard bindings, pause tabs and boss bar",
		"new": [
			"Random redeem codes: new codes give a random legendary (any generation or a chosen one), a random shiny, a shiny legendary or a Mega-capable Pokémon. They prefer something you don't have yet and pay coins when nothing new is left.",
			"Run in progress: if you left a run saved, the menu reminds you when it opens and when you press Play: resume it or give it up.",
			"Keyboard options for PC: Settings > Controls > Keyboard lets you rebind Options, Build summary, move cycling, Z-Move, Dynamax, Dash, Team swap and moves 1-6.",
		],
		"changes": [
			"Pause: Tab (Select on a gamepad) opens the Build summary and Esc (Start) opens Options. The key of the open tab closes it; the other key switches tab. Dynamax moved from Select to X by default.",
			"New profiles: Skip the quiz now lets you pick any of the normal starters (the strong starter list was removed).",
			"Menus: the left stick moves through menus more slowly.",
			"Boss HP bar at the top centre, below the clock, counters, Dynamax bar and notices.",
		],
		"fixes": [
		],
	},
	{
		"ver": "0.1.0-alpha.6",
		"date": "2026-10-28",
		"title": "Alpha 6: chained fusions and screen fixes",
		"new": [
			"Fusion: a fused move can now fuse again with another evolved, max-level move, up to 4 moves in one slot. The slot bar shows every move inside it (a fusion bonded with another move no longer seems to vanish).",
		],
		"changes": [
		],
		"fixes": [
			"Collection: Use shiny version now only affects the Pokémon you are looking at, not everything you own.",
			"Item found: the swap screen shows the new item once at the top and one card per item you would give up, instead of repeating the same item.",
			"HUD: the Z-Move cooldown is a clear ring with the time inside the button (like Dynamax), and rift and thief notices no longer hide behind the Dynamax bar.",
		],
	},
	{
		"ver": "0.1.0-alpha.5",
		"date": "2026-10-28",
		"title": "Alpha 5: save and quit, HUD layout editor, redeem codes",
		"new": [
			"HUD layout editor (Settings > Graphics > Edit HUD layout): drag or nudge every on-run HUD element, resize it, turn the radar and the stats panel on or off, and save your layouts as presets. The per-element size sliders moved here.",
			"Save and quit: pause > Save and quit stores your Normal run and the main menu offers Resume run (not during boss fights, rifts or other special events).",
			"Radar switch: Settings > Graphics > Radar turns the on-run map off.",
			"Redeem codes: Settings > Account > Redeem code unlocks special bundles (starter pack, Mega pack, Legend pack and more). Each code works once.",
			"New profiles can skip the quiz and pick a starter right away.",
		],
		"changes": [
		],
		"fixes": [
			"Save codes are now short (about 14,000 characters even with everything unlocked). The importer ignores line breaks and spaces added when copying, says what is wrong when a code is rejected, and old codes still work.",
		],
	},
	{
		"ver": "0.1.0-alpha.4",
		"date": "2026-10-28",
		"title": "Alpha 4: skip upgrades with the controller",
		"new": [
		],
		"changes": [
			"Controller: the Cancel button (B / Circle) now skips a level-up upgrade for +25% XP, and the Skip prompt shows the button.",
		],
		"fixes": [
		],
	},
	{
		"ver": "0.1.0-alpha.3",
		"date": "2026-10-27",
		"title": "Alpha 3: new menu credit",
		"new": [
		],
		"changes": [
			"The main menu credit now reads “Made by Dwr3ker”; the original authors stay credited in Settings > About.",
		],
		"fixes": [
		],
	},
	{
		"ver": "0.1.0-alpha.2",
		"date": "2026-10-27",
		"title": "Alpha 2: handhelds, navigation and crash report",
		"new": [
		],
		"changes": [
			"Handhelds and squarer screens: the Pokémon collection uses bigger cards (6 per row) and the main menu uses the extra height.",
			"Crash report: if a run ends unexpectedly, the next launch shows the end of the game log so it can be photographed and sent. The vibration permission was added.",
		],
		"fixes": [
			"Controller: Up and Down now stay in their own column, so the Gacha tabs no longer bounce left and right, and the right panel of the mode list no longer jumps into the Challenges section.",
		],
	},
	{
		"ver": "0.1.0-alpha.1",
		"date": "2026-10-27",
		"title": "Megarift Survivors 0.1: Doofcraft-style edition (test build)",
		"new": [
			"Mega Evolution: from minute 30 a unique card transforms capable Pokémon (41 Mega, Primal and Crowned forms) with +30% damage and HP, +10% speed and -10% cooldowns.",
			"Mega Rifts from minute 15, a mega-capable badge in the collection, and Behemoth moves for Crowned Zacian and Zamazenta.",
			"Common, Rare, Epic and Legendary upgrade cards: their bonuses are multiplied by 1, 1.25, 1.5 and 2.",
			"Hyper mode on Normal Run: everything runs twice as fast, with +30% experience and ×1.5 coins. It has its own record and achievements.",
			"Dash: Shift or Space, a DASH button on screen and a controller button. You are briefly invulnerable and hit whatever you pass through.",
			"Eternamax Eternatus: the final boss now attacks with Eternabeam, cannons, rings, a tail slam and meteors, and is healed by three dark obelisks.",
			"After you defeat Eternatus you choose: end the run with a victory or keep fighting. You get a reward (coins, tickets and x10 tickets) and he returns every 30 minutes (15 in Hyper) with another reward.",
			"Doom: every time you defeat Eternatus and keep going, the Doom level rises: more elites with traits, a bigger swarm, Mega Rifts, and Eternatus learns the Gravity Well, a double Eternabeam and to revive obelisks. Coins are worth more (up to x2.5).",
			"Endgame: upgrades go beyond their maximum (Overcap, at half effect) and, after the first Eternatus, three new cards appear: Second Wind, Overdrive and Apex Predator. Seven new achievements.",
			"Mega Calamity: between two Eternatus fights a Mega legendary appears with telegraphed attacks (Stomp and Barrage) and a good reward. It arrives 15 minutes before the next Eternatus.",
			"Wild legendaries from minute 30: up to three at once, appearing more and more often.",
			"Deoxys can change Forme (Attack, Defense or Speed) with a unique card from minute 5.",
			"Arceus starts with Judgment and finds Plates that change its type and look.",
			"Z-Crystal as a card from minute 15: it unlocks your Z-Move for the run, with a 2-minute recharge.",
		],
		"changes": [
			"Balance: +10% damage with moves of your own type, Momentum for chained defeats (up to +20% damage), a ×2.5 speed cap and shorter enemy shields (3.5 s).",
			"Rifts: the first check is at 90 s and then every 30 s, with a 20% chance that grows 5% with every miss (max 50%). There is no longer a time limit: they keep appearing until Eternatus.",
		],
		"fixes": [
		],
	},
]


# Primera vez con esta version (y ya habia partidas jugadas): el menu abre la pantalla de novedades.
static func should_show() -> bool:
	var v: String = UPD.APP_VERSION
	if String(SV.d.get("notes_seen", "")) == v:
		return false
	SV.d["notes_seen"] = v
	SV.save()
	var has := false
	for e in ENTRIES:
		if String(e["ver"]) == v:
			has = true
	if not has:
		return false
	var st: Dictionary = SV.d.get("stats", {})
	return int(st.get("runs", 0)) > 0   # instalacion nueva: no hay nada que "haya cambiado" para esta persona


const MONTHS := {
	"es": ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
	"en": ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
	"fr": ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"],
	"it": ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"],
	"pt": ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"],
	"ru": ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"],
}


# "2026-10-15" -> "15 October 2026" / "15 de octubre de 2026" / "2026年10月15日", segun el idioma.
static func fmt_date(iso: String, code: String) -> String:
	var p: PackedStringArray = iso.split("-")
	if p.size() != 3:
		return iso
	var y: int = int(p[0])
	var m: int = clampi(int(p[1]), 1, 12)
	var d: int = int(p[2])
	if code == "ja" or code.begins_with("zh"):
		return "%d年%d月%d日" % [y, m, d]
	if code == "vi":
		return "%d tháng %d, %d" % [d, m, y]
	var key: String = code
	if code.begins_with("es"):
		key = "es"
	elif code.begins_with("pt"):
		key = "pt"
	if not MONTHS.has(key):
		key = "en"
	var mn: String = String(MONTHS[key][m - 1])
	if key == "es" or key == "pt":
		return "%d de %s de %d" % [d, mn, y]
	return "%d %s %d" % [d, mn, y]
