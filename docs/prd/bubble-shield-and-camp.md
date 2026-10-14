# PRD: Bubble shield & the travelling camp

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

The shield is the cozy. Outside it's total chaos; inside you're fine, you're chilling,
and you have breathing room even in the middle of a storm. The shield is also the
fulcrum the camp balances on. You can drag a lot of stuff around, but whatever is
outside the bubble when a storm hits gets destroyed. So your camp is as big as the best
shield you can move through a storm.

## What the player experiences

- **The shield is a small, light generator.** You carry it or set it down, switch it
  on, and the bubble blooms open in under a second with a hum.
- **Inside: no wind, no dust, but light comes through.** The storm's roar is muffled.
  Outside, it's chaos.
- **The bubble moves with the generator.** Carry it, or let something carry it, and you
  can travel through a storm inside it, with the camp following on short lines.
- **Outside the bubble, the weather hurts.** You take damage, and so do camp pieces left
  out. They wear down and eventually get destroyed.
- **When the power dies in a storm, it's a tough place to be.** The bubble collapses
  and the storm floods in. You'd better have some juice left in the hoverboard, because
  you have to run. If you got here, you've probably used up every other option, and it
  might be GG.

## What hurts you out there

There are three kinds of harm. Survival owns what they do to you; this PRD owns which
shields block which.

| Harm | Where it comes from | Base shield blocks it? |
|---|---|---|
| **Wind** | Strong wind, which can happen outside storms too, in gusts | Yes |
| **Storm** | Dust and sand scouring you inside a storm | Yes |
| **Temperature** | Heat and cold, which get worse toward the poles | **No** |

**Shields protect per harm, at levels:** immune, strong, weak or none.

**Shields open up the map.** The base shield is very power-efficient, reliable, light,
easy to carry and quick to start, but it does nothing about temperature. That pushes you
into the storms early. Later shields that also hold back heat and cold are what open up
the poles.

**Late game, shields nest.** One example is a two-shield setup:
- A big **wind shield** around the whole camp: immune to wind, no help with
  temperature.
- A smaller **temperature shield** inside it, around the farm: strong against
  temperature, weak to wind.

Farming is a subset of the camp, so the temperature shield sets how big the farm can be,
and it's usually smaller than the wind shield. A **combo shield** is strong against both
but immune to neither.

## What Sand Game taught us

Worth keeping: the bubble blooming open in 0.6 s, the activate, hum and shutdown
sounds, the muffled storm inside, and the shader. What was missing:

- **Only you were protected,** not the things inside with you.
- **The wind kept blowing inside the bubble,** because there was one global wind.
- **The power drain was flat** whatever the weather.
- **"Inside" came from enter and exit events,** which can miss.

## Rules

1. **Inside is a place, not an event.** Sheltered means being within the bubble's
   radius of a running generator, and it's computed on demand. Anything can ask "am I
   sheltered?" at any moment and get the true answer.
2. **The bubble edits the weather.** Every system reads the *felt* weather: the wind
   and storm fields (Wind & storms) with shelter applied. Inside a base shield, wind
   and storm read zero. When bubbles nest, each harm gets the strongest protection
   among the bubbles you're inside. So rope loads, damage, dust, fog, sound and power all agree
   about where the bubble is, because they ask the same question.
3. **Everything inside is protected,** camp pieces as well as you.
4. **Light passes through,** so solar still works inside, as far as the storm allows.
5. **You and ropes pass through freely. Wind-blown things don't.**

## Size, and what decides the camp

The bubble's radius is the fulcrum. You *can* drag more than fits, but in a storm,
whatever is outside it gets destroyed. Two other forces push the other way:

- **Hauling capacity**, the horsepower of you, the beast or the yacht. This decides how
  much you can move.
- **Electric power.** This decides how much of what you move actually works, and how
  big a bubble you can keep up.

The shield decides how much of it is safe. All three grow with upgrades.

## Power

- **The base shield sips power.**
- **Draw depends on the shield type.** Some types draw more in storms or at larger
  sizes, and the system plans for that, but the main way to save power is simple:
  switch the shield off, and stay out of storms.
- **A full base shield lasts about 30 minutes in a storm.** That's a starting value to
  tune.
- **The wind doesn't push the base bubble.** Some later types might, which would make
  them want staking.
- **Low power gives warning.** The hum drops and the bubble flickers before it fails.
  The generator shows its charge on itself, with no menu.
- **An empty shield collapses.** Shelter switches off for everything at the same moment.

## Skeleton version

- One shield type that blocks wind and storm but not temperature. Protection is per
  harm from day one, so later types and nesting slot in without rework.
- Carry it, place it, and switch it on or off. It blooms in about 0.6 s and keeps
  running while carried.
- Shelter computed from distance, plus a felt-weather wrapper that rope wind loads,
  damage, fog, dust and sound all read.
- Wind and storm damage to you and to objects outside, with placeholder durability.
  Objects inside are safe.
- A battery that lasts about 30 minutes in a storm, and collapses the bubble when it's
  empty.
- A charge readout on the generator itself.
- Sand Game's activate, hum and shutdown sounds, and the muffled storm inside.
- Sand Game's shield shader as the starting look. Fog and dust are carved out inside
  the bubble.
- The probes below, all passing.

## Full version

- **Shield types:** thermal shields that hold back heat and cold and open the poles,
  combo shields, and types that catch the wind. Plus bigger radii, upgrades and mods.
- **Nested setups,** like a wind shield around the camp with a temperature shield around
  the farm.
- **The warning and the collapse, staged:** the hum sagging, the flicker, the roar
  flooding in.
- **The edge of the world in a storm.** Dust churns right against the bubble's
  surface, from the same work as the wall look-test.
- **Shields on movers:** the beast or the yacht carrying the generator.

## Probes

1. **Shelter agrees everywhere.** At random points inside and outside the bubble, every
   consumer (rope wind load, damage, fog, dust, sound) agrees on whether that point is
   sheltered.
2. **Inside is untouched.** In the worst storm, a camp inside takes zero damage and zero
   wind load for ten simulated minutes.
3. **Outside suffers.** The same camp outside, in the same storm, takes damage and is
   destroyed in the expected time.
4. **The moving bubble.** Carry a running shield 2 km through a storm with a floater on
   a short line. The floater never leaves the bubble and never takes damage.
5. **Power adds up.** Drain matches the expected rate at each storm intensity and bubble
   size. An empty battery collapses the bubble, and shelter switches off for every
   consumer on the same frame.
6. **Fast boot.** The bubble is protecting within its boot time.
7. **Origin shifts are invisible.** Shelter is unaffected by a shift.
8. **Nesting takes the best of each.** Inside both a wind shield and a temperature
   shield, each harm gets the stronger protection. Inside only the outer one,
   temperature reaches you.

## Out of scope

- Blocking projectiles, or any shield combat. There are no enemies.

## Open questions

None right now. The shield's power numbers get settled alongside the Power PRD.
