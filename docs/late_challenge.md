# Late-run challenge for strong builds

Normal runs only, every difficulty, and only with **Adaptive difficulty** on (Settings). Weak or new builds are not
affected: these rules only ever raise the usual numbers.

## Pressure (open map)
A value **p from 0 to 5** (scripts/pressure.gd), shown in the HUD's **Challenge %** line under the timer.
- **Rises** by 0.03 per second (from minute 5, outside rifts, while you have over 60% HP) when you're clearly
  overpowered: the screen is full (85% of the alive limit) and you took under 5% of your max HP in the last 20 s, or
  regular enemies die within 3.5 s of appearing (median of the last 30).
- **Falls** by 0.05 per second when you took over 30% of your max HP in the last 10 s (counted as hits land, even if you
  heal at once), or when enemies live over 7 s and you're being hit.
- **Effects on new spawns** (old ones are left alone):
  - spawn rate ×(1 + p), surges ×(1 + 0.5p);
  - alive limit +16 per point, at most +32 (64 → 96; 80 → 112 after Eternatus). On Effects quality Low, or Auto when the
    frame rate drops, at most +16;
  - HP ×(1 + 1.5p) (up to ×8.5), damage ×(1 + 0.2p) (up to ×2), elite chance +10% per point;
  - knockback taken ÷(1 + p): with strong area attacks, constant pushes kept enemies from ever reaching you.

## Rift legendaries
Legendary rifts, Mega rifts and Dynamax / Gigantamax dens. A build that would kill the boss in under 30 s gets a longer
fight, but more power still means a shorter one: a fight that would take *ttk* seconds lasts `30 × (ttk / 30)^0.1`.
Kills in 10 s → ~27 s; in 1.5 s → ~22 s; in 0.5 s → ~20 s.
- **Start:** a small floor, 2.5 s of your recent open-map damage, so it doesn't vanish before the first check.
- **Checks** at 0.75, 1.5, 4 and 10 s: the boss's real damage taken per second since the first hit sets its max HP for
  that length. Only ever up; the damage already done stays.
- **Its hits:** at least 8% of your max HP after your Defense.
- Rewards are unchanged.

## Where it lives
scripts/pressure.gd; scripts/main.gd (`pressure` hooks in the spawner, `_spawn_one`, `_cap`, `_damage_enemy`,
`_hurt_player`, `_kill_enemy` path; `_recent_dps`, `_rift_target`, `_rift_scale`, `_rift_calibrate`).
Tests: pressure_test, rift_scale_test.
