<!-- Hunter's spec, 2026-10-18, as given. Its decisions are folded into the PRDs; this is the source. -->

# Desert: Storms, Signals & Sailing Spec

Oct 18, 2026 · @Hunter Boyd

## Overview

This spec fixes boring early-game storms by speeding up clear-weather travel (sailing, a carving board) and giving storms a payoff, and it defines the Walker, the living city and the anomaly as systems the player discovers through radio.

Design pillars that every feature here must respect:

- **Storms are cozy, not micromanagement.** A storm is the stress test of your build. Tanking storms is the stationary/AFK playstyle by design.
- **Clear weather is the active phase.** You avoid, track or exploit storms. Normal pace is hybrid play: a mobile base on mostly sunlight-based crops, moving to stay out of storms.
- **No NPCs, no exposition.** Everything is learned through radio, logs, terminals and physical cues.
- **No one-off exceptions.** New mechanics reuse core systems (storm curve, ropes, Console, devices) rather than special flags.

## Storms and the early game

The problem is that an early player with no instruments is stuck staring at a storm that lasts roughly 20 minutes per day and can run several days. The fix is three layers: faster travel so you can avoid storms, a reason to go out in one, and a way to skip the wait.

### Auto-walk (first)

- Holds your heading while you navigate by compass or other instruments, so a storm still lets you make long-range progress.
- Ships before sleep; it's low risk and helps instrument-equipped players right away.

### Sleep

- Needed despite the no-pause philosophy. Bedrolls, beds in some ruins, maybe the open sand if the camp is stable.
- Options on use: sleep X hours, until a time, or through the storm. Gear like a radio unlocks more options (e.g. wake for a broadcast).
- **Don't fast-forward physics.** Freeze the camp, evaluate battery and shield against the storm curve over the slept hours, and apply the result ("shield held", "a crate broke loose"). This avoids Jolt instability during a time skip.
- Sleep item may share the hoverboard's mount slot on a crate.

### Things to do under the shield

- Tinkering: swapping mods and repairing gear while stationary under the shield.
- Watching for loot blowing in (below).
- The radio as the cozy companion.

### Storms expose and rebury ruins

- Large shifting dunes expose ancient structures and the best loot mid-storm. Active players can take the risk of going out to find them.
- Storms can rebury what they exposed, so a ruin seen mid-storm may be gone by morning. This also makes chunk derendering canon: the desert ate it.
- Lower-tier exposed loot is blown downwind, so stationary players still get some delivered (pairs with the collector).

### Finding exposed ruins in low visibility

- Early cue: a glint of light through the dust (and optionally a metallic clang on the wind).
- Later cues: particle sensor or ground radar pins the site on the Console.

## The anomaly

The anomaly is a rare storm type whose real intensity spikes far past what every instrument, and the Walker, forecasts. It's the one storm the Walker misjudged, which nearly wiped out the nomads.

**Implementation** (fits the current system: a predictable curve sampled ahead for forecasts, wind and particle damage):

- Forecasting keeps sampling the clean visible curve. Every instrument and the Walker read only that.
- A hidden multiplier applies only at damage time.
- Skew it toward particle damage, so a camp built only for wind gets wrecked.

**Tells** (driven off the hidden term, learnable by experienced players):

- Compass drift.
- Odd radio static.
- Shield particle load climbing while the wind reading looks normal.

After the Walker is taught (see quest lines), anomalies appear on your map and the Walker's moon-wide feed flags them.

## Radio

Two stations carry the Walker and nomad story: the Walker's moon-wide survey feed and the living city's short-range coded chatter.

|  | Walker station | Living city station |
| --- | --- | --- |
| Range | Moon-wide, strongest after the Ledger's | Short range, a few km; meant for its own scouts and foragers |
| Content | Dry survey log: bearings, wind readings, terrain notes; planet-wide weather that's hard to interpret but very useful | Coded tones, no voices: e.g. storm coming, tether in; city moving. Sometimes its own encoded coordinates |
| What the player gets | A weather and route feed if decoded; contact log entries from nomads who still pray to it | Free early warning while in range; signal strength as a breadcrumb; coordinates to find the city |
| How you find it | Moon-wide, so findable by scanning | Frequency must be discovered by exploring (e.g. scratched on a radio in the dead city) |

**Codes.** The player learns the living city's tone patterns by correlation, noticing a storm follows a given pattern.

**Coordinates.** Encoded as star positions, since the nomads navigate by stars. Decoding needs observatory charts or the player's own sky knowledge.

**Contact log.** The Walker records every signal it receives as data, indifferent to its flock. A nomad praying to it shows up as a bearing; several from different positions triangulate the living city.

**Implementation.** A station is a node with position, frequency, range and a message generator; signal strength falls off with distance.

## Walker and nomad quest lines

The Walker's quest line ends with the player teaching it the anomaly tells it couldn't pick up on, and that act also settles the nomads.

### Lore baseline

- The Walker is a legged survey robot that exists only to survey storms and understand Zan's weather. It is completely indifferent to its flock.
- For centuries the nomads followed it reliably through storms because it predicted intensity accurately.
- It walked into the anomaly, misjudged it, and nearly wiped them out. Survivors lost faith and now live in the **living city**, another lost city. The Walker still travels with the **dead city**, the old nomad city.
- Some nomads still contact it, pray to it and visit it. Life on Zan is thought extinct; the living city is deep hidden lore.

### Teaching the Walker

1. Survive an anomaly while recording your own sensor logs.
2. Plug your Console into the Walker and upload them.
3. Result: anomalies appear on your map and the Walker's moon-wide feed starts flagging them, a world-changing payoff anyone listening can hear.

### Taking the Walker

- The Walker doesn't care about its chassis being taken, as long as it keeps roaming and surveying. This rewards nomadic play.
- Kept stationary too long, it goes bad. Tells: its feed degrades, its power draw rises, and its logs turn subtly wrong.

### Pilgrimage and aggro

- If you take the Walker before doing the nomad quest line, the nomads may go on pilgrimage and find their god gone.
- They only turn aggressive if you haven't taught the Walker the anomaly tells yet.
- Teaching it afterward sends a signal that calls off the aggro.
- Aggro is not a big deal in play; it mostly affects endings.

## Sailing

Sailing becomes the main way to make hybrid travel fast enough that storms are worth avoiding, progressing from kitesurfing on the board to helming the camp as a land yacht. Storms bring the strongest wind, so the fastest move is running just ahead of a front on its own wind.

### Today

- The sail is a separate rig. You tether to it at your waist and ride the hoverboard behind it, pitching it with the line.
- Rope balance is mostly lines snapping, or you take damage when you're the fulcrum.

### Progression

| Stage | Rig | How you steer |
| --- | --- | --- |
| 1. Kitesurf (early) | Minimal camp: chassis + shield + sail as one unit ahead of you; you on the board behind | Light control line to the sail; carve with the board's dug edge (see Hoverboard) |
| 2. Larger camp | Sail in front, you in the middle, camp dragging close behind; shield around you | A hidden tow line runs sail to camp; you're the helmsman, not the load path |
| 3. Land yacht (found parts) | Helm seat + keel part mounted on the camp | Ride the camp and steer it like a hovercraft |

A third mode stays available: let the camp sail itself downwind while you scout alongside.

### Physics rules

- Never make the player the link between a heavy sail and a heavy camp. Realistically it would fold you in half, and a tiny body under tension from both sides is where Jolt jitters.
- Run a hidden tow line straight from sail to camp; the board's carve applies a steering force on that line.
- Lines snap past their load, and you take damage if you end up as the fulcrum.
- Without lateral grip you can only run downwind. The board's dug edge (stage 1) or the keel (stage 3) is what lets you tack.

## Hoverboard dig and carve

Add a "dig": dropping one edge so the hover field bites into the sand, trading speed for sideways grip with a big sand spray. It's both the skid players want and the keel for kitesurfing.

### Current feel (keep)

Never sinks into sand, gets air, crouch to pump momentum, shift to kick off, S to brake, steers toward camera forward. The ride already carves, skids past its grip, and drifts when crouched into a hard turn.

### Fiction

The hover field pushes against the sand. Lower ride height on one edge and the field bites the surface, turning ground effect into grip.

### Mechanics

- **Dig value, 0 to 1.** Lowers the low edge toward the sand, multiplies grip, adds drag proportional to dig × speed.
- **Input: S becomes the dig.** S while steering digs into the carve; S alone swings the board sideways for a hockey stop. Replaces today's flat brake with a physical one. Crouch keeps pump and drift.
- **Catch an edge.** Dig × speed × slip past a threshold wipes you out: a stumble off the board and a knock.
- **Kite tow.** The dug edge resists the sideways part of the line's pull, which is what lets you tack.

### Feedback (it lives or dies on this)

- **Look:** rooster tail of sand from the dug edge, scaling with depth; board tilts; slight camera roll.
- **Sound:** hover hum drops in pitch under dig load, layered with a gritty hiss that grows as you dig in; a whoosh on release.
- **Feel:** small camera shake (or rumble) when the edge bites; bigger when it catches.

### Code changes (from a read of the repo)

| File | Today | Change |
| --- | --- | --- |
| `game/board/ride.gd` | Bank *raises* the board: `_lowest()` adds clearance for the lean, so it never touches sand. Brake is a flat `move_toward` | Add `dig`; let the low edge come down; multiply `board_grip`; add dig drag; S-driven dig and hockey stop; edge-catch check |
| `game/core/tuning.gd` | Board grip/drift values only | Add `board_dig_grip`, `board_dig_drag`, `board_dig_depth`, edge-catch threshold |
| `game/rope/ropes.gd` → `Ride.tow()` | Tow adds to velocity and swings the nose to the line | Dig resists the lateral component of the tow |
| `game/player/feel.gd` | Sand spray and `SLIDE` hiss fire only in on-foot slide mode; camera leans with bank via `BANK_SHARE` | Drive spray and hiss from dig and slip on the board, emitted from the low edge, thrown outward; add bite/catch shake |
| `game/board/board.gd` | Hum pitch follows speed and battery only | Drop pitch under dig load; release whoosh |
| Player / board | No fall or bail state (only `bottomed` / `landed`) | Wipeout: `set_down()` plus a knock |
| `probes/movement/` | Frame-rate proofs exist | New probe: stopping distance under dig is identical at 30, 60 and 120 Hz |

## Distant phenomena

Gas-pocket dust plumes and far-off volcano plumes are always distant spectacles, never close enough to hurt you; they already have a spec and an agent on them.

- **Audio only, no camera shake.** A gentle rumble whose strength depends on distance.
- **Delay by distance.** The rumble arrives after you see the plume, like thunder after lightning; that delay is the key to selling scale.
- **Low-pass by distance.** Farther booms lose more high end.
- **Navigation landmark.** A big plume marks a vent's direction; wire it into the navigation work.

## Open questions and agent split

### Open questions

- [ ] Exact sleep outcome model: which failures (crate lost, shield down, line snapped) can happen while asleep, and how likely?
- [ ] How much storm-exposed loot and reburial already exists in code?
- [ ] What does the living city's tone code sound like, and how many messages does it have?
- [ ] Anomaly frequency, and how strong the particle skew is.
- [ ] Edge-catch threshold and what the wipeout costs (damage, lost board, stamina).
- [ ] Where helm seat and keel parts are found, and which era they come from.

### Suggested agent split

These are independent enough to run in parallel:

1. **Board dig physics:** `ride.gd`, `tuning.gd`, tow interaction, frame-rate probe.
2. **Board dig feedback:** spray, hiss, hum, camera shake in `feel.gd` and `board.gd`.
3. **Auto-walk.**
4. **Sleep:** frozen-camp outcome evaluation against the storm curve.
5. **Anomaly:** hidden storm term, particle skew, tells.
6. **Radio stations:** station node system, Walker feed, living city codes.
7. **Storm exposure:** dune exposure/reburial, glints, blown loot.
