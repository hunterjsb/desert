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
mode: the Surveyor, highlighted, the Salvager and the Homesteader, under a line of what each is
like to play. Each is a `Kit` resource (`game/survival/`): its id, name and line, its start on the
moon ([the world system](../world-system.md#the-feral-layer-and-spawns)), whether it's balanced and
what unlocks it. The menu offers the origins open to the profile (`Kit.open_to`, through
`Profile.has`); the Salvager's and Homesteader's playstyle unlocks wait on something that counts a
playstyle, so all three are open from the first run. The novelty kits aren't built; an origin that
isn't balanced is offered Normal only. The run keeps its origin (`World.kit`) and so does its save
(`kit`); a new run after a death comes as the same origin. A save from before origins has none and
resumes as it was, from the tuning's start. Spawns probes 2 and 3.

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
3. **The profile only ever grows by `profile.unlock`, discovery and the how-tos it's
   shown,** and only reset empties it.

## Skeleton version

- The run save and resume, Save & quit from the system menu, Resume from the main menu,
  and the two modes: Normal saving as you go and offering the save back after a death,
  Ironman's death deleting it.
- The profile file with discoveries and `profile.unlock`, and reset in Options.
- The default kit as a data resource.
- The probes below, all passing.

**Built** (2026-10-16), waiting at the gate. Two autoloads: `Saves` (`has_run`, `save`,
`save_in_background`, `run_seed`, `ironman`, `restore`, `delete`) and `Profile`
(`unlock`, `discover`, `learn`, `has`, `reset`). Menus & UI calls them from Save, Save & quit,
Resume, New game, the death screen and Options.

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
  radio's channel, beacon and charge; a save from before, with five slots, resumes with
  their contents carried), what's in your hands, at your waist or being
  hauled, and the board you ride with its ride as it stood), the clock, the moon position, the engine's origin, and where power, wear,
  farming and your body are in their ticks. Then everything of yours: each thing by its
  catalog id, where it is and how it's moving, its wear, charge, water, growth and
  harvests, a shield's switch and how far its bubble has bloomed, a stake driven or not,
  and every part in every socket, down to a line's end on a hook's ring and a shield
  seated on a crate. Every line and strong cable with its ends, length and load, and its
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
- **A frame that changes keeps older saves** (2026-10-17). A save says how it numbers
  each frame's sockets. One without that is from before the crate lost its side rings,
  and is renumbered as it resumes: every part goes back in its own socket, and a hook
  from a side ring goes on a free ring or comes out beside the crate (Devices & mods).
  The file's version is unchanged, so those saves aren't refused.
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
  tick, which added up on a floating crate; it's held on its seat every tick now.

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
    first piece joined came off its end, moored by a hook on its ring, with a charged
    crate and a running light shield standing on it, is
    saved and resumed: the same pieces stand on the same places, turned as they were,
    with every tray, what stood where with its charge, the shield running and the line
    tied, and it floats on.
13. **What you carry.** Saved carrying a radio on the weather station, a compass and
    three canisters and resumed, the radio is carried on the same channel with the same
    charge, playing from you with its words showing, the compass is carried, and the
    canisters stack as one, each with its water. A save from before, with five slots,
    resumes with their contents carried.
14. **An older crate.** Two crates saved as a build from before 2026-10-17 numbered
    them, side rings and all: one floating, moored by hooks on both side rings, and one
    resting with a hook on all four rings, its side hooks tied to stakes. Resumed, every
    part and seated device is in its own socket; the first's side hooks are on its front
    and back rings with their lines, let out where they must be to reach, the second's
    lie beside it with their lines' ends loose, and the first floats on, moored, nothing
    flung.
15. **A farm from before.** A save the build before the crop roster wrote, of a
    harvester planter with three carrots and a ripe fungus, carrots stored, a survival kit
    with seeds and carrots carried, resumes as root-tubers in the standard planters, a
    still-ripe vat fungus in the pot, tubers stored and carried, and the farm goes on.
16. **A Console resumes** (2026-10-17). A Console with its screen, three instruments and a
    radio on its top, its screen turned to its log and its shield's auto-on switched off,
    resumes with the same parts in the same sockets, the same page, the same switch and the
    same log, and reads on.

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
  Archaeologist's condition is open in the session.
- **"Build" in the two new unlocks.** The session: "Build and use a dune sailboat," "Build a
  patrol-style board yourself (proposed)." Here: parts are found, never crafted, and an unlock is
  a discovery or something done. Not said what building a craft reports, or when it counts as
  used; the Daventry unlock is open in the session itself.
- **Flags across runs.** The ending flags are read as part of the run save. Whether Daventry's
  loudness or Mother Cistern's state outlives the run is not said, and the profile has no place
  for a value that grows.
- **Mode and achievements.** The vision leaves open whether achievements care which mode a run is
  in. The session's rule that novelty starts are excluded from Ironman is the first rule about
  mode, and it covers starts, not achievements.

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
