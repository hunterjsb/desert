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
- **Auto-walk** (Hunter, [2026-10-18 spec](../storms-signals-sailing-2026-10-18.md)). It holds
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

  | Make | Who made it | Weight | Flat out | Rides | Grip and skid | Landing | Draw | Hum |
  |---|---|---|---|---|---|---|---|---|
  | Hoverboard (`board`) | Tilg & Standard's issue, the colony's yard and survey board and still the company's: gunmetal, teal and safety yellow, its batch stencil on the tail (TILG XN 0217 on a deep one) | 7 kg | 20 m/s | 0.35 m | grips 18 m/s², skids keeping 0.9 and bleeding 0.6 | jars at 9 m/s, throws at 15 | 40 W + 260 W | the hover's own |
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

From Hunter's [storms, signals & sailing spec](../storms-signals-sailing-2026-10-18.md). The board's feel stays (never sinks, gets
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

Historical readings, not in the session (the ordinary-board towing restriction below is
superseded by Hunter's 2026-10-19 powered-board decision):
- **The standard board stays as built.** "Generalises the existing board" is read as the same idea
  with more sockets, not a change to the board in this PRD: the kit's board, hung on its deck,
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
  under it), or fit a planter's tray mount. A deck carries trays or runners, never both, and a
  refusal says "runners and trays don't mix". A deck's runners turn to its length, however its
  pieces sit on the grid. Runners draw no power. They ride the
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
([spec](../storms-signals-sailing-2026-10-18.md)):
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
  and a line from the camp at your waist too: take a coil's end to a ring on the camp, walk off
  paying out, and use ties it at your waist. With a sheet and a line to another device (not a
  stake) both there, you'd be the link, so the rope system runs a hidden line of its own from the
  sheet's tie on the boom's end, through a ring at your waist, to where the camp's line ties on. The
  camp's line rides on it, drawn as it lies past you; its length is the camp's line's plus how far
  your waist was from the boom's end when it formed, so reeling the camp's line shortens it. The ring
  slides: running straight through you, the line's pull passes you by, and your body bears only its
  bend. Meanwhile the sheet runs through its block, under the boom's end hauled right in on the rig's
  middle line, so its own pull, now only yours, lands there: you're towed as a light load and your
  side of the line steers. Step onto the board and both stay tied (any other line is untied first,
  as before); untie either and the hidden line is gone, the camp's line let out to reach you. Seated
  at a helm you're aboard, and no hidden line forms.
- **Steering is the carve.** Dig in and carve off the line and its bend pulls the boom's end and
  the camp's nose toward you; the dug edge holds you there, as it holds a tack. Out to windward the
  rig bears away, to leeward it heads up. On the "sail_tow" camp on a broad reach in 10 m/s, a 20°
  carve dug a third in turns the rig +25° off the wind in 2.5 s to windward and −39° to leeward,
  against −2° with no carve (2026-10-19, the rebuilt decks, the board's push giving out past what
  tows you; +31° to windward on them before that, and +49° and −46° with the crate's rig). Left alone the rig rounds up and stops, as stage 1's does, so you keep
  steering; the probes hold its course as a helmsman would, by a turn on the rig.
- **The numbers** (measured with the crate's rig; not yet re-measured on the rebuilt decks, whose
  ballast sits in a frame where the crate stood). The rig is the "sail" deck less its shield, 88 kg
  on skates; the camp a deck two by two on skates with the shield and, as built now, two big
  batteries, its line from the hook on its front left ring. On a broad reach (120°) in a steady
  10 m/s, held to its course, the rig makes 1.7 m/s towing the camp (2.5 m/s towing you alone):
  the hidden line carries 37 N, your sheet 30 N, and the lines on you pull 59 N all told, against
  57 N with the rig towing you alone. As the link you'd have borne about 130 N. That reach lays the
  boom on its 85° stop, where the sail stalls till the rig gets going, so it draws and stalls by
  turns; the numbers are from 8 to 12 s in. A skates camp halves a rig's speed; a floating one is blown downwind round
  the rig and rounds it up, and plates drag too hard to tow.
- **The fulcrum.** Rope & tethering's rule, which the spec takes as there already and wasn't: lines
  snap past their load (1,500 N held, as ever), and your body bears what the lines on it pull against
  each other plus any line's bend round you. Held past your strength, 400 N (`fulcrum_n`), for as
  long as a line's load is held, you lose 8 health a second for each share more (`fulcrum_hurt`),
  never your last, and your view shakes. Braced 4 m to windward of the hidden line with the camp
  moored, the line bends round you at up to 500 N in 12 m/s and takes 9 health in 10 s; the lines
  hold. Riding either stage you're never hurt.
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
- **Probes** (`probes/sail/`): 9, the hidden tow line, your load and the carve steering, the
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

### The dune sailboat (Agreed, session 4, part 3; superseded)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); the Varran settler's
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

## Playtest follow-up (Hunter, 2026-10-19; in progress)

- **Board and rig:** "board speed is broken ... cant speed up to normal board speeds when attached to the rig." The approved redesign below replaces the blanket tow-speed restriction with battery-funded, load-limited motor assistance, preserving momentum and slack-line catch-up.
- **Varran attachment bug:** "the second line on the sail is attached to a floating hook, not on a chassis." Every bridle end must stay seated in its actual chassis hook across initial assembly, riding, hauling, saving and resuming. Fix the attachment before evaluating the three-line rig's handling.
- **Rope motion:** the waist-to-rig rope looks "glitchy and nauseating ... blurry and jumping around erratically" when looking down while sailing. Make its presentation follow the displayed camera and attachment positions smoothly; preserve the physical simulation and real tension.
- **Several waist lines (design open):** "not so sure about having three ropes tied to your waist"; explain and manage which line is tied, untied and reeled. Measure both the resultant pull and opposing loads on the player before choosing a safe-force limit or release behavior. Do not silently remove the bridle or invent a force cap.

**Built follow-up (2026-10-19; rendered checks passed).** The Varran's two physical bow hooks
were seated on its chassis, including through riding, reeling and saving. The floating hook
was the sheet's drawn inboard deck ring: every mast projected it under the fully hauled boom,
2.33 m behind the mast, beyond the compact Varran's deck. It now rests on the nearest actual
chassis top surface, inset by the rope radius, and the drawn line ends exactly there. Its
slack uses the distance between that anchor and the boom at the permitted trim. This is a
presentation correction; the physical sheet still pulls at the boom's end. Sailing probe 15
checks support and all three physical attachments before riding, after hauling and after resume.

The board and its camera already interpolate between physics ticks; the waist lines used
raw tick positions. At 5 m/s that put the nearby line up to 8.3 cm ahead of the displayed rider
at 60 ticks/s, then jumped it back every tick. Waist endpoints now use the same ride/tumble
offset as the camera. Slack chain links also interpolate for drawing, then follow the displayed
endpoints; simulation points and forces are untouched. Rope probe 17 checks the relative
position through five fractions of a frame and confirms drawing leaves simulation positions
unchanged. The existing rendered-ring/length/sag, origin-shift, towing and sheet-hauling probes
pass. A loaded Varran recording at about 6.3 m/s and 190 N, with all three lines retained,
shows coherent near-waist lines and the seated ring through a motor-assisted turn.
The recorded cadence was about 60–61 FPS with variable frame intervals, not a 144 Hz test;
rope probe 17 separately checks five interpolation fractions. The render-pass ring
refresh also removes a measured 102 mm tick lag: over 210 rendered frames its anchor
error stayed within 0.016 mm, with zero drawn inboard endpoint error.

**Powered-board measurement before the approved redesign.** With the actual Varran board in still air,
its stationary rig's three lines extended to 100 m and carrying zero tension, holding forward
for eight seconds reached 0.992 m/s. Detaching those lines, resetting board velocity and holding
forward for another eight seconds reached 19.753 m/s. The magnitude-based tow limiter therefore
suppresses even unloaded repositioning. Simply allowing thrust toward the rig is insufficient:
the resulting momentum can pass it and load the ropes later. Any future motor assistance must
account for that stored energy, or explicitly accept battery-funded towing. The current board
physics was left unchanged until the following decision was approved.

**Powered-board direction approved (Hunter, 2026-10-19).** The board
may influence its rig by pulling or racing ahead; its momentum as a keel, swing and
counterbalance is part of the fun. Replace the blanket no-tow speed suppression with motor
overload: towing a tiny rig should crawl, while a large rig should ground the board and make
its motor sputter. Slack lines should allow fast powered catch-up toward the rig. The earlier
absolute prohibition on motor-assisted towing is superseded by this decision. Implement load,
motor and battery behavior together, retaining rope strength and anti-launch safeguards.
- **Learning to sail (agreed):** "a sailing tutorial in the sail scenario"; Hunter suggested physical items explaining the mechanics in depth. Give the sail scenario an accessible tutorial, with readable sailing notes for wind and heading, sheet trim, board edging, and the Varran bridle. Teach the current controls and why the rig responds, without taking away the skill of sailing. This extends the earlier brief controls-only how-to.

**Sailing notes implementation plan (2026-10-19).** One physical, carryable and mountable field booklet lies beside the sail scenario's starting board; a streamer on the mast supplies the wind cue it explains. Use on the booklet, loose or held, opens a chapter list and short readable pages through the existing menu root. Chapters explain felt wind and points of sail, raising/furling and sheet trim, the board's edge and powered limitations while tied, Varran's three-line bridle and tack, and named gaze-based line selection shared by reeling and untying. Controls render from action bindings. Reading adds no deed: this dev-scenario teaching aid points to the existing sailing actions whose deeds already record practice.

**As built:** `SailingNotes` is the `sailing_notes` catalog device, a 0.3 kg cloth-bound field booklet with a sail on its cover. `scenario sail` puts it within reach beside the board and mounts a streamer on the practice mast. Use reads it loose or carried. Six chapters are split into 18 short pages, with Next/Previous/Chapters through the normal menu stack. The notes explain loaded motor assistance, overload recovery and gaze-selected rope handling; they invent no release-all control or force cap. Menus probe 19 starts the real sail scenario, uses the booklet from the player's starting position, traverses pages and back, measures every text and navigation rectangle at 1280×720, and reopens the carried booklet with console focus restored. Rendered captures confirm the booklet is reachable and its trim/bridle pages fit at 1280×720. Focused menu checks also cover hiding background how-to hints while reading and restoring them afterward.


**Powered sailing implementation plan (2026-10-19).** Preserve the rope solver's impulses
and the board's momentum; remove the speed limit derived from the rig's speed. Any taut
line load changes the motor to a bounded low-force, low-power tow mode. Only opposing
load heats the motor; aiding sail pull and unpowered carving do not overload it. Sustained opposing load overheats the
hover, lowers its ride toward the sand and adds sand drag; thrust and the existing hum
sputter while overloaded, then recover after unloading. Motor work delivered against the
line is metered in addition to the free ride's existing stylized draw, with an efficiency
loss; stalled attempts still consume power. New load, force, power, response and sound
settings belong in tuning.tres. Probes measure slack catch-up, small-load crawl, heavy-load
grounding and recovery, turning momentum, rope strength, and battery accounting.


**Powered sailing as built (2026-10-19).** `Ride` no longer reads a rig-speed ceiling.
Three fully slack waist lines allow a charged board to pass 10 m/s within four seconds;
turning retains more than 90% of its old-direction momentum over the next tick (sailing 18).
Line load blends motor assist into a 90 N / 80 W mechanical towing reserve; opposing load
alone heats it. The load response is 0.2 s, the overload reference 70 N, and stalled motion
below 0.1 m/s heats the hover over 0.6 s. A grounded, still-commanded motor stays hot until
the rider eases or the sail moves it again. Full overload lowers the target ride height to
0.04 m, adds 3 m/s² sand drag and pulses motor thrust and the existing hum at 6 Hz, 25% on.
These numbers are in `tuning.tres`; ropes still transfer momentum through the existing solver.

A one-piece grounded cargo moves at under 3 m/s and uses additional battery power (sailing 16).
A four-piece grounded deck drives heat above 90%, lowers the rider's feet within 0.2 m of the
sand and produces both audible on and off pulses; releasing the throttle recovers the hover
within two seconds (17). The separate 13.8 kg skates fixture crawled at 0.24 m/s, averaging
34 W of extra motor input. The existing 40 W hover plus up to 260 W commanded drive remains
billed during a stalled attempt; positive motor work against the line is added at 80%
efficiency, then scaled by the board make. Heat, load and sputter phase save with the ride;
the existing save-mid-ride probe passes.

In a steady 10 m/s, the powered Varran makes 5.96 m/s on one beam reach and 5.13 on the other,
with zero overload during the final ten seconds of aiding wind load on either tack (600
loaded ticks each). A powered tack now eases and brakes first, bears away, hauls the far bow
line 6 m at the normal hand pace, holds it while the rig crosses, then gradually heads up
while paying it out. Paying it out before the crossing has settled can send it back to its
old side. Sailing 13 exercises that sequence without moving an attachment; the field notes
teach it. The undug wind-only comparison and movement's dug-edge probe explicitly disable
motor force to isolate the wind's sideways shove from the newly permitted powered steering.
Sailing 14 retains the no-catapult and at-most-rope-rating checks when racing past the rig.
Rendered loaded sailing and motor-assisted turning checks passed with all three lines.
The changed motor hum has not received a separate listening-quality acceptance;
its sputter follows the tested overload pulse.


**Overrun probe correction (2026-10-19).** With powered movement enabled, the old straight
passing path could hit the rig's mast: the reproduced dismount at 20.60 s was a real
`crash` at 8.51 m/s, not a rope-induced launch. Preserve that collision behavior. Sailing 14
now lays its lines from a 2 m farther outboard passing lane before either end starts moving.
It requires actual slack followed by retension, no rope force beyond its rating and a rider
still aboard; its forced 12 m/s phase must also reach at least 90% of the rope rating.
Three checks passed on the corrected fixture. The measured run spent 4.1 s with all lines
slack, retensioned while the rider stayed aboard and reached exactly 1,500 N; the forced
phase reached 1,500 N and one line parted. A failed ride check now stops before dereferencing
the absent ride, preserving the original failure instead of adding a secondary script error.

### Normal-play sailing teaching (agreed Sanddune work)

Learning through objects applies to the normal Varran start as well as the dev sailing scenario.
The existing field booklet is available from the suit and a streamer flies on the rig's mast.
The shared booklet must distinguish the practice rig's skates from the Varran's floating,
three-line rig, explain raising the sail and floating the deck, and keep the personal shield on
the rider so it does not shelter the sail. No new input action, item type or reading deed is needed.
The player can read and carry the notes through the existing device/menu system.

The line-handling chapter also teaches the agreed named waist-line choice in the carry view:
select a line to keep working it, or choose Follow gaze to return to aiming along a line. A held
line still takes priority. Empty-handed use unties the selected waist line after the normal delay.

**Initial placement:** `varran_kit.tres` placed `sailing_notes` 0.73 m beside the board and mounted a
`streamer` on the existing named mast through the same rig step used by the sailing scenario.
`SailingNotes` uses the existing chapter/page reader and control macros; its opening covers both
rig types, floating the Varran deck and keeping its personal shield on the rider. The line chapter
describes carry-view selection and Follow gaze. Existing saves are not retroactively supplied
with the starting pair. Source inspection found no Varran fixture count/index assumptions to
change; this bounded change adds no probes.

**Storm-access correction:** A normal seed-1234 Varran capture found the loose booklet 23.5 m
from the rider after the opening fade and 90 further physics ticks, with an active storm at spawn.
Starting guidance must survive that weather: the Varran now carries the physical booklet in the
existing suit inventory, where its existing Use opens the reader. The practice scenario keeps
its loose booklet beside the board. The mast streamer remains mounted. This supersedes the
normal-start loose placement above; no new item, action or UI is required.

The carried-booklet visual check also exposed inventory tiles behind reader text.
The covered carry view is now hidden until the reader closes, then returns with
mouse interaction restored; deed toasts no longer cover menu headings.

**Rendered acceptance:** a fresh storm Varran run showed the carried booklet and
mounted streamer at 1280×720. Inventory Use opened the actual reader. Opening and
line-handling pages fit with their navigation; the carry view and deed toast stayed
hidden behind them. Closing the reader restored carried objects, all three waist
line rows and a free pointer. The final visual helper exited without runtime errors.

**Radial overload coverage (2026-10-19).** The normal Varran's added streamer changes the
trajectory enough that sailing 14's later fixed downwind velocity no longer challenges a
line. On the exact teaching candidate, the normal phase still gave 4.2 seconds slack,
retension and a 1,500 N peak while riding; the forced phase peaked at only 345 N locally
(296 N on CI), correctly failing its unchanged 90%-of-rating coverage assertion. Measured
relative velocity along the near bow line was **-8.48 m/s**: the imposed motion closed the
gap, making slack instead of applying overload. This is a fixture direction error, not
evidence that the strength limiter changed.

Keep the normal powered run and both strength/coverage requirements. For the forced
phase, move at 12 m/s away from the actual near bow attachment relative to the moving
rig, facing along the resulting motion. This heads into the open lane away from the rig,
without crossing its chassis or mast, and must load that specific line to at least 90%
of its rating while no line pulls past its rating. Do not change gameplay physics.

With that fixture correction the near bow's measured opening speed is 11.98 m/s along its
three-dimensional radial (12 m/s horizontally); it reaches exactly 1,500 N, all lines stay
at or below 1,500 N, none parts and no wipeout is emitted. The normal powered phase retains
4.2 seconds slack and retension while riding. Two official focused sailing-14 runs pass
(13 seconds each); the direct measurement replay also passes. No physics or presentation
source changed.

## Mooring-stake teaching for unassisted departure (agreed, 2026-10-19)

Sanddune's minimum unassisted Surveyor departure needs the existing mooring actions to be
findable. First holding a stake with a live attached line teaches the two meanings of Use:
aim at an open, level horizon or into the sky to tie it at the waist and tow; return it to the hand, aim at
nearby sand and Use to drive it again. Dropping a stake leaves it loose, not anchored.
This uses `UIRoot.teach` once per profile, with live action bindings. A bare stake, a
not-yet-held pickup and menu/showpiece gear do not trigger it. No handling, load or binding
changes follow from the lesson.

The lesson is a profile how-to, not a new feat: existing towing outcomes keep their existing
deed paths (`Ropes._towing`, including planters in tow, and the sail-at-waist deed). No new
deed is awarded for reading instructions.

As built: `Stake._physics_process` checks that the player's hands have finished taking the
stake and that it still carries a live rope before calling the profile how-to. It waits
while a menu holds input. Headless import completed on the pinned Godot version; no new
probe or gameplay behavior run was performed for this teaching-only change. A later
1280×720 capture showed the existing mooring stake held and both instruction lines
fitting at the top of the view. The external helper hit a teardown-only script error
after saving the image; its call was corrected without changing game code.

## Sailing correction: physical boom and explicit routing (agreed, 2026-10-20)

The user's sailing playtest rejects the one-sided angular latch, diagonal-only
control and reeling that appears to rotate a yacht magically. Boom control must
come from actual rope forces and usable hooks. Replace the scalar trim spring
and its hard angular stop with a physical boom body on a free mast-axis hinge.
The sail's wind force acts on that body; its hinge and ordinary sheet transmit
loads to the carrier. Reeling changes the sheet's actual length, never a separate
trim angle. Collision geometry, rather than an invisible angular limit, bounds
its travel. Preserve rope strength, injury and closing-speed protections.

This supersedes the hidden automatic tow link described above. An actual line
routed through a usable hook supplies its visible load path; no automatic hidden
constraint bypasses the player. Starting rigs provide a real deck guide and
usable eased sheet geometry, and the Varran carries a mooring stake. Independent
boom mass must not remain counted in the carrier; save/resume and origin shifts
retain its relative pose and velocity. Measurements follow implementation.

Initial physical diagnostic: the old tall ballast-frame fixture stops the spar
at 16.2 degrees through real contact. With that obstruction removed, the boom
passes the former 85-degree stop (92.8 degrees measured). Settled hinge pivot
error is 0.009–0.13 mm; after an origin shift it is 0.016 mm. The later higher gooseneck clears that frame, retaining its original 4 kg
ballast and avoiding the gust-recovery pitch failure caused by removing it.
The Varran keeps 1.5 m departure slack on both bow lines; the sheet
includes its actual guide path and enough eased line for either tack,
instead of catching the rider first through the old trim spring. These are
initial diagnostics, not yet acceptance of handling or safety.

The gooseneck and sail socket rise together by 0.5 m on the telescopic mast,
putting the actual boom above the normal navigation computer and ballast frame.
This is a visible hardware clearance, not a collision exemption or angular stop.
Arbitrarily tall player-fitted gear can still obstruct the boom. The additional
height changes sail leverage and centre of mass and must be measured during
loading, tipping, furling and save/resume checks.

The `sail_tow` scenario now lays a visible ordinary towline from the sailing
deck's stern hook to the following camp's bow hook. The rider has an independent
sheet, so the camp's load follows that explicit rope instead of a hidden bypass
or a pair of opposed waist lines. Deliberately tying opposed loads still uses
the normal injury and rope-strength rules.

The physical boom save also retains its complete relative transform and world
linear/angular velocities. Relative yaw and hinge spin alone omit small solver
constraint errors and carrier motion, so are insufficient for a resumed rigid
body. The original hinge anchors are restored before applying that saved state.
Native spar/sand collisions replace the previous duplicate analytic boom-tip
contact; the existing uncollided upper-mast sand support remains.

The rope solver's previous-tick velocity predictor also keeps the derived boom
body by its owning mast reference. A boom has no independent catalog identity;
skipping its cache silently changes the first resumed rope step.

The compact Varran's aft mast leaves only about 0.7 m to a supported aft
guide. In a forward-swept boom position this approaches a dead centre: about
0.1 m effective sheet lever was observed with 500 N sheet tension and roughly
100 N wind drive, overloading the rider. Move the mast to the front row and
the heavy navigation computer aft. The actual supported guide can then sit
about 1.7 m aft of the hinge, providing real mechanical leverage. The higher
gooseneck clears the computer. This changes physical layout, never torque by
an invisible correction.

Starter lines have a normal coil's capacity (at least their initially paid
length), with only the initial route paid out. The old factory gave a sheet
no unused real rope; its removed virtual inboard had concealed that limit.
Gybes use the real coil reserve rather than a hidden trim allowance. The
Varran course retains its release/brake, far-bow haul and payout sequence; the
helmsman tends actual sheet at the normal reel rate.

The first restored rope solve reads Jolt's direct inverse inertia tensor rather
than the RigidBody node cache: engine state synchronization has not populated
that cache before the first callback. The prior cached identity contributed to
a first-tick angular error and 8.9 cm of four-second save/resume drift despite
identical saved poses and velocities; the direct read reduces this to 6.24 cm,
which still fails the unchanged 5 cm check and remains under investigation.

The overrun fixture uses the opposite outboard passing lane, avoiding a real
chassis collision while retaining slack, retension, riding, and full-strength
radial overload assertions. Official overrun check passes in 13 seconds; the
Varran reach/tack course passes in 31 seconds. These precede final combined
verification.

The old hidden-tow check's cross-run subtraction of sheet force is superseded
by direct deck-to-deck rope topology, one independent waisted sheet, and normal
opposed-load/injury measurements. Towing changes apparent wind and heel, so an
independent sheet force cannot be inferred by subtracting another run. Its
motion, directional carving, deliberate fulcrum injury and strength thresholds
remain unchanged.

The remaining first-step audit finds the fresh physics direct state still at
identity while the restored node has its saved transform: its inertia tensor is
therefore expressed in the wrong orientation during the first custom solve.
Restoration must synchronize the actual physics pose before creating dependent
hinges and before allowing custom rope/runner callbacks; merely assigning the
scene transform is insufficient at this between-tick point. Verify this against
the unchanged future-pose tolerance before acceptance.

The yacht/tow fixture helmsman must choose an apparent-wind attack angle whose
lift drives along the hull, rather than simply choosing the nearest angle.
With a genuinely free boom, the nearest choice can drive backwards; an angular
latch previously concealed that fixture mistake. This changes only deliberate
probe sheet handling at normal reel speed, not game wind forces or controls.

The yacht trace measures about 0.2 degrees attack and 8 N sail force. Its
fixture auto-feather rule was investigated alongside the stale outboard
reserve. The explicit yacht/tow driving mode holds the requested attack
instead of applying the inherited 2–6 degree fixture roll cutoff; this is
normal deliberate sheet handling. Actual hull tilt, injury, still-aboard,
strength and progress assertions remain; gust/tipping fixtures retain their
existing heel response. No game automatic control is added.

The yacht's apparent zero attack also exposes an outboard-length error in the
fixture: its reserve was captured while the player stood ashore, then preserved
after sitting at the nearer helm. A yacht/tow helmsman tending a chosen attack
must account for the current complete routed path and gather that real slack,
still at normal reel rate. The Varran tack helper retains its departure reserve
so it does not silently winch a moving multi-line rider into the rig.

With that real sheet handling, the unchanged yacht check passes in 28 seconds:
keeled upwind progress, sideways drift, staying at the helm, actual sheet
reeling, and resuming seated all remain asserted. The basic two-tack runner
check independently passes in 32 seconds.

For the tow steering comparison, the helmsman first trims, then holds that
actual paid length while carving. Continuing to pay out automatically during
the carve cancels the very line-load change being measured. Normal digital
braking plus a 40 degree look/carve offset produces +7.4 and −17.7 degrees
relative to the passive turn in 2.5 seconds, retaining the 6 degree assertions.
The tow trial measures 2.06 m/s following-camp speed and 67 N on the unhurt
rider. The deliberate hazard moves the former boom end to a real deck cleat,
ties the tow end to the waist, and lets the on-foot rider actually move between
rig and moored camp under a known 900 N rig pull. Disabling player motion had
artificially absorbed the force before the second line could take strain. The
real arrangement reaches 937 N opposing load and 21 health with both lines
intact; the worked line is unloaded before the independent reeling check.

The official visible-tow check passes in 26 seconds with those assertions intact.
