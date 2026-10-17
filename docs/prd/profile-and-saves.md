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
  bars and slots, and every thing in the world near you, with its parts, charge, wear,
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
- **Reset** is an action in Options, behind a confirmation, and nowhere else.
- **Versioned,** like the save.

## Kits are data

The starting kit (Salvage & ruins, Survival) is a data resource, a list of things and
how many, never code. Only the default kit is balanced. Alternative kits and choosing
between them are deferred until discoveries can unlock them.

## Rules

1. **A save holds what you changed, never what the seed already says.**
2. **Saving never changes the run.** Saving and resuming at once gives the same world,
   tick for tick, as not saving at all.
3. **The profile only ever grows by `profile.unlock` and discovery,** and only reset
   empties it.

## Skeleton version

- The run save and resume, Save & quit from the system menu, Resume from the main menu,
  and the two modes: Normal saving as you go and offering the save back after a death,
  Ironman's death deleting it.
- The profile file with discoveries and `profile.unlock`, and reset in Options.
- The default kit as a data resource.
- The probes below, all passing.

**Built** (2026-10-16), waiting at the gate. Two autoloads: `Saves` (`has_run`, `save`,
`save_in_background`, `run_seed`, `ironman`, `restore`, `delete`) and `Profile`
(`unlock`, `discover`, `has`, `reset`). Menus & UI calls them from Save, Save & quit,
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
  moving, stamina, your bars, your slots, what's in your hands, at your waist or being
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

- Kits unlocked by discoveries, and choosing one at New game.
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
7. **A coil in a slot.** Saved with a 6 m coil, the kit's length, and a cable in your
   slots and resumed, the coil comes out a working 6 m line and the cable whole.
8. **Normal saves as you go.** Saved by hand, no save lands before the autosave period
   is up and one does just after; none while you're dead, in Ironman, or in a dev
   scenario's run.
9. **The mode survives.** An Ironman run saved and resumed is still Ironman's: no Save,
   and death deletes its save. A save with no mode resumes as Normal.
10. **Quick save and quick load.** Quick saved in Normal and moved elsewhere, quick load
    puts you back where and when you saved, through the fade. In Ironman neither saves
    nor loads, and a dev scenario's run never saves.
12. **A deck resumes.** A floating deck of three pieces, two of them turned, moored by a
    hook on its ring, with a charged crate and a running light shield standing on it, is
    saved and resumed: the same pieces stand on the same places, turned as they were,
    with every tray, what stood where with its charge, the shield running and the line
    tied, and it floats on.

## Out of scope

- Accounts, sign-in and cloud sync, until they attach at `profile.unlock`.
- More than one save slot.

## Open questions

- None yet.
