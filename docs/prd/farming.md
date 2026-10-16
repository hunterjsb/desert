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

**Every crop needs water.** A planter holds its own water, which you top up from
sealed containers or a condenser. That ties the farm to the daily water rhythm: water
you harvest at dawn keeps the crops alive through the heat.

**Seeds are found,** mostly in ruins. Survival kits are a common find, usually with
seeds and water in them.

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
   own storage, with no hoppers and no conveyors. It also replants, and you set the
   split on the planter itself: how much of each harvest gets replanted, and how much
   gets stored. Set it right and the farm keeps itself going.
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

- The hover planter with small and large slots and a water tank.
- One light-needing crop, and fungus, to prove both sets of conditions.
- Growth from felt light and temperature.
- Harvesting by hand, the harvester mod (into storage, with the replant split), and
  dropping food onto you.
- The probes below, all passing.

**As built in the skeleton (2026-10-16):**
- **The planter** is the catalog's planter: three small slots and a large one on top, a
  battery slot, two ring mounts, a bottom mount for a hover tray and a port, as before,
  plus its own 4 L water tank and a new **mod mount** on its back. It's found with an
  empty tank. Use a canister you hold on it to pour in as much as fits.
- **Two crops:** carrots in the small slots, fungus in the large one. Each is a part of
  its crop, so nothing is matched by name. Sown it stands short; it grows taller and
  fuller as it grows, and ripe it turns its ripe colour (carrots orange, fungus pale).
- **Growth** ticks on power's tick of world time, so the dev time warp grows crops with
  everything else and the frame rate never changes a harvest. It reads the felt light
  where the planter stands (the sun, dimmed by the storm, and still the storm's inside
  a bubble) and the felt temperature (a bubble that holds back temperature holds its
  own). It doesn't need power.
  - **Carrots** start growing at a felt light of 0.25 and grow full from 0.6. A full
    storm leaves 0.22, so they starve in one. They grow between −10 and 60 °C and
    ripen after three minutes of full growth. At the equator that's about one and a
    half harvests a clear day: they grow through the morning, stall in the noon heat
    and pick up again late in the afternoon.
  - **Fungus** grows full in a felt light of 0.25 or less (night, or a storm's dark) and
    not at all from 0.5. It grows between −5 and 45 °C and ripens after six minutes. A
    storm at the equator blankets the swing to between −2.5 and 42.5 °C, so it grows the
    whole time and ripens in six minutes.
  - **Past its hardy limits a crop wilts,** losing growth at twice its best rate, down
    to nothing but never dying: carrots below −30 or above 70 °C, fungus below −15 or
    above 55. That's what "fails" means. In the clear at the equator, fungus grows in
    the evening, then the night's cold wilts it back, and its best is 0.62 of ripe. In
    a storm 60° out, the wider swing does the same and its best is 0.68. At 60° in the
    clear both crops wilt to nothing by the end of a day; inside a thermal shield both
    ripen within one.
  - **A ripe crop stops,** and holds through any weather until it's picked.
- **Water:** a crop drinks as it grows, 0.25 L for a carrot to ripen and 0.3 L for a
  fungus. With the tank dry it stops exactly where the water ran out.
- **By hand:** take on a ripe crop and its harvest comes to your hands as food
  (carrots or fungus caps, four units of 150 kcal), and its slot is free. Food is like a
  ration: put it in your slots and the suit eats it, or use it to eat your fill. Take
  on a crop that isn't ripe and it comes out whole, to sow somewhere else.
- **The harvester** fits the mod mount. With it fitted, a crop is harvested the tick it
  ripens: its share of seed goes straight back into its slot, any more into free slots
  that fit, and seed with no free slot is kept for one. The rest is stored as food in
  the planter. Use on the planter steps the share it replants through 0, 25, 50, 75 and
  100%. It starts at 25%, one of a harvest of four, which keeps every slot sown. A
  share that doesn't make a whole seed is carried over, so the split holds over many
  harvests. It draws no power yet.
- **Dropping food onto you:** within 6 m, while your slots hold less than 2,000 kcal of
  food (a full stomach) and one is free, the planter drops a harvest's worth into it,
  one drop a tick, and you see it fall onto you. Auto-eating does the rest.
- **What one planter gives:** a harvester planter of three carrots and a fungus at 25%,
  at the equator, stores about 1,900 kcal a day in the clear (all carrots) and 1,400 in
  a storm (all fungus). You eat 1,000. It drinks 1 to 1.3 L a day, so a full tank lasts
  three or four days, and one condenser can't keep you and it both.
- **Wear:** a planter outside a bubble in a storm wears like any device, and a wrecked
  one grows nothing.
- **Seeds are found** (2026-10-16): carrots and fungus lie loose on ruins' floors, and in
  survival kits. Seeds keep only out of the weather, so a kit on open sand has mostly
  lost its seeds and one on a ruin's floor holds them. Over thousands of chunks, 58 of
  99 seeds were in ruins. A found seed is a seedling at nothing grown, ready to sow. The
  harvester is a rare deep part, the rarest part on open sand.
- **The playtest scenario** ("farm" in the scenario menu) starts you fed and watered on
  a clear morning with a storm due in one and a half to three minutes. Two hover
  planters float in front of you, each on a line to a stake, sown with three carrots
  and a fungus started part grown: the carrots at 85%, so they ripen within a minute in
  the clear, and the fungus at half, so it ripens a few minutes into the storm. One is
  yours to pick by hand, its tank half full, with a full canister by your feet to top
  it up; the other has a harvester and a full tank. A charged shield generator stands
  between them, switched off, and its bubble takes both. A spare carrot is in your
  slots.
- **Probe 3 is built** with a test-only thermal shield. Probe 6 waits for stage 12.

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
4. **The harvester misses nothing.** Over a long run, everything that ripens is either
   replanted or stored, in the split you set, and a farm set to replant enough never
   runs out of plants.
5. **No water, no growth.** A crop whose planter runs dry stops growing.
6. **The AFK promise feeds you.** This is shared with Survival: an automated farm keeps
   an idle player fed.
7. **Frame-rate proof.** Growth is the same at 30, 60 and 120 frames per second.

## Out of scope

- Conveyors, hoppers and automation chains between devices, for now.
- Pests and diseases.

## Open questions

None right now.
