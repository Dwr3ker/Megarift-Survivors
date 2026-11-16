# Wardrobe: rules (roadmap step 51)

Cosmetics for your Pokémon in runs, drawn in code. They change nothing in play: no stats, no hitboxes. You equip one
of each kind in the **Wardrobe** (a button on the main menu's stage), and they show in every mode, Team mode included.

## The three kinds
| Kind | What it is | Where it draws |
|---|---|---|
| **Trail** | Particles left behind as your Pokémon moves; they fade out when you stand still | On the ground, under every Pokémon, attack and warning |
| **Aura** | A soft animated ring at your Pokémon's feet | On the ground, under every attack warning (it never hides one) |
| **HUD frame** | A border style for the Pokémon card at the top left of the run HUD | The HUD |

Trails and auras follow the **Effects quality** setting: fewer particles on Medium, fewer again on Low.

## The first set and where each is earned
| Item | Kind | Earned by |
|---|---|---|
| Sparkle | Trail | Free |
| Flame | Trail | Achievement *Hard to beat* (survive 10 minutes) |
| Bubble | Trail | Medal *Good Samaritan* (rescue a Pokémon) |
| Petal | Trail | Achievement *First hatch* (hatch an egg) |
| Leaf | Trail | Medal *Alpha tamer* (catch an Alpha) |
| Star | Trail | Achievement *Something shines* (get a shiny) |
| Snow | Trail | Medal *Night survivor* (survive a whole night) |
| Rainbow | Trail | Gacha |
| Glow | Aura | Free |
| Ember | Aura | Achievement *Hard as nails* (minute 15 on Hard) |
| Ripple | Aura | Medal *Spelunker* (complete an elemental cave) |
| Bloom | Aura | Achievement *Collector* (own 50 Pokémon) |
| Spark | Aura | Medal *Hawk eye* (discover a secret) |
| Shadow | Aura | Gacha |
| Classic | HUD frame | Free (today's look) |
| Gold | HUD frame | Achievement *Marathon* (survive 30 minutes) |
| Crystal | HUD frame | Medal *Space visitor* (defeat Deoxys) |
| Neon | HUD frame | Gacha |

- **Gacha:** every 10-pull has a **10%** chance ⚙ of one Wardrobe item you don't own yet, from the gacha-only items
  (Rainbow, Shadow, Neon). It shows with the pull results.
- Achievements and medals you already have unlock their items the first time you open the menu after the update.
- Items unlocked show *New look unlocked: (item)* and a dot on the Wardrobe button until you open it.

## Defaults
Nothing is equipped at first (no trail, no aura, Classic frame), so the game looks as it does today until you choose.

## Controls
- The Wardrobe has three tabs (Trails, Auras, HUD frames): LB / RB, Q / E, or press a tab.
- Press an owned item to wear it; press the trail or aura you're wearing again (or **None**) to take it off.
- A locked item plays dimmed and says where it is earned.

## Where it lives
scripts/wardrobe.gd (items, save, unlocks, all the drawing), scripts/cosmetics_fx.gd (the run layer),
scripts/wardrobe_ui.gd (the screen). Tests: wardrobe_save_test, wardrobe_run_test, wardrobe_ui_test.
