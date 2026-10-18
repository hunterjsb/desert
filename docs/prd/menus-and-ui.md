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

A title at the top, "Desert" for now in a light logo like the prototype's, and the
starting kit in the foreground tilting toward the mouse, as the prototype's shield and
radio did (Hunter, 2026-10-16). A few small words at the bottom of the screen, over the
live desert. No background art,
no panels, no big centred buttons. (Hunter, 2026-10-16: the main menu's words "a tad
more spacing and bigger", then "a lot bigger", the pause menu too: menu words are 20,
the main menu's 24; the menus over a running game stand in the middle of the screen, the
aim dot hidden behind them.)

- **The scene** is the real world seen from a fixed camera, with no player spawned and
  the weather running at normal speed. It keeps its simulation cheap, and it's silent:
  a storm at the menu is only to look at (Hunter, 2026-10-16: "super super loud").
  Sound comes back with the run.
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

- **Choosing who you come as** (Hunter, 2026-10-18, after playing it): the origins stand in a
  list on the left, bigger and spaced so each reads at a glance, with a very short line under
  each and "????" for one still locked, and nothing written above the list. The starting kit in
  the foreground slides over to the right as New game opens the choice, and shows the
  highlighted origin's own kit as the selection moves. The main menu shows the kit of the
  origin last played, kept in the profile.

## The system menu

The back action, with nothing else open, brings up the system menu over the running
game. It holds **Options** (controls, audio, graphics), **Save** in a Normal run, and
**Save & quit**, all safe at any moment, mid-storm included (Profile & saves). **New game**
asks who you come as, the origin last played highlighted, then which mode, Normal
highlighted or Ironman; **dying** in a Normal run shows Load last save, highlighted, and
New run (Hunter, 2026-10-16).

## Saying less

(Hunter, 2026-10-18: "we have like a 30 word tooltip on a chassis, almost everything is
overload. its good to have info, but if we cant find more intuitive ways to communicate a lot
of this, then we will need to just stop dropping things out the tooltip.")

- **The look-at line says what it is and the one thing you need now,** a few words. Anything
  else is shown another way, the ghost, a highlight of what would move, a sound, the thing's
  own look, or it isn't said.
- **What makes power says "output",** what uses it "draws".
- **Teaching happens once, where it's needed:** a skill like trimming a sail by the sheet at
  your waist gets a short how-to the first time, then is left to you. Sailing should take
  skill; the how-to says what the controls do, not how to win.

## The dev console

Developer tools come through a console, not a row of function keys (Hunter, 2026-10-16:
"have ` open a console and we can use commands there, and free up f keys for keybinds").
The console action opens a line to type commands into: the scenarios, flying, time warp,
low gravity and the rest of what the dev keys did, with help and history. The dev
overlay keeps its own key. The function keys this frees go to the player, such as quick
save and quick load.

## Skeleton version

*As built, 2026-10-16.*

- **One theme** (`game/ui/theme.tres`, set as the project's) used by every UI: the
  survival bars, the inventory view, the look-at readout, the keys list, the death
  caption, the dev overlay and the dev console. Geist for text, Geist Mono for
  readouts (the bars' water and food, what you carry and its weight, the look-at line, the dev
  overlay's numbers, the console), from the official release, with their licence, in `assets/fonts/`.
  Off-white text, dark semi-transparent panels, and the teal accent for danger: a bar
  under a quarter (health, hunger or thirst) turns teal. Keys on screen are a soft
  lavender for now, one colour in the theme (`Palette/key`), until the open question
  below is settled.
- **The UI root** (`game/ui/ui_root.gd`) owns focus and the back action. Back closes a
  menu over a menu, then a panel of the game's (the inventory), and in a run with
  nothing open brings up the system menu. While a menu is up nothing pressed reaches
  the game behind it, nothing held acts either (move, sprint, crouch and jump wait, on
  foot and on a board, as they do while the screen fades), and the mouse is free;
  closing the last one in a run captures it again. A gamepad's face buttons confirm and go back, and its D-pad moves the selection.
- **The main menu** is the game's own scene (`game/main.tscn`): the real world on a seed
  of its own, from a fixed camera on the highest sand near its spawn, facing upwind
  where the weather comes from. No one stands there and nothing of yours is in it; only
  the weather moves, at its own pace. A low shade under the words, and a soft dark edge
  on every menu word and line, keep them readable over bright sand and in a storm,
  highlighted or not. The selection shows by brightness alone.
- **The title** at the top of the main menu is the game's name, "Desert" for now, kept in
  one place (`UIRoot.TITLE`), so a rename is one line. It's uppercase and widely spaced
  in Geist Light, off-white, centred over the words, with a small moon hung to its left
  as the prototype's logo had: a lit crescent over the faint rest of the disc, drawn in
  the theme's colours. A faint high shade, the twin of the low one, keeps it readable
  over a bright sky; in a storm it reads on its own.
- **The showpiece** (`game/ui/showpiece.gd`) is the kit of the origin last played,
  floating between the title and the words, put together as a new run's is. Before any
  run it's the Surveyor's crate: the light shield and the light panel on top, the board
  racked on its side, the batteries half full and their lights showing it. Each kit says
  what of it is shown, side by side (`Kit.shown`): the Salvager's board and light shield,
  the Homesteader's planter, shield and condenser; one much wider than the crate is shown
  smaller, to fit where the crate does. It tilts toward the mouse, up to 25°, easing
  there, and rests facing you until the mouse moves and once it leaves the window. Dragged, it spins, and
  let go it keeps a little of the spin; a press on a word is always the word's, and
  under Options it can't be grabbed. Only its looks are kept, never a body, so it can't
  fall, blow away or be saved, and it stands in the desert's own light and weather,
  dark in a storm but for its tells, its charge lights and the shield's blue band. New game over a save asks
  "this ends your saved run" with the safe answer highlighted, and back declines too.
  Then New game asks who you come as, with nothing written above: the origins down the
  left in bigger words, well spaced, each with a few smaller words under it (tows a camp,
  rides light, stays put) that brighten with it, and ???? for one still locked, which the
  selection passes over; the origin last played is highlighted, the Surveyor before any,
  so the kit on show stays as it is. As the choice opens the showpiece
  slides aside to the right, easing there, and shows the highlighted origin's kit, the
  last one shrinking away and the next growing in as the selection moves; back slides it
  home to the kit of the origin last played. Then which mode, laid out the same: Normal,
  highlighted, "saves as you go", and Ironman, "death ends the run"; back goes back a
  step, the save untouched. The origin a run is begun or resumed as is kept in the
  profile (Profile & saves). Into the
  game: a fade to black, the run built (`game/run.tscn`, which is what `main.tscn` used
  to be), and back from black once the sand round you is solid.
- **The system menu**, over the running game under a dark wash: Options, Save in a
  Normal run, and Save & quit. Save keeps the menu up and its word says how it went:
  Saved, or Couldn't save. Nothing pauses.
- **The death screen,** in a Normal run, over the running game: "You died", with Load
  last save, highlighted, and New run. Back doesn't close it. Load is Resume, through
  the fade; New run is New game in Normal, on a new seed, the save deleted. Dying before
  the run has ever been saved offers only New run. In Ironman there's no screen: the
  caption says you died and a new run begins at once.
- **The dev console** (`game/dev/console.gd`), opened by the console action in a run with
  nothing else open: a small dark panel near the top of the screen, a line to type into
  under the last few lines it said. While it's up every key goes to it and nothing
  reaches the game: held keys wait as under a menu, the mouse is free, and the world
  runs on. Back closes it before anything else, and so does the console action. Up and
  down step through what was typed, and the focus-next key finishes a command's name, a
  scenario's key or a catalog id. Each command is a thin call into the game: `help`;
  `scenarios`, and `scenario <key>`, which replaces the scenario menu; `fly`; `warp [n]`,
  alone stepping x1, x10, x60; `gravity [m/s²]`, alone low gravity or back; `time <0–1>`,
  on to the next such moment of your local day; `tu [6|9|13]`, Tu's width across the sky in degrees,
  the three under trial, alone the next of them (2026-10-17); `give <id> [n]`, a part into your hands, or a
  device, a stake, a coil or a cable at your feet, by catalog id; and `fresh`, fed,
  watered and whole on a fresh suit's kit. The keys list and Options' controls list
  show the console action and the dev overlay's under a heading of their own, and the
  function keys the dev tools held now go to quick save and quick load (Profile & saves).
  The look-tests keep their own keys and have no console.
- **Options:** volume, fullscreen, vsync and render scale (confirm steps a value on,
  menu left and right change it either way), kept on this machine in
  `user://settings.cfg`, apart from the profile; the controls list, read-only, every key
  read from the bindings; and Reset profile behind a question, shown only when there is
  a profile.
- **Saves and the profile** are reached only through `/root/Saves` and `/root/Profile`
  (Profile & saves), and a missing one means there are none: no Resume, and Save & quit
  becomes Quit to menu. Resume builds the world on the save's seed, puts the run back
  once the sand has settled, and comes back from black only when everything of yours is
  back. A save that can't be resumed says why on the main menu, and a save that fails
  keeps you in the run and asks.
- The dev scenarios (`-- --scenario=<key>`) still start straight into a run, which is
  never saved: no Save, Quit to menu in place of Save & quit, and no autosave, so the
  player's own save is left as it was. A run the console's `scenario` has been used in
  is the same from then on.
- `look/menus` shoots the main menu, with its title and crate, in a storm and on a clear
  day; who you come as with each origin highlighted and with one locked, and the modes;
  the main menu after a Homesteader's run; and the system menu, to judge by eye
  (`look/menus/shoot.sh` builds the sheet).
- Probes 1–9 pass, each proven against a broken build. Probes 3, 4 and 7 use the real
  saves, kept in each probe's own folder; probe 3 is the whole trip: New game, Save &
  quit out on the sand, Resume, and you're back where you were.

## Full version

- Remapping in Options.
- A seamless drop-in from the menu into the run: the camera gliding down, the weather
  blending into the starting conditions (deferred, 2026-10-16).
- Readouts that move off the overlay onto the suit, where they can.

## Probes

1. **Never paused.** With the system menu open, world time, weather and physics advance
   exactly as they do with it closed.
2. **Back closes the topmost first.** With the inventory open, back closes it; pressed
   again, it opens the system menu; again, it closes that.
3. **The menu's default.** The title is the game's name, over the starting crate, which
   is only to look at: no body in it, and a storm doesn't move it. With a save, Resume
   is highlighted and confirm resumes; with none, Resume is absent and New game is
   highlighted, and it asks who you come as, then which mode with Normal highlighted.
4. **New game asks over a save,** and declining leaves the save untouched.
5. **One theme.** Every UI control in the game, menus and gameplay, draws from the one
   theme.
6. **Held keys wait.** With the system menu open and the move action held you stay put,
   on foot and on a board; closed, the same hold walks you and rides you.
7. **Death in Normal.** Saved from the system menu, you die elsewhere: the screen offers
   Load last save, highlighted, and New run, and back leaves it up. Load puts you back
   where and when you saved; New run starts a fresh run on a new seed.
8. **The dev console.** Its action opens it over a run; typed and held keys reach only
   it, `warp 4` runs the clock four times as fast and `scenario dusk` puts you at dusk in
   a run that's never saved; back closes it and nothing else, and so does its action.
9. **The kit on show.** Before any run the main menu shows the Surveyor's kit. New game
   slides it aside, and with the Salvager highlighted it shows the Salvager's; back slides
   it home. After a Salvager run the menu shows the Salvager's kit, and so does the next
   session's.

## Out of scope

- Accounts, sign-in, Steam or Discord identity (Profile & saves).
- A pause.

## Open questions

- **Key hints and the accent.** Hunter asked for keys on screen to be coloured; the
  look reserves the one accent for power and danger. Keys could take the accent too,
  stand out by brightness in a thin keycap instead, or keep a colour of their own. For
  now they keep a colour of their own, a soft lavender, one entry in the theme, so
  trying another is a one-line change.
