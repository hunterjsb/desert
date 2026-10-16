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

1. **Sealed fresh water in ruins and survival kits.** This is what you live on at
   first.
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

**As built in the skeleton (2026-10-15):**
- **Your inventory is five slots on the suit, plus your waist** (Hunter's direction,
  2026-10-15, loose). There's no inventory screen to manage. The inventory action opens a
  very minimal view of the slots and what's tied at your waist. Any part with nothing
  fastened to it fits, and rope and wire go in rolled up (below). Menus mostly come as
  devices. There's no main menu yet.
- **The inventory by mouse** (Hunter, 2026-10-16, replacing the look-across picking): the
  inventory action frees the mouse. Clicking a slot with something in it brings it to
  your empty hands; clicking an empty slot puts what you hold into it. Clicking a full
  slot while you hold something that fits swaps them. The slot under the mouse is lit,
  and a click anywhere else in the view does nothing. You don't turn while it's open, and
  take works on the world as ever, not on the slots. Closing it captures the mouse again,
  as does a run ending while it's open.
- **Stakes go in too** (Hunter, 2026-10-16: "we should be able to put stakes in our inv"):
  a stake that isn't driven and has nothing tied to it goes in a slot, and comes out
  ready to drive.
- **Rope goes in as a coil** (Hunter, 2026-10-16: "i cant put rope in my inv"): a rope you
  hold but haven't laid, its first end in your hand and the rest at your belt, rolls back
  up into its coil, the belt end comes off, and the coil goes in the slot. Taken out, it
  comes to your hands and uncoils as ever, its first end in your hand again. A cable
  plugged into nothing goes in the same way, as one piece; taken out, you hold a plug
  with the other plug and its cable following, as with a found one. A laid or tied line
  stays out until it's taken up, and so does one paying out or being let go at your
  waist, a cable plugged in at either end, a plug off any cable, and a strong cable that
  has snapped. Stowed rope and wire lie rolled up as found ones do, as one body: the
  line or cable itself is gone until it's taken out, so nothing of it is left behind to
  go with the land as you travel. The coil keeps the line's length, so the kit's comes
  out 6 m, a found one 12 m and the half of a snapped line its own length, and a save
  keeps it too. The view shows a coil with its length (Rope coil, 6 m) and a stowed
  cable as a cable.
- **The suit** is those slots plus its built-ins: air and radiation protection, free and
  drained by nothing. Its sockets for mods (heater, cooler, reclaimer, battery, harness
  hooks) wait for the full version, so in the skeleton the suit isn't a device yet.
- **Sealed water and food.** A canister holds 2 L and a ration 1,000 kcal, found sealed and
  full. Like a battery, a canister carries what's in it and its light shows how full it
  is. A ration eaten to the end is gone; an empty canister stays, to be filled again.
  Every run starts with one canister and one ration in your slots. Sealed water is found
  in survival kits, and sealed rations in kits and on ruins' floors (Salvage).
- **Needs** are health, hunger and thirst out of 100, on the same fixed tick of world
  time as power, so the dev time warp runs them with everything else. Hunger empties in
  two days and thirst in one, up to twice as fast in the heat (from 30 °C up to the suit's
  hot limit). A full thirst bar is 1.5 L and a full stomach 2,000 kcal. Stamina stays
  Movement's.
- **Auto-eating and drinking:** below 80% thirst or 60% hunger, the suit tops you up to
  full from your slots, from the least full canister or ration first, so one empties and
  frees up before the next is opened. Use a canister or ration you hold to drink or eat
  your fill.
- **The three harms,** in health a second: the storm 0.25 at full intensity, wind 0.01 for
  each m/s past 20, and temperature 0.05 for each degree past the suit's limits of −40 and
  75 °C. Empty, starving takes 0.1 and thirst 0.3. Unharmed, fed and watered, you heal
  from nothing to full in a day. Caught in the open, a full storm and its wind kill you
  in five or six minutes. With nothing left to drink, you have five more once thirst runs
  out. Falls don't hurt yet.
- **Temperature joins the felt weather.** At the equator in the clear it swings between
  −25 and 65 °C, peaking mid-afternoon. The swing widens toward the poles (twice as wide
  at a pole) and a full storm halves it. A bubble holds its share of the way to 20 °C.
  At the equator the suit keeps you within its limits; the heat starts to harm about
  13° out (5 km), and the cold about 20° out. Temperature is what the poles cost.
- **The crude condenser** is a catalog device with a canister socket, a battery slot, a top
  mount for a panel, a port, a ring mount and a bottom mount. It runs whenever it has
  power and a canister with room, drawing 40 W, and makes 10 L an hour of world time in
  air at 0 °C or colder, falling to a fifth of that at 40 °C, by the felt temperature
  where it stands. At the equator in the clear that's about 2 L a day. You drink about
  1.8 L a day there, less under a storm's blanket, so one condenser just keeps you, if it keeps its power and stays
  inside the bubble when a storm comes.
- **How long sealed water lasts:** a full canister and a full thirst bar see you through
  about two days at the equator. Each more canister is about another day.
- **Death starts a new run.** The world goes with everything in it, and a fresh one on a
  new seed takes its place. You start at its spawn, fed and watered, with the canister
  and the ration in your slots.
- **The starting kit** (Hunter, 2026-10-16: "start with the shield and solar panel",
  then five things: water, one ration, a weak shield, a light solar panel and a short
  rope coil). The kit is data, `game/survival/standard_kit.tres` (a `Kit`: what's carried
  into the suit's slots and what's set down beside you, by catalog id and how many, how
  full its batteries start, how long its coil is, and whether it starts cabled). Only
  this standard kit is balanced; choosing a kit waits. Every run, the first and every
  one after a death, begins on a clear morning with the first storm due in three to
  eight minutes, facing where it will come from (Hunter, 2026-10-16: "it spawns me in a
  storm!"), and starts with it: the canister and the ration in your slots, and on
  the sand beside you, once the ground there is solid, a **light shield generator** with
  its battery half charged, switched off, the **light solar panel** cabled into its port,
  and a **6 m rope coil** (a found one lays 12 m). The light shield is clearly weaker
  than a found one: a 4 m bubble against 7 m (a third of the room for a camp), and it
  lets half the wind through, so lines inside still take load. It's built light enough
  that the light panel keeps it going: it sips 2 W in the clear and draws 20 W holding
  back a full storm. On the probes' seed, a day of the run's own weather at the spawn
  (a quarter of it under a storm) ran it from 50.0 to 50.9 Wh, the panel making 3.0 Wh
  to the shield's 2.1, never lower than 49.8. A clear day gains about 2.5 Wh; a day of
  full storm loses about 6, which its half battery covers for a week of them. No shield
  of any kind goes in your slots; you carry one in your hands. A dev scenario that
  drops its own camp clears the run's kit first. Survival probe 4 checks both runs start
  with it and runs the light shield for a day.
- **Food and water from salvage:** no new food was needed. Survival kits, common on
  ruins' floors and sometimes on open sand, hold a sealed canister and a ration three
  times in four, and seeds for a planter; loose rations and seeds lie on ruins' floors.
- **The playtest scenario** ("survive a few days", in the dev menu) starts you over at a
  clear dawn, with a condenser in front of you (a battery, a panel and an empty
  canister fitted), a charged shield generator, a cable and two spare rations. A
  simulated run of it on the probes' seed: standing in the open, a storm kills you on
  day two. With the shield alone, a long storm drains it on day three. With the shield
  and the condenser cabled into one pool, and canisters swapped as they run dry, you're
  alive after three days with a quarter of the power left.

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
6. **The inventory by mouse.** The inventory action frees the mouse and closing it
   captures it again. Clicks move things between your hands and your slots as they
   should, and a plug off any cable never fits.
7. **Rope goes in as a coil.** The kit's 6 m coil and a found 12 m one each go in a slot,
   and a kilometre on come out, pay out to the same length and tie onto stakes; paying
   out or laid, a line stays out. A cable plugged into nothing goes in and comes out
   whole, a strong one too; plugged in at one end, it stays out.

## Out of scope

- Disease, injuries to specific body parts, and sleep.

## Open questions

- **Why is the scavenger out here?** The game reveals it over time. We don't need the
  answer yet.
