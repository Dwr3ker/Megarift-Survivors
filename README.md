# Megarift Survivors (Android)

A free, fan-made, **offline** survivor-like for Android. Survive endless waves of Pokémon, level up, evolve your moves, open rifts to fight legendaries and face the final boss.

This is a fork of **[JayElDragon's Godot port](https://github.com/JayElDragon/poke-survivor)** of **[PokéSurvivor by JPTER78](https://github.com/JPTER78/pokesurvivor)**. It keeps everything from that port (touch and gamepad controls, 11 languages, local saves, minimap, 960+ Pokémon, gacha, missions, achievements) and adds the systems and balance that make the independent rewrite at [pokesurvivor.doofcraft.com](https://pokesurvivor.doofcraft.com) feel different: Mega Evolution, rarity-tier cards, Hyper mode, a real final boss, an endgame, save-and-resume and more.

> **No ads. No purchases. No accounts.** Your progress stays on your device. The only network request the game makes is a single update check against this repository's GitHub releases when the menu opens (nothing is sent but a standard HTTPS request); it can be switched off by emptying `REPO` in `scripts/updater.gd`.

Current version: **0.1.2** (0.1.0 was the first stable release, after ten alpha test builds) — see [`RELEASE_NOTES_v0.1.0.md`](RELEASE_NOTES_v0.1.0.md). This is an early build of a new project: expect rough edges.

## What's new compared with the base port

| | |
|---|---|
| **Mega Evolution** | A rare Unique card from minute 30 (15 in Hyper) transforms 41 capable Pokémon: 37 Megas, Primal Kyogre/Groudon and Crowned Zacian/Zamazenta. +30% damage and HP, +10% speed, −10% cooldowns, new look and type. |
| **Mega Rifts** | From minute 15 a rift's legendary can arrive in its Mega/Primal/Crowned form (5% → 30% of rifts), tougher and with a bigger reward. |
| **Rarity-tier cards** | Stat cards roll Common, Rare, Epic or Legendary (×1, ×1.25, ×1.5, ×2 bonus); better odds later in a run. |
| **Hyper mode** | Toggle on Normal Run: the run clock goes twice as fast, with +30% XP and ×1.5 coins. Own record and achievements. |
| **Eternamax Eternatus** | The 60-minute final boss now fights with Eternabeam, cannons, expanding rings, a tail slam and meteors, and is healed by three obelisks. After the win you can end the run or keep going; he returns every 30 minutes (15 in Hyper) with a reward each time. |
| **Doom (endgame)** | Each extra Eternatus you beat raises a Doom level: tougher elites with traits, a bigger swarm, Mega rifts, new Eternatus attacks, endgame cards, Overcap upgrades and scaling coins. |
| **Wild legendaries** | From minute 30, up to three legendaries roam among the normal enemies, appearing more and more often. |
| **Dash** | Shift/Space, an on-screen DASH button or a controller button. Short burst with brief invulnerability that damages what it crosses. |
| **Mega Calamity** | Between two Eternatus fights, a Mega legendary arrives with telegraphed attacks (Stomp and Barrage) and a good reward. |
| **Deoxys formes** | A Unique card from minute 5 lets Deoxys switch between Attack, Defense and Speed Forme. |
| **Arceus plates** | Arceus starts with Judgment and finds Plates that change its type, its Judgment and its look. |
| **Kyurem and DNA Splicers** | Kyurem starts with its own move, Glaciate. From minute 30 a Unique card fuses it into Black Kyurem (+40% damage) or White Kyurem (+25% damage, −15% cooldowns). Glaciate then evolves into Freeze Shock (an electrified lance that paralyses) or Ice Burn (white fire that burns). |
| **Z-Crystal card** | From minute 15 a card can unlock your type's Z-Move for the run (2-minute recharge). |
| **In-run evolution** *(alpha.9)* | Charmander → Charmeleon → Charizard during a run. Pokémon that can evolve get a guaranteed Evolution card at Lv. 16 and 34 (three-stage lines) or Lv. 20 (two-stage lines); Eevee-style branches let you choose. Evolving gives the next stage's stats, a full heal and a permanent bonus. Starting unevolved is weaker early but scales further; starting fully evolved is stronger early and earns a *Seasoned* bonus that grows with your level (about 5% behind late), and only a run that starts as the Mega-capable Pokémon can Mega Evolve. |
| **Dynamax and Z-Move visuals** *(alpha.9)* | Z-Moves gather energy into your Pokémon during the cinematic; Dynamax drops a beam of light, each Max Wave is a real shockwave and the big ones show the type's Max move name. |
| **Chained fusions** | Two bonded, evolved, max-level moves fuse into one; a fusion can fuse again with another until it holds 4 moves, and the move bar shows every move in the slot. |
| **Boss HP bar** | A boss bar at the top centre, below the clock, counters and notices. |
| **Item swap screen** | Finding an item with a full bag shows the new item once, with one card per item you would give up. With empty hands there is now a **Skip** card, so you can decline an item. **Not this run** (R) stops an item from being offered for the rest of the run; it comes back next run (it used to block the item forever, with no way to undo). |
| **Reliable pickups** | Pickups are collected within a reach that grows with your Pokémon's size, along the whole path you moved that frame (a dash or a fast step can't skip over them at low frame rates), and pulled pickups always fly faster than you run. |
| **Item cycling and chest pity** | Items cycle: every item is offered once before any repeats. After 2 chests without an item, the next chest always contains one. |
| **Effects under the Pokémon** | Rings, hit arcs and beams come out from under the sprite; limits on live effects keep busy runs smooth. |
| **Balance** | +10% damage with your own type, Momentum for chained defeats, speed cap, shorter enemy shields. |
| **Save and resume** | Pause → *Save and quit* stores a Normal run; the menu reminds you of it and offers *Resume run* or *Give up*. A resumed run keeps the permanent upgrades it was saved with, so you cannot leave, buy upgrades and come back stronger. Kecleon purchases and your reservation are kept too. Save codes are compressed (about 14,000 characters for a full save). |
| **Daily Challenge** | Every day is one of three formats, picked by the date and the same for everyone: **Medal Rift** (one Pokémon, two rules, score points), **Draft Day** (choose 1 of 3 Pokémon, each with its own rule) or **Gauntlet** (a new rule joins every 5 minutes; survive 20 minutes). Points = defeats + 300 per boss + 5 per second. Bronze / Silver / Gold (3,000 / 8,000 / 15,000 points, or 5 / 10 / 20 minutes in the Gauntlet) pay 1 ticket, 3 tickets and a purple ticket, once per day. A streak of days with a medal pays 50 coins per day (up to 300) and a purple ticket every 7th day. Unlimited tries; the best of the day counts. |
| **Evolution scene** | Evolving from a level-up card plays like the main games: the world pauses, light gathers into your Pokémon, its white silhouette swaps between the old and new form faster and faster, a white flash, then the new Pokémon fades in with a "Congratulations!" box. |
| **Buff badges** | Attack, Speed, Defense and Regen boosts show beside your Pokémon: an icon, one rising arrow per stack (a number past 5), and a ring for the time left that blinks before it runs out. |
| **Max pull** | Two gacha buttons spend every gold ticket in batches of 10 (56 tickets → 50 pulls) or every purple ticket (7 tickets → 70 pulls) after a confirmation. Each batch keeps its own Very Rare guarantee and Z-Crystal roll, and a summary lists the new Pokémon and shinies. |
| **Favorites with a controller** | In the Pokémon list the top face button (Y on Xbox, Triangle on PlayStation, X on Nintendo) toggles the highlighted Pokémon's favorite heart. Cards show bigger Pokémon and a bigger heart. |
| **Legend Shards and Legend Pick** | Every legendary duplicate from the gacha gives a Legend Shard on top of its coin refund, and every Eternatus defeat gives one more (banked when the run ends). On the Gacha screen, **Legend Pick** spends 5 shards on any legendary you don't own, chosen from a grid. |
| **Move previews** | When a level-up card offers a new move, its icon slot becomes a small looping arena: your Pokémon, three foes and the move's pattern in its type colour (shots, beams, cones, rings, orbiting orbs, dashes, meteors, mines, chains, turrets and more), so you can see how it attacks before you take it. |
| **IVs and natures** | Every Pokémon you own has IVs (0-31) in HP, Attack and Speed, each worth -5% to +5%, and a nature: Lonely, Bold, Brave, Timid, Hasty or Relaxed (+10% on one stat, -5% on another, so a random roll is never a real setback) or a neutral one. They apply in runs (an evolved Pokémon keeps the ones it started with). A duplicate re-rolls each IV and keeps the better value. The Pokémon page shows them. Pokémon you don't own (a daily pick) are neutral. **Training** on the Pokémon page: HP Up, Protein and Carbos raise one IV by 3 (up to 31) for 300 coins each, and a **Mint** unlocks a new nature for 1,000 coins. A duplicate also brings its own nature: every nature a Pokémon has had (from duplicates or a Mint) can be switched to for free. |
| **Region maps** | Pressing Play on a Normal run opens the region picker: every region with an in-game snapshot (`tools/capture_regions.ps1` refreshes them), its two biomes and your best time. **Kanto** is open from the start, and each next region unlocks by **defeating Arceus** (the Judgment at minute 30) on the previous one (Kanto → Johto → … → Paldea). **Every region** (the classic run) is always available. Saves from before region maps keep their progress: a player who has beaten Eternatus starts with every region open, and one who has beaten Arceus starts with Johto open. Regions opened under 0.1.1's old rule (survive 30 minutes) stay open. A region run uses its two biomes (for example Hoenn: Sea Grotto, then Igneous Volcano after the first boss) and its wild Pokémon, bosses, rift legendaries and roaming legendaries; a stage with fewer than 4 of the region's Pokémon borrows from the others. |
| **Achievements for the new features** | A new **Regions** tab: Champion of Kanto … Champion of Paldea (defeat Arceus on each map), Region hopper (3 regions) and World Champion (all 9, with a title). Plus Perfect specimen / Flawless squad (31 in all three IVs), Nature's palette (all 11 natures on one Pokémon), Personal trainer (25 vitamins), Fresh breath (a Mint), Shard collector / Shard hoarder (5 / 25 Legend Shards), Hand-picked legend / Legend curator (1 / 5 Legend Picks), All in (a Max pull), Golden day / Gold standard (1 / 10 daily Gold medals), Week of medals (a 7-day daily streak), and Layaway / Regular customer (1 / 10 Kecleon reservations). Region clears, perfect IVs and natures count what your save already has. |
| **Gacha completion bonus** | The more of a region banner you own, the better your odds: Pokémon you're missing weigh up to ×3 within their rarity, and the shiny chance rises smoothly from 1% to 5% at 100% completion. The banner screen shows the current values under the legendary pity bar. |
| **Kecleon shop** | Offers are cards framed in the Kecleon's color, with an icon, price, how many you own and a bar showing how long Kecleon stays. **Reserve**: pay 30% to hold an item you can't afford yet. This uses up the visit's purchase, and the next Kecleon of any color brings it for the remaining 70%. One reservation at a time; if the item can no longer be given (for example Lucky Dice is already active), the 30% is refunded. Keys 1-3 buy offers, 4 buys the reserved item. |
| **Customisation** | HUD layout editor (move, resize and hide every on-run element, with presets), radar switch, per-Pokémon *Use shiny version*, a Poké Ball on each Pokémon's page that shows its rarity, keyboard rebinding and gamepad remapping. |
| **Redeem codes** | Settings → Account → Redeem code unlocks special bundles, random Pokémon and a chosen Pokémon (alpha.9). |

## Feature guide (PDF)

[`docs/Megarift-Survivors-features.pdf`](docs/Megarift-Survivors-features.pdf) lists the features of this port with screenshots. It is rebuilt from this README and `docs/features.json` on every commit by the git hook in `.githooks/` (run `git config core.hooksPath .githooks` once after cloning; it needs `pip install reportlab pillow`). `tools/capture_docs.ps1` refreshes the screenshots by running the game.

## Controls

| | Keyboard | Touch | Gamepad (default, remappable) |
|---|---|---|---|
| Move | WASD / arrows | joystick | left stick |
| Switch move | 1–6, Q / E | tap a move icon | LB / RB, D-pad |
| **Dash** | **Shift**, or **Space** when nothing is nearby to interact with | **DASH** button | **Cancel button** (B on the Xbox layout); it shares the button with "Back" in menus |
| Z-Move | Z | Z button | left stick click |
| Dynamax | C | MAX button | X |
| Build summary | Tab | pause button | View / Select |
| Options (pause) | Esc / P | pause button | Menu / Start |
| Team swap (Team Mode) | R | — | right stick click |
| Choose partner (Pokémon list) | Choose button | Choose button | X / Square / Y |

The gamepad layout (Xbox, PlayStation, Nintendo) and every gamepad button and keyboard key can be changed in **Settings → Controls**. In the Pokémon list, LB / RB step through the regions and the left face button (X / Square / Y) makes the highlighted Pokémon your partner; Confirm on a text box opens the on-screen keyboard.

## Install / build

**PC (Windows):** download `megarift-survivors-<version>-windows.zip` from the Releases page, unzip it and run `Megarift Survivors.exe` (a single file, no install). Windows SmartScreen may warn because the file is not signed: choose *More info* then *Run anyway*. Build it yourself with `tools/build_windows.ps1`.

Download the APK from the [Releases page](https://github.com/Dwr3ker/Megarift-Survivors/releases) (sideload it: Android will ask you to allow installs from your browser or file manager), or build it yourself:

1. Install [Godot **4.4.x**](https://godotengine.org/download/archive/) (developed with 4.4.1) and its **export templates**.
2. Install a JDK 17 and the Android SDK (platform-tools, build-tools 35.0.1, platform 35) and point Godot at them in *Editor Settings → Export → Android*.
3. Open `project.godot` and let it import, then **Project → Export → Android**, or from a terminal:
   ```
   godot --headless --path . --export-debug "Android" build/megarift-survivors.apk
   ```
4. **Release build:** the app's package id is `io.github.dwr3ker.megarift` (set in `export_presets.cfg`; it is deliberately different from the base port's, so both can be installed side by side). Release APKs are signed with a private keystore kept **outside the repository**; `tools/build_release.ps1` reads its path and password from a local credentials file and passes them to Godot through environment variables, so no secret is ever written into the project. See `tools/RELEASING.md`. If you fork this project, change the package id and create your own keystore.
   - Because the package id differs from the original port's, this app starts with an empty save. To move your progress, use **Settings → Copy save code** in the old app and **Paste save code** here.

The in-game **update check** looks at `Dwr3ker/Megarift-Survivors` (`REPO` in `scripts/updater.gd`). Publish each release with the tag `v<version>` matching `application/config/version` (for example `v0.1.1` or a test build `v0.1.1-alpha.1`) and attach the `.apk` and the `-windows.zip`: players on an older version then see an update notice whose button downloads the right file for Android or Windows. Pre-releases (alphas) are included: an alpha is older than its final release (`0.1.1-alpha.1` < `0.1.1-alpha.2` < `0.1.1`). The alpha builds up to alpha.10 used GitHub's "latest release" endpoint and can't recognise newer versions, so testers on them install 0.1.0 by hand once. See `tools/RELEASING.md`. If you fork the project, change `REPO` to your own repository (or empty it to turn the check off).

## Tests

The feature work is covered by headless Godot scripts (one per system, 35 in total), in `tools/tests/`:

```
godot --headless --path . --script res://tools/tests/mega_run_test.gd
```

Each prints `PASS`/`FAIL` per check and ends with `RESULT: PASS` or `FAIL`. Tests that start a run snapshot your save and restore it when they finish. They exercise game logic only: **they cannot tell you how the game feels**.

## Credits and licenses

- **Original game:** [PokéSurvivor by JPTER78](https://github.com/JPTER78/pokesurvivor) — game design, systems, balance and content.
- **Godot / Android port:** [JayElDragon](https://github.com/JayElDragon).
- **Doofcraft edition:** the new systems are inspired by [PokeSurvivor Doofcraft](https://pokesurvivor.doofcraft.com), an independent rewrite of PokéSurvivor. This project is **not affiliated with it**. Rules and numbers were taken from what that game publicly shows and serves to every player (its changelog, in-game text and data tables) and re-implemented here from scratch; none of its code or art is included.
- **Dash:** modelled on the dash in [PokeTide](https://poketide.com) (distance, speed, invulnerability and cooldown), again re-implemented from scratch.
- **Sprites:** [PMD SpriteCollab](https://github.com/PMDCollab/SpriteCollab), CC BY-NC 4.0 — **non-commercial use only**, attribution to the artists required. The full artist list, including the Mega, Primal, Crowned, Forme and Arceus-plate sheets added in this fork, is in [`CREDITS.md`](CREDITS.md).
- **Data and names:** [PokéAPI](https://pokeapi.co). **Fonts:** Pixelify Sans and Noto Sans CJK, SIL Open Font License 1.1.
- **Code:** MIT (see [`LICENSE`](LICENSE)).
- Pokémon and its characters are trademarks of Nintendo, Creatures Inc. and GAME FREAK inc. This is a free, non-profit fan project with no affiliation to them.
