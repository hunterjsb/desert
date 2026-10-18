# PRD: Power

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Power turns the stuff you haul into stuff that works. It keeps the shield up, the camp
floating and the hoverboard ready to run. It's also what the first pillar means in
practice: **steady state is a power budget that balances** through day, night and storm.
A camp that generates more than it draws, and stores enough to cover the gaps, is a
camp you can walk away from.

**In the world.** The colony bought its power gear, like everything else. Solar comes from a big
commodity maker: everywhere, cheap and useless in storms, which is why it's the common starting
power. Wind comes from a different maker: planted gear that's strong in storms and ties you
down. Batteries are anonymous commodity infrastructure, like screws or rope, and carry no
maker's mark. See [the lore research](../lore-research.md).

## What the player experiences

- **Every device has its own battery,** and you can see its charge on the device itself.
  There's no menu.
- **You start with a light solar panel** that you can set down and pick back up. Out of
  the storm, you sit for a moment and recharge the shield, or the hoverboard once
  you've found one.
- **The rudimentary setup** wires a source straight into a device: a solar panel into the
  shield. It works while the sun shines.
- **Then batteries.** You charge them at a source and swap them by hand. Carrying a fresh
  battery to the shield in the middle of a storm is a scene. A charged battery in your
  hand is stored power.
- **Late game, a central capacitor** feeds the camp, and you stop swapping by hand.
  It isn't one item. It's an arrangement of batteries and wires you build, so its size
  and shape are up to you. That's where steady state lives.
- **Swapping is physical.** You pull the battery out and put another one in, and it
  passes through your hand slot like anything else.

## Modular, like everything else

The battery slot is a mod socket, the same idea as rope hooks and hover trays. A better
battery is an upgrade you fit. The socket system itself belongs to the Devices & mods
PRD; this PRD owns what flows through the battery slot.

## Sources

| Source | Strong when | Weak when | The catch |
|---|---|---|---|
| **Solar** | Clear skies, daytime, toward the poles | Storms (some types keep a little), night | None, beyond the weather |
| **Wind** | Storms, toward the stormy equator | Calm | It has to be planted to work, so you stay or leave it behind |
| **Heavy generator** | Always: strong and steady | Out of fuel | It rides on caterpillar tracks, slows the camp, and burns fuel |
| **Burner** (proposed, session 4, part 4) | Night and storm, when solar can't help: it runs on stored fuel | Out of fuel | Its fuel is coalcane, which needs water and a day's light to grow ([below](#fuel-crops-and-the-burner-proposed-not-built)) |

**Solar comes in forms that trade portability for output:**
- **Light:** placeable and picked back up. This is the starting source.
- **Tracked:** heavier and stronger.
- **Mounted:** fitted on top of a device, like a hover planter. Its weight raises that
  device's hover draw.

**Fuel is rare, and it's mostly found:**
- **Rare consumable fuels.**
- **Fissile material,** if you're lucky, and something that can burn it, if you're
  luckier.
- **Fuel grown from plants,** at various grades of usefulness, which ties power to
  farming.

**Turbines have to brave the storm.** Because the bubble edits the weather (Bubble
shield PRD), a turbine inside a wind shield feels no wind and makes nothing. It has to
stand outside, in the storm, and take the damage. The alternative is a shield that
lets wind through, like the late-game temperature shield. That trade-off comes free from
the felt-weather rule.

## Fuel crops and the burner (proposed, not built)

*[Session 4, part 4](../plants-worldgen-ruins-2026-10-17.md); implied equipment, direction only, with no
number set. It is the fuel half of "Fuel grown from plants" above.*

**Coalcane is the only renewable fuel crop** ([Farming](farming.md#each-crop-ancestor-engineering-drift-and-hooks-agreed)):
"a night/storm counterpart to solar, burned in a **new burner device**." The stalk stores oils and
resins, not sugar, and "trades water for power." Old petrified groves are "a big one-time fuel haul"
and a sign of ancient water. The session lists the new equipment as a "burner/generator (for coalcane
fuel)" and a humidifier, "both crate parts like the existing devices" ([Devices &
mods](devices-and-mods.md#the-burner-and-the-humidifier-proposed-not-built)).

Readings, not in the session:
- **It makes "fuel grown from plants" concrete.** The cane grows on a day's light and the planter's
  water, is cut, and is burned when the sun is not there. Rule 1 holds if the burner's output
  is the stalk's energy and no more: the sun's share is stored in the stalk, and the water it took came
  from the condenser's power or a canister. The session gives no energy per stalk, and no water per
  stalk, so whether the loop pays (the condenser's draw against the burner's output) is a number to set,
  and probe 1 is the check.
- **The burner is a source with a store.** It reads no weather, so a storm and a night do not matter
  to it, and it draws on stock, the way a battery does. Its fuel is carried or fed, and not wired.
- **The heavy generator may be the same machine.** The table's "heavy generator" burns fuel and rides
  on tracks, and the session's burner is a "crate part." They are read as two devices, a big tracked
  one and a small fitted one, which the session does not say (open questions).
- **The humidifier and the lamp are loads.** The humidifier raises humidity for the storm family and
  the lamp lights the office fern. Both draw from the pool like any device ("Instruments, farming gear
  and tools draw small amounts"). Neither draw is set.
- **Quietbloom is a load that gives nothing back.** It "grows by eating your power," draining a
  battery or a radio slowly. Rule 1 needs the drained energy to go somewhere: into the plant's growth, as
  stored value, and not vanish. How it is metered, and whether it takes from any device nearby or from
  one it grows toward, is not said.
- **A wind surge is a back-burner idea.** "Turbines spike; charge batteries hard" in a storm
  ([Wind & storms](wind-and-storms.md#storm-only-mechanics-back-burner)). The turbine here makes up
  to 200 W in a gale, so a surge would be a term above that.

## The kiln and its fuel (Agreed, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), section 5; direction only, with no number set.
[Devices & mods](devices-and-mods.md#the-kiln-agreed-session-4-part-5-not-built) has the kiln itself.*
"The kiln is a new processing device that burns coalcane," in three era variants: the colonial **electric
furnace** ("most efficient; runs on power, not coalcane"), the First Kingdoms' **brass-fitted forge**
(middle efficiency) and the second age's **beehive clay kiln** (lossy). A variant's job is the same, and its
"efficiency and fuel draw" differ.

Readings, not in the session:
- **Coalcane has more mouths.** The burner turns it to power, the kiln to heat, and the Stoker eats it
  ("feeding... calms it"; [the lore](../lore-research.md#the-stoker-and-the-end-of-zan-agreed-session-4-part-5)).
  Cane is thirsty and rare, and the session sets no figure for a stalk's energy or its water, so whether
  a farm can feed all three is a number to set (the burner's own loop is unset already).
- **The kiln's heat is not power.** A stalk burned in the kiln gives ceramic, salt or safe water and no
  watts; the same stalk in the burner gives watts. They are two devices that want one crop, and the game
  has no heat model to join them.
- **The electric furnace is a load, like any device.** It draws from the pool while it works, so rule 1
  holds with its draw counted. The session gives no draw.
- **A requisition is a drain.** The Quartermaster module "requisitions a cut of your camp power." Energy
  taken has to go somewhere (rule 1); the session does not say where, or what share.
- **"Restored vent taps" read as the colonial vent power stations** along the rift (part 4's generated
  pieces), which feed the Stoker. Whether a restored tap can also power a camp is not said.

## What draws power

- **Shields,** by type. A full base shield lasts about 30 minutes in a storm. The main
  way to save power is to switch it off and stay out of storms.
- **Hover trays** keep camp pieces floating, each lifting under its own spot
  (Devices & mods, 2026-10-17), and their draw rises with the weight they
  carry, mounts included. Without enough power, you haul. Use sets a tray resting,
  drawing nothing, for a camp that's staying put (Devices & mods).
- **The hoverboard** has its own battery. That's your escape when the shield dies.
- **Instruments, farming gear and tools** draw small amounts.

## Rules

1. **Energy is conserved.** Every battery has a charge, every device a draw that depends
   on what it's doing, and every source an output. The numbers always add up.
2. **Sources read the felt weather.** Solar reads light (storm, time of day, latitude).
   Wind reads the felt wind at the turbine.
3. **Power ticks at a fixed rate,** independent of frame rate, as cheap arithmetic.
4. **Charge is shown on the device.**
5. **Power lives in devices, and devices belong to the camp.** Like everything else,
   whatever you leave behind is forgotten.

## Skeleton version

- Batteries as items with a charge and a capacity. Every powered device has one
  battery slot.
- The light solar panel (place it, pick it up) and one crude wind turbine, each reading
  the felt weather. A source can be wired straight into a device or into a charger.
- A day-night cycle of about 20 minutes driving solar output.
- Swapping batteries by hand.
- The shield, the test floater and the hoverboard all draw from their batteries.
- A simple charge light on every device.
- A fixed-rate power tick.
- The probes below, all passing.

**As built (2026-10-14):**
- **The light solar panel is the panel part.** Carry it and fit it on any device's top
  mount; it powers that device. A small **charger** frame (a top mount and a battery
  slot) is how you charge a loose battery in the sun.
- **The starting light panel** (2026-10-16) is a small device of its own: a 30 W panel,
  half a found one, built into a flat frame with a port, 5 kg, that you carry, set down,
  pick back up or seat on a top mount. It's half a crate's top, like a found panel, so
  it rides beside a shield. Lying flat, the wind meets its edge, so a breeze doesn't
  skate it off. Every run starts with it seated on the kit's floating crate beside the
  light shield (Survival).
- **The starting power margin** (2026-10-16): over a clear equator day the light panel
  makes about 3.2 Wh against the light shield's 0.7, and on the probes' seed a day a
  quarter stormy made 3.0 Wh against 2.1, so the battery ends the day a little fuller.
  A day of full storm costs about 6 Wh net. Against the base shield it would fall short:
  even a 60 W panel makes about 6.4 Wh a clear day against the base shield's 3.3, and a
  full storm drains 100 Wh in 30 minutes, so "sit for a moment and recharge the shield"
  would want about 1 kW of panel for the base shield.
- **Two battery slots on one device** share its pool like any two batteries; its charge
  light shows them together.
- **Cables are two plugs on 6 m of wire.** Each plug snaps into a port socket like any
  part, so wiring is the same act as fitting. Pull a cable too far and a loose plug is
  dragged along; with both ends held fast, a plug pops out.
- **Cabled devices share one pool.** What they make feeds what they draw, then fills
  their batteries, and any surplus is spilled. A pool that can't meet its draw goes
  dark, so a crate's tray stops and it settles to the sand. A dark pool runs nothing
  and lets its sources recharge it, and restarts once its batteries hold 5%.
- **The shield comes first** (2026-10-16, pulled forward from the full version for
  the floating kit crate). Every device has a rank, and a shield ranks above everything
  else. When a pool runs short, a device that ranks below the highest in it stops
  drawing once the pool's batteries are down to a quarter, which is kept for the higher
  ranks, unless its sources alone carry everything; it starts again once they hold
  30%. So a crate's tray lets the crate settle onto the sand and leaves the last quarter
  to the shield seated on it, and a condenser cabled to a shield stops at a quarter the
  same way. A pool with nothing ranked above the rest runs down as before.
- **Trays draw for what they hold up** (2026-10-17): 2 W for each kilogram a tray pushes
  up, so at rest a device's trays together draw 2 W a kilogram of it, as a single tray
  always did (91 W for the kit's crate). A deck tipped onto the sand draws less, the sand
  carrying a share, and a line pulling down draws more. A tray that's stopped asks for
  the whole weight, what lifting it again would take, so the quarter's stop and the 30%
  restart work as before.
- **The tick reads each source at its own world time**, four times a second of world
  time, so the dev time warp charges faster and 30, 60 or 120 frames a second give the same charge to
  the bit.
- **The turbine** makes up to 200 W in a gale and nothing while it's being moved.
- **The hoverboard** (Stage 10) draws 40 W floating and up to 260 W more at full push,
  so a base battery lasts about twenty minutes flat out. What it draws is metered tick
  by tick in world time and read by each power tick for its own quarter second, so its
  charge comes out the same at 30, 60 or 120 ticks a second.
- **A racked board charges from the camp** (2026-10-16). Its battery stays its own,
  out of the crate's pool, and it draws up to 50 W to charge it, a base battery in two
  hours. That draw ranks below the shield, so it stops with the crate's tray once the
  pool is down to a quarter and starts again at 30%, and it never takes the shield's
  last quarter. What it draws is stored in its battery, not used, so the ledger still
  adds up. On the starting kit the light panel is the only source, so it's a trickle,
  and the board's weight adds 22 W to the tray's draw: on the probes' seed, from 10 Wh
  over the reserve, the board took 4.2 Wh in five minutes before the pool was down to a
  quarter, and charged again 2.3 days in, once the panel had brought the pool to 30%.
  Every run starts with it racked, so on its first day the kit's crate settles at 0.56
  days instead of 1.00 (Survival).
- **Two kinds of cable** (decided 2026-10-14, from the Stage 4 playtest). **Common
  wiring** pops a plug when pulled too hard, and Hunter likes that: a floating planter
  blown off a turbine unplugs itself. A **strong cable** is also a rope, so it holds
  what it's plugged into and powers it. It never pops; too much load snaps it at
  4,000 N. While you hold one of its plugs, the rope pulls on you, not on the plug in
  your grip. A loose plug on either kind is dragged along by what drifts off with
  the other end, never slung, however long it was caught.
- **The reference camp** (Stage 12, 2026-10-17) is what probe 4 leaves alone. The "afk"
  dev scenario parks it round you, running, on a deck two pieces by two (Hunter,
  2026-10-17: "add a 2x2 pimped out chassis to afk scenario"), a tray under every piece and
  a hook on every free ring, floating about a metre up. Standing on it, their own trays
  off: the base shield on a big battery and a condenser on a battery and a panel, on the
  upwind pieces; the crate, with two big batteries, the light panel and a found panel;
  and a second crate with two more big batteries, a found panel and a lamp. All of it is
  one pool, and a strong cable from the crate's port holds the turbine out in the wind
  beyond the bubble, its battery in the pool too: a 1,700 Wh bank and 210 W of panels.
  The deck is moored to a stake upwind of it. Two harvester planters float upwind of it
  on their own trays and batteries, on hoses from the condenser (Survival), each moored
  to a stake of its own. Floating, the deck draws about 370 W, its 185 kg at 2 W a
  kilogram, more than all the rest together. At 45° north, through two days and nights
  of the probes' seed, 24 minutes of them full storm, nothing in it went dark and its bank
  fell to 84% (it never fell below 98% when the camp sat on the sand, its trays resting,
  before the deck). At the equator the deck floated for 7.4 days, nearly six of them
  storm, until the bank was down to its reserve and the deck gave way to the shield,
  settling on the sand; the planters' own batteries ran out about the sixth day, and
  they settled too, still growing. The kit's power under a found shield (the light panel
  and a battery half charged) went dark in the same weather at 1.34 days.
- **What the camp costs** (2026-10-18, from Hunter feeling it lag). Running, the
  reference camp cost the main thread about 7 ms a tick over the world without it, and
  its slowest tick each second 7 to 9 ms more. Most of it was the hard floor under loose
  bodies reading the sand under all eight corners of each of the deck's 60-odd shapes;
  then ropes reading the sand under their links every frame, and devices walking all
  their children for their sockets and their face to the wind. Now the floor passes over
  a device or a shape clear of the highest sand under it, ropes keep what they read
  through points that haven't moved, and devices keep what they work out from their
  children until those change: about 1.5 ms a tick, and 4 ms on the slowest, headless
  on the desktop. The camp comes out the same to the bit. What's left is mostly the ropes
  and the power tick, four times a second. Probe 11 holds it.
- **Holding a turbine out from a deck is tight.** A strong cable is 6 m and the base
  shield's bubble 7 m, so a turbine on a cable from a deck under it stands only just
  outside. On the 2x2 deck the shield stands on the piece across from the crate, as far
  from its port as the deck allows, and the turbine stands 7.6 to 7.9 m from the shield.
  A wind that swings round toward the shield's side can bring it inside, where it makes
  nothing. A floating deck on a strong cable to a turbine on the sand also creeps toward
  it, drawn by the cable's weight, about 0.3 m a day until its mooring is taut, so the
  scenario moors it nearly taut.
- **A turbine has to be held out there.** Nothing plants one yet (the probes freeze
  theirs), and standing loose, a storm slides it over the sand, making nothing while it
  moves: in a first try at the camp it slid 33 m in the first storm, until its cable
  popped. On a strong cable from the moored crate, through three minutes of full storm
  in real time, it made power 99% of the time and drifted 1.4 m.
- **The storm wears the turbine out.** About half an hour of full storm wrecks it, and
  nothing mends it: on the probes' seed it goes on the third day (2.45 days in at the
  equator, 2.67 at 45°), having made about 90 Wh for the camp, less than a battery
  holds. That's why probe 4 runs two days. A wrecked device leaves its pool, and its
  battery's charge with it. After that the bank carries the camp alone: the camp on the
  sand, before the deck, was down to 63% after eight days at the equator, nearly six of
  them storm, where the floating deck reached its reserve at 7.4 days (above).
- **Panels hardly count against a storm.** Over probe 4's two days the camp's panels
  made about 5 Wh, and it passes with them broken (the camp on the sand, before the
  deck). A day of storm costs the base shield
  about 67 Wh, which 90 W of panels earn back in about eleven clear days at the equator.
- **The turbine's blades turn with what it makes** (2026-10-17). A real rotor turns with
  the wind and makes power with the wind cubed, so its speed goes with the cube root of
  its share of the 200 W: slow in a breeze, under a turn a second in the prevailing
  10 m/s, and two a second at its rating, still two blades and not a blur. It eases up
  and runs down over a few seconds, stands still while the turbine makes nothing
  (wrecked, moving, in a bubble or a calm), and swings round on its mast to face into
  the wind. It's only drawn: it reads what the power tick worked out and touches nothing.
- **The eclipse is a power check** (2026-10-17, [the Tu spec](../tu-and-day-2026-10-17.md)).
  Once a day on the near side the sun goes behind Tu, and solar reads the light it feels, so
  it falls to nothing for the eclipse: 16, 26 or 40 seconds of totality at the three sizes
  under trial, 6°, 9° and 13° ([the moon](../the-moon.md#day-length)), with a few seconds of
  partial phase either side. A camp rides it out on storage or wind. Tu's own light at night is far too
  weak for panels, so they make nothing by it. Solar also follows local time now, which
  follows longitude, so a panel carried east sees an earlier sunset.

## Full version

- **Battery tiers,** chargers, wires, and central capacitors built from them.
- **Tracked and mounted solar.**
- **Priorities beyond the shield's.** When the capacitor runs low, the shield is the
  last thing to lose power (begun in the skeleton: two ranks, one reserve).
- **The heavy generator** on caterpillar tracks, with fuels: rare consumables,
  fissile material with something to burn it, and fuel grown from plants.
- **Draw by state:** idle, active, holding back a storm.
- **More sources,** still to be designed.

## Probes

1. **Energy adds up.** Over a long run, what was generated equals what was stored plus
   what was used. No energy appears from nowhere.
2. **Frame-rate proof.** The same run at 30, 60 and 120 frames per second gives the same
   charge levels.
3. **Sources read the felt weather.** Solar follows clear, storm, day, night,
   latitude and the eclipse, making nothing with the sun behind Tu. A turbine inside a base wind shield makes nothing; one outside in a storm
   makes the most.
4. **The AFK promise.** A reference camp (shield, floater, panels, turbine, capacitor)
   parked at mid-latitude runs through 24 simulated hours of weather without any
   device going dark. A deliberately underbuilt camp fails the same test, which proves
   the test can fail.
5. **Clean swaps.** A swapped battery takes effect immediately, and no charge is counted
   twice.
6. **Thirty minutes.** A full base shield in a storm lasts about 30 minutes.
7. **A strong cable holds.** In a 20 m/s wind, a floating planter on a strong cable
   to a staked turbine stays on the end of it, joined and powered. On a common cable
   the same rig pops a plug and blows away. Holding a strong cable's plug, the
   planter pulls on you.
8. **Dragged, not slung.** In a gale a floating planter drags a strong cable's loose
   plug over the dunes and round your legs, from several starts and winds. The plug
   never closes on the port dragging it much faster than 3 m/s, and never outruns
   the wind.
9. **The shield comes first.** The run's kit crate under clear skies, its shield on and
   its battery just above a quarter: its tray gives way at a quarter and it settles on
   the sand while the shield keeps running, and the light panel brings the battery back
   until it floats again.
10. **The rotor turns.** A planted turbine's blades turn faster in a gale than in a
    light wind, and stand still while it's dragged or once it's wrecked.
11. **The camp costs little.** Parked and running, the reference camp's scripts take
    at most three times a tick what the same world's took just before it was parked,
    so a slow machine is slow on both sides.

## Out of scope

- Real electrical simulation, like voltage or wire resistance.

## Open questions

- **Are wires their own item, or can a rope carry power** (conductive cable as an
  upgrade), so tying things together and wiring them up are the same act? **Answered:
  both.** Common wiring is its own item; the strong cable is a rope that carries power.
- **What other sources are there?** Salvaged colonial power cells, for example, since
  the best tech is the oldest.

The Console and sleep sessions (2026-10-17) add two. Each is quoted on both sides and left
standing.

- **A sleep has to be lived through.** Here: power ticks every quarter second of world time, and
  `power.gd` says "a jump in time (a scenario) isn't lived through: nothing charged meanwhile."
  Any gap over 60 seconds is dropped, by needs, the farm and wear as well, and the dev console's
  `time` command jumps that way. The session: "resource arithmetic overnight against a queryable
  storm-intensity curve (shield draw scales with storm strength, so duration matters)" (Survival,
  [Sleep](survival.md#sleep-proposed)). Not said: whether a sleep runs the ticks in a batch or
  sums them in closed form. Either way rule 1, "Energy is conserved," has to hold across it, and
  a probe that a slept span and the same span lived leave the same charge is the obvious check.
  Length is cheap: a three-day storm is an hour of world time, 14,400 ticks.
- **What a Console and its mods draw.** Here: "Instruments, farming gear and tools draw small
  amounts," and the radio draws 2 W. The session: a Console "still takes a hover tray,
  batteries and power like a crate." Not said: what a screen, a radar or another computer mod
  draws, whether a Console on a dark pool goes blind, and what its weight adds to the tray's draw
  at 2 W a kilogram.

Session 4, part 4 (2026-10-17) adds the following. Each is quoted old and new, and the PRD follows the
session as direction.

- **The burner against the heavy generator.** Here (Sources): the "heavy generator" "rides on
  caterpillar tracks, slows the camp, and burns fuel," with "fuel grown from plants" among its fuels.
  The session: a "burner/generator (for coalcane fuel)" as a "crate part." *Follows the session for the
  burner.* Not said whether the heavy generator also takes coalcane, or whether they are one device.
- **A plant that drains power against "energy is conserved."** Here: "Every battery has a charge, every
  device a draw... The numbers always add up." The session: quietbloom "grows by eating your power" and
  "slowly drains" radios and batteries. Not said where the energy goes, or what the plant draws from.
- **What coalcane is worth.** The session says "trades water for power" and gives no figures. Not said
  how much water, light and time a stalk takes, or how much power it gives, so whether burning it pays
  is unset.

Session 4, part 5 (2026-10-17, [the gods session](../gods-gear-farside-2026-10-17.md)) adds the
following. Each is quoted old and new, and the PRD follows the session as direction.

- **A second burner of coalcane.** Here (Fuel crops and the burner): coalcane "is the only renewable fuel
  crop," burned in "a new burner device." The session: the kiln "burns coalcane" too, and a fed Stoker
  eats it. *Follows the session.* Not said how many stalks each takes, or which a farm should feed first.
- **The electric furnace against "no real electrical simulation."** Here (out of scope): "Real electrical
  simulation, like voltage or wire resistance." The session: a furnace "runs on power." Read as a load
  with a draw, which needs no simulation. Not said what it draws.
- **A requisition against "energy is conserved."** Here: "Every battery has a charge, every device a
  draw... The numbers always add up." The session: the Quartermaster "requisitions a cut of your camp
  power." Not said where the cut goes, or whether the module is a load that gives nothing back, as
  quietbloom is above.
- **A god module's draw.** The session gives none for the Walker, the Quartermaster, Mother Cistern or
  the Almanac. Not said whether a module runs on the deck's pool, its own battery, or nothing.
