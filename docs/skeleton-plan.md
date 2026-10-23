# Skeleton plan

*Draft, 2026-10-13. How we build the skeleton described in [the vision](vision.md): every
system in rough form, wired into one complete loop, before anything gets polished.*

**Where we are:** Stages 0 and 1 passed the gate on 2026-10-14, and Stage 2 passed later
the same day, with the look-test's wall in the game. Stage 3 passed that evening ("works.
nice."). Stage 4 passed on 2026-10-15 ("feeling great!"), with a strong cable that's
also a rope. Stages 5 to 7 passed the same day: the rope ("feels good"), the shield
generator ("the shield feels good too") and survival, with the inventory as five slots
on the suit (hunger, thirst, the condenser and death into a new run all worked when
Hunter played it). Movement on foot (slide, jump, crouch, digging in) was built
alongside them. Shield probe 4, which carries the shield 2 km through a storm with a
crate on a waist line, stands in for Movement 4 until the full camp exists. The real
dune shapes were pulled forward the same day: a look-test put candidate dunes in the
real world, Hunter picked Ridges, and they're the game's ground now, with the sand
shader he chose to keep. Stage 8, salvage and ruins, was built the same day and passed
on 2026-10-16 (strip and fit, the ruin's walk-through and finds outside all "works"): finds half-buried in the dunes from the seed and how hard the
weather has been, a deep layer harder weather uncovers more often, one walk-in ruin
pressed into the ground's one function, and "go looking" among the dev scenarios. Stage 9,
farming, was built on 2026-10-16 and is waiting at the gate: the hover planter
with its water tank, carrots that want the clear day and fungus that wants the
storm's dark, growing by felt light and temperature and wilting past their limits,
picking by hand, the harvester mod with its replant split, food dropped onto you, and
"farm" among the dev scenarios. Probe 3 was cheap with a test-only thermal shield, so it's
built too. On 2026-10-16 a normal run became playable end to end: rope, cables, seeds,
survival kits and the harvester are found, every run starts with its kit (data: water, a
ration, a light shield, a light solar panel and a short coil), and a shield seats on a
crate, which has more sockets. The same day the run save and the profile were built
(Profile & saves): Save & quit and Resume, a minute after resuming matching one never
saved, and discoveries recorded across runs. So were the menus, ahead of Stage 12: the
main menu over a live desert, the system menu, options and one theme in Geist (Menus &
UI 1–5). Stage 10, the hoverboard and camp range, was built the same day too and waits
at the gate behind Stage 9: a board found in the deep layer, buried nose down, that
skims the dunes at 72 km/h on its own battery, carves and drifts, floats off crests and
tows nothing, and the camp-range warnings, a chime and a line of text timed by your
speed, 20 s and then 8 s before you'd lose the camp. The "ride" scenario lays a
charged board at your feet by a small camp. The Movement PRD's probes keep their
numbers, 1 to 7; the on-foot probes built with Stage 5 are 8 to 14. Stage 11's sound
pass was pulled forward the same day: softer fitting and a softer suit, new sounds for
most actions, World and UI buses, and the whole mix levelled (Radio, sound &
atmosphere, "As built"). The radio finished Stage 11 on 2026-10-17 and waits at the
gate. It's a device you carry or seat on a top mount, and use turns its dial through Sand
Game's music by day and by night, a weather station reading the storm field ahead, and a
beacon pointing at the find in a ruin's hall. Its static comes in ahead of a storm and
stays in the bubble. It's a find, and the "radio" scenario sets one in front of you
with a shield and a storm 300 m off. Radio probe 3 is Bubble shield probe 1, so it isn't
written twice. Stage 12's reference camp was built on
2026-10-17: the "afk" dev scenario parks it round you, running. The same day it moved onto
a floating deck two pieces by two, a tray under every piece: the base shield, a condenser
and two crates of batteries and panels stand on it as one pool, it's moored to a stake, two
harvester planters float beside it on hoses from the condenser, each moored to its own
stake, and a turbine is held out in the wind on a strong cable from a crate. The AFK promise is proved three ways (Power 4, Survival 1 and Farming 6):
its power holds through two days and nights at 45° north, and it keeps you alive and
fed through three days at the equator, mostly storm. What ends it is water, which
nothing brings you yet, and the turbine, which the storm wears out on the third day
(Power, Survival and Farming, "As built"). Stage 12 waits at the gate for a full run
from the main menu.

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
  Looks come after the loop works. The art direction is settled alongside the build
  (Hunter's call, 2026-10-16): a look-test of candidate styles, so real assets start
  from decisions already made, while everything in the game stays grey. He picked B,
  chunky worn industrial, for now ([art direction](art-direction.md)). One step further,
  left to Claude by Hunter the same day: a paint pass puts B's palette and its UV-less wear
  shader on today's shapes, so playtests look like the game. It makes no models, so
  nothing is lost when shapes change.
- **Tuning lives in one file.** Chunk size, storm speed, shield life and every other
  number sits in one tuning file, so tuning never means editing code.
- **Scenarios for every playtest.** The dev console's scenario command drops you into a
  starting condition, like a storm 100 m away and coming at you, found in the run's own
  weather rather than faked. Each stage adds the scenarios its playtest needs, and a
  probe checks that each one delivers what it says.

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
- **A dev overlay** (as in Sand Game) shows every number. Probes read the same
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
- A mode readout (walking, sprinting, flying) on the dev overlay. The Stage 1 playtest
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
version, because its fourth traveller needs the sand yacht. (The yacht exists since
2026-10-18; its traveller doesn't yet.)

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
**The rope core is in the game** (2026-10-14, pulled in for Stage 4's strong cable).
The world owns the ropes and the look-test uses them; Stage 5 builds the rest on top.

**Builds:**
- The rope constraint and the drawn rope, fixed attachment points (hooks), breaking
  and holding strengths, wind catch, and the tension creak.
- The test floater: a hovering box with a hover tray and a battery.
- You on the end of a line (held or waist-tied, dragged by gusts), stakes, and camped
  versus travelling, including towing on foot.

**You play:** tie the floater down in a storm, tow it across the dunes, and get dragged.

**Probes:** Rope & tethering 1–11.

## Stage 6: The bubble shield

**A shield look-test ran ahead of it** (2026-10-15, `look/shield`): sitting inside a bubble
while the storm wall engulfs it reads right. Shelters are spheres Weather reads by
distance and the storm shaders carve (up to 8, so bubbles nest); inside, the felt storm
and wind are zero, the senses read clear and the light still follows the open storm.
Stage 6 builds the shield device on that. The look-test's shield is a fixed prop with a
key, only for judging the look; the real one is an object, a generator you carry, set
down and switch on, with the bubble following it (Hunter, 2026-10-15).

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

**Probes:** Radio, sound & atmosphere 1, 2, 4 and 5. Probe 3 is Bubble shield 1, passing
since Stage 6.

## Stage 12: The loop

**Builds:** the menus, the run save and the profile ([Menus & UI](prd/menus-and-ui.md),
[Profile & saves](prd/profile-and-saves.md); pulled forward 2026-10-16 and built alongside
stages 10 and 11), then nothing new: this stage wires up the reference camp (shield,
floater, planters, panels, turbine and batteries) and plays the whole loop.

**You play:** a full run from the main menu, start to death or to AFK, with a save &
quit and a resume along the way.

**Probes:**
- Menus & UI 1–5 and Profile & saves 1–5.
- The AFK promise, three ways: Power 4, Survival 1 and Farming 6.
- Every probe from every earlier stage, passing together.

**When this passes the gate, the skeleton is done** and muscle can start.

**How players will really camp** (Hunter, 2026-10-17: "the afk setup is ok but its not
realistic"). Likely one crate carrying the shield, the board, batteries and one panel,
its hooks maxed, each towing something: a condenser, a farm, another crate. The chassis
should replace that train of towed things with one deck, and with it most of the physics
risk and clunkiness of many bodies on many lines. The reference camp is now rebuilt on a
deck: "add a 2x2 pimped out chassis to afk scenario" (Hunter, 2026-10-17). It's built (the
numbers are in Power, Survival and Farming, "As built"), with spare stakes, a coil and a hose
in your pack for moving the planters about.

## Waiting for the full version

These probes need content the skeleton doesn't have:
- Wind & storms 7 (the sand yacht). The yacht is built now, as your own camp under sail
  ([Movement](prd/movement.md#sailing-the-camp-hunter-2026-10-17)), but the probe still
  waits: it needs a reference traveller that sails it, chasing gaps, over a long run.
- Survival 5 (the water rhythm).

**A proposed build order for the lore and kits pieces (part 3's, kept for reference).** Session 4,
part 3 (2026-10-17, the lore session) lists seven buildable
pieces, roughly in order of how soon they could land. The same day's part 4 lists ten of its own,
which is the newer proposed order ([below](#the-newer-proposed-order-session-4-part-4)); where the two
overlap part 4's wins. This is a historical proposed order, not a schedule. The weather-sign plant
was built with the feral layer on 2026-10-18; the remaining pieces have no stage or date and wait
for the skeleton's gate as the full version does. They follow the
existing conventions, with no one-off exceptions in core systems.
1. **Feral plants as a weather sign (built 2026-10-18).** Wild saltbush folds before storms, driven
   by the storm curve at its location. The wider feral trail and history ideas remain open. The curve can be queried
   ahead ([Wind & storms](prd/wind-and-storms.md#feral-plants-the-free-barometer-agreed-session-4-part-3-not-built)).
2. **Feral plant lines.** Scatter feral scrub along procedural old-road lines that trend toward
   Cistern shrines or water. Visual only at first, with no gameplay beyond the weather pose
   ([Farming](prd/farming.md#feral-plants-and-a-crops-history-agreed-session-4-part-3-not-built)).
3. **The hoverboard as a superchassis.** The patrol board needs mount points for a shield,
   battery, radio, condenser, bedroll and tow, as a chassis rather than special-cased slots, with
   a narrow shield that stays on while riding. This also generalises the existing board
   ([Movement](prd/movement.md#the-patrol-board-a-superchassis-agreed-session-4-part-3-not-built),
   [Devices & mods](prd/devices-and-mods.md#the-patrol-board-as-a-superchassis-proposed-not-built)).
4. **The dune sailboat.** A wind-driven slow hauler that reads the wind vector already in the
   world, with tow capacity well above the board
   ([Movement](prd/movement.md#the-dune-sailboat-agreed-session-4-part-3-not-built)).
5. **Kit unlocks.** Add the two kits to the local profile: the Varran settler unlocks on building
   and using a sailboat, the Daventry patrol board on building a patrol board. The Daventry
   unlock is still open ([Profile & saves](prd/profile-and-saves.md#kits-are-data)).
6. **Sister and Mother Cistern.** A fixed-coordinate prefab landmark: a half-buried temple, a
   dormant terminal and a basin that refills slowly. Restoring and linking can wait for the
   endings work ([Salvage & ruins](prd/salvage-and-ruins.md#landmarks), [World &
   terrain](prd/world-and-terrain.md#landmarks)).
7. **Ending flags.** Track the Daventry axis as a running loudness value from dead-lane
   transmissions and launches, and the Cistern axis as dormant, restored or linked. Don't build
   epilogues yet ([Profile & saves](prd/profile-and-saves.md#ending-flags-proposed)).

No Varran, Daventry or war content goes into normal play beyond radio noise
([Radio, sound & atmosphere](prd/radio-sound-and-atmosphere.md#offstage-states-on-the-air-agreed-session-4-part-3-not-built)).
The seed vaults and the second-age broadcasts are proposed too, but the session's list doesn't
include them, so they are not in this order.

### The world system, built whole (Hunter, 2026-10-17)

"Flesh out the ruin gen... so we can stop just having totally random loot just all over the
desert. actually lets go for the whole system, who am i kidding? half assing is what killed
last sand game. a giant isnt built of small human skeletons." So part 4's world steps (6 to 10)
and part 5's lineage and landmark steps are built as one system, not a piece at a time: the
history pass and its landmarks and paths, structures by era with their exposure, loot that
comes from sites and storms instead of open sand, item lineage and layered marks, the feral
layer, and spawns by kit. It starts with its architecture and spine (one design, one set of
interfaces), then parallel builders on top of it. The architecture is [the world
system](world/world-system.md); its spine (the history pass, the landmarks, the path network and the site
index) is built (2026-10-17), and its build plan names the five packages that follow.

### The newer proposed order: session 4, part 4

*Session 4, part 4 (2026-10-17, [the plants session](briefs/plants-worldgen-ruins-2026-10-17.md)) lists ten
steps, "roughly in the order things can land. Follow existing conventions; no one-off exceptions in
core systems." It is a historical proposed order, not a schedule. Several items have since been
built: the feral layer on 2026-10-18 and the coalcane-burner chain on 2026-10-22. Other items
retain their current status in the linked system PRDs. It is the newer, so it supersedes part 3's
list above where they overlap. [Part 5's list](#the-newest-proposed-order-session-4-part-5), below,
is newer still. The session's scope warning stands: "the game has no structures and
no terrain generation yet. Lore here is deliberately deeper than what should be built now." This
warning describes the project at that session; world generation and structures have since advanced
([World & terrain](prd/world-and-terrain.md), [Salvage & ruins](prd/salvage-and-ruins.md)).*
1. **The crop data model (core built 2026-10-16; first crops and shared growth built 2026-10-17).**
   The planned roster and some crop behaviors remain open. The original proposal was to replace carrot
   and fungus with a data-driven crop definition: family,
   water need, light source, growth speed, yield, output type, per-axis tolerances, planter socket
   kind, propagule type and stage behaviour. Root-tuber and vat fungus go in first, as direct
   replacements, then the rest ([Farming](prd/farming.md#the-crop-data-model-the-first-step-of-the-proposed-order)).
2. **Planter socket kinds (built 2026-10-17).** Small, standard and deep sockets in the typed-socket
   system, appended to
   existing frames and never inserted ([Devices & mods](prd/devices-and-mods.md#slots-and-sticky-faces)).
3. **Shared growth stages (core built 2026-10-17; some proposed crop behaviors remain open).**
   Seedling, growing, mature, to seed, with per-crop flags: keeps growing
   (sandroot), storm-burst fruiting, cyclic water output (dewleaf, stormcup), regrow from the stump
   (coalcane), stall until rain (rainseed).
4. **Propagules and clean against wild.** One pick-up-and-plant mechanic with a propagule item per crop;
   a clean or wild flag that affects yield and output quality; going to seed flips clean toward wild.
5. **New devices.** The burner that consumes coalcane and produces power is built (2026-10-22); the
   humidifier remains proposed. The office fern's lamp uses the existing lamp-on-crate snap
   ([Power](prd/power.md#fuel-crops-and-the-burner-built-2026-10-22),
   [Devices & mods](prd/devices-and-mods.md#the-burner-and-the-humidifier-proposed-not-built)).
6. **The terrain and history generation phase.** Fixed landmarks placed per seed, then the colonial
   skeleton, then the later layers, as invisible paths. It starts with the colonial skeleton and the
   second-age roads only ([World & terrain](prd/world-and-terrain.md#world-generation-by-layers-agreed-session-4-part-4-not-built)).
7. **The repeatable structure kit.** It begins with the second age, the most common: wayshrine,
   watchtower and house ruin, each with buried, partly exposed and exposed states and an era loot
   table. Then the other eras' kits ([Salvage & ruins](prd/salvage-and-ruins.md#structures-by-era-and-the-loot-model-agreed-session-4-part-4-not-built)).
8. **Loot relocation.** Move loot out of open sand into the structures' loot tables, keeping a
   low-value drift channel carried by storm wind.
9. **Wild plant placement (feral layer built 2026-10-18; coalcane added 2026-10-22).** The feral
   layer places its implemented crops by habitat rules. The wider crop roster and some habitats from
   this proposal remain open.
10. **Spawn by kit.** Surveyor in deep desert, salvager near wrecks, homesteader on a road.

*Deferred in the original session's proposed order:* feral plants as a weather sign ("needs the queryable storm
curve from the sleep work"), later built with the feral layer on 2026-10-18; storm-only mechanics ([Wind & storms](prd/wind-and-storms.md#storm-only-mechanics-back-burner)),
landmark interiors and heat shields.

**Where it overlaps part 3's list.**

| Part 4 | Part 3 | How they meet |
|---|---|---|
| The weather sign (implemented) | 1. Feral plants as a weather sign | Part 4 historically deferred what part 3 put first. **Saltbush is the weather-sign plant**; the wild layer and its storm-driven pose were built on 2026-10-18. The dependency part 4 named, a queryable storm curve, is met ([Wind & storms](prd/wind-and-storms.md#feral-plants-the-free-barometer-agreed-session-4-part-3-not-built)). |
| 6. The history phase (second-age roads) and 9. Wild plant placement | 2. Feral plant lines along old roads | The same work, split: the roads come with step 6, and the saltbush lines that trace them with step 9. Part 3's "visual only first" is what the lines are until then. |
| 6. Fixed landmarks per seed | 6. Sister and Mother Cistern as a fixed-coordinate landmark | Sister is one of the eight fixed landmarks (Halfrise is the other second-age anchor), placed per seed and not at fixed coordinates. |
| 7. The second-age kit (wayshrine, watchtower, house ruin) | 6. Sister (a half-buried temple) | Sister is a landmark, not the kit, but its temple is the second age's biggest piece, so the kit's tables and its exposure states come first. |
| 10. Spawn by kit | 5. Kit unlocks | Neighbours: the unlock and the place a kit starts. Part 4 spawns the three balanced kits only; the Varran and Daventry starts have no spawn yet. |
| 2. Planter socket kinds | 3. The hoverboard as a superchassis | Different frames, one rule: new sockets are appended and never inserted (sockets save by list index). |
| none | 3. The superchassis, 4. The dune sailboat, 7. Ending flags | No counterpart in part 4; they stand as they are. |

Neither list holds the Console, sleep, the seed vaults, the second-age broadcasts or the endings.
Part 3's list also says no Varran, Daventry or war content goes into normal play beyond radio noise,
and part 4 adds none.

### The newest proposed order: session 4, part 5

*Session 4, part 5 (2026-10-17, [the gods session](briefs/gods-gear-farside-2026-10-17.md)) lists ten steps. They
"follow part 4's ten items. Gear and world work comes first; the gods build on top." This is a proposed
order, not a schedule: none has a stage or a date, none is built, and each waits for the skeleton's gate
as the full version does. It is the newest, so it supersedes the earlier lists where they overlap.*
1. **Timeline fix.** Add the Dark Age to world generation's history pass: lineage only, no sites.
2. **Item lineage data.** Original era plus remake history on every item. It drives the layered marks
   ([Devices & mods](prd/devices-and-mods.md#item-lineage-agreed-session-4-part-5-not-built), [art
   direction](art-direction.md#layered-marks-agreed-session-4-part-5-named-not-drawn)).
3. **Era stats.** Efficiency against repairability for each era, and the repair materials: colonial
   parts, metal, and cord, ceramic and saltbush wood ([Devices &
   mods](prd/devices-and-mods.md#frames-by-era-agreed-session-4-part-5-not-built)).
4. **Kiln.** The device, its four chains and its three era variants ([Devices &
   mods](prd/devices-and-mods.md#the-kiln-agreed-session-4-part-5-not-built), [Power](prd/power.md#the-kiln-and-its-fuel-agreed-session-4-part-5-not-built)).
5. **Landmark swap.** Remove the orbital launch site. Add the Rim depot near Sister, and the far-side
   volcano with the elevator-stub observatory at the anti-Tu point ([World &
   terrain](prd/world-and-terrain.md#the-rim-depot-the-twin-fires-and-the-elevator-stub-agreed-session-4-part-5-not-built)).
6. **Terminal output system.** Short god logs, forms and dispatches shown on consoles. One system serves
   every god ([Devices & mods](prd/devices-and-mods.md#the-terminal-output-system-proposed-session-4-part-5-first-piece-built)).
7. **God module framework.** Mountable gods as crate modules with innate powers; stationary gods as
   consoles; per-god state (willing, captive, fed, corrupted) ([Devices &
   mods](prd/devices-and-mods.md#god-modules-as-crate-modules-proposed-session-4-part-5-not-built)).
8. **Dispatch items.** Sealed packets with a sender, a recipient and opened and forged flags.
9. **The gods, in order:** the Quartermaster, Mother Cistern, the Almanac, the Stoker, the Eye. The
   Walker and the Ledger "already exist in part 2 canon."
10. **Endings.** The Haberjack bunker, the captive-launch rule, blow up the moon ([the
    vision](vision.md#the-haberjack-bunker-agreed-session-4-part-5)).

*Deferred, in the session's own words:* hoppers, orbital strike, storm radio windows, hive mind forgery,
and the Eye's growth beyond corruption.

**Where it overlaps the earlier lists.**

| Part 5 | Earlier | How they meet |
|---|---|---|
| 1. Timeline fix | Part 4, step 6, the history phase | The pass keeps part 4's layers and adds no layer: the Dark Age has no sites. Its order is colonial, collapse, skimmer era, First Kingdoms, Dark Age, second age, feral. Part 4 starts that phase with the colonial skeleton and the second-age roads only, so the Dark Age has nothing to write until loot tables exist (steps 2 and 8). |
| 2. Item lineage | Part 4, step 8, loot relocation | Lineage is drawn with a find, so it comes with the loot tables. |
| 3. Era stats | Part 4, step 5, new devices, and the crate makers | Era is a field on a frame, as the maker is: both are catalog data, and new sockets are appended and never inserted. |
| 4. Kiln | Part 4, step 5, the burner and humidifier | The same family of devices, burning the same coalcane. The kiln is the first device that processes. |
| 5. Landmark swap | Part 4, step 6, fixed landmarks per seed | One of the eight landmarks is swapped. How they are placed does not change. |
| 6. Terminal output | The Console, in neither earlier list | The output system and the Console's screen are one thing. |
| 7. God module framework | The Console's computer-mod port; part 3, step 3, the superchassis | A module is a typed part, and its sockets are appended. |
| 9. The gods | Part 3, step 6, Sister and Mother Cistern | Sister is the landmark of part 3's step 6 and part 4's step 6. Mother Cistern's terminal and module are part 5's. |
| 10. Endings | Part 3, step 7, ending flags | The new endings and the gods' states are more flags ([Profile & saves](prd/profile-and-saves.md#ending-flags-proposed)). |
| 8. Dispatch items | none | No counterpart in the earlier lists. |

Part 4's steps 1 to 4, 7, 9 and 10 and part 3's steps 1 to 5 have no counterpart in part 5 and stand as
they are. Neither list holds sleep, the seed vaults or the second-age broadcasts.
