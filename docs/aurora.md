# Aurora: rules (roadmap step 61)

Some nights the sky lights up: green, blue and violet ribbons wave across the top of the screen for a short while,
and wild Pokémon are much more likely to be shiny until it fades.

## When
| Rule | Value |
|---|---|
| Chance | **40%** of nights get one ⚙ |
| Start | a random moment **20 to 100 s** into the night (night lasts 3 minutes) |
| Length | **50 s**, fading in and out over 4 s; it always ends before dawn |
| Per night | at most one |
| Where | everywhere the day/night cycle runs (Normal runs, every difficulty, Hyper, Daily, Team, Co-op, Survival...). Inside rifts, caves and the Tower it waits, hidden, and carries on when you come out. |

It runs on the run clock, so pausing freezes it.

## Bonus while it shines
- Wild shiny odds **×8** (Pokémon that appear while it shines, bosses too). Stacks with the Shiny Charm.
- Experience **×1.25**.
- Nothing else changes: no extra enemies, no stat changes.

## What you see
- A banner: *Aurora! Shiny odds ×8 while it shines*, and *The Aurora fades.* when it ends.
- **Aurora 42s** on the HUD line beside the run timer (with the weather, if there is any).
- Ribbons over the top ~40% of the screen, translucent, under the HUD, so no enemy or attack warning is hidden. The night
  tint turns slightly teal but stays as dark. Effects quality Low draws coarser ribbons.
- Medal **Northern lights**: see an Aurora.

## Where it lives
scripts/aurora.gd (timing, bonus, sky), hooked into main.gd beside the day/night cycle (scripts/daynight.gd).
Test: aurora_test.
