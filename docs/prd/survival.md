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
  In a storm at midnight, where the sand is otherwise under 0.5 (L*, from
  `look/headlamp` at the fixed exposure, measured again under Tu's light 2026-10-17),
  the sand 5 m ahead is 36 with steps 5 darker, 10 m ahead 13 with steps 2 darker, and
  15 m ahead 5. With the eye ([art direction](../art-direction.md#eye-adaptation),
  `look/headlamp --eye`) the beam holds it to under twice: 46, 19 and 8, steps 5, 3 and 2
  darker, and the dark round it stays black. By a camp the bubble's ring and a lamp's
  own pool still stand out in its light. It costs the GPU nothing measurable at 1920x1080 (within 0.1 ms, the
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
4. **Water-storing plants,** like the yucca. Session 4, part 4 (proposed, not built) replaces the
   yucca with the roster's water crops: dewleaf (a night trickle, collected at dawn), stormcup (water
   from a storm, tainted when wild) and sandroot (starch and water, dug from a deep root)
   ([Farming](farming.md#the-plant-system-agreed-session-4-part-4-partly-built)). Whether a water crop
   beats the condenser in some niche is open.

Open water doesn't last, so water lives in sealed containers.

One more source sits in a fixed place (Agreed, session 4, part 3; not built). Mother Cistern's
temple at Sister is dormant but "still drips a trickle into a basin: a reliable small water source
until restored" ([World & terrain](world-and-terrain.md#landmarks), [Salvage &
ruins](salvage-and-ruins.md#landmarks)). Every source above is carried, towed or found where you
are. A basin you can return to is the opposite, so what it does to "your home goes with you" is
open ([the lore](../lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)).

## Food

From farming, and from sealed rations in ruins. Session 4, part 4 adds salt, a crop output that
"makes food last longer," and has vat fungus grow on "rotten food or plant waste" as compost
([Farming](farming.md#the-plant-system-agreed-session-4-part-4-partly-built)). Nothing here spoils yet:
food is a ration, sealed or carried, and eaten by the suit. Whether it should is open
([Farming](farming.md#open-questions)).

## AFK is something you build

There's no hard-coded "camp feeds you" rule. Instead:

- **You auto-eat and auto-drink from your own inventory,** which is limited.
- **A properly automated farm drops food and water onto you.** You pick it up, and auto
  eating and drinking does the rest.

With the setup right, you can go fully AFK. You just have to build it.

## Waiting out a storm: auto-walk, then sleep (agreed, 2026-10-18 spec)

Hunter's [storms, signals & sailing spec](../storms-signals-sailing-2026-10-18.md) settles the sleep question below: storms are the
cozy stress test of your build, tanking them is the stationary, AFK way to play, and clear weather is
the active phase. Three layers fix the early wait:
- **Auto-walk first:** it holds your heading while you steer by the compass or the Console, so a storm
  still lets you make distance. Low risk, so it ships before sleep. *Built (2026-10-18): its own
  action holds the way you faced while your own walk carries you, until you move yourself or
  something stops you ([Movement](movement.md#on-foot)).*
- **Sleep:** a bedroll, beds in some ruins, maybe the open sand if the camp is stable. Use offers so
  many hours, until a time, or through the storm; gear such as a radio adds more (wake for a
  broadcast). **Physics never fast-forwards:** the camp freezes, its batteries and shield are worked
  out against the storm curve over the hours slept, and the result is applied ("shield held", "a
  deck broke loose"). A bedroll sticks on a deck like anything else. Built ([Sleep, as
  built](#sleep-as-built-2026-10-18)).
- **Something to do under the shield:** swapping mods and repairing gear, watching for loot blowing
  in, the radio.

Open: which failures can happen asleep and how likely. *Answered as built (below):* the shield
running dry, a line giving at the storm's peak, wear on what's outside a bubble, and your water or
food running out, each from the night's own numbers rather than dice.

## Sleep, as built (2026-10-18)

*Hunter's [spec](../storms-signals-sailing-2026-10-18.md#sleep), built 2026-10-18 (`game/survival/sleep.gd`).*

**Where you sleep.**
- **The bedroll** is a device by the catalog's rules: devices stay bodies of their own when they're
  stuck on a deck, and a part becomes its deck's shapes, worked by nothing. Rolled company canvas
  0.9 m long, 3 kg, low and round, so a breeze leaves it be on the sand and a storm slides it. Use on
  it laid on the sand, among what you carry, or stuck on a deck asks how long to sleep. In your hands, use
  lays it out where you look, fore and aft as you face, or at your feet when nothing flat is in reach;
  setting it down asks nothing of the camp, only sleeping does. The Surveyor and the Homesteader start
  carrying one; the Salvager, riding light, finds one or a ruin's bed. It's found on deserters' dugout floors (3 in 12 of
  their draws, beside their survival kits) and now and then lying on open sand (1 in 14 of the
  surface's devices). There's no sleeping on bare sand without one: the bedroll is how you sleep in the
  open.
- **Ruin beds.** A kit piece marks boxes as beds (`StructureKit.bed`): the hab pod's bunk, and a
  sleeping bench of saltbush wood, a dyed mat on it, in the house ruin's back room. Looking at one, the
  line says "Bed", and use sleeps there. Buried, it's under the sand with the rest.

**The words.** Use on a bed brings up words over the running game, as the system menu does, nothing
paused: "Through the storm", only while one's on you or due within the weather's own forecast; "Sleep
8 h", left and right changing the hours, 1 to 24; "Until morning", left and right stepping morning
(06:00 local), noon, dusk (18:00) and night (midnight); and with a radio in earshot that has power,
"Until a storm's called", offered while the weather station holds its calm (no storm on you and none
due within five minutes, six hours of the day): the radio comes on to the Walker's carrier as you lie
down, its dial kept on it as it moves from day to day, and the Walker breaking its calm to report a
storm wakes you if the radio hears it, the report on its line as you wake. A god's broadcast at a fixed
hour, the session's sleep clock, isn't built. Through the storm needs a running shield over you.

**Only a still camp sleeps**, read off the physics as it runs: you on your feet and still, your hands
free, nothing at your waist; your devices and stakes within 30 m slower than 0.5 m/s and 1 rad/s, and no sail raised there (the night reckons the wind on what's held, not a
sail's pull); and no harm reaching you where you lie, which in a storm means under a running
shield and out of one, wind under 20 m/s and the air within the suit's limits. Then the screen goes
black over half a second while the physics runs on and the camp is watched. Anything over those marks,
then or at the start, and you don't sleep: use's line says why with the soft knock ("no shield", "the
deck's still moving", naming what moved as you lay down or as the screen went dark, "sail up", "too
windy", "hands full", "a line at your waist").

**The night.** Physics never steps. The camp is held where it stands and the clock steps to when you
wake 10 s of world time at a time (`sleep_tick`), each system living each step by its own sums in the
order a frame runs them, through its `live` tick: Power (panels and turbines by the felt weather,
every draw, the shield's by the storm where it stands, the reserve and the restart), each shield's
bubble straight to what its power says, Wear on what's outside a bubble, the Farm (crops, wild plants,
the hoses' water) and the condenser through Power, then your needs, drinking and eating from what you
carry as the suit does, and the tracks the wind fills. A shield's held storm and a day under the bubble
count toward their deeds asleep as awake. What the physics fed them stays as it stood: a floating
deck's load on its trays, a planted turbine.
- **Lines** meet the wind each step as Ropes reckons it (`load_at`): what a line bore as you lay
  down, plus its share of how much harder the wind then pushes what it holds, held still (Weather's
  `wind_load`: its catch by the felt wind's square, at the hardest gust of the step, read each second).
  A thing on several lines shares its push, so one gone leaves more to the rest. Against live tension in
  steady 20 to 40 m/s winds it's within 11%, mostly a little under.
- **What nothing holds drifts.** Each group of things joined by lines with nothing in it held fast (a
  driven stake, a find) goes with the wind at its speed less what the sand's friction holds back, none
  of it while it floats, as a body slides once the wind beats its friction live. Carried off the ground
  the world keeps, it's gone. Against live, in steady 24 to 40 m/s winds (2026-10-19): a crate slides
  within 2% of it, and the Surveyor's camp, leaning on its edge as it goes, 10% to 25% slower, so a
  night carries a loose camp a little farther than living it would.
- **Against live play** (probe 16): the reference camp lives a day and a night of the probes' seed, a
  storm over a fifth of it or more, at the time warp's fastest, and sleeps the same: its batteries
  1733.6 Wh slept against 1734.2 lived (0.04%), the shield's pool 1567.2 against 1567.8, held both
  times; the turbine's wear and the farm's food agree, and water and thirst agree once the next drink's
  taken. At a 2 s step it's 0.01%, at 20 s 0.08%. A day costs about 0.3 s to sleep and four days about
  1 s, lived in one frame while the screen is black.

**What wakes you:** the hour chosen, the storm passing where you lie, the station's call, never more
than 4 days (`sleep_most_days`); or sooner, any harm reaching you (the storm or the wind as a bubble
goes, the heat, the cold), or thirst or hunger down to a quarter with nothing left to take.
**Sleep is no dodge:** under a bubble the night works the storm out on your camp, and asleep out in
the open, with no bubble over you, a storm's arrival wakes you, the night lived up to its front and no
further ("The storm woke you"). On the probes' seed, a storm due 354 s on woke you 360 s on, the
first sleep tick inside it (probe 20).

**What goes wrong asleep** (the spec's open question), each out of the same numbers, no dice, so a camp
that would come through live comes through asleep and one that wouldn't, doesn't:
1. **The shield runs dry.** Its pool can't meet the storm's draw; its bubble collapses, the storm
   floods in and you wake to it ("Light shield gave out", "The storm woke you").
2. **A line gives at the storm's peak.** Loaded past its strength it gives as it would live: rope
   snaps, a hose pops an end, a stake pulled past its holding comes out. What it held breaks loose and
   goes where the wind takes it ("Deck broke loose", or "Deck blew away" carried off the ground).
3. **Wear.** What was outside a bubble wears as it would; one wrecked is said ("Panel wrecked").
4. **Your water or food runs out.** You wake with a quarter left ("Woke thirsty"). The Surveyor's one
   canister wakes you about 45 hours into a long storm.

**Waking.** A few lines at the top of the screen as it comes back from black, for 7 s, in the
caption's capitals: how long you slept, what woke you if it was early, each shield that was up, what
broke loose or blew away, what's wrecked. The world goes on as it now is: every ticking system's next tick
is on the new hour, none to catch up; the forecast reads from it and the eye settles, as for any cut;
the storm pass's map is drawn for it while the screen is still black, so none is drawn in a hitch; the
sky and the day are the clock's, and the plume works its streak out whole for the new hour on the
first frame, as for any jump; and a catch line's drift since you lay down comes in at once, as after
any jump. Nothing is saved mid-night, which is one frame
under the fade, and a save made on waking resumes as you woke.

**Probes** 16 to 20 (below). **Not yet:** a smart shield doesn't switch itself on asleep, since the
Console's radar doesn't sweep, so sleep with the shield on; what drifts never snags on a dune or a
ruin; a line's share of the wind is what it holds itself, so a deck on a line to a deck on a line to
a stake puts only the second deck's push on the last line. The dev overlay's `sleep/last` says how
long the last night was and what it cost. The **"sleep"** dev scenario stands you at dusk by a still
camp to try it: a deck of two resting on the sand, the bedroll and the base shield running on it, a
wall to windward on a frame and a radio on the weather station.

**After sleeping it** (Hunter, 2026-10-18): "we should be able to place the bedroll... allow them to
place it but you cant sleep until your camp is stable. and so right now cant you hack the game by
sleeping before a storm hits you?... it took me 3 sleeps and about 100 hours to sleep through that
storm":
- **The bedroll goes down anywhere;** only sleeping waits for a still camp, and it says what's
  moving. *Built (above).*
- **Sleep is no dodge:** the night already works the storm out on your camp; and asleep out in the
  open, with no bubble over you, a storm's arrival wakes you. *Built (above).*
- **A storm that runs for days** is the field's long tail, not an anomaly ([Wind &
  storms](wind-and-storms.md#the-anomaly-as-built-2026-10-18) for the anomaly, built 2026-10-18).
  *Built:* the run's first storm passes in five to twenty minutes ([the starting
  kit](#skeleton-version)), and no anomaly comes in a run's first five days; the tail itself is
  [Wind & storms](wind-and-storms.md#open-questions)'s question. A night slept through an anomaly
  lives its real damage on a plan made from the clean curve.

## Sleep (proposed)

*Hunter, 2026-10-17 ([session](../console-sensors-sleep-2026-10-17.md)). The 2026-10-18 spec agreed
it and it's built ([above](#sleep-as-built-2026-10-18)); kept for its readings and its problem's
numbers.*

**The problem.** "Storm days are about 20 minutes and storms can last several days; waiting one
out early game is boring. Storm-loot mechanics will help once they're in." In this game's numbers
most storms are short: the median is 17 minutes and 71% pass within a base shield's 30 ([Wind &
storms](wind-and-storms.md#open-questions)). The rest don't. A day is 20 minutes, so a storm of
several days is an hour or more of waiting. The longest ran past three hours, and the kit's own
first storm sat on the spawn for more than three and a half days on the probes' seed (the
starting kit, in the skeleton's list below). *Now (2026-10-18) the run's first storm is an ordinary
one, five to twenty minutes.*

**Sleep, not auto-walk.** "Sleep to fast-forward is the preferred fix over auto-walk, but not
settled." Auto-walk was then in no doc and no code; the 2026-10-18 spec put it first, and it's built
(above).

**The worry, and the proposal.** "Main worry: physics stability while time skips." The proposal
under discussion: "check camp stability with real physics before sleep, then only do resource
arithmetic overnight against a queryable storm-intensity curve (shield draw scales with storm
strength, so duration matters). Not agreed."

What the game already has, as readings and not in the session:
- **The curve is queryable.** `storm_at` is a pure function of place and time, so a camp that
  stays put has an intensity curve for the whole span ([Wind &
  storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built) answers it: yes, already).
- **Shield draw already goes by storm strength.** It sips 10 W in the clear and draws 200 W holding
  back a full storm, 2 W and 20 W for the light shield, and between the two in a lesser one
  (Bubble shield & camp). So the night's cost is that draw summed over the span: "duration
  matters" is built.
- **The arithmetic already runs on ticks of world time.** Power ticks every quarter second of
  world time, and your needs, the farm and the storm's wear ride the same tick. The dev time warp
  (x10 and x60) moves the clock fast, and the AFK probes run a camp for days that way (the "afk"
  scenario, Stage 12). The physics doesn't keep up. A physics tick is still a sixtieth of a
  second, so at x60 a second of world time moves bodies a sixtieth of a second's worth. A warped
  camp is tested against the wind's values and not their duration, which is the session's worry
  as it stands in the code.
- **A jump in time is not lived through.** The dev console's `time` command moves the clock on,
  and Power, your needs, the farm and wear all drop any gap over 60 seconds of world time:
  "nothing charged meanwhile," as `power.gd` puts it. So a sleep can't just move the clock. It has to run those ticks
  across the span (Power, open questions).
- **The night's worst wind is queryable too.** The wind is as pure a function as the storm, so
  "check camp stability" can test the camp against the worst gust the span will bring and not
  only the wind now. A gust is what tests a line, a hose (500 N) and a floating planter.
- **A sleeper needs a bubble.** Outside a shield a full storm and its wind kill you in five or six
  minutes (the three harms, in the skeleton's list below). A sleep through a storm is a sleep inside a running shield
  whose pool outlasts the span. If the pool ran dry mid-sleep, "the bubble collapses and the storm
  floods in."
- **Sleeping costs water and food.** Thirst empties in a day and hunger in two. The "afk" camp's
  three canisters were empty by four days. A sleep of days runs the same drain, and the same
  condenser, farm and sun, in its arithmetic.
- **Loaded ground doesn't change.** Finds are laid when a chunk loads, so a storm slept through
  uncovers nothing today. The storm-loot the session leans on is two full-version lines: "Storms
  wear dunes down" ([Wind & storms](wind-and-storms.md)) and "Things surfacing during a storm"
  ([Salvage & ruins](salvage-and-ruins.md)).

**Where and on what you sleep.**
- **Bedrolls,** "probably sharing the hoverboard's mount slot on a crate." *Settled by the chassis
  (2026-10-18):* the rack is gone with the crate, and a bedroll sticks anywhere on a deck it fits,
  beside the board or not ([Devices & mods](devices-and-mods.md#the-chassis-as-the-one-structure-built-2026-10-18)).
- **Ruin beds.** "Some ruins have beds" ([Salvage & ruins](salvage-and-ruins.md)).
- **Bare sand:** "Maybe sleep on bare sand if stable." Stable is the pre-sleep check above.
- **The patrol board's bedroll** (session 4, part 3; not built). The Daventry kit has a bedroll to
  "sleep out storms under the shield," on the board's own superchassis
  ([Movement](movement.md#the-patrol-board-a-superchassis-agreed-session-4-part-3-not-built)).
  That is the sleep proposal's sleeper in a bubble, with a strong shield "that can practically stay
  on permanently" and a compact high-capacity battery to outlast the span. The board carries it.

**A bed opens sleep options.** "Sleep X hours, sleep until a time, sleep through the storm. Gear
unlocks options; a radio adds some."

**Radio clocks.** "Second-era religious broadcasts still air at reliable times." (The endings
session, later the same day, repeats it from the Console doc: they "can serve as a sleep clock,"
and says why they keep time, below.) Readings: the
era is the second age, in which the faith of Tu dominates and whose daily rite is the
noon eclipse, "predicted to the second" ([the lore](../lore-research.md#the-faith-of-tu-and-the-ai-gods-agreed-session-4-part-2)).
A broadcast that airs at a fixed time of day is a clock that reads the real day, so it fits the
radio's rule that broadcasts read the real systems. It would be automatic, as the ghost relay is. The game has
no eclipse yet and no clock you can read: the sun shows the day, and in a storm only the radio's
music tells day from night, six to six. So a broadcast would give "sleep until a time" something
to name.

**Why they keep time (endings session, 2026-10-17).** Getting transmissions working is hard, and
second-age people kept an arcane understanding of the transmitters in which debugging is ritual,
"kept word for word." Radio priest is a role inside each god's cult, so a broadcast is a ritual
procedure run the same way each time ([the
lore](../lore-research.md#second-age-radio-and-its-priests-agreed-and-idea-endings-session)). The
reading is that a procedure kept word for word does not drift, which is why it airs at reliable
times. The session says only that they "still air at reliable times." Which god's broadcast serves
as the clock is open. The Ledger has the strongest signal, so its broadcast is the easiest to
find on any radio ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md#second-age-broadcasts-agreed-and-idea-endings-session-not-built)),
but whether the Ledger is still broadcasting when the player arrives is open too, and so is
whether a broadcast carries a voice or only tones and numbers. The daily rite, the noon eclipse, is
still the second age's own clock, and the radio's rule is that broadcasts read the real systems.

**Its links.** [Power](power.md): the shield's draw by storm strength is what a sleep sums, and
the sum has to be lived through. [Devices & mods](devices-and-mods.md): the deck a bedroll sticks on. [Salvage &
ruins](salvage-and-ruins.md): the beds. [Radio, sound & atmosphere](radio-sound-and-atmosphere.md)
and [the lore](../lore-research.md#the-faith-of-tu-and-the-ai-gods-agreed-session-4-part-2): the
broadcasts. [Wind & storms](wind-and-storms.md): the curve.

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
    that slows you further (at 90 kg, a third of it). The run's kit carries 5.9 kg, a
    canister, a ration and a bedroll (2026-10-18); every carryable thing of the kit, its stake, its
    board with the board's battery and the light panel too, comes to 23.9 kg, comfortably under.
    Probe 14 measured 1.80 m/s with the kit and 1.17 m/s at 59.9 kg, sunk 6.5 cm. Only
    what you carry counts, not what's in your hands. On a board you ride as ever.
  - **Stacks.** Like things stack as one: canisters, rations, batteries, stakes, hooks,
    coils of a length, cables of a kind. A device with anything fitted in it, a radio with
    its battery, is a thing of its own.
  - **Nothing fastened.** A device goes in whole, stuck on nothing, with nothing stuck on
    it, no plug in its ports and no line on its rings. So the board, the light panel and
    a shield generator go in once they're off the deck; a deck doesn't, being too heavy
    to carry. A shield carried running keeps its bubble round you as one in your
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
  your hands and uncoils as ever, its first end in your hand again. A cable or a hose
  plugged into nothing goes in the same way, as one piece; taken out, you hold a plug with
  the other plug and its cable following, as with a found one. A laid or tied line stays
  out until it's taken up, and so does one paying out or being let go at your waist, a
  cable plugged in at either end, a plug off any cable, and a strong cable that has
  snapped. Carried rope and wire lie rolled up as found ones do, as one body: the line or
  cable itself is gone until it's taken out, so nothing of it is left behind to go with
  the land as you travel. The coil keeps the line's length, so the kit's comes out 6 m, a
  found one 12 m and the half of a snapped line its own length, and a save keeps it too.
  The view shows a coil with its length (Rope coil, 6 m) and a carried cable as a cable.
- **The inventory shows things as they are, and gadgets work from it** (Hunter,
  2026-10-17: "display the rendered items, so if a player has a compass or gadget in their
  inventory, they can use it by just openening it and dont necesarily need to mount or
  hold it for it to be fully useful"). As built:
  - **Each thing or stack is a tile** with a picture of its own painted model, seen from a
    little above and to one side (a compass nearly straight on, to read), its name, the
    number that matters for all of the stack together (water, food, charge, a coil's
    length, a radio's frequency with its battery's charge) and, for a stack, how many. Tiles
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
    radio plays from you, its line of words showing as ever. What has no battery of its own
    since the chassis rework, a shield or a condenser, runs only on a deck or a cable, so
    carried it's dark.
  - **Use on a thing uses it where it is:** a device is worked (the radio's dial sweeps on),
    and water or food you drink or eat your fill of, the least full first, as the suit
    would. Anything else does nothing. Over a thing, use never reaches the world, so it
    can't switch what you happen to be looking at; off the tiles it works the world as
    ever. A click brings a radio to your hands still playing.
  - **Saves** keep everything you carry, each thing with its state, so stacks come back as
    they were, and a radio its dial, volume, beacon and charge. A save from before, with five
    slots, resumes with what was in them carried.
- **The compass** (2026-10-17): a small find, a part, whose needle points to the moon's
  north. Held, you read it in your hand; carried, in the inventory. The sun gives you the
  same without one: the moon has no tilt, so the sun rises due east and sets due west
  everywhere, stands to the south at noon north of the equator (north of you south of it,
  overhead on it), and morning shadows point west. A storm hides it; the compass doesn't
  care.
  - **Tu's field moves it** (agreed 2026-10-18, built but for the ground). Zan has no field of
    its own, only patches of old magnetism in its volcanic ground. The needle lines up with
    Tu's, which in Tu's equatorial plane runs along the axis Tu and Zan share, so it points
    north, but weakly: a few tenths of a microtesla at 12.7 Tu radii, a hundredth of Earth's or
    less. So it's slow to settle, sways about ten degrees either way once each time Tu turns
    (Tu's field is tipped from its spin like Jupiter's), and swims over old volcanic ground and
    in a storm's charged dust. It never shows Tu-ward: a needle can't know it, and the Console
    can. As built:
    - **Slow to settle.** The needle swings about the field once in about three seconds and
      settles by a damping of 0.4, so it overshoots and comes back; the liquid in its case
      drags it along as the case turns. Spin round half a turn and it's dragged nearly 60°
      off, swings back after a second and a half and settles within a degree in about six.
    - **The sway** follows Tu's turn as the sky draws it, from the one account
      (`DayCycle.tu_turn`): ten degrees east of north as Tu's tipped field swings one way and
      ten west as it swings back, once a turn, so about every three minutes at 9°.
    - **In a storm** the storm field where the compass is, not the weather you feel, swims it
      up to 35° in a full storm, wandering over a few seconds, the same in every run of a
      seed; a bubble doesn't stop it.
    - **Old volcanic ground** has its hook (`Compass.ground_deviation`) and turns it by nothing
      until the geology says where that ground lies.
    - The needle is worked in world time, so it pauses with the game and keeps up with the
      dev time warp. Unread for ten seconds or more, in the pouch, it comes out settled.
      Its numbers are tuning (`compass_swing_seconds`, `compass_damping`,
      `compass_sway_degrees`, `compass_storm_degrees`).
  As built before, and still:
  - **A 12 cm field compass,** 0.2 kg, company issue: a gunmetal case, a bone card under a
    black bezel, north marked on the card in safety yellow, and a needle whose red north
    half glows a little, so it reads at night and in a storm. Nothing takes it: it's read,
    not fitted.
  - **Held flat** (taken up from the sand), it points along the field on the ground. **Held up**
    (out of the inventory, it comes to your hands facing you) it reads as if laid level
    with its top away from you: north ahead is straight up the card, north on your right
    is to the right. Carried, the inventory shows it the same way, turning as you turn.
  - **Past a pole.** Walking over a pole turns the moon's north round (the moon position
    keeps which way it lies), and the compass follows that, not the world's fixed axes: it
    always points the way that takes you toward the north pole. The radio's spoken
    bearings follow the same north, so the two never disagree. The sun doesn't yet: the
    day is one clock for the whole moon, so past a pole the sun keeps the course it had,
    rising in the compass's west. Turning it round there would make it jump at the pole.
  - **Found** on the surface, one in twenty-one of the surface layer's loose parts (99 of the
    4,675 finds salvage probe 5 tallies over two seeds, about one in 47),
    and the console's `give compass` puts one in your hands.
- **The suit** is what it carries plus its built-ins: air and radiation protection, free
  and drained by nothing. Its sockets for mods (heater, cooler, reclaimer, battery,
  harness hooks) wait for the full version, so in the skeleton the suit isn't a device yet.
- **Sealed water and food.** A canister holds 2 L and a ration 1,000 kcal, found sealed and
  full. Like a battery, a canister carries what's in it and its light shows how full it
  is. A ration eaten to the end is gone; an empty canister stays, to be filled again.
  Every run starts carrying one canister and one ration, and the Surveyor's and the
  Homesteader's a bedroll ([Sleep](#sleep-as-built-2026-10-18)). Sealed water is found
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
  holds through most of a storm and lets go in its worst. Rolled up it goes in with what
  you carry like a cable, shown as a Hose, hoses stacking, and stays out while an end is
  in a socket, and so does a carried device with a hose's end in it. A save keeps hoses,
  what's on their ends and the water in tanks (saves probe 11). It's found on open sand,
  a little less often than wire, and `give hose` makes one.
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
- **The eclipse cools the air** (2026-10-17, [the Tu spec](../tu-and-day-2026-10-17.md)).
  The temperature follows local time, which follows longitude, and on the near side it
  dips while the sun is behind Tu: deeper the longer the sun has been hidden and the
  higher it stood, so a wider Tu's longer eclipse dips further, and a storm's blanket
  softens it as it does the day's swing. It's a few degrees, never near the
  suit's limits; it also nudges the condenser and the crops, which read the same felt
  temperature.
- **The crude condenser** is a catalog device with a water tap and a port, too tall to stand
  under a frame. It stands on a deck and runs on the deck's pool, whenever there's power and
  somewhere for its water, a canister with room or a hose (above), drawing 40 W, and makes 10 L an hour of world time in
  air at 0 °C or colder, falling to a fifth of that at 40 °C, by the felt temperature
  where it stands. At the equator in the clear that's about 2 L a day. You drink about
  1.8 L a day there, less under a storm's blanket, so one condenser just keeps you, if it keeps its power and stays
  inside the bubble when a storm comes.
- **How long sealed water lasts:** a full canister and a full thirst bar see you through
  about two days at the equator. Each more canister is about another day.
- **Death starts a new run.** The world goes with everything in it, and a fresh one on a
  new seed takes its place. You start at its spawn, fed and watered, carrying the
  canister, the ration and the bedroll.
- **The starting kit** (Hunter, 2026-10-16, after playing the first one: "start the
  player with floating crate, shield and hoverboard already mounted ... we should at
  least add a hook so we can tow it"; reworked round the chassis, 2026-10-18, from [the
  chassis spec](../chassis-kits-dunes-2026-10-18.md)). The kit is data,
  `game/survival/standard_kit.tres` (a `Kit`: what the suit carries, what's set down beside you
  and where, what comes put together, a deck as its rig's steps ([Devices &
  mods](devices-and-mods.md#the-chassis-as-the-one-structure-built-2026-10-18)), which lines are
  laid, how full its batteries start and how long its line is). It's the Surveyor's, the default
  origin's; the Salvager and the Homesteader have kits of their own, chosen at New game ([Profile &
  saves](profile-and-saves.md#kits-are-data)), each beginning at its own start on the moon.
  (Session 4, part 2 lists the Surveyor's standard shield, multi-compass, stake tether and radio
  against the kit below: the clash is recorded in [the vision](../vision.md#player-origins-and-kits),
  and this kit is what's built.) Every run, the first and every one after a death, begins on a
  clear morning with the sun well up, a third of the way through the day, so the panel makes about
  half its 30 W from the first minute, and the first storm due in three to eight
  minutes, facing where it will come from (Hunter, 2026-10-16: "it spawns me in a
  storm!"). That storm is an ordinary one, passing in five to twenty minutes, a quarter
  of a day to a day (Hunter, 2026-10-18: "it took me 3 sleeps and about 100 hours to sleep
  through that storm"): the start looks on through the mornings for one, so the run's
  clock may begin days in, and with none in reach it takes the first storm that comes.
  The run's days count from its own start, kept in its save, so it begins on day 1
  wherever a day is shown (Resume, the Console's clock).
  On ninety starts (thirty worlds, each origin) the first storm ran 5 to 20 minutes, the
  median 14, the clock beginning on day 10 at the median and day 122 at the latest;
  before, a third ran past a day, the longest 92 minutes, and the clock began by day 24.
  The run starts with it: carrying the canister, the ration and a bedroll, and beside
  you, once the ground there is solid, a camp you learn the whole system from by sight:
  - **a floating deck** of two pieces at your front right, a hover tray under each, set
    toward its back so the deck hangs within about 2° of level. On the near piece, on its
    top: a **battery** half charged, the **light shield generator**, switched off, and the
    **light solar panel**, all one pool. On the far piece a **frame** stands, an **upright**
    on its side facing you, the **hoverboard** hung across the upright with its battery half
    charged, and a **compass** stuck beside it. A hook sits on the near piece's outer ring.
  - **moored to a stake** driven upwind of it, by the hook, on the kit's **6 m line**
    (a found coil lays 12 m). Floating, nothing holds a deck but its lines. To travel, take
    up the stake and tie it at your waist, and the deck follows on its line with its bubble
    (survival probe 8); to camp, drive the stake again.
  - The board comes off the upright to the ride action, which steps you on; take lifts it
    off into your hands.
  None of what's stuck on the deck goes in with what you carry while it's stuck there, nor the
  deck, too heavy to carry; the board, the light panel, the light shield and the compass do
  once they're off it.
  The light shield is clearly weaker than a found one: a 4 m bubble against 7 m (a third
  of the room for a camp), and it lets 15% of the wind through where a found one stills
  it (Hunter, 2026-10-16: blocks most of the wind, so you barely drift inside). It sips
  2 W in the clear and draws 20 W holding back a full storm. The deck weighs 68 kg, against the
  old crate's 45.5, so its trays draw about 136 W floating it, and the board charges from the
  deck at up to 50 W, far more than the 30 W panel can keep up with: the deck floats on what its
  battery holds, and the shield ranks above both, so neither the trays nor the board ever takes
  the battery's last quarter (Power). On the probes' seed, from the run's own first morning, the
  trays gave way and the deck settled onto the sand 0.43 days in (the crate's had at 0.55), and
  the light shield ran on through the day. The rest of the old crate's day (the panel bringing
  it back to floating, the shield's 75 minutes of storm in the last quarter) isn't yet
  re-measured on the deck. The kits are due a rework of their own; balance targets the Surveyor.
  A dev scenario that drops its own camp clears the run's kit first.
  Survival probe 4 checks both runs start with it and runs the light shield into the
  second morning.
- **Food and water from salvage:** no new food was needed. Survival kits, common on
  ruins' floors and sometimes on open sand, hold a sealed canister and a ration three
  times in four, and seeds for a planter; loose rations and seeds lie on ruins' floors.
- **The playtest scenario** ("survive a few days", among the dev scenarios) starts you over at a
  clear dawn, with a deck of two resting on the sand in front of you: a condenser with an empty
  canister in its tap and a solar panel on one piece, a charged shield generator and two
  batteries on the other, all one pool; and two spare rations. A simulated run of it with the
  old slot camp, on the probes' seed: standing in the open, a storm killed you on day two; with
  the shield alone, a long storm drained it on day three; with the shield and the condenser in
  one pool, and canisters swapped as they ran dry, you were alive after three days with a quarter
  of the power left. Not yet re-measured on the deck.
- **The AFK promise, with a body** (Stage 12, 2026-10-17). The "afk" scenario stocks you
  as you'd leave yourself: three canisters of water and nothing to eat; the farm drops
  your food onto you. Idle in the reference camp (Power) at the equator for three
  days of the probes' seed, about two of them storm, you come through untouched: the
  bubble keeps every harm off you, the farm's drops are all you eat, 2,400 kcal, and you
  drink about 1.7 L a day. Take the farm away and you starve at 2.83 days (probe 1).
  Rebuilt on its floating deck (Power), the camp gives the same three days to the gram.
- **Water is where AFK ends.** Nothing brings you water yet: you drink only from what you
  carry. The camp's condenser waters only the farm, down its hoses, and a canister it
  fills still has to come to you by hand. So the camp keeps you as long as the water you
  carry: left on, the three canisters were empty by four days and you died of thirst at
  4.78, fed, with food stored and the shield up, while the farm's tanks stayed above 3 L
  (Farming).

## Full version

- **Suit mods:** heater, cooler, water reclaimer, harness hooks.
- **The water rhythm:** frost and dew, and open water that freezes and boils off.
- **Water-storing plants.**
- **Farm automation that delivers to you** (Farming).
- **Needs you can read without bars:** breathing, vision, sound, suit readouts.
- **Radiation as a harm** (an idea for later), maybe combined with storm and heat
  damage. For now the suit handles it. Session 4, part 4 gives every crop a radiation tolerance
  ([Farming](farming.md#the-stat-axes-agreed)), which needs a radiation to read: another reason to
  decide this one.

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
   and walk off: the deck follows on its line, floating all the way, its shield's
   bubble with it.
9. **The board on a deck.** The kit's board, stuck on its deck, rides with the deck as it's
   towed and charges from the camp until the pool is down to the shield's reserve, takes
   nothing past it, and charges again once the panel brings the pool back, every watt-hour of
   it accounted for; the ride action takes it off and steps you on, and saved on the deck it
   resumes there.
10. **Stakes go in.** A found stake and a loose one, each taken up, go in and come out
    ready to drive; driven, each holds a floating piece on a line in a breeze,
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
    the moon's north, in your hand and in the inventory. Tu's sway, a storm's swim and the
    needle's slow swing are tuned out for it.
14. **Weight is the only limit.** Whatever you can carry goes in, a board, a light panel,
    a survival kit and a stake among them, and ten batteries stack as one. With the kit's
    load you walk at your full pace, standing tall; with twice what you carry easily you
    sink in and walk slower by the share the inventory shows, and it says you're
    encumbered and by how much.
15. **Tu's field moves the compass** (2026-10-18). Lying flat and still in clear air through
    one turn of Tu, its needle sways with the turn, ten degrees east of north and ten west,
    never further. Spun half round in half a second it's dragged along, swings back after
    more than a second, not snapping, and settles within a degree inside ten.
16. **A night slept comes out as lived.** The reference camp lives a day and a night of the probes'
    seed, a storm through it, at the time warp's fastest, and sleeps the same: its batteries, its
    shield's pool and whether the shield held agree within 1% of all it stores.
17. **Only a still camp sleeps.** Under a running shield in a full storm with a deck floating beside
    you, you can; with the deck swinging, or set swinging as the screen goes dark, or out in the
    storm, you can't, it says what moved, and no night passes. The bedroll goes down all the same:
    with the deck swinging, use in your hands lays it on the sand, and use on it says "the deck's
    still moving".
18. **A line gives at the storm's peak.** Asleep under a shield with a storm coming on, two decks on
    the sand past its bubble on lines to stakes: the one made stronger than the night's peak load
    holds its deck where it was, the weaker gives and its deck is gone where the wind took it, and
    waking says so.
19. **Waking jumps cleanly.** Eight hours asleep, you wake eight hours on: every ticking system stands
    on the new hour, the forecast reads from it, no storm map is drawn in a hitch after, and a save
    made on waking resumes as you woke.
20. **Sleep is no dodge** (2026-10-18). Asleep in the open on the probes' seed, no bubble over you, a
    storm due in the morning: its arrival wakes you, the night lived up to it, and waking says the storm
    woke you.

## Out of scope

- Disease, injuries to specific body parts, and sleep as a need. *(Sleep to wait out a storm is
  built, above; it adds no bar and restores nothing time and the shield don't.)*

## Open questions

- **Why is the scavenger out here?** The game reveals it over time. We don't need the
  answer yet. *Narrowed by session 4, part 2:* each origin has its own reason, and the default
  is a Tilg & Standard contractor ([the vision](../vision.md#player-origins-and-kits)).
- **A size cap for big but light things?** Weight is the only limit, so a 1.3 m board or
  a light panel goes in as easily as a battery of the same weight (Hunter, 2026-10-17:
  still open). Not built.

The sleep proposal (2026-10-17) raised these; the 2026-10-18 spec agreed it, and what's built
answers most ([Sleep, as built](#sleep-as-built-2026-10-18)). Each is quoted on both sides, with what
was built.

- **The sleep simulation approach.** Open in the session. Here: the arithmetic runs on ticks of
  world time, and under the dev time warp the physics still steps a sixtieth of a second a tick
  while the clock runs on. The session: "check camp
  stability with real physics before sleep, then only do resource arithmetic overnight." Not
  said: what "stable" means in the check (lines holding, nothing loose, the shield's pool
  outlasting the span), how long the real physics runs before the skip, or whether the physics
  runs again for the last stretch before you wake. How the arithmetic is run is Power's question.
  *Built:* stable is you and the camp still and no harm reaching you, read as the physics runs and
  watched over the half-second fade; each system's own tick, in 10 s steps; the physics never runs
  for the night, and the world goes on from it as it stands.
- **Sleep against "Out of scope... sleep."** Here: "Disease, injuries to specific body parts,
  and sleep," and the needs are health, hunger, thirst and stamina, with no sleep bar. The
  session: sleep as a way to fast-forward, "preferred... over auto-walk." Not said: whether the
  line means sleep as a need, which the proposal doesn't add, or sleep at all. Also not said:
  whether sleeping restores anything past what rest and time in the shield already do.
  *Built:* no need bar; the line now reads "sleep as a need," and sleeping restores only what time
  does (healing, unharmed, fed and watered).
- **Sleep against "The game never pauses."** Here (Menus & UI, rule 2 and probe 1): "world time,
  weather and physics advance exactly as they do" with a menu open. A sleep isn't a pause, but
  it skips a stretch the physics never lives through, which that rule was written to keep out of
  menus. Not said whether the rule is about menus only. *The spec:* sleep is "needed despite the
  no-pause philosophy." The words don't pause; the night is a jump the physics doesn't live.
- **What wakes you.** The session: "sleep through the storm." Here: a shield whose pool runs dry
  collapses, and the storm floods in; thirst empties in a day. Not said whether a bed refuses a
  sleep the camp can't last, warns, or wakes you early when the pool nears the shield's reserve
  or a need runs low. *Built:* it never refuses for the span; harm wakes you (the bubble going),
  and so does thirst or hunger at a quarter with nothing left.
- **Where each start sleeps.** Here: the Surveyor starts with the board hung on its deck's
  upright, the Salvager has "Hoverboard and the light shield; little else", and oysters "never
  find ruins" (the vision's playstyles). The session: bedrolls share the rack, and some ruins have
  beds. Not said where a hover punk keeps a bedroll. An oyster never sees a ruin bed. *Built:* the
  rack is gone with the crate, and a bedroll sticks on a deck beside the board as anything does;
  the Surveyor and the Homesteader carry one, and the Salvager has none and finds one, or a ruin's
  bed.
- **How you name a time.** The session: "sleep until a time." Here the game has no clock you can
  read: the sun by day, and in a storm the radio's music, day or night. Not said what a time is
  made of: hours, dawn and dusk, or a broadcast. *Built:* hours, the four moments of the local day
  (morning, noon, dusk, night), the storm passing, and the weather station's call.
- **The broadcasts and the era.** The session: "second-era religious broadcasts." Read here as
  the second age. In session 3's six eras the second is the war, and in session 4, part 4's numbered
  list it is the skimmer era. Not said which is meant (the endings session later writes
  "second-age"). The
  voice question is in [Radio, sound & atmosphere](radio-sound-and-atmosphere.md#open-questions).
- **Which broadcast is the clock.** The endings session (2026-10-17): second-age broadcasts "still
  air at reliable times and can serve as a sleep clock." Not said which god's broadcast, whether the Ledger is still on the air, or whether a clock has to be a
  voice and not tones and numbers ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md#open-questions)).
  *Narrowed:* the weather station's call is built as the radio's wake; a fixed-hour broadcast isn't.
- **A bubble on a board for sleeping.** Session 4, part 3: the patrol board's bedroll is there to
  "sleep out storms under the shield." Here: a sleep through a storm is a sleep inside a
  running shield whose pool outlasts the span, and the sleep session wants the camp checked for
  stability first. Not said what "stable" means for a board, which has no camp. *Still open:* the
  patrol board isn't built.
