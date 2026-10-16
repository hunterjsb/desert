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
