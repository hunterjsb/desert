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
  dead. So is its **headlamp** (Hunter, 2026-10-16), which comes on by itself in the
  dark, at night or in a storm, so your tracks can be followed when nothing else lights
  the sand. **Switched off for now** (Hunter, 2026-10-17: "lets actually disable the
  headlamp for now"): one setting in the tuning turns it back on, and its probe and
  look-test turn it on for themselves. **Built** (2026-10-16): a warm spot from your head along your view, tilted a
  little down, with a soft edge and no shadows (what you hold would throw one down the
  beam). It fades on over a second and a half once the light on open ground round you
  falls below 15% of the sun overhead and the whole sky's, which is sunset, any night,
  or deep in a storm by day, and off again only past 25%, so it never flickers at the
  edge (probe 11). It needs no action, power or bar, and nothing in the world reads it.
  In a storm at midnight, where the sand is otherwise 0.7 (L*, from `look/headlamp`),
  the sand 5 m ahead is 35 with steps 5 darker, 10 m ahead 13 with steps 2 darker, and
  15 m ahead 6. By a camp the bubble's ring and a lamp's own pool still stand out in
  its light. It costs the GPU nothing measurable at 1920x1080 (within 0.1 ms, the
  noise of four runs); its shadows would add 0.06 to 0.3 ms. Tuning's Light group
  holds its thresholds and beam.
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
- **Your inventory is what the suit carries, by weight, plus your waist** (Hunter,
  2026-10-17, replacing the five slots of 2026-10-15: "Move to weight-bound with no
  defined size, replacing slots. This allows stacks and avoids inventory management. Soft
  limit: extra weight slows you and you start sinking into the sand. The inventory clearly
  shows when you're encumbered and by how much."). There's no inventory screen to manage
  and no count: whatever you can carry in your hands goes in, with nothing fastened to it
  (below), and weight is the only limit. Menus mostly come as devices.
  - **The soft limit.** Up to 30 kg you don't feel it. Past it you sink into the sand the
    way hauling on a line digs you in (Movement): lower by a few centimetres, slower and
    tiring faster on the move, standing too but tiring only as you walk. By 60 kg you're
    sunk in as far as hauling takes you, at 65% of your pace, and every kilogram past
    that slows you further (at 90 kg, a third of it). The run's kit carries 2.9 kg, a
    canister and a ration; every carryable thing of the kit, its stake, its board with
    the board's battery and the light panel too, comes to 20.9 kg, comfortably under.
    Probe 14 measured 1.80 m/s with the kit and 1.17 m/s at 59.9 kg, sunk 6.5 cm. Only
    what you carry counts, not what's in your hands. On a board you ride as ever.
  - **Stacks.** Like things stack as one: canisters, rations, batteries, stakes, hooks,
    coils of a length, cables of a kind. A device with anything fitted in it, a radio with
    its battery, is a thing of its own.
  - **Nothing fastened.** A device goes in whole, seated on nothing, with nothing seated on
    it, no plug in its ports and no line on its rings. So the board, the light panel and
    a shield generator go in once they're off the crate; the crate doesn't, being too
    heavy to carry. A shield carried running keeps its bubble round you as one in your
    hands does. A size cap for things big but light, like the board, is an open question.
- **The inventory by mouse** (Hunter, 2026-10-16, replacing the look-across picking): the
  inventory action frees the mouse. A click on a thing, or a stack, brings one to your
  empty hands, the fullest of water, food or charge; a click anywhere on the view with
  something in your hands puts it in. The thing under the mouse is lit. You don't turn
  while it's open, and take works on the world as ever, not on what you carry; so does
  use, but over a thing it's the thing's (below). Closing it captures the mouse again, as
  does a run ending while it's open.
- **Stakes go in too** (Hunter, 2026-10-16: "we should be able to put stakes in our inv"):
  a stake that isn't driven and has nothing tied to it goes in as it is, and comes out to
  your hands ready to drive. A found one goes in once it's taken up. A driven stake stays
  out, and so does one with a line on its eye until the line's end is taken off it. The
  view shows it as Stake, stakes stack, and a save keeps them carried.
- **Rope goes in as a coil** (Hunter, 2026-10-16: "i cant put rope in my inv"): a rope you
  hold but haven't laid, its first end in your hand and the rest at your belt, rolls back
  up into its coil, the belt end comes off, and the coil goes in. Taken out, it comes to
  your hands and uncoils as ever, its first end in your hand again. A cable plugged into
  nothing goes in the same way, as one piece; taken out, you hold a plug with the other
  plug and its cable following, as with a found one. A laid or tied line stays out until
  it's taken up, and so does one paying out or being let go at your waist, a cable plugged
  in at either end, a plug off any cable, and a strong cable that has snapped. Carried rope
  and wire lie rolled up as found ones do, as one body: the line or cable itself is gone
  until it's taken out, so nothing of it is left behind to go with the land as you travel.
  The coil keeps the line's length, so the kit's comes out 6 m, a found one 12 m and the
  half of a snapped line its own length, and a save keeps it too. The view shows a coil
  with its length (Rope coil, 6 m) and a carried cable as a cable.
- **The inventory shows things as they are, and gadgets work from it** (Hunter,
  2026-10-17: "display the rendered items, so if a player has a compass or gadget in their
  inventory, they can use it by just openening it and dont necesarily need to mount or
  hold it for it to be fully useful"). As built:
  - **Each thing or stack is a tile** with a picture of its own painted model, seen from a
    little above and to one side (a compass nearly straight on, to read), its name, the
    number that matters for all of the stack together (water, food, charge, a coil's
    length, a radio's channel with its battery's charge) and, for a stack, how many. Tiles
    run in rows of up to eight, low in the middle of the screen. The light is a clear
    day's, the world's own sun and sky colours, whatever the hour or the weather outside,
    so a tile reads in a storm at night.
  - **The weight** is a line over the tiles, what you carry against the 30 kg you carry
    easily, and a bar up to 60 kg marked at 30. Past it the line says you're encumbered,
    how far over and what it leaves of your pace ("encumbered: 59.9 kg, 29.9 over · 65%
    pace"), and the line and the bar's part past the mark are in the accent.
  - **Cheap:** a tile's picture is drawn only while the view is open, once when what it
    shows changes, and not again until it does; a compass's is drawn again only as its
    needle turns. Measured at 1920 by 1080 (`look/inventory`, other probe runs sharing the
    machine), carrying six stacks: the view open and still adds about 0.3 ms a frame, 5.5
    to 5.7 ms, and draws no picture again; turning with a compass carried, it draws one
    picture a frame, 0.05 ms of the GPU.
  - **A device you carry works on its own battery, as anywhere else** (Hunter, 2026-10-17,
    rejecting a pocket flag and a built-in cell as exceptions to core systems): it rides on
    you out of sight, touching nothing, and the weather doesn't wear it in the suit. So a
    radio plays from you, its line of words showing as ever.
  - **Use on a thing uses it where it is:** a device is worked (the radio's dial turns),
    and water or food you drink or eat your fill of, the least full first, as the suit
    would. Anything else does nothing. Over a thing, use never reaches the world, so it
    can't switch what you happen to be looking at; off the tiles it works the world as
    ever. A click brings a radio to your hands still playing.
  - **Saves** keep everything you carry, each thing with its state, so stacks come back as
    they were, and a radio its channel, beacon and charge. A save from before, with five
    slots, resumes with what was in them carried.
- **The compass** (2026-10-17): a small find, a part, whose needle points to the moon's
  north. Held, you read it in your hand; carried, in the inventory. The sun gives you the
  same without one: the moon has no tilt, so the sun rises due east and sets due west
  everywhere, stands to the south at noon north of the equator (north of you south of it,
  overhead on it), and morning shadows point west. A storm hides it; the compass doesn't
  care. As built:
  - **A 12 cm field compass,** 0.2 kg, company issue: a gunmetal case, a bone card under a
    black bezel, north marked on the card in safety yellow, and a needle whose red north
    half glows a little, so it reads at night and in a storm. Nothing takes it: it's read,
    not fitted.
  - **Held flat** (taken up from the sand), it points north along the ground. **Held up**
    (out of the inventory, it comes to your hands facing you) it reads as if laid level
    with its top away from you: north ahead is straight up the card, north on your right
    is to the right. Carried, the inventory shows it the same way, turning as you turn.
  - **Past a pole.** Walking over a pole turns the moon's north round (the moon position
    keeps which way it lies), and the compass follows that, not the world's fixed axes: it
    always points the way that takes you toward the north pole. The radio's spoken
    bearings follow the same north, so the two never disagree. The sun doesn't yet: the
    day is one clock for the whole moon, so past a pole the sun keeps the course it had,
    rising in the compass's west. Turning it round there would make it jump at the pole.
  - **Found** on the surface, one in nineteen of the surface layer's loose parts (107 of the
    4,675 finds salvage probe 5 tallies over two seeds, about one in 44),
    and the console's `give compass` puts one in your hands.
- **The suit** is what it carries plus its built-ins: air and radiation protection, free
  and drained by nothing. Its sockets for mods (heater, cooler, reclaimer, battery,
  harness hooks) wait for the full version, so in the skeleton the suit isn't a device yet.
- **Sealed water and food.** A canister holds 2 L and a ration 1,000 kcal, found sealed and
  full. Like a battery, a canister carries what's in it and its light shows how full it
  is. A ration eaten to the end is gone; an empty canister stays, to be filled again.
  Every run starts carrying one canister and one ration. Sealed water is found
  in survival kits, and sealed rations in kits and on ruins' floors (Salvage).
- **Needs** are health, hunger and thirst out of 100, on the same fixed tick of world
  time as power, so the dev time warp runs them with everything else. Hunger empties in
  two days and thirst in one, up to twice as fast in the heat (from 30 °C up to the suit's
  hot limit). A full thirst bar is 1.5 L and a full stomach 2,000 kcal. Stamina stays
  Movement's.
- **Auto-eating and drinking:** below 80% thirst or 60% hunger, the suit tops you up to
  full from what you carry, from the least full canister or ration first, so one empties
  before the next is opened. Use a canister or ration you hold, or one you carry in the
  inventory, to drink or eat your fill. A canister or ration inside a carried survival
  kit isn't drawn on: take it out first.
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
  new seed takes its place. You start at its spawn, fed and watered, carrying the
  canister and the ration.
- **The starting kit** (Hunter, 2026-10-16, after playing the first one: "start the
  player with floating crate, shield and hoverboard already mounted ... we should at
  least add a hook so we can tow it"). The kit is data, `game/survival/standard_kit.tres`
  (a `Kit`: what the suit carries, what's set down beside you and where,
  what comes assembled, socket by socket, which lines are laid, how full its batteries
  start and how long its line is). Only this standard kit is balanced; choosing a kit
  waits. Every run, the first and every one after a death, begins on a clear morning
  with the sun well up, a third of the way through the day, so the panel makes about
  half its 30 W from the first minute, and the first storm due in three to eight
  minutes, facing where it will come from (Hunter, 2026-10-16: "it spawns me in a
  storm!"), and starts with it: carrying the canister and the ration, and beside you,
  once the ground there is solid:
  - **a floating crate** at your front right: a crate frame with a hover tray, a
    battery half charged and a hook on its back, floating at the tray's height. The
    **light shield generator**, switched off, sits on its front top mount and the
    **light solar panel** on its back one, both on the crate's power. The light panel
    is half a crate's top, the same footprint as a found panel, so the two sit 5 cm
    apart and clear of everything else on the crate (survival probe 4 checks it by
    their bounds).
  - **moored to a stake** driven upwind of it, by the hook, on the kit's **6 m line**
    (a found coil lays 12 m). Floating, nothing holds a crate but its lines: loose in
    the start's 10 to 13 m/s breeze it was gone in seconds. To travel, take up the
    stake and tie it at your waist, and the crate follows on its line with its bubble
    (survival probe 8); to camp, drive the stake again.
  - **a hoverboard** racked on the crate's left side (Hunter, 2026-10-16: "i think it
    should start you w a *racked* hoverboard"), its battery half charged, ready to
    ride: the ride action at it takes it off and steps you on. It's one line of the
    kit, `10: &"board",` among the crate's sockets, naming the board beside you in the
    rack; without that line it lies on the sand at your left.
  None of it overlaps you or each other at the start, the racked board included. None of
  it goes in with what you carry while it's seated on the crate, nor the crate, too heavy
  to carry; the board, the light panel and the light shield do once they're off it.
  The light shield is clearly weaker than a found one: a 4 m bubble against 7 m (a third
  of the room for a camp), and it lets 15% of the wind through where a found one stills
  it (Hunter, 2026-10-16: blocks most of the wind, so you barely drift inside). It sips
  2 W in the clear and draws 20 W holding back a full storm. The crate's tray draws
  about 90 W floating everything on it, the racked board's 11 kg included, and the
  board charges from the crate at up to 50 W, far more than the 30 W panel can keep up
  with, so the crate floats on what its battery holds, and the shield ranks above both:
  neither the tray nor the board ever takes the battery's last quarter (Power). On the
  probes' seed, over the run's own first day (a storm from 0.33 days in, through the
  night) the crate floated until 0.56 days, when, with the battery at 25 Wh, it settled
  onto the sand; with the board lying beside it instead, it floated until 1.00 days. The
  shield ran on, 20.9 Wh left at 1.25 days (23.8 with the board beside), the panel
  having made 3.3 Wh to the shield's 6.3. That storm sits on the spawn for more than
  three and a half days; with the board beside, the shield was still up at 4 days with
  7.1 Wh left. Under clear skies the panel brings the battery from a quarter back to 30%
  in 1.35 days and the crate floats again until it's back at a quarter: a clear day is
  worth a few minutes of floating, fewer while the board charges. The quarter kept back runs the light shield for 75 minutes of
  full storm with no sun, almost four days of it. A dev scenario that drops its own
  camp clears the run's kit first.
  Survival probe 4 checks both runs start with it and runs the light shield into the
  second morning.
- **Food and water from salvage:** no new food was needed. Survival kits, common on
  ruins' floors and sometimes on open sand, hold a sealed canister and a ration three
  times in four, and seeds for a planter; loose rations and seeds lie on ruins' floors.
- **The playtest scenario** ("survive a few days", among the dev scenarios) starts you over at a
  clear dawn, with a condenser in front of you (a battery, a panel and an empty
  canister fitted), a charged shield generator, a cable and two spare rations. A
  simulated run of it on the probes' seed: standing in the open, a storm kills you on
  day two. With the shield alone, a long storm drains it on day three. With the shield
  and the condenser cabled into one pool, and canisters swapped as they run dry, you're
  alive after three days with a quarter of the power left.
- **The AFK promise, with a body** (Stage 12, 2026-10-17). The "afk" scenario stocks you
  as you'd leave yourself: three canisters of water and nothing to eat; the farm drops
  your food onto you. Idle in the reference camp (Power) at the equator for three
  days of the probes' seed, about two of them storm, you come through untouched: the
  bubble keeps every harm off you, the farm's drops are all you eat, 2,400 kcal, and you
  drink about 1.7 L a day. Take the farm away and you starve at 2.83 days (probe 1).
- **Water is where AFK ends.** Nothing brings you water yet: you drink only from what you
  carry, and a condenser fills its own canister, to be swapped by hand. So the camp keeps
  you as long as the water you carry: left on, the three canisters ran out at 4.5 days
  and you died of thirst at 4.8, fed, with food stored and the shield up.

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
   captures it again. A click on a thing brings it to your hands and a click on the view
   puts what you hold in; like things stack, and a click on a stack hands you its
   fullest. A plug off any cable never goes in.
7. **Rope goes in as a coil.** A 6 m coil, the kit's length, and a found 12 m one each go
   in, and a kilometre on come out, pay out to the same length and tie onto
   stakes; paying out or laid, a line stays out. A cable plugged into nothing goes in
   and comes out whole, a strong one too; plugged in at one end, it stays out.
8. **The kit in tow.** In a crosswind you take up the kit's stake, tie it at your waist
   and walk off: the crate follows on its line, floating all the way, its shield's
   bubble with it.
9. **The board racked.** The kit's board seats in its crate's rack through the tug and
   take, clear of everything a fully fitted crate holds, and the ride action takes it off
   and steps you on. Racked, it rides with the crate towed 40 m, charges from the camp
   until the pool is down to the shield's reserve, takes nothing past it, and charges
   again once the panel brings the pool back, every watt-hour of it accounted for. Take
   lifts it off; saved racked, it resumes racked. The kit starts it racked.
10. **Stakes go in.** A found stake and a loose one, each taken up, go in and come out
    ready to drive; driven, each holds a crate floating on a line in a breeze,
    the found one after a save and a resume too. A driven stake, or one with a line on
    its eye, stays out.
11. **The headlamp.** Under a clear sky at noon it's off. At dusk, the light wavering
    round its threshold as a passing veil of dust would, it comes on once and stays on.
    Deep in a storm at night it's on, and lights the ground 10 m ahead at least as well
    as a device's lamp lights the sand 5 m off.
12. **A device works carried.** A radio playing in your hands goes in whole and plays on
    from you on its own battery. Use on it in the inventory turns its dial, and its words
    show; use on your canister there drinks from it, and switches nothing you're looking
    at, while use off the things you carry works the world as ever. A click brings the
    radio back to your hands still on.
13. **The compass reads true.** Held flat it points north whichever way you face; held
    up, north ahead is up its card and north on your right is right; carried, the
    inventory reads the same, live as you turn. Over a pole the needle turns round with
    the moon's north, in your hand and in the inventory.
14. **Weight is the only limit.** Whatever you can carry goes in, a board, a light panel,
    a survival kit and a stake among them, and ten batteries stack as one. With the kit's
    load you walk at your full pace, standing tall; with twice what you carry easily you
    sink in and walk slower by the share the inventory shows, and it says you're
    encumbered and by how much.

## Out of scope

- Disease, injuries to specific body parts, and sleep.

## Open questions

- **Why is the scavenger out here?** The game reveals it over time. We don't need the
  answer yet.
- **A size cap for big but light things?** Weight is the only limit, so a 1.3 m board or
  a light panel goes in as easily as a battery of the same weight (Hunter, 2026-10-17:
  still open). Not built.
