# Sandgame — Vision

*Working title. Draft, 2026-10-13. This page is the source of truth for what the game is;
every PRD answers to it.*

## The game in one breath

A cozy survival game on a dead desert moon. Your home is a bubble shield you carry with
you, tied down with rope against the wind. You wander wherever you like, and the better
you play, the more your little camp sustains itself, until you can stop, sit back, and
let it run.

## Pillars

1. **Steady state is the reward.** Getting stronger means getting more self-sufficient,
   not more powerful in a fight. A well-run camp reaches a steady state where going AFK
   costs nothing. That's the satisfaction of a Satisfactory factory or a Minecraft AFK
   farm, at the size of one traveller.
2. **Your home goes with you.** There's no base to return to. The shield, the planters
   and the power all travel with you, tethered against the wind. You pick the direction.
3. **The wind is the difficulty dial.** Drift with the wind and life is calm. Push into
   it and things get harder, but storms strip the dunes and uncover more, so the
   rewards get better.
4. **Cozy, not hostile.** No enemies to fight and no tower defense. The pressure comes
   from the moon itself: wind, storms, heat, thirst. The feeling inside the bubble is
   warmth and safety, with the radio on.

## Core loop

Wander → find what the wind uncovers → bring it into the bubble → grow, power and
upgrade the camp → the camp sustains more of itself → go further, or into the wind.

## The camp

- **The camp is several physical things, not one building.** The shield is small enough
  to carry. Planters, power and the rest are objects in the world that you tether
  together.
- **It floats when there's power for it.** When there isn't, you haul it. Running low on
  power should feel like a slowdown, not a wall.
- **Power sources trade off against movement** (leaning, not settled). Solar builds
  power by day but is useless in a storm. Heavy gear, like something on caterpillar
  tracks, is strong for the camp but slows you down.
- **About five inventory slots, and almost no menus.** Things live in the world and in
  your hands, not in an inventory screen.

## Runs

- **Endless.** There's no ending. Long-term goals might come later, but the game is
  meant to be played indefinitely.
- **Death means a new run.** Whatever you had stays out there in theory but is
  practically unreachable. With RNG driving both the terrain and the finds, this is
  roguelite territory.

## The world

- **Infinite desert** with simple procedural terrain. Solo, first-person 3D, Godot 4.7.
- **Only what's around the player exists.** There can be exceptions, like a farm left
  running on purpose, but never as the rule. A solo player who abuses that only hurts
  their own frame rate.
- **Possibly stateless** (undecided). The dunes are featureless and shift out of sight,
  so nothing beyond render distance would need storing. Turn back far enough and the
  land has changed. That's a shortcut the fiction supports.
- **No AI enemies**, so no creature rigging.

## Setting (working sketch, not canon)

A colonized desert moon in the Xandaris universe, Kenshi in spirit. A high-tech
spacefaring society settled it and then collapsed to its own AI. Later civilizations
rose and fell in turn (a first and a second empire), leaving an apocalypse world.
Three thousand years after that, the moon has reverted to near-uninhabitable: ruins,
dunes, maybe a few holdouts.

The strangeness at its heart is that **history runs backwards in the ground.** The
oldest, rarest ruins hold the most advanced technology, because they come from the
original colonists. Everything built after them is cruder.

Lore gets worked out loosely alongside the systems so that it stays consistent from
the start.

## How we build it

- **Skeleton first.** Every system exists in a rough form (grey boxes, placeholder
  sounds), all wired into one complete loop, before any single system gets polished.
  Then muscle, then looks. Sand Game and Delve both died from stacking finished
  features on a weak frame.
- **A PRD before code.** Each system gets a PRD describing its skeleton version and
  its full version. It's approved before anything is built.
- **The ground is one function.** A single height function is the truth for the
  terrain mesh, its collision and object placement. Collision is built once per chunk
  and is never rebuilt under the player. World state lives apart from the chunks.
  (These rules come from Sand Game's terrain failure.)
- **Sand Game is the reference** (the [`archive`](https://github.com/hunterjsb/desert/tree/archive)
  branch) for feel, and the source of its sounds, models and shaders. Its code isn't
  reused.

## PRDs to write

1. World & terrain
2. Wind & storms
3. Rope & tethering
4. Bubble shield & the travelling camp
5. Power
6. Survival needs (heat, thirst, hunger)
7. Farming
8. Movement (on foot, hoverboard)
9. Salvage & ruins
10. Radio, sound & atmosphere

## Open questions

- Who is the player, and why are they out here?
- If a good camp reaches steady state, what ends a run? Being endless, cozy and
  permadeath pull against each other.
- Stateless desert: yes or no?
