# Eggs: rules (roadmap step 19)

Eggs are found in runs, go into an incubator, and hatch after you walk far enough in later runs. A hatched Pokémon has
better IVs than a gacha pull and twice the gacha's shiny chance. Numbers marked ⚙ are first guesses to tune in play.

## Where eggs come from
| Source | Chance of an egg |
|---|---|
| Defeating a regular boss | 15% ⚙ |
| Catching or defeating an Alpha | 30% ⚙ |
| A successful rescue | 15% ⚙ |

- At most **2 eggs per run** ⚙, so they stay special.
- The egg drops like an item: walk over it to pick it up (*Egg found!*). Eggs picked up in a run are kept when the run
  ends, however it ends (like Legend Shards), and a saved run keeps them.
- You can hold **12 eggs** ⚙. With 12, no more drop until you hatch some.

## What's inside
- Decided when the egg drops: a first-stage, non-legendary Pokémon (Charmander, not Charizard; never a legendary).
  On a region map it comes from that region; otherwise from any region.
- Its rarity follows the Pokémon's gacha rarity: Common, Uncommon, Rare, Very rare.
- The egg shows a hint, not the answer: its shell has one of **6 looks**, by egg group (from the Pokémon's first type):

| Look | Types |
|---|---|
| Red speckles | Fire, Fighting, Dragon |
| Blue waves | Water, Ice, Flying |
| Green leaves | Grass, Bug, Poison |
| Yellow zigzag | Electric, Normal, Fairy |
| Brown bands | Ground, Rock, Steel |
| Purple swirls | Psychic, Ghost, Dark |

## Hatching
- The **Incubator** (a button at the top-right of the main menu's stage) has **3 slots**. Every egg in a slot gains the distance you walk in each run (all three at once),
  counted when the run ends. Eggs outside the incubator don't progress.
- Distance to hatch, by rarity ⚙: Common **1 km**, Uncommon **1.5 km**, Rare **2.5 km**, Very rare **4 km**.
  (Walking non-stop you cover roughly 3.5 km in a 15-minute run.)
- A ready egg shows *Oh? The egg is moving!* and a badge on the menu; hatching plays a short scene: the egg wobbles,
  cracks, flashes, and the Pokémon appears.

## The hatched Pokémon
- **New to you:** it joins your collection with good IVs: each of HP, Attack and Speed is at least **20** of 31 ⚙.
- **Already owned:** the same as a gacha duplicate: coins back by rarity, and its IVs can rise.
- **Shiny chance: 2%** ⚙ (twice the gacha's 1%; region Shiny Charms apply on top).

## Rewards
- Achievements: *First hatch* (hatch an egg), *Egg collector* (hatch 10, title *Breeder*), *Shiny surprise* (hatch a shiny).

## Controls
- Press a bag egg to incubate it; if the incubator is full it is picked, then press a slot to swap it in (Back cancels).
- Press an incubated egg to take it back to the bag (its distance is kept), or to hatch it when it is ready.
- A tap, click or A press during the hatch skips to the Pokémon.

## Where it lives
scripts/eggs.gd (rules and save), scripts/egg_art.gd (the 6 shells), scripts/incubator_ui.gd (the screen),
scripts/hatch_scene.gd (the scene); drops in main.gd `_egg_try`. Tests: egg_save, egg_drop, egg_credit, egg_ui, egg_hatch, egg_ach.
