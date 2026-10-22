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
- **Auto-walk** (Hunter, [2026-10-18 spec](../briefs/storms-signals-sailing-2026-10-18.md)). It holds
  your heading while you steer by the compass or other instruments, so a storm still lets you
  make long-range progress.
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

**Auto-walk, built (2026-10-18, `game/player/auto_walk.gd`, probe 21).** Its own action turns
it on and off. It holds the way you faced when it began, not the camera, so you can look round,
read the compass in your hand or watch the storm and keep going the same way. It only gives
your walk its way: the same pace, stamina, slopes, slides and wind, a sprint while you hold
sprint, and against a line at your waist you dig in as usual. It ends when you move yourself (a
move held as it began counts once you've let it go), turn it off, walk into something solid
near head-on, start up a face too steep to stand on, get on the board, a line at your waist goes
taut against a stake or anything else held fast behind you, you die, or a menu or the console
comes up. The inventory doesn't end it. A small chevron low in the view says it's on and points
the way it holds as you look round. Saves don't keep it: a resumed run starts with it off.

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
- **It overloads before becoming a hauler** (Hunter, 2026-10-19). Slack sailing lines allow free powered catch-up; a tiny loaded rig crawls, and a big load grounds the hover and makes its motor sputter. The rider may race ahead, swing the rig and counterbalance it with real momentum. This supersedes the earlier blanket no-tow rule.
- **It travels on the camp** (Hunter, 2026-10-16: "i like a rack"; the rack went with the
  crate, 2026-10-18). Stuck on a deck, hung on an upright as often as not, it rides wherever
  the deck goes and charges from the camp's power, after the shield. Pack up and walk with the
  camp, and the board comes; take it off to scout.
  When the shield dies deep in a storm, you take what's in your hand and go. Before you
  find a board, a shield failure deep in a storm is fatal, so early runs stay in
  shallow storms and carry spare batteries.

**Built (2026-10-16, Stage 10, `game/board/`).**
- **A find.** The board is a catalog device in salvage's deep layer, one in nine of its
  devices, found buried on end, nose down. Its battery sits at its nose and comes filled
  like any deep find's; its port charges it from a cable. The "board" scenario
  lays a charged one of every make at your feet.
- **On and off.** The ride action steps you onto the board in your hands, the one you
  look at, or the nearest at your feet, if it has charge, and steps you off again,
  keeping your way: faster than you can run, you skid, and the board goes on as a body.
  For safe boarding, a line or a grip in your hands is let go, a line at your waist is
  untied first (it takes its moment) and you step on once it's free, and riding you
  take only loose things on no line. A sail's sheet at your waist stays tied, so your camp
  can tow you. The same holds for a camp's line beside it, which its rig tows past you
  ([stage 2](#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)). Limited motor
  work against those lines was approved on 2026-10-19; see powered sailing below.
- **On a deck** (2026-10-18, replacing the crate's rack). The board sticks on any sticky face
  of a chassis it fits, flat on its underside: across a deck's top, or hung on an upright's
  face ([Devices & mods](devices-and-mods.md#the-chassis-as-the-one-structure-built-2026-10-18)).
  Held to the face it's shown there itself, and take leaves it; take lifts it off again, whole.
  Stuck, it rides held fast wherever the deck goes, its 11 kg join the deck's hover load, and it
  charges from the deck's pool after the shield (Power). You can't ride it stuck: the ride action
  at a board on a deck takes it off and steps you onto it, as the ride action at any board you
  look at puts it under your feet. It saves and resumes where it was stuck. Every Surveyor run
  starts with the board hung across the kit's upright (Hunter, 2026-10-16: "i think it should
  start you w a *racked* hoverboard"; Survival).
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
    the sideways moves still carve while it brakes. *Replaced by the dig on 2026-10-18
    ([below](#dig-and-carve-agreed-2026-10-18-spec-built)).*
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
    back within 8° of your way. From 19.4 m/s, a hard turn standing skids round 81° in
    1.18 s and comes out at 14.3 m/s, sliding 50° at most (1.05 s, 12.9 m/s and 46° before
    the [skid](#the-rides-feel-and-boards-by-make-hunter-2026-10-18-built)); drifting it comes
    round in 1.38 s at 16.7 m/s, sliding 61°.
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
  and you turn the board slowly to the sand below so it lands along it (since 2026-10-18 it
  [flies true](#the-rides-feel-and-boards-by-make-hunter-2026-10-18-built) instead). Coming down,
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

### The ride's feel, and boards by make (Hunter, 2026-10-18; built)

"slide on hard turns and landings, not just brakes. orient the board properly when in the air and
taking off. allow for hard landing and turn skidding. consider crashes. lets also add some variety
to the look and feel for diff makes of boards. lore accurate. more sounds and audio queues too"
- **It slides:** a hard carve past its grip skids sideways, and a landing at speed or at an angle
  slides out before it bites, not only the dig's stop.
- **It flies true:** off a lip the board pitches with its path and rolls with its carve, and in the
  air it eases toward the way it's going; it lands on the slope it meets.
- **Hard landings and crashes:** a landing too steep, too fast or crossed slides out, jars you, or
  past worse throws you off as the dig's wipeout does; a crash into something solid at speed is a
  wipeout too, gentle in cost.
- **Boards by make:** each era and maker builds its own, true to the lore (the hoverboard is
  skimmer-culture gear; a colonial issue board, a knights' patrol board and the second age's
  temple-made ones differ): their looks, weight, grip, top speed, hover height and sound differ as
  data on one ride.
- **It sounds like riding:** carve and skid hiss, lip pops, landings by how hard, wind rush with
  speed, the hum by make, and a knock on a crash.

**Built (2026-10-18, `game/board/ride.gd`, `game/board/makes.gd`, `game/board/ride_sound.gd`,
`game/player/feel.gd`, `game/look/dress.gd`, `probes/movement/` 25 to 29).** The dig, its hockey
stop and the crouch drift ride as they did.
- **The skid.** Standing, a carve the hover can't hold breaks loose: at 7 m/s or faster, once the
  board points 12° off your way, it skids, its hover keeping 0.9 of its grip, and a full sideways
  skid bleeds 0.6 of its speed a second where the scrub before it bled all of it. It slides on
  while you turn into it and bites again once it comes back within 5° of your way. It can't skid
  dug past a third, drifting, stopping, braking or towed. Flat out, turning your view at 0.4 rad/s
  it grips; at 1.6 rad/s it breaks loose in 0.35 s and holds 29° to 43° off its way for 2.2 s of
  2.5, out at 11.4 m/s, and straightened bites in 0.4 s. The hard turn from 19.4 m/s now comes
  round in 1.18 s at 14.3 m/s, sliding 50° (1.05 s, 12.9 m/s and 46° before); the drift still
  slides furthest and keeps the most, 61° and 16.7 m/s.
- **It flies true.** From 0.25 m over its ride height it flies free, all of it 1 m higher: its
  pitch eases toward its path's at 2.5 Hz (5 Hz on the sand), nose up as it rises and down as it
  falls (less below 6 m/s along its nose, never past 35°); it levels across, and it leans with how
  fast you turn it in the air, so it rolls on with a carve. With nothing steering it, its nose
  comes round to its way at 1.2 rad/s. Coming down, over the last 0.6 s before the last 0.15 s,
  it turns to the sand where it'll meet it. Popped from a crouch at 19.7 m/s, its nose rises
  9.8° and falls 7.0°, 2.2° off its path on average, and it lands 0.5° off the sand's slope;
  turned 30° off its way at the top, it lands along it. Flying it grips nothing: its hover takes
  the sand again 0.4 m over its ride height, which is when it has landed. Your view leans with
  the board as you see it from where you look (0.35 of its lean and its lie across the sand), so
  a board across your way leans your view less.
- **Landings.** How hard it lands is the fastest it came down at the sand while it flew (the
  hover's cushion still brakes it, so height alone is soft), counted harder crossed: up to twice,
  sideways at 10 m/s or more. A landing knocks the hover's grip loose by as much, up to 80% of it
  at the jar, coming back over about 0.6 s, and while it's loose a slide breaks loose from 5°:
  crossed 25° from a 12 m drop flat out it slides 2.19 m across before it bites, in 0.57 s,
  against 1.62 m in 0.37 s for the same crossing on the sand. Past 9 m/s it **jars** you: a shake,
  a slam and a burst of sand. Past 15 m/s it **throws you off**, the dig's wipeout (5 health, 25
  stamina, never your last). A 1 m drop lands at 4.2 m/s; 12 m, 10.3 straight and 14.5 crossed
  25°; over the long ride's 20 km the hardest was 8.0, pushing off the biggest crest 6.8, and
  popping 16.5 m off it 12.8, which jars and holds. Landing crossed is the mistake that throws you.
- **Crashes.** Into something held fast or 12 kg or heavier (a ruin wall, a wreck, a deck, a crate)
  faster than 7 m/s, all of your way into a wall or a slope's share of it, throws you off, and so
  does sand rising into it faster than its hover lifts it, head on into a face, which the long
  ride never met. Lighter things you shove. The board bounces back off what it hit by 0.3 of the
  speed it hit with. Head on at 18.5 m/s you're thrown and it comes back at 5.5 m/s; at a crawl
  the wall only stops you, and at a glance, 4.8 m/s into it, you slide along at 17.3 m/s.
- **Boards by make** (`BoardMakes`). A make is its catalog id, so a save keeps it as it keeps any
  thing, and every make has the issue's box and rack seat. Its ride is shares of the Hoverboard
  tuning; its look is Dress's; its lineage's marks go over it as over anything.

  | Make | Provenance / attribution | Weight | Flat out | Rides | Grip and skid | Landing | Draw | Hum |
  |---|---|---|---|---|---|---|---|---|
  | Hoverboard (`board`) | Tilg & Standard's present-day issue: the colony's yard and survey board, still the company's standard. Gunmetal, teal and safety yellow, with its current batch stencil on the tail; a deep colonial find carries the older TILG consignment stencil, from before the successor company existed. | 7 kg | 20 m/s | 0.35 m | grips 18 m/s², skids keeping 0.9 and bleeding 0.6 | jars at 9 m/s, throws at 15 | 40 W + 260 W | the hover's own |
  | Skimmer racer (`racer_board`) | The skimmer era's own: light, cheap imports H-Town's crews raced while Zan wasn't a desert; narrow and pointed, a kicked tail, hand-painted crew red with a pale stripe, tape round its rails, three small pads, the crew's patch on its tail | 5.5 kg | 23 m/s | 0.42 m, springier | grips 15.3 m/s², breaks loose soonest and skids longest, keeping 0.72 of it and bleeding 0.39 | throws you sooner (0.85 of the thresholds), slower to bite | 1.1 times | a thin bright whine |
  | Patrol board (`patrol_board`) | The Knights Requisitioner's, the Ledger's armed auditors, ridden ahead of the crusade's water convoys: wide and plated, olive armour down its rails, a steel bumper lashed with cord, its deck the order's grey with their daubed sign, as on their hopper, and a stencil on its tail, every crate accounted for; four dim pads | 11 kg | 18 m/s | 0.30 m | grips 22.5 m/s², skids short and scrubby, keeping 0.99 and bleeding 0.78 | sturdiest (1.3), bites back fast | 1.15 times | a deep pulsing thrum |
  | Temple board (`temple_board`) | Made at Mother Cistern's temple: an old hover core under saltbush planks lashed with fern cord, a round ceramic cap on its nose in her blue glaze, the sign of Tu on a limewashed patch, a water vial and a tassel | 9 kg | 17 m/s | 0.46 m, the softest spring | grips 17.1 m/s², slides soft, keeping 0.81 and bleeding 0.48 | the biggest cushion (1.35), sturdy 1.1, slowest to bite | 1.25 times | a soft hum with a ceramic ring |

  The makes are readings: the lore calls the hoverboard skimmer-culture gear and names the
  Knights Requisitioner and the Cistern's temple, and says nothing of their boards; the numbers
  are defaults, all but their order. Lineage still
  sets the era's numbers: a racer found in the skimmer era's ruins weighs 0.7 of that and wears
  out twice as fast. On the flat flat out the racer does 22.5 m/s 0.43 m off the sand and the
  patrol board 17.7 m/s 0.30 m off; carving at 1.4 rad/s the racer breaks loose in 0.32 s and
  slides 54° off its way, the patrol board holds within 6°.
- **Where they're found.** The issue on the colonial era's floors and loose in the deep layer, as
  before; racers in the skimmer era's floors and best, a wreck hull's best among them; patrol
  boards in a watchtower's cache and as a Knights' hopper's best; temple boards among the second
  age's best. The Salvager starts with a new racer, plain; every other run racks the issue. The
  `board` scenario lays one of each at your feet. The patrol board's superchassis is still
  [proposed](#the-patrol-board-a-superchassis-agreed-session-4-part-3-not-built): the Knights' board
  is a make of the one ride, not the Daventry kit.
- **Sounds** (`RideSound`, made here, `assets/audio/make_board_sounds.py`): each make's hum, rising
  with speed, sagging as the battery dies, dropping under a dug edge; a carve's hiss as hard as the
  hover holds you round; the slide's hiss and its rooster tail of sand off a skid, a drift or a
  landing's slide, as a dug edge's (Feel); the wind's rush with speed; a pop off a lip or a hop; a
  landing by how hard, a slam past the jar; a scuff as a skid bites again; a knock and a thud on a
  crash. The battery says "do-doo" once a minute from flat at full push and lower, once, 15 s from
  it, in place of the low-battery ticking (`Sounds.battery_low` and `battery_critical`; the hum's
  sag is the tell between).
- **Frame-rate proof.** All of it steps with the ride at 240 Hz: the extended route, with a skid, a
  pop turned in the air and a crossed landing sliding out, follows the same path to a tenth of a
  millimetre at 30, 60 and 120 ticks on the issue (165 m) and on a racer (180 m).
- **Saves** keep a make. They don't keep a skid, a landing's loosened grip or a flight under way: a
  ride resumed mid-skid starts gripping.
- **Tuning:** `board_skid_speed` 7, `board_skid_grip` 0.9, `board_skid_drag` 0.6, `board_air_hertz`
  2.5, `board_land_jar` 9, `board_land_throw` 15, `board_crash` 7; the makes in `BoardMakes.MAKES`.
  The look-test `look/boards/shoot.sh` shoots each make, a skid, a hard landing and a pop's pitch.

**Playtest (Hunter, 2026-10-19; agreed, built).** "Hover boards are feeling better, but
skidding should leave deep marks, and is it still possible to fall off the board? i liked that
feature. just make it clear youre really tumbling."
- **A skid gouges the sand:** deep, wide marks where the board slides sideways, plainly more than a
  carve's line, kept the way tracks are.
- **Falling off is kept,** and reads as a real tumble: your view rolls and tumbles over the sand
  with you, sand thrown and thuds as you hit, before you come to rest. Falling off still happens on
  a landing past the throw, a crash and the edge catch.

**Built (2026-10-19, `game/player/tumble.gd`, `game/world/tracks.gd`, `game/player/feel.gd`,
`game/player/player.gd`, `probes/movement/` 30 and 31).**
- **The gouge.** Wherever the board slides across its way on the sand (`Ride.slide_across`: a skid,
  a drift, a landing's slide, a dug edge dragged across in a stop) at 1 m/s across or more, its hover
  shoves the sand out from under its whole length: the tracks press all it swept since the last
  tick, its walls sloping over half a metre. It's as deep as the slide is hard, all of it from
  6 m/s across and never under 0.4 of that: twice a footprint at its deepest, drawn 12 cm down where
  a footprint is 6 cm (the sand shader's marks now go to twice a full one). The tracks keep and
  heal it as any mark, so it takes twice a footprint's time to fill: three hours in calm air, forty
  minutes in a full storm. Flat out, the carve the hover holds leaves its line 0.25 of a footprint
  deep and 0.65 m wide; turned hard enough to skid, a gouge 2.0 deep and 2.1 m wide. The tracks'
  tick, gouging, takes about 1 ms at worst.
- **The tumble.** Thrown off, you let go of what you held and tumble on over the sand with all of
  your way, toward the board's low side, off a wall bouncing back at 0.3 of what you hit it with.
  You go over onto the sand over 0.3 s; each time you come down at 1 m/s or more you hit it, which
  takes 0.4 of your way and throws you into the next roll at a quarter of what's left (2.4 m/s at
  most), and below that you plough to a stop at 1 g. You roll over at half a radian a second for
  each m/s of your way, never more than three quarters of a turn a second, and down on the sand you
  roll onto your nearer side. At rest you lie 0.5 s, then get up over 0.6 s; until you're up you
  can't move, look about or step back on. Something solid
  in the way stops you as it would on foot. The cost is the wipeout's, unchanged: 5 health, never
  your last, and 25 stamina.
  - An edge caught in a flat-out hockey stop throws you at 13.5 m/s: three hits, rolled three
    quarters of a turn, 9.7 m and at rest in 1.42 s, up 1.1 s later.
  - A landing past the throw at 15.4 m/s: three hits, 10.8 m in 1.48 s; flat out, 16.6 m/s, 12.3 m
    in 1.62 s.
  - A crash head on at 19.2 m/s: back off the wall at 5.8 m/s, one hit, 3.2 m in 0.87 s.
  - It steps at 240 Hz inside each tick, as the ride does: from the same throw it goes 13.3719 m at
    30, 60 and 120 ticks.
- **Your view** goes over onto the sand with you, your eyes 0.25 m over it lying, and rolls with
  your body, but never past 75°: rolling on, it pitches into the sand instead, as far as 60° face
  down, so it never turns over however you do, and righted as you get up. Options has no motion
  setting, so the roll stays bounded for everyone. Each hit thuds by how hard (`tumble_a.wav`,
  `tumble_b.wav`, made here in `make_board_sounds.py`, CC0), throws a burst of sand up ahead of you
  along your way, shakes your view and leaves your body's imprint, 1.6 by 0.5 m, in the sand;
  ploughing to a stop you hiss, spray sand and groove it as a slide does.
- **The board tumbles away on its own,** a body again: it keeps a quarter of its way, pops up
  2 m/s and spins over its edge and end over end.
- **Yard Sale** (hidden, Board, after Big Air): tumble 12 m in one wipeout, recorded by the tumble
  as it goes (Profile & saves). Near flat out it's yours; an edge caught in a stop isn't enough.
- **Not saved:** a save mid-tumble resumes you on your feet. The look-test `look/tumble/shoot.sh`
  shoots a skid's gouge beside a carve's line and a tumble through your eyes and from behind.

### Dig and carve (agreed, 2026-10-18 spec; built)

From Hunter's [storms, signals & sailing spec](../briefs/storms-signals-sailing-2026-10-18.md). The board's feel stays (never sinks, gets
air, crouch pumps, kick, carving, the drift); move back becomes the **dig**: one edge drops so the
hover field bites the sand, trading speed for sideways grip with a big spray. Moving back while
steering digs into the carve; alone it swings the board sideways to a hockey stop. Digging past
what the speed and slip allow catches an edge: a stumble off the board and a knock. The dug edge
resists the sideways pull of a tow, which is what lets a kite-towed board tack. It lives or dies on
its feedback: a rooster tail of sand off the dug edge, the board tilting, a little camera roll, the
hum dropping under load with a gritty hiss growing, a whoosh on release, a small shake as the edge
bites and a bigger one as it catches. Open then: the catch threshold and what a wipeout costs,
both answered below.

**Built (2026-10-18, `game/board/ride.gd`, `game/player/feel.gd`, `game/board/board.gd`,
`probes/movement/`).** The rest of the ride is as it was; move back's flat brake is gone.
- **The dig** is how deep one edge is in the sand, 0 to 1, following move back over about
  0.2 s (a stick held partway digs partway). Dug, the field rides 0.3 m lower and the low
  edge comes down to 1 cm off the sand, never into it (1.7 cm at most in a dug carve,
  against 27 cm standing). Its edge takes out your way across the board: slicing along its
  length it holds 2.5 times the hover's grip, 45 m/s², and dragged across, as in a stop, no
  more than the hover's 18. The sand drags a quarter of your speed a second at full dig,
  and dug you don't push. The board leans with the edge's pull as with a carve's.
- **Into a carve** (move back while steering) it bites: from 19.4 m/s a hard turn comes
  round 81° in 0.67 s at 8.9 m/s, sliding 21° at most, where standing it skids round in
  1.05 s at 12.9 m/s, sliding 46°.
- **The hockey stop** (move back alone). The board swings across your way at 5 rad/s,
  faster than its hover follows, its hover letting go, and the edge digs in as it comes
  across: from 13.4 m/s you stop in 0.78 s and 5.8 m on your line (14 cm off it), never
  reversed, whichever way you look; coasting goes 66 m. From rest it does nothing.
  Steering back against your way keeps the flat brake, 8 m/s²: looking back at the storm
  flat out must never dig in or throw you, and a skid alone couldn't stop a board sliding
  back down a slope to push it up again.
- **Catching an edge.** The edge's load is dig times your way across the board; past
  6.5 m/s it catches. A full hockey stop loads it to about 0.38 of your speed, so it holds
  up to about 17 m/s and catches flat out (7.3 from 19.4 m/s); a cruise loads it to 4.0. Tapping
  move back, or carving the speed off first, keeps it under. Digging into a carve barely
  loads it, since the edge grips.
- **A wipeout costs** a knock, gently: the board stops in the sand and you're thrown on,
  tumbling ([since 2026-10-19](#the-rides-feel-and-boards-by-make-hunter-2026-10-18-built); till
  then you slid on your feet with 60% of your way); you lose 5 health (unharmed, it's back in
  a minute; a knock never takes your last) and 25 stamina; the board keeps a quarter of its
  way, pops up 2 m/s and tumbles behind you, a body you walk back to. Nothing is lost or
  broken. The numbers are Tuning's `board_dig_catch`, `board_wipeout_hurt` and
  `board_wipeout_winded`.
- **Towed** (a sail's sheet, a kite), a line's pull drags the hover's grip out from under
  it, so only the dug edge holds against the line's sideways pull, and left alone the board
  trails its own way (a camp tows you at 2.8 m/s held across the wind; it towed you at 3.5 before
  the dig, 3.3 before its sail's twist reached it whole). Pulled 3 m/s² downwind
  with the board steered 60° across, undug it runs straight downwind at 2.9 m/s; dug in it
  holds its line 60° across at 3.8 m/s, 34 m in 10 s. That's the tack.
- **Feedback,** drawn and heard, never fed back. A rooster tail of sand off the dug edge's
  length, thrown up and outward, away from where the edge pulls the board (ahead of you in
  a stop), left behind as you go: bigger, faster and higher the deeper and faster
  you dig, most dragged across (thicker, not more grains: it's the slide's spray, 192 grains
  riding). The slide's
  hiss grows with it. The hover's hum drops up to 28% under the dig's load, and letting a
  deep dig out at speed whooshes (the throw's sweep, low). Your view rolls with the board's
  lean as it does carving; a small shake as the edge bites (dug past half at 5 m/s or
  more), a big one, a lurch and a thud as it catches.
- **Frame-rate proof.** All of it is stepped with the ride at 240 Hz: a dug carve and a
  hockey stop stop in 3.3901 m at 30, 60 and 120 ticks, on the same path to a tenth of a
  millimetre (2.952 m since the ride's feel, its route longer). Saves keep the dig.
- **Tuning:** `board_dig_grip` 2.5, `board_dig_drag` 0.25, `board_dig_depth` 0.3,
  `board_dig_catch` 6.5. The look-test `look/dig` shoots the spray at three depths, the
  stop and the lean.

### The patrol board: a superchassis (Agreed, session 4, part 3; not built)

*Session 4, part 3 (lore session); a novelty start's
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

Historical readings, not in the session (the ordinary-board towing restriction below is
superseded by Hunter's 2026-10-19 powered-board decision):
- **The standard board stays as built.** "Generalises the existing board" is read as the same idea
  with more sockets, not a change to the board in this PRD: the kit's board, hung on its deck,
  still tows nothing, and the probes above are unchanged.
- **It would be the first board that tows,** against "It tows nothing" above, which keeps the
  board fun and out of the camp's way. The patrol board's camp is its own, so it may not compete
  with a real one, but the session doesn't say ([the
  clash](../world/lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)).
- **A shield that stays on while riding** is a bubble moving at board speed. It has a precedent:
  the light shield is meant to be "light enough to carry, switched on, while you walk or board" ([Bubble shield
  & camp](bubble-shield-and-camp.md#the-carried-light-shield-and-the-starts-not-built)). The
  patrol board's is seated on the board instead, strong and narrow. How a bubble this narrow
  behaves at board speed is not said.
- **Sleeping under the shield** is the sleep proposal's bubble, on a board
  ([Survival](survival.md#sleep-proposed)). On a deck a bedroll sticks beside the board; the
  superchassis carries its own.

## Haulers: moving the base faster

The base gets faster through a progression of haulers:

1. **On foot,** from the start: reliable and slow.
2. **The mechanical beast.** Walking pace, but it carries a lot and follows you on its
   own. It's made of stiff parts, so it needs no skin rigging.
3. **The sand yacht.** The real fast base-mover. It runs on the wind, so it belongs in
   this world. It's fast with the wind, it can zigzag upwind (tacking), and a real land
   yacht can go faster than the wind itself. A good one might outrun a storm with the
   camp aboard. *Built as your own camp rigged to sail ([above](#sailing-the-camp-hunter-2026-10-17)):
   the light deck it's tuned on goes at a running pace; floating on a keel and sailed from its helm
   ([the yacht](#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)), near the wind's speed
   off it, not yet past it or a storm's front.*
4. **Big carriers,** like the walker farmer, that carry the farm and the shield.

Early on you weather storms. Later, the yacht lets you choose between weathering one
and outrunning it.

### Sailing the camp (Hunter, 2026-10-17)

"Feeling the weight of your camp around your waist or in your hands is gonna be a really big
part of the game. the camp should be able to be used as a sail, especially when paired with
some sort of skates or board plate and actual sail mount... deep, fun, intuitive yet realistic
windsailing mechanics... it can be quite large." This is the vision's sand yacht, built from
your own camp's parts rather than found whole:

- **A sail mount and a sail.** A mast stands on a deck, and a large sail rides it. Raised, it
  catches the real wind; furled, it doesn't.
- **Runners: skates or a board plate.** Stuck under a deck in place of trays, they
  slide easily along their length and grip hard across it, as a land yacht's runners do, so a
  camp on runners sails across the wind and can work upwind, where a floating camp only
  drifts downwind.
- **Realistic, and felt.** The sail makes lift and drag by its angle to the apparent wind; its
  pull acts high up, so the camp heels in a gust and can tip; reaching is fastest, dead
  downwind is slower, straight upwind is impossible, so you tack. The pull reaches you down
  your lines: on foot or on the board, tied at your waist, your camp tows you.
- **Trimmed by its sheet.** The sheet is a line from the sail you hold or tie at your waist:
  reeling it in hauls the sail in, paying out eases it, so trimming is the reeling you
  already do. The line does it, never the control itself: reeling shortens the sheet, and the
  wind swings the boom against it (Hunter, 2026-10-18: "having scroll magically rotate the sail
  along with pulling the rope has been an issue both from a sense perspective and gameplay").
- **Storms.** A raised sail in a storm is the danger it should be: reef or furl it, or it
  tears and the mast can snap.

**As built (2026-10-18, `game/devices/runners.gd`, `game/sail/mast.gd`, `probes/sail/`).**
- **The parts.** Three finds, each a `give` id: skates (`skates`) and a board plate
  (`board_plate`), which are runners, and a mast (`mast`) with a sail (`sail`) to fit it.
  All lie deep, the mast rarely, and a mast is found with its sail on it.
- **Runners** stick under a deck's pieces in place of trays (held to a deck's top, they go
  under it), or fit a planter's tray mount. Skates and hover parts may share a deck (see
  [Hybrid runner and hover carriage](#hybrid-runner-and-hover-carriage-agreed-and-built-2026-10-20)).
  A deck's runners turn to its length, however its pieces sit on the grid. Runners draw no power. They ride the
  ground's one function, never the sand's collision: each corner of a runner's face reads
  `height_at` and is a spring on the sand that, with the others, holds up the load and settles
  it about 1 cm in; only the blades reach the sand, 5 cm below the frame they hang from (3 cm
  for the plate), so no lattice crease or chunk seam catches the body. Along its length a
  runner at rest holds a tenth of its load (skates; the plate 12%), and sliding it drags 3.5%
  and 3% more for each m/s (the plate 5% and 4%). Across, it ploughs: each corner takes out its
  sideways way as if its share of the load came to rest in 0.04 s, as far as its grip, 90% of
  the load for skates and 45% for the plate, so the plate skids sideways where skates bite.
  So a camp on runners is driven along them; a floating one only drifts.
- **The mast** stands upright on a deck's top, stuck there from your hands like the shield.
  Stowed it's a 1.3 m pole, 8 kg; stuck, it stands to 4.4 m over the deck. The sail, 5 kg, fits
  its sail mount low on it, furled along its 2.3 m boom, and is 5.5 m² raised: 3.4 m up the
  mast, the boom's length along its foot, 1 m across its head. A camp sails the way it faces:
  the boom trails behind the mast, which way the mast was turned as it was stuck.
- **Raising and furling** are use on the mast (its pole or the boom), 1.5 s each, with the sound
  of cloth. Off its mount, the sail comes down. Furled, the wind sees only the bundle on the boom.
- **The sheet** is any line whose end is on the boom's end, where the sail adds a tie. It runs
  through a block there and in to a ring on the camp, under where the boom's end lies hauled
  right in, and that inboard part holds the boom: the wind swings it out to leeward until the
  inboard is taut. Both are drawn, the inboard straight while it holds the boom and sagging when
  it doesn't. Reeling the sheet, in your hand or at your waist, takes the inboard in through the
  block a notch at a time (0.25 m, about 7° of swing) at your hands' 1 m/s; the line to you is
  no shorter, so the rope comes to the coil where the sheet is on you, all 3.1 m of the inboard
  once it's hauled right in. The boom comes in after it, drawn by the sheet's pull: the sail's
  twist over the sheet's lever, about 25 to 75 N in 10 m/s. Hauling slows from half your strength
  (400 N) and stops at all of it, as any line's does, so a loaded sail in a storm comes in slowly
  or not at all. Paying out gives line back and the wind takes the boom out after it: the boom
  swings with its own weight (12 kg·m²), its gooseneck's drag and the air the sail swings
  through, so in a breeze it follows the line out and in light air it lags, the inboard slack
  until it catches up; with no wind it stays where it is. Taut, the sheet holds it springing back
  six times a second, damped as a line is, and draws its end in no faster than a rope closes.
  Once the inboard is all in a notch reels the line itself, and once it's all out (85°) a notch
  pays the line out. With nothing holding the sheet's far end (dropped, untied, snapped) it runs,
  and the boom swings free and spills the wind; tied on again, it holds the boom where it is. With
  another line at your waist too, reeling works the one you look nearest along
  ([Rope & tethering](rope-and-tethering.md)), so you trim by looking at the sail. *Before
  (to 2026-10-18), a notch moved the boom's limit directly and the sail swung in step with the
  reeling, nothing drawn between the boom and the camp and no rope gathered; a sail too loaded to
  come in had the notch reel the line instead, drawing you to the camp.*
- **Reading the trim.** The cloth shows it, and reading it is the skill: eased past meeting the
  wind, under 12° of attack, its luff lifts first, just behind the mast, the lifting spreading aft
  as it's eased further until under 2° the whole sail flogs, harder in a harder wind. Drawing, it
  bellies as hard as the air presses across it, on a reach or running, and hangs in under 3 m/s.
  Over-sheeted past the stall it stays full but drives less: the cloth can't show that, the
  camp's way and lean do. A slack inboard says the sail is eased further than the wind takes it.
- **The how-to** (2026-10-18, Hunter: "i need an explanation on trimming with the sheet at my
  waist"). The first time a sheet is at your waist, once a profile, a short how-to shows near
  the top of the screen for nine seconds, its keys as bound: "The rope at your waist is the
  sail's sheet: it runs through the boom's end to a ring on the camp. Reel in draws the boom in
  toward the ring, pay out lets the wind take it out. You steer by where you walk, as with a
  tiller." It says what the controls do, never how to sail well. The words are `Mast.HOW_TO_SAYS`.
- **The sail's push.** Lift and drag by the sail's angle of attack to the apparent wind, the
  felt wind less the camp's own way at the sail: lift rises to 1.3 at 18° and stalls past it,
  falling away to a flat sheet's, and drag grows from 0.05 to 1.8 square on, where it catches
  the wind as any face that size does. The push acts 1.5 m up the sail, a third of the way back
  along it, 2.6 m over the sand on a deck, so the camp heels. Held out by its sheet, the sail's
  twist goes into the camp through the sheet, every moment the sheet holds it, easing or not;
  swinging free, as in a gybe, only its drag against swinging, and brought up at its 85° stop
  its swing slams into the camp. Lying over
  past 40° it fades, and past 70° it meets the sand, not the wind. Inside a running bubble the
  sail feels what the bubble lets through, like everything: nothing in a base shield's, 15% of
  the wind in a light shield's. Sail with the shield off; when a storm comes, furl it and put
  the bubble up, or run before the storm in clear air.
- **Points of sail.** Measured with the crate's rig, before the chassis rework; the rebuilt deck,
  its ballast two big batteries, is not yet re-measured. The "sail" deck, 89 kg on skates,
  steered and its sheet tended, in a
  steady 10 m/s wind: dead downwind 3.4 m/s, under the wind's speed; a broad reach (120°) 4.5;
  a beam reach 4.3, sliding sideways 0.1 m/s; a close reach (70°) 2.9; close-hauled at 60° 1.9,
  making 1.0 m/s upwind. From rest at 60° it barely gets going, and at 50° not at all: bear away
  to build speed, then head up. Head to wind it makes no ground, blown back 0.7 m/s, so you tack. On a plate the beam
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
  on the "sail" deck rounds up gently into the wind and stops: its ballast to windward drags its
  windward runners a little harder.
- **Towed on the board.** Stepping onto the board, a sheet at your waist stays tied, while any
  other line at your waist is untied first, as before, but for a camp's line beside the sheet
  ([stage 2](#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)). Towed, the board runs where the line
  leads and your keys turn it; only its dug edge holds against the line, so dug it carves
  across the pull ([the dig](#dig-and-carve-agreed-2026-10-18-spec-built)). It pushes and
  can now motor against a line within its small towing reserve (2026-10-19, powered sailing below).
  Reeling works riding, so you trim the sheet as you go. **Historical motor limit, superseded by the powered-sailing decision below:** its push never ran you past what your
  lines lead to while they're slack (2026-10-19): it gives out as you come 1 m/s faster than it, so
  an overrun goes slack and comes taut again firmly, never with a snatch. On the "sail" deck in 10 m/s, the sheet
  tended and the camp held across the wind, it tows you at 2.8 m/s on the end of the sheet, itself
  at 2.6. Left to steer itself with its sheet tended, it bears off onto a run, its boom at its 85°
  stop, and slows: before the sail's twist reached the camp whole (2026-10-18) it held a broad
  reach and towed you at 3.3 m/s.
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
  tick, so a reach sails the same at 30, 60 and 120 ticks a second (2.903, 2.902 and 2.900 m/s,
  50.4, 50.3 and 50.2 m in 20 s). In four minutes back and forth in gusts, over eight chunk seams
  and through three origin shifts, no tick changes its way by more than 0.13 m/s, it spins no
  faster than 1.6 rad/s, turning hard about at each end, leans under 8° and never touches the
  sand but by its blades. (It turned at 1.2 rad/s while its swinging boom dragged on it as hard
  as the air does; now only its gooseneck does.)
- **Cost.** About 100 to 130 µs a tick for a deck's runners and 110 µs for its sail, its drawn
  sheet with it, measured in the probes on a loaded machine; a camp on runners spends nothing
  floating.
- **The "sail" scenario** stands you on level open sand in a steady 8.5 to 11.5 m/s breeze out
  of any lee, facing across it with the wind on your left. Ahead stands a deck two pieces by
  two on skates, the mast and its furled sail on its front piece to windward, two big batteries
  and a battery in a frame behind it and a shield, switched off, behind to leeward, all one
  pool, and a bare tail piece behind the frame where the sheet's ring sits, 2.33 m behind the
  mast under the boom's end hauled right in (the yacht has the same tail); the sheet runs from the
  boom's end to your waist, eased to let the boom out 75°, and a charged board lies at your
  feet. Use the mast to raise the sail, step on the board, and reel in as it picks up speed.
- **Sailing probes** (`probes/sail/`): 1, runners sail across the wind where a floating camp
  drifts; 2, no ground straight upwind, ground on either tack; 3, the sheet trims the drive and
  reeling takes its inboard in, the coil at your waist growing by it; 4, it heels in a gust and
  recovers, and a blast puts it over smoothly; 5, a raised sail tears in a storm and a furled one
  doesn't, and a blast snaps the mast; 6, your camp tows you on the board; 7, nothing flings, and
  it sails the same at any tick rate; 8, furling in a breeze never tears the sail, and it raises
  again (Hunter: it couldn't be raised once brought down: the furled bundle's drag over the last
  of the cloth showing read as a tearing load); 12, reeling in draws the boom in over two seconds
  behind the line, the sheet taut and pulling, never a jump, paying out lets the wind take it out
  till the sheet holds it, and in still air it stays and the sheet hangs slack. Profile & saves
  probe 16: a rigged camp resumes.

### Sailing, from kite to yacht (agreed, 2026-10-18 spec; built)

Sailing is how hybrid play travels fast enough that storms are worth avoiding; the strongest wind
is a storm's, so the fastest move is running just ahead of a front on its wind
([spec](../briefs/storms-signals-sailing-2026-10-18.md)):
1. **Kitesurf, early:** a minimal camp (chassis, shield, sail as one unit) ahead of you on the
   board, a light control line to the sail, carving with the board's dug edge.
2. **A larger camp:** sail in front, you in the middle, the camp close behind in the shield; a
   hidden tow line runs from sail to camp, and you're the helm, not the load path.
3. **Land yacht, from found parts:** a helm seat and a keel part on the camp; you ride it and steer.
And the camp can sail itself downwind while you scout alongside.
**Never make you the link between a heavy sail and a heavy camp:** it would fold you in half, and a
small body under tension from both sides is where Jolt jitters. Without lateral grip you can only
run downwind; the dug edge or the keel is what tacks. Open then: where the helm seat and keel are
found, and from which era; answered below.

**Built (2026-10-18, `game/rope/ropes.gd`, `game/rope/rope.gd`, `game/sail/helm.gd`,
`game/devices/runners.gd`, `probes/sail/`).** Stage 1 is [Sailing the camp](#sailing-the-camp-hunter-2026-10-17)
as built, unchanged.
- **Stage 2, set up with the actions you have.** The sail's sheet at your waist, as for stage 1,
  and a line from the camp at your waist too. The hidden tow line first built here is gone
  (2026-10-20, see [the sailing correction](#sailing-correction-physical-boom-and-explicit-routing-agreed-and-built-2026-10-20)):
  every pull follows a real line, so to tow a camp you run a real towline from the rig to it, and
  holding both a sheet and a camp's line you are the link and bear their load as the fulcrum rule says.
- **Steering is the carve.** Dig in and carve off the line and its bend pulls the boom's end and
  the camp's nose toward you; the dug edge holds you there, as it holds a tack. Out to windward the
  rig bears away, to leeward it heads up. On the "sail_tow" camp on a broad reach in 10 m/s, a 20°
  carve dug a third in turns the rig +25° off the wind in 2.5 s to windward and −39° to leeward,
  against −2° with no carve (2026-10-19, the rebuilt decks, the board's push giving out past what
  tows you; +31° to windward on them before that, and +49° and −46° with the crate's rig). Left alone the rig rounds up and stops, as stage 1's does, so you keep
  steering; the probes hold its course as a helmsman would, by a turn on the rig.
- **The fulcrum.** Rope & tethering's rule, which the spec takes as there already and wasn't: lines
  snap past their load (1,500 N held, as ever), and your body bears what the lines on it pull against
  each other plus any line's bend round you. Held past your strength, 400 N (`fulcrum_n`), for as
  long as a line's load is held, you lose 8 health a second for each share more (`fulcrum_hurt`),
  never your last, and your view shakes.
- **Stage 3: the helm seat** (`helm_seat`, 7 kg), a skimmer pilot's, stuck upright on a deck's
  top the way anything that stands is. Use on it sits you there: you ride the camp as what's stuck
  on it does, your weight its, low in the seat, touching nothing, and lines at your waist pull the
  deck. The sideways moves turn the camp as a hovercraft's do, its hover field pushing it round
  toward a turn of 0.5 rad/s by up to 800 N·m (`helm_turn`, `helm_torque`), and letting go holds
  its heading. Reeling works the sheet at your waist. Ride, or use on it again, stands you up off the
  side it slides away from, onto the sand with its way; leaning past 40° throws you off. The first
  sit teaches, once a profile, what the controls do (`Helm.HOW_TO_SAYS`). Saves keep you at the helm.
- **The keel** (`keel`, 7 kg), a skimmer's ventral strake: a hover tray drawn out into a fin, stuck
  under a deck where a tray goes and lifting 60 kg as it faces the sand. Floating, its field bites the sand across its length as a
  runner ploughs, taking the slip out as a runner does, exactly over the tick, as hard as 0.6 of
  the weight its camp floats; along it, it drags 0.02 of that. It lies along its deck however its
  piece is turned. Its grip and its seat's ways are the parts' own, found by what they are, not
  where they fit.
- **The yacht.** The "yacht" scenario: a deck three by two floating on five trays and the keel
  (under the aft leeward piece), the mast at its front to windward, the helm seat aft on its middle
  line over a tray, two big batteries and a battery in a frame to windward of it, and the tail
  behind them for the sheet's ring; 146 kg as built now (134 with the crate it had), on 460 kg
  of lift, floating within 2° of level. The figures below were measured with the crate and aren't yet
  re-measured. (Sat at a
  corner of a deck two by two, a tray can't hold you and the corner drops to the sand.) In a steady
  10 m/s, steered from its helm up to 60° off the wind, it makes 5.0 m/s and 36 m upwind in 20 s,
  sliding 0.1 m/s; with a tray in the keel's place it slides off at 7.6 m/s and goes 136 m
  downwind however it's steered. Floating, it has no runners' drag: borne away to a broad reach
  it's at 9.6 m/s 20 s on, near the wind's own speed.
- **Sailing itself downwind** still works: the "sail" deck floating, its sheet made fast and nobody
  aboard, runs downwind at 8.2 m/s in 10 m/s while you ride where you like.
- **Where they're found.** Both lie in skimmer wrecks, in the wreck hull's best: what its deep cache
  holds once a storm strips past it, and in Han a third of its floors and caches. The skimmer era is
  the best single-item gear, a skimmer's pilot sat in that seat and it rode that strake, and the
  hoverboard is skimmer-culture gear already; wrecks lie shallow and tilted, exposed and reburied
  fast, so they're an expedition's find, near the Salvager's start. Each is 3 in 13 of a wreck's best.
- **Frame-rate proof.** Physics ticks only. Over 15 s at 30, 60 and 120 ticks a second the yacht
  sails 38.1, 38.2 and 38.2 m and the towing rig 29.4, 31.4 and 31.9 m (the lines swing you a tick at
  a time); nothing changes its way faster than 4.3 m/s² or spins past 0.5 rad/s.
- **Scenarios:** "sail_tow" (stage 2, both lines at your waist, the board at your feet) and "yacht"
  (the sheet at your waist, by the helm), in the sail scenario's breeze. The look-test `look/sail`
  shoots them as its fifth and sixth shots.
- **Probes** (`probes/sail/`): 9, the visible tow line, your load and the carve steering, the
  fulcrum, and reeling the sheet in tow leaves the camp's line be; 10, the yacht tacks with its keel
  and only runs downwind without, a floating camp sails itself downwind, reeling at the helm hauls
  the sheet, and a save at the helm resumes there; 11, nothing flings aboard at 30, 60 and 120
  ticks a second.

**Built (2026-10-19): stage 1 afloat, the Varran settler's rig** (`varran_kit.tres`,
`game/player/player.gd`, `probes/sail/13`). A rig with no runners and no keel, floating, towing you on
the board, your dug edge its only grip across the wind: the Varran rides his board as its keel
([Profile & saves](profile-and-saves.md#starts-on-the-chassis-and-two-new-kits-agreed-2026-10-18-spec-built)).
- **It flies as a kite does, on two lines.** On its sheet alone a floating rig hangs off its boom's
  end like a flag and only drags you downwind; nothing holds the sail at an angle to the wind. So its
  bow line goes to your waist too, from a hook on one of its front corners' outer rings: hung from
  that hook and its boom's end, the rig lies across its lines and flies out to one side of the wind.
  With its sheet at your waist, a line from the sheet's own rig stays tied as you step onto the board,
  as a camp's line its rig tows past you does; anything else is untied, as before. Its lines go to one
  body, so you're never the link between two.
- **Both tacks without moving a line** (2026-10-19; before, the hook set the side and nothing in the
  game said to move the line to the other for the other tack). A bow line runs from each bow hook,
  both at your waist with the sheet: a kite's bridle, its two legs meeting at you. The one nearer
  you flies it and the far one hangs slack, so one set of lines does on either tack. To change tack
  you send it across as a kite rider does, by pulling on the side you're going to: look at its far
  bow corner and reel that line in as you bear away and turn, and it pulls the rig across onto the
  new side; pay it out again once it's there. In 10 m/s on a beam reach, the far line taken in 6 m at
  your hands' pace as you turn and let out again, it tows you 4.9 m/s across with the wind on your
  left and 3.9 m/s with it on your right, every line where it was laid; on the new tack it flies
  from the same near hook, its sheet pulling 150 N. The first ride after the board's own how-to
  teaches it (`Mast.BRIDLE_HOW_TO`). Why this and not a bridle that turns it by itself: tried in the
  probes, the rig won't come round on its own. A bridle's apex a metre or so off its bow (the bow
  line's end carried over where two legs from both hooks would put it) keeps whichever tack it was
  launched on and drags you backwards on the other; one 3 m off weathervanes it into hanging
  downwind, flying neither; the bow line at the mast's foot hangs it downwind like a flag; and a turn,
  a gybe or a stop alone never swings it across. It has to be steered across, and a kite rider
  steers by pulling the side they're turning to.
- **Steered by where you ride, trimmed by its sheet.** You look and press the way you mean to go,
  dig the edge in, and the rig flies out ahead and to leeward; reeling, as ever, works the line you
  look nearest along: look at the sail to trim it, at a bow corner to work its line.
- **An overrun goes slack, then pulls** (2026-10-19). Holding forward on a run used to let the
  board's push take you past the rig at 15 m/s while its lines lay slack; they came taut again at
  7.6 m/s and snatched to 6,750 N for a tick, past their 1,500 N rating without breaking, and once
  threw the rider. Now slack in the lines never lets the board's push run you past what they lead to:
  it gives out as you come more than 1 m/s faster than it (`Ride.OUTRUN`), as far as the lines are
  slack. Held forward on a run the lines go slack for 7 s and come taut again at 1,080 N at most,
  you riding on; and no line ever pulls past its strength (Rope & tethering, "Holds or parts"):
  thrown past the rig at 12 m/s, its lines pull 1,500 N at most and hold.
- **Why a deck two by two.** Narrower decks were tried in the probes and are no rig: two pieces abreast
  or in a line go over or hang luffing on the lines, and three in an L fly one tack only, by which side
  its weight is on. Its four trays sit out at its corners, which keeps it up in 14 m/s on a beam
  reach, where trays under the pieces' middles let it go over.
- **The numbers** (the probes' seed, a steady wind, the sheet tended as probe 6's sailor tends it, the
  edge dug a quarter; running, undug, the board left to run where the lines lead). Its speed by point
  of sail, degrees off the wind:

  | Wind | 60° | 75° | 90° | 120° | 150° | 180° |
  |---|---|---|---|---|---|---|
  | 6 m/s | none | 1.0 | 1.8 | 3.8 | 4.7 | 2.0 |
  | 10 m/s | 0.8 | 3.0 | 4.8 | 6.0 | 4.8 | 5.1 |
  | 14 m/s | 1.9 | 5.3 | 7.1 | 10.0 | 8.1 | 8.3 |

  At 75° in 10 m/s it makes 0.8 m/s against the wind, and at 60° crawls, 0.4 of its 0.8 upwind: a
  kite points no higher than a close reach. It's the same on either tack (4.77 and 4.80 m/s on a beam reach), each
  line pulls about 170 N, and it heels 3° in 10 m/s and 10° in 14. Undug on that beam reach it makes
  1.6 m/s across and is blown 5.0 m/s downwind: the edge is the keel. (Measured on one bow line; on
  two, 4.9 m/s, the far one slack, and undug 1.2 across and 1.8 downwind.) In 18 m/s it goes over on a
  beam reach and runs at 11 m/s, its sail at the edge of tearing: furl it, or run.
- **Probes** 13: the rig sails with you on the board as its keel, its three lines kept as you step on,
  on one tack and then, its far bow line reeled in and out as you turn, the other, no line moved;
  undug it runs off downwind. 14: an overrun goes slack, then pulls under the lines' strength, and
  forced past it, a line never pulls past its strength.

**Playtest (Hunter, 2026-10-19; agreed, not built).**
- **The boom is solid to you.** "The horizontal part of the mast hitting you in the face and phasing
  through you. it should run into you and do damage at speed and potentially knock you off the
  craft, forcing you to design around it." A swinging boom strikes you by its speed where it meets
  you: a knock, harm at speed, and a hard one throws you off the deck. Where you sit or stand
  against where the boom sweeps is part of designing a rig.
- **Sailing stays hard and real, with a way to learn it.** "Sailing is cool rn but im bad at it so
  i think having an ideal comparison would help learn, an easy mode if you will, cuz i want to keep
  sailing hard and realistic." A Console with navigation equipment on a yacht shows the ideal: the
  sheet and heading that would sail best for where you're going, against what you're doing.
- **Console control:** "a mod that is some sort of rotor you can tie the sail rope to if you want
  console control." A winch, stuck on a deck, that takes the sheet. With a Console it trims the
  sail to the ideal, and with a keel, helps you drive: driving by computer shows you what ideal
  sailing looks like.
- **When (Hunter, 2026-10-22):** after the review fixes settle ("after"). The hand winch is built;
  the Console's ideal and its winch control are not.

### The dune sailboat (Agreed, session 4, part 3; superseded)

*Session 4, part 3 (lore session); the Varran settler's
centrepiece, proposed. The chassis spec (2026-10-18) made his craft a minimal fast sailing rig
instead, built (above), and Storm Runner, not a sailboat built and used, opens his start.* "Dune sailboat: slow hauler for hybrid play." It
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
"Camp lost · Chassis piece". The line counts down once the edge is 20 s off at your pace,
and gives the distance, "LAST WARNING · camp 140 m from the edge · turn back", once
it's 40 s off: you've turned back or stopped, not carved. The numbers are in Tuning's
Camp range group.
*After Hunter's ride (2026-10-16: "the timer popped so many times"), built the same
day.* A warning used to re-arm whenever your way swung off the edge or you slowed, so
carving out from camp fired it again, chime and all, and the line dropped and came
back; past the edge it said "lost in 0 s" until streaming let the camp's chunk go,
seconds later on a busy machine.

## Your body (2026-10-21)

You have a body: the Surveyor's suit (`SurveyorLooks`, art direction), rigid
pieces posed each frame by `Body` from how you move, with no shapes of its own
(gonkhub asked for a first-person body; Hunter wants it to carry gear later).

- **Walking:** a footfall each half stride, as Feel's steps fall, lifting more
  at a run; the arms swing against it.
- **Crouched or sat:** the hips drop with your eye and the knees bend to keep
  the boots on the sand; sat, the hands rest on the knees.
- **Lying down:** stretched out face down behind your eyes, arms forward.
- **Elsewhere:** in the air the legs gather; on a board the feet stand apart
  along it; tumbling or flying, nothing is drawn.
- **Holding something** (Hunter, 2026-10-22: "lets hold small things closer,
  but we can hold them down maybe to keep them out of our face? it really like
  our hands/arms to grib the item and move mechanically"). A small thing (a
  radio, battery, canister, ration, med kit, compass, scoop, sealant, flare, the
  Guide, anything under `pick_small` across) rides low in your arms, 0.45 m
  below your eyes and 0.27 m out (`suit_carry`), swinging a fifth of your look
  (`suit_carry_follow`): out of your face looking level, in view looking down.
  Both gloves close on its real sides by its back edge and stay on it as it
  moves; once on, they move with it exactly, and only reaching for it or
  letting go eases. Read while held, it comes up into view (`suit_read`): a
  radio while you tune it, a booklet while it's open, then it lowers again.
  An aimed tool, the cutter, keeps its low working pose at your right, aimed
  where you look, gripped by its rear handle. A deck is held out ahead by its
  nearest frame faces; rope ends, hooks, coils and anything a line is on stay
  out ahead where the lines need them. Arms keep their 0.61 m length.
- **Vaulting:** empty hands reach for the ledge and the leading knee gathers
  in proportion to its real rise, following `LedgeVault.progress`.
- **In first person:** your eyes stand 0.24 m ahead of your trunk's middle.
  Hunter found the old wide chest "in your face ... seizure inducing" while
  boarding; gonkhub chose a slimmer suit over hiding the torso, so the chest
  sits below and behind your view while helmet and collar are drawn only for
  their shadow and other views.
- **Between ticks:** the suit draws with the same between-tick offset as the
  camera and the ridden board, so it never jitters against them.

The limbs ease with time (`suit_ease_seconds`), the same at any frame rate.
Probes: movement 39 (only looks, boots on the sand), 41 (gloves on a carried
radio and battery at any look, low and out of your face, raised to read; on a
cutter and a chassis), 42 (the riding suit draws with the
board at 15 FPS, helmet and collar out of view), 44 (the climb gesture).

**Cost.** Nine paired rounds of 60 frames at 1920×1080 on the RTX 3070, the
slim suit holding nothing, drawn against hidden: in your own view looking down
+0.08 ms median (-0.49 to +0.39), from outside -0.04 ms (-0.21 to +0.53), within
noise; an earlier run gave -0.41 ms looking down, where the suit covers the
sand's close relief. `look/player_body/cost.tscn` repeats it.

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
   counts bounces. Since it flies true (2026-10-18), 59 launches, the underside at least
   5.1 cm off the sand, the hardest landing 8.0 m/s, under the jar, and never thrown.)*
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
   same path. *(Built: kicks from rest, a push, a carve, a hop, a drift, a coast, a dug
   carve and a hockey stop, then (2026-10-18) a hard carve that skids, a pop turned in the
   air and a crossed landing that slides out, over 165 m on the issue and 180 m on a
   skimmer racer: the same path to a tenth of a millimetre, the stop 2.952 m (2.407 m on
   the racer) at each rate to a millimetre, with the same charge and stamina left, and the
   same path to the bit with the drawing switched off.)*
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

15. **The hockey stop** (was "move back brakes", until the dig). From rest move back
    never moves you; riding, the board swings across and stops you far shorter than
    coasting, never reversing you or turning you off your line, even looking off your way.
    *(Built: from 13.4 m/s, 5.8 m in 0.78 s, looking along your way or 34° off it; coasting,
    66 m. The flat brake stopped in 1.45 s.)*
16. **The kick.** From rest a kick gets you going and costs stamina, with none there's no
    kick, and kicking climbs a slip face faster. *(Built: kicks alone, 6.8 m/s in 2 s for
    24 stamina; up a 31.7° slip face from its foot in 3 s, 13.9 m against 8.8 m.)*
17. **Pumping.** Over the ridges flat out, a rider in rhythm beats one standing still, but
    only a little, and the wrong way round loses. *(Built: with the tuck switched off,
    30 s, 544.3 m against 540.1 m, +0.8%; the wrong way round 536.0 m.)*
18. **The drift.** A hard turn crouched slides further out and keeps more speed than the
    same turn skidding, and standing up grips again. *(Built: from 19.4 m/s, out at
    16.7 m/s against 14.3, sliding 61° against 50°; before the skid, 16.6 against 12.9.)*
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
    landing is 3.7 g. Off the biggest crest it lands at 6.8 m/s pushing and 12.8 popping,
    which jars and holds.)*

Auto-walk has its own:

21. **Auto-walk.** It walks you exactly as holding move forward does, and holds its way
    while the view turns right round. A move of your own ends it (one held as it began
    counts once you let go), and so does walking into a wall or up a face too steep to
    stand on. *(Built: 5.2198 m in 3 s from rest either way, at 1.8 m/s; the view turned
    450° in 3 s and the way held to 0.001°; into a wall it stops dead; walking up to a
    31.9° face it climbs 4.7 m of the foot and stops where the sand passes 28°, then stands.)*

The dig has its own ([Dig and carve](#dig-and-carve-agreed-2026-10-18-spec-built)):

22. **The dug carve.** A hard turn from speed skids standing and grips dug, coming round
    sooner and slower, its low edge down to the sand and never into it. *(Built: 21°
    sliding against 50°, 1.7 cm off the sand.)*
23. **Catching an edge.** A hockey stop flat out holds with the catch set just past its
    load and throws you off set just short; as tuned, a cruise holds and flat out catches;
    thrown, you're knocked and winded, never killed, and the board tumbles behind you.
24. **The dug edge tacks.** Towed by a steady pull, a board steered across it runs
    downwind undug and holds its line dug. *(Built: 0° against 60°.)*

The ride's feel has its own ([The ride's feel](#the-rides-feel-and-boards-by-make-hunter-2026-10-18-built)):

25. **A hard carve skids.** Flat out, a carve the hover holds grips; a harder one breaks loose
    and skids well off its way for as long as you turn into it, and straightened it bites.
    *(Built: turning 0.4 rad/s it grips; 1.6 rad/s, loose in 0.35 s, 29° to 43° off its way for
    2.2 s of 2.5, biting again 0.4 s after.)*
26. **Hard landings.** A small drop presses and a big one jars; landing crossed hits harder; a
    big crossed landing slides out further and longer before it bites than the same crossing on
    the sand; and past the throw you're thrown off, knocked and winded, never killed. *(Built:
    4.2 and 10.3 m/s, 14.5 crossed 25°; 2.19 m in 0.57 s against 1.62 m in 0.37 s; thrown with
    the throw set just short of the landing, holding set just past it.)*
27. **A crash wipes out.** Head on into a wall at speed throws you and the board bounces back;
    at a crawl the wall only stops you; at a glance you slide along it and ride on. *(Built:
    18.5 m/s, the board back at 5.5 m/s; 1.5 m/s; 4.8 m/s into it, on at 17.3.)*
28. **It flies true.** Popped off the flat, the board's nose rises and falls with its path and it
    lands along the sand; turned off its way in the air with nothing steering, it comes round.
    *(Built: 9.8° up, 7.0° down, 2.2° off its path on average, 0.5° off the sand; turned 30°, it
    lands along its way.)*
29. **Boards by make.** A skimmer racer and a patrol board: the racer faster flat out, higher,
    breaking loose sooner and sliding further, and each its own weight, look and hum. *(Built:
    22.5 against 17.7 m/s, 0.43 against 0.30 m, 54° against 6°.)*

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
  meant, or only the patrol board. **Settled by Hunter, 2026-10-19:** the standard board may make limited, battery-funded pulls through sailing lines; heavy towing overloads it.
- **A slow sailboat against a fast yacht.** Here: the yacht is "the real fast base-mover" and
  "might outrun a storm with the camp aboard." The session: a "slow hauler." Not said how the two
  relate.
- **A moving bubble.** Here: riding you "take only loose things on no line," and the notes want
  the light shield "light enough to carry, switched on, while you walk or board." The session: "a narrow shield
  that stays on while riding," seated on the board's superchassis. Not said how it is mounted or
  how a bubble that narrow rides at speed.

The sleep session (2026-10-17) adds one. It is quoted on both sides and left standing.

- **The rack against a bedroll.** Here: a crate frame had one rack, holding one thing. The
  session: bedrolls, "probably sharing the hoverboard's mount slot on a crate." *Settled by the
  chassis (2026-10-18):* the crate and its rack are gone, and the board and a bedroll each stick
  anywhere on a deck they fit, side by side.

## Playtest follow-up (Hunter, 2026-10-19; built)

- **Board and rig:** "board speed is broken ... cant speed up to normal board speeds when
  attached to the rig." The redesign approved below replaces the blanket tow-speed
  restriction with battery-funded, load-limited motor assistance, preserving momentum and
  slack-line catch-up.
- **Varran attachment bug:** "the second line on the sail is attached to a floating hook,
  not on a chassis." Every bridle end stays seated in its actual chassis hook across
  assembly, riding, hauling, saving and resuming.
- **Rope motion:** the waist-to-rig rope looks "glitchy and nauseating ... blurry and
  jumping around erratically" when looking down while sailing. Its presentation follows the
  displayed camera and attachment positions smoothly, while the physical simulation and real
  tension are preserved.
- **Several waist lines:** "not so sure about having three ropes tied to your waist." Which
  line is tied, untied and reeled is managed in the carry view ([Rope &
  tethering](rope-and-tethering.md#waist-lines)). The bridle is not silently removed and no
  force cap is invented.
- **Learning to sail (agreed):** "a sailing tutorial in the sail scenario"; Hunter suggested
  physical items explaining the mechanics in depth. Give the sail scenario an accessible
  tutorial, with readable sailing notes for wind and heading, sheet trim, board edging, and
  the Varran bridle. Teach the current controls and why the rig responds, without taking
  away the skill of sailing. This extends the earlier brief controls-only how-to.

**Attachment and rope motion, built (2026-10-19).** The Varran's two physical bow hooks sit
on its chassis, through riding, reeling and saving. The floating hook was the sheet's drawn
inboard deck ring: every mast projected it under the fully hauled boom, 2.33 m behind the
mast, beyond the compact Varran's deck. It now rests on the nearest actual chassis top
surface, inset by the rope radius, and the drawn line ends exactly there; its slack uses the
distance between that anchor and the boom at the permitted trim. This is a presentation
correction: the physical sheet still pulls at the boom's end. Sailing 15 checks support and
all three physical attachments before riding, after hauling and after resume.

The board and its camera interpolate between physics ticks, but the waist lines used raw
tick positions: at 5 m/s that put the nearby line up to 8.3 cm ahead of the displayed rider
at 60 ticks/s, then jumped it back every tick. Waist endpoints now use the same ride and
tumble offset as the camera, and slack chain links interpolate for drawing, then follow the
displayed endpoints; simulation points and forces are untouched. Rope 17 checks the relative
position through fractions of a frame and that drawing leaves simulation positions
unchanged.

**Powered-board direction approved (Hunter, 2026-10-19).** The board may influence its rig
by pulling or racing ahead; its momentum as a keel, swing and counterbalance is part of the
fun. Replace the blanket no-tow speed suppression with motor overload: towing a tiny rig
should crawl, while a large rig should ground the board and make its motor sputter. Slack
lines should allow fast powered catch-up toward the rig. The earlier absolute prohibition on
motor-assisted towing is superseded by this decision. Implement load, motor and battery
behavior together, retaining rope strength and anti-launch safeguards.

Why: the old magnitude-based tow limiter suppressed even unloaded repositioning. With three
slack 100 m lines the Varran board reached only 0.99 m/s in eight seconds of forward thrust,
against 19.75 m/s with the lines detached. Allowing thrust toward the rig is not enough on
its own: the momentum can carry the board past the rig and load the ropes later, so that
stored energy has to be accounted for.

**Powered sailing as built (2026-10-19).** The ride no longer reads a rig-speed ceiling, and
the rope solver's impulses and the board's momentum are preserved. Line load blends motor
assist into a bounded low-force, low-power mechanical towing reserve of 90 N and 80 W. Only
opposing load heats the motor; aiding sail pull and unpowered carving do not overload it.
The load response is 0.2 s with a 70 N overload reference, and stalled motion below 0.1 m/s
heats the hover over 0.6 s. A grounded, still-commanded motor stays hot until the rider
eases or the sail moves it again. Full overload lowers the target ride height to 0.04 m,
adds 3 m/s² of sand drag and pulses motor thrust and the existing hum at 6 Hz, 25% on;
unloading recovers it. Motor work delivered against the line is metered on top of the free
ride's stylized draw, at 80% efficiency scaled by the board make, and a stalled attempt
still bills the 40 W hover plus up to 260 W of commanded drive. Heat, load and sputter phase
save with the ride. All numbers are in `tuning.tres`.

Three fully slack waist lines let a charged board pass 10 m/s within four seconds, and
turning keeps over 90% of its old-direction momentum over the next tick (sailing 18). A
one-piece grounded cargo crawls under 3 m/s on extra battery power (sailing 16); a
four-piece grounded deck drives heat above 90%, lowers the rider's feet within 0.2 m of the
sand and pulses audibly, and releasing the throttle recovers the hover within two seconds
(17). The 13.8 kg skates fixture crawled at 0.24 m/s on 34 W of extra motor input. In a
steady 10 m/s the powered Varran makes 5.96 m/s on one beam reach and 5.13 m/s on the other,
with no overload from aiding wind load.

A powered tack eases and brakes first, bears away, hauls the far bow line 6 m at the normal
hand pace, holds it while the rig crosses, then gradually heads up while paying it out;
paying out before the crossing has settled can send the rig back to its old side. Sailing 13
exercises that sequence and the field notes teach it. Racing past the rig stays safe by rope
strength: the lines go slack and retension, none pulls past its 1,500 N rating and the rider
stays aboard, while a collision with the rig's mast is a real crash and stays one. Sailing
14 covers it, including a forced 12 m/s phase moving away from the near bow attachment that
loads that line to its full rating.

### Sailing notes (built 2026-10-19)

One physical, carryable and mountable field booklet teaches sailing (`sailing_notes`, a 0.3
kg cloth-bound booklet with a sail on its cover), and a streamer on the mast supplies the
wind cue it explains. Use on the booklet, loose or carried, opens a chapter list and short
readable pages through the normal menu stack: six chapters over 18 pages, with Next,
Previous and Chapters, and controls rendered from action bindings. The chapters explain felt
wind and points of sail, raising and furling and sheet trim, the board's edge and its
powered limitations while tied, the Varran's three-line bridle and tack, and rope handling:
open the carry view, hover a rope to see it and choose it to work it. They invent no
release-all control or force cap. Reading adds no deed; the sailing actions' own deeds
record practice. While the reader is open the carry view and background how-to hints are
hidden and then restored, and deed toasts never cover menu headings.

In normal play the Varran carries the booklet in the suit inventory, where Use opens the
reader, and a streamer flies on its mast. A loose booklet beside the starting board was 23.5
m from the rider in the spawn storm, so starting guidance has to survive weather. The sail
scenario keeps its loose booklet beside the board. The shared booklet distinguishes the
practice rig's skates from the Varran's floating three-line rig, explains raising the sail
and floating the deck, and keeps the personal shield on the rider so it does not shelter the
sail. Existing saves are not retroactively supplied with the starting pair. Menus 19 covers
the sail scenario's booklet: reachable from the start, every page and navigation control
fitting at 1280×720, and the carried booklet reopening.

## Mooring-stake teaching for unassisted departure (agreed, 2026-10-19)

Sanddune's minimum unassisted Surveyor departure needs the existing mooring actions to be
findable. First holding a stake with a live attached line teaches the two meanings of Use:
aim at an open, level horizon or into the sky to tie it at the waist and tow; return it to
the hand, aim at nearby sand and Use to drive it again. Dropping a stake leaves it loose,
not anchored.

The lesson is a profile how-to shown once, with live action bindings (`UIRoot.teach`); a
bare stake, a not-yet-held pickup and menu or showpiece gear do not trigger it, and it waits
while a menu holds input. It is not a feat: existing towing outcomes keep their deed paths
(`Ropes._towing`, including planters in tow, and the sail-at-waist deed), and no deed is
awarded for reading instructions. No handling, load or binding changes follow from it.

## Hybrid runner and hover carriage (agreed and built 2026-10-20)

Hunter: "I think its fine to put skates on a hovercraft". Skates and a hover keel or tray
may sit on different clear places of one deck, replacing the former assembly restriction.
Their existing physical systems decide support: powered lift can raise its runners clear;
runners on the sand push and grip only by their actual contact load. An airborne skate must
neither plough nor count as a hover keel merely because its blade has a penetration
statistic, and true hover-fin grip stays proportional to the weight the hover field actually
supports. Lift capacity, mass, power and placement geometry are preserved, and no tuning
changed.

As built, hover-fin discovery requires positive lift as well as a keel statistic. The runner
contact and hover-support solvers need no new coupling: each blade corner is already gated
by ground distance and its support impulse, and fin grip already uses the mass the hover
field really carries. In sail 19's mixed deck, runner support is zero in flight, and a deck
sliding sideways at 4 m/s keeps over 3.9 m/s after half a second without a fin; a real fin
cuts that by more than 0.5 m/s. Ground-runner sailing and hover-keel tacking (sail 1 and 10)
are unchanged.

## Sailing correction: physical boom and explicit routing (agreed and built, 2026-10-20)

The sailing playtest rejected the one-sided angular latch, diagonal-only control and reeling
that appears to rotate a yacht magically. Boom control comes from actual rope forces and
usable hooks. A separate rigid boom body runs on a free mast-axis Jolt hinge, with no motor
or angular limit. Local apparent wind acts on the sail body; the hinge and the ordinary
sheet transmit its loads. Reeling changes actual paid length. Real contact geometry bounds
movement. Rope strength, closing-speed protections and opposed-load injury are unchanged.

The hidden automatic tow link is removed, because Hunter rejected the magic of it. Starter
sheets run through an actual removable fitted hook ([Rope &
tethering](rope-and-tethering.md#player-routed-lines-hunter-2026-10-20-built)). The tow
scenario has an explicit deck-to-deck line and an independent waisted sheet; the game never
silently bypasses the player or ties a second load to them. Deliberately retying opposed
loads still exposes the rider to the normal physical injury rules.

### Geometry and loading

The shared gooseneck and sail socket rises 0.5 m on the existing telescopic mast; the spar,
hinge, fitted tip and cloth share that frame. Normal navigation computer and ballast
geometry clears it, though arbitrarily tall custom gear can still obstruct it. The original
4 kg ballast frame is kept: removing it caused a real gust-recovery pitch failure. Native
spar contact replaces the duplicate analytic boom-tip ground force, and the upper-mast
ground support remains.

The Varran mast moves to the front row and the navigation computer aft. The old aft mast had
only about 0.7 m to a supported guide, which approached a 0.1 m effective lever at dead
centre: about 500 N of sheet tension against roughly 100 N of wind drive. The supported
guide now sits about 1.7 m aft of the hinge, giving real leverage. Both bow lines keep 1.5 m
of departure slack; the sheet includes its whole routed path and eased departure swing.
Starter lines keep a normal coil's capacity with only the initial path paid out, and a
carried stake is in the Varran kit.

The physical sail and fitted tip total 5.3 kg, counted once in the boom and not in the
carrier's fitted mass, with a rectangular gathering-cloth surrogate setting its centre and
inertia. The complete Varran carrier plus boom is 121.6 kg. Rope effective mass accounts for
the actual centres of mass, combined Jacobians when a guide shares an endpoint's body, and
the coupled free-hinge response ([Rope &
tethering](rope-and-tethering.md#player-routed-lines-hunter-2026-10-20-built)). Impulses
land only at the real attachment points and Jolt supplies the hinge reactions.

### Resume and mounted-pose ordering

A save keeps the boom's complete relative transform, world linear and angular velocities,
and its rope predictor cache, by the owning mast reference; yaw and relative hinge speed
alone omit real constraint error and carrier motion. Final mass properties are set before
the hinge is configured in its authored rest frame, saved body poses are committed to the
physics server, and the first rope step reads the direct inertia tensor.

A mounted kinematic mast takes its carrier's current pose before hinge, wind and rope work
(`follow_mount`). The mast's physics callback runs before its parent's seat refresh, so
without this the mast kept the previous world pose while the carrier advanced about 0.05 m.
This adds no force, damping or angular constraint. The rig-resume check (saves 16) covers
it.

### Checks and presentation

Sail 12 measures the sheet's actual routed extension against paid length and the rope's
declared maximum stretch, rather than an ideal angular latch, keeping its 1.5 degree per
tick smoothness, positive tension, still-air payout and wind-return assertions. The visible
tow (sail 9), the yacht (sail 10), the Varran reach and tack course (sail 13), the overrun
(sail 14) and the mounted hooks (sail 15) cover the rest of the rig.

A tow carve works by trimming first, then holding the paid length: automatic payout during
the carve would cancel the load change, and the production game adds no automatic control.
The following camp moves at 2.06 m/s with 67 N on the unhurt rider. In the fulcrum case, the
boom end cleated to the rig and the tow end tied to a movable rider between it and a moored
camp, a known 900 N rig pull produces 937 N of opposing load and 21 health lost, with both
lines intact (the fulcrum rule in [Rope &
tethering](rope-and-tethering.md#you-on-the-end-of-a-line)).

The rendered Varran shows the higher spar above the navigation computer, all three lines,
and the real guide foot seated on an interior panel clear of the case and deck edge. At 4.53
m/s its sheet carries 61.7 N. The field-note images use the actual higher boom and routed
hook geometry.

## Vaulting ledges (Hunter, 2026-10-20/21)

Hunter: "the vaulting is way too low, you cant vault up a chassis, that was the
goal. its still jumpy/choppy. we shouldnt vault tiny objects on the ground. we
should animate it too."

Sprint into a ledge, or jump toward it, to climb onto its walkable top,
including a floating chassis. Walking into a wall never climbs it. The reach is
measured above your current feet, so a jump adds only the height it really
gained; one vault per takeoff. Ledges under the minimum rise stay ordinary
clutter to step or jump over.

The climb sweeps the whole capsule up, across and down before it starts, and
again each tick along a curved path in the support's own frame, so a moving or
turning deck carries it and nothing is teleported, kicked or frozen. A new
obstruction, a lost support, a menu or a relocation cancels it with the travel
you had; rope drag still acts. A save keeps the safe position, not the climb.
Up and Over is recorded on a completed vault.

As built (`game/player/ledge_vault.gd`, Tuning's Ledge vault group): 1.1 m reach
above the feet, 0.3 m minimum rise, 0.9 m forward, 0.18 m over the top, 0.55 s
for a full-height climb and less for a lower one, four stamina. The path is
quadratic segments joined with continuous tangents, travelled by distance with
eased progress; the camera and suit interpolate it between ticks. A powered
two-chassis craft with its top 1.13 m above the sand is climbed at 30 and 60
render rates with the deck still hovering (peak craft spin 0.042 rad/s).
Probes: movement 32 (refusals, obstruction, moving support, origin shift,
saving), 35 (0.2 m clutter never mantles), 43 (the powered chassis), 44 (the
body follows).

### Large mixed-deck baseline (measured 2026-10-20)

A focused Godot 4.7.2/Jolt audit compared 4-piece and 27-piece decks and a 108-piece
notched deck, alternating skates and trays, hover off/on and yaw 0/45 degrees.
The 108-piece craft weighed 1,584 kg, with 54 skates, 54 trays and 18 batteries.
On real near-level sand (0.12–0.14 m height spread), after settling and then eight
seconds in 12 m/s wind, grounded support was about 15,508 N, spin stayed below
0.00029 rad/s and tilt below 0.66 degrees. Floating runner support was zero; it
drifted downwind at 4.23 m/s with spin below 0.0068 rad/s and tilt below 0.72 degrees.
No unstable-support or runaway-spin defect was demonstrated in these cases.

Support-solver CPU cost was about 0.11 ms/tick for four grounded pieces,
0.33 ms for 27 and 1.21–1.24 ms for 108; the latter cost 0.59–0.60 ms airborne.
These are local headless CPU timings, not total frame or GPU budgets. Mounted
masts/independent booms, rope impulses, boarding/landings, steep terrain and empty
battery transitions remain unmeasured in this audit and need combined checks.
The stress helper emitted teardown resource/instance warnings after completing;
their cause is unresolved. Preserve this measured baseline when changing support,
contact or pooled inertia; do not infer stability of every large craft from it.

A separate actual-craft boarding diagnostic also passed on the integrated hybrid
assembly source: 16 joined chassis, alternating eight skates/eight hover trays,
one big battery, 233 kg total. Its powered deck sat about 1.039 m above local
sand. Real sprint/jump input engaged the vault and finished with feet 0.060034 m
above its local origin (the 0.06 m deck top). Peak angular speed was 0.0632 rad/s,
peak tilt 0.79 degrees, and runner support zero. This covers one powered boarding
case; it does not establish steep-terrain or mast/rope-loaded boarding. The final
repeat on the interrupted-vault/save fix passed and exited without warnings; an
earlier repeat reported teardown warnings. The larger stress helper warnings
remain unresolved.

Final edge handling: the first swept rise clears stale grounded state and consumes
the current takeoff, preventing a canceled climb from counting as another ground
approach. A vertical ray under the candidate feet also requires an actual top;
rounded capsule contact against an edge alone is insufficient. Final seating snaps
at most 0.04 m, so a removed top leaves the player airborne rather than dropping
them instantly to distant ground. Cancel/save uses the approach pace plus the
support's point velocity, never the faster controlled climb motion. Movement 32
captures a live mid-climb Snapshot and checks that its saved vertical velocity is
not an extra jump, and checks removal of a top while the climb is active. The
final clear-light GPU run passed these same input cases and its captures were
inspected again.

A separate 27-piece notched deck (407 kg, nine skates and eighteen trays) used
offset mounts and mixed quarter-turns in 12 m/s wind, with six-second hover-off,
hover-on, empty-battery and post-touchdown phases. Powered transition spin peaked
at 0.0186 rad/s. Empty-battery touchdown briefly reached 0.475 rad/s, mostly roll
and pitch, then settled: the next six seconds peaked at 0.00086 rad/s, with tilt
below 0.92 degrees and support about 3,993 N, near its weight. No sustained spin
defect was demonstrated. Solver means were 0.16–0.28 ms/tick across these phases.
This covers one offset mixed assembly and battery transition, without mast, ropes,
steep terrain or player loads; the helper emitted teardown warnings after passing.

#### Authored placement in loaded boarding checks (built 2026-10-21)

Use `World.teleport` when a boarding fixture places an already active player at
its next approach. Directly assigning that CharacterBody's position creates a
native kinematic impulse before the test's input begins. An external 27-piece
uneven-craft case initially misidentified that setup impulse as powered-off
boarding instability: the first no-input tick already spun the deck at 9.287
rad/s. Keeping the original input cadence and 0.9 s / 0.08 m acceptance while
using the existing teleport API removes the kick. No Player/vault force law,
collision policy or acceptance threshold needs changing for this observation.

Keep a focused real-input regression covering the loaded, offset mixed craft,
ordinary battery exhaustion while aboard and powered-off reboarding. Retain
live native support and the actual hinged mast, routed sheet and mooring lines;
the fixture's setup teleport must not become a gameplay force workaround.

Movement 40 now covers that single combined boarding/ordinary-touchdown failure
mode. The notched 27-piece craft weighs 407 kg, carries eighteen offset hover
trays, nine offset skates, a real hinged mast and three physical lines, and sits
on actual sand with 0.514 m height spread. A 5 Wh battery drains through ordinary
device demand; both boarding attempts use actual movement input and unchanged
0.9 s / 0.08 m top/floor acceptance. No runtime boarding code changed.

On the inspected Godot 4.7.2 unseen GPU run, powered boarding peaked at 0.1195
rad/s and 0.790 degrees tilt; grounded reboarding peaked at 0.0892 rad/s and
2.127 degrees, with feet 0.06076 m above the chassis origin and floor true.
Natural power loss/touchdown briefly reached 0.6653 rad/s and 4.094 degrees,
then settled. All sampled frames during depletion/touchdown and the eight
seconds after reboarding retained floor contact, and no missing-ground rescue
ran. Movement 32, 35, 39 and 40 pass. The four actual 1280x720 captures in
`look/loaded_boarding` were inspected at powered boarding, touchdown, grounded
boarding and settling. They establish the visible endpoints for this one
moored moderate-wind assembly, not free-sailing/storm boarding or movement feel.
The GPU run passed before reporting eleven ObjectDB instances and four resources
still in use at teardown; these warnings remain unresolved.

## Solid wreck support (2026-10-20; built)

The board's hover previously read sand alone, so even an existing solid roof
was an obstacle rather than ground. Read reachable walkable faces of actual
static box colliders alongside sand, with one capped broadphase query per
outer tick and cached analytic faces for the inner integration. Preserve
ordinary wall/crash behavior, ceilings, hops, and sand's existing height field.
The wreck collision account is in Salvage & ruins.

As built: `Ride._height` reads sand plus cached reachable static box faces.
`TerrainChunk.ground_bodies()` lets the one outer-tick query exclude all live
quarter-heightmaps; a capped result receives five footprint ray samples.
`_move` treats walkable static contacts as floor and respects resolved ceiling
height. `Player._after_move` recognizes sand by HeightMap shape rather than
all static bodies. Actual controls climbed a partly buried 15.76° skimmer roof
without a throw; walking remained on it. Existing wall-crash and on-foot
frame-rate checks pass. The Salvage & ruins account records the measurements
and synthetic 64-face cost limit.

Movement 33 now keeps that board approach in CI: actual forward input moves
from sand onto the partly exposed, leaning skimmer roof. It checks the board's
underside remains above the roof, gains height and progresses without a throw;
it reads the wreck's geometry rather than reproducing the support cache. The
focused check passes in 10 s. An external control using the old sand-only height
read travelled 4.63 m without gaining height, put even the player's feet below
the roof (local 3.136 m against its 3.25 m top), and failed the approach check.

### Hopper ramp edge correction (2026-10-20; agreed before implementation)

Combined CI found one real opening snag in Kits 2: the hopper's lowered aft
ramp, near world (214.5193, 349.6859) in the fixed fixture. An isolated replay
reproduced it in both orientations. The capsule's rounded contact against the
small ramp edge produced normals with Y about 0.744–0.80, interpreted as a
roughly 40-degree slope despite the box's flat top. With static floors correctly
separated from sand, this repeatedly requested passive sliding; pace oscillated
around 0.03–0.25 m/s. The old all-static-as-sand classification had masked it.

Keep sand classification accurate. For an actual walkable contact on a static
box, read the box face at that contact instead of the capsule's rounded normal;
a tilted roof keeps its real tilt. Restore missing walking pace along that
actual support plane with a collision sweep, preserving wall obstruction and
floor edges. Keep the unchanged full opening traversal check, and add one
focused actual-player hopper ramp regression in Movement 34.

After-frame tracing also exposed the ramp's geometry: the front of its
horizontal slab stands about 0.109 m above the approached sand, giving a real
46.15-degree capsule contact before a walkable top is reached. Do not promote
that wall contact. Make this existing ramp a shallow inclined slab, lowering
only its outer edge to floor level and retaining the inner 0.08 m deck
connection. Draw and collide the same rotated box; preserve its existing box
index, all openings, loot/socket indices, and exposure/sand profile. Once a real
walkable contact exists, use the actual upward box face without a nearest-face
tie that can vary across the rounded edge.

As built, the ramp keeps its original box index. Its shared local box rotation
is 2.41 degrees; the outer top is approximately 0 m and the inner top 0.08 m
above the structure's floor. The existing apron covers the roughly 2 mm plan
extent added by the rotation. Exposure state/profile, room floors, openings,
loot and socket indices are unchanged. Static-floor pace compensation sweeps
along the actual plane; sand retains its original deterministic correction.
Movement 34 passes both actual approaches (four legs, no stuck leg or snag),
in 21 s; Movement 32 and 33 pass in 10 s each. The unchanged full Kits 2
traversal remains the acceptance gate for every kind's openings.

### Native hinge response and sailing stability (built 2026-10-20)

The rope iteration's initial velocity and the runner's support and contact response use the
same free-hinge degrees of freedom. Aerodynamic impulses already on the boom contain
relative motion the native hinge will block, so current and expected virtual motion are
projected through the assembly matrix. The runner takes a fresh native assembly snapshot
whether or not ropes exist, so untying the last line cannot change its support. Force and
torque coupling is resolved once per runner tick from six root impulse responses, the whole
supported mass sets the spring and damping coefficients, and native contact impulses land
only on the hull, with Jolt supplying the real hinge reactions. Non-hinged craft keep their
ordinary response and no tuning changed.

The native centre-of-mass model is limited to actual hinged assemblies, where the coupled
response needs it. Ordinary rope bodies keep their established mass-origin approximation,
and the 3 m/s solver closing bound and 5 m/s loose-plug acceptance are unchanged; improving
that approximation is separate work with its own contact and closing-speed evidence.

A fixed sheet reaches 2.907, 2.908 and 2.908 m/s at 30, 60 and 120 Hz after about 51.3 m,
with roll of 0.8 to 0.9 degrees. Sail 7 is the four-minute stability check of gust, turn,
seam crossings and origin shifts. It launches at a fixed clock on the original open-sand
lane. During a reversal its pilot eases the ordinary sheet at the normal reel rate while the
hull is more than fifteen degrees from its next course, then resumes its sheet tending, and
the last five seconds ease to luff; six forty-second legs turn both ways. It counts only
real changes of world chunk under the moving deck, against a four-seam minimum, with origin
shifts counted apart. Its run covers eleven seams and three origin shifts, with speed at
most 4.12 m/s, tick changes under the 0.3 m/s bound, 0.67 rad/s spin, 12.3 degrees of roll
and 0.014 m of penetration. Fixtures that tend a driving reach work the whole rope path at
the normal reel speed, using the actual physics interval; the pilot never rotates the boom
or sets velocity, and the production game adds no automatic trim.

A launch thirty metres before a nearby grid corner put the route on different sand and gave
a 0.36 m/s tick change, above that bound. That contact case is unresolved, and stability on
every slope is not shown by this fixture.


### Manual sail hoist (built 2026-10-20)

Hunter: "We should raise it with a new wheel attachment for the chassis, a pulley". A
removable hand winch fits an ordinary chassis surface. Its halyard runs from an accessible
sail-head tie over a visible masthead pulley to the winch, a separate ordinary line from the
sheet. Turning the wheel hauls or eases the paid rope at a bounded manual rate, and the
brake holds when released. Sail height follows the available halyard path without commanding
boom angle, rotation or rig velocity. A disconnected halyard lets the cloth lower, and a
loose mast's cloth cannot stay hoisted.

The halyard is a real load path. The cloth's weight is the manual hauling load while the
cloth, the route and the supporting tie all exist, and that load clears when any of them
goes away. The old instant raise and lower toggle is deleted; old saves migrate to the winch
and halyard. Existing sheet, yank and selected-line controls keep their behavior, and
looking at a mounted winch with empty hands works that wheel before a waist line. There is
no new binding and no powered auto-trimmer.

As built, `ManualWinch` winds an ordinary `Line` with its existing saved endpoints and one
real masthead guide. The cloth's head hangs on the halyard: the line holds it no lower than its
paid length allows and carries the cloth's weight (its share along an upright mast) as part of
its pull, its strength and what the winch or your hands work against. Eased or let go, the
head slides down under that weight, no faster than the luff runs (`halyard_lower_seconds`).
A line made fast between points of one rigid body pulls only with what it carries: it can't
move them apart, so the solver gives it no impulses. Old saves keep their fields but lose the
toggle: a raised sail with no halyard comes down, and saves 43 covers that. A queued stroke
stops when the operator looks away, leaves reach, opens a menu or takes something in hand,
and the brake keeps the achieved paid length. A partly hoisted sail saves and resumes with
the same halyard, route and winch tie, and keeps lowering. Sail 21 covers winding by
physical wheel input (raising, untouched sheet length, All Hands, holding, lowering after
disconnection), sail 22 that winding needs your hands and attention, and sail 23 that a
detached halyard loses its load. The winch uses the established worn materials: a metal and
teal drum, wound rope, yellow handle, mounting plate and masthead block, with the catalog
footprint containing the moving wheel and grip; the handwheel turns on the drum axle and the
sheave swivels toward its tail under a fixed mast bracket.

The wind deed requires the sail at full height: hauled to the drum's stop (the tail-to-masthead
distance plus the head clearance), its head block seated within `Mast.SEATED` of the pulley.
The deed's thresholds are unchanged (Wind 25).

**Review fixes (2026-10-22).** Rope bodies measure lever arms from their native centre of mass
everywhere, not only on hinged assemblies, since Jolt's velocity is that centre's. A camp lying
over meets the sand at its frame corners, seated shapes and masthead together
(`Runners.rest_on`, swept three times), where the masthead used to be met alone and before the
rest: probe 4 found it 0.54 m in the sand once its halyard end had a collider there, and now
measures the masthead directly. One hinged assembly is configured per carrier a tick and only
its velocities are re-read per contact. Probe 25 bounds the tipped contact work of the
2x2 sailing rig lying over at 1 ms a tick; on the loaded shared host it measured 0.72 to 0.83 ms
(nine near points of 41). The 108-piece camp was not re-timed. The overloaded motor's
sputter is its pulse's share of each tick, the same at any tick rate. A taut line still governs
the motor whichever way it pulls: keyed to the opposing pull alone, a throttled rider overran
the Varran rig and was snatched off the board mid-tack (probe 13).

### Authored rig balance and hoist hardware (built 2026-10-20)

The playtest accepts that real ropes and collisions govern the sail, while skate craft stall
and hover craft tend to circle. Authored construction is improved rather than adding a
course-holding force: the yacht's mast and lateral resistance sit on its centreline, with
symmetric corner lift and its finite ballast distributed, and the skated rig's mast moves
closer to its middle without exceeding its mounting face, with real hook clearance.

Every authored sailing scenario and Varran start supplies a fitted manual winch and an
ordinary pre-rigged halyard; kit data names both endpoints and counts the supplied line, and
the Varran counts and saves this fourth line apart from its three waist lines. Generated
salvage can supply the same winch, so a player can assemble the mechanism outside a dev
scenario. The illustrated sailing controls show hoisting at the wheel. Sail 11 (aboard
motion and rate) and sail 13 (Varran handling) pass on the revised layouts.

## Ground rest and crawling (Hunter, 2026-10-20)

Hunter: "allow x to sit down on the ground and z to lie down, which could allow
for sleeping and crawling." Sit and lie down toggle on supported ground.
Moving rises from sitting; lying down you crawl. Jump or lie down again rises
when there is room; a blocked rise keeps you low rather than jumping through a
ceiling. Lying down also needs the length of you clear behind (1.5 m from your
eyes to your boots), so the suit never lies through a wall. Boarding or taking a
helm needs room to stand. Airborne, riding, tumbling or seated, you can't rest.

The capsule keeps its width and feet, shortening to 1.15 m sat and 0.7 m prone;
the eye eases to 1.0 m or 0.5 m over 0.22 s, never past a ceiling. Prone you
crawl at 0.55 m/s. Wind, slope, ropes and moving supports still move you:
resting never anchors. From prone, use offers bare-ground sleep under the usual
sleep checks. Saves keep the posture without earning Ground Rest again; one
first-time hint teaches crawl, sleep and rising. Probes: movement 36 (rise and
crawl), 37 (headroom, room behind, eye containment), 38 (external motion).

### Runner clearance and native hull contacts (agreed 2026-10-20)

Fitted runner support stays outside Jolt's speculative native contact distance under its
ordinary settled load, while native collision stays available whenever a hull or runner
actually meets the ground or another physical object; no force, velocity cap or collision
exception is added. The runner face clearance is 0.04 m in Tuning: with the existing 0.01 m
settled compression its nominal 0.03 m gap is outside pinned Jolt's 0.02 m speculative
contact distance. This raises the same physical support geometry by 0.02 m and preserves its
spring, grip and damping.

Why: sail 7 showed a native hull contact jolt of 1.495 m/s after 74 s, with terrain present
and nothing frozen. Reporting boom contacts left it unchanged, but reporting one hull
contact removed it. Godot 4.7.2's
[`JoltBody3D::set_max_contacts_reported`](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/jolt_physics/objects/jolt_body_3d.cpp#L809)
turns off manifold reduction when any contacts are reported, so contact reporting is an
engine policy change, not passive instrumentation. The 0.02 m distance comes from
[`JoltProjectSettings`](https://github.com/godotengine/godot/blob/4.7.2-stable/modules/jolt_physics/jolt_project_settings.cpp#L42).

Disabling hull manifold reduction was rejected on cost. On the 108-piece mixed deck (1,584
kg, 54 skates, 54 trays, 18 batteries), whole-process CPU per physics tick rose from 8.00 to
8.38 ms to 11.71 to 12.06 ms grounded, with airborne about 7.0 to 7.4 ms. The 0.04 m
clearance keeps default manifold reduction and measured 7.85 to 8.35 ms grounded and 7.06 to
7.21 ms airborne. That craft stays stable grounded and powered at yaw 0 and 45 degrees (tilt
under 0.7 degrees, airborne runner support zero). These are whole-process samples, not
native solver timings: pinned `JoltPhysicsServer3D::get_process_info` returns zero, so
native counters cannot check a constraint budget, and the cost of larger craft or rough
terrain is not established. Sail 7 passes unchanged with the clearance.

### Capsized mast contact and the native assembly (built 2026-10-21)

The masthead's approximate sand contact uses the same native assembly point mobility and
projected velocity as runner support. Its hull is freely hinged to a physical boom, and
treating the hull as isolated understates the mass meeting the sand (about 1.43 kg effective
against an 87.3 kg hull and hinged boom), so the uncollided upper mast sank over a metre
before the spar landed. The contact keeps its existing separation, penetration recovery and
Coulomb friction law and applies its impulse only to the real hull at the contact's world
point; Jolt does the hinge reactions. There are no velocity clamps, changed acceptance
bounds or contact-reporting settings.

The 0.04 m runner clearance had changed the tipping contact sequence, and reverting it would
bring back the long-sailing hull-contact failure. With the assembly response the tipping
check (sail 4) passes natively on Linux and macOS, ending at about 101 degrees of heel. The
contact model is built only after a contact point enters its ground reach, so upright
large-deck runner support is unchanged.

### Coupled normal and friction at a capsized point (built 2026-10-21)

Normal and friction impulses were computed independently from the same incoming point
velocity, but the point mobility has off-diagonal terms: friction changes normal velocity
and normal support changes tangential slip. A penetrating masthead contact targeting +0.5
m/s of separation predicted -0.373 m/s after the summed impulses.

Normal support is now solved first, slip is computed from the resulting virtual point
velocity, the friction impulse's normal response is eliminated from its tangential mobility
and compensated in the normal impulse, and friction is bounded by the existing coefficient
times the corrected normal impulse. That keeps the contact's separation and penetration
target while reducing tangential slip without reversing it. The combined impulse is
delivered once to the actual hull, with no clamps and no change to clearance, recovery
speeds, restitution, friction or acceptance bounds. Sail 24 places a hinged rig's masthead
0.03 m into sand at 3.163 m/s incoming: the independent law recovers at 0.572 m/s and fails
the 0.01 m/s target tolerance, and the coupled law gives 0.500 m/s.

### Capsized carrier frame edges meet the sand (built 2026-10-21)

The remaining native tipping peak was a real collision of the carrier's own frame. Its
lowest enabled, non-socket frame corner was 0.0077 m below sand while the spar was 0.408 m
clear, because the capsized contact traversal visited mounted devices but omitted the
carrier's joined frame (its runner faces are airborne at 97 degrees of heel).

The traversal now includes a chassis's enabled frame collision shapes, including joined
panels owned by the root, and visits mounted frames once as before. The carrier's frame uses
the runner clearance, so its point support keeps the same sand separation ahead of Jolt's
speculative skin, while frozen mounted-device frames keep their zero-clearance contact. It
uses real shape corners and the same point-contact law, with no extra cushion dimensions,
forces or velocity limits; board handling is unchanged. The tipping check (sail 4) passes
natively on Ubuntu, macOS and Windows, ending at about 103 degrees of heel.

#### Final capsized large-camp cost

Measured on the 108-piece L-deck (54 skates, 54 trays, 18 batteries, 18 mounted devices and
one freely hinged mast, 1,772 kg), falling freely from 100 degrees of heel onto real terrain
and settling near 152.5 degrees. The original isolated-hull contact path is compared with
the final one (assembly response, coupled friction and carrier-frame support).

| Per physics tick | Original contact path | Final contact path |
| --- | ---: | ---: |
| Candidate frame/mast corners | 153 | 1,017 |
| Actual near-ground contacts, falling | 2.80 | 12.48 |
| Actual near-ground contacts, settled | 4 | 8 |
| Impulses applied, settled | 2 | 3 |
| Timed near-contact work, falling | 9.6–10.0 µs | 1.94–1.98 ms |
| Timed near-contact work, settled | 13.9–14.1 µs | 1.32–1.33 ms |
| Assembly construction within settled work | 0 | 1.20–1.22 ms |
| Whole-process CPU, falling | 9.38–9.46 ms | 13.46–14.08 ms |
| Whole-process CPU, settled | 8.83–9.00 ms | 12.48–12.63 ms |

The final geometry adds 864 real carrier-corner candidates and raises the settled
whole-process mean about 3.64 ms per tick, roughly 41 percent. This is a material cost of
the correctness repair on a large capsized camp and remains an open performance limit. Both
cases settle stably (heel 152.52 and 152.56 degrees). The figures are whole-process CPU,
including the terrain-height and reach queries, so they neither isolate native solver cost
nor budget more simultaneous contacts, multiple booms, rough terrain or larger camps.
Upright runner support does not enter this added path. Further optimization should look at
geometry and height-query reuse while preserving impulse order and fresh projected
velocities; caching the full physics snapshot changes sequential contact response.

**Native projection skip.** A fresh native contact model (`RopeArticulation.native`)
has zero external velocity, so its predicted/external projection pass is skipped, while
ordinary rope models keep both passes. On the 108-piece capsized camp this cut settled CPU
about 3% (12.58 to 12.16 ms per tick) with identical contact outputs. Since 2026-10-22 the
model is configured once per carrier a tick and only its velocities are re-read per contact
(see the review fixes under the manual sail hoist). Rope 32 checks that ordinary steps with
real external motion still conserve momentum and obey the hinge.

### Cache the chassis's ordered frame geometry (built 2026-10-21)

For the tipped chassis's own frame only, the ordered collision-shape references and each
shape's eight local AABB endpoints are cached, keeping every contact and its original order.
Enable and socket flags, shape identity and local and global transforms are read live, and
native and projected velocity is refreshed in each contact, so enabling a shape, changing
its pose or shifting the origin cannot reuse stale world points. The cache rebuilds through
`_shapes_changed` on join, detach, reroot, fitting, mounting and removal, and shape-resource
changes invalidate cached endpoints, with replacement resources recognized before their
first contact. Mounted devices keep the uncached traversal, and terrain reads and the
contact law are untouched. An earlier last-chunk and sample-array sampler was rejected: it
cost slightly more CPU.

On the 108-piece capsized fixture, whole-process CPU per physics tick fell from median
13.854 to 13.688 ms falling (1.2%) and from 12.979 to 12.365 ms settled (4.7%), with
identical contact and motion output. That is a small bounded benefit on a shared host, not
recovery of the earlier correctness cost or a general frame budget; cold-cache rebuilds and
frequent geometry edits are not timed. World 13 compares the cached geometry with the
native-shape debug bounds across joins, reroot and detach, resource edits and replacement,
pose, enable and order changes, mounting and removal, and an origin shift. Sail 4 and 24 are
unchanged.
