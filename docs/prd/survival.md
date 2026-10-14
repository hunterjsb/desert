# PRD: Survival

*Draft, 2026-10-13. Answers to [the vision](../vision.md). The physical reasoning behind
air, temperature and water is in [the moon](../the-moon.md).*

## Why this system exists

Survival is the pressure that a good camp turns into steady state. Out here you need
air, water, food and protection from the elements. Early on, every one of them is a
worry. A well-built camp handles them without you, until going AFK costs nothing.

## Who you are

**A scavenger and a survivor, in a suit.** Nobody survives on this moon without one:
the air is too thin to breathe, the days are scorching, the nights freeze, and
radiation reaches the ground.

**Why you're out here** gets revealed over the course of the game, never up front.
First and foremost, you're out here to survive.

## The suit

- **The suit is the one gift this brutal world gives you.** Its air and radiation
  protection are free, with no power and no bar. You have a sick suit, and you're not
  dead.
- **Losing the suit kills you.** For now that's the whole rule.
- **It's a device like any other,** with sockets (Devices & mods) plus some built-in
  features. Fit a heater, a cooler, a water reclaimer, a better battery or harness
  hooks.
- **It shapes how you tether.** Harness points, how strong a waist line can be, and how
  hard a gust drags you all depend on the suit.

## What you track

| Need | What drains it | What restores it |
|---|---|---|
| **Health** | The three harms, falls, and empty needs | Rest, food, time inside the shield |
| **Hunger** | Time | Food |
| **Thirst** | Time, faster in the heat | Water |
| **Stamina** | Sprinting, climbing slip faces, holding a line under load | Rest |

## The three harms

These come from the Bubble shield PRD, applied to you through the felt weather:

- **Wind:** strong wind, including gusts outside storms.
- **Storm:** dust and sand scouring you.
- **Temperature:** heat and cold, wider toward the poles. The base shield doesn't block
  it, but suit mods can resist it.

## Water

Water freezes overnight, melts at dawn and boils off by afternoon (see the moon).
Sources, from early to late:

1. **Sealed fresh water in ruins.** This is what you live on at first.
2. **Frost and dew,** harvested in the cold hours. There's more toward the poles.
3. **Condensers,** found, powered and towable. They work best at night.
4. **Water-storing plants,** like the yucca.

Open water doesn't last, so water lives in sealed containers.

## Food

From farming, and from sealed rations in ruins.

## AFK is something you build

There's no hard-coded "camp feeds you" rule. Instead:

- **You auto-eat and auto-drink from your own inventory,** which is limited.
- **A properly automated farm drops food and water onto you.** You pick it up, and auto
  eating and drinking does the rest.

With the setup right, you can go fully AFK. You just have to build it.

## On screen

Health, hunger, thirst and stamina get **bars**. That's an exception to "almost no menus"
at this early stage. They might show only when a need runs low, but they're always
visible in dev mode. Better ways to express them come later: breathing, vision, sound
and readouts on the suit.

## Death

Death means a new run (see Runs in the vision).

## Rules

1. **Needs tick at a fixed rate,** independent of frame rate.
2. **Every harm reads the felt weather,** so inside a shield that blocks a harm, it
   doesn't touch you.
3. **Auto-eating and auto-drinking only draw from your inventory.** Anything else, you
   build.
4. **Every number is visible in dev mode.**

## Skeleton version

- Health, hunger, thirst and stamina, shown as bars.
- The three harms, through the felt weather.
- The suit as a device with a couple of sockets. Its air and radiation protection are
  free built-ins.
- Auto-eat and auto-drink from inventory.
- Sealed water in ruins, and one crude condenser.
- Death starts a new run.
- A dev overlay showing every number.
- The probes below, all passing.

## Full version

- **Suit mods:** heater, cooler, water reclaimer, harness hooks.
- **The water rhythm:** frost and dew, and open water that freezes and boils off.
- **Water-storing plants.**
- **Farm automation that delivers to you** (Farming).
- **Needs you can read without bars:** breathing, vision, sound, suit readouts.
- **Radiation as a harm** (an idea for later), maybe combined with storm and heat
  damage. For now the suit handles it.

## Probes

1. **The AFK promise, with a body.** A reference camp with an automated farm keeps an
   idle player alive through 24 simulated hours. Take the farm away and the same player
   dies, which proves the test can fail.
2. **Frame-rate proof.** Needs drain the same at 30, 60 and 120 frames per second.
3. **Shelter means safe.** Inside a shield that blocks a harm, that harm does nothing to
   you.
4. **A clean new run.** Death starts a new run with nothing left over from the old one.
5. **Water's daily rhythm** (once adopted). At the equator, open water freezes at night
   and boils off by afternoon.

## Out of scope

- Disease, injuries to specific body parts, and sleep.

## Open questions

- **Why is the scavenger out here?** The game reveals it over time. We don't need the
  answer yet.
