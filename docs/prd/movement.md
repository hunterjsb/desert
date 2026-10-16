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

- **Walking, about 6.5 km/h, and sprinting at about 14 km/h,** which costs stamina.
  Raised at the Stage 5 gate, where both felt slow and a slide was hard to justify
  (Hunter, 2026-10-15); the head's sway stays as it was.
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

**Built (2026-10-15, `game/player/feel.gd`, `probes/movement/`).** Jump and crouch are
their own actions. Crouching at a run or heading downhill turns into a slide. Slides gain speed
above about 6°, and sand steeper than 28° slides you whatever you do. The jump is 0.45 m
at 1 g and 1.0 m at 0.45 g, because the push-off is the same on any moon. Crouching cuts
your wind catch to 45%. Hauling hard against a line digs you in: up to 35% slower, and
your stamina drains faster. The feel settings live in their own "Body feel" tuning group.

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
- **It travels racked** (Hunter, 2026-10-16: "i like a rack"). A crate frame has a rack
  along its side; the board seats in it the way the shield seats on a top mount, rides
  wherever the crate goes, and charges from the camp's power, after the shield. Pack up
  and walk with the camp, and the board comes; take it off the rack to scout.
  When the shield dies deep in a storm, you take what's in your hand and go. Before you
  find a board, a shield failure deep in a storm is fatal, so early runs stay in
  shallow storms and carry spare batteries.

**Built (2026-10-16, Stage 10, `game/board/`).**
- **A find.** The board is a catalog device in salvage's deep layer, one in nine of its
  devices, found buried on end, nose down. Its battery sits at its nose and comes filled
  like any deep find's; its port charges it from a cable. The scenario menu's "ride"
  lays a charged one at your feet.
- **On and off.** The ride action steps you onto the board in your hands, the one you
  look at, or the nearest at your feet, if it has charge, and steps you off again,
  keeping your way: faster than you can run, you skid, and the board goes on as a body.
  It tows nothing: a line or a grip in your hands is let go, a line at your waist is
  untied first (it takes its moment) and you step on once it's free, and riding you
  take only loose things on no line.
- **Fast.** 20 m/s, 72 km/h, flat out on the flat in still air, against storm fronts
  riding the prevailing wind at 6 to 14 m/s. Drag grows with speed², and a third of it
  is the air's, felt against the felt wind: a tailwind carries you faster and a headwind
  holds you back, and a tuck (crouch) shows the wind less, about 22 m/s flat out. Slopes
  pull it as they pull a slide, so it runs past top speed down a slip face (22.8 m/s on
  the long ride) and slows climbing one, to about 11 m/s in still air.
- **Carving.** Move forward and the sideways moves push and carve where they point from
  your view, as walking does. The board swings round under you at up to 2.5 rad/s and
  your way follows it as hard as its hover grips sideways, 18 m/s², so a gentle turn
  holds and a sharp one skids: flat out, a hard turn comes round 90° in about 3 s, the
  board up to 48° ahead of your way, and you come out of it at 18 m/s from 20. Steering
  back against your way, move forward while looking behind you, brakes too; a jump hops.
- **After Hunter's first ride** (2026-10-16: "feels really nice. a little twitchy on the
  tilt"), five changes, built the same day:
  - **The tilt settles,** never twitches. Its pitch and roll over the sand settle as a
    critically damped spring at 5 Hz, in about an eighth of a second, and its lean into
    a carve at 1.2 Hz, so going from one hard carve to the other (60°) takes about half a
    second. Both are stepped with the ride, and drawn smoothed between ticks with its
    turn, as its place already was; your view leans with a share of the drawn lean. Flat
    out across the ridges, carving hard each way, the lean changes at most 2.9° a tick at
    sixty ticks (it snapped up to 60° before), the pitch at most 1.4°.
  - **Move back only brakes,** 8 m/s², from 13 m/s to a stop in about 1.5 s whichever
    way you look; from rest it does nothing. It never steers you round into reverse, and
    the sideways moves still carve while it brakes.
  - **Sprint kicks off the sand,** like a skateboard push: 2.5 m/s along the board from
    rest, less the faster you go and nothing at top speed, a kick every 0.6 s while it's
    held, 6 stamina each, and only with the board near the sand. Holding it you don't get
    your breath back, so a full bar is 16 kicks, about ten seconds. From rest to 10 m/s
    takes 0.8 s instead of 1.25 s; up a 32° slip face from its foot you climb 13.9 m in
    3 s instead of 8.8 m. Top speed and range don't change.
  - **Pumping.** Your legs work against what the hover holds you with beyond your weight:
    standing up as it presses into a dip, or getting low as it unloads over a crest, puts
    that work into your way; standing lifts your weight 0.5 m. Flat out at 20 m/s a good
    crouch over a crest gains about 0.25 m/s and standing into the dip that follows about
    0.45 m/s, some 3.5% for the pair, and the wrong way round costs as much. Drag takes
    each surge back within a couple of seconds, so over 30 s of ridges pushing flat out a
    rider in rhythm goes 0.8% further than one standing still (the tuck aside). The tuck
    is still the most speed there is flat out: tucked all the way goes 10% further than
    standing, pumping with the tuck 5%.
  - **A drift.** Crouch into a hard carve, 8 m/s or faster with the board swung 20° off
    your way, and the board slides out on purpose: it swings round at 3.5 rad/s, grips at
    14 m/s², and a slide fully sideways bleeds a quarter of its speed a second instead of
    all of it. Steer it with the move keys; it ends when you stand up or the board comes
    back within 8° of your way. From 19.4 m/s, a hard turn standing skids round 80° in
    1.05 s and comes out at 12.9 m/s, sliding 46° at most; drifting it comes round in
    1.4 s at 16.6 m/s, sliding 60°.
- **Floaty.** Its underside rides 0.35 m over the sand and keeps 8 cm clear of it,
  about 6 cm at a corner. The
  spring is stiff pressed down and softer lifting off, and pulls you back down at most
  15 m/s² past gravity, so off a big crest at top speed you float a metre or two; a hop
  falls at 0.6 g. It feels the sand along its own length, and the sand round it from
  0.45 s of travel behind to 0.45 s ahead, both as running means along the way it went,
  so the ground's lattice never judders it and a dip's bottom is rounded instead of
  slammed into. Climbing flat out straight into a slip face's foot is the hardest it
  gets, about 5 g for a moment.
- **Its own battery.** It draws 40 W floating and up to 260 W more at full push (Power):
  a base battery lasts about twenty minutes flat out, about 23 km over the dunes. Out of
  charge, you step off. Outside a bubble the weather wears it like any device.
- **Frame-rate proof.** It's stepped 240 times a second inside each tick, your crouch,
  its tilt, its kicks and your stamina on it too. At its speed your view would stutter
  between ticks, so Feel draws you, and the board, its tilt and its turn, smoothed
  between the last tick and this one; the ticks never see it.
- The numbers are in Tuning's Hoverboard group.

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

**Built (2026-10-16, Stage 10, `game/player/camp_range.gd`).** The camp is every device
of yours lying in the world, anything not in your hands, at your waist or under your
feet, the run's starting kit included. Each is forgotten once your chunk is more than
nine from its own (the view's eight, and one more before a chunk is let go), so each has
an edge 576 to 640 m out along the chunk grid, further on the diagonal. The warnings watch the edge you're heading for: the
first comes 20 s before you reach it at your pace, or 40 m from it at any pace; the last
at 8 s or 12 m. Cross it and you're told what was lost. Clear of it again, it can warn
again. Flat out on the board that's the first warning about 400 m before the edge, so a
couple of hundred metres from camp, and the last 160 m before it; braking and turning
back takes about 20 m. The look is a skeleton's, until the open question below is
answered: a chime (three quick beeps for the last, a falling tone for a loss) and one
line of text at the top of the view, "Leaving camp range · lost in 18 s", "LAST WARNING ·
camp lost in 6 s · turn back", "Camp lost · Crate frame". The numbers are in Tuning's
Camp range group.

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

All built: on foot alongside Stage 5, the board and the camp-range warnings at Stage 10.

## Full version

- **Tricks.**
- **Board mods** in its sockets: battery, hover pads and the like (Devices & mods).
- **The beast, the sand yacht and big carriers.**
- **The board's feel and sound,** polished.

## Probes

1. **The long ride.** Ride 20 km of dunes, slip faces and chunk seams at top speed. The
   board never dips below the sand, never launches unexpectedly, and never jitters.
   *(Built: half across the ridges with the wind and against it, half wandering, over
   411 chunk seams, 18.8 m/s on average. The underside never came nearer the sand than
   5.8 cm; 55 launches, every one off a crest, at most 1.9 m over its ride height; no
   judder; the hardest moment 5.3 g, climbing into a slip face; the ground solid under
   you all the way.)*
2. **The escape is real.** A charged board escapes a storm front from a set distance.
   *(Built: in the run's own weather, a front 50 m upwind. Flat out downwind on a base
   battery, the front falls behind at about 11 m/s, 2.1 km behind after three minutes,
   with 86 Wh of 100 left. Sprinting the same way on foot, it catches you in 6 s.)*
3. **The wind dial on foot.** Crossing the same dunes takes more time and stamina upwind
   than downwind. *(Built: 60 m of dunes near spawn you can cross both ways, in a 20 m/s
   gale: 13.4 s and 112 stamina with it, 20.1 s and 178 into it. A ridge itself you can't
   cross into the wind on foot at all: its slip face is too steep to climb.)*
4. **The camp follows on foot.** Tow the reference camp 2 km on foot, through a storm,
   with the bubble up. Everything arrives, inside the bubble and undamaged. *(Shield
   probe 4 stands in until the full camp exists.)*
5. **The warnings always come first.** At every speed up to full, the camp-range
   warnings fire with enough time to react before the camp is lost. *(Built: from 1 m/s
   to a board's 26 m/s with a tailwind, along the chunk grid and across it, the first
   warning comes 20 s or more before the edge and the last 8 s or more, and past it the
   camp is lost and you're told. Turning back flat out at the last warning, you come no
   nearer the edge than 139 m.)*
6. **Frame-rate proof.** The same ride at 30, 60 and 120 frames per second follows the
   same path. *(Built: kicks from rest, a push, a carve, a hop, a drift, a coast and a
   brake over 85 m: the same path to a tenth of a millimetre, with the same charge and
   stamina left, and the same path to the bit with the drawing switched off.)*
7. **Origin shift at speed.** Riding across an origin shift at top speed causes no hitch
   and no jump. *(Built: flat out in real time at sixty frames a second, ruins and finds
   laid out as you go, across four shifts in 1.1 km: your way changes no more at a shift
   than anywhere, the ground stays solid 120 m ahead, and no frame spends longer than
   1.2 to 1.3 ms streaming headless, against the 2.0 ms line. In a real window at 144 Hz
   (`look/stream`, which now rides a board flat out downwind too) the worst was 1.21 ms
   over 410 m; the ring of collision round you came up short for a moment after a
   crossing in 92 of its 2,857 frames.)*

Movement on foot, built alongside Stage 5, has its own:

8. **Slides.** Momentum is the reward: down a real slope a crouch at a sprint slides
   you past anything your legs can do; on the flat a slide stops about where the sand's
   friction says.
9. **Too steep to stand.** A slip face won't hold you.
10. **A jump shows gravity.** The same push-off on any moon: 0.45 m at 1 g, 1.0 m at
    0.45 g.
11. **Frame-rate proof on foot.** The same keys at 30, 60 and 120 ticks trace the same
    path, walking, sliding and jumping.
12. **Crouching braces.** Crouched, the wind catches less of you.
13. **Hauling digs in.** Against a heavy line you sink, slow and tire faster.
14. **Never below the sand.** Slides, jumps and landings at 1 g and 0.45 g never put you
    in the sand.

The board after Hunter's first ride has its own:

15. **Move back brakes.** From rest it never moves you; riding, it stops you and never
    reverses you, even looking off your way. *(Built: from 13.4 m/s, stopped in 1.45 s,
    looking along your way or 34° off it.)*
16. **The kick.** From rest a kick gets you going and costs stamina, with none there's no
    kick, and kicking climbs a slip face faster. *(Built: kicks alone, 6.8 m/s in 2 s for
    24 stamina; up a 31.7° slip face from its foot in 3 s, 13.9 m against 8.8 m.)*
17. **Pumping.** Over the ridges flat out, a rider in rhythm beats one standing still, but
    only a little, and the wrong way round loses. *(Built: with the tuck switched off,
    30 s, 546.8 m against 542.4 m, +0.8%; the wrong way round 538.1 m.)*
18. **The drift.** A hard turn crouched slides further out and keeps more speed than the
    same turn skidding, and standing up grips again. *(Built: from 19.4 m/s, out at
    16.6 m/s against 12.9, sliding 60° against 46°.)*
19. **The tilt settles.** Flat out across the ridges, carving hard each way, the board's
    pitch and lean never jump. *(Built: at sixty ticks, the lean at most 2.9° a tick, the
    pitch 1.4°; before, the lean snapped up to 60° and the pitch moved up to 1.8°.)*

## Out of scope

- Climbing walls, swimming and flying.

## Open questions

- **How fast is the board, and how far does a charge go?** It has to beat a storm front.
  The rest is tuning. *First numbers (Stage 10): 20 m/s flat out, about 23 km on a base
  battery; it outruns a front by about 11 m/s with the wind behind it.*
- **Do tricks do anything,** or are they just for fun?
- **How do the warnings show up?** Sound, the suit, the radio, a visible edge? *The
  skeleton chimes and puts one line of text at the top of the view, as a stand-in.*
- **How far can the board scout?** The camp is forgotten about 600 m out, half a minute
  flat out, so scouting on the board is out and back within that, or with the camp in
  tow on foot.
- **Slip faces steep enough to slide you:** yes (Hunter, 2026-10-15). The Ridges dunes
  (World & terrain) have them, at 31.5°, and the probes find them near spawn.
