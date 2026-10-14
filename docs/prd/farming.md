# PRD: Farming

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

The farm is the engine of steady state. It turns light, warmth and time into food, and
some crops also give water and fuel. It's also the part of the camp that most needs
protecting. Crops can't take the temperature swings that you can survive in a suit, so
the farm is what pulls a thermal shield into your life.

## Crops and what they need

| Crop | Needs light | Temperature range | Best where |
|---|---|---|---|
| **Ordinary crops** (carrots and the like) | Yes | Fairly stable | Anywhere but the poles, in clear spells |
| **Yucca** | Yes | Fairly stable | The same, and it stores water and regrows its fruit |
| **Fungus** | No | Very stable | Near the equator only, and it thrives in storms |

**Why fungus loves storms, physically.** Storms are dark, and their dust blankets the
day-night temperature swing (see [the moon](../the-moon.md)). Inside a long storm,
ordinary crops starve for light while fungus gets the darkness and the steady
temperature it wants. Away from the equator the swings get too wide for it.

**The poles make farming hard.** Outside a thermal shield, nothing grows there. That's
why the temperature shield sets how big the farm can be (Bubble shield & camp).

## The farm hardware

- **The hover planter first.** It's a device (Devices & mods) with small and large plant
  slots. A seedling is a part that fits a slot.
- **Then several planters,** arranged however you like. Clip them close together in a
  grid on a single tether, or tie each one to yourself.
- **Later, bigger carriers.** Large found things that can carry the farm, and even the
  shield, so you don't have to carry it yourself. Something like a caterpillar or walker
  farmer.

## Harvesting and getting food to you

1. **By hand at first.** Pick what's ripe.
2. **A harvester mod** ends manual harvesting. Ripe crops go straight into the planter's
   own storage, with no hoppers and no conveyors.
3. **Dropping food onto you** completes the AFK promise (Survival). The planter drops
   produce to you, you pick it up, and auto-eating does the rest.

## What a farm gives

- **Food.**
- **Water,** from yucca.
- **Fuel,** at different grades (Power).

## Rules

1. **Growth ticks at a fixed rate,** independent of frame rate.
2. **Growth reads the felt conditions:** light from the sky (time of day, storms), and
   temperature with shelter applied. A crop inside a thermal shield feels the shield's
   temperature, not the moon's.
3. **Crops are parts in plant slots.** They're typed and never matched by name.
4. **The farm belongs to the camp.** Like everything else, whatever you leave behind is
   forgotten.

## What Sand Game taught us

Sand Game had the bubble planter with small and large slots, carrots (fast, several per
harvest) and yucca (slower, with fruit that regrows). The concepts carry over. The
code doesn't: crops were recognised by matching names, and growth ran on fixed timers
that ignored the weather.

## Skeleton version

- The hover planter with small and large slots.
- One light-needing crop, and fungus, to prove both sets of conditions.
- Growth from felt light and temperature.
- Harvesting by hand, the harvester mod into the planter's storage, and dropping food
  onto you.
- The probes below, all passing.

## Full version

- **Yucca,** with its water and regrowing fruit.
- **Fuel crops.**
- **Planter grids** on a single tether.
- **Big carriers,** like the walker farmer, that can carry the shield too.
- **More crops.**

## Probes

1. **Growth follows conditions.** Each crop grows at the expected rate under each mix of
   light and temperature, and stops where it should.
2. **Fungus stays near the equator.** It fails far from the equator, and does better in
   storms than in clear weather.
3. **The poles need a thermal shield.** Crops at a pole fail outside a thermal shield and
   grow inside one.
4. **The harvester misses nothing.** Over a long run, everything that ripens ends up in
   storage.
5. **The AFK promise feeds you.** This is shared with Survival: an automated farm keeps
   an idle player fed.
6. **Frame-rate proof.** Growth is the same at 30, 60 and 120 frames per second.

## Out of scope

- Conveyors, hoppers and automation chains between devices, for now.
- Pests and diseases.

## Open questions

- **Do crops need water?** That would tie the farm to the daily water rhythm.
- **Where do seeds come from?** Found only, like parts, or can crops give seeds back?
- **How much automation is there,** beyond the harvester and dropping food onto you?
