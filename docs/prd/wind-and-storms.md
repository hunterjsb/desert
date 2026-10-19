# PRD: Wind & storms

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

The weather is the main character. The wind is the difficulty dial, and storms are the
threat, the source of the coziness, and the thing that reshapes the land and uncovers
what's buried. Nearly every other system reads from this one: the rope, the camp, power,
farming, terrain, salvage and sound.

## What the player experiences

- **The wind is always there.** It pushes you, it strains your ropes, sand streams off
  the dune crests, and you can hear it.
- **Storms are common, almost persistent.** Clear skies are rare and earned (see the
  two moods in the vision).
- **The wall.** You see it on the horizon first: a wall of dust wider than your view and
  taller than the sky, moving toward you. The light changes, the wind turns and rises,
  and dust starts racing along the ground ahead of it. You have minutes to batten down.
  The wall fills the sky, then it's on you, and within seconds you can barely see past
  your shield. That's the cozy part.
- **Reading the weather.** You learn to read the wind and, with better instruments,
  predict where the storms are going.

## What Sand Game taught us

Two things worked: the distant look of the storms, and the darkness and intensity once
one caught you. The wall never happened, because the storm was an **object**: a dust
dome about 240 m across and 150 m tall, drifting with the wind. You could see all of
it, you could walk around it, and you entered it through a trigger area that faded the
light over 3 seconds. A wall needs the opposite of all three: no visible edges, no way
round, and an arrival that comes in stages.

## The model: weather is a field, not objects

Like the ground, the weather is one function. **`storm_at(place, time)`** gives a storm
intensity from 0 to 1, generated from the run's seed and carried along by the
prevailing wind. The visuals, the darkness, the damage, power output and forecasts all
read it. Nothing computes storminess any other way.

- **A storm is wherever the field is high.** Its edge (the front) is where the field
  crosses a threshold. A sharp threshold gives storms hard edges, which means walls
  instead of gradual fog.
- **Common and almost persistent** means the field sits above the threshold most of the
  time, in most places. Clear skies are gaps that drift through it. Finding a gap and
  staying in it is the diligence and luck the vision talks about.
- **Stateless and deterministic.** Nothing is stored. Because the field can be sampled
  anywhere and at any time, including the future, **forecasting comes free**: an
  instrument just looks ahead in the field.
- **`wind_at(place, time)`** is the prevailing wind (direction and strength drift
  slowly), plus gusts, plus storm outflow (the wind blows hardest just ahead of and
  inside a front).
- **Storms travel with the prevailing wind**, so reading the wind is reading the weather.
- **Storms usually move fast.** It's normally about 5 minutes from first seeing the
  wall to impact, and up to 20 minutes in rare cases. Most storms move faster than
  anyone can walk.
- **The field also changes over time.** Gaps open and close, storms grow and fade. A
  clear gap travels with the wind, so matching the wind keeps you in the clear, but
  only until the gap closes.

This also explains *why* the wind is the difficulty dial, without any extra rules.
Travel downwind and storms behind you close in slowly, because you're moving with
them. Travel upwind and you meet storms head-on, at their speed plus yours. You face
more storms, so you uncover more finds. The risk and the reward both come out of the
same field. The faster the camp travels, the stronger the dial: on foot, storms catch
you whatever you do, but the sand yacht can nearly keep pace.

**How long storms last** is a tuning target. Sitting a storm out is the main move early
on (Movement), so a typical storm should pass within a full base shield's 30 minutes.
Longer storms are the real danger, the kind that makes you carry spare batteries or
plant a turbine. Late-game camps can sustain through storms that last for days.

**How rare clear skies are isn't a number we set.** It comes out of how much of the
moon is stormy, how big gaps are and how long they last, how fast storms move, and how
fast and how cleverly you travel. We tune the field, then measure what reference
travellers actually experience (probe 7). Skill has to visibly earn more clear sky.

## The wall

This is the hardest problem in the game and the core of its feel. A dust wall feels
like a wall when:

1. **It's wider than the view.** The front is a curve across the whole horizon. You
   can't see its edges and you can't go round it.
2. **It's taller than the sky.** Real dust walls stand a kilometre or more tall and
   stretch for tens of kilometres. Up close, the top is lost in its own haze.
3. **It arrives in stages, not at a trigger.** The light dims as the wall blots out the
   sun. The wind turns and rises. Dust streams along the ground ahead of it, and the
   sound grows into a roar. Then the face arrives and visibility collapses within
   seconds.
4. **The face moves.** It billows, rolls and boils, with layers of motion at different
   depths, not one scrolling texture.
5. **It encloses you.** Once you're inside, the shield's edge is the edge of the world.

**What already lands** (Hunter, watching the look-test's first version on 2026-10-14). Its
approach is the feeling: a huge wall of dust, uniform and infinitely complex at the same
time, and overwhelmingly massive as it comes into view. The crude in-game wall, a flat
curtain on the front, looks nothing like it, so the full wall is built from the
look-test.

**Approach** (as built by the look-test, 2026-10-14).
- **One pass, from 5 km to inside.** Every pixel marches a ray through the storm, so the
  face never changes renderer and there's no hand-off to hide at contact. Godot's
  volumetric fog isn't used.
- **The face billows around the field's front.** Rounded heads with creases between
  them, at several sizes rising at different speeds. Small detail fades with distance,
  so far off the wall stays one mass.
- **A storm map carries the field to the GPU.** A worker samples `storm_at` round you
  every second, in the air's own frame, so storms ride the drift exactly. The field
  stays the one truth.
- **The game and the senses.** The game plays by the field: the storm state, harm,
  shelter. The senses follow the drawn face where your eyes are: light, fog, dust and
  sound. The darkness lands exactly when the dust visibly swallows you. The light dims
  in stages before that, as the wall blots out the sun and then towers over the sky.

**An early look-test** (decided). A standalone scene whose only job is making the wall
feel right, built alongside the skeleton. It isn't meat on the bones. It's finding out
whether the hardest thing is possible before we depend on it.

## Reading the weather

- **Your own senses first:** the wind on you, the colour of the sky, the sound.
- **The plants** (Agreed, session 4, part 3; not built): feral scrub closes up before a storm,
  a free barometer for anyone ([below](#feral-plants-the-free-barometer-agreed-session-4-part-3-not-built)).
- **Instruments are finds and upgrades.** A barometer shows a storm coming hours ahead.
  A wind vane shows direction and strength. A weather radio picks up forecasts, and
  maybe there's a storm map.
- **Better instruments see further into the field,** both further away and further
  ahead in time, and more accurately.
- **A lore hook (loose):** history runs backwards in the ground, so the best forecasts
  could come from the rarest finds, like a colonial weather station still broadcasting.

**How the wind moves things** (decided 2026-10-14, from the Stage 4 playtest). It's a
function of friction. Everything catches wind by its size: drag grows with the square
of the wind and with a thing's biggest face, at the rate the rope look-test's floater
was tuned to. Resting on sand, a thing has a friction of 0.5 to beat, so a breeze
leaves a loaded deck be and a storm slides it. Floating, nothing holds it, so it drifts off
downwind unless it's tied down. That's what rope is for.

### Instruments and the Console screen (proposed; first version built)

*Hunter, 2026-10-17 ([session](../console-sensors-sleep-2026-10-17.md)). Direction, not a final
spec. A first version is built (As built, below).* Weather sensing is "multifaceted: each instrument adds its own
stats, and the screen shows every stat available." The screen is [the
Console's](devices-and-mods.md#the-console-proposed-first-version-built). It turns the instruments named
above (a barometer, a wind vane, a weather radio, "maybe there's a storm map") into a set that
reads together.

| Instrument | Adds |
| --- | --- |
| Anemometer / vane | Wind speed and direction now |
| Barometer | Pressure trend: rough warning of an incoming storm |
| Hygrometer | Humidity (ties into the condenser) |
| Radar (top mod) | The storm front: distance and heading |
| Radio | Old weather-station broadcasts: forecast beyond the horizon |
| Particle sensor | Sand density: how hard the storm will hit |

- **Resolution scales with data.** "Sparse gear shows numbers; with all the gear (roughly two
  linked Consoles) the screen is effectively a storm mini-map."
- **Ground and ruin detection is separate equipment,** "looking down, not up," and "likely a
  different camp setup." It is not in this table. A loot beacon already points at a find from the
  radio, and the Archaeologist start lists a ground-penetrating radar ([the
  vision](../vision.md#player-origins-and-kits)). *Session 4, part 4, the newer, softens this:* "a
  basic survey mod on the console picks up buried metal," so colonial pipelines show as lines on
  screen ([Devices & mods](devices-and-mods.md#the-console-proposed-first-version-built), [World &
  terrain](world-and-terrain.md#readability)). A basic survey mod is a Console mod; heavier ground
  detection is read as staying separate.
- **The radio** is the table's radio row, and it already does the forecast half. Its weather
  station ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md), as built) speaks a
  forecast read from this field. The Console's screen would show it beside the other stats.

**Can a storm's intensity be queried ahead of time? Yes, already, with no change to the field.**
The session lists it as open, "willing to modify." Nothing needs modifying. `storm_at(place,
time)` is a pure function of the run's seed, the place and the time, so it can be sampled "at any
time, including the future," and "forecasting comes free" (the model above). `WeatherField` is built that way: `storm_at`,
`wind_at`, `steady_wind_at`, `outflow_at`, and `next_change`, which finds when a place's storm
state flips. The radio's weather station does it now. It reads the field where the radio stands,
20 minutes ahead, every 5 seconds, and speaks when a storm comes, from which way, its strongest
steady wind and how long it lasts (radio probe 1 and weather probe 3 check it is honest). A
storm's intensity curve at a camp is `storm_at` at the camp's place, sampled over time.

What is not built is a longer reach, or a reading of the curve itself: the radio speaks front
times and the peak wind, not the intensity along the way. Both are another reader of the same
function, not a change to it. Two limits come with it. A forecast is for one place, so it is a
forecast for staying put, and walking into the wind brings the storm sooner. And the cost grows
with how far ahead and how finely it looks. The radio's 5 s step over 20 minutes is cheap. A camp
asleep for days is a longer run of the same call ([Survival](survival.md#sleep-proposed)).

Readings, not in the session:
- **The instruments read the field, not the felt weather.** Inside a base shield the felt wind
  and storm read zero (Bubble shield & camp, rule 2), and a Console's camp sits inside its
  bubble. An anemometer or a particle sensor that read the felt weather would read still air in
  the one place it is meant to work. The radio's forecast already reads the field itself.
- **Three of the six have no field of their own.** The field is the storm, the wind and a
  front's outflow, and "nothing computes storminess any other way." There is no pressure,
  humidity or sand density in it. A barometer's trend could read the outflow, which rises "from a
  lead ahead of the front." A particle sensor could read the storm's intensity, which the dust
  and the damage already read. A hygrometer has nothing in the field to read, and the condenser
  reads only the felt temperature, so "ties into the condenser" would add a term to both.
- **Radar and a mini-map are the wall's own query.** The front is where the field crosses its
  threshold, and storms ride the prevailing wind, so a front's heading is the wind's. The storm
  map that draws the wall already samples the field out to 20 km each way on a 128 by 128 grid,
  once a second. A mini-map is that grid on a screen, finer with more gear.

**As built (2026-10-17, a first version).** Each instrument is a computer mod that adds its own
rows to the Console's screen. Every one reads the field itself, at the Console's place, never
the felt weather, so a bubble doesn't blind it. The field has no pressure, humidity or sand in
it, so those three are worked out from it, with their numbers in tuning. They read once a
second of world time.
- **Anemometer:** the wind now, gusts and all, as its speed and the point it comes from, as the
  deck feels it: the field's wind less the deck's own way over the sand (2026-10-18). "WIND 12.4
  m/s WNW", its angle off the bow and its steady part under it, and the true wind too while the
  deck moves.
- **Barometer:** pressure from the field. It's 310 hPa, the moon's thin air ([the
  moon](../the-moon.md)), where the field sits at its threshold, and it falls 8 hPa for each unit
  the field rises, so it falls as a storm comes. It shows the pressure and its trend per minute
  over the last two minutes. While the field here is rising toward its threshold, that trend
  carried on gives a rough time until the storm, and under 15 minutes it warns, a row in amber:
  "storm ~5 min". It's rough on purpose, a curve carried on as a straight line.
- **Hygrometer:** humidity from the cold and the storm, tied to the condenser by sharing its
  function (`Condenser.yield_lph`). It reads 60% in air as cold as a condenser makes its most in,
  less as the air warms, as the condenser's yield falls, and up to 25% more as a storm nears: the
  air grows humid over a kilometre or two ahead of its front, most in the storm itself. It shows
  what a condenser would make there too: "HUMID 37 %", and under it "condenser 6.2 L/h". The same function gives
  every cell of the map its humidity, so the blue laid over the map deepens toward each front and
  the reading is its value where you stand (2026-10-18). The condenser doesn't make more as a
  storm nears yet; that half of the tie is still proposed.
- **Particle sensor:** sand in the air, from the storm's intensity. A storm is at full intensity
  within about 100 m of its front, so the sensor also reads how deep into the field it is, as
  salvage counts a storm's heart (the field 0.4 past its threshold): from 0.9 g/m³ at a wall to
  3 g/m³ at the heart, and a little ahead of the wall from the front's outflow. It shows its trend
  over 30 s, as a small arrow. With a radar it also says how hard the coming storm hits: the most
  sand in its first kilometre ("hits 1.8 g/m³").
- **Radar,** on the computer-mod top: it sweeps 36 bearings, one a tick, stepping 100 m out to
  its reach, 6 km (a stat of the part), until the storm state changes, then closes in on the edge
  to 2 m. It reports the nearest edge, its distance and its point. Its heading is the way storms
  ride the wind. Its ETA is the storm upwind reached at that speed: the nearest wall is often
  sliding past to one side, and the upwind one agrees with the forecast. Inside a storm it gives
  the nearest clear air and when the storm clears, or that it runs on upwind past its reach.
  "FRONT 1.2 km N", then under it its eta, "5 min", which way it's moving, "8 m/s ESE", and
  "hits 1.8 g/m³". It samples the field round the Console itself rather than reading the wall's
  map, which is centred on you, not on your camp.
- **A radio on the Console's deck** (on its top mount until the chassis rework) adds the forecast
  it already makes (`Radio.forecast`, 20
  minutes ahead, read again every 5 s, where the radio is): "FCST 5 min storm", then under it
  where it's from, "WNW", its winds, "27 m/s", and how long it lasts, "9 min". It feeds the Console while it's powered and whole, whatever its
  dial plays aloud.
- **Resolution scales with data** (2026-10-18, replacing the first version's map that showed only
  with the full set): the map is always there while anything reads, and finer the more the system
  has. A radar alone draws 8 cells across its 12 km, each other kind of instrument 4 more, the
  full set 28, and a second radar linked half as fine again, 42. With no radar it's an estimate,
  hatched, from 3 to 9 cells across as instruments are added: the barometer's expected storm laid
  upwind along the anemometer's wind, as far as that wind carries it before it arrives. On the map are the front's numbers at the front,
  the pressure's bar, humidity over the clear air, sand in the storms, the forecast along its foot
  and the wind's gyro under it ([Devices & mods](devices-and-mods.md#the-console-proposed-first-version-built)
  has the screen).
- **Cost:** a radar's sweep is a bearing a tick, about 60 samples; its map a few rows a tick, a
  whole pass each second of world time, at most 42 by 42 samples, one a cell. At a fast clock both
  go faster, to keep up.

### Feral plants: the free barometer (Agreed, session 4, part 3; not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); the first piece of its
build order, and none of it is built.* Feral scrub "closes up or turns its leaves before a storm."
It is "a free, slotless, low-tech barometer for players without weather consoles, and the
knowledge nomads would have had by heart" ([the
lore](../lore-research.md#life-on-zan-feral-plants-agreed-session-4-part-3)). It sits beside the
instruments above as their cheapest form: the barometer row's "rough warning of an incoming
storm," with no device, no slot and no power. The session's build note: "A plant prop whose pose
(open → closed / leaves turning) is driven by the storm intensity curve with some lead time.
Requires the curve to be queryable ahead of time, which was already flagged for sleep."

**The curve is queryable ahead already, so nothing in the field changes.** The Console session
asked the same question and it is answered above: `storm_at(place, time)` is a pure function of the
run's seed, the place and the time, and `WeatherField` samples it forward for the radio. A plant's
pose is that function at the plant's own place, a lead time ahead. It keeps no state and is
deterministic like the rest of the field.

Readings, not in the session:
- **It is a forecast for the plant's own place,** as the radio's is for where the radio stands. A
  plant by the road you are walking shows the storm at that spot, not at you, and walking into
  the wind brings the storm sooner than the plant says.
- **The plant reads the field, not the felt weather.** Inside a base shield the felt storm reads
  zero, but scrub stands out in the world, and it has to show the storm that is coming, so it reads
  `storm_at` and nothing else.
- **The lead time is the open part.** "Some lead time" is the session's. For scale, a wall gives
  about 5 minutes from first sight to impact, the radio looks 20 minutes ahead, and a game day is
  20 minutes. A lead shorter than the radio's keeps the plant the lowest rung of the ladder, which
  is its role; the session sets none.
- **Which pose goes with which intensity is tuning.** Open when the field is quiet, closed or
  turned as it rises toward the storm threshold; the session says only "open → closed / leaves
  turning."
- **Cost is a handful of samples a plant,** only for plants in loaded chunks, at a low rate like
  the radio's 5 seconds. The count in view is a tuning matter.

The plants are also a trail and a source of lore and loot ([Farming](farming.md#feral-plants-and-a-crops-history-agreed-session-4-part-3-not-built)).

**Session 4, part 4 names the plant, and defers it (Agreed).** The weather-sign plant is
**saltbush**: its leaves fold when pressure drops, protecting the salt bladders, and the Sisters
seeded it along pilgrim roads, so a line of it is also a trail ([Farming](farming.md#each-crop-ancestor-engineering-drift-and-hooks-agreed)).
That is the generic feral scrub of part 3 given a species and a reason. The same session puts
"feral plants as weather sign" among its deferred pieces, "needs the queryable storm curve from the
sleep work," and orders the plants' placement after world generation. Part 3's order had the weather
sign first. The newest wins, so it is deferred in the proposed order.

**The dependency it names is already met.** The session waits on "the queryable storm curve from the
sleep work." That curve exists: `storm_at(place, time)` is a pure function of the run's seed, the
place and the time, `WeatherField` samples it forward, and the radio's weather station reads it 20
minutes ahead every 5 seconds (the section above answers the Console session's same question, "yes,
already"). Nothing in the field or in sleep has to be built first, so the deferral is a matter of
order, not of a missing piece. A saltbush's pose is `storm_at` at its own place, a lead time ahead.
It can be built whenever the plant prop exists, and it needs nothing from sleep.

## Storms as planning sessions (Agreed, session 4, part 4; not built)

*[Session 4, part 4](../plants-worldgen-ruins-2026-10-17.md); labels as the session gives them (Agreed,
Idea, Back burner, and anything under its open questions undecided). None of it is built.*

"A storm can last 20-40 minutes, a whole play session. It becomes the reflective half of the loop;
calm is the active half." The storm is for:
- **Reading the storm.** The Console and the plants show where it is heading and what it may uncover.
- **Planning routes.** Map, known roads, spotted signs; pick the post-storm target and the long-term
  goal.
- **Tending camp.** Water crops fill, fungus blooms and glowcap lights up; harvest and process.
- **Listening.** The radio carries better in some storms.
- **Crafting and repairing.** Fix storm damage, rearrange mods.

This is the other half of the loop in [Salvage & ruins](salvage-and-ruins.md#two-channels-agreed):
shelter and catch drift while the storm rages, then go into its wake to hunt what it uncovered.

Readings, not in the session:
- **The length is the long end of the field's.** Here the median storm is 17 minutes and 71% pass
  within a base shield's 30 (open questions), the longest past three hours. A storm of "20-40
  minutes" is a long one, not a typical one, and the multi-day ones are the sleep proposal's case
  ([Survival](survival.md#sleep-proposed)). The two answer different storms. Whether a planning
  session makes sleep less needed is not said.
- **"What it may uncover" needs exposure to be forecastable.** If a site's state is a function of the
  weather (Salvage & ruins), the same function run ahead says which stretch of ground a storm will
  strip. The session does not say the Console shows it.

### Storm-only mechanics (Back burner)

Liked, and not to be built yet:
- **Wind power surge:** turbines spike and charge batteries hard.
- **Static harvest:** particle storms build charge, and a lightning rod or collector captures a big
  spike, risking fried electronics. Ties to quietbloom.
- **Deep exposure:** mid-storm sand movement briefly opens the deepest ruin layers. *Built 2026-10-18 as the
  storm's own work on a site ([Storms with a payoff](#storms-with-a-payoff-agreed-2026-10-18-spec)).*
- **Storm blooms:** storm crops fruit only now.
- **Radio windows:** some conditions carry distant transmissions.
- **Glass forming:** lightning in heat storms fuses sand into glass, a crafting material collected in
  the wake.

Deferred in the same list: feral plants as a weather sign, landmark interiors and heat shields.

## Storms with a payoff (agreed, 2026-10-18 spec)

From Hunter's [storms, signals & sailing spec](../storms-signals-sailing-2026-10-18.md):
- **Storms expose and rebury ruins.** Big shifting dunes lay bare ancient structures and the best
  loot mid-storm, for the active player willing to go out; the storm can bury them again, so a ruin
  seen mid-storm may be gone by morning (the desert ate it, which makes a chunk dropping out canon).
  Lower-tier loot blows downwind, so a stationary camp still gets some.
- **Finding them in the dust:** first a glint through the dust and a metallic clang on the wind;
  later the particle sensor or ground radar pins the site on the Console.
- **The anomaly:** a rare storm whose real intensity spikes far past every forecast. Forecasts and
  instruments read only the clean curve; a hidden multiplier applies at damage time only, skewed
  to particle damage, so a camp built only for wind is wrecked. Its tells, from the hidden term:
  compass drift, odd radio static, and a shield's particle load climbing while the wind reads
  normal. It's the storm the Walker misjudged. Built, and the spec's open question, how often and
  how strong the skew, answered ([below](#the-anomaly-as-built-2026-10-18)).

### The anomaly, as built (2026-10-18)

- **Where it lives.** A property of the air in `WeatherField`, pure in the seed: hearts on a lattice
  of the moving air's frame, patches 20 km wide, and of time, spans of 4 hours, each pair holding one
  with a chance of 0.37. A heart rides the drift as the storms do. It reaches 8 km, full within the
  first 2, and lives two hours either side of its peak, full for the middle 80 minutes. Its hidden
  term (`anomaly_at`, 0 to 1) is the heart's share there times how near its storm is: from nothing a
  kilometre or two ahead of the front (0.25 in the field's own units) to whole at the wall, so a
  heart over a clear gap is nothing. The storm field itself is untouched.
- **How often** (the spec's open question). One storm in ten that passes a still camp holds one: 123
  of 1,250 storms over 12 seeds and 90 days each, about one every six hours of play (the median gap
  3.1 hours), and more for a camp travelling into the wind, which meets more storms. A third of
  those bring the heart's full over the camp. None comes in a run's first five days, 100 minutes,
  counted from its own start (`World.began`; a new run begins days into the weather's clock, on day
  11 for the probes' seed): ordinary storms are learnt first. A heart whose life began in those days
  never forms, so none fades in either. The anomaly scenario asks for one, so its dev run has no such
  days (`World.anomalies_any_time`). One in ten is rare enough to be a story and frequent enough that
  a long run meets two or three, enough to learn the tells and to record one for the Walker.
- **How strong the skew** (the other half). At the heart the real damage is 5 times the clean
  curve's in particles and 1.5 times in wind past what's stood: of what it adds, eight parts go to
  the sand for one to the wind. So a full storm's 200 W shield draw is 960 W; a turbine sized for an
  ordinary storm's 200 W falls 760 short, so a base battery behind it lasts eight minutes; and out
  past the bubble things wear five times as fast (a device wrecks in two minutes, times its
  toughness), and in the open you lose health at 1.25 a second, not 0.25. Over the storms that
  hold one, the median adds about 100 Wh to a shield's draw, a base battery's whole charge, so a
  camp built for wind on one battery runs dry in about half of them; in the scenario its turbine
  wrecks and its battery is all but flat. The wind's share stays small because what a camp builds
  for the wind (lines, a turbine, a dune's lee) reads the wind as it is: the lee takes two-thirds of
  the wind and only a third of the sand.
- **Damage-time only, through one door.** `Weather.hidden(at, t)` makes the term the two
  multipliers, and only what deals damage asks it: devices' wear (Wear), your harm (Vitals), a
  crop's wind and dust, in a planter or wild (`Planter.felt_at`), and a shield's load
  (`ShieldGenerator.particle_load`), which sets its draw and counts toward Sandblasted as what it
  really held off. Everything else reads the clean field: the storm state, the light and dust, the
  wind that pushes and loads lines, every instrument, the radio's forecast, the readout's next
  change, the Console, salvage's exposure and the sleep's plan.
- **Sleep.** The night lives through the anomaly: power, wear, the farm and your vitals live each of
  its steps through the same functions, so a shield sized by the forecast runs dry at the heart, the
  storm comes in and wakes you. Its plan, through the storm or until the station calls, was made on
  the clean curve.
- **The tells,** each read off the hidden term where it stands, and none spoken by any forecast:
  - **They rise for about five minutes before the heart's full** (the median from a fifth of the
    term to nine-tenths, for a still camp; a quarter of them under four, a quarter over eight),
    starting ahead of the wall when the heart rides in on it, inside the storm when it follows.
  - **The compass leans toward the heart,** steadily, up to 60° at its full and never past the
    heart's way, fading within 300 m of it, where a storm's dust only swims it quickly both ways.
    Ahead of the wall, in clear air, the needle settles off north and stays there, and it follows
    the heart round as it passes over.
  - **The radio crackles,** on every channel and inside a bubble too, while the weather station
    reports an ordinary storm: its static thinned and pitched up (1.4 to 2.2 times), cut into
    bursts of 70 ms with under half of them sounding, as loud as the term is deep and at most half
    of full static, where a storm's static hisses steady.
  - **A shield's load climbs past a full storm's,** which only an anomaly makes: its draw with it,
    as you read it looking at the shield ("draws 960 W"); its hum straining up in pitch, from 0.9 to
    1.25 at the heart; and on the Console's stats each shield's "load" under its line, in per cent of
    a full storm, marked past 100, while the anemometer's wind and the particle sensor's sand read an
    ordinary storm (at the probes' heart: load 500%, sand 1.35 g/m³, wind 27 m/s).
- **The hook** for the map and the Walker's feed: `WeatherField.anomalies_near(x, z, t, reach)`
  lists every heart within reach at a moment, where it is, its reach, when it peaks, how strong it
  stands and its share at the place. Only the compass reads it now; teaching the Walker is its own
  quest line.
- **The scenario,** "anomaly": clear, its storm due in two and a half to five minutes, the heart's
  full over you within five minutes of the wall, facing upwind beside a camp built for wind: the
  reference camp's deck resting on the sand, moored upwind; a Console reading the wind and the sand;
  a radio on the weather station; the base shield on one battery, running, all stuck on the deck;
  and a turbine out in the gale on a strong cable from the radio's port, enough for an ordinary
  storm. A compass is in your suit. It's searched
  wherever a heart passes within 60 km of where the run began, from the clock's start for up to 200
  days: hearts are sparse, and 30 km and 30 days found none on one seed in eight (how Hunter met
  it, 2026-10-18), where this finds one within 23 days on each of 60 seeds tried. The dev overlay
  shows the hidden term where you stand (`weather/anom`).
- **Its deeds** (agreed 2026-10-18): Eye of the Anomaly and Tells, hidden, in the Weather tree (built
  2026-10-19), and Taught with the Walker's quest ([Profile & saves](profile-and-saves.md#round-two-the-trees-that-tie-it-together-agreed-2026-10-18-step-1-built-2026-10-19)).

## Dune archaeology (agreed, 2026-10-18 spec; built 2026-10-19)

From the [chassis spec](../chassis-kits-dunes-2026-10-18.md): the lee, drift and exposure systems talk to each other, so camping
by a big dune becomes a way to play: let the ruins come to you.
- **Exposure gets a dune term:** more stripping on a windward face and crest, more burial in the
  lee, still stateless.
- **Dune ruins:** a seeded ruin under each big dune, uncovered only past an intense storm, so nearly
  every big dune yields something in a big one; seeded, never spawned on noticing the player.
- **Light loot over the crest:** in a storm it falls out in the lee of crests near camp too, not
  only at staked lines.
- **Three ways to play it:** up to the windward crest mid-storm for medium loot; stay in the lee and
  let light loot come; wait and dig the bared ruin after. **Storm chasing** is the same high tier
  metered: many freshly bared sites in their window, volume over depth, no new table.
- **Lazy loading:** a buried site costs nothing at chunk load, a seed only; exposure checks run on a
  low-priority queue by distance, and a site builds only once bared and you've slowed nearby, so a
  fast rider never stutters on what they pass.

**What there was already** (the spec's open question: "How much storm-exposed loot and reburial already
exists in code?", answered 2026-10-18). A good part of it, held still. A site's exposure was the
weather's: the sand off it was summed over the last 12 hours of storms in 30-minute ticks, so a storm
that had come and gone left it deeper and calm let the sand back, and its loot was gated by it (buried,
19 of 305 things showed; dug out, 298; an era's best only past a storm). But it was read when the site's
ground was first built and held while that ground was loaded: nothing changed in front of you, and a
17-minute storm could fall between two ticks and count for nothing. Drift was the storm's own stream,
caught on a line between stakes, five times as much in a lee, from nowhere in particular. Skyline's glints
showed bare metal by a site's state and went out in any storm. Nothing was "newly" exposed, nothing
clanged, and no site shed anything.

**As built (2026-10-18)**, the first two bullets ([the world system](../world-system.md#what-storms-do-to-sites-now)
has the detail):
- **A storm works the site it sits on.** Its heart moves sand a minute at a time where its big dunes move,
  off a site or onto it, in patches 400 m across that change over 15 minutes, and what it moved comes back
  within minutes once it lets go: in a storm's heart it has more than a metre off a site 45% of the time,
  and after a storm's height its sand is back to a tenth in a median 13 minutes. A ruin seen mid-storm may
  be gone by morning. It's a pure function of the field's history, read between minute ticks, so a site's
  state at any moment is known without anyone having watched it: saves, sleep and far stand-ins agree.
- **A loaded site changes live**, a frame at a time: its look, its boxes and what it holds rise out of the
  sand or sink back, its ground pressed afresh in steps of 2.5 cm, never popping and never over you or
  your camp; what you've taken stays taken. **A chunk unloading is the desert eating it:** come back and
  the site is as the weather has it then.
- **The best loot shows mid-storm.** A site's deepest sockets open only once a storm strips past them, so
  mid-storm they're open for the active player who goes out: at 1.4 m deep, 38% of the time in a storm's
  heart against 1% on the settled sand alone. This builds the back burner's "deep exposure."
- **Lower-tier loot blows downwind.** A site laid bare sheds its light lesser things into the drift
  stream, carried along the wind and caught by the same lines and lees: about one thing a storm on an 8 m
  line 30 m downwind in the open, five times as many in a lee.
- **Finding them in the dust.** What a storm newly lays bare glints through the dust out to 90 m in the
  dust's glow, whichever way it faces you, Skyline's glints let through near; and clangs on the wind now
  and then, heard to 140 m
  after the sound's trip, duller the further. `sites.newly_exposed` lists the sites a storm has newly
  laid bare near a place; the ground radar pins them on a Console's survey page (below).
- **Probes:** kits 3 and 4, loot 7, sightlines 4, saves 23.

**As built (2026-10-19), the rest** ([the world system](../world-system.md#what-storms-do-to-sites-now) has
the detail):
- **The dune term.** Where a site lies among the dunes weighs its exposure (`Exposure.dune_at`), -1 to 1,
  read from the bare dunes along the run's long-term wind, which they face: toward 1 on a windward face or a
  crest, toward -1 on a slip face or in a crest's lee. On a face or crest the weather strips up to twice as
  hard, the storm's work off it too; in a lee the sand comes back up to twice as fast, the storm's work onto
  it too **(defaults)**. Still pure, in the dunes and the field's history. Over three days of seed 1234's
  weather, halfway up a big dune's windward face 3.6 times the sand is off that open sand would have off, and
  in its lee a third.
- **Dune ruins.** One seeded ruin to each 300 m of a big dune's crest, a dune standing 14 m or more over
  the trough past its slip face, in its own lee: on the flat past the foot of its slip face, where the dune
  term has the lee deep, a colony's hab pod or now and then a First Kingdoms hut, 5.5 to 6.5 m deep
  **(defaults)**. 35 of the 40 big dunes within 1.5 km of the start hold one. Their weather is any site's;
  the lee and the depth keep them: through two days, storms that never bring their heart over one leave it
  under the sand (8 bared of 1,162), and one whose heart holds over it half an hour or more lays nearly
  every one bare (136 of 160). Once the storm lets go it's back under in minutes, unless you're standing on
  it. What they hold is kept whole under the dunes, survey gear among it: sieves on their shelves, a ground
  radar most often in their deepest cache (`SiteLoot.DUNE`).
- **Light loot over the crest.** In a storm light things fall out of the slowed wind in the lee of a crest
  near camp with no line at all: within 24 m of you or a deck of yours, wherever the lee is half or more,
  0.5 things an hour on a hundred square metres of full lee in a storm's heart, a pile's worth at most (8)
  lying there **(defaults)**. Under a tall slip face, a storm's hour round its heart lets about 3.6 fall
  round you, open sand none. It's the open drift's stream, what the wind carries, laid as drift is: on the
  sand, held there, yours.
- **Lazy loading.** Checked first: `structure.gd` builds every standing site at chunk load whatever its
  state, its ground pressed, its look and boxes made and its loot laid. A dune's ruin is a seed only
  (`DuneRuins`) and costs a chunk's load nothing. While you're slow (under 4.5 m/s for 2 s), a worker at low
  priority finds where the seeds within 300 m lie and reads how far out of the sand each is, nearest first,
  each again every 15 s of world time; a ground radar's place is looked over whatever your pace. One a storm
  has bared builds into the site index once you're within 150 m and slow, the chunks under it pressed afresh
  with it on a worker **(defaults)**. Ridden past bared at 20 m/s 40 m off, nothing of it is found, read or
  built, and the seeds cost the frame 0.03 ms. Measured on a 1.5 km ride along the crests at 20 m/s: built
  as history's are (every one found, bared or not, slow or not), 10 ruins built on the way and the terrain's
  slowest frame was 4.5 ms (laying their finds 4.2 ms, a worker's turn finding them 28 ms); built lazily,
  none, and 0.95 ms. Once built a ruin is a site like any other until the sheet lifts it 1.8 km off.
- **The archaeology setup** (the spec's open question, decided 2026-10-19): a ground radar fitted to a
  Console, a sand scoop and a sieve, all on one deck ([Devices & mods](devices-and-mods.md#the-ground-radar-and-the-sieve-built-2026-10-19)).
  Why these: the radar is a Console sensor mod, as the spec asks, and its page the survey Devices & mods
  already planned; the scoop is the dig there already is (a wreck's packed holds), so the digging tool
  builds on it rather than adding a second; the sieve is the one new thing, and earns its place by sifting
  what the scoop digs. One deck, because a setup is a camp you put together, as the home's three are.
- **Digging a ruin out yourself** (the other open question, decided 2026-10-19). The scoop held on the sand
  over a site's ground digs it out as a storm would lay it bare: its footprint's area a metre deep at 1.5 s
  a cubic metre **(default)**, a hab pod a metre in 72 s, rising out of the sand as it goes through the
  same exposure, ground steps and finds a storm's work does. What's dug is the site's memory, apart from the
  weather's function, so a storm never undoes it, and never past dug out, so the deepest sockets still want
  a storm. A wreck's sand is its holds' and the ground's own isn't dug. A dune's ruin still only a seed
  (found by the radar under the sand) can be dug too, and builds once something of it shows. **It's yours,
  not a storm's,** when a dune's ruin comes dug out with at least half its depth off by your hand: what the
  storm took counts against you, so it's a ruin dug after the sand came back, not one a storm handed you.
  Why: it reads the deed as it's worded and is plain to see. "No digging under the surface" holds: what
  comes off is the site's own sand, its rooms' fill and the drift on its walls, never the dunes' and never
  below its floor.
- **Sifting.** A sieve in your suit, or set down or stuck on a deck within 4 m, sifts what the scoop digs:
  a light thing of the site's lesser rows for every 50 m³ (0.02 a cubic metre) **(default)**, from its own
  stream of the site and how many have come, laid at your feet. A dune's ruin dug out yields about five.
- **The three ways to play,** as built: up the windward crest mid-storm (the dune term strips it hardest);
  in the lee, letting light things fall round you; and after, the ruin a storm bared, held bare while you
  stand on it and dug out by hand. Storm chasing is as before, the dune ruins among the sites it reaches.
- **The `dig` scenario** stands you by a big dune's ruin a storm has just laid bare, a scoop in your hands
  and a sieve carried.
- **Probes:** kits 6 (the dune term strips a windward face more than its lee), 7 (a big dune's ruin bares
  only past an intense storm), 8 (a buried site costs nothing until it's bared and you've slowed by), loot 8
  (light loot falls in a crest's lee) and loot 7 standing its ruin in the open; Profile & saves 32 and 33.

## What storms do to everything else

These are owned by their own PRDs and listed here so the field serves them all.

- **You** (Survival): darkness, near-zero visibility, wind pushing you, and damage
  outside the shield.
- **The camp and rope** (Rope, Camp): wind force on everything tethered, and gusts that
  strain the ropes.
- **Power** (Power):
  - Solar falls to almost nothing in a storm, though some types might keep a little.
  - Wind power is strongest in a storm, but it has to be planted to work, so you either
    stay put or leave it behind.
- **Farming** (Farming): ordinary crops struggle through long storms, and fungus thrives
  in them.
- **Terrain and finds** (World & terrain, Salvage): storms uncover finds, and land
  generated after a storm passes is new.
- **Sound** (Radio, sound & atmosphere): a roar outside, muffled inside the shield.

## The lee of a dune

(Hunter, 2026-10-17: "camping against a steep dune when the wind is coming from over top
of it should provide some shelter".) The ground breaks the wind. Downwind of a crest that
stands well above you, the wind is weaker: most of all close under a steep slip face,
fading out a few crest-heights further on, and not at all on the windward side or on
open flats. It's read from the one ground (`height_at`) upwind along the wind as it blows
now, so it turns with the wind: the dunes face the prevailing wind, so their slip faces
are the usual shelter, and a storm blowing from another quarter may leave you exposed.
It's a share of shelter, through the same felt-weather wrapper as a bubble's, so
everything that feels the wind feels it: you, the camp, the ropes, the turbine. It takes
the edge off a storm's wear but never stands in for a shield, and the dust and darkness
still come over the crest. Camping in the lee is a choice with a cost: less wind for the
turbine.

**As built (2026-10-17):**
- **Where it is.** The ground is read upwind of a place, along the wind blowing there
  that moment, at 32 places out to 250 m, close together near and spreading out further off.
  Each crest found shelters the place by three things: how many of its own heights away
  it stands (fully out to two, not at all past seven), how far above the place it rises
  (from 1.5 m, fully from 6 m, well over your head), and how steeply the ground falls
  from it toward the place (from 16°, fully from 26°). The best crest counts. A place on
  a slope climbing into the wind gets none (from 2°, all of it by 8°): the wind has come
  back down to the sand and speeds up it.
- **How strong.** A full lee takes two-thirds of the wind (65%) and a third of a storm's
  wear and harm (33%). Under an 18 m dune on the probes' seed it's full from high on the
  slip face to about 15 m past its foot, half about 45 m past it, and gone where the
  next dune's windward ramp starts, about six heights from the crest. A storm's 25 m/s
  blows about 9 at the foot, so you stand without being shoved and nothing past 20 m/s
  harms you or wears your devices there; the storm's own harm and wear fall by a third.
- **It turns with the wind.** Slip faces lie at 31.5° and windward ramps at 14° at most,
  so only a slip face throws the wind clear. The dunes face the long-term wind, so a
  slip face's foot is the usual shelter. As the wind swings across a face its lee
  thins, and from the other side a dune shelters nothing: the same foot is exposed.
- **What feels it.** Everything that reads the felt wind and storm: you, loose things,
  ropes, the board, harm, wear and power. A bubble keeps out its share of what the lee
  lets through, so the light shield under a slip face leaves 5% of a gale. The storm
  state, the darkness, the dust's thickness, the storm face and a shield's draw stay
  the field's: the dust and the dark still come over the crest. The wind's sound, the
  dust streaks and grit and the view's buffeting follow the open air round you, lee
  and all.
- **The turbine.** Its output goes with the cube of the wind, so in a full lee it makes
  about 4% of what it would in the open. Camping in the lee costs you the turbine
  unless it stands out of it, up on the crest or out past the lee.
- **It's a place's.** It's read at the ground under a place, so everything standing
  there shares it, and still air has none.
- **Cost.** Worked out at points 4 m apart for headings 2° apart and blended between
  them. Each point is a pure function of the ground and the heading, so the cache only
  saves work and the weather stays deterministic. It reads the ground's own samples
  every 2 m, which every loaded chunk holds, near or mid. On the dev machine, under
  load, a read costs about 2 µs on top of the field's wind at the place (about 4,
  which the felt wind reads anyway and the felt storm now reads too), and the
  reference camp makes 14 a tick, well under 0.1 ms. A fresh point costs about 80 µs,
  so when the wind turns past a 2° step the camp's 14 points cost about 1 ms in that
  one tick, once every half minute or more.
- **On the dev overlay,** `lee` beside `shel` shows the share of the wind the ground
  keeps from you, and a camp's walls with it (below).
- **The lee scenario** stands you at the foot of a tall slip face, its crest at least
  15 m above you and a lee at least nine-tenths full, facing up it into the wind coming
  over the crest, in the clear with a storm due in two to six minutes.

### A wall's lee (built, 2026-10-19)

Hunter's [spec](../chassis-kits-dunes-2026-10-18.md#wind-on-faces): a camp's upright faces
catch the wind and shelter what's behind them like a small dune, edge-on to travel and
broadside as a windbreak when camped. Each deck's faces standing across the wind and still
in it (a wall, a screen, fabric; Devices & mods, wind on faces) cast a lee, through the same
felt-weather wrapper as a dune's, so everything that feels the wind feels it: you, crops,
devices' wear, loose things, ropes, the turbine and other decks' faces.

- **Where it is.** Behind the face along the wind blowing at its deck, full for two of its
  heights and gone by seven, as a crest's, and across and up as wide and high as the face
  stands to the wind, fading out within three tenths of its height past its edges. An
  angled face casts a narrower lee and a weaker one, by how squarely it meets the wind;
  edge-on, none; a shelf, level, none.
- **How strong.** A full lee's share, as a dune's: two-thirds of the wind (65%) and a third
  of a storm's wear and harm (33%). Behind a 1 m wall broadside to a 12 m/s wind, the wind
  1.5 m back is cut by 65%, and a 3 kg box resting there stays put where the same box in
  the open slides 1 m in two seconds (probe 22). Under a dune it takes its share of what the
  ground's lee lets through, and a bubble keeps out its share of what's left.
- **Its own deck.** A deck's own walls don't shelter its own faces, which shade one another
  instead, but the rest of it behind them (devices, what's stuck, its pieces' edges) catches
  only the wind they let through: the Surveyor's camp with its wall upwind catches about half
  at its middle what it does with the wall to leeward. A frame open away from the wind with
  its back closed shelters its inside the same way.
- **As it stands now.** Read as shelters are, at any time asked; worked out again only when
  the wind's way across the deck turns 3°, and a deck held in your hands casts none. A read
  costs about 2 µs near a camp's walls and 1 µs elsewhere, on top of the field's wind.

## Plumes

*Built 2026-10-18, on the `plumes` branch, from Hunter's brief ([geology and
plumes](../geology-and-plumes-2026-10-18.md)), a second round after he played it ("vent is cool, nice
and ashy... i did see the smoke change... works. but i want these epic, distance plumes with booms
too!"), and a third, the look as it is now, when the smoke didn't sit right: "the plumes kinda take me
out of it too. they dont look great, just like the smoke is weird. i know performant smoke is hard to
do, thats why i was thinking its mostly emitting gas at this point so its just massive sand plumes that
are epic from a distance but really just blend into the storm and or the haze when up close cuz theyres
so big". The vents and the gas pockets are the world system's ([Geology](../world-system.md#geology)),
and so are the brief's ten questions, answered there; the booms are [Radio, sound &
atmosphere](radio-sound-and-atmosphere.md#distant-phenomena-agreed-2026-10-18-spec)'s.*

Han's rift has two live vents, one past each end of the pipes, and the far-side volcano a flank vent
below its capped summit. Each vents all the time and now and then bursts; round the rift, gas pockets
blow out. What comes out is mostly gas, hot and unseen, and what you see is the sand and dust it sweeps
up from round the mouth and lifts: a vast column of the storms' own dust. They're geological events at
one place, not weather: they never come to you, a vent has a mouth you can walk to, and from tens of
kilometres off a column stands over the horizon, and over the storms, that you can steer by. Storms are
horizon-wide walls that advance; a plume is a column from a point, towering 1.5 to 3 km and bending over
into a long dusty ribbon downwind, and a burst swells it to 6 to 10 km, spreading out at its top. Up
close it's no thing at all: walking into it the air thickens round you, as walking into a storm does.

### The physical abstraction

- **What shows.** The gas doesn't (which gases, and how much of each, is left open: the science
  brief's guesses are carbon dioxide, sulphur gases and water vapour). The sand and dust it lifts do,
  the storms' own: their colour, their light and their billows. The gas gathers it up round the mouth
  as it rises, half of it there and all of it by 40 s; the sand falls out of it by e over 150 s,
  leaving the fine dust, a third of it, that stays up for the column's ten minutes. A burst's ash is
  a faint trace at its core, darkening it by up to a third and gone in a minute and a half.
- **How it rises: Briggs's buoyant plume.** Bent over by the wind it climbs as 1.6 F^1/3 x^2/3 / u
  (x downwind, u the wind), and levels where the air's stability stops it, at 2.6 (F / u N²)^1/3, or
  5 F^1/4 N^-3/4 in still air. Levelled, it spreads out sideways as a current does in stable air, a
  quarter of N times its height in metres a second, wider than it's deep: a burst's umbrella. F, its
  buoyancy flux, is `plume_buoyancy` (300,000 m⁴/s³, a look value: tens of gigawatts of heat in thin
  air, a strongly degassing vent) times how hard the source is venting as it leaves; N, the air's
  stability, is 0.009 /s by day and 0.016 /s by night **(defaults)**. So a seep's column stands about 2
  km in a 10 m/s wind by day and 3 km in a calm, lower and flatter at night. A burst, at 25 to 170 times
  the seep (7.5 to 50 million m⁴/s³, the strongest an active vent's explosions honestly reach short of a
  great eruption), climbs for three minutes or so to 6 to 10 km in a breeze and spreads over many
  kilometres, holding its height for a minute and a half and fading by e over four minutes; a pocket's
  blowout, at 1.7 to 6.7 times, throws a kilometre or two up the sand it bursts
  through, twelve times a vent's dust for its lift. It rises
  from 150 m wide, the sand swept up round the mouth, widens by a quarter of its rise and spreads by 4%
  of how far it's gone.
- **Gravity and the air.** F goes with gravity, and N² does too, so how high a plume levels doesn't
  change with gravity; only how hard it climbs at first does (the dev gravity switch shows it). Thin
  air lifts more for the same heat; that's folded into `plume_buoyancy`.
- **Transport.** What left the source at a moment is where the field's own drift has carried it since
  (`drift_at`, exact for the prevailing wind, so the tail curls as the wind has turned), plus a front's
  outflow along it, taken as the mean of then and now. Each point of its streakline (24, from the mouth to
  ten minutes old) is a moment's parcel; the column is drawn round them.
- **Deposition.** What's on the ground is the long record of the old eruptions, not today's dust: a
  fan of grey ash down the long-term wind (the dunes' own) from the nearest live vent within 3.2 km, by
  e every 260 m, dark cinder within 16 to 44 m of the slot and sulphur in its throat, drawn by the sand's
  look.
- **Storms.** A storm's dust between you and any part of a plume hides that part, and from inside a
  storm you see none of it, as you see nothing far there. Within the storm walls' reach (15 km) it's
  judged pixel by pixel against the storm pass's own faces and billowed tops, so a column meeting a wall
  goes into it and what towers over a wall's top shows over it; past that, against the field itself,
  striding through clear air by how far the nearest dust must be, so no storm is stepped over
  (`Plume.seen_through`, which the skyline uses too). A storm's dust takes what's behind it as the air
  in one does: all of it past 400 m. A storm's shadow dims the sun on it, by the storm walls' own
  reading. Storms don't feed it and it doesn't feed them: their outflow bends it, nothing more.
- **Light.** The storm walls': the sun through the column toward it and through any storm, with the
  walls' share kept on its shaded side; the sky's, less in its creases and deep in it; the eclipse
  ring's thrown forward; Tu's shine by night; and the same haze.

### What's built

- **Up to three plumes** (`Plume`, `game/weather/plume.gd`, under Weather): the nearest sources in sight,
  each kept by its plume while it's in sight. Each frame a plume works out a little of its streakline
  from the time, its source and the weather alone (its young end, which changes fast in a burst, one
  point every other frame, the rest one point in eight frames, a quarter as often past 3 km), all at once
  after a jump. Nothing is simulated or stored: it's a pure function of the time.
- **The column** (`PlumeDraw`, `game/weather/plume_draw.gd`): a compute pass after the storm pass,
  every plume in sight marched at half the screen's size, a quarter of the rays, and brought up to full
  size by depth, each pixel from the half-size ones nearest it in distance, so a dune's edge in front
  of it stays sharp. The march runs through the dust round 15 points of the streakline (all of its
  young end, where a burst's column stands, and every few of its tail), each stretch a cone as wide as
  the plume there and, levelled, as flat, the stretches blended where they meet so none hands over to
  the next with a seam. Its face carries the storm walls' own billows, their two big octaves under
  their slow warp, at its scale: a wall's biggest tile three of its widths, churning slowly up it. Its
  width swells and narrows along it by up to a sixth seeping and two fifths in a burst, by what left
  at stronger and weaker moments, so the swellings ride up it. Its dust takes at most five optical
  depths a width, its face stepped finely where it's that dense, so a face shows its billows' shape;
  through thin dust the steps lengthen. Lit as a wall is, with its own shadow read half its width
  toward the sun: dark in its body, its sunlit tops bright. Where a burst began between two points the
  stretch joining them isn't drawn: the burst's first gas there is thin. The march strides through clear
  air by how near any stretch may come, never by where its bounds start, so where a ray meets it
  doesn't hang on them. Each group of rays reads the plumes into its shared memory once.
- **Up close it dissolves.** Within 120 m none of it is drawn, fading in by 500 m, and the air you stand
  in takes over: stood in its dust (`Plume.air`, from the column as the shader would find it), the haze
  closes in to how far that dust lets you see (3 over its dust a metre, 60 m to 4 km), in the storm's
  fog colour and as thick as the haze can be, the light dims by half a storm's, and Atmosphere's grit
  and dust parcels blow round you, a storm's grit seven-tenths as thick. At a seeping vent's mouth in a
  breeze you see about 2.6 km; under its thicker column, or a burst's, far less.
- **Far off.** Its rays aren't the camera's far plane's: it dissolves into the distance between 30 and
  45 km (Tuning `plume_fade_m`), much further than the
  storm walls, since what towers over the haze stands clear of it. Past the skyline's reach (3 km) it's
  a landmark: the haze takes it as if it were only as far as distance to the 0.3 power says. Dunes in
  front hide it. The flat world shows it further than a real moon's curve would.
- **Booms and a roar:** [Radio, sound &
  atmosphere](radio-sound-and-atmosphere.md#distant-phenomena-agreed-2026-10-18-spec).
- **The "vent" dev scenario** stands you 1.5 km across the rift from its live vent, facing it, a
  minute before a burst in clear daylight, with a charged board at your feet.
- **The dev overlay** names the nearest live vent drawn, how far and which way, and whether it's
  seeping or bursting (`weather/vent`), and a pocket blowing (`weather/pocket`); `goto live_vent`,
  `goto live_vent_2` and `goto flank_vent` stand you by them.

### What it costs

On the RTX 3070 at 1280 by 720, measured while Hunter's game held the GPU at 64 to 79% (look/plume:
the GPU's frame time with every plume drawn and without, the median of paired turns; and the drawing's
own GPU time from timestamps round its two passes): drawn at half size, walking into it adds 0.8 to
1.6 ms a frame and standing in it 1.0 to 1.4 ms, a burst at 1.5 km 0.7 to 1.3 ms, a seep at 1.5 km 0.6
to 1.0 ms, and from 7 to 25 km 0.3 to 1.4 ms; from inside a storm, which hides it before it's marched,
nothing measurable. Its own timestamps read 1.3 to 2.3 ms near, but they never fall below about 0.8
ms even with nothing of it in view, the game's work falling between them, so the frame difference is
the truer reading. Drawn at full size the same views took 3 to 3.7 ms. On the main thread a plume in
sight takes 0.088 ms a frame on a busy desktop with its share of handing the plumes to the drawing
(wind & storms probe 16, against its 0.25 ms bound), and all of them together 0.1 to 0.27 ms in the
look-test; the one frame after a jump in time or place works a whole line out at once.

### Probes

15. **The plume bends with the wind.** Beside the vent, what left it at each moment lies where the
    field's drift carried it since (within 3°); in a strong wind it stands lower 300 m downwind, under
    three quarters as high, and runs out half as far again; a storm between you and it hides it,
    clear air shows it, and from inside a storm even what towers 4 km up is lost; and with a storm by
    the vent and clear air nearer you, its foot is lost while what towers 4 km up over the storm's roof
    shows.
16. **The plume through a run.** With the clock stopped it holds still, and paused nothing moves; an
    origin shift leaves it where it was; walked 3.5 km off until its mouth's ground is forgotten it
    still shows, and back beside it rises from the same place; stood in its dust at the mouth the haze
    closes in round you (to 2.6 km at the probe's moment, in a breeze, against 9 km 800 m upwind); a storm over the vent hides it and it
    comes back after; what it shows is the vent's venting at that moment; and it costs the main thread
    under a quarter of a millisecond a frame.
17. **A burst is heard after it's seen** ([Radio, sound &
    atmosphere](radio-sound-and-atmosphere.md#distant-phenomena-agreed-2026-10-18-spec)).
18. **A plume from far now and then.** Sitting three hours where each origin starts on six worlds,
    looking every minute: 15 of 18 starts see a plume from 5 km or more (it must be three in four), a
    median 7% of the time (it must be 3%), most often a burst's column over the storms, which holds its
    height for a minute and a half.

Geology's own probes are the world system's (geology 1 and 2), and the kits' probes take the mouth
like any piece.

**To see them** (unseen, on a GPU): `look/plume/shoot.sh <dir>` finds moments in the run's own weather
(the calmest and the windiest clear ones, a burst well risen, a burst over a storm by the vent, dusk, a
front coming over the vent, night, a pocket blowing, the far side's flank vent), stands each shot so its
source lands where it's laid for the shots, shoots each far and mid (1.5 to 25 km, the far ones from the
crest nearest; the 25 km burst from whichever side of the vent sees its middle and top, on to the next
burst if storms hide it where it's drawn), walks into its dust in the calm (450 m) and stands in it (40
m), shoots from inside a storm, and the rift vent's mouth up close, times each, and builds
`~/Desktop/plume.png`.

### Its limits

- **One wind at every height.** The field has no wind shear and no inversion, so a plume bends in the
  same wind all the way up and can't punch through a lid or spread under one. Its stability is a day and
  a night value, not the air's own profile, and a burst's 10 km climbs through an atmosphere that doesn't
  thin with height.
- **Soft, not cauliflower.** Its billows are a wall's at its scale, but its dust is thinner than a
  wall's, so a burst reads as a soft sunlit mass with lumps on its face rather than hard turrets, most
  of all against the light. Its steps are staggered by a fixed pattern, a fine regular dither in its
  densest views.
- **The far storm veil is coarse.** Past the storm walls' reach the storms between are read at four
  ages along it, not pixel by pixel, and against the field's threshold, not the billowed faces.
- **Its mouth hands over.** Past the sheet's reach a vent's plume rises from where it would be laid from
  where you are; laid, from its mouth, which may have slid up to 24 m along the rift, so its root can step
  that far once, about 1.3 km off. The sheet's seams move a far plume a little as you walk (56 to 74 m at
  3.5 km, measured on a single jump; walking, in steps of a metre or so).
- **Three at once.** A fourth source in sight waits for one of the three to be further.
- **No hazard or reading.** The gas isn't felt or measured yet, and the ash fan doesn't grow with bursts.
- **The far plume is the weather's.** Storms cover most of the near side most of the time, so from where
  you are a plume shows only now and then (probe 18), and in a gale a seep lies low.

## Hooks from the sky (proposed, not settled)

*Proposal, session 4, part 2 ([lore session](../lore-session-2026-10-17-part-2.md)). Not settled
and not built; whether either goes in is an open question.* Tu hangs fixed in the near side's
sky ([the lore](../lore-research.md#tu-the-tidal-lock-and-the-water-agreed-session-4-part-2)),
and the session proposes two weather hooks from it:
- **An eclipse squall:** air rushing toward Tu's noon shadow.
- **A slow storm season:** when Zan swings closest and Tu looks visibly larger.

Readings, not in the session:
- Neither would be a new kind of weather. The squall would be a time-of-day term in `wind_at` on
  the near side, pointing at the shadow's centre at the noon eclipse, a clock the game already
  keeps ([the moon](../the-moon.md#day-length)). The season would be a slow swing in `storm_at`'s
  strength or coverage by orbital phase. Either stays deterministic and forecastable like the
  rest of the field, and designed, not simulated air (out of scope below).
- Both need what the game doesn't have yet. The squall needs a near side, and the game has only
  latitude. The season needs an orbital phase and a visible swing in Tu's size, against an orbit
  that is "rounding out," and Tu's size is itself under trial
  ([the body research](../body-research.md#tus-size-under-trial)).

## Skeleton version

- `wind_at` and `storm_at` from the run's seed. One slowly drifting prevailing wind,
  simple gusts, and a storm field carried by the wind with a sharp threshold.
- The wall: the look-test's billowed face, drawn from the field through the storm map.
- Inside a storm:
  - darkness, and fog closing in to the shield
  - wind force on the player and on loose objects
  - placeholder damage outside the shield
  - the far terrain rings switched off
- A debug readout of the wind, the local storm intensity, and the distance and time to
  the nearest front.
- The probes below, all passing.

## Full version

- The wall, built from what the look-test learns.
- The staged arrival: light, wind shift, ground dust, sound.
- Storms weaken toward the poles (decided). The field's coverage and intensity fall
  with latitude, so the poles are clear and calm, and their price is temperature (owned
  by Survival). Prevailing wind bands by latitude.
- Storm sizes, from dust haze to an ordinary storm to a great wall.
- Instruments and forecasts (the Console's set is proposed above).
- Feral plants as a free weather sign (proposed above; first in part 3's proposed order and
  deferred in part 4's, the newer: [skeleton plan](../skeleton-plan.md#the-newer-proposed-order-session-4-part-4)).
- Real dune shapes facing the prevailing wind (decided; see World & terrain).
- Wind particles and sound, with Sand Game's particles and recordings as the reference.
- **Storms wear dunes down** (Hunter, 2026-10-17, loose: "later on in the game, when we
  have better systems, this could even erode part of the dune and spawn loot"). A storm
  scouring a dune could cut into it and lay bare a find. *Partly built 2026-10-18: a storm
  moves the sand over a site, live, as a pure function of the field; the open dunes
  themselves still never change while loaded (World & terrain, rule 2).*

## Probes

All run without a window, with a fixed seed.

1. **Deterministic.** The same seed, place and time always give the same wind and storm.
2. **Storms ride the wind.** A front's measured motion matches the prevailing wind.
3. **Forecasts are honest.** Sampling the field ahead in time predicts when a front
   reaches a fixed point, within a tolerance.
4. **The wall is where the field says.** The storm map holds the field's own values, its
   fronts land on the field's in every direction (within a fifth of a map cell, before
   the billows), and the renderer finds the map through an origin shift.
5. **Inside means inside.** The storm state, harm and the far ring switch on exactly
   when the field at the player crosses the threshold. Fog and light switch exactly
   when the drawn face reaches your eyes. Both switch off when it passes.
6. **Wind pushes.** A loose box drifts downwind at the expected rate.
7. **Clear skies are earned.** Over a long simulated run, four reference travellers
   (sitting still, drifting with the wind, chasing gaps on foot, chasing gaps by sand
   yacht) each spend a share of time in the clear that lands inside their target band.
   The share has to rise with skill and speed. *(Waiting: the sand yacht is built as of
   2026-10-18, [Movement](movement.md#sailing-the-camp-hunter-2026-10-17), but no traveller
   sails it yet. At 3 to 4.5 m/s in a 10 m/s wind it runs well under a front's 6 to 14 m/s.)*
8. **Storms pass.** For a traveller sitting still, most storms pass within a full base
   shield's charge, and longer ones exist.
9. **The lee of a dune.** In a steady gale along the dunes' own heading, the wind at the
   foot of a tall slip face is cut by about the lee's full share, and up the same dune's
   windward slope and out on open sand it isn't cut at all. With the wind from the
   other side the same foot is exposed, and so is the foot of the windward slope. A box
   resting at the foot stays put where the same box on open sand slides off downwind.
10. **Tu stays put** ([the moon](../the-moon.md#day-length)). Through a day where a run
    begins, the Tu the sky draws strays no further than its daily nod while the sun goes
    round the sky. On the far side it never rises and casts no light.
11. **The eclipse.** At each size under trial the sun goes behind Tu once a day and
    totality lasts what Tu's width makes it. Solar's felt light is nothing through it, the
    sky draws the sun behind Tu, and the air is cooler for it and over it half a day on. Tu
    is dark then and full half a day later. At the Rim the eclipse takes next to nothing.
12. **Local time follows longitude.** A quarter of the way round to the east it's six hours
    later, and the drawn sun, the light, the warmth and a radio's day music follow; to the
    west it's six hours earlier.
13. **The eye** ([art direction](../art-direction.md#eye-adaptation)). Handed readings as
    its meter would give them, it's as before in daylight. On a frame as black as a night
    with no Tu it opens over time, never at once: about a doubling in the first few
    seconds, then on to its floor within half a minute, never past it. Back in daylight
    it closes within two seconds, never past where it began. With Tu's disc in view it
    opens only so far as keeps it short of white. The camera takes its exposure, and the
    fixed one with the eye off.
14. **The radar reads the field** (2026-10-17). A Console with a radar stands in the clear,
    the clock stopped, a front a few kilometres off. Swept round once, its front is as near
    as the field's nearest stormy ground in any direction, to within 1% and 5 m, and that way,
    to within its 10° between bearings. Inside a storm it says so.
19. **The anomaly hides** (2026-10-18). Through its storm, from the clear to its heart, the field,
    its wind and the radio's forecast are what a run with no anomalies reads, and so are the
    Console's wind and sand at the heart; outside the bubble there, harm and a crop's dust read the
    particles five times over and the wind's harm one and a half, wear reads the same, and the
    shield holds back five full storms' sand.
20. **The anomaly's tells** (2026-10-18). Well ahead of its wall there's none; where its hidden term
    is a half and at its heart, the compass leans further toward the heart and the radio crackles
    louder; at the heart the shield's load on the Console's stats is past three full storms' while
    its wind and sand read an ordinary storm.
21. **No anomaly in a run's first days** (2026-10-18). A fresh run begins where and when a new one
    would, days into the weather's clock; through its first five days no heart comes within 60 km of
    where it began, where with them lifted, as for a dev run that asks for one, some would.
22. **A wall shelters what's behind it** (2026-10-19). A camp's wall broadside to a steady wind in a
    storm, on open sand: just behind it the wind is cut by about a full lee's share and the storm's
    wear and harm by theirs; beside it, upwind of it and seven heights behind it, nothing is; edge-on
    it shelters nothing. A light box resting behind it stays put where one in the open slides.

## Out of scope

- Rain, lightning and other weather.
- Simulating real air physics. The field is designed, not simulated.
- Saving weather.

## Tu and the storms

([The Tu spec](../tu-and-day-2026-10-17.md), 2026-10-17.) On the near side Tu is the
landmark, and storms blot it out, so you lose it exactly when it matters. The walls are drawn
over the sky, so a wall between you and Tu hides it, and inside a storm's dust it's gone. At
night a wall is lit by Tu's light as the open ground is, and during the eclipse it goes dark
with everything else.

## Open questions

- **Does the eclipse kick the weather?** The spec leaves open "whether the eclipse also
  affects the weather model, such as a pressure or wind kick," and the eclipse squall below
  is the session's proposal for it. Nothing is built: the field doesn't know about the
  eclipse, and the eclipse only darkens the light and dips the temperature.
- **What target bands for clear skies** should each reference traveller get? Set them
  once the skeleton can measure them. The skeleton starts here: someone sitting still
  is in a storm 70% of the time, the median storm lasts 17 minutes, 71% pass within a
  base shield's 30, and the longest run past 3 hours. Storms ride a prevailing wind of
  10 m/s that swings by up to 6 either way, so a wall first seen 3.5 km out arrives in
  4 to 16 minutes.
- **Do the eclipse squall and the storm season go in?** Proposed, not settled (above). If they
  do, the squall is a near-side term in the wind and the season a slow swing in the storm
  field. The sky now gives both what they'd read: the near and far side by Tu's height, and the
  orbital phase (`DayCycle`, [the moon](../the-moon.md#day-length)). Tu's shadow is far wider
  than Zan, so the whole near side is in it at once; its "centre" is the point under Tu, where
  the sun stood highest and the eclipse's chill is deepest, so a squall would point there.

Session 4, part 3 (2026-10-17) adds two. Each is quoted on both sides and left standing.

- **How far ahead a plant reads.** The session: the pose is driven by the intensity curve "with
  some lead time." Not said how much, against the barometer's "rough warning" and the radio's 20
  minutes (the open question below about "hours ahead").
- **A free sign against the instruments.** Here: "Instruments are finds and upgrades," and
  "Better instruments see further into the field." The session: scrub is "a free, slotless,
  low-tech barometer." Not said whether it sees as far as a found barometer or only the near
  front, or whether a player with the instruments still has a reason to watch the plants.

The Console session (2026-10-17) answers one of its own questions and adds the rest. Each is
quoted on both sides and left standing.

- **Answered: can a storm's intensity be queried ahead of time?** Yes, already, as above. What
  stays open is how far ahead an instrument reads and how finely.
- **What the tiers are.** The session: "Resolution scales with data," with "roughly two linked
  Consoles" for a mini-map. Not said: which instrument adds what resolution, how far the
  mini-map reaches, or what "all the gear" is.
- **"Hours ahead" against a storm minutes away.** Here: "A barometer shows a storm coming hours
  ahead" (the draft of 2026-10-13). The session: the barometer is a "rough warning of an incoming
  storm." A wall is about 5 minutes from first sight to impact, up to 20, a day is 20 minutes so
  a game hour is about 50 seconds, and the radio already looks 20 minutes ahead. Not said whether
  the hours are game hours, or whether the barometer is meant to beat the radio.
- **Instruments inside the bubble.** Here: every system reads the felt weather, which is still
  inside a shield. The session puts the instruments on a camp's Console. Not said whether they
  read the field through the bubble, as the radio's forecast does, or sit outside it (an
  antenna on a mast, a radar on a top mod).
- **Pressure, humidity and sand density.** Here: "Nothing computes storminess any other way."
  The session adds three readings the field has no number for. Not said whether they are derived
  from the storm and its outflow, or whether the field gains terms.
- **The radio "beyond the horizon."** Here: the built forecast is the field "where the radio
  stands," 20 minutes ahead, and new channels are finds. The session: "old weather-station
  broadcasts: forecast beyond the horizon." Not said whether that is further in distance (a
  forecast for another place), further in time, or a found channel (the lore hook above: "a
  colonial weather station still broadcasting").

Session 4, part 4 (2026-10-17) adds the following. Each is quoted old and new. The newest session wins
in the living docs, so this PRD follows it as direction and says so on each line.

- **The weather sign: first, or deferred.** Session 4, part 3's first step is the sign, and part 4
  defers it "needs the queryable storm curve from the sleep work." *Follows part 4.* The curve is
  queryable already (above), so the stated reason no longer holds and the order is the only open part.
- **Saltbush against "feral scrub."** Part 3: "Feral scrub closes up or turns its leaves before a
  storm." Part 4: saltbush is the weather-sign plant. *Follows part 4;* the scrub is saltbush. Not
  said whether other feral plants (dewleaf, stormcup) also show the weather.
- **A planning session against the sleep proposal.** Here ([Survival](survival.md#sleep-proposed)):
  "waiting one out early game is boring," and sleep is "the preferred fix." The session: a storm is
  "the reflective half of the loop." Both can hold if planning is for the 20-40 minute storm and
  sleep for the multi-day ones; the session does not say.
- **Storms of 20-40 minutes against the field.** Here: the median storm is 17 minutes, 71% pass within
  30, and some run past three hours. Not said whether the field is to be retuned toward the
  session's length; "how long storms last is a tuning target."
  *Measured 2026-10-18* over the starts of twelve worlds, 200 days each (2,916 storms): median 17.7
  minutes; 45% run past a day (20 minutes), 18% past two, 6% past three; the longest 8.4 days (2.8
  hours), and 79% of all storm time is in storms past a day. The tail keeps its shape whatever the
  scale: the longest is near ten times the median in every tuning tried. Faster evolving (3 or 6
  times) or a slow lull carved through the field barely moves it. Raising the threshold to -0.05 makes
  the moon stormy 56% of the time, not 70, and storms past three days 2%, the median 13 minutes;
  halving the wavelength to 8 km halves every storm (median 8 minutes, the longest 71, past three
  days 0.3%) with walls twice as often. *Proposed, not built:* leave the field, since a sleep covers
  four days and the kit's shield lasts about that long, or raise the threshold a little (-0.10: 63%
  stormy, 4% past three days). Only the run's first storm is held to an ordinary length
  ([Survival](survival.md#skeleton-version)).
- **Fixing storm damage against wear that nothing mends.** Here (Power): the turbine's storm wear
  "nothing mends," and parts are "found, never crafted." The session: "craft and repair: fix storm
  damage, rearrange mods." *Follows the session as an activity;* no repair exists and none is
  designed.
- **Radio that carries better, against a radio that crackles.** Here (Radio, sound & atmosphere):
  "Reception crackles and distorts as storms build," and static is "full inside" a storm. The session
  lists "the radio carries better in some storms" among the Agreed uses, and its back burner has "radio
  windows." Read as the activity agreed and the mechanic that makes some storms carry better on the
  back burner.
- **Lightning against "out of scope."** Here (Out of scope): "Rain, lightning and other weather." The
  back burner's static harvest ("lightning rod") and glass forming ("lightning in heat storms") need
  it. Back burner, so nothing now.
- **"Storm blooms" against bursts.** The session's Agreed growth stage is that storm crops "fruit in
  bursts during storms, not on a timer," and the back burner is "storm blooms: storm crops fruit only
  now." Read as bursts agreed and the "only" held back ([Farming](farming.md#open-questions)).
- **Storm-driven dune movement.** The session's own open question: how much the terrain can support.
  Here, loaded ground never changes (World & terrain, rule 2), and "Storms wear dunes down" is
  already a loose full-version line. *Since 2026-10-18 a site's ground follows a storm's work live,
  pressed afresh in fine steps; whether the open dunes may follow the same way is still open.*
