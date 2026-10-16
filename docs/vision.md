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
   farm, at the size of one traveller. In practice, it's a power budget that balances
   through day, night and storm.
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

## Two moods

- **Clear skies:** big, lonely, epic views to a horizon blurred by heat shimmer. These
  are rare, and you earn them with diligence and some luck in staying away from the
  storms.
- **Inside a storm:** you can barely see past your shield, if at all. This is where it
  gets cozy.

## The camp

- **Editing your devices is the gameplay.** Every device is modular, with sockets for a
  battery, rope hooks, a hover tray and better parts. Fitting a hook, a tray, a better
  battery or a charged one is how you progress.
- **The camp is several physical things, not one building.** The shield is small enough
  to carry. Planters, power and the rest are objects in the world that you tether
  together.
- **The shield decides how big the camp can be.** Whatever is outside the bubble in a
  storm gets destroyed, so the camp is as big as the best shield you can move through a
  storm.
- **Shields open up the map.** The base shield keeps out wind and dust but not heat or
  cold, so it pushes you into the storms early. Shields that hold back temperature are
  what open up the poles. Late game, shields nest: a big wind shield around the camp,
  with a smaller temperature shield around the farm.
- **It floats when there's power for it.** When there isn't, you haul it. Running low on
  power should feel like a slowdown, not a wall.
- **Power sources trade off against movement** (leaning, not settled). Solar builds
  power by day but is useless in a storm. Wind power is strongest in a storm, but it
  has to be planted, so you either stay or leave it behind. Heavy gear, like something
  on caterpillar tracks, is strong for the camp but slows you down.
- **Parts are found, never crafted** (for now), and they wear out only from the
  elements. Salvage is the whole economy.
- **The camp moves at walking pace, and storms are weathered, not outrun.** Each storm
  is a judgment call: stay and let it pass, or push through inside the bubble. Early on,
  a post or ruin to tie to is precious.
- **Haulers make the base faster later:** a rusty mechanical beast that follows and
  carries (stiff parts, so no skin rigging), a sand yacht that rides the wind and might
  outrun a storm with the camp aboard, and big carriers.
- **The hoverboard is just for you:** fast, floaty and fun, for scouting and escaping. It
  tows nothing.
- **Your hands plus about five inventory slots, and almost no menus.** Things live in
  the world and in your hands, not in an inventory screen. (Hunter, 2026-10-15, loose:
  one action brings up a very minimal overlay of your few slots and what's at your waist,
  tied into the world rather than managed. Maybe putting something down while it's open
  stows it. Most menus come as devices. A main menu exists for new run, resume and
  options.)

## Runs

- **Endless.** There's no ending. Long-term goals might come later, but the game is
  meant to be played indefinitely.
- **Death means a new run.** Whatever you had stays out there in theory but is
  practically unreachable. With RNG driving both the terrain and the finds, this is
  roguelite territory.
- **You start with the essentials:** a floating crate with a weak shield and a light
  solar panel mounted on top and a hook to tow it by, a hoverboard beside it, a short
  rope coil, and sealed water and a ration in the suit (Hunter, 2026-10-16: "start the
  player with floating crate, shield and hoverboard"; earlier the same day the shield
  and panel lay on the sand and the board was only a find). The shield and panel are
  clearly worse than anything found deep, so the first deep find reads as an upgrade,
  and the kit can never leave the shield without power.
- **Permadeath is the intended mode, and it's what we balance around.** Save & quit only
  suspends a run: one save per run, and death ends it ([Profile & saves](prd/profile-and-saves.md)).
  An optional mode allows saving and reloading, but turning it on disables achievements,
  the way Project Zomboid-style games treat their custom difficulty settings.

## The world

- **A day lasts about 20 minutes,** start to finish. That drives solar and the
  temperature swings.
- **Infinite desert** with simple procedural terrain. Solo, first-person 3D, Godot 4.7.
- **Only what's around the player exists.** There can be exceptions, like a farm left
  running on purpose, but never as the rule. A solo player who abuses that only hurts
  their own frame rate. Ride too far from your camp and it's forgotten, but the game
  always warns you clearly first.
- **Stateless.** The dunes are featureless and shift out of sight, so nothing beyond
  render distance is stored. Turn back far enough and the land has changed.
- **It's a moon, not a plane.** Your position is tracked as latitude and longitude, so
  walking far enough brings you back round and the poles are real places. The ground
  near you is still flat.
- **Latitude is the second difficulty dial.** Toward the poles, storms weaken but the
  temperature swings get wider: hotter days, colder nights. Difficulty changes kind
  rather than amount. The equator is stormy and mild, while the poles are clear and
  extreme, so the big views are more common there and you pay for them in heat and
  cold. It also gives two play styles: the equator is choppy and rich in salvage, while
  the poles have less loot but more stability, which suits building big and outpacing
  the storms.
- **World coordinates are always tracked**, so distance from spawn is known even
  though the land isn't kept. A fixed underlying topography (the large shapes the dunes
  sit on) may come later.
- **No AI enemies**, so no creature rigging.

## Setting (working sketch, not canon)

A colonized desert moon in the Xandaris universe, Kenshi in spirit. A high-tech
spacefaring society built a transit hub there, and then a war cut the lane and orphaned
it. It became a smuggler moon, until a volcanic paroxysm cut every outside link and took
most of the people who understood the machines. Bronze Age empires rebuilt in the ashes
and rose and fell in turn, leaving an apocalypse world. Roughly three thousand years
later, the moon has reverted to near-uninhabitable: ruins, dunes, maybe a few holdouts.
The air is thin and fading, the days scorch, the nights freeze, and water goes through
all three phases every day. The physics is in [the moon](the-moon.md), and the history
is in the lore session ([part 1](lore-session-2026-10-14.md), [part
2](lore-session-2026-10-14-part-2.md)) and [the lore research](lore-research.md).

You're a **scavenger and a survivor, in a suit**, because nobody survives here without
one. The suit is the one gift this world gives you. Why you're out here gets revealed
over the course of the game, never up front. First and foremost, you're out here to
survive.

The strangeness at its heart is that **history runs backwards in the ground.** The
oldest, rarest ruins hold the most advanced technology, because they come from the
original colonists. Everything built after them is cruder.

**People are only ever hinted at.** A hatch open in the distance, just out of reach. A
ruin with something recently used left behind. Maybe a voice on the radio. There are no
NPCs, and the game never answers the question.

Lore gets worked out loosely alongside the systems so that it stays consistent from
the start.

## How we build it

- **Skeleton first.** Every system exists in a rough form (grey boxes, placeholder
  sounds), all wired into one complete loop, before any single system gets polished.
  Then muscle, then looks. Sand Game and Delve both died from stacking finished
  features on a weak frame.
- **A PRD before code.** Each system gets a PRD in `docs/prd/` describing its skeleton
  version and its full version. It's approved before anything is built.
- **Headless probes prove it works.** Every system ships with automated checks that run
  the game without a window and assert on what happened. In Delve they caught almost
  every bug, and almost none of those bugs were visible by reading the code.
- **The ground is one function.** A single height function is the truth for the
  terrain mesh, its collision and object placement. Collision is built once per chunk
  and is never rebuilt under the player. World state lives apart from the chunks.
  (These rules come from Sand Game's terrain failure.)
- **Sand Game is the reference** (the [`archive`](https://github.com/hunterjsb/desert/tree/archive)
  branch) for feel, and the source of its sounds, models and shaders. Its code isn't
  reused.

## PRDs

1. [World & terrain](prd/world-and-terrain.md)
2. [Wind & storms](prd/wind-and-storms.md)
3. [Rope & tethering](prd/rope-and-tethering.md)
4. [Bubble shield & the travelling camp](prd/bubble-shield-and-camp.md)
5. [Devices & mods](prd/devices-and-mods.md)
6. [Power](prd/power.md)
7. [Survival](prd/survival.md)
8. [Farming](prd/farming.md)
9. [Movement](prd/movement.md)
10. [Salvage & ruins](prd/salvage-and-ruins.md)
11. [Radio, sound & atmosphere](prd/radio-sound-and-atmosphere.md)
12. [Menus & UI](prd/menus-and-ui.md)
13. [Profile & saves](prd/profile-and-saves.md)

The order we build them in is the [skeleton plan](skeleton-plan.md).

## Open questions

- Why is the scavenger out here? The game reveals it over time, and we don't need the
  answer yet.
- If a good camp reaches steady state, what ends a run? Being endless, cozy and
  permadeath pull against each other. A long-horizon backdrop for any answer: the moon
  itself has an end state, a calm, stable desert once its orbit recircularises.
