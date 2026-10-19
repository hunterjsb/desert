# PRD: Profile & saves

*Draft, 2026-10-16. Answers to [the vision](../vision.md). Hunter's direction came the
same day, written in another session; this PRD takes it on and fits it to the game as
built.*

## Why this system exists

Two kinds of thing outlast a sitting. **A run** is one life on one moon: it can be set
down and picked up again, and it ends when you die. **The profile** is you across runs:
what you've found and what that has unlocked. They live in separate files, so a run can
end without touching the profile.

**Quick save and quick load** (Hunter, 2026-10-16) are their own actions in a Normal
run: quick save saves at once, quick load loads the last save. Ironman has neither.

**Two modes** (Hunter, 2026-10-16; the vision). **Normal**, the default: you save when
you like from the system menu, the game saves for you every few minutes of play and when
you quit, and death offers to load the last save or start a new run. **Ironman**, chosen
at New game: Save & quit only suspends the run, and death ends it, deleting its save.
Either way there's one run, and one save for it; a run's mode is fixed when it starts.

## The run save

- **Save & quit is safe at any moment,** mid-storm included, from the system menu
  (Menus & UI). Resume puts everything back as it was: where you stood, the time, your
  bars and what you carry, and every thing in the world near you, with its parts, charge, wear,
  water and growth, and every line between them.
- **The world itself isn't saved.** It comes from the run's seed (World & terrain), the
  weather from the seed and the time (Wind & storms), and finds from the seed and the
  weather (Salvage & ruins). A save holds only what you changed: the things that are
  yours, and which finds near you were taken.
- **One save at a time.** New game over a save asks first (Menus & UI). In Ironman, death
  deletes it; in Normal, death offers it back.
- **Versioned.** The file carries a format version, so an old save can be migrated or
  refused cleanly, never half-read.

## The profile

- **One local file,** separate from run saves. No accounts, no sign-in.
- **Unlocks** all go through one call, `profile.unlock(id)`. Steam achievements or cloud
  sync attach there later, and nowhere else.
- **Discoveries.** Finding a kind of thing for the first time reports it to the profile.
  Future kits unlock from discoveries (find a turbine, unlock a turbine-heavy kit).
- **How-tos shown** (2026-10-18). Each how-to is recorded the first time it shows,
  `profile.learn(id)`, so it's taught once a profile, never once a run
  ([Menus & UI](menus-and-ui.md#saying-less)). It's neither an unlock nor a discovery, so
  nothing attaches to it.
- **Reset** is an action in Options, behind a confirmation, and nowhere else.
- **Versioned,** like the save.

## Kits are data

The starting kit (Salvage & ruins, Survival) is a data resource, a list of things and
how many, never code. Only the default kit is built. Alternative kits and choosing
between them are deferred until discoveries can unlock them.

**Origins (Agreed, session 4, part 2; not built).** [The vision's origins and
kits](../vision.md#player-origins-and-kits) change what is balanced: **only the first three kits
(the Surveyor, the Salvager and the Homesteader) are balanced. The rest are novelty starts,
excluded from Ironman** (the session writes "Iron Man"; it is the same mode). Each kit is data
like the default, and each unlocks through `profile.unlock`:

| Kit | Unlock |
|---|---|
| Surveyor | Default |
| Salvager | A playstyle, e.g. long board distance or surviving a storm on carried gear |
| Homesteader | A playstyle, e.g. riding out big storms without moving camp |
| Archaeologist | Proposed: finding a number of landmarks |
| Replacement | Needs a prior save |
| Prisoner | Finding the black site |
| Nomad | The nomad city ending |
| Varran settler | Build and use a dune sailboat (session 4, part 3) |
| Daventry patrol board | Build a patrol-style board yourself (proposed; the exact unlock is open) (session 4, part 3) |
| Hive mind experiment | The last unlock in the game |

The Varran settler and the Daventry patrol board are session 4, part 3's two new novelty starts
([the vision](../vision.md#player-origins-and-kits)). Like the other novelty kits they are not
balanced and get no Ironman, and the session says so in as many words: "These two, like the other
novelty kits, aren't balanced and get no Iron Man mode."

Readings, not in the session. Discoveries here are the first time you find a kind of thing; these
unlocks are also what you did (a playstyle), where you went (a landmark) and how you finished
(an ending), which would be new reports to the profile, each still through `profile.unlock`
(rule 3). Ironman deletes its save when you die, and the Replacement "needs a prior save," so it
can only follow a Normal run. The two new unlocks are also what you did, building and using a
craft. The sailboat's is "build and use," read as fitting found parts into one and then using it,
a report when it first carries you. The patrol board's is "build," proposed, and the session lists
its exact unlock as open.

**Built (2026-10-18): the three balanced origins.** New game asks who you come as before it asks the
mode: the Surveyor, the Salvager and the Homesteader, each with a few words under it, the origin
last played highlighted and the Surveyor before any (Menus & UI). Each is a `Kit` resource
(`game/survival/`): its id, name and words, its start on the moon ([the world
system](../world-system.md#the-feral-layer-and-spawns)), whether it's balanced, what unlocks it
and what of it the main menu shows. The menu lists every origin, one not open to
the profile (`Kit.is_open_to`, through `Profile.has`) as ????. A kit's `unlock` can name a deed
(below), which then opens it. The Surveyor is open from the first run; Frequent Flyer (a long ride on
the board) opens the Salvager, and Hermit (a whole day under a shield) the Homesteader (Hunter,
2026-10-18: "let's lock the two other starts behind some deeds"). The dev console's `unlockall`
opens both for testing. The profile keeps the origin a run was last begun or resumed as (`Profile.last_origin`), whose
kit the main menu shows; reset forgets it. The novelty kits aren't built; an origin that
isn't balanced is offered Normal only. The run keeps its origin (`World.kit`) and so does its save
(`kit`); a new run after a death comes as the same origin. A save from before origins has none and
resumes as it was, from the tuning's start. Spawns probes 2 and 3.

## Deeds (achievements; agreed 2026-10-18, built)

What you've done across every run, kept in the profile, which only grows. A deed both tells
your story and opens things: a start still shown "????" opens by a deed (each kit's `unlock`
names it), and so can a kit variant or a mark on your gear (Hunter: "they should do both").

- **Recorded where it happens:** the system that knows (the board, the shield, the planter, the
  sail, the deck, power, the world's landmarks and sites) records the deed through one shared
  hook the moment it's done. Nothing polls for them.
- **Only real runs count:** a dev scenario's run never records one; Ironman deeds are marked
  as such.
- **The first list** (Hunter, 2026-10-18; the X's are tuning, set to be reachable but earned):
  - Board: jump X m high on it; travel X m on it; **Flying Bling**, ride into a storm at night or
    during an eclipse.
  - Shield: take X of a storm's wear on a shield; **Hermit**, a full day under a shield.
  - Farming: grow three kinds of crop; two planters in tow at once.
  - Sailing: **Set Sail**, a sail's sheet tied at your waist.
  - Camp: six chassis pieces joined in one deck; a Console, a condenser and a battery on one
    deck (the crate the first list named went with the chassis, 2026-10-18).
  - Power: over X W made in one system.
  - Story: **The Old City**, reach Port Morgan; **Hot Tourist Destinations**, reach every named
    landmark; a structure of each of the four ages stood in.
- **Earning one is an event** (Hunter, 2026-10-18: "achv should be a bigger deal when you get them
  in game, sound + badge, plus indication of your unlock on the menu"): a sound of its own and its
  badge, its card's picture and name, shown a moment over the game; and the main menu marks what's
  new, the Deeds word and a start a deed has opened, until you've looked. Built (2026-10-18): the
  badge (`DeedBadge`, through `UIRoot.badge`) is a small dark panel a fifth of the way down the
  screen, under the notes and how-tos at the top, the deed's card picture beside "Deed done" and its
  name; it rises into place over a third of a second, stays three and a half, and fades. Its sound,
  three soft bell notes rising (`deed.wav`, made here, CC0), plays as it shows, on the menus' bus.
  Two done at once wait their turn, each shown and heard alone, and the run's end takes any still
  waiting. Nothing else is said: no note.
  The marks are the profile's (`Profile.is_new`, `seen`): each deed done, and each start it opens
  that wasn't open, is new until the deeds menu is opened, or that start highlighted.
- **Shown in a grid,** reached from the main menu and the system menu: each deed a tile, named,
  with a short line saying what it asks, lit once done (Menus & UI). Then (Hunter, 2026-10-18): a
  tree of what waits on what, each card only a name and a picture of its thing, and what it asks
  and how far along you are beside the card highlighted.

**Built (2026-10-18).** One table, `Deeds.TABLE` (`game/saves/deeds.gd`): each deed's id, name, the
line saying what it asks, its family and the deeds it waits on, its card's thing, whether it's hidden
(none is), and its goal, which is Tuning's (the Deeds group). What a deed opens is each kit's own
`unlock`, so it has one owner. The names Hunter didn't give are proposals, his to rename; the id
stays. Green Thumb is new, so Crop Rotation has one before it.

| Id | Name | Asks | After | Recorded |
|---|---|---|---|---|
| `board_distance` | Frequent Flyer | Ride a board 5,000 m without stepping off; opens the Salvager | | the ride, by how far it has come (kept in the save mid-ride) |
| `board_height` | Big Air | Fly 8 m over the sand on a board | Frequent Flyer | the ride, each tick, by the board's height over the sand under it |
| `board_storm` | Flying Bling | Ride into a storm by night or in an eclipse | Big Air | the ride, the tick you go from clear air into a storm, the sun down or partly behind Tu |
| `shield_day` | Hermit | Spend a whole day under a shield, never stepping out; opens the Homesteader | | Wear's tick: time under a bubble without a break, a day's length, kept in the save |
| `shield_storm` | Sandblasted | Hold off 60 minutes of storm with one shield | Hermit | Wear's tick: a running shield counts the storm where it stands, kept on the shield and in the save |
| `crop` | Green Thumb | Grow a crop | | a planter's harvest, by hand or by its harvester |
| `crops` | Crop Rotation | Grow 3 kinds of crop | Green Thumb | the same, each kind counted once a profile |
| `planters_towed` | Meals on Wheels | Have 2 planters in tow at once | Green Thumb | a line tied or moved, something tied at your waist or taken in your hand: planters along the lines from you, or standing on what they reach, short of a driven stake |
| `deck_home` | All Mod Cons | A Console, a condenser and a battery on one deck | | a device or a part stuck on a deck, or a piece joining with one on it |
| `sail_waist` | Set Sail | Tie a sail's sheet at your waist | | your waist, once the sheet tied on there is laid |
| `deck_pieces` | Six Pack | Join 6 chassis pieces into one deck | All Mod Cons | a piece joining a deck |
| `power` | Power Trip | Make 300 W in one system | Set Sail | Power's tick, by what each pool makes |
| `port_morgan` | The Old City | Reach Port Morgan | | the world, as the history follows you, inside the landmark's footprint |
| `ages` | Carbon Dated | Stand in a structure of each of the four ages | | the world, stepping onto a structure's ground, its era counted once a profile; the Dark Age built nothing |
| `landmarks` | Hot Tourist Destinations | Reach every named landmark | The Old City | the same as The Old City, each of the eight counted once a profile |

- **What waits on what** (Hunter, 2026-10-18: "even though we dont have any deps yet, so make up
  some deps"): made up, each family a branch from an easy deed to harder ones, and the two proposed to
  open starts, Frequent Flyer and Hermit, wait on nothing. A deed's branch is open once everything it
  waits on is done and open in turn.
- **Done out of order:** recording never waits. A deed done before what it waits on is kept in the
  profile with its run all the same, and opens its start if it names one; it shows, lit and
  counted, once its branch opens, and its badge waits until then, shown after the deed that opened it
  (Big Air's, then Flying Bling's).
- **How far along:** a deed that's a number to reach goes through `Deeds.measure(world, id,
  value)`, which keeps the best so far in the profile (`Profile.best`, `improve`), a step at a time
  (250 m, half a metre, a minute, 10 W, one), and records the deed once the goal is reached. A deed
  of different things counts them (`Profile.toward`).

How each X was chosen, from the probes' numbers:
- **8 m over the sand.** A hop on the flat flies 1.7 m over the sand, a pop from a crouch 2.9,
  riding the dunes by spawn 2.5, and pushing flat out off the biggest crest within 12 km 5.3; popping
  off that crest flies 16.8 (Movement probe 20's rides, read as this deed reads them). So it takes
  the pop, on a big crest.
- **5 km in one ride.** A base battery lasts about 23 km flat out over the dunes, and the
  Surveyor's board starts half charged, so about 11 km: 5 km is four minutes flat out, far past
  camp range, a ride you set out on.
- **60 minutes of storm.** The reference camp's shield, always up at the equator, held off 43
  minutes of full storm in three days (none the first, 5 the second, 20 the third): about four
  days of a camp's storms.
- **300 W.** The reference camp makes 240 W at its best, at noon, and its turbine 200 W in a gale,
  while the panels give little in a storm: 300 takes a second turbine or five panels in one system.
- **A whole day** is the day's length, 20 minutes; the reference camp's bubble covers you all day.
  **3 kinds of crop**, **2 planters** and **6 pieces** are Hunter's numbers, tuning too.

- **The hook.** `Deeds.done(world, id, part)` records a deed the moment it's done; with a part (a
  crop, a landmark, an era) the part counts toward it and it's done once enough different ones
  have, across every run. Each check is a comparison where the system already works, and nothing
  looks for deeds on its own. A deed done shows its badge, with its sound.
- **Only a player's own run counts** (`World.counts_deeds`): the game sets it on a run that isn't
  a dev scenario's and clears it the moment `scenario` is used, or any dev command that changes the
  run (`god` among them; Menus & UI, the dev console), and a death in that run keeps it. The save
  keeps it cleared (`dev_run`), so a dev run resumed is one still. The menu's world, a probe's and a
  look-test's count nothing.
- **Kept in the profile** (`Profile.deed`, `did`, `deeds`, `toward`, `best`): each deed with when,
  the run's seed and origin, and whether it was Ironman; what has counted toward each, and the best
  toward each that's a number. Achievements
  attach at `Profile.deed`, as unlocks do at `unlock`. Only reset empties them, and the dev
  console's `deeds clear`.
- **The dev console**, at the main menu too: `unlockall` opens every start whatever deeds are done
  (through `Profile.unlock`, so forgetting the deeds leaves them open; reset closes them), `deed
  <id>` grants one, `deeds` lists what's done and what isn't, and `deeds clear` forgets them all.
- **Probes** 17 to 22, and Menus & UI probe 11.

### Round two: the trees that tie it together (agreed 2026-10-18; not built)

Hunter, 2026-10-18: "what are the big deeds and deed trees we're missing to tie everything
together?", then "lets do it, and do it right, in the right order." Sailing, ruins, storms, wrecks,
the anomaly, the radio gods, the sky and the far places had no deed. Each tree runs from an easy
deed to a hard one, and each ends in a start opening or a step in the story. The numbers are
starting points, tuned from the probes' numbers as the first batch was. Each deed is recorded by
the system that knows, through the one hook.

**What moves.** The shield family becomes **Weather**. Set Sail moves from Camp to the head of
**Wind**, so Power Trip waits on All Mod Cons instead. Carbon Dated moves from Story to the head of
**Ruins**. All Mod Cons and Six Pack follow the chassis rework (built): the home is a Console, a
condenser and a battery stuck on one deck, and a wall or shelf on a frame's face is a piece, where
the frame is a part stuck on the deck.

| Tree | Deed | Asks | After | Recorded |
|---|---|---|---|---|
| Wind | Set Sail | Tie a sail's sheet at your waist (as now) | | your waist |
| Wind | **Close-Hauled** | Make 1 km upwind under sail | Set Sail | the sail's pull on you or your camp: ground made against the wind, kept through tacks |
| Wind | **Land Yacht** | Sail a keeled camp 5 km from its helm | Close-Hauled | the helm, by the ground its camp covers with you seated and a keel under it |
| Wind | **Storm Runner** | Sail 3 km on a storm's outflow, ahead of its wall; opens the Varran settler | Land Yacht | the sail, while the field puts you in a front's outflow and short of its wall |
| Weather | Hermit, Sandblasted | (as now) | | Wear |
| Weather | **Eye of the Anomaly** (hidden) | Live through an anomaly's heart | Sandblasted | Vitals: the hidden term where you stand reaches its full and falls back to nothing with you alive |
| Weather | **Tells** (hidden) | Notice each of an anomaly's three tells | Eye of the Anomaly | each tell where it's shown to you: the compass leaning in your hand, the crackle on a radio you hear, a shield's load past 100% read off the shield or the Console |
| Weather | **Taught** (hidden) | Teach the Walker the anomaly | Tells | the Walker, once it holds evidence for each tell (the session 5 ruling); built with its quest |
| Ruins | Carbon Dated | (as now) | | the world |
| Ruins | **Bared** | Take loot from a site a storm has stripped | Carbon Dated | site loot, from a site whose exposure the storm raised |
| Ruins | **Storm Chaser** | Reach 3 freshly bared sites in one storm | Bared | the world, reaching a site whose exposure this storm raised |
| Ruins | **Dune Reader** | Find a ruin buried in a dune's own lee | Storm Chaser | dune archaeology; built with it |
| Ruins | the archaeologist's two | Assemble the archaeology setup; dig a ruin out yourself; together they open the Archaeologist | Dune Reader | the chassis spec's two deeds, built with the kit |
| Scrap | **First Cut** | Cut a wreck's seam through | | Wreckage, a seam's last cell cut |
| Scrap | **Stripped** | Free every module on one wreck | First Cut | Wreckage, the last module of a wreck freed |
| Scrap | **Clean Hands** | Make a live wreck's hazards safe without a shock or a sickness | Stripped | Wreckage, the last hazard of a wreck made safe, none of them set off |
| Scrap | **Bonepicker** | Scrap one of each of the five wreck kinds | Clean Hands | Wreckage, by kind: hull, hauler, freight pod, lifeboat, hopper |
| Signals | **First Light** | Hear a god inside its window | | the radio, a god's own transmission heard |
| Signals | **Pantheon** | Hear all seven gods | First Light | the same, each god counted once a profile |
| Signals | **Triangulated** | Take three bearings on the living city | Pantheon | the Walker's contact log; built with the stations' second pass |
| Signals | **The Living City** | Find the living city | Triangulated | the world; built with it |
| Far | **Totality** | Watch a whole eclipse out in the open | | the sky, the sun gone in and come out with you outside any bubble |
| Far | **Glint** | Reach a site whose glint you saw from 5 km off | Totality | the Skyline marking a stand-in's glint shown to you, the world reaching that site |
| Far | **Live Vent** | Stand at a live vent's mouth | Glint | geology, a vent's mouth while it's live |
| Far | **Thunder** | Hear a burst's boom from 20 km away | Live Vent | Rumbles, a boom heard at that distance |
| Far | **Under Tu** | Stand with Tu overhead | Totality | the sky, Tu within 5° of straight up |
| Far | **The Dark Side** | Stand where Tu never rises | Under Tu | the sky, past the Rim |
| Nomad | **Ten Days** | Live 10 days in one run | | the run's clock, from World.began |
| Nomad | **Moved House** | Move your camp 20 km in one day | Ten Days | the camp, its deck's ground covered since the day began |
| Nomad | **Slept It Off** | Sleep through a storm with nothing lost from your camp | Ten Days | Sleep, waking after the storm with every piece of your camp still on it |
| Nomad | **Nomad** | A deed from each of Wind, Weather, Ruins, Signals and Far | each of those trees | the hook, once the last of them is done |

- **Hidden deeds** show "????" and no picture until they're done; their branch's lines still show
  that something waits there. The anomaly's deeds are hidden so the grid doesn't say anomalies
  exist before you've learnt them by their tells.
- **Nomad ties the trees together:** its card stands apart, with a line from each of the five
  trees, lit where you've done one. It waits on any one deed of a tree, not a named one, so the
  table's `after` gains "any of a family".
- **The grid holds every tree:** about forty deeds in eleven trees, each tree a column under its
  name. It scrolls, and opens on the latest done (the devex round).
- **The order.** Each part waits for what it reads to land:
  1. After the devex, chassis, sail-trim and board rounds land (all landed 2026-10-19): the hidden
     flag, the grid holding every tree, the moves above, and every deed whose system is built:
     Wind (without its start), Weather to Tells, Ruins to Storm Chaser, Scrap, Signals to Pantheon,
     Far, and Nomad's first three.
  2. With the chassis spec's starts and kits: Storm Runner opens the Varran settler.
  3. With dune archaeology: Dune Reader and the archaeologist's two, which open the Archaeologist.
  4. With the radio stations' second pass and the Walker's quest: Triangulated, The Living City,
     and Taught.
  5. Last, once every tree it reads has landed: Nomad and its "any of a family", so that what it
     asks never changes after someone has earned it.

## Starts on the chassis, and two new kits (agreed, 2026-10-18 spec; the starts built, the kits not)

From the [chassis spec](../chassis-kits-dunes-2026-10-18.md); balance targets the Surveyor only.
- **The Surveyor:** two chassis joined as a deck and a frame with an upright on its side, its gear
  stuck on so the system is learned by sight: a battery, the shield, a compass, and the hoverboard
  hung on the upright. It keeps the board: it's how the Surveyor tows its camp and kites.
- **The archaeologist** (a woman on a Daventry-funded university expedition, hunting proof of why
  humanity must be careful; Zan only partly fits that story: the hive-mind war mattered, but
  abandonment, oversight and human failings killed it): ground radar on a Console, a digging tool
  and sifting gear. Opened by two hard deeds: assemble the archaeology setup; dig a ruin out of a
  dune yourself, its site laid bare by your digging rather than a storm's.
- **The Varran settler** (an imperial settler who trusted tech over the land): a minimal fast sailing
  rig, an out-of-place heavy navigation computer rich in wind and storm, two batteries, a small
  shield carried with its own battery and raised round himself in storms (never on the sail: the
  bubble would block its wind), riding a hoverboard as the keel. Opened by building and using a
  dune sailboat. What sits outside his bubble wears in a long storm, as anything does; a light
  panel can go on top, weakly.
- **The Salvager and Homesteader** stay deed-opened and get reworked onto the chassis.

**Built (2026-10-18), the three origins on the chassis.** Each start is a rig, data steps the
one builder (`Rig`) puts together, as the scenarios and the showpiece are (Devices & mods):
- **The Surveyor:** two pieces joined, floating on a tray under each, set back under its
  weight so it rides within 2° of level; a frame on the second piece with a wall on its back,
  the board hung on the wall's outside with a compass beside it; a battery, the light shield
  and the light panel stuck on the first piece; a hook on its outer ring, moored to a stake on
  a 6 m line. 68 kg, it draws about 136 W floating (the crate drew 91 W), so its trays give way
  at about 0.43 days on the probes' seed instead of 0.56, while the shield runs the whole first
  day (Power). Still floating, as a camp you tow should, and viable; the kits agent may
  rebalance it. Carried, as before: a canister, a ration and the bedroll.
- **The Salvager:** a plate, one chassis resting on the sand with the light shield and a full
  battery stuck on it, beside the board and the heat cutter; the scoop, sealant and med kit
  carried.
- **The Homesteader:** a deck of two resting on the sand, its homestead: the base shield, a big
  battery and a solar panel on one piece, the condenser with its canister and a battery on the
  other, all one pool; the planter and the turbine beside it as they stand, with a common and
  a strong cable to wire them.
- **The main menu's showpiece** builds the origin's rig, so the Surveyor shows its deck, wall
  and board.

## Ending flags (proposed)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); proposed, and none of it
is built.* The build note: "Track the Daventry axis as a running 'loudness' value from dead-lane
transmissions and launches, and the Cistern axis as dormant / restored / linked. Don't build
epilogues yet." The axes are the endings' cross-cutting modifiers ([the
vision](../vision.md#the-three-axes-varran-daventry-and-cistern)).
- **Daventry loudness** is a number that grows as the player transmits on, or flies down, the dead
  lane. "Player control is how careful you are with the transmitter." The stolen freighter and the
  pathfinder read it: loud, and Daventry waits at the lane; quiet, and the passage is unnoticed.
- **The Cistern state** is one of three: dormant, restored, or linked into the network.
- **Nomad reputation** (session 5, [the vision](../vision.md#nomad-reputation-agreed-session-5-not-built)) is a
  third running value: a number that rises with sails and goods returned at a shrine and falls with theft,
  and that, through the nomad quest line the Walker's quest ties closely to, decides whether you may tend to
  the Walker. How it is counted is not said.

Readings, not in the session:
- **They are a run's changes, so they belong to the run save,** whose rule is that a save holds
  what you changed. Each is small: a number and one of three states. The Cistern state is the
  landmark's record in the sense [World & terrain](world-and-terrain.md#landmarks) reads it. They
  are not profile entries, since the profile grows by unlocks and discoveries only (rule 3) and
  these are neither.
- **Saving never changes the run** (rule 2), so a resumed run has exactly the loudness it saved
  with. The session gives the value no clock of its own.
- **Ironman:** the flags go with the run, like the rest of its save.
- **Not said:** whether the loudness ever falls; whether a flag carries into a later run, since
  "persist the player's changes" doesn't say within a run or across runs; and which launches
  count. The session's table has both escape endings "Unaffected," so a launch here is read as a
  launch into the dead lane.
- **The player isn't told.** There is no exposition, so a flag is heard on the radio and seen in
  the epilogue, not shown in a menu. How the player learns a choice matters is open. A seed:
  hearing a Daventry broadcast hints they can hear you
  ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md#offstage-states-on-the-air-agreed-session-4-part-3-not-built)).

## Rules

1. **A save holds what you changed, never what the seed already says.**
2. **Saving never changes the run.** Saving and resuming at once gives the same world,
   tick for tick, as not saving at all.
3. **The profile's unlocks, deeds, discoveries and how-tos shown only ever grow, by
   `profile.unlock`, `profile.deed`, discovery and `profile.learn`,** and only reset empties
   them, or the dev console's `deeds clear` the deeds. Beside them it keeps the origin you last
   came as.

## Skeleton version

- The run save and resume, Save & quit from the system menu, Resume from the main menu,
  and the two modes: Normal saving as you go and offering the save back after a death,
  Ironman's death deleting it.
- The profile file with discoveries and `profile.unlock`, and reset in Options.
- The default kit as a data resource.
- The probes below, all passing.

**Built** (2026-10-16), waiting at the gate. Two autoloads: `Saves` (`has_run`, `save`,
`save_in_background`, `run_seed`, `ironman`, `restore`, `delete`) and `Profile`
(`unlock`, `discover`, `learn`, `has`, `reset`, `remember_origin`, `last_origin`). Menus & UI
calls them from Save, Save & quit, Resume, New game, the death screen and Options.

- **The mode** is chosen at New game, held by the run (`Runs.ironman`) and kept in its
  save, and Resume reads it back. A save from before modes has none and resumes as
  Normal, so the format's version didn't change.
- **Normal saves:** Save in the system menu, a save by itself after `autosave_minutes`
  (Tuning, 3) of play since the last one, and one when the game's window closes. The
  first storm comes three to eight minutes in, so dying in it has a save to go back to.
  The autosave is taken between two ticks, ahead of the run's own nodes, and written to
  disk on a worker thread; never while you're dead, while a run is being put back, or
  while the screen fades.
- **What an autosave costs the frame** (taking the run and encoding it), measured on a
  busy machine: about 0.7 ms on a fresh run with its kit, and 1.1 ms (1.5 at worst) for
  the probes' camp mid-storm, 8 things and 3 lines; it grows by about 20–40 µs for each
  thing of yours. The disk write, about 0.25 ms there and unbounded on a slow disk, is
  off the frame.
- **A death in Normal** keeps the save and shows the death screen (Menus & UI): Load
  last save is Resume, and New run is New game in Normal.
- **What a save holds:** you (where you stand, which way you face and look, how you're
  moving, stamina, your bars, everything you carry (each thing with its state, as a
  radio's dial, volume, beacon and charge, one saved before the dial on its channel's
  carrier; a save from before, with five slots, resumes with
  their contents carried), what's in your hands, at your waist or being
  hauled, and the board you ride with its ride as it stood), the clock and when on it the
  run began (its day 1; a save from before kept none and counts from the clock's zero),
  how long the run has been played (a save from before kept none, and its run never
  counts it) and when it was saved, the moon position, the engine's origin, and where power, wear, farming and
  your body are in their ticks. Then everything of yours: each thing by its
  catalog id, where it is and how it's moving, its wear, charge, water, growth and
  harvests, a shield's switch and how far its bubble has bloomed, a stake driven or not,
  every part in every slot, down to a line's end on a hook's ring, and on a chassis
  everything stuck on each piece (version 2, below). Every line and strong cable with its ends, length and load, and its
  strand's points as drawn, so nothing snaps or flings on resume. Of the finds, only the
  chunks near you: how hard the weather had been when each came near, and which finds were
  taken. No ground, no weather, no untouched find. A camp mid-storm saves in about 13 KB.
- **Places are world metres,** in doubles, and the engine's origin is kept, so a resumed
  run computes in the same numbers as the one saved.
- **Resume** happens on a world built on the save's seed once it has settled. The fresh
  world's own things (its kit) go; the clock, you and the finds' memory are back at once,
  and your things follow as soon as the ground under them is solid, the clock held still
  until then (`Saves.restored` says when). A resumed run gets no new kit. Saved mid-ride,
  you're back on the board going as you were; a board that can't carry you then is set
  down as stepping off would leave it, and comes down on the sand.
- **Versioned:** each file opens with what it is and its version, and one of another
  version, or not a save at all, is refused with the reason (`refused`) before any of it
  is read. A refused profile is never written over, except by a reset.
- **Version 2** (2026-10-18, the chassis): each body is saved with what's in its slots by
  their place in its frame's list, and with what's stuck on it, each by the piece it's on,
  its pose on that piece and the face's way out, and its own record: a part with its state,
  or a device with its own slots and state. A deck's pieces are saved in the order they
  joined, each saying how: across a ring (the piece it joined, that piece's ring, its quarter
  turns) or on a frame's face (the piece the frame stands on, the frame among what's stuck
  there, the face's name). Resuming builds each piece alone with what's on it, then joins it,
  so nothing joins before what it hangs from. A version 1 save, from before, is refused before
  a byte of it is read, and the menu says plainly why: "it was saved before camps were rebuilt
  round the chassis, so nothing in it would sit where it was". The profile, its deeds and its
  unlocks carry on untouched; only the run is lost, an alpha's honest break.
- **A death in Ironman deletes the save,** so the main menu offers only New game, and
  a new Ironman run begins at once.
- **A dev scenario's run is never saved,** and a death in it begins a new run without
  touching the save on disk. That's a run started with `--scenario=<key>`, or one the
  console's `scenario` has been used in.
- **Quick save and quick load** (Menus & UI's console freed their keys). In a Normal run
  quick save is the system menu's Save, at once, with a small note saying Saved, or
  Couldn't save; quick load is the death screen's Load last save, through the fade, and
  with no save it says so. Ironman ignores both with a short note, and a dev scenario's
  run never saves. With a menu or the console open, neither acts.
- **The profile** is `profile.save` beside the run save. Taking a find reports every kind
  it held, the first of each being a discovery. `has(id)` answers for unlocks and
  discoveries alike.
- **The default kit** is the starting kit's data resource (`game/survival/standard_kit.tres`).
- **Probes** run on a folder of their own, never the player's save or profile.
- **Found along the way:** a device seated on another trailed its seat a little every
  tick, which added up on a floating deck; it's held on its seat every tick now.

## Full version

- Kits unlocked by discoveries, playstyles, landmarks and endings. The first three are
  balanced and chosen at New game (built), the novelty starts are not, and Ironman excludes
  them (Kits are data).
- Steam achievements and cloud sync, attached at `profile.unlock`.

## Probes

1. **The round trip.** Save mid-storm with a camp running (a shield up, a floater on
   lines, a planter growing, a charge draining), resume, and the next minute matches a
   run that never saved, to within physics' own repeatability.
2. **Only what changed.** A save holds no terrain and no untouched finds, and stays small.
3. **Death ends an Ironman run.** After dying the save is gone, and the menu offers
   New game.
4. **Versions.** A save or profile from an unknown version is refused with a message,
   never half-loaded.
5. **Discoveries are recorded once,** survive a new run, and reset empties them.
6. **Saved mid-ride.** Resumed, you're back on the board at the saved speed and ride on
   where the run never saved went; with the ride dropped from the save, the board comes
   down on the sand instead of hanging in the air.
7. **A coil carried.** Saved carrying a 6 m coil, the kit's length, and a cable, and
   resumed, the coil comes out a working 6 m line and the cable whole.
8. **Normal saves as you go.** Saved by hand, no save lands before the autosave period
   is up and one does just after; none while you're dead, in Ironman, or in a dev
   scenario's run.
9. **The mode survives.** An Ironman run saved and resumed is still Ironman's: no Save,
   and death deletes its save. A save with no mode resumes as Normal.
10. **Quick save and quick load.** Quick saved in Normal and moved elsewhere, quick load
    puts you back where and when you saved, through the fade. In Ironman neither saves
    nor loads, and a dev scenario's run never saves.
12. **A deck resumes.** A floating deck of three pieces, two of them turned, left when the
    first piece joined came off its end, trays under all, moored by a hook on its ring, a
    frame with a wall and a shelf on one piece, the board on the wall and a battery on the
    shelf, a running light shield and two batteries on another, is saved and resumed: the
    same pieces stand on the same places, every thing on the same face of the same piece in
    the same pose with its charge, the shield running and the line tied, and it floats on.
13. **What you carry.** Saved carrying a radio on the weather station, a compass and
    three canisters and resumed, the radio is carried on the same frequency with the same
    charge, playing from you with its words showing, the compass is carried, and the
    canisters stack as one, each with its water. A save from before, with five slots and a
    radio kept as a channel, resumes with their contents carried, the radio on that channel's
    carrier.
14. **An older save is refused** (2026-10-18). A version 1 run save isn't offered, says
    plainly why, and resuming it changes nothing, while the profile's unlocks and deeds
    carry on.
15. **A farm from before.** A save the build before the crop roster wrote, of a
    harvester planter with three carrots and a ripe fungus, carrots stored, a survival kit
    with seeds and carrots carried, resumes as root-tubers in the standard planters, a
    still-ripe vat fungus in the pot, tubers stored and carried, and the farm goes on.
16. **A Console resumes** (2026-10-17). A Console with its screen, three instruments and a
    radio on its top, its screen turned to its power page, the number its shield page had,
    resumes with the same parts in the same sockets, the same page and the same log, and
    reads on.

17. **A deed is kept** (2026-10-18). Reaching Port Morgan in a run records The Old City there and
    then, with the run's seed and origin and not Ironman, and the next session's profile still has
    it.
18. **A dev run counts nothing.** The console's listing commands leave a run counting; once warp has
    changed it, reaching Port Morgan records no deed, and no landmark toward them all, and saved and
    resumed it's a dev run still.
19. **Unlockall opens the starts.** With the Salvager and the Homesteader behind their proposed
    deeds, a fresh profile has the Surveyor alone; the console opens over the main menu, unlockall
    there opens every start, New game shows none locked, and forgetting the deeds leaves them open.
20. **A hermit's whole day.** Under the reference camp's shield most of a day, its bubble down a
    moment, then most of a day again, is no Hermit; a little longer and it is.
21. **All four ages.** Stepping onto two colonial structures, a skimmer wreck and a First Kingdoms
    hut is three ages; onto a second-age house ruin too, Carbon Dated is done.
22. **Six pieces, one deck.** A deck of five beside one of three is no six-piece deck; the first
    deck's sixth piece makes Six Pack.
23. **A save never buries you** (2026-10-18). Saved standing on a cistern's floor as the storm that
    dug it out lets go, the sand held off it over you, a resume brings it back dug out round you, the
    sand at your feet and not over them, though the weather alone would have it filled.

## Out of scope

- Accounts, sign-in and cloud sync, until they attach at `profile.unlock`.
- More than one save slot.

## Open questions

- **The Replacement's prior save.** It "starts at the previous run's last camp, among its
  wreckage" and "needs a prior save." Here: one save at a time, a save holds only what you
  changed, and a new run begins from the seed. Not said: which save it reads when death has just
  offered the last one back, and where a camp that has to outlive its run is kept.
- **What each playstyle unlock counts.** "Long board distance," "surviving a storm on carried
  gear" and "riding out big storms without moving camp" are examples, not rules, and the
  Archaeologist's condition is open in the session. Built: a deed can open a start, and Frequent
  Flyer and Hermit are proposed for the Salvager and the Homesteader; whether either is locked at
  all is Hunter's, so both are open for now.
- **"Build" in the two new unlocks.** The session: "Build and use a dune sailboat," "Build a
  patrol-style board yourself (proposed)." Here: parts are found, never crafted, and an unlock is
  a discovery or something done. Not said what building a craft reports, or when it counts as
  used; the Daventry unlock is open in the session itself.
- **Flags across runs.** The ending flags are read as part of the run save. Whether Daventry's
  loudness or Mother Cistern's state outlives the run is not said, and the profile has no place
  for a value that grows.
- **Mode and achievements.** The vision leaves open whether achievements care which mode a run is
  in. The session's rule that novelty starts are excluded from Ironman is the first rule about
  mode, and it covers starts, not achievements. Built: a deed counts in either mode, and the
  profile marks one done in Ironman.

Session 4, part 4 (2026-10-17) adds three. Each is quoted old and new. The newest session wins in the
living docs, so this PRD follows it as direction.

- **What a plant adds to a save.** Here (rule 1): "A save holds what you changed, never what the seed
  already says," and the run save keeps every part in every socket. The session: a crop is clean or
  wild, in a stage (seedling, growing, mature, going to seed), and carries a propagule item. *Follows
  the session:* a planted crop's stage and its clean or wild flag are the run's changes, and so are a
  propagule you carry. Wild plants placed by habitat are the seed's, and are saved only once you have
  dug one up ([Farming](farming.md#the-plant-system-agreed-session-4-part-4-partly-built)).
- **A structure's state.** The session gives each structure three states (buried, partly exposed,
  exposed) that storms shift. If a state is a function of the seed and the weather, nothing is saved
  (rule 1). If you dig one open, or a landmark is repaired, that is a change and is saved, keyed by the
  structure ([Salvage & ruins](salvage-and-ruins.md#open-questions)).
- **Landmarks per seed.** Here ([World & terrain](world-and-terrain.md#landmarks)): a landmark's
  changes are read as "a record keyed by the landmark," kept whatever the distance. The session places
  each landmark per seed, so a record is keyed by the landmark in this run's world, which is another
  reason it lives in the run save and not the profile.
