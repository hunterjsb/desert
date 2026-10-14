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

**Approach.**
- **From a distance:** a giant curtain built along the front, wherever the field crosses
  the threshold. It's found by sampling outward from the player in every direction, so
  it follows the storm's true shape. A shader gives the face its billowing, layered
  for depth.
- **As the face arrives:** Godot's volumetric fog (which only works close to the camera)
  takes over, along with particles and the darkening.
- **The hand-off between the two** is the moment the wall reaches you. That's where the
  enclosure lives, and it's the riskiest visual in the game.

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

## Skeleton version

- `wind_at` and `storm_at` from the run's seed. One slowly drifting prevailing wind,
  simple gusts, and a storm field carried by the wind with a sharp threshold.
- A crude wall: a big dark curtain along the front, visible from far away.
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

## Probes

All run without a window, with a fixed seed.

1. **Deterministic.** The same seed, place and time always give the same wind and storm.
2. **Storms ride the wind.** A front's measured motion matches the prevailing wind.
3. **Forecasts are honest.** Sampling the field ahead in time predicts when a front
   reaches a fixed point, within a tolerance.
4. **The wall is where the field says.** The curtain's distance in each direction
   matches the threshold crossing.
5. **Inside means inside.** Darkness, visibility and damage switch on exactly when the
   field at the player crosses the threshold, and switch off when it drops back.
6. **Wind pushes.** A loose box drifts downwind at the expected rate.
7. **Clear skies are earned.** Over a long simulated run, four reference travellers
   (sitting still, drifting with the wind, chasing gaps on foot, chasing gaps by sand
   yacht) each spend a share of time in the clear that lands inside their target band.
   The share has to rise with skill and speed.
8. **Storms pass.** For a traveller sitting still, most storms pass within a full base
   shield's charge, and longer ones exist.

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
