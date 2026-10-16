# PRD: Profile & saves

*Draft, 2026-10-16. Answers to [the vision](../vision.md). Hunter's direction came the
same day, written in another session; this PRD takes it on and fits it to the game as
built.*

## Why this system exists

Two kinds of thing outlast a sitting. **A run** is one life on one moon: it can be set
down and picked up again, and it ends when you die. **The profile** is you across runs:
what you've found and what that has unlocked. They live in separate files, so a run can
end without touching the profile.

Permadeath stays the intended mode (the vision). Save & quit only suspends the run; there
is one save per run, and death ends it. Reloading earlier saves would be the optional
mode the vision mentions, and isn't built here.

## The run save

- **Save & quit is safe at any moment,** mid-storm included, from the system menu
  (Menus & UI). Resume puts everything back as it was: where you stood, the time, your
  bars and slots, and every thing in the world near you, with its parts, charge, wear,
  water and growth, and every line between them.
- **The world itself isn't saved.** It comes from the run's seed (World & terrain), the
  weather from the seed and the time (Wind & storms), and finds from the seed and the
  weather (Salvage & ruins). A save holds only what you changed: the things that are
  yours, and which finds near you were taken.
- **One save at a time.** New game over a save asks first (Menus & UI), and death
  deletes it.
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
  and death deleting the save.
- The profile file with discoveries and `profile.unlock`, and reset in Options.
- The default kit as a data resource.
- The probes below, all passing.

**Built** (2026-10-16), waiting at the gate. Two autoloads: `Saves` (`has_run`, `save`,
`run_seed`, `restore`, `delete`) and `Profile` (`unlock`, `discover`, `has`, `reset`).
Menus & UI calls them from Save & quit, Resume, New game and Options.

- **What a save holds:** you (where you stand, which way you face and look, how you're
  moving, stamina, your bars, your slots, what's in your hands, at your waist or being
  hauled), the clock, the moon position, the engine's origin, and where power, wear,
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
  until then (`Saves.restored` says when). A resumed run gets no new kit.
- **Versioned:** each file opens with what it is and its version, and one of another
  version, or not a save at all, is refused with the reason (`refused`) before any of it
  is read. A refused profile is never written over, except by a reset.
- **Death deletes the save,** so the main menu offers only New game.
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
- The optional saving-and-reloading mode.

## Probes

1. **The round trip.** Save mid-storm with a camp running (a shield up, a floater on
   lines, a planter growing, a charge draining), resume, and the next minute matches a
   run that never saved, to within physics' own repeatability.
2. **Only what changed.** A save holds no terrain and no untouched finds, and stays small.
3. **Death ends the run.** After dying the save is gone, and the menu offers New game.
4. **Versions.** A save or profile from an unknown version is refused with a message,
   never half-loaded.
5. **Discoveries are recorded once,** survive a new run, and reset empties them.

## Out of scope

- Accounts, sign-in and cloud sync, until they attach at `profile.unlock`.
- More than one save slot.

## Open questions

- None yet.
