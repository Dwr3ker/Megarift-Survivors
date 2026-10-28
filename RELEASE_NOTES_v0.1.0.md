# Megarift Survivors v0.1.0 — pre-release (test build)

## Changes in 0.1.0-alpha.3
- The main menu credit now reads "Made by Dwr3ker" (the original authors stay credited in Settings > About and in `CREDITS.md`).

## Changes in 0.1.0-alpha.2
- **Controller:** Up/Down now stay in their own column. The Gacha tabs no longer bounce left and right, and the right panel of the mode list no longer jumps into the Challenges section (Up past its top returns to the selected mode).
- **Handhelds and 4:3 screens:** the Pokémon collection shows bigger cards (6 per row, 24 per page) and the main menu uses the extra height with a taller stage and bigger buttons.
- **Crash report:** if a run ends unexpectedly, the next launch shows the end of the game log (with the `[run]` clock lines) so it can be photographed and sent. File logging is on for mobile. The Android vibration permission was added; if the game still closes about 30 seconds into a run, try turning Vibration off in Settings and send the report screen.
- **Known issue:** a crash about 30 seconds into a run was reported on a phone and a handheld and could not be reproduced on PC. This build is meant to capture the cause.


> **This is an early test build of a new project.** Version numbering starts at 0.1.0 (the 5.x numbers belong to the original Android port). Expect rough edges and untuned balance.

Released 2026-10-27. Formerly "Pokémon Survivors — Doofcraft-style edition". A fork of [JayElDragon's Godot port](https://github.com/JayElDragon/poke-survivor) (v5.4) of **PokéSurvivor by JPTER78**, adding the systems and balance that make the independent rewrite [pokesurvivor.doofcraft.com](https://pokesurvivor.doofcraft.com) feel different. Everything is still **offline**: no ads, purchases or accounts. The only network request is the update check described below.

> **New package id.** This release installs as its own app, `io.github.dwr3ker.megarift`, next to the original port (`jayeldragonpokesurvivor.mobile`) and starts with an empty save. To bring your progress over, open the old app, go to **Settings → Copy save code**, then in this app use **Settings → Paste save code**. Save codes from v5.4 import unchanged and new data is added around your progress.

---

## Highlights

- **Mega Evolution**: 41 Pokémon can transform mid-run (Megas, Primals, Crowned forms), plus **Mega Rifts**.
- **Rarity-tier upgrade cards** (Common / Rare / Epic / Legendary).
- **Hyper mode**: the whole run at double speed.
- **Eternamax Eternatus**: a real final boss with telegraphed attacks and healing obelisks.
- **Dash** with brief invulnerability, on keyboard, touch and gamepad.
- Wild legendaries, Deoxys formes, Arceus plates and a Z-Crystal card.

---

## New

### Mega Evolution
- From **minute 30** (minute 15 in Hyper) a rare **Unique** level-up card (12% per level-up) can transform a capable Pokémon for the rest of the run: **+30% damage and max HP, +10% speed, −10% cooldowns**, a 2.6 s transformation with invulnerability, and the form's own look and type.
- **41 species:** 37 Megas (Charizard X, Mewtwo Y, Gengar, Gardevoir, Lucario, Rayquaza, Diancie, Darkrai, Zeraora and more), **Primal** Kyogre and Groudon, and **Crowned** Zacian and Zamazenta.
- A Mega cannot use a Z-Move: taking the card removes yours.
- A **MEGA / PRIMAL / CROWNED** badge marks capable Pokémon in the collection and pickers, and the detail screen names the item that triggers it.
- **Zacian and Zamazenta** can be offered Metal Claw (this game's Iron Head line). When crowned it becomes **Behemoth Blade** (Zacian) or **Behemoth Bash** (Zamazenta, a new move), keeping its level, evolution and bond.

### Mega Rifts
From minute 15 a rift's legendary can appear in its Mega, Primal or Crowned form. The chance rises with the run: **5% at minute 15, 15% at 30, 30% at 60**. These bosses have ×1.3 HP, ×1.2 damage and ×1.2 XP, and drop 20% more coins. Defeating one still counts for the base species in your records.

### Rarity-tier upgrade cards
Vigor, Power, Sprint, Reflexes, Armor, Synthesis, Magnet and Learning now roll a tier with bonuses of **×1 / ×1.25 / ×1.5 / ×2**. Odds improve later in a run (minute 0: 70/22/7/1%, minute 30+: 45/32/17/6% for Common/Rare/Epic/Legendary). Tiers show as coloured card headers; Legendary uses the gold card. Other stat cards, and cards that unlock a move evolution, stay Common.

### Hyper mode
A toggle on the **Normal Run** screen. The run clock runs at **2×**, so waves, bosses, rifts, Eternatus (at 30 real minutes), Z-Move/Dynamax unlocks and mega cards all arrive in half the real time. **+30% XP, ×1.5 coins**, rift legendaries scale a little slower, and the on-screen clock shows real time with a HYPER tag. Hyper has its own best time (it never touches your normal record) and two new achievements: **Fast forward** (30 minutes) and **Hyper Darkest Day** (beat Eternatus).

### Eternamax Eternatus
The 60-minute finale is now a proper fight. Damage is a **percentage of your max HP**, and every attack is telegraphed:
- **Eternabeam**: a red warning arc, then a beam sweeps 180° (60%). Dodge it with the dash or stay out of the arc.
- **Cannons**: circles that track you for 1.5 s, lock for 1 s, then explode (30%), two at a time.
- **Rings**: expanding rings with gaps to slip through (15% each).
- **Tail slam**: if you stay close for 3 s (35%).
- **Meteors**: 5–8 impacts near you (25%) that leave pools for 5 s (4% per half second).
- **Three Dark Obelisks** heal it (about 1.2% of its HP per second together) until destroyed.
- It speeds up at 50% HP, enrages at 25%, and goes berserk after 7 minutes. **After the win you choose:** *End the run* (victory, rewards banked now) or *Keep fighting* (full heal, the run goes on). Each defeat pays **1,500 coins, 10 tickets and 2 ×10 tickets** the first time and **1,000 coins, 5 tickets and 1 ×10 ticket** for every repeat, added to your run total on the spot (so ending the run, or falling later, never loses them). Eternatus returns every **30 minutes** (**15 real minutes in Hyper**), stronger each time, with no limit. Rainbow ×25 tickets and pity changes are not part of this build.

### Endgame: Doom, Overcap and endgame cards
Every time you beat Eternatus and keep going, your **Doom level** rises (shown as `DOOM II` next to the clock). Each level adds a rule, not just bigger numbers:
- **Doom 1+**: elites show up at least 25% of the time and carry a trait (**Swift** +25% speed, **Armored** +40% HP). Three new level-up cards appear (12% per level-up): **Second Wind** (an extra revive, one per Doom level), **Overdrive** (dash cooldown −20%, down to half) and **Apex Predator** (+5 Momentum charges, twice). Eternatus returns with the **Gravity Well**: it drags you toward his core for 3 s and explodes for 30% of your max HP. Walk away and you're fine.
- **Doom 2+**: the enemy cap rises from 64 to 80 (the extras have 60% HP). Eternabeam sweeps **twice**, the second one after a 0.9 s warning.
- **Doom 3+**: every rift is a Mega/Primal/Crowned legendary. Dead Dark Obelisks **come back** (one per 45 s).
- **Doom 5+**: enemies hit 10% harder per level.
- **Rewards scale too**: coins you pick up are worth ×(1 + 0.25 per Doom level), max ×2.5; Mega Evolution gains +10% damage per level (max +30%); up to 3 extra wild legendaries at once. The Eternatus payout itself stays flat.
- **Overcap**: when Power, Reflexes, Magnet, Learning or Caliber reach their maximum, they keep appearing as **OVERCAP** cards (half effect, up to 125% of the cap) so late level-ups are never dead.
- **Mega Calamity (second late boss)**: once you've beaten Eternatus and kept going, a Mega / Primal / Crowned legendary arrives **15 minutes before the next Eternatus** (minute 75, 105, 135…; never sooner than 8 minutes after the last Eternatus, skipped if it wouldn't fit). It's a normal chasing boss with about half Eternatus' HP, hits hard, and adds two telegraphed attacks that cost a percentage of your max HP: **Stomp** (a 150-radius zone on itself, 25%) and **Barrage** (3+ zones on you, 20% each). It enrages at 50% HP (40% faster) and each Doom level makes it 15% faster. The same legendary never comes twice in a run. Reward on the ground: **4 tickets, a ×10 ticket, 600 coins and an item**.
- **New achievements**: Marathon (30 min), To the End (60 min), Darkest Day, The Return, Endless and Eternal (Eternatus ×1/×2/×3/×5; the last three in a single run), and Calamity Breaker (beat a Mega Calamity).

### Dash
Short burst of **96 units in 0.16 s** with **0.25 s of invulnerability**, a **3 s cooldown**, damaging every enemy on its path once (25, +5% per level, scaled by your damage bonuses). **Keyboard:** Shift, or Space when nothing is nearby to interact with. **Touch:** a gold DASH button under the Z button. **Gamepad:** new remappable "Dash" action, by default on the Cancel button (it remains "Back" in menus).

### Wild legendaries
From minute 30, up to **three legendaries at once** roam among the normal enemies, arriving about every 6–7 minutes at first and more often later (0.15 → 0.40 per minute by minute 60). They have about 4× the HP of a normal enemy at that point, give 15× XP, and no longer slow the horde or block events the way the old boss-like legendary did.

### Deoxys formes
From minute 5 Deoxys can be offered a Unique **Forme Change** card, then picks Attack (+30% damage), Defense (−23% damage taken) or Speed Forme (+30% speed). It can switch again later (90 s between changes).

### Arceus plates
Arceus starts with **Judgment**, a homing Normal-type projectile only it has. From minute 5 it can find **Plates** (18, one per type) as Unique cards: Arceus and Judgment change type and Arceus wears its type-form sprite until it picks another plate. Plates do not change which new moves are offered.

### Z-Crystal card
From minute 15 a level-up (about 10%) can offer the Z-Crystal of your Pokémon's type. It unlocks your Z-Move for the run with a **2-minute recharge**. Z-Moves unlocked in your profile keep working as before (4-minute recharge).

---

## Balance changes

- **+10% damage** with moves of your Pokémon's own type.
- **Momentum:** each chained defeat adds +2% damage up to +20%; it starts fading 2 s after your last defeat (orange bar under your HP).
- Movement speed is capped at **×2.5** of base.
- Enemy shields last **3.5 s** with a **12 s** lock before the same enemy can be shielded again (was 7 s / 14 s).
- **Rift schedule:** the first check is at **90 s** (it used to be a guaranteed rift at 60 s), then one check every **30 s**. Each check has a **20% chance that grows by 5% for every miss in a row (up to 50%)** and resets after every rift (the base game grew by 20% per miss). Rifts no longer stop at minute 28: they keep appearing until Eternatus, which also lets Mega Rifts reach their full 60-minute curve and keeps Hyper players supplied. Start time and base chance follow Doofcraft; the small pity and the missing cutoff are deliberate choices to avoid long dry spells (in simulation the unlucky 1-in-10 first rift comes at about 4 minutes instead of 6.5). Rift portals still last 45 s and rift fights 120 s.
- Wild legendaries replace the old one-at-a-time boss-like legendary.
- Tuning numbers come from what the Doofcraft edition publishes; values that depend on this game's own enemy scaling (wild legendary and Eternatus HP, obelisk strength) are my estimates.

---

## Other changes

- **62 new sprite sets** from PMD SpriteCollab (45 Mega/Primal/Crowned/Forme/Eternamax forms and 17 Arceus plate forms). Missing Faint/Shoot animations reuse the form's Hurt/Charge, as the base game does for its own species.
- In-game **What's new** entry for 0.1.0, and the version reads 0.1.0.
- The **update check** now looks at this project's own GitHub releases (`Dwr3ker/Megarift-Survivors`) instead of the original port's. It is the only network request the game makes.
- The inherited **Support/donation screen is removed**: it linked to the original port author's Ko-fi and spoke in his voice. The About screen now credits everyone and links to this repository.

---

## Known issues and limitations

- **Balance is untested by long play.** The new fights and rates follow Doofcraft's published numbers where they exist, but no one has played hours of runs to tune them. Eternatus in particular may be too easy or too hard.
- **Translations:** English is complete for all new text. The other languages show the Spanish source text for the new strings (menus and moves from the base port are unaffected).
- **Offline only.** The Doofcraft edition's accounts, friends, co-op, spectating, leaderboards and regional servers are not part of this fork.
- **Not ported:** Rainbow ×25 tickets (and the gacha pity changes that go with them), Waves mode and the Halloween event. The Eternatus rewards are paid in the existing coins, tickets and ×10 tickets.
- Some Mega forms have no Faint/Shoot animation on SpriteCollab and reuse Hurt/Charge.
- The repository still contains unused leftover files from the base port (`main_e14.gd`–`main_e16.gd`, `menu_e14.gd`, `menu_e15.gd`, `*.gd.txt`). Two of them print harmless parse errors during export.
- The release APK is signed with a private release key (certificate SHA-256 `BE:72:4C:B1:D0:A5:E3:4E:B5:09:FC:3D:DE:88:6B:79:57:C9:54:12:28:86:15:88:46:B5:DD:76:A4:F6:8C:30`). It is an APK for sideloading: Android will ask you to allow installs from your browser or file manager. A Play Store upload needs an app bundle (AAB), which this project's export settings do not produce yet.

---

## Credits

Original game **PokéSurvivor** by JPTER78; Godot/Android port by JayElDragon; new systems inspired by **PokeSurvivor Doofcraft** (not affiliated; re-implemented from public information, no code or art copied); dash modelled on **PokeTide**; sprites by the **PMD SpriteCollab** artists (CC BY-NC 4.0, non-commercial); names and data from PokéAPI. Full list in [`CREDITS.md`](CREDITS.md). Pokémon is a trademark of Nintendo, Creatures Inc. and GAME FREAK inc.; this is a free fan project with no affiliation to them.
