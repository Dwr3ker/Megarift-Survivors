# Move slots and full fusions

## Slots
- **4 move slots**, always. Only the selected slot attacks; bonded moves share a slot.
- The **Weapon slots** shop upgrade (5th and 6th slot) is gone. Every bought level is refunded in full the first time
  the new version loads (5,400 for the first level, 11,880 for the second), with a one-time notice. A run saved with 5-6
  slots keeps them until it ends.

## Bonds and fusion
- A bond links 2 moves into one slot; they fire together.
- One fusion per run. It can grow to **4 moves** by bonding another move to it and fusing.
- A **full fusion (4 moves) can't be bonded**. Such bonds in runs saved by older versions are undone when the run is
  resumed, and the bond is given back.

## Where it lives
scripts/main.gd (`_max_moves`, `_bond_options`, `_fix_bonds`), scripts/save_data.gd (`_migrate_wslot`),
scripts/run_save.gd (resume), scripts/menu.gd (refund notice, Lexicon). Test: endgame_moves_test.
