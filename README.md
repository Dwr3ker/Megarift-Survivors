# Megarift Survivors (Android)

A free, fan-made, **offline** survivor-like for Android. Survive endless waves of Pokémon, level up, evolve your moves, open rifts to fight legendaries and face the final boss.

This is a fork of **[JayElDragon's Godot port](https://github.com/JayElDragon/poke-survivor)** of **[PokéSurvivor by JPTER78](https://github.com/JPTER78/pokesurvivor)**. It keeps everything from that port (touch and gamepad controls, 11 languages, local saves, minimap, 960+ Pokémon, gacha, missions, achievements) and adds the systems and balance that make the independent rewrite at [pokesurvivor.doofcraft.com](https://pokesurvivor.doofcraft.com) feel different: Mega Evolution, rarity-tier cards, Hyper mode, a real final boss and more.

> **No ads. No purchases. No accounts.** Your progress stays on your device. The only network request the game makes is a single update check against this repository's GitHub releases when the menu opens (nothing is sent but a standard HTTPS request); it can be switched off by emptying `REPO` in `scripts/updater.gd`.

Current version: **0.1.0 — pre-release / test build** — see [`RELEASE_NOTES_v0.1.0.md`](RELEASE_NOTES_v0.1.0.md). This is an early build of a new project: expect rough edges.

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
| **Deoxys formes** | A Unique card from minute 5 lets Deoxys switch between Attack, Defense and Speed Forme. |
| **Arceus plates** | Arceus starts with Judgment and finds Plates that change its type, its Judgment and its look. |
| **Z-Crystal card** | From minute 15 a card can unlock your type's Z-Move for the run (2-minute recharge). |
| **Balance** | +10% damage with your own type, Momentum for chained defeats, speed cap, shorter enemy shields. |

## Controls

| | Keyboard | Touch | Gamepad (default, remappable) |
|---|---|---|---|
| Move | WASD / arrows | joystick | left stick |
| Switch move | 1–6, Q / E | tap a move icon | LB / RB, D-pad |
| **Dash** | **Shift**, or **Space** when nothing is nearby to interact with | **DASH** button | **Cancel button** (B on the Xbox layout); it shares the button with "Back" in menus |
| Z-Move | Z | Z button | left stick click |
| Dynamax | C | MAX button | View / Back |
| Pause | Esc / P | pause button | Menu / Start |

The gamepad layout (Xbox, PlayStation, Nintendo) and every button can be changed in **Settings → Controls**.

## Install / build

Download the APK from the [Releases page](https://github.com/Dwr3ker/Megarift-Survivors/releases) (sideload it: Android will ask you to allow installs from your browser or file manager), or build it yourself:

1. Install [Godot **4.4.x**](https://godotengine.org/download/archive/) (developed with 4.4.1) and its **export templates**.
2. Install a JDK 17 and the Android SDK (platform-tools, build-tools 35.0.1, platform 35) and point Godot at them in *Editor Settings → Export → Android*.
3. Open `project.godot` and let it import, then **Project → Export → Android**, or from a terminal:
   ```
   godot --headless --path . --export-debug "Android" build/megarift-survivors.apk
   ```
4. **Release build:** the app's package id is `io.github.dwr3ker.megarift` (set in `export_presets.cfg`; it is deliberately different from the base port's, so both can be installed side by side). Release APKs are signed with a private keystore kept **outside the repository**; `tools/build_release.ps1` reads its path and password from a local credentials file and passes them to Godot through environment variables, so no secret is ever written into the project. See `tools/RELEASING.md`. If you fork this project, change the package id and create your own keystore.
   - Because the package id differs from the original port's, this app starts with an empty save. To move your progress, use **Settings → Copy save code** in the old app and **Paste save code** here.

The in-game **update check** looks at `Dwr3ker/Megarift-Survivors` (`REPO` in `scripts/updater.gd`). Publish each release with the tag `v<version>` (for example `v0.1.1`) and an `.apk` asset: players on an older version then see an update notice with a download button. Pre-releases (test builds) are ignored by the check on purpose and are installed by hand; see `tools/RELEASING.md`. If you fork the project, change `REPO` to your own repository (or empty it to turn the check off).

## Tests

The feature work is covered by headless Godot scripts (one per system, 20 in total), in `tools/tests/`:

```
godot --headless --path . --script res://tools/tests/mega_run_test.gd
```

Each prints `PASS`/`FAIL` per check and ends with `RESULT: PASS` or `FAIL`. Tests that start a run snapshot your save and restore it when they finish. They exercise game logic only: **they cannot tell you how the game feels**, and none of this has been verified on physical Android hardware yet (see the release notes).

## Credits and licenses

- **Original game:** [PokéSurvivor by JPTER78](https://github.com/JPTER78/pokesurvivor) — game design, systems, balance and content.
- **Godot / Android port:** [JayElDragon](https://github.com/JayElDragon).
- **Doofcraft edition:** the new systems are inspired by [PokeSurvivor Doofcraft](https://pokesurvivor.doofcraft.com), an independent rewrite of PokéSurvivor. This project is **not affiliated with it**. Rules and numbers were taken from what that game publicly shows and serves to every player (its changelog, in-game text and data tables) and re-implemented here from scratch; none of its code or art is included.
- **Dash:** modelled on the dash in [PokeTide](https://poketide.com) (distance, speed, invulnerability and cooldown), again re-implemented from scratch.
- **Sprites:** [PMD SpriteCollab](https://github.com/PMDCollab/SpriteCollab), CC BY-NC 4.0 — **non-commercial use only**, attribution to the artists required. The full artist list, including the Mega, Primal, Crowned, Forme and Arceus-plate sheets added in this fork, is in [`CREDITS.md`](CREDITS.md).
- **Data and names:** [PokéAPI](https://pokeapi.co). **Fonts:** Pixelify Sans and Noto Sans CJK, SIL Open Font License 1.1.
- **Code:** MIT (see [`LICENSE`](LICENSE)).
- Pokémon and its characters are trademarks of Nintendo, Creatures Inc. and GAME FREAK inc. This is a free, non-profit fan project with no affiliation to them.
