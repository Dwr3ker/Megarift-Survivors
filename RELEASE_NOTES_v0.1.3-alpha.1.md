# Megarift Survivors v0.1.3-alpha.1 (test build)

Released 2026-11-01 as a pre-release for testing the new move visuals. Install over 0.1.2 (Android version code 14): your progress is kept.

## New
- **A look for every move:** all 128 moves now have their own animation that fits the name, instead of another type's attack in a new colour. Body Slam squashes down with dust rolling out, Karate Chop drops a hand-blade, Lick unrolls a tongue, Bug Bite snaps small mandibles, Swords Dance circles you with swords, Agility leaves speed lines, Harden closes steel plates in, Dragon Dance circles you with dragon flames, Ice Beam grows ice crystals, Flash Cannon is a white-hot flare, Psybeam ripples, Zap Cannon throbs and sparks, Fleur Cannon is a stream of petals, Fire Spin throws rings of fire, Heat Wave shimmers, Fire Lash is a whip of flame, Play Rough kicks up a scuffle cloud, and more. The full list is in `docs/move_visuals.md`.

## Changes
- **View and HUD size:** Pause > View zooms from 70% to 250% (it was 100-200%). Settings > Graphics > HUD size (60-140%) replaces Screen size and scales only the run HUD; menus, the pause screen and the level-up cards keep their size.
- **One way out of a run:** the pause screen has a single exit: Save and quit in Normal runs, Quit run in modes that can't be saved. If a Normal run can't be saved right now (a boss fight, a rift...), it explains why and asks before quitting without saving.

## Fixes
- On Windows, the update notice now downloads the Windows version (the `-windows.zip`) instead of the Android APK.
- Grass Knot now raises roots and Petal Blizzard throws petals, matching their names.

## Downloads
- Android: `megarift-survivors-0.1.3-alpha.1.apk`
- Windows: `megarift-survivors-0.1.3-alpha.1-windows.zip` (unzip and run Megarift Survivors.exe)
