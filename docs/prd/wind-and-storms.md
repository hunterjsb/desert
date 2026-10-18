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
leaves a crate be and a storm slides it. Floating, nothing holds it, so it drifts off
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
- **Anemometer:** the wind now, gusts and all, as its speed and the point it comes from. "WIND
  12.4 m/s from WNW".
- **Barometer:** pressure from the field. It's 310 hPa, the moon's thin air ([the
  moon](../the-moon.md)), where the field sits at its threshold, and it falls 8 hPa for each unit
  the field rises, so it falls as a storm comes. It shows the pressure and its trend per minute
  over the last two minutes. While the field here is rising toward its threshold, that trend
  carried on gives a rough time until the storm, and under 15 minutes it warns: "STORM LIKELY ~5
  min". It's rough on purpose, a curve carried on as a straight line.
- **Hygrometer:** humidity from the cold and the storm, tied to the condenser by sharing its
  function (`Condenser.yield_lph`). It reads 60% in air as cold as a condenser makes its most in,
  less as the air warms, as the condenser's yield falls, and up to 25% more in a full storm. It
  shows what a condenser would make there too: "HUMID 37% · condenser 6.2 L/h". The condenser
  doesn't make more in a storm yet; that half of the tie is still proposed.
- **Particle sensor:** sand in the air, from the storm's intensity. A storm is at full intensity
  within about 100 m of its front, so the sensor also reads how deep into the field it is, as
  salvage counts a storm's heart (the field 0.4 past its threshold): from 0.9 g/m³ at a wall to
  3 g/m³ at the heart, and a little ahead of the wall from the front's outflow. It shows its trend
  over 30 s. With a radar it also says how hard the coming storm hits: the most sand in its
  first kilometre ("hits 1.8 g/m³").
- **Radar,** on the computer-mod top: it sweeps 36 bearings, one a tick, stepping 100 m out to
  its reach, 6 km (a stat of the part), until the storm state changes, then closes in on the edge
  to 2 m. It reports the nearest edge, its distance and its point. Its heading is the way storms
  ride the wind. Its ETA is the storm upwind reached at that speed: the nearest wall is often
  sliding past to one side, and the upwind one agrees with the forecast. Inside a storm it gives
  the nearest clear air and when the storm clears, or that it runs on upwind past its reach. "FRONT 1.2 km N · ETA 5 min", then "heading ESE 8 m/s ·
  hits 1.8 g/m³". It samples the field round the Console itself rather than reading the wall's
  map, which is centred on you, not on your camp.
- **A radio on the Console's top mount** adds the forecast it already makes (`Radio.forecast`, 20
  minutes ahead, read again every 5 s, where the radio is): "FCST storm in 5 min from WNW", then
  "winds to 27 m/s · lasts 9 min". It feeds the Console while it's powered and whole, whatever its
  dial plays aloud.
- **Resolution scales with data, as far as a first step:** any set shows numbers. The full set, all
  five computer mods and a radio, on one Console or across a linked deck, adds a storm map to the
  weather page: 18 cells across the radar's 12 km, the moon's north up, a row sampled a tick, with
  you at its middle, the nearest edge drawn in amber, and the way storms ride. A finer map from more
  gear is still proposed.
- **Cost:** a radar's sweep is a bearing a tick, about 60 samples; the map a row a tick, 18 more.
  At a fast clock both go faster, to keep up.

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
- **Deep exposure:** mid-storm sand movement briefly opens the deepest ruin layers.
- **Storm blooms:** storm crops fruit only now.
- **Radio windows:** some conditions carry distant transmissions.
- **Glass forming:** lightning in heat storms fuses sand into glass, a crafting material collected in
  the wake.

Deferred in the same list: feral plants as a weather sign, landmark interiors and heat shields.

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
  keeps from you.
- **The lee scenario** stands you at the foot of a tall slip face, its crest at least
  15 m above you and a lee at least nine-tenths full, facing up it into the wind coming
  over the crest, in the clear with a storm due in two to six minutes.

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
  scouring a dune could cut into it and lay bare a find. Loaded ground never changes
  (World & terrain), so this would happen where you aren't, or be staged, and it ties in
  with storms uncovering finds (Salvage & ruins).

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
   The share has to rise with skill and speed.
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
  already a loose full-version line.
