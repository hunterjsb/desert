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
your stamina drains faster. You start to dig in once a line takes 35% of your pace, and
are all the way in, within about a second, once it takes the 65% you'd manage dug in
(2026-10-18: the depth had been read against the pace you were already sunk to, so a
pull near that edge took over two seconds to dig you in). A load past what you carry easily sinks you in the same way,
standing too, but tires you only on the move, and past sunk in it slows you further
(Survival, 2026-10-17). The feel settings live in their own "Body feel" tuning group.

## Meeting a storm

Storms are faster than anyone walks, and the wall gives you about 5 minutes. That's time
to batten down, not to run. Pull the planters in, stake what needs staking, shield up.
Then choose:

- **Sit it out** and let it pass. (Or sleep through it: proposed, [Survival](survival.md#sleep-proposed).)
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
  like any deep find's; its port charges it from a cable. The "ride" scenario
  lays a charged one at your feet.
- **On and off.** The ride action steps you onto the board in your hands, the one you
  look at, or the nearest at your feet, if it has charge, and steps you off again,
  keeping your way: faster than you can run, you skid, and the board goes on as a body.
  It tows nothing: a line or a grip in your hands is let go, a line at your waist is
  untied first (it takes its moment) and you step on once it's free, and riding you
  take only loose things on no line. A sail's sheet at your waist stays tied, so your camp
  can tow you, and the board pushes against no line (2026-10-18,
  [sailing](#sailing-the-camp-hunter-2026-10-17)).
- **Racked** (2026-10-16). A crate frame's rack runs along the top of its left side. The
  board is longer than the crate, 1.3 m against 0.8 m, so it overhangs 25 cm front and
  back. It stands on its edge, nose forward and deck out, 1 cm off the side and 17 cm
  proud of the top (clear of the ring mount below it, until the crate lost its side
  rings on 2026-10-17). It seats the way the
  shield seats on a top mount: holding it at the rack, the tug leans it in and take seats
  it, and take lifts it off again, whole. Racked, it rides exactly on its seat wherever
  the crate goes (towed 40 m, it moved 0.008 mm off its seat at most), its 11 kg join the
  crate's hover load, and it charges from the camp after the shield (Power). You can't
  ride it racked: the ride action at a racked board takes it off and steps you onto it,
  as the ride action at any board you look at puts it under your feet. It saves and
  resumes racked. Every run starts with the board racked on the kit's crate (Hunter,
  2026-10-16: "i think it should start you w a *racked* hoverboard"; Survival).
- **Fast.** 20 m/s, 72 km/h, flat out on the flat in still air, against storm fronts
  riding the prevailing wind at 6 to 14 m/s. Drag grows with speed², and a third of it
  is the air's, felt against the felt wind: a tailwind carries you faster and a headwind
  holds you back, and a tuck (crouch) shows the wind less, about 22 m/s flat out. Slopes
  pull it as they pull a slide, so it runs past top speed down a slip face (22.9 m/s on
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
    standing, pumping with the tuck 2.4% (5% before the board caught air).
  - **A drift.** Crouch into a hard carve, 8 m/s or faster with the board swung 20° off
    your way, and the board slides out on purpose: it swings round at 3.5 rad/s, grips at
    14 m/s², and a slide fully sideways bleeds a quarter of its speed a second instead of
    all of it. Steer it with the move keys; it ends when you stand up or the board comes
    back within 8° of your way. From 19.4 m/s, a hard turn standing skids round 80° in
    1.05 s and comes out at 12.9 m/s, sliding 46° at most; drifting it comes round in
    1.4 s at 16.6 m/s, sliding 60°.
- **Floaty, and it catches air.** Its underside rides 0.35 m over the sand and keeps
  8 cm clear of it, about 6 cm at a corner. The spring is stiff pressed down and softer
  lifting off, and pulls you back down at most 15 m/s² past gravity, but only while the
  sand is near: that hold eases off over the first 0.5 m above ride height, and past it
  you fly under gravity alone. It feels the sand along its own length, and the sand
  round it from 0.45 s of travel behind to 0.45 s ahead, both as running means along the
  way it went, so the ground's lattice never judders it and a dip's bottom is rounded
  instead of slammed into. Climbing flat out straight into a slip face's foot is the
  hardest it gets, about 5 g for a moment.
- **Air** (Hunter, 2026-10-16: "it doesnt really seem like we can catch air on the
  board"; built the same day). Flying, only the air's drag slows you, not the hover's,
  and you turn the board slowly to the sand below so it lands along it. Coming down,
  the hover brakes your fall evenly to meet the sand at its pace by ride height, about
  12 m/s² and never more than 36, so a landing from high up is a firm press, never a
  slam or a bounce. A jump hops 4 m/s up and the hop falls at 0.6 g; from a crouch it
  pops 1.5 m/s higher, so getting low into a crest, as pumping does, and jumping off its
  top flies furthest. At 1 g, before and after:
  - **A hop** on the flat: 0.76 m over ride height for 1.0 s, now 1.35 m for 1.4 s;
    from a crouch, 2.55 m for 2.0 s (it was no higher).
  - **Off the biggest crest** within 12 km of spawn, 43 m from crest to trough, pushing
    flat out with the wind (16.7 m/s at the top): 1.9 m for 0.8 s, now 5.0 m for 2.1 s
    and 34 m long. Over the small dunes by spawn, 1.3 m for 0.6 s, now 3.0 m for 1.2 s.
  - **Popping off that crest:** 16.5 m up for 4.6 s and 56 m long, landing at 3.7 g at
    most. Before, the same pop flew 10 m and landed at 39 g.
  - At 0.45 g (the dev gravity) a hop is 3.0 m for 3.1 s, a pop 5.7 m for 4.0 s, and the
    biggest crest 11.4 m for 4.2 s.
- **Its own battery.** It draws 40 W floating and up to 260 W more at full push (Power):
  a base battery lasts about twenty minutes flat out, about 23 km over the dunes. Out of
  charge, you step off. Outside a bubble the weather wears it like any device.
- **Frame-rate proof.** It's stepped 240 times a second inside each tick, your crouch,
  its tilt, its kicks and your stamina on it too. At its speed your view would stutter
  between ticks, so Feel draws you, and the board, its tilt and its turn, smoothed
  between the last tick and this one; the ticks never see it.
- The numbers are in Tuning's Hoverboard group.

### The patrol board: a superchassis (Agreed, session 4, part 3; not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); a novelty start's
centrepiece, proposed, and none of it is built.* The Daventry patrol board is a "heavily modded
military hoverboard: a camp in a board, its own bespoke superchassis" ([the
kit](../vision.md#player-origins-and-kits)). It carries a strong but narrow shield that "can
practically stay on permanently," a tow, a bedroll (sleep out storms under the shield), a compact
high-capacity battery, a small direction-finding radio and a tiny condenser. Its weakness is few
slots: "anything big still needs a camp."

The session's build note: the board "needs mount points for a shield, battery, radio, condenser,
bedroll and tow, as a chassis rather than special-cased slots. A narrow shield that stays on while
riding. This also generalises the existing board." [Devices & mods](devices-and-mods.md#the-patrol-board-as-a-superchassis-proposed-not-built)
has the frame's side.

Readings, not in the session:
- **The standard board stays as built.** "Generalises the existing board" is read as the same idea
  with more sockets, not a change to the board in this PRD: the kit's board, racked on a crate,
  still tows nothing, and the probes above are unchanged.
- **It would be the first board that tows,** against "It tows nothing" above, which keeps the
  board fun and out of the camp's way. The patrol board's camp is its own, so it may not compete
  with a real one, but the session doesn't say ([the
  clash](../lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)).
- **A shield that stays on while riding** is a bubble moving at board speed. It has a precedent:
  the light shield is meant to be "light enough to carry, switched on, while you walk or board" ([Bubble shield
  & camp](bubble-shield-and-camp.md#the-carried-light-shield-and-the-starts-not-built)). The
  patrol board's is seated on the board instead, strong and narrow. How a bubble this narrow
  behaves at board speed is not said.
- **Sleeping under the shield** is the sleep proposal's bubble, on a board
  ([Survival](survival.md#sleep-proposed)). The bedroll shares no rack here, since the board is
  the rack's occupant on a crate; the superchassis carries its own.

## Haulers: moving the base faster

The base gets faster through a progression of haulers:

1. **On foot,** from the start: reliable and slow.
2. **The mechanical beast.** Walking pace, but it carries a lot and follows you on its
   own. It's made of stiff parts, so it needs no skin rigging.
3. **The sand yacht.** The real fast base-mover. It runs on the wind, so it belongs in
   this world. It's fast with the wind, it can zigzag upwind (tacking), and a real land
   yacht can go faster than the wind itself. A good one might outrun a storm with the
   camp aboard. *Built as your own camp rigged to sail ([above](#sailing-the-camp-hunter-2026-10-17)):
   the light deck it's tuned on goes at a running pace, not yet past the wind or a storm's front.*
4. **Big carriers,** like the walker farmer, that carry the farm and the shield.

Early on you weather storms. Later, the yacht lets you choose between weathering one
and outrunning it.

### Sailing the camp (Hunter, 2026-10-17)

"Feeling the weight of your camp around your waist or in your hands is gonna be a really big
part of the game. the camp should be able to be used as a sail, especially when paired with
some sort of skates or board plate and actual sail mount... deep, fun, intuitive yet realistic
windsailing mechanics... it can be quite large." This is the vision's sand yacht, built from
your own camp's parts rather than found whole:

- **A sail mount and a sail.** A mast seats on a crate's top mount or a deck mount, and a large
  sail rides it. Raised, it catches the real wind; furled, it doesn't.
- **Runners: skates or a board plate.** Fitted under a crate or a deck in place of trays, they
  slide easily along their length and grip hard across it, as a land yacht's runners do, so a
  camp on runners sails across the wind and can work upwind, where a floating camp only
  drifts downwind.
- **Realistic, and felt.** The sail makes lift and drag by its angle to the apparent wind; its
  pull acts high up, so the camp heels in a gust and can tip; reaching is fastest, dead
  downwind is slower, straight upwind is impossible, so you tack. The pull reaches you down
  your lines: on foot or on the board, tied at your waist, your camp tows you.
- **Trimmed by its sheet.** The sheet is a line from the sail you hold or tie at your waist:
  reeling it in hauls the sail in, paying out eases it, so trimming is the reeling you
  already do.
- **Storms.** A raised sail in a storm is the danger it should be: reef or furl it, or it
  tears and the mast can snap.

**As built (2026-10-18, `game/devices/runners.gd`, `game/sail/mast.gd`, `probes/sail/`).**
- **The parts.** Three finds, each a `give` id: skates (`skates`) and a board plate
  (`board_plate`), which are runners, and a mast (`mast`) with a sail (`sail`) to fit it.
  All lie deep, the mast rarely, and a mast is found with its sail on it.
- **Runners** fit a bottom mount in place of a tray: under a crate, or under each piece of a
  deck. A device carries trays or runners, never both, and a refusal says "runners and trays
  don't mix"; a device standing on a deck takes none ("no runners on a deck"), and one
  with runners in is refused a deck mount with "take its runners off first". A deck's runners
  turn to its length, however its pieces sit on the grid. Runners draw no power. They ride the
  ground's one function, never the sand's collision: each corner of a runner's face reads
  `height_at` and is a spring on the sand that, with the others, holds up the load and settles
  it about 1 cm in; only the blades reach the sand, 5 cm below the frame they hang from (3 cm
  for the plate), so no lattice crease or chunk seam catches the body. Along its length a
  runner at rest holds a tenth of its load (skates; the plate 12%), and sliding it drags 3.5%
  and 3% more for each m/s (the plate 5% and 4%). Across, it ploughs: each corner takes out its
  sideways way as if its share of the load came to rest in 0.04 s, as far as its grip, 90% of
  the load for skates and 45% for the plate, so the plate skids sideways where skates bite.
  So a camp on runners is driven along them; a floating one only drifts.
- **The mast** seats on a crate's top mount or stands on a deck mount, from your hands like
  the shield. Stowed it's a 1.3 m pole, 8 kg; seated, it stands to 4.4 m over its mount. The
  sail, 5 kg, fits low on it, furled along its 2.3 m boom, and is 5.5 m² raised: 3.4 m up the
  mast, the boom's length along its foot, 1 m across its head. A camp sails the way it faces:
  seated, the boom trails behind its host.
- **Raising and furling** are use on the mast (its pole or the boom), 1.5 s each, with the sound
  of cloth. Off its mount, the sail comes down. Furled, the wind sees only the bundle on the boom.
- **The sheet** is any line whose end is on the boom's end, where the sail adds a tie. The wind
  swings the boom out to leeward until the sheet holds it: the sheet's inboard length says how
  far, as if it ran from the boom's end to a block on the camp below it. Reeling it, in your
  hand or at your waist, hauls the sail in a notch at a time (0.25 m, about 7° of swing), the
  line itself no shorter; paying out eases it, and once the sail is all the way out a notch
  pays the line out instead. A sail pulling harder than your strength (400 N) won't come in.
  With nothing holding the sheet's far end (dropped, untied, snapped) it runs, and the boom
  swings free and spills the wind; tied on again, it holds the boom where it is. With another
  line at your waist too, reeling works the one you look nearest along
  ([Rope & tethering](rope-and-tethering.md)), so you trim by looking at the sail.
- **The how-to** (2026-10-18, Hunter: "i need an explanation on trimming with the sheet at my
  waist"). The first time a sheet is at your waist, once a profile, a short how-to shows near
  the top of the screen for nine seconds, its keys as bound: "The rope from the sail's
  boom, its sheet, is at your waist: the shorter it is, the closer in the sail. Reel in trims
  the sail in, pay out lets it out. You steer by where you walk, as with a tiller." It says what the controls do, never
  how to sail well. The words are `Mast.HOW_TO_SAYS`.
- **The sail's push.** Lift and drag by the sail's angle of attack to the apparent wind, the
  felt wind less the camp's own way at the sail: lift rises to 1.3 at 18° and stalls past it,
  falling away to a flat sheet's, and drag grows from 0.05 to 1.8 square on, where it catches
  the wind as any face that size does. The push acts 1.5 m up the sail, a third of the way back
  along it, 2.6 m over the sand on a deck, so the camp heels. Held out by its sheet, the sail's
  twist goes into the camp through the sheet; swinging free, as in a gybe, only its drag
  against swinging, and brought up short by its sheet its swing slams into the camp. Lying over
  past 40° it fades, and past 70° it meets the sand, not the wind. Inside a running bubble the
  sail feels what the bubble lets through, like everything: nothing in a base shield's, 15% of
  the wind in a light shield's. Sail with the shield off; when a storm comes, furl it and put
  the bubble up, or run before the storm in clear air.
- **Points of sail.** The "sail" deck, 89 kg on skates, steered and its sheet tended, in a
  steady 10 m/s wind: dead downwind 3.4 m/s, under the wind's speed; a broad reach (120°) 4.5;
  a beam reach 4.3, sliding sideways 0.1 m/s; a close reach (70°) 2.9; close-hauled at 60° 1.9,
  making 1.0 m/s upwind. At 50° it can't get going from rest: bear away to build speed, then
  head up. Head to wind it makes no ground, blown back 0.7 m/s, so you tack. On a plate the beam
  reach is 2.9 m/s. A 6 m/s breeze is too light to start it; at 14 m/s it heels 12° and must be
  eased to hold a beam reach, at 4.6 m/s.
- **Heel and capsize.** In 10 m/s on a beam reach its windward blades unload and it leans under
  a degree or two. A 12.5 m/s gust with the sheet made fast lifts its windward runners, leaning
  it 3 to 5°, and it comes back down as the gust passes. In an 18 m/s blast held to its course it
  goes over, 3.9 rad/s at most, and comes to rest lying on its edge and its mast: the
  masthead and the boom's end meet the sand, and whatever stands on a tipped device rests on
  its frame's corners, so nothing it carries goes through. You right it as you right anything:
  take hold of it and rotate.
- **Steering is by where you pull.** A line pulls the end of the camp it's tied to toward you.
  The sheet is on the boom's end, which trails behind and to leeward, so the camp's tail
  follows your pull and its bow swings away, as with a tiller: towed straight behind, you hold
  it on its course; swing out to its windward side and it bears away, to its lee and it heads
  up. A line from a ring at its bow steers the other way round, like reins. Taking hold of it
  and rotating turns it as you'd turn any camp. Left to itself with its sheet made fast, a camp
  on the "sail" deck rounds up gently into the wind and stops: its crate to windward drags its
  windward runners a little harder.
- **Towed on the board.** Stepping onto the board, a sheet at your waist stays tied, while any
  other line at your waist is untied first, as before. Towed, the board runs where the line
  leads and your keys carve; it pushes and kicks against no line, so it still tows nothing.
  Reeling works riding, so you trim the sheet as you go. On the "sail" deck in 10 m/s, with the
  sheet tended, the camp tows you at 3.5 m/s on the end of the sheet.
- **Storms and breaking.** A raised sail tears by the wind it stands in, drawing or luffing or
  lying over: past 600 N of load (what a 20 m/s wind does to it raised, or a reach drawing hard
  at 18 m/s) it loses a fifth of its cloth a second for each share past that, shrinking its
  area, and below 15% it's rags. Its mast snaps past 1,000 N of pull felt for 0.05 s: a raised
  sail drawing in a 24 m/s storm, or broadside in 22 m/s. A furled sail takes no harm. Both sit
  under a line's 1,500 N and a stake's 2,500 N, so a camp moored with its sail up loses the
  sail, then the mast, before its line or its stake. The weather wears the mast as any device.
- **Saves** keep the mast's raise, its sheet's trim, the boom's swing and the loads, and the
  sheet as a line; a resumed rig sails on within a centimetre of one never saved (6 mm after 4 s). No frame
  changed, so older saves load as before.
- **Stability.** Physics ticks only. The runners hold the load up together, solved for the
  body's rise and tilt at once, and plough by the way it went before anything pushed it this
  tick, so a reach sails the same at 30, 60 and 120 ticks a second (2.938, 2.938 and 2.936 m/s,
  51.2 m in 20 s each). In four minutes back and forth in gusts, over eight chunk seams and
  through three origin shifts, no tick changes its way by more than 0.12 m/s, it never spins
  faster than 1.2 rad/s, leans 7° at most and never touches the sand but by its blades.
- **Cost.** About 100 µs a tick for a deck's runners and 80 µs for its sail, measured in the
  probes on a loaded machine; a camp on runners spends nothing floating.
- **The "sail" scenario** stands you on level open sand in a steady 8.5 to 11.5 m/s breeze out
  of any lee, facing across it with the wind on your left. Ahead stands a deck two pieces by
  two on skates, the mast and its furled sail on its front piece to windward, a crate with two
  batteries behind it and a shield, switched off, behind to leeward; the sheet runs from the
  boom's end to your waist, eased to let the boom out 75°, and a charged board lies at your
  feet. Use the mast to raise the sail, step on the board, and reel in as it picks up speed.
- **Sailing probes** (`probes/sail/`): 1, runners sail across the wind where a floating camp
  drifts; 2, no ground straight upwind, ground on either tack; 3, the sheet trims the drive and
  reeling hauls the sail; 4, it heels in a gust and recovers, and a blast puts it over
  smoothly; 5, a raised sail tears in a storm and a furled one doesn't, and a blast snaps the
  mast; 6, your camp tows you on the board; 7, nothing flings, and it sails the same at any
  tick rate; 8, furling in a breeze never tears the sail, and it raises again (Hunter: it
  couldn't be raised once brought down: the furled bundle's drag over the last of the cloth
  showing read as a tearing load). Profile & saves probe 16: a rigged camp resumes.

### The dune sailboat (Agreed, session 4, part 3; not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); the Varran settler's
centrepiece, proposed, and none of it is built.* "Dune sailboat: slow hauler for hybrid play." It
is "a wind-driven slow hauler that reads the wind vector already in the world," with "tow capacity
well above the board." The kit that carries it is fragile, needs wind and has low-quality parts
([the kit](../vision.md#player-origins-and-kits)).

Readings, not in the session:
- **The wind vector is `wind_at`,** the prevailing wind plus gusts and a front's outflow. Rule 2
  below has movement read the felt wind, so the sail works outside a bubble, where the wind is.
- **It is not the sand yacht.** The list above makes the yacht the late "real fast base-mover,"
  fast with the wind and tacking upwind, and a good one might outrun a storm. The sailboat is
  slow. Whether it is the yacht's early form, a rung between the beast and the yacht, or another
  craft is not said, and Wind & storms probe 7 (the sand yacht) is unchanged.
- **"Build and use" is the kit's unlock** ([Profile & saves](profile-and-saves.md#kits-are-data)).
  Parts are found, never crafted, so building is read as fitting found parts, and no PRD has the
  sailboat's frame yet.

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
at 8 s or 12 m. Each comes once and stays up however your way swings, until you're
clearly back in range: a quarter further from the edge than where the first came. Cross
the edge and the camp is forgotten right there, not whenever streaming gets round to
its chunk, and you're told what was lost, once; then it's quiet. Flat out on the board
that's the first warning about 400 m before the edge, so a couple of hundred metres from
camp, and the last 160 m before it; braking and turning back takes about 20 m. The look
is a skeleton's, until the open question below is answered: a chime (three quick beeps
for the last, a falling tone for a loss) and one line of text at the top of the view,
"Leaving camp range · lost in 18 s", "LAST WARNING · camp lost in 6 s · turn back",
"Camp lost · Crate frame". The line counts down once the edge is 20 s off at your pace,
and gives the distance, "LAST WARNING · camp 140 m from the edge · turn back", once
it's 40 s off: you've turned back or stopped, not carved. The numbers are in Tuning's
Camp range group.
*After Hunter's ride (2026-10-16: "the timer popped so many times"), built the same
day.* A warning used to re-arm whenever your way swung off the edge or you slowed, so
carving out from camp fired it again, chime and all, and the line dropped and came
back; past the edge it said "lost in 0 s" until streaming let the camp's chunk go,
seconds later on a busy machine.

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
- **The dune sailboat and the patrol board's superchassis** (proposed above; the third and fourth
  pieces of the proposed build order in the [skeleton
  plan](../skeleton-plan.md#waiting-for-the-full-version)).
- **The board's feel and sound,** polished.

## Probes

1. **The long ride.** Ride 20 km of dunes, slip faces and chunk seams at top speed. The
   board never dips below the sand, never launches unexpectedly, and never jitters.
   Unexpectedly means off a bump, a seam or its own landing: off a big crest at speed
   it should fly. *(Built: half across the ridges with the wind and against it, half
   wandering, over 408 chunk seams, 18.6 m/s on average. The underside never came
   nearer the sand than 7.0 cm; 59 launches, every one off a crest, at most 4.9 m over
   its ride height and 2.0 s long, none within half a second of a landing; no judder;
   the hardest moment 5.0 g; the ground solid under you all the way. Before the air, 55
   launches, at most 1.9 m and 0.7 s, and the probe allowed 3 m; it now allows 8 m and
   counts bounces.)*
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
   camp is lost and you're told, within 0.1 s of when the last warning's countdown said.
   Turning back flat out at the last warning, you come no nearer the edge than 139 m.
   Carving flat out from side to side on past the edge, each warning comes once, the
   line never drops or changes its form, the loss is told once, and for 30 s after it
   nothing is up and nothing chimes.)*
6. **Frame-rate proof.** The same ride at 30, 60 and 120 frames per second follows the
   same path. *(Built: kicks from rest, a push, a carve, a hop, a drift, a coast and a
   brake over 85 m: the same path to a tenth of a millimetre, with the same charge and
   stamina left, and the same path to the bit with the drawing switched off.)*
7. **Origin shift at speed.** Riding across an origin shift at top speed causes no hitch
   and no jump. *(Built: flat out in real time at sixty frames a second, ruins and finds
   laid out as you go, across four shifts in 1.1 km: your way changes no more at a shift
   than anywhere, the ground stays solid 120 m ahead, and no frame spends longer than
   0.9 ms streaming headless, against the 2.0 ms line: 1.1 to 1.4 ms before a chunk's
   collision came in quarters (World & terrain, 2026-10-18). In a real window at
   144 Hz (`look/stream`, which now rides a board flat out downwind too) the worst was
   1.21 ms over 410 m; the ring of collision round you came up short for a moment after a
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
    30 s, 544.3 m against 540.1 m, +0.8%; the wrong way round 536.0 m.)*
18. **The drift.** A hard turn crouched slides further out and keeps more speed than the
    same turn skidding, and standing up grips again. *(Built: from 19.4 m/s, out at
    16.6 m/s against 12.9, sliding 60° against 46°.)*
19. **The tilt settles.** Flat out across the ridges, carving hard each way, the board's
    pitch and lean never jump. *(Built: at sixty ticks, the lean at most 2.9° a tick, the
    pitch 1.4°; before, the lean snapped up to 60° and the pitch moved up to 1.8°. Since
    the board catches air it flies the slip faces it rode down, so the probe heads into
    the wind first and climbs them: the pitch moves 1.75° a tick at most, climbing into a
    slip face's foot, as it did before the air; the lean 2.4°.)*
20. **Catching air.** A hop flies over a metre for more than a second, and from a crouch
    it pops higher; off a big crest flat out the board flies 1.5 s or more, 3 m or more
    up; and landing, pushing or popping off the crests, it never slams, bottoms out or
    bounces. *(Built: the numbers are under Air, above; the hardest moment flying or
    landing is 3.7 g.)*

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

Session 4, part 3 (2026-10-17) adds three. Each is quoted on both sides and left standing.

- **The board's tow.** Here: "It tows nothing. That keeps it fun, and it keeps it from competing
  with the camp." The session: the patrol board has a "Tow," and the sailboat's "tow capacity
  [is] well above the board." Not said whether the standard board towing something small is
  meant, or only the patrol board; this PRD follows the second.
- **A slow sailboat against a fast yacht.** Here: the yacht is "the real fast base-mover" and
  "might outrun a storm with the camp aboard." The session: a "slow hauler." Not said how the two
  relate.
- **A moving bubble.** Here: riding you "take only loose things on no line," and the notes want
  the light shield "light enough to carry, switched on, while you walk or board." The session: "a narrow shield
  that stays on while riding," seated on the board's superchassis. Not said how it is mounted or
  how a bubble that narrow rides at speed.

The sleep session (2026-10-17) adds one. It is quoted on both sides and left standing.

- **The rack against a bedroll.** Here: a crate frame has one rack, along its left side, holding
  one thing, and every run starts with the board racked on it. The session: bedrolls, "probably
  sharing the hoverboard's mount slot on a crate." Not said: whether sharing means swapping (take
  the board off to rack the bedroll), a second rack, or a bedroll small enough to ride beside the
  board; how big a bedroll is; or whether a Console, a crate variant, keeps a rack. The board was
  fitted to clear everything a full crate holds by bounds (survival probe 9), and a bedroll would
  need the same.
