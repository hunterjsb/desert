# PRD: Movement

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Moving is most of what you do: wandering, choosing a direction against the wind, towing
the camp, and deciding how to meet each storm. Movement is where both difficulty dials
are felt in your body. It's also where the game has to be most fun from second to
second, because you'll spend hours doing it.

## The split

**The camp moves at walking pace. The board is just for you. Storms are weathered, not
outrun,** at least until the late-game haulers arrive.

## On foot

- **Walking, about 5 km/h, and sprinting,** which costs stamina.
- **You tow the camp.** You're the most reliable thing to tow with: bubble up, planters
  floating on short lines (Rope & tethering).
- **The dunes push back.** Gentle windward slopes are easy. Climbing a steep slip face
  is slow and costs stamina, and travelling into the wind means climbing them.
- **The wind pushes you,** using your wind catch and the felt weather. Inside a shield,
  it doesn't.
- **Lines pull you.** A strong gust on a line drags you, and a waist tie slows you down.
- **Sliding** (decided 2026-10-15, from Hunter's old vision board: "sand game has a lot
  of sand so sliding will be an important mechanic"). Passive: a slope too steep to
  stand on slides you down it. Active: slide on purpose and build momentum downhill.
  Momentum is the reward.
- **Jump and crouch** (decided 2026-10-15). A small, honest jump that shows the moon's
  gravity. Crouching makes you smaller to the wind, so you brace against a storm.
- **Your feet sink when you haul** (decided 2026-10-15). Walking or sprinting against a
  heavy pull on a line, you dig in: you sink a little, slow down and tire faster.
- **The body feels it:** sway as you walk, a spring in the step, a dip when you land,
  and a lean into strong wind. Sand Game's footstep, slide and impact recordings.

## Meeting a storm

Storms are faster than anyone walks, and the wall gives you about 5 minutes. That's time
to batten down, not to run. Pull the planters in, stake what needs staking, shield up.
Then choose:

- **Sit it out** and let it pass.
- **Walk through it** inside your moving bubble.
- **Head into the wind** to come out the back sooner. It's the hard way.
- **Sidestep an edge** on foot, if you read the storm early enough.

**Early on, weathering is hard,** and anchors are precious. A post or a ruin to tie more
of the camp to when a storm hits is worth a lot. Every storm is a judgment call, based on
how fast it looks like it's moving and what your instruments tell you: stay here for
this one, or push through?

**Later, it gets easier.** Bigger setups let you keep moving and sustain through storms,
even storms that last for days.

## The hoverboard

- **It's a find, not a starting item.** Finding one is a moment of freedom.
- **Fast and floaty.** It skims the dunes, and it's fun to turn, with a little give and
  rotation on the curve of a dune so you can do tricks.
- **It's for scouting and escaping.** Unloaded and charged, it outruns a storm front. It
  runs on its own battery.
- **It tows nothing.** That keeps it fun, and it keeps it from competing with the camp.
  When the shield dies deep in a storm, you take what's in your hand and go. Before you
  find a board, a shield failure deep in a storm is fatal, so early runs stay in
  shallow storms and carry spare batteries.

## Haulers: moving the base faster

The base gets faster through a progression of haulers:

1. **On foot,** from the start: reliable and slow.
2. **The mechanical beast.** Walking pace, but it carries a lot and follows you on its
   own. It's made of stiff parts, so it needs no skin rigging.
3. **The sand yacht.** The real fast base-mover. It runs on the wind, so it belongs in
   this world. It's fast with the wind, it can zigzag upwind (tacking), and a real land
   yacht can go faster than the wind itself. A good one might outrun a storm with the
   camp aboard.
4. **Big carriers,** like the walker farmer, that carry the farm and the shield.

Early on you weather storms. Later, the yacht lets you choose between weathering one
and outrunning it.

## Leaving your camp behind

Only what's near you exists (World & terrain). Ride too far from your camp and it's
forgotten. That's fine, as long as it's never a surprise:

- **The game warns you, clearly, before the camp is lost.** One warning as you near the
  edge, and a last one before you cross it.
- **Warnings are timed by speed, not just distance.** Even at full speed on the board,
  you get enough seconds to turn back.

## Rules

1. **The board floats on the ground's one function.** Its hover height follows
   `height_at`, so it never catches on collision seams between chunks. It only collides
   with objects and ruins.
2. **Movement reads the felt wind,** so shelter applies to it.
3. **Frame-rate proof.** The same input gives the same path at any frame rate.
4. **Never silently lose the camp.** Leaving camp range always comes with warnings, with
   enough time to react at any speed.

## Skeleton version

- Walking, sprinting and stamina, with slip faces costing more.
- Towing the camp on foot.
- Wind pushing you, and lines dragging you.
- The hoverboard: fast, floaty and carving, with its own battery.
- Camp-range warnings.
- Getting on and off the board quickly.
- The probes below, all passing.

## Full version

- **Tricks.**
- **Board mods** in its sockets: battery, hover pads and the like (Devices & mods).
- **The beast, the sand yacht and big carriers.**
- **The board's feel and sound,** polished.

## Probes

1. **The long ride.** Ride 20 km of dunes, slip faces and chunk seams at top speed. The
   board never dips below the sand, never launches unexpectedly, and never jitters.
2. **The escape is real.** A charged board escapes a storm front from a set distance.
3. **The wind dial on foot.** Crossing the same dunes takes more time and stamina upwind
   than downwind.
4. **The camp follows on foot.** Tow the reference camp 2 km on foot, through a storm,
   with the bubble up. Everything arrives, inside the bubble and undamaged.
5. **The warnings always come first.** At every speed up to full, the camp-range
   warnings fire with enough time to react before the camp is lost.
6. **Frame-rate proof.** The same ride at 30, 60 and 120 frames per second follows the
   same path.
7. **Origin shift at speed.** Riding across an origin shift at top speed causes no hitch
   and no jump.

## Out of scope

- Climbing walls, swimming and flying.

## Open questions

- **How fast is the board, and how far does a charge go?** It has to beat a storm front.
  The rest is tuning.
- **Do tricks do anything,** or are they just for fun?
- **How do the warnings show up?** Sound, the suit, the radio, a visible edge?
