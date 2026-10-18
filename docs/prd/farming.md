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
sealed containers or a condenser. **Canisters attach, and hoses carry water** (Hunter,
2026-10-17: "instead of pressing use with a water cannister on the planter, we should
attach the cannister. the same port should allow attaching a *hose* which is like the
cable, it carries water, it tethers but not as strong as rope"). A planter has a water
socket, as the condenser does. Fit a canister into it and the planter draws from it into
its tank as it drinks; use with a canister no longer pours. The same socket takes a hose's
end instead (Survival). That ties the farm to the daily water rhythm: water
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

## Feral plants and a crop's history (Agreed, session 4, part 3; not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); loose, and none of it is
built.* Zan has no native life, only feral colonial imports ("rogue plants"). They are not the
planter's crops: they grow wild, in the world, and the farm's two crops are unchanged. They do four
jobs at once ([the lore](../lore-research.md#life-on-zan-feral-plants-agreed-session-4-part-3)):
- **Weather sign.** Feral scrub closes up or turns its leaves before a storm, a free, slotless,
  low-tech barometer ([Wind & storms](wind-and-storms.md#feral-plants-the-free-barometer-agreed-session-4-part-3-not-built)).
- **Trail.** The priestesses of Mother Cistern seeded hardy strains along pilgrim roads and
  irrigation lines as devotion. Those plantings went wild, so a line of scrub is an old sacred
  route.
- **Lore.** Following a feral line tends to lead toward a Cistern shrine and water.
- **Loot.** The order's seed vaults hold preserved colonial seed stock that powers farming
  setups ([Salvage & ruins](salvage-and-ruins.md#seed-vaults-agreed-session-4-part-3-not-built)).

**Every crop system should carry its history** (the session: "The same depth should apply to
agriculture generally"). The farm's crops are typed parts, never matched by name (rule 3 below), so
a crop's history is data on the part and not a new rule. Gear already carries its history in
maker's marks and item text that hint and never state ([Salvage & ruins](salvage-and-ruins.md#lore)),
and a crop would do the same: where its stock came from, shown in the seed's description and
marks, never told. That is a reading. Which history each crop carries is not said.

Readings, not in the session:
- **Wild scrub is not a part in a plant slot.** Rule 3 is about the planter. A feral plant is a
  prop in the world, placed from the seed like a ruin, and nothing in this PRD ties it to a slot.
  Whether one can be picked, moved or sown is not said (open questions).
- **The oracle already names them.** A squatting oracle broadcasts "which feral strains tolerate
  ash soil" ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md)), so feral strains were in
  the lore before this session, and the two are read as the same plants.
- **Where they grow.** "Outside a thermal shield, nothing grows" at the poles, and natural regolith
  isn't soil. Scrub that lives unplanted fits the Rim's ash-rich soil and the old irrigation lines
  (the lore), not bare sand everywhere.

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
  plus its own 4 L water tank, a new **mod mount** on its back, and beside it a **water
  socket** (2026-10-17). It's found with an empty tank. A canister fitted to the water
  socket keeps the tank full from what it holds as the crops drink, so the canister
  empties while the tank stays full, and once it's dry the tank's own 4 L carry on; take
  it out as any part. A hose's end there instead fills the tank from whatever the hose
  joins (Survival). Use with a canister in hand no longer pours: it drinks, as anywhere.
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
  fungus. With the tank dry it stops exactly where the water ran out. A fitted canister
  waters it again until both run dry, and a full one keeps the tank full, losing just
  what the crops drink (probe 5).
- **By hand:** take on a ripe crop and its harvest comes to your hands as food
  (carrots or fungus caps, four units of 150 kcal). Food is like a ration: carry it and
  the suit eats it, or use it to eat your fill. Take on a crop that isn't ripe
  and it comes out whole, to sow somewhere else.
- **Picking by hand keeps the farm going** (Hunter, 2026-10-16): picked fungus regrows
  from what's left in the slot, fruiting again the way mushrooms do; a picked carrot gives
  its seed with the food, to sow where you like. The harvester still saves you the work
  and drops the food on you. As built, the fungus stays in its slot and grows again from
  nothing, as fast as a new one. The carrot's seed falls in with what you carry, as the
  harvester's food does, since your hands are full of the food (2026-10-17: what you
  carry has no slots to fill, so it always does).
- **The harvester** fits the mod mount. With it fitted, a crop is harvested the tick it
  ripens: its share of seed goes straight back into its slot, any more into free slots
  that fit, and seed with no free slot is kept for one. The rest is stored as food in
  the planter. The share it replants is one of 0, 25, 50, 75 and 100%. Use on the
  planter used to step it; now use sets the planter's tray, as on any device (Hunter,
  2026-10-17: "lets not have f toggle replant % on the planter... we will find another
  way to toggle or adjust replant%"), and the share has no control until that's found.
  It starts at 25%, one of a harvest of four, which keeps every slot sown. A
  share that doesn't make a whole seed is carried over, so the split holds over many
  harvests. It draws no power yet.
- **Dropping food onto you:** within 6 m, while you carry less than 2,000 kcal of food (a
  full stomach), the planter drops a harvest's worth onto you, one drop a tick, and you
  see it fall. Auto-eating does the rest.
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
- **The playtest scenario** ("farm" among the dev scenarios) starts you fed and watered on
  a clear morning with a storm due in one and a half to three minutes. Two hover
  planters float in front of you, each on a line to a stake, sown with three carrots
  and a fungus started part grown: the carrots at 85%, so they ripen within a minute in
  the clear, and the fungus at half, so it ripens a few minutes into the storm. One is
  yours to pick by hand, its tank half full, with a full canister by your feet to fit
  to its water socket; the other has a harvester and a full tank. A charged shield
  generator stands between them, switched off, and its bubble takes both. You carry a
  spare carrot.
- **Probe 3 is built** with a test-only thermal shield.
- **The AFK promise feeds you** (Stage 12, 2026-10-17, probe 6). The reference camp's
  farm (Power) is two planters with harvesters, three carrots and a fungus in each, their
  tanks full. Over three days at the equator it fed you alone: the carrots ripened in the
  first clear spell and the fungus through the storms after, 24 and 56 units, and it
  dropped 4,800 kcal onto you, of which you ate 2,400, keeping 4,200 more (with what you
  carry weight-bound, 2026-10-17; it was 2,700 while two free slots held its drops). Your hunger
  never fell below the mark where the suit feeds you, and every slot stayed sown. A
  planter drops what it stored first, so you ate carrots while the fungus piled up.
  Water no longer ends it (2026-10-17): a condenser beyond the shield, on a battery and a
  panel of its own, waters both planters on hoses. The driest tank had 3.66 L left after
  three days, where with nothing to fill them it had 0.65 L and the two ran dry at 3.65
  and 4.96 days; left on for six and a half days, long after you'd died of thirst, the
  tanks never fell below 3.09 L. The condenser made about 1.9 L a day, about what the two
  drink, and since water goes to the emptier tank first, the two stay level. Since the
  camp moved onto its deck (Power, 2026-10-17) the condenser stands on it, in the deck's
  pool, and the planters float upwind of it on their own trays and batteries, each moored
  to a stake upwind: a hose's weight draws a floating planter in toward the deck, and
  tied to the deck instead, the two drifted in 1.2 m in half a day and bumped it. The
  three days come out the same.

## Full version

- **Yucca,** with its water and regrowing fruit.
- **Fuel crops.**
- **Planter grids** on a single tether.
- **Big carriers,** like the walker farmer, that can carry the shield too.
- **More crops,** each carrying its history (above).
- **Feral plants** as a weather sign and a trail, and the order's seed vaults as a source of stock
  (proposed, above). The plants are the first two pieces of the proposed build order in the
  [skeleton plan](../skeleton-plan.md#waiting-for-the-full-version); the vaults are not in it.

## Probes

1. **Growth follows conditions.** Each crop grows at the expected rate under each mix of
   light and temperature, and stops where it should. Picked by hand, a carrot gives its
   food and its seed, and fungus gives its caps and fruits again.
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

Session 4, part 3 (2026-10-17) adds three. Each is quoted on both sides and left standing.

- **Feral scrub against "nothing grows" and the regolith.** Here: "Outside a thermal shield, nothing
  grows there," and every crop is sown in a planter with its own soil. The session: "Zan has no
  native life, only feral colonial imports." Not said where scrub grows, or whether it grows at
  all on the poles' bare sand.
- **What a feral plant gives.** The session names its four jobs: a weather sign, a trail, lore and
  the vaults' loot. It does not say whether a plant can be harvested, moved or sown, or whether it
  has a seed.
- **Which history a crop carries.** "Every crop system should carry its history." The farm has
  carrots and fungus, with yucca and fuel crops to come. Not said what each one's history is, or
  how it shows without exposition.
