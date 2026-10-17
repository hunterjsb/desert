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
First and foremost, you're out here to survive. (Session 4, part 2 gives each start an origin;
the default is a Tilg & Standard contractor. See [the vision](../vision.md#player-origins-and-kits).)

## The suit

- **The suit is the one gift this brutal world gives you.** Its air and radiation
  protection are free, with no power and no bar. You have a sick suit, and you're not
  dead. So is its **headlamp** (Hunter, 2026-10-16), which comes on by itself in the
  dark, at night or in a storm, so your tracks can be followed when nothing else lights
  the sand. **Switched by hand for now** (Hunter, 2026-10-17: "have b toggle the headlamp
  for now and then add eye adaptation"): its own action turns it on and off, fading
  either way, and a run begins with it off; it no longer comes on by itself. It was
  briefly switched off altogether the same day. **Built** (2026-10-16): a warm spot from your head along your view, tilted a
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
3. **Condensers,** found, powered and towable. They work best at night, and **better toward
   the far side** (Agreed, session 4, part 2; a hook, not built). Water evaporates on the warm
   near side and cold-traps as frost and ground ice on the far side, so the far side's colder air
   is where a condenser makes most. The condenser already reads the felt temperature where it
   stands (below), so the hook is the far side being colder; the game has no near and far side
   yet, only latitude, so it waits for them ([the lore](../lore-research.md#tu-the-tidal-lock-and-the-water-agreed-session-4-part-2)).
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
  a stake that isn't driven and has nothing tied to it goes in a slot as it is, and comes
  out to your hands ready to drive. A found one goes in once it's taken up. A driven
  stake stays out, and so does one with a line on its eye until the line's end is taken
  off it. The view shows it as Stake, and a save keeps it in its slot.
- **Rope goes in as a coil** (Hunter, 2026-10-16: "i cant put rope in my inv"): a rope you
  hold but haven't laid, its first end in your hand and the rest at your belt, rolls back
  up into its coil, the belt end comes off, and the coil goes in the slot. Taken out, it
  comes to your hands and uncoils as ever, its first end in your hand again. A cable or a
  hose plugged into nothing goes in the same way, as one piece; taken out, you hold a plug
  with the other plug and its cable following, as with a found one. A laid or tied line
  stays out until it's taken up, and so does one paying out or being let go at your
  waist, a cable plugged in at either end, a plug off any cable, and a strong cable that
  has snapped. Stowed rope and wire lie rolled up as found ones do, as one body: the
  line or cable itself is gone until it's taken out, so nothing of it is left behind to
  go with the land as you travel. The coil keeps the line's length, so the kit's comes
  out 6 m, a found one 12 m and the half of a snapped line its own length, and a save
  keeps it too. The view shows a coil with its length (Rope coil, 6 m) and a stowed
  cable as a cable.
- **The inventory shows things as they are, and gadgets work from it** (Hunter,
  2026-10-17: "display the rendered items, so if a player has a compass or gadget in their
  inventory, they can use it by just openening it and dont necesarily need to mount or
  hold it for it to be fully useful"). Each slot shows its thing rendered, lit as in the
  world, with its name and the number that matters under it (water left, a coil's length,
  a battery's charge). Small gadgets go in a slot whole and keep working there: the radio
  plays from you on its own battery, and the compass's needle turns live in its slot, so
  opening the inventory is a glance at it. Use on a slot uses the thing in place (turns the
  radio's dial); a click still brings it to your hands. Bigger devices still need your
  hands or a mount.
- **The compass** (2026-10-17): a small find, a part, whose needle points to the moon's
  north. Held, you read it in your hand; in a slot, in the inventory. The sun gives you the
  same without one: the moon has no tilt, so the sun rises due east and sets due west
  everywhere, stands to the south at noon north of the equator (north of you south of it,
  overhead on it), and morning shadows point west. A storm hides it; the compass doesn't
  care.
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
- **The hose** (Hunter, 2026-10-17: "like the cable, it carries water, it tethers but not
  as strong as rope"). Two ends on 6 m of hose, a thick tube of sun-faded blue rubber,
  each end a steel coupling that fits a water socket with the same snap as a canister:
  the condenser's, a planter's, a survival kit's. Each water socket takes one thing, a
  canister or a hose's end, so a fitted end offers a water socket of its own, on a spout
  on top, as a hook offers a ring: a canister goes on there, or another hose's end, and
  one condenser waters two planters. Devices joined by hoses share their water as cabled
  ones share power, on the farm's tick of world time. What a condenser makes goes to the
  emptiest tank first, then to the fullest canister with room, so one fills up for you to
  take away; with a hose in place of its canister its water goes straight down the hose,
  and with nowhere for it (everything it reaches full, or nothing at the hose's far end)
  it stops, as with a full canister. Tanks are kept full from the canisters, the least
  full first, so one empties and frees up, as your suit drinks from them; a canister at
  one end of a hose feeds the planter at the other (water probe 1). Nothing flows from
  canister to canister, and a hose carries no power. A hose is a rope, as a strong cable
  is, so it holds what it joins and hangs and sags like one, drawn thicker than rope in
  blue rubber. It holds a third of a rope's load, 500 N sustained, and past that it never
  snaps: an end pops out of its socket, and the hose stays on by the other, dragging the
  loose end along. A floating planter hosed to a staked condenser stays on the end of its
  hose in a 15 m/s wind, the hose bearing 400 N at most; in a 40 m/s storm wind it pops
  at 500 N and the planter blows away, while a
  rope under the same pull, 920 N, holds (water probe 2). A storm's steady wind loads a
  floating planter about 325 N and its hardest gusts about twice that, so a hose alone
  holds through most of a storm and lets go in its worst. Rolled up it goes in a slot
  like a cable, shown as a Hose, and stays out while an end is in a socket. A save
  keeps hoses, what's on their ends and the water in tanks (saves probe 11). It's found
  on open sand, a little less often than wire, and `give hose` makes one.
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
- **The crude condenser** is a catalog device with a water socket, a battery slot, a top
  mount for a panel, a port, a ring mount and a bottom mount. It runs whenever it has
  power and somewhere for its water, a canister with room or a hose (above), drawing 40 W, and makes 10 L an hour of world time in
  air at 0 °C or colder, falling to a fifth of that at 40 °C, by the felt temperature
  where it stands. At the equator in the clear that's about 2 L a day. You drink about
  1.8 L a day there, less under a storm's blanket, so one condenser just keeps you, if it keeps its power and stays
  inside the bubble when a storm comes.
- **How long sealed water lasts:** a full canister and a full thirst bar see you through
  about two days at the equator. Each more canister is about another day.
- **Death starts a new run.** The world goes with everything in it, and a fresh one on a
  new seed takes its place. You start at its spawn, fed and watered, with the canister
  and the ration in your slots.
- **The starting kit** (Hunter, 2026-10-16, after playing the first one: "start the
  player with floating crate, shield and hoverboard already mounted ... we should at
  least add a hook so we can tow it"). The kit is data, `game/survival/standard_kit.tres`
  (a `Kit`: what's carried into the suit's slots, what's set down beside you and where,
  what comes assembled, socket by socket, which lines are laid, how full its batteries
  start and how long its line is). Only this standard kit is balanced; choosing a kit
  waits. (Session 4, part 2 balances three kits, the Surveyor, the Salvager and the
  Homesteader, and lists the Surveyor's standard shield, multi-compass, stake tether and radio
  against the kit below, a light shield, a light panel and a racked board: the clash is
  recorded in [the vision](../vision.md#player-origins-and-kits), and this kit is what's
  built.) Every run, the first and every one after a death, begins on a clear morning
  with the sun well up, a third of the way through the day, so the panel makes about
  half its 30 W from the first minute, and the first storm due in three to eight
  minutes, facing where it will come from (Hunter, 2026-10-16: "it spawns me in a
  storm!"), and starts with it: the canister and the ration in your slots, and beside
  you, once the ground there is solid:
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
    kit, `8: &"board",` among the crate's sockets, naming the board beside you in the
    rack; without that line it lies on the sand at your left.
  None of it overlaps you or each other at the start, the racked board included, and
  neither the crate, the board, the panel nor any shield goes in your slots; you carry a
  shield in your hands.
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
  as you'd leave yourself: three canisters of water, nothing to eat, and two slots free
  for what the farm drops. Idle in the reference camp (Power) at the equator for three
  days of the probes' seed, about two of them storm, you come through untouched: the
  bubble keeps every harm off you, the farm's drops are all you eat, 2,400 kcal, and you
  drink about 1.7 L a day. Take the farm away and you starve at 2.83 days (probe 1).
- **Water is where AFK ends.** Nothing brings you water yet: you drink only from your
  slots. The camp's condenser waters only the farm, down its hoses, and a canister it
  fills still has to come to your slots by hand. So the camp keeps you as long as the
  water you carry: left on, the three canisters were empty by four days and you died of
  thirst at 4.78, fed, with food stored and the shield up, while the farm's tanks stayed
  above 3 L (Farming).

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
7. **Rope goes in as a coil.** A 6 m coil, the kit's length, and a found 12 m one each go
   in a slot, and a kilometre on come out, pay out to the same length and tie onto
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
10. **Stakes go in.** A found stake and a loose one, each taken up, go in a slot and
    come out ready to drive; driven, each holds a crate floating on a line in a breeze,
    the found one after a save and a resume too. A driven stake, or one with a line on
    its eye, stays out.
11. **The headlamp.** Under a clear sky at noon it's off. At dusk, the light wavering
    round its threshold as a passing veil of dust would, it comes on once and stays on.
    Deep in a storm at night it's on, and lights the ground 10 m ahead at least as well
    as a device's lamp lights the sand 5 m off.

## Out of scope

- Disease, injuries to specific body parts, and sleep.

## Open questions

- **Why is the scavenger out here?** The game reveals it over time. We don't need the
  answer yet. *Narrowed by session 4, part 2:* each origin has its own reason, and the default
  is a Tilg & Standard contractor ([the vision](../vision.md#player-origins-and-kits)).
