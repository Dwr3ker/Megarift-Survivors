extends RefCounted
# Recetas de Move Fusion: dos movimientos evolucionados al maximo y vinculados se funden en uno solo.
# [id, nombre, movA, movB, descripcion, color]
const R := [
	["inferno_tempest", "Inferno Tempest", "heat-wave", "gust", "A hurricane of fire that sweeps away everything in its path.", "#ff6a2a"],
	["thunder_apocalypse", "Thunder Apocalypse", "thunderbolt", "zap-cannon", "A devastating lightning storm upon your enemies.", "#ffe14a"],
	["abyssal_singularity", "Abyssal Singularity", "shadow-ball", "psychic", "A dark hole that pulls in and crushes.", "#7a4ad8"],
	["absolute_zero", "Absolute Zero", "ice-beam", "hydro-pump", "Freezes the very water: a beam of absolute cold.", "#8fe8ff"],
	["dragon_cataclysm", "Dragon Cataclysm", "dragon-breath", "eruption", "Dragon breath and magma in a cataclysmic blast.", "#d84a3a"],
	["toxic_eden", "Toxic Eden", "solar-beam", "sludge-bomb", "A poisonous garden that blooms and poisons the area.", "#8ad84a"],
	["heavens_judgment", "Heaven's Judgment", "fleur-cannon", "dazzling-gleam", "Divine light that judges every enemy.", "#ffc8f0"],
	["earthbreaker", "Earthbreaker", "bulldoze", "stone-edge", "Breaks the ground and hurls sharp rocks.", "#b8975a"],
	["phantom_legion", "Phantom Legion", "shadow-bone", "infernal-parade", "A legion of specters marches at your side.", "#a070e0"],
	["solar_annihilation", "Solar Annihilation", "solar-beam", "hyper-beam", "A solar beam of total annihilation.", "#fff08a"],
	["crimson_execution", "Crimson Execution", "high-jump-kick", "sacred-sword", "A leap and crimson slash that executes the target.", "#e0304a"],
	["frozen_thunder", "Frozen Thunder", "thunderbolt", "ice-beam", "Icy beams that paralyze and freeze.", "#b8f0ff"],
	["celestial_meteor", "Celestial Meteor", "dragon-rage", "meteor-mash", "A rain of draconic meteors from the sky.", "#ff9a3a"],
	["blood_moon", "Blood Moon", "dream-eater", "hypnosis", "A red moon that lulls to sleep and devours dreams.", "#c02050"],
	# extras
	["magma_cyclone", "Magma Cyclone", "magma-storm", "air-slash", "A cutting cyclone of lava.", "#ff7a3a"],
	["blazing_comet", "Blazing Comet", "flamethrower", "meteor-mash", "A flaming comet that crashes down on the group.", "#ff8a2a"],
	["storm_wing", "Storm Wing", "thunderbolt", "wing-attack", "Electricity-charged wings that cross the map.", "#ffe86a"],
	["glacier_storm", "Glacier Storm", "ice-beam", "air-cutter", "Bursts of ice blades.", "#a8e8ff"],
	["venom_nightmare", "Venom Nightmare", "sludge-bomb", "shadow-ball", "Toxic bombs wrapped in shadows.", "#9a5ad0"],
	["tidal_thunder", "Tidal Thunder", "hydro-pump", "thunderbolt", "An electric wave that ravages the wet.", "#5ac8ff"],
	# lista 2 (combate y destruccion)
	["volcanic_armageddon", "Volcanic Armageddon", "eruption", "magma-storm", "Summons volcanoes around the player that spew lava and create rivers of magma. Trapped enemies take continuous burns.", "#ff5a1a"],
	["thunder_prison", "Thunder Prison", "electroweb", "zap-cannon", "Creates an electric prison around groups of enemies. Those trapped take chained shocks and a final electric cannon blast.", "#4ab8ff"],
	["eternal_blizzard", "Eternal Blizzard", "aurora-beam", "icicle-spear", "Fires spinning icy beams that create ice spears. The spears bounce between frozen enemies.", "#7ae8ff"],
	["oceanic_devastation", "Oceanic Devastation", "whirlpool", "crabhammer", "A whirlpool drags enemies in and creates huge water pincers that strike from opposite sides.", "#3a8ae8"],
	["natures_wrath", "Nature's Wrath", "leaf-storm", "leech-seed", "A storm of leaves plants seeds in enemies. The seeds grow into roots that immobilize and drain life.", "#5ad84a"],
	["divine_execution", "Divine Execution", "sacred-sword", "behemoth-blade", "A celestial sword pierces enemies, ignores part of their defense and leaves luminous cuts.", "#ffe8a0"],
	["meteor_breaker", "Meteor Breaker", "stone-edge", "hammer-arm", "A ground strike that raises huge rock columns and shatters them into fragments.", "#c8a060"],
	["phantom_assassin", "Phantom Assassin", "shadow-bone", "cross-poison", "Poisoned spectral bones chase enemies and burst into toxic crosses.", "#9a60d8"],
	["dragon_overlord", "Dragon Overlord", "dragon-darts", "dragon-energy", "Energy dragons seek out independent targets; their power depends on the player's current health.", "#7a5ae8"],
	["sky_execution", "Sky Execution", "air-slash", "axe-kick", "Throws wind blades that mark enemies, then unleashes aerial kicks on them.", "#a8d8ff"],
	["iron_guillotine", "Iron Guillotine", "anchor-shot", "stone-axe", "Chained anchors immobilize enemies while giant axes fall upon them.", "#9aa8b8"],
	["piercing_catastrophe", "Piercing Catastrophe", "drill-run", "stone-edge", "A rock drill tears through hordes and leaves spikes on the ground.", "#b89a68"],
	["crimson_barrage", "Crimson Barrage", "blaze-kick", "bolt-beak", "Electrified fiery charges that deal more damage when they connect quickly.", "#ff6a3a"],
	["dragon_cyclone", "Dragon Cyclone", "dragon-breath", "air-cutter", "A draconic cyclone spins around the player, flinging blades in every direction.", "#6a8aff"],
	["shattering_glacier", "Shattering Glacier", "ice-hammer", "ice-ball", "Ice hammer blows create huge frozen balls that grow as they hit and finally shatter.", "#9ae0ff"],
	# lista 3 (oscuras, psiquicas, venenosas, estrategicas)
	["nightmare_eclipse", "Nightmare Eclipse", "infernal-parade", "night-shade", "Darkness covers the stage and releases specters that deal more damage to enemies with status conditions.", "#6a3aa8"],
	["psychic_oblivion", "Psychic Oblivion", "psystrike", "psyshock", "A mental blast weakens enemy defenses and releases successive psychic waves.", "#e84ab8"],
	["toxic_apocalypse", "Toxic Apocalypse", "sludge-wave", "poison-jab", "Poison waves mark enemies; then toxic spikes appear beneath the marked ones.", "#a83ad8"],
	["mind_shatter", "Mind Shatter", "psybeam", "mist-ball", "Refracted psychic rays create illusions that attack different enemies.", "#f08ae8"],
	["venom_cataclysm", "Venom Cataclysm", "cross-poison", "sludge-bomb", "Poisonous crosses explode into toxic bombs that leave small contaminated zones.", "#8a3ac8"],
	["spectral_inferno", "Spectral Inferno", "infernal-parade", "mystical-fire", "Ghostly flames chase enemies afflicted by status conditions and temporarily reduce their offensive power.", "#9a5aff"],
	["cosmic_cannon", "Cosmic Cannon", "fleur-cannon", "psystrike", "A huge cannon of psychic and fairy energy fires a concentrated blast with a long cooldown.", "#ff9af0"],
	["guardians_sanctuary", "Guardian's Sanctuary", "roost", "milk-drink", "Creates a recovery zone that heals gradually and grants temporary protection.", "#8affb8"],
	["golden_cataclysm", "Golden Cataclysm", "pay-day", "egg-bomb", "Throws golden explosive eggs. Some hits generate small amounts of regular coins, with a cap per activation.", "#ffd84a"],
	["crystal_labyrinth", "Crystal Labyrinth", "stealth-rock", "freeze-dry", "Generates a temporary maze of frozen crystals that damage and slow enemies.", "#8adaff"],
	["solar_sandstorm", "Solar Sandstorm", "scorching-sands", "eruption", "Storms of scorching sand sweep across the map and leave small craters.", "#ffa83a"],
	["phantom_whirlpool", "Phantom Whirlpool", "whirlpool", "shadow-bone", "A dark whirlpool pulls enemies in while spectral bones spin inside it.", "#5a6ad8"],
	["razor_dimension", "Razor Dimension", "slash", "air-slash", "Dimensional cuts tear across the screen, with a higher chance of critical hits.", "#d8e8ff"],
	["frostfire_cataclysm", "Frostfire Cataclysm", "ice-burn", "magma-storm", "Alternates zones of heat and cold; enemies affected by both elements suffer a thermal explosion.", "#ff8a9a"],
	["celestial_barrage", "Celestial Barrage", "dragon-darts", "fleur-cannon", "Draconic projectiles mark targets and a cannon of light strikes all marks at once.", "#ffc8ff"],
]


static func find(a: String, b: String) -> Dictionary:
	for r in R:
		if (r[2] == a and r[3] == b) or (r[2] == b and r[3] == a):
			return {"id": r[0], "name": r[1], "a": r[2], "b": r[3], "desc": r[4], "col": r[5]}
	return {}
