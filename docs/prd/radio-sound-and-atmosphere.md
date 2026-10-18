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

A device you carry or mount (Devices & mods). It also works carried in the suit, as any
device does: it plays from you, on its own battery, and use on it in the inventory turns
the dial (Survival, 2026-10-17). **Its reach is huge,** with the exact
range still to tune. Better radios and antenna mods hear more clearly. Tune it, and you find:

- **Music, for the vibes.** Sand Game's tracks carry over: "Sandy Andy" by day and
  "Waiting on the Sun" by night. More channels come later.
- **Weather broadcasts.** These are automated. They tell you where storms are heading,
  how strong they are and when they'll arrive, all read from the real storm field (Wind
  & storms). Better equipment hears further ahead and more accurately. The Console's
  instrument table lists this as its radio row ([Wind &
  storms](wind-and-storms.md#instruments-and-the-console-screen-proposed)).
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

**As built (2026-10-17, Stage 11):**
- **A device, as this PRD says,** and an instrument for a top mount (Devices & mods): a
  small set, 2.5 kg, with a battery slot on its back and a port. You carry it, set it down
  or seat it on a top mount the way the shield seats, and it plays from where it is,
  heard at its level within 3 m. It draws 2 W while it's on, from its battery or the pool
  of the crate it sits on, so a base battery runs it for 50 hours and a dark one is silent.
  It's a find on the surface, about one in six of the surface layer's devices, and in
  ruins. It isn't in the starting kit. The "radio" scenario sets one at your feet with a
  charged shield and a storm 300 m off.
- **Use turns the dial:** off, music, weather, beacon and off again, with a burst of static
  between stations. Its dial lights while it's on, and the look-at readout names the
  channel.
- **Music:** "Sandy Andy" while the sun is up and "Waiting on the Sun" while it's down,
  six to six, however dark a storm makes the day. The station plays on whether anyone
  listens, so you tune in mid-song, and it changes over at sunset and sunrise through a
  burst of static.
- **Weather:** three soft tones every few seconds, and one line of words low in the view
  while you're within 5 m of it: a storm coming, from which way, in how long, its
  strongest steady wind and how long it lasts; or, in one, how long it has left. It reads
  the storm field where the radio stands, 20 minutes ahead, every 5 s. That's a forecast
  for staying put: walk into the wind and the storm comes sooner.
- **A beacon:** the find a beacon can promise is the device in a ruin's hall, which every
  ruin holds whatever the weather. The seed leaves a beacon running in about a third of
  the ruins. Tuned to the beacon, the radio takes the nearest within 3 km whose find isn't
  yours already, and keeps it until you tune round again. It pings, quicker as you near,
  and the line gives the bearing as a compass point, like "a signal, north-north-east",
  and whether it's faint, clear or strong, then "right here" within 15 m. With none in
  reach there's only static.
- **Static** comes in with a storm front's outflow, the wind that rises ahead of the wall,
  so it starts before the storm arrives and is full inside it, in a bubble too: it's the
  sand charging up (the lore research), not the storm's sound. At its loudest it's 5 dB
  under the music.
- **The probes:** 1, 2, 4 and 5 are in `probes/radio`. Probe 3 is Bubble shield probe 1,
  which already walks you out through a bubble's shell and back a quarter metre at a time
  and checks the roar is muffled exactly inside it, so it isn't written twice.
- **Carried** (2026-10-17): it goes in with what you carry whole, rides on you out of sight
  and plays from you on its own battery, its line of words showing, and use on it in the
  inventory turns the dial (Survival). Its spoken bearings, a beacon's or where storms come
  from, are by the moon's north, so past a pole they agree with the compass.
- **Not yet:** bumps crackling, distorted tracks in storms, more channels, lore, oracles,
  frequencies as finds and antennas.

### The ghost relay

*Agreed, session 4, part 2 ([lore session](../lore-session-2026-10-17-part-2.md)); loose, and not
built.* A nomad radio relay still broadcasts storm and water reports in Zan-Han-Mon slang on
automatic, a ghost station long after its builders died. The waymarks, caches and camp scars the
player finds belong to the same dead tribes ([the
lore](../lore-research.md#the-decline-nomads-and-the-moving-city-agreed-session-4-part-2)).

Readings, not in the session:
- It fits the radio as built: another automated station beside the weather broadcast. Rule 1
  still holds, so its storm reports would read the real storm field, in the nomads' slang
  (Monward, Hanmen, Zanborn, the tu- prefix) instead of the forecast's plain words.
- Its water reports have nothing to read yet. The world has no water field (Survival: water
  comes from condensers, frost and ruins), so they wait for one, or become a bearing to a find.
- It is a channel to find. "New channels are finds," so its frequency would be scratched on a
  waymark or stored in a device.

The session also lists a loose radio ending, finding "the right frequencies to reach Tilg or the
last town" ([the vision](../vision.md#landmarks-and-endings)). It isn't designed.

### Second-age broadcasts (Agreed and Idea, endings session; not built)

*The endings session ([endings and radio](../endings-and-radio-2026-10-17.md)); loose, and none of
it is built. Each item keeps the session's own label ([the
lore](../lore-research.md#second-age-radio-and-its-priests-agreed-and-idea-endings-session)).*
- **Agreed.** Getting transmissions working is genuinely hard. With no manuals, second-age people
  cobbled together an arcane, mythological understanding of the transmitters: how to run,
  interpret and debug them. **Debugging is ritual, kept word for word.**
- **Agreed.** Radio priest is a role inside each god's cult, not its own order, so broadcasts
  sound like ritualised procedure. **Proposed voices:**
  - **The Ledger:** tallies and cargo codes as psalms.
  - **Mother Cistern:** gentle calls tied to rations and rain.
  - **The Quartermaster:** muster calls, and an authentication challenge nobody can answer.
  - **The Walker:** coordinates and bearings.
  A "prayer" might be an old Tilg maintenance checklist.
- **Agreed.** The Ledger has the strongest signal, being the smartest. Whoever holds Mon controls
  the loudest voice on Zan, another stake in the crusades.
- **Open.** Whether the Ledger is still broadcasting when the player arrives ("in a sense": it
  still counts either way). Whether broadcasts still carry voices or only tones and numbers.
- From the Console doc: second-age broadcasts still air at reliable times and can serve as a sleep
  clock ([Survival](survival.md#sleep-proposed)).

Readings, not in the session:
- **They are more stations like the weather one.** Automated, on a schedule, read off the radio's
  dial as the ghost relay is. A found channel, by "new channels are finds," or one every radio
  hears, is not said.
- **The Ledger loudest** reads as reach and level: the farthest a station is heard and the least
  static under it. The radio's reach is "huge, with the exact range still to tune," so the Ledger
  is the standard the others are tuned below. How loud is not said.
- **A ritual that keeps word for word keeps its time.** That is why the broadcasts "air at
  reliable times," and why the sleep proposal can use them as clocks. It is a reading.
- **Rule 1 still holds if the text is real.** Broadcasts read the real systems. A checklist, a
  cargo tally and the unfunded forecast Mother Cistern's order rehearses are real documents, not
  invented lines. The Quartermaster's challenge and the Walker's bearings are the awkward two
  (open questions).

### Offstage states on the air (Agreed, session 4, part 3; not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)); loose, and none of it is
built.* The session's hard rule is no NPCs, no dialogue and no exposition, and "galaxy lore stays
offstage until the endings." The war, Varran and Daventry appear in normal play only as faint
radio ([the lore](../lore-research.md#the-wars-end-the-wall-and-the-states-of-the-players-time-agreed-session-4-part-3)).
- **Varran** is heard only from the orbital station: above the storms the antenna hears Varran
  broadcasts, the pathfinder's second step. The Varran settler's own radio is "tuned to home
  frequencies it can't hear from the surface."
- **Daventry** is the one with a seed on the surface: "hearing a Daventry broadcast hints they can
  hear you." Its loudness value rises with dead-lane transmissions
  ([Profile & saves](profile-and-saves.md#ending-flags-proposed)).
- **Faint** is read as low in the mix and rare, in the radio's own terms (static, level, a channel
  to find). Nothing else of the war reaches a radio.

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
- **Softer suit.** What you carry goes in and out as a pouch does, and the inventory opens and
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
  the suit -38 and the menus -40 to -49. The radio is in the world, not the weather, so
  a bubble never muffles it: its music is -28 from 3 m and its static -33 at most. Small
  world sounds are heard at their level from 2 m and fade past it.
- **One table.** Every sound's file is named once, in `game/core/sounds.gd`, and a
  probe checks that each one the game names loads and that the buses exist.
- **Not yet:** a turbine's whir by its speed, and clanks when things knock together.

## Atmosphere

- **Clear skies:** big, lonely views, heat shimmer at the horizon, and quiet apart from
  the wind.
- **Inside a storm:** the world outside the bubble is dark and roaring, the camp is lit
  warm inside it, and the radio crackles.
- **The day:** a 20-minute cycle of scorching noon, long shadows, a freezing night under
  the stars, and frost glittering at dawn (see the water rhythm in Survival). On the near
  side Tu hangs over it all, and once a day it eclipses the sun ([the moon](../the-moon.md#day-length)).
  The day and night music follow the sun where you are, so they change at your local
  sunrise and sunset, and the eclipse's dark is still the day.

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
- **Lore channels, the squatting oracles and signal decoding, and the maybe-voice.** The ghost
  relay (above) is one more, and so are the second-age broadcasts and the faint offstage states
  (both above).
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
  *The skeleton sounds a station's tones and puts one line of words low in the view, as
  a stand-in.*
- **Exactly how far does a radio reach,** and how much does an antenna add? *First
  number: a beacon is heard from 3 km.*

The Console and sleep sessions (2026-10-17) add three. Each is quoted on both sides and left
standing.

- **Do religious broadcasts have a voice?** Open in the session: whether they "still have a
  voice or are just tones and numbers." Here: "Maybe a voice" is never confirmed, voice acting is out of scope, and the
  skeleton sounds a station's tones with one line of words. The ghost relay is automatic too. The
  lore: the AI gods "speak only through terminals," and it asks whether they ever broadcast
  ([section 16](../lore-research.md#16-open-after-session-4-part-2), item 8). Not said which a
  second-age broadcast is. The skeleton's tones and a line already read as "tones and numbers."
  A voice would be the maybe-voice, which the game never confirms.
- **When the broadcasts air.** The session: "second-era religious broadcasts still air at
  reliable times," so they can serve as clocks ([Survival](survival.md#sleep-proposed)). Here:
  rule 1, broadcasts read the real systems, and the music changes at six and six. The lore's
  daily rite is the noon eclipse, "predicted to the second," and the game has no eclipse and
  only latitude, where the eclipse belongs under Tu. Not said: whether the schedule is fixed
  times of day or follows the rite, what airs, and whether every radio hears it or it is a found
  channel ("New channels are finds").
- **How the radio's reading reaches the Console's screen.** Here: the weather line shows low in
  the view within 5 m of a radio, a "stand-in" the skeleton puts there. The session: the radio is a row in the
  instrument table, the screen shows every stat, and audio "comes from a radio on a top mount."
  Not said whether a radio seated on the Console's top slot feeds the screen by being seated or
  needs a computer-mod port, or whether the screen replaces the line as how a broadcast is
  delivered (the question above).

The endings session and session 4, part 3 (2026-10-17) add four. Each is quoted on both sides and
left standing.

- **The gods on the air against "no link."** Here: the lore's AI gods "speak only through
  terminals" and "have no link to each other any more," and part 2's Launch ending needed
  "bridging Mon and Han across open desert." The endings session: "Radio priest is a role inside each god's
  cult," and "The Ledger has the strongest signal." Not said why a god heard across the desert
  can't reach the others, or what the bridge adds if it is already on the air. *Narrowed by session 4,
  part 5: gods "rarely reach each other," and the channels left are a repaired Starcom, the Walker's
  route, rare storm radio windows that catch "fragments of gods arguing" (back burner), and the player
  carrying a dispatch. Part 5 also amends "speak only through terminals": machines may talk through
  terminals, and whether a god is ever heard as a voice is still this PRD's open question
  ([the lore](../lore-research.md#dispatches-how-gods-talk-agreed-session-4-part-5)).*
- **Ritual text against rule 1.** Here: "Broadcasts read the real systems" and "never makes things
  up." The session's proposed voices include Mother Cistern's calls "tied to rations and rain"
  when it has never rained, the Quartermaster's "authentication challenge nobody can answer," and
  the Ledger's tallies as psalms. A prayer "might be an old Tilg maintenance checklist," which is a
  real text. Not said whether the rest are read from real documents or are invented ritual.
- **The Walker's bearings against "never early."** The session: the Walker's voice is
  "coordinates and bearings," and "finding it must never happen early." Here: a beacon already
  gives a bearing to a find, and a find is guaranteed (rule 2). Not said how a bearing to the
  Walker is kept from leading to it early.
- **Voices and the Ledger.** Open in both sessions: "Whether the Ledger is still broadcasting when
  the player arrives" and whether broadcasts carry "voices or only tones and numbers." Here, voice
  acting is out of scope and the skeleton sounds tones with one line of words.

Session 4, part 4 (2026-10-17) adds one, quoted on both sides. The newest session wins in the living
docs, so the radio follows it as direction.

- **A plant the radio hears, and a radio that carries better in some storms.** Here: the radio reads
  the real systems (rule 1), "static comes in with a storm front's outflow" and is "full inside" a
  storm, and "reception crackles and distorts as storms build." The session: quietbloom grows
  toward radio sources and "its growth shifts in response to radio signals, as if listening," so
  "with a console nearby the radio picks up faint patterns from it" ([Farming](farming.md#each-crop-ancestor-engineering-drift-and-hooks-agreed)),
  and "the radio carries better in some storms," with "radio windows" on its back burner
  ([Wind & storms](wind-and-storms.md#storm-only-mechanics-back-burner)). Read as a plant's pattern
  being one more real system to read, which the session never explains. Not said what a pattern
  sounds like, whether it needs the Console, or which storms carry better.
