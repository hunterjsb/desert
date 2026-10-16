# PRD: Radio, sound & atmosphere

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

This is where the cozy lives. The radio is your company, one of your instruments, and a
window on the moon's past. Sound tells you about the world before you see it: a storm
building, a rope taking load, a shield running low. Atmosphere is the feel of the two
moods. Hunter has a vision for the look and feel that gets built in as we go, so this
PRD sets the systems and stays loose on the art.

**In the world.** The radio hears what survived: StarCom stations, beacons left running, and
local models that drifted. The far end of the lane, if it is ever heard at all, is one very
rare, coherent, unanswering frequency, unlike the drifting oracles, and its purpose is never
stated or confirmed in-game (a standing rule from the lore session). See [the lore
research](../lore-research.md).

## The radio

A device you carry or mount (Devices & mods). **Its reach is huge,** with the exact
range still to tune. Better radios and antenna mods hear more clearly. Tune it, and you find:

- **Music, for the vibes.** Sand Game's tracks carry over: "Sandy Andy" by day and
  "Waiting on the Sun" by night. More channels come later.
- **Weather broadcasts.** These are automated. They tell you where storms are heading,
  how strong they are and when they'll arrive, all read from the real storm field (Wind
  & storms). Better equipment hears further ahead and more accurately.
- **Loot beacons.** Automated signals that give a bearing to something worth finding,
  like "a signal, north-north-east."
- **Lore.** Garbled fragments that hint and never state.
- **Squatting oracles.** Degraded local models that survived, such as a weather
  forecaster or an agricultural system, have taken over dead StarCom stations and
  broadcast strange, fragmentary material. Taken as scripture it's noise. Decoded, it's
  real information, like planting timing or storm precursors, so **decoding the signal is
  a skill.** Rule 1 still holds: what decodes is true to the real systems. See
  [the lore session](../lore-session-2026-10-14.md).
- **Maybe a voice.** One of the hints that someone might still be out there (Salvage &
  ruins). It's never confirmed.

**New channels are finds.** You tune into a frequency you've found scratched on
something or stored in a device.

**Storms get into the signal.** Reception crackles and distorts as storms build, even
inside the bubble. Sand Game already had a distorted cut of "Sandy Andy" for this.
Crackly music while a storm roars outside is the cozy moment.

**It's a physical object with charm.** Switch it on and it gives a burst of static. Bump
it and it crackles.

## Sound

Everything that matters can be heard, so you can read the world by ear:

- **The storm:** a roar that rises before the wall arrives, and is muffled inside the
  shield.
- **The wind:** always present, with its strength audible, and humming in taut ropes.
- **Rope:** a creak that rises with load, and the crack of a snap.
- **The shield:** boot, hum and shutdown, and a hum that sags when power runs low.
- **You:** footsteps in sand, sliding down slip faces, the board's hover hum.
- **Parts:** the clunk of a snap, and clanks when things knock together.

**Kept from Sand Game:**
- the radio tracks and the "this isn't a beach, this is a desert!" clip
- the storm and desert-wind recordings
- the shield's boot, sustain and power-down sounds
- the rope creak, the metal clanks, the static and radio interference
- the sand footsteps and slide, and the planter's hover hum

**As built (2026-10-16, the sound pass pulled forward from Stage 11):**
- **Soft hands.** Fitting a part or a mod is a soft seat with a small click: a Sand
  Game clank with its ring cut off. Taking one out is its lighter match, and a line's
  end tied on creaks instead. Taking something off the sand is a sift, and what you put
  down or throw lands with a soft crunch where it lands; a throw whooshes.
- **Softer suit.** The slots are a pouch, in and out, and the inventory opens and
  closes with a cloth rustle. These are the quietest things in the world.
- **New:** a stake driven in, water poured into a planter, a crop picked, the
  harvester's food landing on you, the condenser's drip (quicker the more it makes),
  soft bell chimes for the camp-range warnings, the board's ride (the planter's hover,
  pitched by speed), getting on and off it, and a tick in its last minute of battery
  that quickens as it runs out. The menus click very quietly as you move and confirm,
  and on back.
- **The mix.** Buses: World (and Weather inside it, whose low-pass is the bubble's
  muffle) and UI, under a limiter on Master; the options' volume is Master's. The main
  menu mutes World only, so its desert's storm is silent and its words are heard.
  Every file is levelled to how loud it's heard, with the table in
  `assets/audio/CREDITS.md`: the storm roars at -20 LUFS in the open and -32 inside a
  running bubble, the wind reaches -30 at a gale, a walking step is -36, fitting -30,
  the suit -38 and the menus -40 to -49. Small world sounds are heard at their level
  from 2 m and fade past it.
- **One table.** Every sound's file is named once, in `game/core/sounds.gd`, and a
  probe checks that each one the game names loads and that the buses exist.
- **Not yet:** a turbine's whir by its speed, clanks when things knock together, and
  the radio itself (Stage 11).

## Atmosphere

- **Clear skies:** big, lonely views, heat shimmer at the horizon, and quiet apart from
  the wind.
- **Inside a storm:** the world outside the bubble is dark and roaring, the camp is lit
  warm inside it, and the radio crackles.
- **The day:** a 20-minute cycle of scorching noon, long shadows, a freezing night under
  the stars, and frost glittering at dawn (see the water rhythm in Survival).

## Rules

1. **Broadcasts read the real systems.** Weather forecasts sample the storm field, and
   loot beacons point at finds the world will actually generate. The radio may crackle,
   but it never makes things up.
2. **A beacon's target is guaranteed.** It's decided from the seed when you tune in, and
   the chunk it sits in is certain to contain it when it loads, whatever the weather
   there.
3. **Sound reads the felt weather.** Storm and wind sounds muffle inside a shield by the
   same shelter test everything else uses.
4. **The important things are audible:** rope load, shield power, a storm on its way.

## Skeleton version

- A radio with three channels: music (the two tracks, by day and by night), weather, and
  a loot beacon. Weather and beacon readouts can be crude.
- Static that rises with the storm.
- Storm roar muffled inside the shield, rope creak, shield sounds and footsteps.
- The probes below, all passing.

## Full version

- **More music channels,** with more tracks from Hunter.
- **Lore channels, the squatting oracles and signal decoding, and the maybe-voice.**
- **Frequencies as finds,** and antenna mods.
- **Distorted tracks in storms.**
- **The storm's approach staged in sound,** to match the wall.
- **The look of both moods,** shaped by Hunter's vision as we go.

## Probes

1. **Forecasts are honest.** A weather broadcast's prediction matches what the storm
   field then does.
2. **Beacons deliver.** Follow a beacon's bearing, and the find is there when its chunk
   loads.
3. **Muffling agrees with shelter.** At every point, whether storm audio is muffled
   matches the shelter test.
4. **Static follows the storm.** Reception noise rises with storm intensity.
5. **Day and night music.** The tracks switch at the right times.

## Out of scope

- Voice acting for characters. There are no NPCs.

## Open questions

- **How are broadcasts delivered?** An automated voice, text on the radio, or tones?
- **Exactly how far does a radio reach,** and how much does an antenna add?
