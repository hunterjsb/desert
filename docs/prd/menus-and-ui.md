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

## The game icon

The game uses a separate, simple icon: one large sand dune silhouette against a quiet
sky, with no lettering or extra scene details. It is the Godot project's icon, distinct
from the worktree picker's launcher icon (Hunter, 2026-10-19).

## The main menu

A title at the top, "Desert" for now in a light logo like the prototype's, and the
starting kit in the foreground tilting toward the mouse, as the prototype's shield and
radio did (Hunter, 2026-10-16). A few small words at the bottom of the screen, over the
live desert. No background art,
no panels, no big centred buttons. (Hunter, 2026-10-16: the main menu's words "a tad
more spacing and bigger", then "a lot bigger", the pause menu too: the main menu's words
are 24; the menus over a running game stand in the middle of the screen, the aim dot hidden
behind them, and since 2026-10-18 are bigger and roomier still, below.)

- **The scene** is the real world seen from a fixed camera, with no player spawned and
  the weather running at normal speed. It keeps its simulation cheap, and it's silent:
  a storm at the menu is only to look at (Hunter, 2026-10-16: "super super loud").
  Sound comes back with the run; the menu's own music is below.
- **The words:** Resume (only when a save exists), New game, Deeds, Options, Quit.
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
- **The Surveyor is the game as meant, the others novel starts,** shown by design and never said
  (Hunter, 2026-10-18): the Surveyor leads the choice in its own right, and the deed-opened starts
  sit apart from it as variations. Five starts since 2026-10-19: the Surveyor, then apart from it the
  Salvager, the Homesteader, the Varran settler and the Archaeologist, each ???? until its deed or, the
  Archaeologist, both of hers (Profile & saves probes 32 and 34).
- **The prop steps aside for every menu over it** (Hunter, 2026-10-18: "the minimal, no
  background text works for the top title and main menu bc they have a consistent sand or sky
  background... we should always move the prop"). The title and the main menu's words stand
  alone over the sand and sky. Every menu opened from them, Options, the "this ends your saved
  run" question, who you come as and the mode, slides the prop to the right and stands on the
  left, as the origin choice does; the question slides it before the origins come up.
- **Each origin shows one compact piece,** not its kit scattered: the Surveyor its deck as
  put together, the Salvager its board, the Homesteader its planter, the Varran settler his rig
  (2026-10-19), its sail raised as a sail on show always is, its boom swung a little off, and the
  Archaeologist her dig camp of three. Under the piece, on the
  right, its gear is listed, each thing and how many, in bare words with no background
  behind them (Hunter, 2026-10-18: no translucent panel), big enough and edged enough to
  read on their own over bright sand.
- **Resume opens the same view:** the prop is your last camp as the save holds it, what stood
  round you when you saved, with the save's numbers beside it (time played, when it was saved,
  the day, who you came as), and confirm carries on.
- **Unmuting starts the theme at once,** with no silence before it. Built (2026-10-18): it comes
  up in a twentieth of a second, not half a second from silence, where the mute left it, or where
  the song starts when that was in the file's own quiet, the four seconds it opens on and the two
  and a half it ends on (`MenuMusic.SOUNDS`).
- **The deeds menu opens on the deed done last,** or the first one open to do, never always the
  first. Built (2026-10-18, `DeedsGrid.opening`): the latest done of those that show done, or with
  none, the first card open and still to do.
- **The main menu marks what's new** (Profile & saves, deeds), built 2026-10-18: a small dot after
  Deeds while a deed done hasn't been looked at in the deeds menu, and after a start in who you come
  as that a deed has opened, until it's been highlighted (`Words.mark_new`, `Profile.is_new`).
- **Music at the main menu,** its own theme, Hunter's "Salt" (Hunter, 2026-10-18: "use this for a
  main menu theme"), with a mute switch in the bottom left that stays as you leave it. The menu's
  storm stays silent.
- **At night the prop still reads:** a soft light on it, the night kept round it (Hunter: "the
  camp can become night in the menu which is extremely cool, but its so dark you cant see the
  gear").

## The system menu

The back action, with nothing else open, brings up the system menu over the running
game. It holds **Options** (controls, audio, graphics), **Deeds**, **Save** in a Normal run, and
**Save & quit**, all safe at any moment, mid-storm included (Profile & saves). **New game**
asks who you come as, the origin last played highlighted, then which mode, Normal
highlighted or Ironman; **dying** in a Normal run shows Load last save, highlighted, and
New run (Hunter, 2026-10-16).

Over a run there's no prop to move, so the system menu's words stand on a soft dark scrim
(Hunter, 2026-10-18: "pause menu is different -- we can add some opaqueness"), clearly
there, with no hard box; and they have more room and bigger type than the rest: larger
words, more space between them and round the group (Hunter, 2026-10-18).

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

**Built** (2026-10-18, `Hands.describe`):
- **The line** is the thing's name and at most one state after it, the first it has of: ripe,
  or why a sown crop isn't growing ("too bright", "dry"); "no power" on a device that would
  run but is dark; a condenser's water as it makes it ("water 8.7 L/h"); what a planter's tank,
  a canister or the survival kit holds ("1.5/4.0 L"); food left ("150 kcal"); a battery's
  charge ("63/100 Wh"); a radio's station; "output 120 W" on what makes power; "draws 371 W"
  on what uses it; a rolled-up coil's length ("12 m"). Six words at most, its name included, where a
  floating deck had 24.
- **Shown another way instead:** weight in what you carry and how you walk; a device's charge
  on its charge light; floating or resting by where it hangs and its hum; a line's strain in
  its creak; how much line you've reeled in by the coil at your hand; a sail raised, furled
  or torn by its cloth; a find's layer by its paint; what take would move on a deck by a faint
  highlight in the ghost's colour, the bare piece alone where it comes off, else every piece.
- **Not said at all:** hooks and pieces counted, a tray's lift, runners, a panel's or lamp's
  rating, a stake's holding, a sail's area and pull, a planter's stored food, seeds and
  replant share, a Console's instruments counted.
- **Refusals** stay a few words with their soft knock; the stake's are "not sand" and "out of
  reach".
- **How-tos** go through one path, `UIRoot.teach`: shown once a profile (`Profile.learn`)
  near the top of the screen, its keys drawn as bound in the keys' colour, for nine seconds.
  There are three: the sheet's, the ride's and the helm's ([Movement](movement.md#sailing-the-camp-hunter-2026-10-17),
  [the helm](movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)).
- **Probes:** Menus & UI probe 10, a how-to once a profile; Devices & mods probes 18, 19 and 22
  check what the readout and highlight do, never their words.

- **The keys list** (Hunter, 2026-10-18: "f1 is really really hard to read. information
  overload, and tiny text") is a table at the menus' size, 20, edged like them: each key, as
  bound, beside what it does in a word or two, under the headings Moving, Hands, You, Game and
  Dev. What a key does in detail is learned where it's needed: riding's how-to shows the first
  time you ride, as the sail's does (`Controls.HELP`, `Controls.RIDE_HOW_TO_SAYS`).

## The dev console

Developer tools come through a console, not a row of function keys (Hunter, 2026-10-16:
"have ` open a console and we can use commands there, and free up f keys for keybinds").
The console action opens a line to type commands into: the scenarios, flying, time warp,
low gravity and the rest of what the dev keys did, with help and history. The dev
overlay keeps its own key. The function keys this frees go to the player, such as quick
save and quick load.

The console opens at the main menu too, for what needs no world (Hunter, 2026-10-18: "would be
useful for like an `unlockall` command for classes in case i want to test a new class and achv
resets"): `unlockall` opens every start, and deeds can be granted or cleared to test them.

**The dev console for building and testing** (Hunter, 2026-10-18):
- **Any dev command that changes the run** (give, goto, fly, warp, time, gravity, tu, god, fresh,
  scenario) makes it a dev run for deeds: none count from then on. Listing commands (help,
  scenarios, deeds) don't.
- **`fresh` fills you up and leaves what you carry;** the suit's kit isn't restocked.
- **`god`** also lifts the weight limit and lets you take hold of anything, however heavy.
- **The console scrolls back** through what it said.

**Built** (2026-10-18):
- **A dev run:** each of those commands, once it has changed something, clears `World.counts_deeds`,
  the flag a dev scenario clears, and the console says "a dev run from now: no deed counts in it"
  the first time. A command that only shows something, `goto` alone, or `map`, its usage after a
  typo, and the profile's own (`unlockall`, `deed`, `reset`) leave it as it was. The save keeps the
  flag (`dev_run`), and a resumed run takes it back, so a resumed dev run stays one; a death in
  Ironman carries it to the next run, as it does a scenario's.
- **`fresh`** fills health, hunger and thirst and leaves your suit as it is; the scenarios that
  begin on a fresh suit's kit restock it themselves.
- **`god`** has the grasp's strength without limit and never digs you in, and what you carry weighs
  nothing on your pace or your stance (`Grasp.step`, `Suit.burden`): a check on `Vitals.god` at
  those limits, nothing else.
- **Scrolling:** the console keeps its last 200 lines; the wheel scrolls them two lines a notch
  wherever the mouse is, and the page-up and page-down actions a page at a time, while up and down
  still step through what was typed. The head line says how far back it is. While the console is
  up the wheel reaches nothing else, so reeling and bringing nearer or pushing further never fire
  behind it. Anything said brings it back to the latest.
- **Probes:** Dev probes 4 and 5, Menus & UI probe 15, Profile & saves probe 18.
- **A creative menu** for building crafts in a dev run: every part and device in a grid, taken
  straight into your hands (Hunter: "a creative-style menu for building crafts in test").
- **Scenarios are pruned and modernised:** the old ones the chassis and the newer systems have
  overtaken are cut or remade around what the game is now (Hunter: "we should clean up old
  scenarios or repurpose and modernize some").

**Built** (2026-10-19), once the chassis rework landed:
- **The creative menu** (`game/ui/creative_grid.gd`) opens over a run with nothing else open, by the
  creative action (a dev key, listed under Dev) or the console's `creative`, laid out as a menu over a
  run is, the world running on behind it; back or its action closes it. Every part and device give
  makes is a card in the deeds' style, its picture (`ItemIcons`, which now draws any catalog thing as
  it comes) over its name, in groups down two sides: chassis and frames, power, devices, sail and
  rope, tools, food and water, boards by make. Picking one puts a fresh one, as the catalog makes it,
  in your hands; with them full it goes in your suit; one too big for the suit (a Console, a
  condenser, a shield, a planter, a turbine) stands in front of you, and you have hold of it if your
  hands are free, which `god` makes light work of. Rope, wire and hose come rolled, as found. A line
  under the grid says where the last one went. Opening it makes the run a dev run, and the first time
  that line says so. (Since the playtest below, a search and a pick of its groups narrow it, and it
  scrolls.) Its pictures are drawn as the game starts, with the deeds'. `look/creative` shoots it over a run, and with `--scenarios` the
  still camp, every make of board, and the vent as you arrive and as it bursts.
- **`scenario`** alone, or `scenarios`, lists each with a line on what it stages. Each scenario names
  what it lays (`lays`), and `Scenarios.lay` lays it, so dev probe 1 starts every one as the console
  does. A scenario clearing the last one's things unties that one's lines from your waist too, so a
  sheet left on you doesn't keep you from sleeping.
- **The scenarios' fates:**

  | Scenario | Fate | Why, and what it stages now |
  | --- | --- | --- |
  | spawn, clear, wall, storm_500, storm_100, storm_20, deep, clearing, dusk, night, eclipse, far, far_storm | kept | moments of the weather and the sky; nothing of the old structure in them |
  | survive, ruin, farm, radio, clear_skies, afk, lee, chassis, sail, sail_tow, yacht, wreck, console, anomaly | kept | already on chassis decks and plates and the newer systems |
  | kit | cut | a test kit of lone devices and parts on the sand: the creative menu hands over every one |
  | camp | remade as sleep | lone floaters each on a line, a duplicate of afk's moored deck; now dusk at a still camp, a deck of two resting on the sand with the bedroll, the base shield running, a wall to windward on a frame and a radio on the weather station |
  | board | remade | one board by a plate and a bare piece; now a board of every make, charged, by a deck of two resting on the sand |
  | boards | cut | merged into board |
  | vent | new | across the rift from its live vent, facing it, a minute before it bursts in clear daylight, a charged board at your feet |
  | dig | new (2026-10-19) | by a big dune's ruin a storm has just laid bare, the slip face behind it, a scoop in your hands and a sieve carried: dune archaeology's dig, to be tried |
  | walker | new (2026-10-19) | where the run's start puts the Walker, 60 m ahead of it on its route as it comes, a Console holding all three tells beside you on a deck of two, its cable's plug in your hands: the Walker's quest, to plug in as it passes |
- **Probes:** Dev probe 6 (the creative menu) and dev probe 1 (every scenario starts and lays what it
  stages without an error).

**The deeds grid** ([Profile & saves](profile-and-saves.md#deeds-achievements-agreed-2026-10-18-built))
is a menu of its own, reached from the main menu and the system menu.

**Built** (2026-10-18, `game/ui/deeds_grid.gd`), after Hunter's "show relations and a hierarchy":
Deeds stands under New game on the main menu and under Options in the system menu. It opens a tree
of every deed under how many show done ("16 of 44 deeds"), with Back: a branch or two for each family
(Board, Wind, Weather, Camp, Farming, Ruins, Scrap, Signals, Far, Story, Nomad since round two,
2026-10-19, named down the left), each deed a step right of the furthest it waits on, and a line across
from each to what it opens, brighter once that's open. It's laid out as every menu is where it opens:
over the main menu it stands on the left, narrow enough for the prop set aside to its right (940 px,
four steps of 190 px cards); over a run, in the middle on the soft dark field.
- **It scrolls** (round two): taller than the screen has room for (1,062 px), it shows at most two
  thirds of the screen's height of its page, and the wheel or the selection moves it, keeping the card
  highlighted in view. It draws its own bar at its right, what shows in the theme's dim ink over the
  whole in its faint, so nothing in it reaches past the one theme (an engine scroll container's own
  parts style themselves); since 2026-10-19 the bar is the console's and the creative menu's too, and
  dragging it scrolls the tree. It opens scrolled to stand the deed done last in the middle of what shows.
- **A card** is the deed's name and a picture of its thing: the board, the shield, a crop, a planter,
  the Console, a chassis piece, the turbine, the helm, the compass, the heat cutter, a survival kit,
  sealant, a radio, the bedroll; drawn in the theme's ink, a sail on its mast, a storm's wall, an
  anomaly's eye, a bared ruin, a wreck in the sand, a mast's signal, the eclipse, a glint, a vent and
  its boom, Tu overhead, the dark side's stars, the sun's days, and for the story a landmark's mast and
  pennant. Done, it's lit; open but not done, dimmer; still waiting on another, only its thing's
  outline in faint ink and ????. A hidden deed is ???? with no picture until it shows done.
- **The pictures** are Dress's looks of each thing's frame and what's fitted (`ItemIcons`), drawn
  once in a little world of their own as the game starts and kept, so a card costs a texture. (Drawn
  later in a session, once the menu's world had run a few seconds, they came out as slivers, 2026-10-18;
  why is still open.) With no screen to draw on, as in a probe, they stay blank.
- **The card highlighted,** by the mouse over it or the menu's selection, which moves between the
  cards as between words and starts on the deed done last, has a small panel beside it, on whichever side
  has room: the deed's name, what it asks, how far along you are where it's a number or a count
  ("3,250 / 5,000 m", "2 / 3 kinds") or done (in Ironman, if it was), and what it opens. A card
  still locked says only what it waits on, a hidden one only ????. The panel stands over everything
  round the tree, so the scroll never cuts it off, kept on the screen and following its card.
- `look/deeds` shoots the whole tree, its top and its foot, over the main menu and over a run, with
  some done, one of them early, a hidden one done and one not, and a card highlighted
  (`look/deeds/shoot.sh` builds the sheet).

**Playtest (Hunter, 2026-10-19; agreed, built below).**
- **The console has a scroll bar and can be resized.** "There are so many scenarios they dont fit
  in the console. i see we added scroll but lets add a scroll bar and make it resizeable so the
  player can make it bigger." A bar shows where you are in what it said, and you can drag the
  console bigger, kept between sessions.
- **The creative menu scales.** "We will need to find a way to scale it as we will likely have many
  more items." It stays a grid of pictures, with a way to narrow it as it grows: its groups to
  pick from, and a search.

**Built** (2026-10-19), after the playtest:
- **The console's bar** stands beside what it said: what shows of its 200 lines, along the whole, in
  the theme's dim ink over its faint, brighter while held or pointed at. Dragged, or pressed along, it
  scrolls them, as the wheel and the page actions still do; the head line above stays put, saying how
  far back it is. It scrolls a whole line at a time.
- **Resizing:** its sides, its foot and the corners between are taken hold of to pull it bigger or
  smaller, about its middle, from the top where it hangs; the pointer shows which way, and two short
  strokes mark its foot's corner. It stays within the screen, no narrower than 360 px and a few lines
  tall at the least, always whole lines tall. Let go, its size is kept in the settings
  (`Settings.console_size`) and the next session's opens at it; a smaller screen fits it in.
- **At first it's 800 px wide and as tall as `scenario`'s whole list needs**, with the line it was
  typed on and its usage, so the list is read at once wherever the screen has room (a 1080 px screen
  does; at 648 px it's a line short). `scenario` alone and `scenarios` list each on a line of its own,
  their keys in a column, and `help` its commands so.
- **The creative menu scales:** a search line over it narrows the grid to the cards whose name, label or
  id has what's typed, as it's typed; under it, a row of its groups, All first, picks one to show, or
  all of them under their headings, the one picked lit and underlined. What shows is one grid, as many
  cards to a row as the screen has room for (ten at most), as tall as the screen has room for, and the
  rest scrolls by the wheel, its bar (the console's) or the selection, which keeps the card highlighted
  in view; nothing by the name searched for says so. It opens on the first card. By keys alone: up from
  the top row reaches the groups, where moving along picks at once, and up again the search, typing at
  once; down or confirm leaves it for the groups or the first card. The pointer picks a group by
  pressing. `GROUPS` stays the one list of what's on it.
- **One bar** (`game/ui/page_bar.gd`) for the console, the creative menu and the deeds, drawn by the game
  itself since an engine scroll bar styles itself past the one theme.
- `look/creative` with `--devui` shoots the menu narrowed by a search and the console pulled bigger
  saying help and the scenarios.
- **Probes:** Menus & UI probe 15 (its bar tracks each scroll and dragged scrolls it), 17 (the size is
  kept), and dev probe 6 (the search and the groups narrow it, by keys alone, and every thing is still
  reached through its group, once).

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
- **The prop** (`game/ui/showpiece.gd`) is one compact piece of the origin last played's
  kit (`Kit.shown`), floating between the title and the words, put together as a new
  run's is, from the same rig (Rig): the Surveyor's two-piece deck, its battery, light
  shield and light panel on the near piece and the frame on the far one, the board and the
  compass hung on its upright, the batteries half full and their lights showing it; the
  Salvager's board; the Homesteader's planter with its crops, battery, harvester and
  canister. One much wider than the Surveyor's deck is shown smaller, to fit where it does.
  It tilts toward the mouse, up to 25°, easing there, and rests facing you until the mouse
  moves and once it leaves the window. Dragged, it spins, and let go it keeps a little of
  the spin; a press on a word is always the word's, and under another menu it can't be
  grabbed. Only its looks are kept, never a body, so it can't fall, blow away or be saved,
  and it stands in the desert's own light and weather, its tells, charge lights and the
  shield's blue band showing. As the desert's light falls, in a storm or at night, a soft
  key light from over your left shoulder comes up on the prop alone (a render layer only
  it stands on), as bright to the eye whatever the eye has opened to, so its shape and
  colours read with the night left dark round it.
- **Every menu over the main menu** stands down the left in bigger words, a few smaller
  words under each that has them, and slides the prop aside to the right, easing there:
  Options, its controls list, the questions, who you come as, the mode and Resume. The
  title and the main menu's own words stand alone over the sand and sky. It's one state
  (`Showpiece.aside`): a menu opened at the main menu is laid out for it (`UIRoot._menu`)
  and says what the prop shows (`Words.shows`), the kit at home if nothing; back slides it
  home. New game over a save asks "this ends your saved run", the prop already aside, with
  the safe answer highlighted, and back declines too.
- **Who you come as**, with nothing written above: the origins down the left, each with a
  few smaller words under it (tows a camp, rides light, stays put) that brighten with it, and
  ???? for one still locked, which the selection passes over. The Surveyor leads, alone at the
  top in larger words (48, its line 18), a shade brighter at rest than the rest; after a clear
  gap the starts the deeds open stand apart beneath it, smaller (26, their lines 15), closer
  together and dimmer, coming up a moment after it as the choice opens, and one still locked
  fainter still (`Words.set_apart`). Their pieces stand back from the Surveyor's place, shown
  smaller, at home and aside (`Showpiece.NOVEL`). The origin last played is highlighted, the
  Surveyor before any, so the piece on show stays as it is. The highlighted origin's piece
  shows aside, the last one shrinking away and the next growing in as the selection moves,
  and under it on the right its gear in bare words
  at 20, off-white with the theme's soft dark edge and a faint halo, no panel: each thing
  and how many, read from the kit as a run sets it down (`Kit.gear`), two to a line once
  there are many. Then which mode, laid out the same over the chosen origin's piece
  and gear: Normal, highlighted, "saves as you go", and Ironman, "death ends the run"; back
  goes back a step, the save untouched. The origin a run is begun or resumed as is kept in
  the profile (Profile & saves).
- **Resume** opens the same view: Continue, highlighted, on the left, and aside your last
  camp as the save holds it, built from the save's own data with no world
  (`Snapshot.camp`): the thing of yours nearest where you stood and what stood within 12 m
  of it, 8 at most, each with everything stuck or fitted on it and its state (charge, crops, a
  shield's switch), seen from where you stood toward it and fitted to the Surveyor's span.
  Under it, the save's numbers: time played, when it was saved by the clock on the wall
  (today 13:40, yesterday 21:05, 3 days ago), the run's day (counted from its own start, the
  day it began day 1), and who you came as; then how many
  deeds show done ("Deeds 6 of 15"). A save
  from before time played was kept lists the rest. Confirm carries on; back goes back.
- **Music** at the main menu: Hunter's "Salt" (`assets/audio/menu_theme.ogg`, 80 s, looping,
  stereo), from its start as the menu's desert shows, on the menus' bus while the menu's storm
  stays silent (`game/ui/menu_music.gd`). It fades in once the screen is up and out with the
  screen into a run, and comes back from its start on Save & quit; unmuted, it's there at once. (It was the radio's day or
  night track by the menu's own light.) A speaker in the bottom left switches it,
  by a click or by the menu's up and down, round past the first and last words: waves
  while it plays, a cross while it's off, and it stays as you leave it (`Settings.music`).
- **Into the game:** a fade to black, the run built (`game/run.tscn`, which is what
  `main.tscn` used to be), and back from black once the sand round you is solid.
- **The system menu**, over the running game: its words at 28, 26 apart, on a soft dark
  field round them that fades out with no edge (`Field`, a rounded shadow), over a lighter
  wash darkest in the middle (`Scrim`); every menu over a run stands so. It holds Options,
  Deeds, Save in a Normal run, and Save & quit. Save keeps the menu up and its
  word says how it went: Saved, or Couldn't save. Nothing pauses.
- **The death screen,** in a Normal run, over the running game: "You died", with Load
  last save, highlighted, and New run. Back doesn't close it. Load is Resume, through
  the fade; New run is New game in Normal, on a new seed, the save deleted. Dying before
  the run has ever been saved offers only New run. In Ironman there's no screen: the
  caption says you died and a new run begins at once.
- **The dev console** (`game/dev/dev_console.gd`), opened by the console action over a run or any menu: a dark panel hanging from the top of the screen, a line to type into
  under what it said, its bar beside it, pulled to any size within the screen and kept so. While it's up every key goes to it and nothing
  reaches the game: held keys wait as under a menu, the mouse is free, and the world
  runs on. Back closes it before anything else, and so does the console action. Up and
  down step through what was typed, and the focus-next key finishes a command's name, a
  scenario's key or a catalog id. Each command is a thin call into the game: `help`;
  `scenarios`, and `scenario <key>`, which replaces the scenario menu; `fly`; `warp [n]`,
  alone stepping x1, x10, x60; `gravity [m/s²]`, alone low gravity or back; `time <0–1>`,
  on to the next such moment of your local day; `tu [6|9|13]`, Tu's width across the sky in degrees,
  the three under trial, alone the next of them (2026-10-17); `give <id> [n]`, a part into your hands, or a
  device, a stake, a coil or a cable at your feet, by catalog id; `fresh`, fed,
  watered and whole, carrying what you carried; and the deeds' (2026-10-18): `unlockall`, every start
  open whatever deeds are done, `deed <id>`, one granted, `deeds`, which are done, and `deeds
  clear`, all forgotten (Profile & saves). Those and `help` and `scenarios` need no world, so the
  console opens over the main menu and its nested menus too;
  the rest say "only in a run". Closed there, the covered menu and its focus return. The keys list and Options' controls list
  show the console action, the creative menu's and the dev overlay's under a heading of their own, and the
  function keys the dev tools held now go to quick save and quick load (Profile & saves).
  The look-tests keep their own keys and have no console.
- **Options:** volume, fullscreen, vsync and render scale (confirm steps a value on,
  menu left and right change it either way), kept on this machine in
  `user://settings.cfg`, apart from the profile; the controls list, the keys list's own
  table at the menus' 20 with no box (`KeysList`): each key as bound now beside what it does
  in a word or two, under Moving, Hands, You, Game and Dev, read-only until remapping
  comes; and Reset profile behind a question, shown only when there is a profile.
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
- `look/menus` shoots the main menu, with its title and the Surveyor's deck, in a storm, on a clear day
  and with its music off; Options, its controls list and the question over a save with
  the prop aside; who you come as on a first run, the Surveyor alone open, then with each
  origin highlighted, its piece and gear, and with one locked beside one open, and the
  modes; the main menu after a Homesteader's run; the system menu; Resume with that run's
  camp (and the save `LOOK_SAVE` names, if set); and the main menu and Resume at the
  menu's darkest, to judge by eye (`look/menus/shoot.sh` builds the sheet).
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
3. **The menu's default.** The title is the game's name, over the starting deck, which
   is only to look at: no body in it, and a storm doesn't move it. With a save, Resume
   is highlighted and confirm shows the save's camp and numbers, and confirm again
   resumes; a save from before time played was kept still opens. With none, Resume is
   absent and New game is highlighted, and it asks who you come as, then which mode with
   Normal highlighted.
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
9. **The prop aside.** Every menu opened off the main menu stands on the left and slides
   the prop aside; back slides it home. With the Salvager highlighted it shows the
   Salvager's board, and each origin's gear as listed is what its run sets down. After a
   Salvager run the menu shows the Salvager's board, and so does the next session's; the
   music's switch, reached by the menu's actions, stays muted into the next session.
10. **A how-to once a profile.** The first sheet at your waist shows its how-to, its keys as
    bound; tied on again it doesn't, nor in a new run on the same profile.
11. **Deeds open in order** (2026-10-18). A deed done before the deeds it waits on is kept but shows
    dark and uncounted; once they're done it shows done and counts. The card highlighted has its
    panel.
12. **The menu theme.** On the main menu "Salt" fades in on the menus' bus while the world is
    muted; a new run fades it out and stops it; Save & quit brings it back from its start.
13. **The Surveyor leads** (2026-10-18). On a fresh profile New game opens on the Surveyor, first
    and highlighted, its deck on show, and down passes over the starts still locked; with every
    start open it still opens there, its word larger than the rest.
14. **The deeds open on the latest** (2026-10-18). With none done the deeds open on the first card
    still to do; with Green Thumb done and then Hermit, on Hermit. Deeds is new until they're looked at.
15. **The console scrolls back** (2026-10-18). After it has said more than shows, the wheel scrolls up
    to its first line, and what you hold isn't brought nearer; the page actions scroll a page each way,
    the line keeping its focus, and a command run shows at once. Its bar tracks each scroll, and dragged
    to its top shows the first line (2026-10-19).
16. **A hidden deed** (2026-10-19). Open but not done, Eye of the Anomaly is ???? with no picture, its
    panel giving nothing away, and Tells after it waits on ????; done, it shows its name and picture.
    The tree is taller than it shows and opens scrolled to the deed done last, far down it, in view
    with its panel beside it.
17. **The console keeps its size** (2026-10-19). At first it shows every scenario at once, each on a
    line of its own. Pulled out as far as can be, it stays within the screen; pulled in, it's smaller
    about its middle, by whole lines; the settings keep that size, and the next session's opens at it.

## Out of scope

- Accounts, sign-in, Steam or Discord identity (Profile & saves).
- A pause.

## Open questions

- **Key hints and the accent.** Hunter asked for keys on screen to be coloured; the
  look reserves the one accent for power and danger. Keys could take the accent too,
  stand out by brightness in a thin keycap instead, or keep a colour of their own. For
  now they keep a colour of their own, a soft lavender, one entry in the theme, so
  trying another is a one-line change.

## Playtest follow-up (Hunter, 2026-10-19; agreed, in progress)

"I had to go back to main menu ... for unlockall, I should be able to do that from any menu." The console action opens over every menu, including nested origin selection, options, deeds, pause/system menus and creative search. Suspend the covered menu's input, then restore the previous selection and exact usable focus on close. Profile-changing commands such as unlockall refresh a menu already showing locked starts; returning to the main menu is not required.

**Built:** `UIRoot` takes the console action before focused controls can consume it, covers the current menu, and restores its exact word, deed card or search field on close. The origin list is rebuilt with its prior selection so `unlockall` takes effect immediately. Menus probe 18 exercises origin selection, options, deeds, the run system menu, nested run options and creative search; existing console probe 8 still passes.

The once-per-profile how-to is hidden while menus, the console or a fade hold input, so a sail controls hint does not overlap a sailing-notes chapter heading. Its usual timeout continues; it returns to the run only if still current. Menus probe 19 checks covered hints alongside the booklet's bounded text and navigation.

## Reading carried field notes (Sanddune, 2026-10-19)

The normal Varran kit carries its sailing notes so spawn weather cannot blow the
booklet away. Using it from the carry view opens the normal reader. The carried
objects and waist list are hidden while a menu covers them; closing the reader
restores that view with its mouse free. Deed toasts are hidden over menus as
how-to hints already are, so they do not overlap chapter headings. Their normal
timeout continues and the profile retains its unread-deed indication.

## Surveyor field guide reader (agreed and built 2026-10-19)

The Surveyor's carried Guide uses the existing SailingNotes reader through overridable
book title and page data. Preserve sailing chapter/paragraph navigation and reading
from hands, world and carry view. The Guide has five concise single-page chapters;
using it opens its chapter list, with ordinary Back/Chapters navigation. Carry-view
instructions expose Use to read, reinforced by the short first-carried hint; no
automatic reader popup or new reading deed.
Check both existing booklet behavior and the real Guide at 1280 by 720.

As built, SailingNotes exposes `book_title()` and `pages()`; the Surveyor subclass
supplies its own content and first-carried hint. Existing sailing reader probe 19
passes unchanged. In actual 1280 by 720 captures all five Guide pages and their
navigation fit; body heights were 216, 243, 216, 243 and 297 px. All action macros
resolved, Back returned to chapters, and closing chapters restored the open carry
view with its mouse free. The guide's pale survey-cross cover is distinct from the
teal sailing booklet, built from existing procedural pieces and materials.

The Guide's introductory hint uses local 20 px BBCode text, with a shorter first
survey sentence, so it is readable at 720p without changing other hints or the
reader. A second unseen 1280 by 720 capture shows both lines fitting without extra
wrapping or clipping; the five reader pages retain the same measured heights.
