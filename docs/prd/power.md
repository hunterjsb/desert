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

## What draws power

- **Shields,** by type. A full base shield lasts about 30 minutes in a storm. The main
  way to save power is to switch it off and stay out of storms.
- **Hover trays** keep camp pieces floating, and their draw rises with the weight they
  carry, mounts included. Without enough power, you haul.
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
  half a found one, built into a flat frame with a port, 5 kg, that you carry, set down
  and pick back up. Lying flat, the wind meets its edge, so a breeze doesn't skate it
  off. Every run starts with it cabled into the light shield (Survival).
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
- **The tick reads each source at its own world time**, four times a second of world
  time, so the dev time warp charges faster and 30, 60 or 120 frames a second give the same charge to
  the bit.
- **The turbine** makes up to 200 W in a gale and nothing while it's being moved.
- **Two kinds of cable** (decided 2026-10-14, from the Stage 4 playtest). **Common
  wiring** pops a plug when pulled too hard, and Hunter likes that: a floating planter
  blown off a turbine unplugs itself. A **strong cable** is also a rope, so it holds
  what it's plugged into and powers it. It never pops; too much load snaps it at
  4,000 N. While you hold one of its plugs, the rope pulls on you, not on the plug in
  your grip. A loose plug on either kind is dragged along by what drifts off with
  the other end, never slung, however long it was caught.

## Full version

- **Battery tiers,** chargers, wires, and central capacitors built from them.
- **Tracked and mounted solar.**
- **Priorities.** When the capacitor runs low, the shield is the last thing to lose
  power.
- **The heavy generator** on caterpillar tracks, with fuels: rare consumables,
  fissile material with something to burn it, and fuel grown from plants.
- **Draw by state:** idle, active, holding back a storm.
- **More sources,** still to be designed.

## Probes

1. **Energy adds up.** Over a long run, what was generated equals what was stored plus
   what was used. No energy appears from nowhere.
2. **Frame-rate proof.** The same run at 30, 60 and 120 frames per second gives the same
   charge levels.
3. **Sources read the felt weather.** Solar follows clear, storm, day, night and
   latitude. A turbine inside a base wind shield makes nothing; one outside in a storm
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

## Out of scope

- Real electrical simulation, like voltage or wire resistance.

## Open questions

- **Are wires their own item, or can a rope carry power** (conductive cable as an
  upgrade), so tying things together and wiring them up are the same act? **Answered:
  both.** Common wiring is its own item; the strong cable is a rope that carries power.
- **What other sources are there?** Salvaged colonial power cells, for example, since
  the best tech is the oldest.
