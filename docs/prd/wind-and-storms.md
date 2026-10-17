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
- Instruments and forecasts.
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

## Out of scope

- Rain, lightning and other weather.
- Simulating real air physics. The field is designed, not simulated.
- Saving weather.

## Open questions

- **What target bands for clear skies** should each reference traveller get? Set them
  once the skeleton can measure them. The skeleton starts here: someone sitting still
  is in a storm 70% of the time, the median storm lasts 17 minutes, 71% pass within a
  base shield's 30, and the longest run past 3 hours. Storms ride a prevailing wind of
  10 m/s that swings by up to 6 either way, so a wall first seen 3.5 km out arrives in
  4 to 16 minutes.
- **Do the eclipse squall and the storm season go in?** Proposed, not settled (above). If they
  do, the squall is a near-side term in the wind and the season a slow swing in the storm
  field, and both wait for a near and far side and an orbital phase to read.
