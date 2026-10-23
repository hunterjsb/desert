# PRD: Profile & saves

*Draft, 2026-10-16. Answers to [the vision](../vision.md). Hunter's direction came the
same day, written in another session; this PRD takes it on and fits it to the game as
built.*

## Secret variants and canonical starts (selected 2026-10-22)

Hunter, 2026-10-22; submitted decisions `1bbceea8-b056-493d-8fbe-a12498c61c3c`, questionnaire revision 126.

> we dont need to worry about balancing variants, theyre secret unlocks for now, and wont become cannon until they have a special start like our surveyor

Variants remain secret unlocks for now, with no balancing requirement. They become
canonical only when they have a special start comparable to the Surveyor. Do not
infer a required 0.4 sub-variant selector, balanced loadout tradeoff or commitment
to build every origin. Existing profile, unlock and save behavior remains as built;
older balance classifications below describe implementation/history, not a new gate.


## Starter headlamp compatibility (selected 2026-10-22)

Hunter, 2026-10-22, answering the [first-slice brief](../briefs/suit-first-slice-2026-10-22.md):

> 1. yes 2. optional 3. yes 4. yes

Answer 4 approves one fitted starter lamp for legacy saves, exactly once, and a
fitted starter lamp for new origins without a ship. This includes legacy cabin and
flight saves; migration must not duplicate a module already present. Selected, not
built. [Menus](menus-and-ui.md#combined-inventory-direction-and-first-module-selected-2026-10-22)
owns the after-Spaceport sequence; [Surveyor opening](surveyor-opening.md#headlamp-fitting-on-the-ship-selected-2026-10-22)
owns the new Surveyor's optional fitting and impact protection.


## Halloran's first fire (agreed, 2026-10-20)

**First Fire**, hidden in Far, is recorded when a preserved coalcane bundle is physically consumed
by the Stoker. The run saves Halloran's stock taken, fuel consumed, burn expiry, service-door
release and cache items claimed. Missing state in older saves means an untouched encounter.
These values survive site unloading and reprojection, independently of the transient Structure.


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
kits](../vision.md#player-origins-and-kits) historically changed what was balanced (superseded as a design requirement by the secret-variant decision above): **only the first three kits
(the Surveyor, the Salvager and the Homesteader) are balanced. The rest are novelty starts,
excluded from Ironman** (the session writes "Iron Man"; it is the same mode). Each kit is data
like the default, and each unlocks through `profile.unlock`:

| Kit | Unlock |
|---|---|
| Surveyor | Default |
| Salvager | A playstyle, e.g. long board distance or surviving a storm on carried gear |
| Homesteader | A playstyle, e.g. riding out big storms without moving camp |
| Archaeologist | Two deeds, Field Kit and Spadework (built 2026-10-19) |
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
system](../world/world-system.md#the-feral-layer-and-spawns)), whether it's balanced, what unlocks it
and what of it the main menu shows. The menu lists every origin, one not open to
the profile (`Kit.is_open_to`, through `Profile.has`) as ????. A kit's `unlock` can name a deed
(below), which then opens it. The Surveyor is open from the first run; Frequent Flyer (a long ride on
the board) opens the Salvager, and Hermit (a whole day under a shield) the Homesteader (Hunter,
2026-10-18: "let's lock the two other starts behind some deeds"). The dev console's `unlockall`
opens both for testing. The profile keeps the origin a run was last begun or resumed as (`Profile.last_origin`), whose
kit the main menu shows; reset forgets it. Of the novelty kits only the Varran settler is built (below); an
origin that isn't balanced is offered Normal only. The run keeps its origin (`World.kit`) and so does its save
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
(round two's two anomaly deeds are), and its goal, which is Tuning's (the Deeds group). What a deed opens is each kit's own
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
| `power` | Power Trip | Make 300 W in one system | All Mod Cons (Set Sail until round two) | Power's tick, by what each pool makes |
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
- **Names from before** (2026-10-19): session 5 renamed the houses, Kesselside and the Okafor
  bunker. A profile or run saved before reads their old ids as the new ones as it loads
  (`History.RENAMED`, `Eras.RENAMED`), so neither format's version changed.
- **The dev console**, at the main menu too: `unlockall` opens every start whatever deeds are done
  (through `Profile.unlock`, so forgetting the deeds leaves them open; reset closes them), `deed
  <id>` grants one, `deeds` lists what's done and what isn't, and `deeds clear` forgets them all.
- **Probes** 17 to 22, and Menus & UI probe 11.

### Round two: the trees that tie it together (agreed 2026-10-18; steps 1 and 3 built 2026-10-19, step 5 2026-10-22)

Hunter, 2026-10-18: "what are the big deeds and deed trees we're missing to tie everything
together?", then "lets do it, and do it right, in the right order." Sailing, ruins, storms, wrecks,
the anomaly, the radio gods, the sky and the far places had no deed. Each tree runs from an easy
deed to a hard one, and each ends in a start opening or a step in the story. The numbers were
starting points, tuned from the probes' numbers as the first batch was (below). Each deed is
recorded by the system that knows, through the one hook.

**What moves** (built). The shield family becomes **Weather**. Set Sail moves from Camp to the head
of **Wind**, so Power Trip waits on All Mod Cons instead. Carbon Dated moves from Story to the head
of **Ruins**. All Mod Cons and Six Pack follow the chassis rework (built): the home is a Console, a
condenser and a battery stuck on one deck, and a wall or shelf on a frame's face is a piece, where
the frame is a part stuck on the deck.

| Tree | Deed | Asks | After | Recorded |
|---|---|---|---|---|
| Board | **Quiver** | Ride every make of board | Frequent Flyer | `Ride`'s tick: a ride on one make past `deed_make_m` (100 m, seven or eight seconds pushing from a stand on the slowest make) counts that make, once a profile ([Movement](movement.md#the-rides-feel-and-boards-by-make-hunter-2026-10-18-built)). Built 2026-10-22 |
| Camp | **On Reserve** | Run your camp on a power box's batteries | All Mod Cons | `Power`'s tick: a pool drawing more than it makes, carried through, a power box in it with a charged bay supplying. Built 2026-10-22 |
| Board | **Yard Sale** (hidden) | Tumble 12 m in one wipeout | Big Air | `Tumble`'s tick: how far you've tumbled since you were thrown off ([Movement](movement.md#the-rides-feel-and-boards-by-make-hunter-2026-10-18-built)). Built 2026-10-19 |
| Wind | Set Sail | Tie a sail's sheet at your waist (as now) | | your waist |
| Wind | **Fairlead** | Redirect a loaded rope through a fitted hook | | `Line`: a player-routed guide carries at least 10 N sustained load for one second; saved routing retains the real guide reference |
| Wind | **Quick Haul** | Yank a loaded rope through your hands | | `Reel`: a yank takes in at least 0.1 m against at least 20 N; clicking without an actual haul does not count |
| Wind | **Hand-Me-Down** | Take the sail off a wrecked nomad rig | Set Sail | `Salvage.claim`: the find a nomad rig always carries (its mast with its sail, the socket `SiteLoot.RIGGED`) becoming yours |
| Wind | **Telltale** | Trim a sail with a streamer flying on its rig | Hand-Me-Down | `Mast`'s haul: its sheet's inboard taken in or let out a notch, its sail all the way up and yours to sail, with a wind streamer anywhere on its camp, its mast too |
| Wind | **Close-Hauled** | Make 500 m upwind under sail | Set Sail | `Mast`'s tick: while its sail is all the way up and yours to sail (its sheet on you, or you at the helm of its camp), its camp's way against the field's wind, kept through tacks and never below none; gone once it isn't yours to sail. Kept in the save |
| Wind | **Land Yacht** | Sail a keeled camp 5,000 m from its helm | Close-Hauled | `Helm`'s tick: the ground its camp covers while you sit there, floating on a keel under a raised sail; gone when you stand up. Kept in the save |
| Wind | **Storm Runner** | Sail 3,000 m on a storm's outflow, ahead of its wall | Land Yacht | `Mast`'s tick, as Close-Hauled: the ground its camp covers while the field puts it in a front's outflow and short of its wall, gone once it leaves the outflow. Opens nothing yet (step 2) |
| Weather | Hermit, Sandblasted | (as now) | | Wear |
| Weather | **Eye of the Anomaly** (hidden) | Live through an anomaly's heart | Sandblasted | `Vitals`' tick, asleep too: the hidden term where you stand reaches its full (0.99), then falls back to nothing with you alive. Kept in the save |
| Weather | **Tells** (hidden) | Notice each of an anomaly's three tells | Eye of the Anomaly | each where it's shown to you, once a profile: the compass in your hands leaning 10° or more toward a heart (`Compass`); a radio you hear crackling a quarter deep or more (`Radio`); a shield's load past 100%, its hum straining with you in its bubble (`ShieldGenerator`) or its load row on the stats page of a Console near enough to read (`Console`) |
| Weather | **Taught** (hidden) | Teach the Walker the anomaly | Tells | `Console.upload`: a Console plugged into the Walker's port, holding evidence of each tell (the session 5 ruling), teaches it (built 2026-10-19) |
| Ruins | Carbon Dated | (as now) | | the world |
| Ruins | **Bared** | Take loot from a site a storm has stripped | Carbon Dated | `Salvage.claim`: a find taken from a site the storm working on it has further out of the sand than its settled sand would (`Structure.bared`) |
| Ruins | **Storm Chaser** | Reach 3 freshly bared sites in one storm | Bared | the world, stepping onto a site so bared while you're in a storm, each counted once; the count goes the moment you're out of the storm |
| Ruins | **Dune Reader** | Find a ruin buried in a dune's own lee | Storm Chaser | the world, stepping onto a big dune's ruin's ground: one is only ever built once something of it shows |
| Ruins | **Field Kit** | A Console with a ground radar, a scoop and a sieve on one deck; with Spadework opens the Archaeologist | Dune Reader | `Chassis`, as a piece joins or something sticks on its deck, and the Console as its ground radar comes online: the three counted on one deck, as All Mod Cons counts the home's |
| Ruins | **Spadework** | Dig a dune's ruin out yourself; with Field Kit opens the Archaeologist | Dune Reader | `Hands`, a scoop's stroke on its sand: dug out, with at least half its depth off by your hand |
| Scrap | **First Cut** | Cut a wreck's seam through | | `Wreckage.cut`: a plate's last cell cut, and it falls |
| Scrap | **Stripped** | Free every module on one wreck | First Cut | `Salvage.claim`: a wreck's module taken out once it's free, every module of that wreck taken |
| Scrap | **Clean Hands** | Make a live wreck's hazards safe without a shock or a sickness | Stripped | `Wreckage.make_safe`: its last hazard made safe, every one of them safe and none set off |
| Scrap | **Bonepicker** | Scrap one of each kind of wreck | Clean Hands | `Salvage.claim`: a module taken from a wreck counts its kind, hull, hauler, freight pod, lifeboat, hopper or nomad rig (`Wreckage.kinds`; six since 2026-10-19, when it said five), once a profile |
| Signals | **Follow the Signal** | Reach a real ruin beacon using a survey receiver | | `SurveyReceiver`: acquire at least 60 m away, then arrive within 15 m carrying or holding the live receiver, tuned to its beacon; target and acquisition distance persist in a save |
| Signals | **First Light** | Hear a god inside its window | | `Radio`'s tick: tuned to a god while its words are useful, coming through and not cut, and you hearing it: its line in your view, or its sound within earshot with the volume up |
| Signals | **Line of Sight** | Hear an FM station come through quiet | First Light | `Radio`'s tick on the FM band: a station over its threshold enough to be quiet, the volume up and you hearing it (built 2026-10-20, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **Foxhole Radio** | Hear a god inside its window on a crystal set | First Light | `Radio`'s tick on a god with a crystal set: its words useful, coming through and not cut, you hearing it (built 2026-10-21, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **Close Listening** | Hear a god inside its window on a crystal set, through a headset | Foxhole Radio | the same tick as Foxhole Radio, with a headset in the set's bay and the set carried or in your hands (built 2026-10-21, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **Null** | Turn a radio until a god you hear falls silent | First Light | `Radio`'s tick on a god: one that would come through whole broadside to the set's ferrite rod, silent end-on to it, the volume up and you hearing it (built 2026-10-20, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **Long Wire** | Hear a satellite clear on an antenna reel's wire strung from the radio | First Light | `Radio`'s tick on shortwave: an antenna reel's wire strung `sw_wire_m` or more from it and a satellite coming through whole, the volume up and you hearing it (built 2026-10-20, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **High Wire** | Hear a satellite clear on a kite flown 50 m up on a radio's lead | Long Wire | `Radio`'s tick on shortwave: an antenna kite on its top hook's lead 50 m or more up and a satellite coming through whole, the volume up and you hearing it (built 2026-10-21, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **Grounded** | Let a staked kite lead take an arc to earth | First Light | `AntennaKite`'s tick: its lead through a driven stake, the stake's ring dumping charge that had climbed past an arc's (built 2026-10-21) |
| Signals | **Storm on Tu** | Hear Tu roar on shortwave | First Light | `Radio`'s tick on the shortwave band: Tu's roar coming in as loud as an anomaly's crackle is a tell, the volume up and you hearing it (built 2026-10-20, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **Mayday** | Hear a wreck's distress call come through whole | First Light | `Radio`'s tick on the AM dial: a wreck calling SOS near 240 kHz coming through whole, the volume up and you hearing it (built 2026-10-21, [Radio](radio-sound-and-atmosphere.md)) |
| Signals | **Pantheon** | Hear all seven gods | First Light | the same, each god counted once a profile |
| Signals | **Triangulated** | Fix the living city with three crossing bearings | Pantheon | the Console noting the Walker's contact log (`Chart`): three of its noted bearings crossing within 3 km, 8° apart or more (built 2026-10-19) |
| Signals | **The Living City** | See the living city's lights | Triangulated | `CityLights`: its lights shown for your eye at night within its chatter's range, in view, over the dunes and past the storms (built 2026-10-19) |
| Far | **Totality** | Watch a whole eclipse out in the open | | `SkyView`, each frame: the sun seen going in behind Tu, through totality and out again, up all the while, you in no bubble, the clock never jumping |
| Far | **Glint** | Reach a site whose glint you saw from 1,000 m off | Totality | `Skyline`, as it reads the storms between you and what it draws: a stand-in's glint that far off shining for your eye, as a start's sighting is judged, over the dunes and past the storms with the sun up; then the world, stepping onto that site |
| Far | **Just Missed Them** (hidden) | Reach a nomads' camp | Glint | the world, stepping onto a nomads' camp's ground. Hidden: the grid shouldn't say anyone's out there |
| Far | **Live Vent** | Stand at a live vent's mouth | Glint | the world, stepping inside a vent mouth's rampart (every mouth is a live vent's) |
| Far | **Thunder** | Hear a burst's boom from 35,000 m away | Live Vent | `Rumbles`, a vent's burst booming that far off; a gas pocket's doesn't count |
| Far | **Under Tu** | Stand with Tu overhead | Totality | `SkyView`: Tu within 5° of straight up |
| Far | **The Dark Side** | Stand where Tu never rises | Under Tu | `SkyView`: Tu's whole disc under the horizon however far it nods (`DayCycle.never_rises`), 95.5° from the point under Tu at 9° |
| Nomad | **Ten Days** | Live 10 days in one run | | the world's clock, each whole day since `World.began`, which a death's respawn sets afresh |
| Nomad | **Moved House** | Move your camp 5,000 m in one day | Ten Days | `Chassis`' tick: a deck's distance from where it stood as the day began where you are; not while it's in your hands. Kept in the save |
| Nomad | **Slept It Off** | Sleep through a storm with nothing lost from your camp | Ten Days | `Sleep.overnight`: a storm over where you lie at some time in the night, none as you wake, and every deck near you still there with all of its camp on it, nothing wrecked that wasn't |
| Nomad | **Nomad** | A deed from each of Wind, Weather, Ruins, Signals and Far | any deed of each of those trees | the hook, as the last of the five comes to show a deed done: one done early counts once its branch opens. Built 2026-10-22 |

- **Your camp** is a deck as the chassis rework made it (`Chassis.camp`): its pieces
  (`Chassis.pieces()`), every part fitted to them, a frame on a piece among them, and every device
  stuck on it with what's fitted to that, all one pool as its power is. Moved House reads any deck you
  aren't carrying. Slept It Off takes each deck within `sleep_camp_m` of where you lie down.
- **Hidden deeds** show "????" and no picture until they show done, and their panel says only
  "????"; a deed after one waits on "????". Their place and the lines to them still show. The
  anomaly's deeds are hidden so the grid doesn't say anomalies exist before you've learnt them by
  their tells. Their badge says their name. Built: the table's `hidden`, read through
  `Deeds.revealed`.
- **Nomad ties the trees together:** its card stands apart, with a line from each of the five
  trees, lit where you've done one. It waits on any one deed of a tree, not a named one, so the
  table's `after` gains "any of a family". Built 2026-10-22: the table's `after_any`; its card stands
  alone under the middle of the grid, each tree's line marking its branches top to foot down the
  right and running into the card's side, the top tree outermost so none cross.
- **The grid holds every tree** (built for step 1, Menus & UI): every deed in `Deeds.TABLE` in eleven families, the round-two trees with the deeds added since (Line of Sight, Storm on Tu, Long Wire and Null since 2026-10-20; Flight Plan, Make Fast, Foxhole Radio, Close Listening and Mayday 2026-10-21; Whistler cut 2026-10-21 with natural radio; High Wire and Grounded 2026-10-21; Plot a Course and Drop In 2026-10-21; Quiver, On Reserve and Nomad 2026-10-22), each a
  branch or two beside its name down the left, as round one's were (eleven columns side by side
  wouldn't stand left of the prop). It scrolls, and opens on the latest done.
- **The order.** Each part waits for what it reads to land:
  1. **Built 2026-10-19.** After the devex, chassis, sail-trim and board rounds landed: the hidden
     flag, the grid holding every tree, the moves above, and every deed whose system is built: Wind
     (without its start), Weather to Tells, Ruins to Storm Chaser, Scrap, Signals to Pantheon, Far,
     and Nomad's first three.
  2. With the chassis spec's starts and kits: Storm Runner opens the Varran settler. Built 2026-10-19.
  3. **Built 2026-10-19,** with dune archaeology: Dune Reader, Field Kit and Spadework, the last two
     opening the Archaeologist together.
  3b. **Built 2026-10-19,** with the nomads' gear (Hunter: "New features should be exposed via
     deeds"): Hand-Me-Down and Telltale in Wind, Just Missed Them in Far, hidden. A deed for
     spotting from the crow's nest was weighed and left out: what it'd ask (a glint the crests hid
     from the deck) the Glint deed's sightline can't yet tell apart. Profile & saves probe 36.
  4. **Built 2026-10-19,** with the radio stations' second pass and the Walker's quest
     ([Radio](radio-sound-and-atmosphere.md#the-walkers-quest-agreed-2026-10-19-hunter-perfect-built)):
     Triangulated, The Living City, and Taught, hidden. Their cards are marks drawn
     (DeedsGrid): three lines crossing, the city's decks dark against their glow, the Walker.
  5. **Built 2026-10-22,** last, once every tree it reads had landed: Nomad and its "any of a
     family", so that what it asks never changes after someone has earned it. With it, the shipped
     features still without a deed (3b's rule): Quiver for the board makes and On Reserve for the
     power box. Home Again already covers a marked Home. A wall's lee in a storm was weighed and left
     out: behind a wall you still take two-thirds of a storm's harm, so sitting one out there asks
     you to get hurt.

How each X was chosen, from the probes' numbers (the probes' seed, 2026-10-19):
- **500 m upwind,** not 1 km. The "yacht", its sheet tended, settles about 64° off a steady 10 m/s
  at 4.6 m/s, 2.0 m/s of it against the wind (109 m in its first 45 s close-hauled; Movement's 36 m
  in 20 s); the "sail" deck on skates makes 1.0. So 500 m is four to five minutes close-hauled on the
  yacht or eight on skates, and the tacks on top; 1 km was most of a day of it.
- **5,000 m from the helm.** On a broad reach in 10 m/s the yacht comes up to 11.7 m/s, past the
  wind's own speed, 508 m in its first minute from across the wind; close-hauled it makes 4.6. Its
  700 Wh run its trays' 470 W for an hour and a half. So 5 km is about ten minutes at the helm, half
  a day, and the battery is no limit.
- **3,000 m on the outflow.** Over 200 fronts on the probes' seed, the outflow ahead of a wall runs
  360 m deep at the median (115 to 4,120), blowing 14 to 17 m/s, and the wall comes on at 9 m/s (5 to
  14). In 15 m/s the yacht tears its sail on a beam reach (728 N against the 600 that tears it) but
  holds on a broad reach at 20 m/s, 11 of them downwind: it gains on the wall about 2 m/s, so entered
  at the wall the band slips past it in three minutes, about 3.6 km sailed. So 3 km is the band held
  nearly whole.
- **3 bared sites.** Within 1.5 km of the Surveyor's start stand 21 structures, and each of its
  first eight storms (2 to 92 minutes long) bares 9 to 16 of them; round the Homesteader's 48, bared
  13 to 38 at a time; round the Salvager's deep desert 7, bared 0 to 3. Three is a storm chased where
  history stands thick, under a shield you carry.
- **1,000 m off,** not 5 km: the skyline draws to 3 km. Glints in sight are rare: from 15 places round
  the three starts, five saw a glint shine over the dunes at some time of day, for 20 to 50 s, from
  584, 1,378, 2,028 (twice) and 2,326 m. Past 1 km is past the built ground, where all but the
  nearest of them shone from.
- **35,000 m away,** not 20 km. The rift's live vents stand 24 to 30 km from the Surveyor's start,
  10 to 16 from the Salvager's and 9 to 10 from the Homesteader's, and a boom carries 45 km. At 20 km
  the Surveyor would have it at its start; 35 km is past every start, out toward the Rim, a low
  rumble at about -33 dB.
- **5,000 m in one day,** not 20 km. A day is 20 minutes and the yacht's best is 11.7 m/s, 14 km if
  it never turned. Five km is the yacht on its reaches for half a day, or a camp on skates at its
  4.3 m/s beam reach for all of one.
- **12 m in one wipeout:** thrown off a flat-out landing you tumble 12.3 m, and riding at 15 m/s
  13.4; an edge caught in a flat-out stop throws you at 13.5 m/s and only 9.7 m, and a crash bounces
  you back 3.2.
- **5° and 10 days** are the table's. Tu nods about a degree a day, so overhead is a circle about 2
  km across the point under Tu, 25 km from the tuning's start; the Dark Side begins 95.5° from it, 15
  km the other way. Ten days is 200 minutes without dying.
- **Where a tell shows:** 10° of lean is a needle plainly off north in your hand (it leans up to
  60°); a quarter of the crackle's depth bursts at an eighth of full static, plain under the hiss.
- **Dune Reader, Field Kit and Spadework** (step 3), both of the last "fairly hard" as the spec asks,
  from the probes' numbers. 35 of the 40 big dunes within 1.5 km of the probes' start hold a ruin, and it
  shows only past an intense storm: storms that never bring their heart over one leave it under (8 bared
  of 1,162 over two days), those whose heart holds over it half an hour or more nearly always bare it (136
  of 160); after one lets go it's back under in minutes. So finding one is being by a big dune in a big
  storm, or reading the dunes with a radar. Field Kit wants a ground radar, which lies most often in a dune
  ruin's deepest cache, and a sieve, on their shelves: the setup's gear is a dune ruin's to find, a scoop
  the skimmer era's, a Console the colony's best. Spadework wants half a ruin's depth off by your hand: a
  dune ruin is 5.5 to 6.5 m deep and a hab pod 48 m² across, so that's at least 3 m and 3½ minutes holding
  use, and from the sand that came back after its storm (0.6 m off) the probe dug 5.2 m in about six
  minutes. A storm that has taken half or more off one leaves it the storm's: you wait for the sand to
  come back, or find another.

- **Probes** 25 to 31, one a tree, and Menus & UI probe 16; 33, the dune deeds through play (a ruin
  stepped onto, dug out by hand and not before half its sand is yours, and the setup not done until its
  ground radar is fitted), and 34, the Archaeologist locked until both of hers; 35, the Walker's deeds
  through play (Taught as the plug goes in its port, Triangulated as its noted contacts fix the city,
  The Living City from a kilometre off on a clear night). Step 5: 47, Nomad not before a deed shows in
  each of the five trees, in any order; 48, Quiver ridden; 49, On Reserve on a power box; Menus & UI
  probe 51, Nomad's card apart and its lines.

**Cast Off (Sanddune, agreed 2026-10-19):** in Wind after Set Sail, release two
or more waist lines together. `Waist._undone` records it when live line ends
actually drop, including an all-line release resumed during its untie delay.
Selecting a line, starting a timer, or returning an end to the hand does not count.
The existing sail icon is reused.

**New features come with deeds (Hunter, 2026-10-19).** "I love all the new deeds, we should keep
the creed that new features should be exposed via deeds." Every feature that lands brings a deed
or more for doing what it's for, in the tree it fits, recorded where it happens. A deed makes a new
system something you go and do.

## Starts on the chassis, and two new kits (agreed, 2026-10-18 spec; built)

From the [chassis spec](../briefs/chassis-kits-dunes-2026-10-18.md); balance targets the Surveyor only.
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

**The Surveyor's first day, measured again (2026-10-19), kept as it is.** On the probes' seed its
trays give way at 0.43 days, a run's first storm due three to eight minutes in, so the camp floats
for the first eight or so minutes, long enough to tow it a few hundred metres to the shelter you
choose before that storm, then settles and keeps the battery's last quarter for the shield, which
runs the whole first day and into the next morning (Survival probe 4); it rides within 2° of level.
A good first day as it stands, so nothing changed.

**Built (2026-10-19), the Varran settler** (`varran_kit.tres`, the fourth origin, Kit.ORIGINS). A
novelty start: not balanced, so Normal only, and opened by Storm Runner, the Wind tree's last deed
(Hunter's spec said a dune sailboat built and used; round two's tree settled it). It begins where the
Surveyor's would, deep desert with an artery to find. "Sails the storms."
- **His rig,** behind you to your right as the run begins, resting on the sand with its sail furled: a
  deck two pieces by two on four hover trays set out at its corners, his navigation computer on its
  front on the middle line, the mast behind it, two batteries and the light panel aft, and a hook on
  each front piece's outer side ring. No runners and no keel: he's the keel, on his board
  ([Movement](movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)). 121 kg; floating it
  draws 261 W (244 W its trays, 17 W the computer and its screen), so its two batteries float it about
  46 minutes, two and a third days, and the light panel gives 30 W at best. Narrower decks were tried
  and are no rig: two pieces abreast or in a line go over or hang luffing on the lines, and three in an
  L fly only one tack.
- **Its three lines at your waist from the start:** a bow line from each side hook at its bow, its
  bridle, laid 1.5 m slack, and the sheet from the boom's end, 0.5 m; a kit's `waist` lays them, by
  what its rig's steps name (a rig's hook can be named now, as a stick can). One set of lines flies it
  on either tack ([Movement](movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built);
  2026-10-19, before which it had the left bow line alone, and the other tack needed it moved). The
  board lies at your feet, its battery full.
- **Carried:** a canister, a ration and his personal shield, with a battery of its own
  ([Bubble shield](bubble-shield-and-camp.md#the-varran-settlers-personal-shield-built-2026-10-19)).
  A device a kit carries comes with its batteries, as one beside you does. Every battery starts full.
- **To sail:** use the mast to raise the sail, use a piece to float the deck, step onto the board and
  dig in. What sits outside his bubble wears in a long storm as anything does: the rig, the computer
  and the sail, which a storm's wind tears.

**Built (2026-10-19), the Archaeologist** (`archaeologist_kit.tres`, the fifth origin). A novelty start:
not balanced, so Normal only. She came out on a Daventry-funded university expedition to dig up the
proof of why people have to be careful, and Zan only half fits the story she was sent to tell: the
hive-mind war mattered, but what killed the place was being left, being overseen badly and people
being people. "Digs for proof." She begins where the Surveyor would, deep desert, with big dunes
round her as there are anywhere the sand runs deep.
- **Opened by both her deeds,** Field Kit and Spadework (Dune Reader before them in the grid). A kit's
  `unlock` names one deed or unlock, or several apart by commas, all of them needed (`Kit.unlocks`);
  each one says it opens her, and she's marked new only once the last is done.
- **The archaeology setup on a rig** (`Rig`), beside you to your right, resting on the sand: a deck
  of three pieces in a line, a Console on the first with its screen and a ground radar fitted, its
  Map's survey in reach, two batteries in front of it; the light shield and solar panel on the
  second. The third is a clear work surface. Its mass is about 58.3 kg, removing the 1.5 kg scoop
  and 1.2 kg sieve from the earlier measured 61 kg; it draws 11 W (the Console, screen and radar),
  so its two batteries, starting at 80%, keep the survey running about fourteen and a half hours
  of world time with no sun, and the panel gives 60 W at best.
- **Carried:** a canister, two rations, the bedroll, a med kit, a radio with its battery, the scoop
  and the sieve. The scoop and sieve are on her, so she can work at a remote dune; the sieve sifts
  from her suit. A separate hoverboard with its own battery gives her scouting mobility. It doesn't
  tow the heavy lab, which stays as a powered base.

**Playability pass (2026-10-19):** the expedition's roughly 58 kg lab is a stationary home base,
not something the hoverboard can tow. The Archaeologist therefore starts with a separate
hoverboard for scouting, and carries the radio, scoop and sieve so a dune dig works away from the
Console. The lab keeps its ground radar, power, solar panel and light shield; Surveyor remains the
sole balance target. This is still a novelty start, and the board is for the player's travel rather
than hauling the lab.

## Ending flags (proposed)

*Session 4, part 3 (lore session); proposed, and none of it
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
24. **Names from before** (2026-10-19). A profile with Kesselside and the Okafor bunker counted
    toward Hot Tourist Destinations counts Crakeside and the Haberjack bunker instead; a chassis an
    Okafor marked, saved and resumed, is a Haberjack's and wears their heraldry.

32. **Storm Runner opens the Varran settler** (2026-10-19). On a fresh profile New game lists four
    starts, the Surveyor first and highlighted, the Varran's ????; the Wind tree's earlier deeds don't
    open it, Storm Runner does, marked new, and it offers Normal only.
36. **The nomads' gear's deeds** (2026-10-19). Taking a wrecked nomad rig's mast and sail is
    Hand-Me-Down; stepping into a nomads' camp, Just Missed Them, ???? till then; trimming a raised
    sail's sheet is Telltale only with a streamer flying on its rig.

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

## Salvager personal kit (Hunter, 2026-10-19; agreed correction)

The Salvager carries a personal shield with its own full battery instead of starting
with a light shield on a chassis plate. The racer board and cutter remain nearby;
the existing carried supplies and tools remain. The first chassis/home is found in
salvage. Keep the existing deed unlock and generated wreck-field start. The existing
personal shield trades a smaller bubble and higher storm draw for portability; its
tuning is unchanged. Existing saves keep their current equipment.

As built, `salvager_kit.tres` puts `personal_shield` in carried gear and removes the
plate assembly. Suit.restock fits its battery using the kit's existing full-charge
setting. The existing origin-showpiece/gear-list/new-run/save check (menus9) passes
in9s with no assertion changes; other origin resources and the unlock are unchanged.

**Up and Over (2026-10-20):** complete a swept on-foot vault onto a real walkable ledge. Recorded by LedgeVault only after the player establishes floor contact; a blocked or interrupted attempt does not count.

### Deliveryship delivery (2026-10-20)

The first burning flare to call a real delivery from the deliveryship (the flying craft, called the Surveyor
and then the drone until 2026-10-21) records `care_package`
(**Care Package**, Signals, flare icon). The flare records it at the successful
call, alongside its persistent one-call flag. Developer scenarios/commands do
not award it, following the existing deed contract.


**Manual hoist deed (2026-10-20).** All Hands adds the manual-hoist deed to its existing
family. It is recorded where a worked hand winch winds an actual halyard to the configured raised fraction; setting cloth height or loading a
save alone does not award it. Mast hoist/legacy state joins ordinary rig state;
the existing line/end/guide references preserve its physical halyard route.

### Home identity and return (2026-10-20; integration verification pending)

Home Again adds one deed in the Camp family. CampHome
records it on returning within 30 m after a departure of at least 700 m, while
support is ready. The saved Home contains stable assembly/member references,
its geographic anchor, local poses and last received fix. Snapshot prepares the
remote footprint before the ground wait and reconnects references after ordinary
attachments and lines. Old saves without Home keep their previous behavior.
The focused camp integration check passes a 2.1 km departure, far save/restore and
safe unmark after return; broader combined verification remains pending.

### Surveyor arrival and recovery (development, 2026-10-20)

Making Landfall adds one Camp deed. Hands records it when a physical surviving pod object is
taken; generation and restoration do not award recovery or construction deeds.
Snapshot stores arrival phase/elapsed time, resolved survivors and recovery flags,
and reconnects roles through actual object references, including held objects and
fitted cells. Shell roles and skins follow their physical panel when a chassis
reroots. Focused checks cover mid-flight resume, dismantled/held recovery and
rerooted panel saves; combined CI and playtest acceptance remain pending.

### Ground rest (selected 2026-10-20; implemented development)

A Moment's Rest (`ground_rest`, camp family, bedroll icon) records the first
successful voluntary ground sit or lie. Together with Home Again and Making
Landfall, it adds a deed to the Camp family. Loading a save must not record it again. Posture persists independently of the transient camera transition, with standing as
the default for saves written before this feature.


### Flight Plan (2026-10-21; implemented development)

Flight Plan (`flight_plan`, signals family, radio icon) records the first time
you hear Port Morgan Control Tower read the deliveryship's schedule on FM (Radio
probe 47); since the bands were rebuilt (2026-10-21), hearing Port Morgan Tower's
report, the weather at the tower and then the schedule. It is one of the radio-progression deeds.

### Radio upgrades' deeds (2026-10-21; implemented development)

Close Listening (`close_listening`, after Foxhole Radio), signals family, radio
icon, is recorded by `Radio`'s tick. Mayday (`mayday`, after First Light), with
the bands rebuilt, is hearing a wreck's distress call whole on the AM dial.
*Merged 2026-10-21:* the kite from the radio broadcasts work replaced this
branch's reel-flown one, so its High Wire and Grounded (radio probes 55-58)
stand in for Sky Wave and the earth stake's Grounded, and Whistler went with
natural radio: the current roster, which is owned by `Deeds.TABLE`.


**Combined development resume check (2026-10-20).** The preparatory Sanddune
candidate combines Home, Surveyor opening, ground posture and continuous coils.
Actual Main flight/recovery resume passes (9 s), other-origin/developer-scenario
and legacy-start compatibility passes (24 s), and posture/legacy/initial-eye
restoration passes (13 s). Arrival restore guards, resolved survivor references
and ground-pose restoration coexist in Snapshot. This is focused development
evidence; combined CI and ordinary-player acceptance remain pending.

## Gathered lines and Make Fast (selected 2026-10-21; implementation)

Gathering keeps every original Line and end. The primary end carries the others
through ordinary nested fittings; the run records enough ordered member sockets
to rebuild that physical group before reconnecting rope endpoints and routes.
Restore a carried member selection only after hands and waist are restored. A
missing group/selection field means the legacy single-end behavior. Continued
untie timing is transient; taking a snapshot does not mutate a live interaction.

**Make Fast** belongs to Wind after Set Sail. Record it when an ordinary player
placement finishes securing a gathered group with at least two distinct live
lines to one anchor. Gathering, dropping, failed placement and restore do not
record it. Its card uses the existing stake image. This adds one candidate deed to the Wind
family; the real placement check passes (Rope 30, 7 s) and real save/resume passes
(Save 46, 19 s). Gathering alone does not award it; ordinary anchoring does.
Combined candidate verification remains pending.

**Whistler cut (2026-10-21).** Natural radio went when the AM dial became a real
set's longwave and mediumwave (Radio, sound & atmosphere), and its deed with it:
the deed was removed from the current roster. A profile that earned it keeps
its record, unshown: the deeds grid lists only `Deeds.TABLE`.

**High Wire and Grounded (2026-10-21).** The antenna kite brings two signals
deeds (Radio, sound & atmosphere) add two entries to the Signals family.

## Surveyor preflight deeds (selected 2026-10-21; candidate)

Plot a Course records an actual valid choice through the ship's launch computer;
Drop In records successful committed launch from the loaded pod. Both belong to
Camp, with Drop In following Plot a Course, using existing Console/chassis art.
Restoring a plan, reconstructing the cabin or resuming flight records neither.
They add two deeds to the Camp family alongside the radio and antenna-kite deeds above.
Preflight saves retain actual object references and the selected plan/cargo,
not a second kit grant. Integrated evidence remains pending.

**Summit deed (2026-10-22).** Above the Dunes (`summit`, far family, summit mark)
records standing on a mountain's summit structure.

## Towing and gathering deeds (2026-10-22)

The board's powered towing and gathering several line ends in one hand came without deeds.
**Pack Mule** (Board, after Frequent Flyer) is driving a loaded line along with the board's
motor, recorded by the ride; **Bogged Down** (Board, after Pack Mule) is loading that motor
until it sputters. **Fistful** (Wind, after Set Sail) is gathering a second line's end into the
hand, recorded by the waist as the end joins the knot; Make Fast now follows it. Three more deeds
across the Board and Wind families, following the summit deed.

## Lookout (2026-10-22)

Climbing into a crow's nest on a standing mast records **Lookout** (Wind, after
Hand-Me-Down): the nest is the nomads' gear and came without one. Devices 41 checks it.

## Sailing learning aid deed (2026-10-22)

Learning the Ropes (`sail_by_wire`) follows All Hands in the wind family. It is
recorded at the real drum when a Console actually changes a raised, loaded sail's
sheet; selecting a control mode alone earns nothing. This adds the learning-aid deed to the Wind family. The course and Home choice are saved with the Console, while automatic control resumes in hand mode.
The controls are described in [Movement](movement.md#sailing-learning-aid-selected-2026-10-22-built).
