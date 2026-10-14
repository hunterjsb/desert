# Skeleton plan

*Draft, 2026-10-13. How we build the skeleton described in [the vision](vision.md): every
system in rough form, wired into one complete loop, before anything gets polished.*

**Where we are:** Stages 0 and 1 passed the gate on 2026-10-14, and Stage 2 passed later
the same day, with the look-test's wall in the game. Stage 3 is built and waiting at the
gate (F2, K drops the test kit). The rope look-test is done and waiting for Stage 5.

## The loop we're building toward

Walk out with the camp in tow. A storm wall appears, so you batten down: stake the
planters, shield up. Sit it out or walk through it. Find salvage half-buried in the
dunes, strip it, and fit the parts. Charge batteries in the sun, water and grow the
crops, eat and drink. Keep going, or settle in and let the camp run itself.

The skeleton is done when that loop plays end to end, and every skeleton probe in every
PRD passes.

## How we work

- **One stage at a time.** Each stage ends with something you can play.
- **The gate:** a stage is done when its probes pass in CI *and* you've played it and
  said go. Nothing starts until the stage before it has passed the gate.
- **Probes first.** Each stage's probes are written from its PRD before the feature
  they test, and each one is checked against a deliberately broken build to prove it
  can fail.
- **Nothing gets polished.** Grey boxes, placeholder materials, Sand Game's sounds.
  Looks come after the loop works.
- **Tuning lives in one file.** Chunk size, storm speed, shield life and every other
  number sits in one tuning file, so tuning never means editing code.
- **Scenarios for every playtest.** F2 drops you into a starting condition, like a storm
  100 m away and coming at you, found in the run's own weather rather than faked. Each
  stage adds the scenarios its playtest needs, and a probe checks that each one
  delivers what it says.

## Stage 0: Foundation

- A fresh Godot 4.7 project on `master`, beside `docs/`: Jolt physics, Forward+,
  GDScript.
- Layout:
  - `game/<system>/` for the systems
  - `probes/` with one folder per PRD
  - `look/` for look-tests
  - `assets/` holding only what's used, copied from the `archive` branch
- **The probe runner:** one script runs a single probe or all of them, without a window.
  It uses a hard timeout and captures all output. A probe that never finishes counts as
  failed, because a script error hangs instead of crashing. Seeds are fixed, and nothing
  is ever counted by node name.
- **CI** runs every probe on every push.
- **A dev overlay** (F3, as in Sand Game) shows every number. Probes read the same
  values.

**You play:** nothing yet. You check the layout and the runner.

## Stage 1: The ground

**Builds:**
- World & terrain, all of its skeleton: `height_at`, streaming chunks, collision, the
  crude far ring, haze, the origin shift, latitude and longitude, distance from spawn.
- Walking on it (Movement): walk, sprint, stamina, slip faces costing more.

**You play:** walk the dunes. Do they feel solid? Check the far view and the debug
readout.

**Probes:** World & terrain 1–8.

## Stage 2: The weather and the day

**Builds:**
- Wind & storms skeleton: `wind_at`, `storm_at`, the crude wall, darkness and fog
  inside, wind pushing you and loose boxes, the far rings switched off in storms, and
  the weather readout.
- A felt-weather wrapper, with no shelter yet, so everything built from here reads
  weather the right way from day one.
- The 20-minute day and night, which solar will need.
- A mode readout (walking, sprinting, flying) on the F3 overlay. The Stage 1 playtest
  found it hard to tell which one you're in, and the Stage 2 playtest wanted it off the
  screen.
- Enough storm to know you're in one: dust streaming on the wind, a brown glow, and Sand
  Game's storm roar and desert wind. The Stage 2 playtest found darkness alone read as
  night.
- Scenarios: a clear day, a wall on the horizon, storms 500, 100 and 20 m away, deep in a
  storm, a storm about to clear, dusk and night.

**The wall look-test starts here** and runs alongside every stage that follows. It's a
separate scene with one job: making the wall feel right. It has no probes. You judge it
by eye, and what it learns feeds the full version of the wall.

**Pulled forward** (decided 2026-10-14). The look-test's first version was the feeling
right away, so its wall replaces the crude curtain inside Stage 2, drawn from the game's
own storm field so the wall and the probes agree.

**You play:** watch storms roll in and over you. Read the wind. Get pushed around.

**Probes:** Wind & storms 1–6 and 8, and the scenarios probe. Probe 7 waits for the full
version, because its fourth traveller needs the sand yacht.

## Stage 3: Devices & mods

**Builds:** device frames with the five socket types, typed parts, magnetic snapping and
removal, fitted parts merging into the device's shape and weight, stats computed from
parts, the look-at readout, and loose stacking under plain physics.

**You play:** fit and remove parts on test devices. Does the snap feel good? Does
removal make sense?

**Probes:** Devices & mods 1–7.

## Stage 4: Power

**Builds:** batteries in battery slots, the light solar panel, a crude turbine, direct
wiring, a charger, swapping by hand, charge lights and the fixed power tick.

**You play:** charge a battery in the sun, swap it into a device, and watch it drain.

**Probes:** Power 1–3 and 5. Probes 4 and 6 come later, at stages 6 and 12.

## Stage 5: Rope & tethering

This is the riskiest system after the wall, so it comes early. **A rope look-test runs
ahead of it** (decided 2026-10-14), alongside Stage 2. It's a separate scene with
stand-ins to tether: the test floater, a crate, stakes and you. It answers whether rope
can feel right, and probes 1, 2, 3 and 5 answer whether it's reliable. Built
2026-10-14 (`look/rope`): all four probes pass, each proven against a broken rope; it
reads as rope except that light lines look as straight as loaded ones (see the PRD's
open questions). Hunter's verdict: "SO GOOD", no bugs found. His one change: stakes
are their own item, and rope ends snap on and off with the devices' snap system, so
any loose end can be picked up. That makes Stage 5 lean on Stage 3's snapping.

**Builds:**
- The rope constraint and the drawn rope, fixed attachment points (hooks), breaking
  and holding strengths, wind catch, and the tension creak.
- The test floater: a hovering box with a hover tray and a battery.
- You on the end of a line (held or waist-tied, dragged by gusts), stakes, and camped
  versus travelling, including towing on foot.

**You play:** tie the floater down in a storm, tow it across the dunes, and get dragged.

**Probes:** Rope & tethering 1–11.

## Stage 6: The bubble shield

**Builds:**
- The shield device: carried, placed, toggled, the 0.6 s bloom.
- Shelter, plugged into the felt-weather wrapper, so everything built so far feels it:
  rope loads, the fog, sound.
- Wind and storm harm with durability, and the 30-minute battery with its collapse.

**You play:** batten down for a storm, and walk through one inside the bubble with the
floater in tow.

**Probes:**
- Bubble shield 1–8. Probe 8 uses a test-only second shield setup.
- Power 6 (thirty minutes).
- Movement 4 (the camp follows on foot).

## Stage 7: Survival

**Builds:** health, hunger, thirst and stamina bars, the suit (with free air and
radiation protection), the three harms on you, auto-eating and drinking from your
inventory, sealed water, a crude condenser, and death starting a new run.

**You play:** survive a few days from a sealed-water start.

**Probes:** Survival 2–4. Probe 1 comes at stage 12, and probe 5 waits for the full
version's water rhythm.

## Stage 8: Salvage & ruins

**Builds:** finds placed as chunks load (parts and whole devices, partly buried), two
layers exposed by the storm field, one walk-in ruin built into `height_at`, and
stripping found devices for parts.

**You play:** go looking. Strip a find, fit its parts, and walk every room of a ruin.

**Probes:** Salvage & ruins 1–7.

## Stage 9: Farming

**Builds:** the hover planter (slots and a water tank), one crop and fungus, growth from
felt light and temperature, harvesting by hand, the harvester mod with the replant
split, and food dropped onto you.

**You play:** grow food in the clear and fungus in a storm.

**Probes:** Farming 1–2, 4–5 and 7. Probe 3 uses a test-only thermal shield, and probe 6
comes at stage 12.

## Stage 10: The hoverboard and camp range

**Builds:** the hoverboard (a find: fast, floaty, carving, its own battery, tows nothing)
and the camp-range warnings.

**You play:** ride. Is it fun? Then ride away from camp and heed the warnings.

**Probes:** Movement 1–3 and 5–7.

## Stage 11: Radio and sound

**Builds:** the radio with music, weather and a loot beacon, static that follows the
storm, and a sound pass over everything built so far, using Sand Game's recordings.

**You play:** sit out a storm with the radio on. Follow a beacon.

**Probes:** Radio, sound & atmosphere 1–5.

## Stage 12: The loop

**Builds:** nothing new. This stage wires up the reference camp (shield, floater,
planters, panels, turbine and batteries) and plays the whole loop.

**You play:** a full run, start to death or to AFK.

**Probes:**
- The AFK promise, three ways: Power 4, Survival 1 and Farming 6.
- Every probe from every earlier stage, passing together.

**When this passes the gate, the skeleton is done** and muscle can start.

## Waiting for the full version

These probes need content the skeleton doesn't have:
- Wind & storms 7 (the sand yacht).
- Survival 5 (the water rhythm).
