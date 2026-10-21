# PRD: Bubble shield & the travelling camp

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

The shield is the cozy. Outside it's total chaos; inside you're fine, you're chilling,
and you have breathing room even in the middle of a storm. The shield is also the
fulcrum the camp balances on. You can drag a lot of stuff around, but whatever is
outside the bubble when a storm hits gets destroyed. So your camp is as big as the best
shield you can move through a storm.

**In the world.** Shield generators are ordinary commercial goods from a main maker, found all
over the moon, and the one you start with is its common model. A rival maker sells a different
design philosophy at the same tier, and a couple of small makers sell niche builds. The rarest
shield is military: government-issue, off the supply chain, carried here by a deserter, and it
blocks heat and dust together, which commercial shields can't. Maker names are placeholders,
and none of this is final canon; see [the lore research](../world/lore-research.md).

## What the player experiences

- **The shield is a small, light generator.** You carry it or set it down, switch it
  on, and the bubble blooms open in under a second with a hum.
- **Inside: no wind, no dust, but light comes through.** The storm's roar is muffled.
  Outside, it's chaos.
- **The bubble moves with the generator.** Carry it, or let something carry it, and you
  can travel through a storm inside it, with the camp following on short lines.
- **Outside the bubble, the weather hurts.** You take damage, and so do camp pieces left
  out. They wear down and eventually get destroyed.
- **When the power dies in a storm, it's a tough place to be.** The bubble collapses
  and the storm floods in. If you've found a hoverboard, you'd better have some juice
  left in it, because you have to run. Without one, you'd better be near the storm's
  edge. If you got here, you've probably used up every other option, and it might be
  GG.

## What hurts you out there

There are three kinds of harm. Survival owns what they do to you; this PRD owns which
shields block which.

| Harm | Where it comes from | Base shield blocks it? |
|---|---|---|
| **Wind** | Strong wind, which can happen outside storms too, in gusts | Yes |
| **Storm** | Dust and sand scouring you inside a storm | Yes |
| **Temperature** | Heat and cold, which get worse toward the poles | **No** |

**Shields protect per harm, at levels:** immune, strong, weak or none.

**Shields open up the map.** The base shield is very power-efficient, reliable, light,
easy to carry and quick to start, but it does nothing about temperature. That pushes you
into the storms early. Later shields that also hold back heat and cold are what open up
the poles.

**Late game, shields nest.** One example is a two-shield setup:
- A big **wind shield** around the whole camp: immune to wind, no help with
  temperature.
- A smaller **temperature shield** inside it, around the farm: strong against
  temperature, weak to wind.

Farming is a subset of the camp, so the temperature shield sets how big the farm can be,
and it's usually smaller than the wind shield. A **combo shield** is strong against both
but immune to neither.

## What Sand Game taught us

Worth keeping: the bubble blooming open in 0.6 s, the activate, hum and shutdown
sounds, the muffled storm inside, and the shader. What was missing:

- **Only you were protected,** not the things inside with you.
- **The wind kept blowing inside the bubble,** because there was one global wind.
- **The power drain was flat** whatever the weather.
- **"Inside" came from enter and exit events,** which can miss.

## Rules

1. **Inside is a place, not an event.** Sheltered means being within the bubble's
   radius of a running generator, and it's computed on demand. Anything can ask "am I
   sheltered?" at any moment and get the true answer.
2. **The bubble edits the weather.** Every system reads the *felt* weather: the wind
   and storm fields (Wind & storms) with shelter applied. Inside a base shield, wind
   and storm read zero. When bubbles nest, each harm gets the strongest protection
   among the bubbles you're inside. So rope loads, damage, dust, fog, sound and power all agree
   about where the bubble is, because they ask the same question.
3. **Everything inside is protected,** camp pieces as well as you.
4. **Light passes through,** so solar still works inside, as far as the storm allows.
5. **You and ropes pass through freely. Wind-blown things don't.**

## Size, and what decides the camp

The bubble's radius is the fulcrum. You *can* drag more than fits, but in a storm,
whatever is outside it gets destroyed. Two other forces push the other way:

- **Hauling capacity**, the horsepower of you, the beast or the yacht. This decides how
  much you can move.
- **Electric power.** This decides how much of what you move actually works, and how
  big a bubble you can keep up.

The shield decides how much of it is safe. All three grow with upgrades.

## Power

- **The base shield sips power.**
- **Draw depends on the shield type.** Some types draw more in storms or at larger
  sizes, and the system plans for that, but the main way to save power is simple:
  switch the shield off, and stay out of storms.
- **A full base shield lasts about 30 minutes in a storm.** That's a starting value to
  tune.
- **The wind doesn't push the base bubble.** Some later types might, which would make
  them want staking.
- **Low power gives warning.** The hum drops and the bubble flickers before it fails.
  The generator shows its charge on itself, with no menu.
- **An empty shield collapses.** Shelter switches off for everything at the same moment.

## Skeleton version

- One shield type that blocks wind and storm but not temperature. Protection is per
  harm from day one, so later types and nesting slot in without rework.
- Carry it, place it, and switch it on or off. It blooms in about 0.6 s and keeps
  running while carried.
- Shelter computed from distance, plus a felt-weather wrapper that rope wind loads,
  damage, fog, dust and sound all read.
- Wind and storm damage to you and to objects outside, with placeholder durability.
  Objects inside are safe.
- A battery that lasts about 30 minutes in a storm, and collapses the bubble when it's
  empty.
- A charge readout on the generator itself.
- Sand Game's activate, hum and shutdown sounds, and the muffled storm inside.
- Sand Game's shield shader as the starting look. Fog and dust are carved out inside
  the bubble.
- The probes below, all passing.

**As built in the skeleton (2026-10-15):**
- **The generator** is a catalog device you can carry, 6 kg. Since the chassis rework
  (2026-10-18) its only socket is a port: it stands on a deck's top and runs on the deck's pool,
  any battery stuck there, or on what a cable joins it to
  ([Devices & mods](devices-and-mods.md#the-chassis-as-the-one-structure-built-2026-10-18)). Use
  on it, or in your hands, switches it; with nothing to run on it only fizzles. Its charge
  shows on the batteries it draws from, each with its own light.
- **Draw by state:** off it draws nothing; running it sips 10 W in the clear and draws
  200 W holding back a full storm, between the two in a lesser one, so a base battery
  lasts thirty minutes in a storm. A wider bubble costs more by its shell's area. It
  draws by its load, the sand it holds back as it really is: past a full storm's only in an
  anomaly, when its hum strains higher ([Wind &
  storms](wind-and-storms.md#the-anomaly-as-built-2026-10-18)).
- **The warning** comes over the last two minutes at what it's drawing: the hum sags
  and the shell flickers, more and more often. Flat, it collapses over 0.6 s and every
  consumer agrees at every moment, since they all read the same shrinking radius. It
  blooms again by itself once its pool has power, if it's still switched on.
- **Protection is a share per harm,** 0 to 1, carried by each bubble; the levels
  (immune, strong, weak) are numbers on it. Only a bubble that stops the storm outright
  carves the dust out of the storm pass.
- **The light shield** (2026-10-16) is the one every run starts with (Survival): a
  smaller generator, 4 kg, with a 4 m bubble that keeps out the storm outright and
  85% of the wind (Hunter, 2026-10-16: blocks most of the wind, so you barely drift
  inside; at half, he was "being blown by the wind gently despite being in the bubble
  shield"). It sips 2 W in the clear and draws 20 W holding back a full storm, so the
  30 W light panel keeps it going. It starts stuck on the Surveyor's floating deck beside a
  battery, where it ranks above the trays and keeps the battery's last quarter (Power). The base
  shield, found in the deep layer, is the upgrade: a 7 m
  bubble of still air. Its numbers are its frame's own stats, so another kind is data.
- **On a deck** (2026-10-18, replacing seated on a crate): the generator stands upright on a
  deck's top, a body of its own held fast there, and the bubble rides with it, so towing or
  dragging the deck on its line carries the bubble (shield probe 4). It's in the deck's one pool:
  it runs on any battery stuck anywhere on the deck, at the same 10 W sip in the clear, and a
  panel on the deck charges those batteries in the sun (shield probe 5). Use still switches it,
  and take lifts it off whole; off the deck it has nothing to run on and goes dark. Its warning
  reads the whole pool's charge.
- **Wear:** one durability per device, until parts wear on their own. A full storm
  wrecks a device in 10 minutes; wind past 20 m/s wears it too (10 m/s past, 30
  minutes). The turbine, built to stand out in storms, is four times tougher. Wrecked,
  a device is dark for good and rusts over. Your own harm stays the storm's alone until
  Survival brings the three harms.

## The carried light shield and the starts (not built)

*Hunter, 2026-10-17 (notes). This is a change to make, not a
description of what's built. The starts are tentative, as the notes say.*

**What's built.** The light shield every run starts with is round and bone white, 4 kg, with a
4 m bubble. The Surveyor's floating deck carries it stuck on its top (As built, above). Since the
chassis rework it has no battery of its own, so lifted off the deck it goes dark in your hands:
carrying one running needs a pool that travels with you, as the Varran settler's personal shield
has: a battery of its own ([below](#the-varran-settlers-personal-shield-built-2026-10-19), built
2026-10-19).

**What the notes describe.** "New **light shield**: flat, weaker, mounts on a crate like other
shields and takes a battery like other shields, but is light enough to carry, switched on,
while you walk or board." Against what's built, to make:
- **Flat,** where the built one is round.
- **Weaker.** Weaker than what is not said (open questions).
- **Made to be carried switched on, walking or boarding,** as the hover punk's shield. It
  still mounts and takes a battery like the others, so it is the same kind of device, only
  light.

**Rejected, for powering it in your pocket:** a built-in cell and a "pocketable" flag. The
notes: "Both add one-off exceptions to core systems." A reading, not in the notes: a built-in
cell is a shield that runs with no fitted battery, against "a device's abilities come from its
parts" (Devices & mods, rule 4), and a pocketable flag is a shield exempt from the carrying
rules every other device obeys. What's left is carrying it in your hands, running.

**The starts (tentative in the 17 Oct notes; superseded in part, Agreed, session 4, part 2).**
One per playstyle ([the vision](../vision.md#player-origins-and-kits)):
- **Salvager (the hover punk):** "Hoverboard and the light shield; little else."
- **Surveyor (the hybrid, the default):** a standard shield.
- **Homesteader (the oyster):** a "solid shield," with no hover.

Session 4, part 3's two novelty starts add two more shields ([the
vision](../vision.md#player-origins-and-kits)). The Varran settler's is cheap. The Daventry patrol
board's is "strong but narrow" and "can practically stay on permanently," seated on the board's
superchassis ([Movement](movement.md#the-patrol-board-a-superchassis-agreed-session-4-part-3-not-built)).
Neither is balanced, and neither has an Ironman mode.

The notes had put "a normal shield, heavy enough not to be blown around" on "the nomad and
oyster starts," and the docs read "nomad" as the hybrid. Session 4, part 2 makes the Nomad a
different start (from the moving city, a mythic kit), so that reading is gone. Today there is
one kit, the built one, and Survival says: "Only this standard kit is balanced; choosing a kit
waits." The session balances the first three kits.

## The Varran settler's personal shield (built, 2026-10-19)

The chassis spec's "small shield carried with its own battery, raised around himself in storms"
([Profile & saves](profile-and-saves.md#starts-on-the-chassis-and-two-new-kits-agreed-2026-10-18-spec-built)),
and the seam the chassis rework left for it: a shield off a deck goes dark, so this one keeps a
battery of its own, as the radio and the heat cutter do. Not a built-in cell and not a pocketable
flag, both rejected above: a battery slot, and the suit's rule that a device you carry works on you.
- **What it is** (`personal_shield`, a give id): a flat puck in the empire's blue and ivory with a
  dome for its emitter, 3 kg, its battery cradled at its back, 7 kg with it. A 2.5 m bubble round one
  person that keeps out the storm and 85% of the wind, as the light shield's does. Cheap and hungry: 3 W
  in the clear and 50 W holding back a full storm, so a battery lasts 33 hours in the clear and two
  hours of full storm, six storms of twenty minutes.
- **Carried, it runs:** in your hands, or in your suit, where it rides on you and use in the inventory
  switches it; its bubble goes where you go, on the board too. Stuck on a deck it runs on its battery
  and the deck's pool, as the radio does, and charges there.
- **Never on the sail:** stuck on his rig, its bubble would take in the sail and the sail would feel
  no wind. Raised round you at the end of the rig's lines, it takes in only you: the sail feels the
  whole wind and the rig sails on, while you feel what the bubble lets through (shield probe 10).
- **What sits outside it wears,** as anything does: his rig, his computer and his sail in a long
  storm, and a storm's wind tears a raised sail.

## The smart shield (proposed; first version built)

*Hunter, 2026-10-17 ([session](../briefs/console-sensors-sleep-2026-10-17.md)). Direction, not a final
spec; a first version is built (As built, below). It rides on [the Console](devices-and-mods.md#the-console-proposed-first-version-built),
which is itself due for a rework.*

"A shield on a Console becomes 'smart' for now: it reports data and can be controlled from the
screen." What it can do "depends on the Console's gear, e.g. auto-on when a regular radar is
attached." And later: "multiple OEMs and parties making and modding shields and Consoles (not
designed yet)."

Readings, not in the session:
- **It already has most of what it would report.** Its charge (the light), its draw by state, its
  radius, its warning, which reads the whole pool's charge, and whether it is on. The screen
  shows what the shield knows. It would need no new state of its own.
- **Controlled from the screen** means a second place to switch it from. Today use at it, or in
  your hands, switches it, and a shield stuck on a deck stays a body of its own on its pool. On/off
  is all a shield has to control: its radius and its protection are its frame's numbers.
- **Auto-on with a radar** is the one example given. The radar reads the front's distance and
  heading ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)).
  Switching on early costs only the clear-sky sip, 10 W for the base shield and 2 W for the light
  one, until the front arrives. It would cover a storm that finds the shield off.
- **Makers are already in the world.** "In the world" above has a main maker, a rival and small
  makers, and a numbers-are-data rule, so "multiple OEMs" fits what is here. "Parties... modding"
  is the open part (open questions).

**As built (2026-10-17, a first version):**
- **Which shields are smart:** every shield in a Console's system: stuck anywhere on its deck. A
  shield off the deck isn't.
- **What it reports:** a line on the screen's stats page, what it draws and how it's switched,
  and its row on the power page, where the pool's charge and time left read for everything on it
  ([the Console](devices-and-mods.md#the-console-proposed-first-version-built)).
- **Switched from the screen:** its row on the power page switches it off, on or smart. Off and on
  are just as use at it would: with nothing to run on it won't start, and the log says so. A
  shield anywhere in the deck's power pool switches off and on there; only one in the system is
  smart.
- **Auto-on:** with a radar in the system, when the radar's nearest front comes within 1.5 km
  (tuning), every smart shield that's off switches on, and the log says "SHIELD AUTO-ON". It goes
  on the front coming within reach, once: switch it off yourself and it stays off until the front
  has gone out of reach and comes again. Only a shield set smart switches itself on; set off or on,
  it doesn't. Set smart with a front already near, it switches on at once. A shield starts smart,
  and its switch is saved with it. With storms riding at ten metres a second or so, that's about two
  minutes running early, at the clear-sky sip.
- **Its fall:** when a smart shield that's on loses its power, the log says "SHIELD DOWN · NO
  POWER".
- **Still proposed:** other makers' smart shields and Consoles, and what a Console's gear unlocks
  beyond the radar's auto-on.

## Full version

- **Shield types:** thermal shields that hold back heat and cold and open the poles,
  combo shields, and types that catch the wind. Plus bigger radii, upgrades and mods.
- **Nested setups,** like a wind shield around the camp with a temperature shield around
  the farm.
- **The warning and the collapse, staged:** the hum sagging, the flicker, the roar
  flooding in.
- **The edge of the world in a storm.** Dust churns right against the bubble's
  surface, from the same work as the wall look-test.
- **Shields on movers:** the beast or the yacht carrying the generator.

## Probes

1. **Shelter agrees everywhere.** At random points inside and outside the bubble, every
   consumer (rope wind load, damage, fog, dust, sound) agrees on whether that point is
   sheltered.
2. **Inside is untouched.** In the worst storm, a camp inside takes zero damage and zero
   wind load for ten simulated minutes.
3. **Outside suffers.** The same camp outside, in the same storm, takes damage and is
   destroyed in the expected time.
4. **The moving bubble.** Carry a running shield 2 km through a storm with a floater on
   a short line. The floater never leaves the bubble and never takes damage.
5. **Power adds up.** Drain matches the expected rate at each storm intensity and bubble
   size. An empty battery collapses the bubble, and shelter switches off for every
   consumer on the same frame.
6. **Fast boot.** The bubble is protecting within its boot time.
7. **Origin shifts are invisible.** Shelter is unaffected by a shift.
8. **Nesting takes the best of each.** Inside both a wind shield and a temperature
   shield, each harm gets the stronger protection. Inside only the outer one,
   temperature reaches you.
9. **The smart shield** (2026-10-17). A Console with a radar on a deck beside a shield,
   switched off, with a storm on its way: the shield stays off while the radar's front is
   farther than the smart shield's distance and switches itself on once it's within it,
   and the screen logs it. A shield on the sand nearby, off the deck, stays off. Switched
   off from the screen's power page, it stays off while the front holds near; switched on
   there, it's on.
10. **The Varran settler's personal shield** (2026-10-19). His kit's shield rides in your suit with
    a full battery of its own; used there it stands round you on that battery alone, in no other
    pool. Raised round you while his rig tows you across a steady 10 m/s, the sail still feels the
    whole wind and the rig sails on, you feel 15% of it, and its battery pays its 3 W.

## Out of scope

- Blocking projectiles, or any shield combat. There are no enemies.

## Open questions

The shield's power numbers get settled alongside the Power PRD. Session 4's items below are
quoted on both sides and left standing.

- **The same shield, or a new one?** Built: "The light shield (2026-10-16) is the one every run
  starts with... a smaller generator, 4 kg, with a 4 m bubble." The notes: "New **light
  shield**: flat, weaker." If it is today's, flat and weaker are changes to it. If it is a new
  item beneath today's, the name is taken twice. Weaker than what is not said.
- **A normal shield at the start, against "the first deep find reads as an upgrade".** The
  vision: "The shield and panel are clearly worse than anything found deep, so the first deep
  find reads as an upgrade." Salvage: "A found shield generator is the base shield: a 7 m
  bubble of still air against the 4 m... light shield every run starts with." The notes: "the
  nomad and oyster starts get a normal shield." Session 4, part 2 gives the "standard shield"
  to the default Surveyor and a "solid shield" to the Homesteader. If a normal shield is the
  base shield, those starts begin with what other runs find deep. Not said: whether the
  standard shield is the base shield or a step between, and what the first deep find is then.
- **"Heavy enough not to be blown around."** The base generator is 6 kg, 10 kg with its
  battery, against the light one's 4 kg. This PRD says only that "the wind doesn't push the
  base bubble." How heavy is heavy enough, and whether the built 6 kg one is, is not said.
- **Riding with it.** Movement: riding, "you take only loose things on no line." Whether a
  running shield in your hands counts as one is not written down.
- **The flat shape and era.** Art direction has devices differing by era "in shape," the shield
  first ([shape by era](../art-direction.md#shape-by-era)). Whether flat is the light shield's
  own shape or one era's is not said.

The Console session (2026-10-17) adds three, quoted on both sides and left standing:

- **Which shield is "on a Console."** Here: a shield fits a top mount or a deck mount itself, and
  seated it "shares the device's power pool." The session: "a shield on a Console becomes
  'smart'." A Console has one regular top slot, which the radio also wants (Devices & mods, open
  questions). Not said: whether smart means seated on that top slot, or also standing on the deck
  beside the Console, or anywhere in its link. *Settled by the chassis (2026-10-18):* the top slots
  are gone, and every shield stuck on a Console's deck is smart.
- **Auto-on against the switch.** Here: "Use on it, or in your hands, switches it," and "the main
  way to save power is simple: switch the shield off, and stay out of storms." The session:
  "auto-on when a regular radar is attached." Not said: what triggers it (a front within what
  distance?), whether your own off wins, and what a radar that isn't "regular" does. The shield
  already blooms again by itself after a collapse, if it's still switched on, so this would be a
  second automatic start.
- **Makers and modders.** Here: shield makers are in the world, a frame's numbers are data,
  parts are "found, never crafted," and crafting is out of scope. The session: "multiple OEMs and
  parties making and modding shields and Consoles." Not said: whether the parties are in-world
  makers (the lore has them) or people outside the game making and modding its devices, and what
  "making" means with crafting out of scope.

Session 4, part 4 (2026-10-17) adds one, quoted on both sides. The newest session wins in the living
docs, so this PRD follows it as direction.

- **Crops' tolerances are the shield's work.** Here: the base shield holds back wind and dust and not
  heat or cold, and a thermal shield is a full-version type, with one test-only copy in the probes. The
  session: every crop has separate tolerances for wind shear, particle abrasion, heat, cold and
  radiation, and "shields (wind/particle now, heat later) remove most weather factors," so late-game
  farming manages light and water with lamps and humidifiers ([Farming](farming.md#progression-agreed)).
  "There is no heat shield in the game yet." *Follows the session.* Not said what blocks radiation, or
  whether a shield blocks humidity (a storm crop's input) as it blocks the storm's wind and dust.

## The Salvager's personal shield (Hunter, 2026-10-19)

The Salvager now uses the existing carried personal shield, as the Varran does, with
an independent full battery. This supersedes the earlier light-shield-on-plate
starting arrangement for new Salvager runs. The personal shield retains its existing
2.5 m radius, 3 W clear/50 W storm draw and 85% wind protection. No shield tuning or
protection mechanic changes. Its portability supports scouting before finding a home.

## Marked Home: first local expedition slice (selected 2026-10-20; in progress)

A small Home beacon fits a chassis through ordinary mounting. Use it with free
hands to mark one travelling Home. The Surveyor carries one; ordinary surface
salvage can supply another. Marking explicitly claims no untouched loot.

Membership includes the marked chassis assembly, claimed loose belongings inside
its attached shield's configured envelope, and the owned stakes, lines, guides
and cables needed by those belongings. The player and ridden board do not extend
this graph. Membership survives shield shutdown, battery failure and beacon loss;
those affect protection/reception, not ownership. Refresh moving assemblies and
remove genuinely destroyed members. Removing an item from the camp must remain an
ordinary physical action. Replacing/unmarking Home is allowed only when its old
support can safely return to the player area, without immediately deleting it.

Admit the whole graph before reporting Home ready. Initial engineering limits are
512 bodies, a 128 m horizontal span and 49 additional support chunks including a
one-chunk collision halo and one retirement margin. A maximum aligned footprint
can cover three-by-three chunks; collision support expands that to five-by-five,
and safe retirement keeps at most seven-by-seven. Store these in tuning; measure before accepting them as
an operating budget. Refuse an oversized mark visibly rather than keeping a
partial camp. Later motion/extension must not delete an existing admitted member
or introduce magnetic forces; retain its last supported footprint while reporting
that it needs attention and prepare new support before retiring the old support.

Retain actual terrain, collision and history as a second bounded area. Keep the
existing physics, weather, wear, power, water and crop operation. Do not freeze a
remote camp, grant invulnerability or introduce a second catch-up simulation.
Save stable member references, geographic anchor and local member poses; request
remote support before restore waits for distant bodies. Old saves without Home
retain their existing behavior. Check a two-kilometre scouting round trip,
including origin/history changes and a distant save/resume; that check does not
establish an unlimited moon-wide operating range.

The beacon draws 1 W through ordinary device power. Its first reception range is
2 km, subject to measurement. A requested Home view in the carry interface shows
bearing, distance and reception/support status. Keep a clearly labelled last-known
fix when power or range prevents updates. This is known-point navigation with no
automatic terrain survey or permanent HUD/minimap. A moving camp updates its fix
when received. A return after leaving the ordinary player retention area records
one camp-family deed at arrival; tune departure and arrival distances centrally.

This feature is complete only when marking, admission, remote simulation, return
navigation and far restore work together. A marker alone does not make scouting
safe. The current travelling camp and baseline suit protection remain usable.

**Initial implementation evidence (2026-10-20):** The physical beacon, requested
return view, explicit claimed membership, second support region and far-save
references are connected. A 2.1 km round trip/restore and remote battery draw pass.
The beacon model is one cached surface (1,164 triangles), inspected in real GPU
captures. These checks cover a small camp; combined CI, larger camp budgets and
unassisted expedition play remain acceptance gates.

The Surveyor guide's scouting page now teaches taking out and mounting the packed
beacon, marking with free hands, waiting for ready support and opening Home for
return navigation. Compass, landmarks, mooring and weather preparation remain
relevant; a saved fix does not provide shield power or protection.

**Admission-limit measurement:** An isolated real CampHome graph with 512 work
items (511 rigid members, 25 support cells) took 5.462 ms p50 / 5.601 ms p95 to
refresh across 240 samples after 30 warm-ups; maximum 6.237 ms, initial mark
6.949 ms. Item 513 refused the whole mark. The fixture used frozen catalog hooks
and a small footprint, isolating graph CPU cost. It does not establish full
physics/GPU, heterogeneous-device or maximum-span performance acceptance.

### Live expedition acceptance (2026-10-21; focused checks passed)

The bounded follow-up keeps a small marked shield/solar/battery camp and a
claimed loose supply physically active during a 2.1 km scouting departure.
Power must continue through ordinary ticks, including generation and demand,
and shutdown must not erase the loose member. Save while far, restore the
actual supported objects, then return to the same camp and inspect its GPU view.
Existing focused history checks remain the duplicate-sheet acceptance; this
check adds the live-resource and membership combination rather than a second
remote catch-up simulation. It does not establish the maximum camp budget or
boarding/hoverboard travel acceptance.

**Measured result:** Camp 9 passes in 24 s. It marks through the ordinary hands
use path, keeps the unfrozen chassis and loose supply while 2.1 km away, samples
Home's own geography/day/temperature, and runs ordinary automatic power ticks.
The remote camp cell gains charge; total stored energy matches generation minus
demand and spill. Shield shutdown, far save/restore and return preserve exactly
one loose supply and one shield, with no ground rescues before or after restore.

The matching Forward+ 1280×720 return capture passes and was inspected. Its 10 s
remote interval generated 0.139396 Wh, consumed 0.008333 Wh and added 0.131063 Wh
to the actual camp cell. After returning it reports four physical members, 289
loaded chunks and 25 collision chunks. These are one clear-day, still-air,
two-piece stationary camp measurements. The scripted scout relocation and camera
helper do not establish hoverboard travel, human comprehension, storms, moving
rigs or the maximum camp budget. No remote simulation code change was needed.

**Medium-camp acceptance (2026-10-21; focused checks passed):** Exercise a nine-piece
joined deck with mixed hover/skate mounts, powered shield and beacon, solar,
battery dock, condenser and radio, plus a separate tethered planter with stored
produce and a loose claimed supply. Keep ordinary body physics and support
contacts active through a 2.1 km departure and return. Compare the same near camp
unmarked and marked before measuring the retained distant camp; an unmarked
distant camp would be deleted and is not an equivalent baseline. Record engine
main-thread/physics frame times and active-body counts without imposing a new
machine-dependent threshold. Inspect a real unseen return capture. This is a
medium assembly check, not acceptance of the maximum admission count or span.

Camp 10 and the actual unseen `look/home/medium` fixture pass with nine joined
pieces, seven hover trays, two skate mounts, a four-cell dock, two solar panels,
shield, beacon, radio, condenser, tethered planter with four stored coalcane
bundles, one loose bundle, two stakes and three physical lines. This is **10
physical Home members / 46 work items**, with a 189.1 kg joined deck. The skates
are raised clear by powered hover; this checks mixed mounts and actual hover
support, not simultaneous loaded skate contacts. The planter retains its own
real battery/tray and tether, rather than being artificially frozen or mounted.

The focused headless check passed in 28 s. Two actual 1280×720 GPU return views
were inspected: the deck remained assembled and level, with the planter and loose
supply still beside it inside the shield. The fixture samples 240 ordinary
physics frames per phase and watches deck motion continuously after initial
settling, including streaming and origin changes. World resources keep their
normal ticks. Travel is scripted and player physics is disabled by the shared
hands fixture; this does not validate an unassisted hoverboard route, long storm
survival, maximum admission count/span or a general frame-time budget.

In the final GPU run the continuously observed deck stayed below 0.0012 rad/s
spin, 0.0063 m/s speed and 0.780° tilt, with zero ground rescues. Near the same
camp, unmarked then marked, median sampled engine process estimates were
13.904 / 14.218 ms; physics estimates were 6.921 / 7.284 ms. Distant marked
estimates were 14.087 / 8.045 ms, with 314 terrain / 50 collision chunks instead
of 289 / 25 near camp. These are **coarse engine-monitor observations on a
shared desktop**, not independent per-tick timings or isolated Jolt solver cost.
The physics active-object monitor returned zero despite the live bodies, so it
does not establish an active-body count. Remote and near scenes differ; their
whole-frame difference cannot be attributed solely to Home membership.
