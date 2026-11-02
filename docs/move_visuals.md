# Move visuals: one look per move

Every move is drawn with a look that fits its name instead of reusing another type's attack in a different colour.
The look of a move comes from `VFX.for_move(id, type)` (`scripts/vfx.gd`), which merges the per-move entry from
`VFX.MOVE` or `V2.MOVE` (`scripts/vfx2.gd`) over the type's default. The keys are:

| Key | Used by | Meaning |
|---|---|---|
| `proj` | projectiles, boomerangs, mines, meteors, turrets, trails, orbits, dashes, cones | sprite that flies or sits on the ground |
| `melee` | melee moves (`scripts/pfx.gd` `slash`, `PFX.MELEE_STYLES`) | hit animation: impact, jaws, claw, slam, chop, tongue, mandible, cut, dustcloud, whip, vine, feather, and big sprite styles (slashx, kick, fist, hammer, xmark, pincer, shieldbash, stoneaxe, blade) |
| `beam` | beams, chains, special patterns | sprite carried along the beam ("lightning" draws a bolt) |
| `bstyle` | beams (`PFX.BEAM_STYLES`) | solid (default), frost (ice crystals grow off the sides), flare (white-hot core with pulsing rings), stream (thin current full of what it carries), wave (rippling band), charged (throbbing band with sparks) |
| `aura` + `rise` / `inward` | auras | sprites that rise, rush inward, or swirl around you |
| `buff` + `bmode` | buffs and heals | sprite, and how it moves: orbit (circles you), inward (closes in on you), streak (rushes past you), rise (default) |
| `trail` | bullets | particles left behind |
| `pal` | everything | palette override (otherwise the move's type) |

## What changed in this pass

| Before (shared look) | Now |
|---|---|
| Tackle, Body Slam, Karate Chop, Lick: all the same `impact` | Tackle keeps the impact; Body Slam squashes down with dust rolling out; Karate Chop drops a hand-blade; Lick unrolls a tongue |
| Swords Dance, Agility, Harden, Dragon Dance: the same rising arrow | Swords circle you; speed lines rush past; steel plates close in; dragon flames circle you |
| Bite and Bug Bite | Bug Bite snaps small mandibles |
| Ice Beam and Flash Cannon: the same shard beam | Ice Beam grows ice crystals (frost beam); Flash Cannon is a white-hot flare beam |
| Psybeam: the Psychic ring on a plain beam | a rippling wave beam |
| Hyper Beam, Zap Cannon, Fleur Cannon: one cannon beam | Hyper Beam keeps it; Zap Cannon is a throbbing charged beam with electric orbs; Fleur Cannon is a stream of petals |
| Dragon Rage and Ice Burn (White Kyurem): Flamethrower's fire | dragon flames; a pale white flame |
| Grass Knot and Dream Eater: drain hearts | roots rising from the ground; dream bubbles pulled in |
| Powder Snow and Dazzling Gleam: stars | snowflakes; four-point gleams |
| Bonemerang and Psycho Cut: Dark Pulse's crescent | a bone; a psychic blade |
| Spikes and Toxic Spikes: stars | caltrops; dripping poison spikes |
| Fire moves all throwing the same flame | Ember (embers), Fire Spin (rings of fire), Heat Wave (heat shimmer), Flame Wheel (a spinning wheel), Blaze Kick (a flaming boot), Fire Lash (a whip of flame); Flamethrower keeps the flame |
| Confusion, Hypnosis: the Psychic ring | a dizzy spiral with circling stars; hypnotic rings |
| Thunder Wave, Psystrike, Psyshock: twin rings | a zig-zag electric ring; a psychic burst (Psyshock keeps the twin rings) |
| Play Rough, Sacred Sword, Slash, Behemoth Bash, Stone Axe: big X or kick | a scuffle cloud; a blade thrust; one long cut; a shield bash; a stone axe |
| Others | Dark Pulse dark ring, Fairy Wind sparkle gust, Substitute decoy doll, Sludge Wave wave of sludge, Egg Bomb egg, Hail hailstones, Air Cutter thin wind blades, Rock Slide boulders, Petal Blizzard petals, Bubble Beam leaves a bubble trail, Shadow Bone a ghostly trail |

## Keeping it that way

* `tools/tests/move_visuals_test.gd` fails if two moves share the same visual signature (kind, pattern and every
  `for_move` key except the palette), or if a move names a sprite, melee style or beam style that does not exist.
* `tools/capture_moves.ps1` fires every move in a quiet run and writes `docs/move_visuals.png`, a labelled
  contact sheet of all 128 moves, so they can be compared side by side.
