# PRD: Movement

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Moving is most of what you do: wandering, choosing a direction against the wind, towing
the camp, and running when the shield dies. Movement is where both difficulty dials
are felt in your body. It's also where the game has to be most fun from second to
second, because you'll spend hours doing it.

## On foot

- **Walking, about 5 km/h, and sprinting,** which costs stamina.
- **The dunes push back.** Gentle windward slopes are easy. Climbing a steep slip face
  is slow and costs stamina, and travelling into the wind means climbing them.
- **The wind pushes you,** using your wind catch and the felt weather. Inside a shield,
  it doesn't.
- **Lines pull you.** A strong gust on a line drags you, and a waist tie slows you down
  (Rope & tethering).

## The hoverboard

- **Fast and floaty.** It skims the dunes, and it's fun to turn, with a little give and
  rotation on the curve of a dune so you can do tricks.
- **It's your escape.** Unloaded and charged, it outruns a storm front, which moves at
  20–40 km/h. It runs on its own battery.
- **It can tow, but only in a pinch.** Towing slows the board, the drag climbs steeply
  with what you're pulling, and it eats power. That's what makes the escape a choice:
  - Not deep in the storm and running low? Grab a hover planter and run.
  - Too deep? You need every bit of charge and the board can't afford the slowdown.
    Leave the planter, take the board and go, and hope you find another one out there.

## Leaving your camp behind

Only what's near you exists (World & terrain). Ride too far from your camp and it's
forgotten. That's fine, as long as it's never a surprise:

- **The game warns you, clearly, before the camp is lost.** One warning as you near the
  edge, and a last one before you cross it.
- **Warnings are timed by speed, not just distance.** Even at full speed on the board,
  you get enough seconds to turn back.

## Later movers

- **The mechanical beast** follows at a distance and carries or tows things. It's made
  of stiff parts, so it needs no skin rigging.
- **The sand yacht** rides the wind. It can zigzag upwind (tacking), and a real land
  yacht can go faster than the wind itself, so a good one might outrun a storm.
- **Big carriers,** like the walker farmer, that can carry the farm and the shield.

## Rules

1. **The board floats on the ground's one function.** Its hover height follows
   `height_at`, so it never catches on collision seams between chunks. It only collides
   with objects and ruins.
2. **Movement reads the felt wind,** so shelter applies to it.
3. **Tow drag rises steeply with load,** and power draw rises with it.
4. **Frame-rate proof.** The same input gives the same path at any frame rate.
5. **Never silently lose the camp.** Leaving camp range always comes with warnings, with
   enough time to react at any speed.

## Skeleton version

- Walking, sprinting and stamina, with slip faces costing more.
- Wind pushing you, and lines dragging you.
- The hoverboard: fast, floaty and carving, with its own battery, and towing with steep
  drag.
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
2. **The escape is real.** An unloaded board on a full charge escapes a storm front from
   a set distance. The same board towing a loaded planter doesn't.
3. **Towing costs what it should.** Speed and power draw follow the designed curve as the
   towed weight rises.
4. **The wind dial on foot.** Crossing the same dunes takes more time and stamina upwind
   than downwind.
5. **The warnings always come first.** At every speed up to full, the camp-range
   warnings fire with enough time to react before the camp is lost.
6. **Frame-rate proof.** The same ride at 30, 60 and 120 frames per second follows the
   same path.
7. **Origin shift at speed.** Riding across an origin shift at top speed causes no hitch
   and no jump.

## Out of scope

- Climbing walls, swimming and flying.

## Open questions

- **How fast is the board, and how far does a charge go?** It has to beat a storm front
  unloaded. The rest is tuning.
- **Do tricks do anything,** or are they just for fun?
- **How do the warnings show up?** Sound, the suit, the radio, a visible edge?
