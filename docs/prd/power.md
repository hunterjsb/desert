# PRD: Power

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Power turns the stuff you haul into stuff that works. It keeps the shield up, the camp
floating and the hoverboard ready to run. It's also what the first pillar means in
practice: **steady state is a power budget that balances** through day, night and storm.
A camp that generates more than it draws, and stores enough to cover the gaps, is a
camp you can walk away from.

## What the player experiences

- **Every device has its own battery,** and you can see its charge on the device itself.
  There's no menu.
- **The rudimentary setup** wires a source straight into a device: a solar panel into the
  shield. It works while the sun shines.
- **Then batteries.** You charge them at a source and swap them by hand. Carrying a fresh
  battery to the shield in the middle of a storm is a scene. A charged battery in your
  hand is stored power.
- **Late game, a central capacitor** feeds the camp, and you stop swapping by hand.
  That's where steady state lives.
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
| **Heavy generator** | Always: strong and steady | — | It rides on caterpillar tracks and slows the camp |

**Turbines have to brave the storm.** Because the bubble edits the weather (Bubble
shield PRD), a turbine inside a wind shield feels no wind and makes nothing. It has to
stand outside, in the storm, and take the damage. The alternative is a shield that
lets wind through, like the late-game temperature shield. That trade-off comes free from
the felt-weather rule.

## What draws power

- **Shields,** by type. A full base shield lasts about 30 minutes in a storm. The main
  way to save power is to switch it off and stay out of storms.
- **Hover trays** keep camp pieces floating. Without enough power, you haul.
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
- One crude solar panel and one crude wind turbine, each reading the felt weather. A
  source can be wired straight into a device or into a charger.
- Swapping batteries by hand.
- The shield, the test floater and the hoverboard all draw from their batteries.
- A simple charge light on every device.
- A fixed-rate power tick.
- The probes below, all passing.

## Full version

- **Battery tiers,** chargers and the central capacitor.
- **Priorities.** When the capacitor runs low, the shield is the last thing to lose
  power.
- **The heavy generator** on caterpillar tracks.
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

## Out of scope

- Real electrical simulation, like voltage or wire resistance.

## Open questions

- **How long is a day?** Solar needs it, and so do the temperature swings.
- **How does the central capacitor reach devices?** By cable? Could the rope itself
  carry power, with conductive cable as an upgrade, so tying things together and wiring
  them up are the same act?
- **What fuels the heavy generator,** if anything?
- **What other sources are there?** Salvaged colonial power cells, for example, since
  the best tech is the oldest.
