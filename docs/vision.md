# Sandgame — Vision

*Working title. Draft, 2026-10-13. This page is the source of truth for what the game is;
every PRD answers to it.*

## The game in one breath

A cozy survival game on a dead desert moon. Your home is a bubble shield you carry with
you, tied down with rope against the wind. You wander wherever you like, and the better
you play, the more your little camp sustains itself, until you can stop, sit back, and
let it run.

## Pillars

1. **Steady state is the reward.** Getting stronger means getting more self-sufficient,
   not more powerful in a fight. A well-run camp reaches a steady state where going AFK
   costs nothing. That's the satisfaction of a Satisfactory factory or a Minecraft AFK
   farm, at the size of one traveller. In practice, it's a power budget that balances
   through day, night and storm.
2. **Your home goes with you.** There's no base to return to. The shield, the planters
   and the power all travel with you, tethered against the wind. You pick the direction.
3. **The wind is the difficulty dial.** Drift with the wind and life is calm. Push into
   it and things get harder, but storms strip the dunes and uncover more, so the
   rewards get better.
4. **Cozy, not hostile.** No enemies to fight and no tower defense. The pressure comes
   from the moon itself: wind, storms, heat, thirst. The feeling inside the bubble is
   warmth and safety, with the radio on.

## Core loop

Wander → find what the wind uncovers → bring it into the bubble → grow, power and
upgrade the camp → the camp sustains more of itself → go further, or into the wind.

## Two moods

- **Clear skies:** big, lonely, epic views to a horizon blurred by heat shimmer. These
  are rare, and you earn them with diligence and some luck in staying away from the
  storms.
- **Inside a storm:** you can barely see past your shield, if at all. This is where it
  gets cozy.

## The camp

- **Editing your devices is the gameplay.** Every device is modular, with sockets for a
  battery, rope hooks, a hover tray and better parts. Fitting a hook, a tray, a better
  battery or a charged one is how you progress.
- **The camp is several physical things, not one building.** The shield is small enough
  to carry. Planters, power and the rest are objects in the world that you tether
  together.
- **The shield decides how big the camp can be.** Whatever is outside the bubble in a
  storm gets destroyed, so the camp is as big as the best shield you can move through a
  storm.
- **Shields open up the map.** The base shield keeps out wind and dust but not heat or
  cold, so it pushes you into the storms early. Shields that hold back temperature are
  what open up the poles. Late game, shields nest: a big wind shield around the camp,
  with a smaller temperature shield around the farm.
- **It floats when there's power for it.** When there isn't, you haul it. Running low on
  power should feel like a slowdown, not a wall.
- **Power sources trade off against movement** (leaning, not settled). Solar builds
  power by day but is useless in a storm. Wind power is strongest in a storm, but it
  has to be planted, so you either stay or leave it behind. Heavy gear, like something
  on caterpillar tracks, is strong for the camp but slows you down.
- **Parts are found, never crafted** (for now), and they wear out only from the
  elements. Salvage is the whole economy.
- **The camp may get a computer, and a bed** (Hunter, 2026-10-17, proposed and loose). A Console
  reads the weather instruments onto a screen ([Devices & mods](prd/devices-and-mods.md#the-console-proposed-not-built)),
  and sleep may skip the wait on a long storm ([Survival](prd/survival.md#sleep-proposed)).
- **The camp moves at walking pace, and storms are weathered, not outrun.** Each storm
  is a judgment call: stay and let it pass, or push through inside the bubble. Early on,
  a post or ruin to tie to is precious.
- **Haulers make the base faster later:** a rusty mechanical beast that follows and
  carries (stiff parts, so no skin rigging), a sand yacht that rides the wind and might
  outrun a storm with the camp aboard, and big carriers. (Agreed, session 4, part 3: the Varran
  start has a dune sailboat, a slow wind-driven hauler, which the Movement PRD keeps apart from
  the yacht: [Movement](prd/movement.md#the-dune-sailboat-agreed-session-4-part-3-not-built).)
- **The hoverboard is just for you:** fast, floaty and fun, for scouting and escaping. It
  tows nothing. (The one proposed exception is the Daventry patrol board, a novelty start whose
  board is its own superchassis with a tow:
  [Movement](prd/movement.md#the-patrol-board-a-superchassis-agreed-session-4-part-3-not-built).
  The standard board still tows nothing.)
- **Your hands plus what the suit carries, by weight, and almost no menus.** Things live
  in the world and in your hands, not in an inventory screen. (Hunter, 2026-10-15, loose:
  one action brings up a very minimal overlay of what you carry and what's at your waist,
  tied into the world rather than managed. Maybe putting something down while it's open
  stows it. Most menus come as devices. A main menu exists for new run, resume and
  options. 2026-10-17: "Move to weight-bound with no defined size, replacing slots. This
  allows stacks and avoids inventory management.")

## Playstyles

*Hunter, 2026-10-17 ([notes](session-notes-2026-10-17.md)); loose.* Three are supported, and
the game is balanced around the first.

1. **Hybrid (intended).** Drag the camp for heavier challenges (power checks, for example),
   stake it, scout and loot on the hoverboard, then move toward heavier loot.
2. **Hover punk.** Ditch the kit, board only, read the wind and outrun storms, loot up to high
   tier.
3. **Oyster.** Fully stationary: pop the shield immediately, rely on knowing cooldowns, spawn
   rates and the weather, and build an automated AFK setup.

**The extremes are loot-limited by design:** oysters never find ruins, and hover punks miss
loot freshly exposed by storms.

Each has a start of its own in [Player origins and kits](#player-origins-and-kits): the
Surveyor is the hybrid, the Salvager the hover punk and the Homesteader the oyster.

These are about how you carry the camp. The "two play styles" under latitude (below) are about
where you are. The pillars above describe the hybrid. How the two extremes sit with pillar 2,
"your home goes with you," is in the open questions.

## Player origins and kits

*Agreed, session 4, part 2 ([lore session](lore-session-2026-10-17-part-2.md)); loose, and none
of it is built. Only the standard kit exists today. The last two rows before the hive mind start,
the Varran settler and the Daventry patrol board, are session 4, part 3's ([lore
session](lore-session-2026-10-17-part-3.md)).*

The region is healing and people are exploring again, so Zan is being rediscovered by several
kinds of arrival at once. **Balance only the first three.** The rest are novelty starts, excluded
from Ironman (the session writes "Iron Man"). The first three are the three playstyles above:
the Surveyor is the hybrid, the Salvager the hover punk and the Homesteader the oyster.

| Kit | Who | Starting gear | Unlock |
|---|---|---|---|
| **Surveyor** (default, balanced) | Tilg & Standard contractor: spend a decade or as long as you can, build a real base, set for life. No interstellar comms ("not in the budget"). | Tilg-issued crate, standard shield, hover tray, Tilg multi-compass, stake tether, radio. Roughly today's kit. | Default |
| **Salvager** (the hover punk) | Independent scavenger with a board and nerve. | Hoverboard and the light shield; little else. | Playstyle, e.g. long board distance or surviving a storm on carried gear |
| **Homesteader** (the oyster) | Settler come for cheap land, naive about why everyone left. | Full agriculture setup, solid shield, collector (wind net); likely turbine, battery bank, condenser, extra stakes. **No hover.** Civilian brand marks, not Tilg's. | Playstyle, e.g. riding out big storms without moving camp |
| Archaeologist | University expedition. | Ground-penetrating radar, better radio, weak shield, little power. | Proposed: finding a number of landmarks |
| Replacement | The next Tilg surveyor, sent on schedule since Tilg can't know the first is dead. | Starts at the previous run's last camp, among its wreckage. | Needs a prior save |
| Prisoner | Wakes in a cryo cell at the Provisional's black site, `{YEARS_SINCE_FALL}` late. | Almost nothing; the cell is the first shelter. Spawns deep under Tu. | Finding the black site |
| Nomad | From the moving nomad city; best at reading wind and stars. | Mythic. | The nomad city ending |
| Varran settler | Brandt's optimism in a crate; came to claim Zan. | A dune sailboat, a slow hauler for hybrid play; a cheap shield; a planter; solar; a Varran radio tuned to home frequencies it can't hear from the surface. Fragile, needs wind, low-quality parts. | Build and use a dune sailboat |
| Daventry patrol board | Licensed, sealed military kit; here to inspect, not live. | A heavily modded military hoverboard, "a camp in a board," its own bespoke superchassis: a strong but narrow shield that can practically stay on permanently, a tow, a bedroll (sleep out storms under the shield), a compact high-capacity battery, a small direction-finding radio and a tiny condenser. Few slots; anything big still needs a camp. | Build a patrol-style board yourself (proposed; the exact unlock is open) |
| Hive mind experiment | A made human, sent to the moon the hive mind named first. | Secret. | The last unlock in the game |

All starting gear for the surveyor is company issue, which fits the existing "new" mark row and
its cheap batch stencil ([art direction](art-direction.md#makers-marks)). Unlocks all go through
`profile.unlock` ([Profile & saves](prd/profile-and-saves.md#kits-are-data)).

**Two more novelty starts (Agreed, session 4, part 3).** One per state of the player's time, each
a counterpart to the other: a slow hauler and a fast armoured board. Both hand the player
something normally hard to get, as a sidegrade, not overpowered without the rest of a setup.
Balance stays around the Surveyor, the Salvager and the Homesteader. These two, like the other
novelty kits, aren't balanced and get no Ironman. The states themselves stay offstage ([lore
research](lore-research.md#the-wars-end-the-wall-and-the-states-of-the-players-time-agreed-session-4-part-3));
a kit names its state and nothing more, and whether even that fits "galaxy lore stays offstage"
is an open point ([section
17](lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)). What the kits are
built on is proposed in [Devices & mods](prd/devices-and-mods.md#the-patrol-board-as-a-superchassis-proposed-not-built)
(the board's superchassis) and [Movement](prd/movement.md#the-dune-sailboat-agreed-session-4-part-3-not-built)
(the sailboat). Their unlocks are in [Profile & saves](prd/profile-and-saves.md#kits-are-data).

**Clash with the built kit (recorded, not to build).** The Surveyor lists a standard shield, a
multi-compass, a stake tether and a radio. Today's kit ([Survival](prd/survival.md), as built) is
a light shield, a light solar panel and a hoverboard racked on the crate; the radio and the
compass are finds, and there is no multi-compass. The session calls the Surveyor "roughly today's
kit," so this is a difference to settle, not a change to make. A standard shield at the start
also reopens "the first deep find reads as an upgrade" (open questions). The same session turns
"nomad" into a different start: the tentative note of 2026-10-17 put a normal shield on "the
nomad and oyster starts," and the Homesteader (the oyster) gets a solid one while the Nomad is
the moving city's mythic start.

## Runs

- **Endless by default.** No run has to end, and the game is meant to be played
  indefinitely. Endings exist, but only for players who choose them for story reasons
  ([Landmarks and endings](#landmarks-and-endings), session 4, part 2).
- **Death means a new run.** Whatever you had stays out there in theory but is
  practically unreachable. With RNG driving both the terrain and the finds, this is
  roguelite territory. One novelty start, the Replacement, begins at the last run's camp
  ([Player origins and kits](#player-origins-and-kits)).
- **You start with the essentials:** a floating crate with a weak shield and a light
  solar panel mounted on top and a hook to tow it by, moored by its short line to a
  stake (a loose floating crate blows away in the first breeze), a hoverboard racked on
  its side (Hunter, 2026-10-16), and sealed water and a ration in the suit (Hunter, 2026-10-16: "start the
  player with floating crate, shield and hoverboard"; earlier the same day the shield
  and panel lay on the sand and the board was only a find). The shield and panel are
  clearly worse than anything found deep, so the first deep find reads as an upgrade,
  and the kit can never leave the shield without power. (Agreed, session 4, part 2: the start
  does differ by origin. The default Surveyor lists a standard shield, which clashes with the
  built kit's light one, and the Salvager gets the light shield. See [Player origins and
  kits](#player-origins-and-kits). It replaces the tentative note of 2026-10-17, which put a
  normal shield on "the nomad and the oyster"; the open questions and [the bubble shield
  PRD](prd/bubble-shield-and-camp.md#the-carried-light-shield-and-the-starts-not-built) follow.)
- **Saving and loading is the default; Ironman is its own mode** (Hunter, 2026-10-16,
  after a fun run that dying wiped: "dying actually hurt"). By default you save when you
  like, the game saves for you every few minutes and when you quit, and death offers to
  load your last save. Ironman, chosen at New game, is the old rule: Save & quit only
  suspends the run, and death ends it ([Profile & saves](prd/profile-and-saves.md)).
  Whether achievements care which mode a run is in is still open.

## Landmarks and endings

*Agreed, session 4, part 2; the ladder, the variants and the modifiers are the endings session's
([endings and radio](endings-and-radio-2026-10-17.md)), each item **Agreed** or **Idea** as that
session labels it, and the pathfinder, the ascendancy split and the three axes are session 4,
part 3's ([lore session](lore-session-2026-10-17-part-3.md)). Where they differ part 3 is the
newer. Loose, and none of it is built. The replaced table, the clashes and what stays open are in
[the lore research, section 17](lore-research.md#17-open-after-the-endings-session-and-session-4-part-3).*

The game reads as an infinite survival game. Endings exist only for players who choose them for
story reasons, and many players will never see one.

**Principles.**
- **Agreed.** Endings are optional and mostly very hard to reach, at varying levels of rarity.
  Many players will never see one; the game should feel like infinite survival.
- **Agreed.** No NPCs, no dialogue, no exposition. Choices are made through physical actions and
  gear, and consequences are heard on the radio or seen through instruments.
- **Agreed.** Endings fall into two families: **official** (clearance, a login, a rescue, an
  invitation) and **outlaw** (slipping away the skimmer way, unnoticed). The session doesn't say
  which ending is which; a reading is the escapes, the long wait and the nomad city as official,
  and the outlaw Up the well and the stolen freighter as outlaw.
- **Agreed.** Two multi-ending **modifiers** change how any ending plays out: the **observatory**
  (seeing) and the **Walker** (taking or sparing). Session 4, part 3 adds three **axes**: Varran
  flavour, the Daventry axis and the Cistern axis.
- **Agreed (session 4, part 3).** Galaxy lore stays offstage until the endings. Nothing about the
  war, Varran or Daventry appears in normal play except as faint radio.

**Landmarks** are one general system, not one-offs: a small class of prefab sites at fixed
coordinates on the planet grid, the same in every run, that persist the player's changes. They're
the only fixed things on a shifting moon, the exception to unloading out-of-range content. They
can unlock endings and, for the prisoner, spawns. Candidates: the StarCom antenna, the black
site, the Bastion and the Ledger, and from session 4, part 3 **Sister**, the temple of Mother
Cistern. The endings need more places (the sealed hangar in Aitch, the observatory, the far-side
ice, an orbital station), and whether each is a landmark is not said. [World &
terrain](prd/world-and-terrain.md#landmarks) and [Salvage &
ruins](prd/salvage-and-ruins.md#landmarks) hold the rule and the sites.

### The ladder

Roughly from most achievable to rarest. Order, not exact tiers. This replaces the last fold's
shorter table of StarCom, Launch, Shot down, Nomad city and Radio.

| Ending | How | Status |
|---|---|---|
| Shot down (small ship) | Launch a small ship from Port Morgan with only the Ledger's approval; the Quartermaster's air defences shoot you down. The lamest in theory and the most achievable. | Agreed |
| Shot down (freighter) | The same, lifting the freighter. | Agreed |
| Small ship escape | Both the Ledger and the Quartermaster authorise. | Agreed |
| Freighter escape | Lift the whole freighter with both AIs. The Ledger is the freighter's own mind, so the god of the crusades leaves with you. | Agreed |
| The long wait | Make the call (StarCom or radio) and survive the years until a Tilg & Standard ship arrives. Endurance test. | Agreed, must keep |
| Up the well | Restore a skimmer from a sealed hangar deep in Aitch (buried old H-Town), reach orbit, refuel from Tu. Accessible but fairly high tier. See the variants. | Agreed |
| The pathfinder | You never leave Zan; you open the door for someone else. Around or just above Up the well. | Agreed (session 4, part 3) |
| Stolen freighter | Sneak the Ledger's freighter past the Quartermaster (fool it, e.g. a forged Provisional clearance, or knock out the air-defence net) and take the dead lane into old hive mind space. Same tier as AI ascendancy. | Agreed |
| Nomad city | Find the last city. Among the rarest. | Agreed (existing) |
| AI ascendancy | Upload yourself, or, as the hive mind, eat the other gods. Split into regular and true: see below. | Agreed |
| Bringing Zan back | Court Tilg & Standard into investing and terraforming. The rarest; funnels in every other ending. See below. | Agreed |
| Atmosphere | Outlast everything until the air runs out. Not chosen: it arises from a world clock. | Agreed, needs the clock (not built) |

**Carried over from the last fold's table,** where the ladder doesn't contradict it:
- **The long wait** (was StarCom): repair the StarCom interstellar antenna with the right parts.
  Comms are instant but ships take years, so Tilg answers and extraction is years out, and the
  finale is surviving until they arrive.
- **The escapes** (were Launch): the Ledger knows the ships, and the Quartermaster holds the
  clearances. Connecting them means bridging Mon and Han across open desert: two gods talking
  directly for the first time in centuries.
- **Shot down:** the Provisional's old air-defence net shoots down an unauthorised launch. Shot
  down by paperwork.
- **Nomad city:** survive long enough with a camp worth finding, with a powered shield, turbines
  and a radio on the right frequency. The city finds you; a tether line lands at camp and pulls you
  in. Silhouettes only. Giga-rare; best fit for oysters. The ladder says only "Find the last
  city," so both stand and which one triggers the ending is not said ([section
  17](lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)).

**Ideas still loose.** *Wrong answer* (you call out and something that isn't Tilg answers) fits
the hive mind start as the way you discover what you are. *Okafor line*: an underground bunker
with a holdout. *Radio ending* (from earlier docs, "Find the right frequencies to reach Tilg or
the last town") remains undesigned.

**The freighter** is lore: one freighter was left behind at Port Morgan, the Ledger is its
mainframe, and the launch endings use it or a smaller ship from it ([lore
research](lore-research.md#the-freighter-left-behind-agreed-endings-session)).

### Up the well, variants

The source labels the row above Agreed and gives its three variants no label of their own, so
they are carried under the row's.
- **Unprepared:** you reach the abandoned station and starve in orbit. Bleak.
- **Prepared:** the station's antenna has a clear line out above the storms, so it's a faster
  route into the long wait, if you packed enough to survive it.
- **Outlaw (favourite):** slip off unnoticed, even by the Quartermaster, and fly in-system to a
  small new He-3 outpost on a moon of the outer cold giant, set up recently as the region
  recovers. Needs the coordinates (found, or a lucky guess), a fuelled skimmer, and a camp that
  lasts the trip (about a week). You end up among people in a little frontier town, mirroring how
  Port Morgan filled with unregistered drifters. In session 4, part 3 the outpost is a Varran
  frontier town.
- **Idea.** The new outpost is also why Tilg & Standard is sending surveyors now: people are
  coming back to this system.

### Stolen freighter

- **Agreed.** The dead lane is unwatched because it leads toward old hive mind space.
- **Agreed.** The destination's coordinates are written in the hive mind's own naming (it had its
  own name for Zan), readable only from the deepest lore.
- **Agreed.** The arrival stays ambiguous, like the nomad city: lights on an alien horizon,
  shapes that aren't human, cut. Humanity was never alone out there; nothing more is shown.

### The pathfinder (Agreed, session 4, part 3)

You never leave Zan; you open the door for someone else. Tier: around or just above Up the well.
1. **The map:** the restored observatory plus knowledge of the dead lane.
2. **The ear:** only from the orbital station, above the storms, does the antenna hear Varran
   broadcasts.
3. **The act:** transmit the dead-lane coordinates on the Varran frequency.

Epilogue: broadcasts change tone, Brandt's fleet passes overhead through the observatory, then its
lights head down the dead lane. Ambiguous whether you saved or doomed them. No alien city is
revealed; that stays with the stolen freighter.

### Ascendancy, regular and true

- **Agreed.** A human can upload themselves: the body stays at camp, the mind joins the gods.
- **Regular ascendancy** (any start; session 4, part 3): upload yourself and join the network as
  one god among the others, your own voice on the radio.
- **True ascendancy** (hive mind start only; session 4, part 3): consume the other gods. It
  requires a linked Mother Cistern. On the radio the gods go silent one by one until yours is the
  only voice, Sister goes dry, and your voice reaches Varran frequencies: the possum wakes up. The
  faith's original sin returns to Zan.
- **Agreed.** Clear path for the hive mind, obscure for a human.
- **Idea for the human route:** captured hive mind tech sealed deep in the black site looks like
  an incredibly powerful Console mod. Install it, then link the gods through your Console, and it
  eats them instead of bridging them. Nothing warns you; the radio going quiet is the only sign.
  Kept as the endings session wrote it. It clashes with part 3's "hive mind start only," which is
  the newer, so as things stand it is an Idea with nowhere to land ([section
  17](lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)).

### Bringing Zan back (staying)

- **Agreed.** The capstone, and the only ending that saves Zan rather than leaving it. It
  requires a bit of everything: a camp that sustains itself through the worst storms; the
  far-side ice; the restored observatory; a working call (StarCom or the station antenna); and the
  Ledger and Quartermaster connected so Zan's own systems vouch for the claim. Session 4, part 3
  adds a linked Mother Cistern.
- **Agreed.** It must beat the atmosphere clock: whoever comes has to fix the leak
  (terraforming), not just visit.
- **Agreed.** It fans out into variants by construction, not menus: the player should know Zan
  plays out as they intended, even if it isn't simulated. Epilogue as a few still frames.
  Proposed levers: who you call (Tilg & Standard, the outpost drifters, the nomads); registered or
  kept "temporary" (Okafor's old question); which god leads (Ledger, Mother Cistern, or you if
  uploaded); and what you did about the nomads (below).
- **Answered by session 4, part 3.** The endings session left it open: "The Provisional is gone by
  the player's era. How the war ended and what human government exists now is deliberately
  undecided." The war ended in quarantine and fracture, and the states are Varran, Daventry and
  the Rump UG ([lore
  research](lore-research.md#the-wars-end-the-wall-and-the-states-of-the-players-time-agreed-session-4-part-3)).

### Modifier: the observatory (Beyond the Eye)

- **Agreed.** Far-side heretics of the second age worked out that Tu is a planet, not a god, and
  built a telescope where Tu never blocks the sky. Restoring it is a physical goal and a modifier
  for every ending. Every ending gets a blind and a seeing version, and what it unlocks can
  depend on the state of the world.
- **Proposed effects.** Shot down: spot the old defence satellites, so you know you need the
  Quartermaster. Freighter escape: plot a real course. Long wait: watch the rescue ship's light
  approach, a countdown. Up the well and outpost: coordinates and the outpost's glint. Stolen
  freighter: the hive mind name matches a real star. Nomad city: see its lights crossing the dark
  side and intercept it. Staying: see the settlers' route in. AI ascendancy: the uploaded mind
  gets the telescope as its eye. Atmosphere: watch the halo of air thin and measure the clock.

### Modifier: the Walker and the nomads

- **Agreed.** By the player's era the Walker is alone and partly broken; most nomads have died
  out. It still broadcasts its route, and the last nomad city follows that signal from afar. The
  Walker is outside the Ledger and Quartermaster system and normally its own thing; finding it
  must never happen early.
- **Agreed choices:**
  - **Steal its core:** a legendary module. The city doesn't lose its way but suffers badly, and
    their radio station changes so it's clear you've sold them out. Carries into whatever ending
    you choose.
  - **Take the whole Walker** onto a chassis: works as a Console with full weather sensing built
    in (like two fully modded weather Consoles), leaving its slots free for other mods.
    Important late game ([Devices & mods](prd/devices-and-mods.md#the-console-proposed-not-built)).
  - **Copy its data** (plug the Console in briefly): registers the nomads in your report; no
    gameplay benefit.
  - **Leave it alone:** they stay free and uncounted.
  - **Never find it:** the colony arrives blind.
- **Agreed.** Keeping a carried Walker broadcasting (a "religious zeal" module) costs you
  something (power or a slot), so players are tempted to switch it off. If it keeps broadcasting,
  the nomads follow you, a pilgrimage.
- **Idea, open.** Meeting the city while holding their god: if their pilgrimage is underway and
  you never contacted them, they're hostile and kill you (an ending); if they haven't set out,
  they're shocked; if you had prior contact, they're not hostile. Hard parts: showing the
  pilgrimage without dialogue (idea: their station's route calls stop and become a repeated chant
  of the Walker's call sign; radar or the observatory shows their lights turning) and what
  "explaining yourself" or prior contact means with no NPCs (idea: actions, like switching the
  broadcast back on or returning the Walker).

### The three axes: Varran, Daventry and Cistern

*Agreed, session 4, part 3.* They are cross-cutting modifiers beside the observatory and the
Walker. How each is actually implemented is open, and so is how the player learns a choice
matters without exposition (a seed: hearing a Daventry broadcast hints they can hear you).

| Ending | Varran flavour | Daventry axis | Cistern axis |
|---|---|---|---|
| Shot down (both) | None; the Quartermaster's ancient war is the joke | - | - |
| Small ship / freighter escape | Varran traffic logs you as a Provisional vessel | Unaffected | Restored: flowing water left over empty Sister |
| The long wait | Rescuer may be Tilg & Standard or a Varran ship that claims Zan | Daventry may arrive instead, to inspect and quarantine | Restored: your water supply; rescuers find a working shrine |
| Up the well (outlaw) | The He-3 outpost is a Varran frontier town | Unaffected | - |
| The pathfinder | Core of the ending | Daventry hears too and meets Brandt's fleet at the lane: you've started a war | - |
| Stolen freighter | Brandt's fleet arrives behind you | Loud: Daventry waits at the lane. Quiet: unnoticed | - |
| Nomad city | None; timeless | - | Restored: the city settles at Sister (stacks with Walker) |
| AI ascendancy (true) | The possum wakes on Varran frequencies | Daventry proven right publicly | Required; consumed, Sister goes dry |
| Bringing Zan back | Varran settlers are one terraforming lever | - | Required. Linked = full terraform, first rain over Sister |
| Atmosphere | None | - | Restored: slows the clock slightly |

The table has no row for regular ascendancy.
- **Daventry's trigger:** anything touching the dead lane, by broadcast or by ship. Player control
  is how careful you are with the transmitter.
- **Cistern's states:** dormant, restored, or linked into the network. She is never the ending;
  she decides whether Zan is left better or worse than you found it.

### Running gags, and the hive mind start

**Running gags to keep.** The Ledger is Tilg property, so the surveyor is the only person on Zan
with a login to the god of the crusades. The Quartermaster is the Provisional's, so a Tilg login
means nothing to it ([the AI
gods](lore-research.md#the-faith-of-tu-and-the-ai-gods-agreed-session-4-part-2)).

**The hive mind start changes the endings without a cutscene.** Fix StarCom and someone answers,
but not Tilg. Try to launch and the Quartermaster recognises you as the enemy, whatever your
clearance. It has an ending of its own, the true ascendancy above, which replaces the earlier "no
dedicated hive mind ending." That ending is told on the radio, not in a cutscene.

## The world

- **A day lasts about 20 minutes,** start to finish. That drives solar and the
  temperature swings.
- **Infinite desert** with simple procedural terrain. Solo, first-person 3D, Godot 4.7.
- **Only what's around the player exists.** There can be exceptions, like a farm left
  running on purpose, but never as the rule. A solo player who abuses that only hurts
  their own frame rate. Ride too far from your camp and it's forgotten, but the game
  always warns you clearly first.
- **Stateless.** The dunes are featureless and shift out of sight, so nothing beyond
  render distance is stored. Turn back far enough and the land has changed.
- **It's a moon, not a plane.** Your position is tracked as latitude and longitude, so
  walking far enough brings you back round and the poles are real places. The ground
  near you is still flat.
- **Two halves of Zan** ([the Tu spec](tu-and-day-2026-10-17.md), 2026-10-17). Zan is
  tidally locked to Tu. On the near side, the god's side, the giant hangs fixed in the sky
  as a landmark, lights the nights and eclipses the sun once a day. The far side has black
  nights, the stars and no landmark. Local time follows longitude ([the
  moon](the-moon.md#day-length)).
- **Latitude is the second difficulty dial.** Toward the poles, storms weaken but the
  temperature swings get wider: hotter days, colder nights. Difficulty changes kind
  rather than amount. The equator is stormy and mild, while the poles are clear and
  extreme, so the big views are more common there and you pay for them in heat and
  cold. It also gives two play styles: the equator is choppy and rich in salvage, while
  the poles have less loot but more stability, which suits building big and outpacing
  the storms.
- **The sky draws the map** (Agreed, session 4, part 2; loose, not designed). Zan is tidally
  locked to Tu, so where you stand under the giant is a third dial beside wind and latitude:
  under Tu (hottest, the longest eclipses, the richest ruins), the Rim (mild, farmland, Tu
  half-risen on the horizon) or the far side (cold, black nights, where the water ends up). The
  game has only latitude today. [The lore research](lore-research.md#tu-the-tidal-lock-and-the-water-agreed-session-4-part-2)
  has the regions.
- **World coordinates are always tracked**, so distance from spawn is known even
  though the land isn't kept. A fixed underlying topography (the large shapes the dunes
  sit on) may come later.
- **No AI enemies**, so no creature rigging.

## Setting (working sketch, not canon)

A colonized desert moon in the Xandaris universe, Kenshi in spirit. A high-tech
spacefaring society built a transit hub there, and then a war cut the lane and orphaned
it. It became a smuggler moon, until a volcanic paroxysm cut every outside link and took
most of the people who understood the machines. The First Kingdoms, the Dark Age and the
Second Age rebuilt in the ashes, medieval in shape, and rose and fell in turn, until nomads were
all that was left, leaving an apocalypse world. `{YEARS_SINCE_FALL}` after the collapse, a time
not yet set ([placeholders](lore-research.md#placeholders)), the moon has reverted to
near-uninhabitable: ruins, dunes, one nomad city that still moves. The region is starting to
heal, though, and Zan is being rediscovered by surveyors, salvagers and homesteaders (the
origins below).
The air is thin and fading, the days scorch, the nights freeze, and water goes through
all three phases every day. The physics is in [the moon](the-moon.md), and the history
is in the lore sessions ([part 1](lore-session-2026-10-14.md), [part
2](lore-session-2026-10-14-part-2.md), [session 3](lore-session-2026-10-16.md), [session
4](session-notes-2026-10-17.md), [session 4, part 2](lore-session-2026-10-17-part-2.md), [the
endings session](endings-and-radio-2026-10-17.md) and [session 4, part
3](lore-session-2026-10-17-part-3.md)) and [the lore research](lore-research.md).

You're a **scavenger and a survivor, in a suit**, because nobody survives here without
one. The suit is the one gift this world gives you. Why you're out here gets revealed
over the course of the game, never up front. First and foremost, you're out here to
survive.

The strangeness at its heart is that **history runs backwards in the ground.** The
oldest, rarest ruins hold the most advanced technology, because they come from the
original colonists. Everything built after them is cruder: corporate tech lies deepest,
skimmer-era salvage in the middle and the forged goods of the First Kingdoms to the Second Age
near the surface.

**People are only ever hinted at.** A hatch open in the distance, just out of reach. A
ruin with something recently used left behind. Maybe a voice on the radio. There are no
NPCs, and the game never answers the question. (One exception, from session 4, part 2: the
nomad city, shown only in silhouette, never faces or words. See the endings below.) The game
also has no exposition: everything reaches you through marks, carvings, ruin layering,
terminals, radio and the sky.

Lore gets worked out loosely alongside the systems so that it stays consistent from
the start.

## How we build it

- **Skeleton first.** Every system exists in a rough form (grey boxes, placeholder
  sounds), all wired into one complete loop, before any single system gets polished.
  Then muscle, then looks. Sand Game and Delve both died from stacking finished
  features on a weak frame.
- **A PRD before code.** Each system gets a PRD in `docs/prd/` describing its skeleton
  version and its full version. It's approved before anything is built.
- **Headless probes prove it works.** Every system ships with automated checks that run
  the game without a window and assert on what happened. In Delve they caught almost
  every bug, and almost none of those bugs were visible by reading the code.
- **The ground is one function.** A single height function is the truth for the
  terrain mesh, its collision and object placement. Collision is built once per chunk
  and is never rebuilt under the player. World state lives apart from the chunks.
  (These rules come from Sand Game's terrain failure.)
- **Sand Game is the reference** (the [`archive`](https://github.com/hunterjsb/desert/tree/archive)
  branch) for feel, and the source of its sounds, models and shaders. Its code isn't
  reused.

## PRDs

1. [World & terrain](prd/world-and-terrain.md)
2. [Wind & storms](prd/wind-and-storms.md)
3. [Rope & tethering](prd/rope-and-tethering.md)
4. [Bubble shield & the travelling camp](prd/bubble-shield-and-camp.md)
5. [Devices & mods](prd/devices-and-mods.md)
6. [Power](prd/power.md)
7. [Survival](prd/survival.md)
8. [Farming](prd/farming.md)
9. [Movement](prd/movement.md)
10. [Salvage & ruins](prd/salvage-and-ruins.md)
11. [Radio, sound & atmosphere](prd/radio-sound-and-atmosphere.md)
12. [Menus & UI](prd/menus-and-ui.md)
13. [Profile & saves](prd/profile-and-saves.md)

The order we build them in is the [skeleton plan](skeleton-plan.md).

## Open questions

- Why is the scavenger out here? The game reveals it over time, and we don't need the
  answer yet. *Narrowed by session 4, part 2:* each origin has its own reason (see [Player
  origins and kits](#player-origins-and-kits)), and the default is a Tilg & Standard
  contractor. What the game reveals beyond that is still its own.
- If a good camp reaches steady state, what ends a run? Being endless, cozy and
  permadeath pull against each other. A long-horizon backdrop for any answer: the moon
  itself has an end state, a calm, stable desert once its orbit recircularises. *Narrowed by
  session 4, part 2:* optional endings exist for players who want one ([Landmarks and
  endings](#landmarks-and-endings)); a run still never has to end.
- **A standard shield at the start, against "the first deep find reads as an upgrade."** Here:
  a start with a weak shield, "clearly worse than anything found deep, so the first deep find
  reads as an upgrade." The notes (2026-10-17) put "a normal shield" on "the nomad and oyster
  starts," and session 4, part 2 puts a "standard shield" on the default Surveyor and a "solid
  shield" on the Homesteader. A normal shield is read as the base shield found deep, so those
  starts would begin with what other runs find later. Not said: whether the standard shield is
  the base shield or a step between, and what the first deep find is then. (The question "do
  starts differ by playstyle" is answered yes, by origin.) Detail in [the bubble shield
  PRD](prd/bubble-shield-and-camp.md#open-questions).
- **How do the extremes sit with "your home goes with you"?** Pillar 2: "There's no base to
  return to. The shield, the planters and the power all travel with you," and "The camp moves
  at walking pace, and storms are weathered, not outrun." The notes: the oyster is "fully
  stationary," and the hover punk is "board only" and will "outrun storms." The notes call the
  extremes supported, "balanced around the first," so these can read as edges of the hybrid.
  The vision's lines are about the camp, and the hover punk has none. Not said: whether the
  pillars should name the hybrid, or the extremes get a line of their own.
- **Era gear against "history runs backwards".** Setting: "The oldest, rarest ruins hold the
  most advanced technology... Everything built after them is cruder." The notes: "Era gear has
  trade-offs, not a ladder." Quoted in full in [Salvage &
  ruins](prd/salvage-and-ruins.md#open-questions).
- **Session 4, part 2's clashes with this page.** Landmarks against "Only what's around the
  player exists" and "Stateless"; optional endings against "Endless"; the nomad city against
  "People are only ever hinted at"; the Replacement start against "practically unreachable"; the
  Surveyor's kit against the built one. The newer session wins, so they are applied above and
  quoted old and new in [the lore research, section
  16](lore-research.md#16-open-after-session-4-part-2), with what they leave open: where each
  origin spawns, how the sky's regions meet latitude, and how a fixed landmark sits on a seeded
  world.
- **The endings session's and session 4, part 3's clashes with this page.** The five-row ending
  table against the ladder; "There is no dedicated hive mind ending" against the true ascendancy;
  "It tows nothing" for the hoverboard against the patrol board's tow; the sand yacht against the
  dune sailboat; and "There's no base to return to" against Sister's basin, a fixed water source.
  The newer session wins, so they are applied above and quoted old and new in [the lore research,
  section 17](lore-research.md#17-open-after-the-endings-session-and-session-4-part-3), with what
  they leave open: how the three axes are implemented and learned without exposition, the exact
  Daventry unlock, the world clock behind the atmosphere ending, whether the Ledger still
  broadcasts, and which loose ideas (wrong answer, the Okafor line, the radio ending) to develop
  or drop.
