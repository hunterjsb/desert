# PRD: Menus & UI

*Draft, 2026-10-16. Answers to [the vision](../vision.md). Hunter's direction for the
main menu, the system menu and the look of every UI came the same day, written in
another session; this PRD takes it on and fits it to the game as built.*

## Why this system exists

The vision asks for almost no menus: things live in the world and in your hands, and a
device shows its state on itself (a charge light, a hum, a sagging bubble). The UI is
the exception, so it has to be small, quiet and consistent, and it must never stop the
world. The pressure comes from the moon, and a menu is no shelter from it.

## Rules

1. **State shows on things first.** A device's charge, a shield's strain and a crop's
   ripeness show on the device. The overlay carries only what has nowhere else to live:
   the survival bars, the inventory view, key hints and warnings.
2. **The game never pauses.** Opening a menu overlays the running world, storms
   included. Being able to leave the game running at steady state is something a camp
   earns, not something the menu grants.
3. **One theme, one root.** Every UI, menus and gameplay alike, uses one Godot `Theme`
   resource. One UI root node owns focus and the back action. Menus and gameplay UI share
   only the theme and that input routing: no larger UI framework.
4. **Back closes the topmost thing first.** The back action closes the topmost open
   panel (the inventory, say) before it opens the system menu.
5. **Keys come from the bindings.** Every key shown on screen is read from the live
   bindings, never written into text (Devices & mods, "How you handle things").

## The look

- **Near-monochrome.** Off-white text on dark, semi-transparent panels. One accent
  colour, teal/cyan, reserved for power and danger. No sand, rust or scrap styling: the
  world wears the art direction, the UI stays out of its way.
- **Type:** Geist for UI text, Geist Mono for numeric readouts (power, weight, charge).
  Menu text is small, uppercase, widely letter-spaced and light.

## The main menu

A few small words at the bottom of the screen, over the live desert. No background art,
no panels, no big centred buttons.

- **The scene** is the real world seen from a fixed camera, with no player spawned and
  the weather running at normal speed. It keeps its simulation cheap.
- **The words:** Resume (only when a save exists), New game, Options, Quit.
- **Confirm** triggers the highlighted word. Resume is highlighted when a save exists,
  otherwise New game.
- **Moving the selection** works by the menu's up and down actions (keys and a gamepad's
  D-pad); the mouse is optional. The selection shows by brightness or a small marker,
  never a box.
- **New game over a save asks first,** since it would end that run.
- **Into the game (first version):** a fade to black, then the player spawns at a normal
  spawn with the run's ordinary starting weather. The menu's view never chooses where a
  run begins.

## The system menu

The back action, with nothing else open, brings up the system menu over the running
game. It holds **Options** (controls, audio, graphics) and **Save & quit**, which is
safe at any moment, mid-storm included (Profile & saves).

## Skeleton version

*As built, 2026-10-16.*

- **One theme** (`game/ui/theme.tres`, set as the project's) used by every UI: the
  survival bars, the inventory view, the look-at readout, the keys list, the death
  caption, the dev overlay and the scenario menu. Geist for text, Geist Mono for
  readouts (the bars' water and food, what's in a slot, the look-at line, the dev
  overlay's numbers), from the official release, with their licence, in `assets/fonts/`.
  Off-white text, dark semi-transparent panels, and the teal accent for danger: a bar
  under a quarter (health, hunger or thirst) turns teal. Keys on screen are a soft
  lavender for now, one colour in the theme (`Palette/key`), until the open question
  below is settled.
- **The UI root** (`game/ui/ui_root.gd`) owns focus and the back action. Back closes a
  menu over a menu, then a panel of the game's (the inventory), and in a run with
  nothing open brings up the system menu. While a menu is up nothing pressed reaches
  the game behind it and the mouse is free; closing the last one in a run captures it
  again. A gamepad's face buttons confirm and go back, and its D-pad moves the selection.
- **The main menu** is the game's own scene (`game/main.tscn`): the real world on a seed
  of its own, from a fixed camera on the highest sand near its spawn, facing upwind
  where the weather comes from. No one stands there and nothing of yours is in it; only
  the weather moves, at its own pace. A low shade under the words keeps them readable
  over bright sand. The selection shows by brightness alone. New game over a save asks
  "this ends your saved run" with the safe answer highlighted, and back declines too.
  Into the game: a fade to black, the run built (`game/run.tscn`, which is what
  `main.tscn` used to be), and back from black once the sand round you is solid.
- **The system menu**, over the running game under a dark wash: Options, and Save &
  quit. Nothing pauses.
- **Options:** volume, fullscreen, vsync and render scale (confirm steps a value on,
  menu left and right change it either way), kept on this machine in
  `user://settings.cfg`, apart from the profile; the controls list, read-only, every key
  read from the bindings; and Reset profile behind a question, shown only when there is
  a profile.
- **Saves and the profile** are reached only through `/root/Saves` and `/root/Profile`
  (Profile & saves), and a missing one means there are none: no Resume, and Save & quit
  becomes Quit to menu. A save that fails keeps you in the run and asks.
- The dev scenarios (`-- --scenario=<key>`) still start straight into a run.
- `look/menus` shoots the main menu and the system menu, to judge by eye.
- Probes 1–5 pass, each proven against a broken build. Probes 3 and 4 use a stand-in
  for the saves, never the real ones.

## Full version

- Remapping in Options.
- A seamless drop-in from the menu into the run: the camera gliding down, the weather
  blending into the starting conditions (deferred, 2026-10-16).
- Kit selection, once there are kits to choose (deferred; Profile & saves).
- Readouts that move off the overlay onto the suit, where they can.

## Probes

1. **Never paused.** With the system menu open, world time, weather and physics advance
   exactly as they do with it closed.
2. **Back closes the topmost first.** With the inventory open, back closes it; pressed
   again, it opens the system menu; again, it closes that.
3. **The menu's default.** With a save, Resume is highlighted and confirm resumes; with
   none, Resume is absent and New game is highlighted.
4. **New game asks over a save,** and declining leaves the save untouched.
5. **One theme.** Every UI control in the game, menus and gameplay, draws from the one
   theme.

## Out of scope

- Accounts, sign-in, Steam or Discord identity (Profile & saves).
- A pause.

## Open questions

- **Key hints and the accent.** Hunter asked for keys on screen to be coloured; the
  look reserves the one accent for power and danger. Keys could take the accent too,
  stand out by brightness in a thin keycap instead, or keep a colour of their own. For
  now they keep a colour of their own, a soft lavender, one entry in the theme, so
  trying another is a one-line change.
