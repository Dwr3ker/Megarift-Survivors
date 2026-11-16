# Terastallization: rules (roadmap step 1, approved 2026-11-09)

Our own take on Tera: a short crystal transformation your Pokémon can use once per run. It changes your Pokémon's type
for attack and defence and makes moves of that type hit harder. Numbers marked ⚙ are first guesses to tune in play.

## Tera type
- Every Pokémon has a **Tera type**, one of the 18 types. It starts as the Pokémon's first type.
- You change it in the Pokédex details (a type picker under the ability). Changing it is free (decided).
- The Tera type follows the species you play as. If your Pokémon evolves during a run, the new species uses its own
  Tera type, but you keep the one you started with for that run (so evolving never changes your plan mid-run).

## Charging and using it
- The **Tera Orb** charges by defeating enemies: full after **300 defeats** ⚙ (a Z-Move needs 250).
  It starts charging from the first minute; bosses count as 10 defeats ⚙.
- When it is full, press **TERA**: the HUD button, the **T** key, or a controller button (all can be rebound in
  Settings → Controls). The D-pad only moves your Pokémon, so Tera can't go there; the controller button is picked in
  step 5.
- **Once per run** (decided). Beating a Legendary rift recharges the orb (the way a Dynamax den recharges Dynamax).
- Not available while Dynamaxed or Gigantamaxed, and you can't Dynamax while Terastallized: they are both
  transformations, and stacking them would be too strong. Mega Evolution and Z-Moves work with Tera.

## While Terastallized (45 s ⚙)
- **Attack:** moves of your Tera type deal **+50%** ⚙. If the Tera type is also one of your own types, **+75%** ⚙.
  Other moves are unchanged.
- **Defence:** you take hits as a **pure Tera-type** Pokémon. A Charizard with Tera Water stops being weak to Rock
  and becomes weak to Electric and Grass.
  The same goes for every type-based protection while it lasts: weather chip damage, lava / poison / spark floors and
  immunity to biome strikes all use the Tera type (Tera Water Charizard is no longer safe on lava). Moves keep your own
  types for the usual same-type bonus.
- **Tera Blast** on activation: a crystal shockwave of the Tera type around you (one burst, like the first Max wave).
- **Look:** the sprite gets a crystal sheen with faceted highlights, and a jewel in the type's colour floats above the
  head. Activation: a crystal shell forms around your Pokémon, cracks and shatters, with a "TERASTALLIZE" banner.
- When it ends: the crystal shatters away, the type returns to normal, and the button shows "Used".

## With the other powers (step 12, checked by tools/tests/tera_combo_test.gd)
| Power | With Tera |
|---|---|
| Mega Evolution, Primal, Crowned | Yes, in either order. The crystal look and the jewel stay on the new body. Mega's own type change doesn't change your defence while Terastallized: you still defend as the Tera type. |
| Z-Moves | Yes. Tera's clock pauses during the Z-Move cinematic. A Z-Move of the Tera type gets the Tera bonus. (A Mega Evolved Pokémon still can't use Z-Moves, as before.) |
| Dynamax / Gigantamax | Never at the same time, in either order. The other button turns grey ("Tera on" / "Max on") and pressing it says why; it's ready again as soon as the first one ends. |
| Necrozma's fusion and Ultra Burst, Kyurem's fusion, Deoxys's formes | Yes. The crystal look and the jewel stay through the change. |

## Modes (step 13, checked by tools/tests/tera_modes_test.gd)
| Mode | Tera |
|---|---|
| Normal, Hyper, Daily, Rifts, Rush, Type survival, Party | Yes |
| Team | Yes, one orb for the team. The Tera type is the Pokémon you control when you press TERA; switching Pokémon ends Tera (the crystal belongs to the one that Terastallized). |
| Tower | No (no Dynamax there either): no button, can't start |
| Challenges, Co-op | Yes, for the player's own Pokémon (not covered by the test yet) |
| Rifts mode | You can Terastallize inside a rift; entering the next rift ends it, and each Legendary rift won recharges the orb |

## Tera bosses (step 14)
- From minute 10 ⚙, about **1 in 5** ⚙ regular bosses Terastallizes at half HP into a random type it doesn't already
  have: crystal look, new type, a short "Tera!" warning. Its weaknesses change with it.
- Rift legendaries and Arceus never Terastallize.

## Decided
- Changing the Tera type is free.
- Once per run, recharged by beating a Legendary rift.
- The D-pad only moves your Pokémon (it no longer also picks moves 1-4); the TERA controller button is chosen in step 5.
