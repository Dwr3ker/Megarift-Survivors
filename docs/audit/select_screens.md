# Audit: mode select and region select (roadmap steps 33 and 47a)

Checked on 2026-11-10 with 1280x720 (16:9) and 1280x960 (what a 4:3 screen gets) and with real controller/keyboard
presses injected into the menu (not just Godot's focus neighbours, because the menu has its own navigation code).
Pictures: `modes_169.jpg` (six modes), `modes_43.jpg`, `region_169.jpg`, `region_43.jpg`.

## Mode select

### Controller and keyboard dead ends
1. **Right from Normal run goes to the top bar**, not to the Hyper switch: Normal run → Right lands on the name pill
   (*Tester*), Right again on the sound button. The Hyper switch is reachable only by going down to Daily and back.
2. **Left from Play (or any option) changes the mode.** Focus jumps to whichever mode tile is level with the button
   (Daily's Play → Left landed on *Permanent challenges*), and since a focused tile is selected, the mode you set up is
   replaced without a press.
3. **Left from a mode tile goes to Back, and Up/Left from Back stay there**: a corner you can only leave with Down.
4. **No shoulder buttons**: LB/RB do nothing; with 13 modes you walk the whole list one by one.
5. B works (Back to the main menu) from the list and from the right panel.

### Layout
6. **The list opens scrolled so the selected mode is off screen**: on both 16:9 and 4:3 the list starts at *Boss Rush*
   with a tile half cut at the top, and *Normal run* (selected) is hidden above.
7. **The list needs scrolling** at 720p: 13 modes + 4 group headings don't fit; the Challenges and Settings groups are
   below the fold.
8. **Rules text is long and boxed**: Daily's four rules overflow into a scroll box inside the panel; small (19 px) text.
9. **The preview is squeezed** between the rules and the options (about 140 px tall at 720p; the Modifiers stat bars are
   clipped).
10. **One-line stat text is cut off**: Normal's Hyper description and *Best Hyper time* run past one line at 720p.
11. **Options pile up**: the Daily Draft picks, Team / Partner / Party pickers and the Modifier grid share a 170 px
    scroll area above Play; the Modifier grid scrolls inside it.
12. **No difficulty or record summary**: Normal shows only the Hyper best time; there is no place for Hard/Nightmare.
13. **4:3 wastes the extra height** of the list column (the list could show every mode on 4:3 but still starts
    scrolled).

## Region select (a pop-up after choosing Normal run)

### Controller and keyboard dead ends
14. **Focus escapes the pop-up**: Down from the regions reaches *Cancel*, and Down again lands on *Team Mode* in the
    mode list behind the pop-up (then Left → Back). You are driving the hidden screen.
15. **Locked regions can't be focused** (they are disabled), so with a controller you can't select one to read why it's
    locked; Right skips over them.
16. **B closes the pop-up but leaves no focus** anywhere: the next press does nothing until you press a direction.
17. **Region buttons have no text** for screen readers / the navigation test (everything is in child labels).
18. The last region is remembered (it is focused when the pop-up opens) - this works.

### Layout
19. **Small**: ten 220x196 cards in a 5x2 grid use about 75% of the width and 60% of the height at 720p; at 4:3 the
    pop-up is the same size, leaving the top and bottom thirds empty.
20. **Tiny text**: the route line and lock reason are 13 px; *Best: 10:00 · Arceus defeated* is squeezed under it.
21. **Locked regions are just dark pictures**: no lock icon, no progress (Pokémon owned / Arceus defeated) on any card.
22. **No difficulty choice**: the region pop-up starts the run straight away, so a difficulty row needs a place either in
    the mode select (before) or here.
