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
  storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)).
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
- **A device, as this PRD says** (Devices & mods): a small set, 2.5 kg, with a battery slot
  on its back and a port, its own since it works away from any deck. You carry it, set it down
  or stick it on a deck the way the shield sticks, and it plays from where it is, heard at its
  level within 3 m. It draws 2 W while it's on, from its battery or the pool of the deck it's
  stuck on, so a base battery runs it for 50 hours and a dark one is silent. Anywhere on a
  Console's deck it's the Console's voice. It's a find on the surface, one in seven of the
  surface layer's devices, and in ruins. It isn't in the starting kit. The "radio" scenario sets one at your feet with a
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
  under the music. An anomaly near brings a crackle of its own under it, short pitched-up
  bursts as deep as its hidden term, which no forecast speaks of ([Wind &
  storms](wind-and-storms.md#the-anomaly-as-built-2026-10-18)).
- **The probes:** 1, 2, 4 and 5 are in `probes/radio`. Probe 3 is Bubble shield probe 1,
  which already walks you out through a bubble's shell and back a quarter metre at a time
  and checks the roar is muffled exactly inside it, so it isn't written twice.
- **Carried** (2026-10-17): it goes in with what you carry whole, rides on you out of sight
  and plays from you on its own battery, its line of words showing, and use on it in the
  inventory turns the dial (Survival). Its spoken bearings, a beacon's or where storms come
  from, are by the moon's north, so past a pole they agree with the compass.
- **Not yet:** bumps crackling, distorted tracks in storms, more channels, lore, oracles,
  frequencies as finds and antennas.

### The dial and the gods on the air (Hunter, 2026-10-18; built)

*Hunter's direction, 2026-10-18: "Each god [has] its own dynamic direction tracked relative to the
player's position. A radio may tune its frequency from 0 to 2000 kHz. Assign each god a frequency
range, and world position. Some are so far away you may reduce it to an abstract direction. Weather
interference between the radio and the god will cause distortion, warping, and cutting of the
transmission. Transmissions will vary. The difference between noise and useful information is if
the player knows when to listen." And: "use the weather god for the weather station." Use the
music, weather and beacon "but don't explicitly name each channel for what it is."*

This replaces "use turns the dial: off, music, weather, beacon" above, and it answers the open
question of whether the gods broadcast: they do. That goes past the lore's "speak only through
terminals" by Hunter's call. The squatting oracles above are now the gods.

- **The dial runs 0–2000 kHz.** Reel in and pay out tune it while you look at a radio, or at a
  console with one in its system: 5 kHz a notch, or 1 kHz with the fine-tune actions. **What reel in
  and pay out work** (2026-10-18, one rule with the reel): the line in your hand first; else the
  radio you look at, which they tune; else the line at your waist you look along, which they reel
  ([Rope & tethering](rope-and-tethering.md)); else a radio you hold, which they tune. The fine-tune
  and volume actions work the same radio. Bring near and push out always move what you hold, never
  a dial. Use sweeps up to the next carrier, and past the last one it goes off. **A volume knob** (Hunter, 2026-10-18:
  "give the radio also an adjustable volume knob"): the volume actions, a tenth a notch from full to
  silent. Each notch is the same 6 dB step, as ears hear loudness (Hunter: "10% should be barely audible,
  and 100% should be louder than most other sounds in the game"): full is +15 dB, a tenth -39 dB, 54 dB
  between (`radio_volume_range_db`, 60 from full to none). It turns down everything the radio plays (music, tones and hiss), which plays on at any
  setting, and a save keeps it. At full it's loud
  (Hunter: "100% volume needs to be much much louder in game"): 15 dB over the levels its tracks are
  made at (`radio_loudness_db`), past the +3 dB cap other things in the world have, and heard at that
  level out to 15 m (`radio_heard_m`), fading 6 dB each time that distance doubles (Hunter: "Sound
  falls off too quickly"); it was 6 m, and 3 m before that, so at 30 m it's 8 dB louder than at 6 m.
  Everything it plays goes through its own bus with a high-pass filter at 400 Hz (`radio_highpass_hz`;
  Hunter: "The radio also needs a hi pass filter on it"), the thin sound of a small speaker, on into the
  world's sound, so the menu still mutes it. The static sinks under anything you can hear, a song, a god
  or the beacon, by up to 18 dB as cleanly as it comes through (`radio_static_duck_db`; Hunter: "Quiet
  down the ambient radio static a lot unless there is nothing currently playing"), and it's all there is
  between stations, in a silence, or when a storm blocks the way (radio probe 18). Nothing names a carrier:
  the line low in the view reads only `262 kHz · …`, and the look-at line has the frequency as its one
  state, "Radio · 262 kHz", or "Radio · off". On a Console's power page its row is the dial's own
  controls: off and on, a sweep to the next carrier as use does, and the volume down and up
  ([Devices & mods](devices-and-mods.md)).
- **Carriers:** the music at 1020 kHz and the beacon at 1930, both behaving as above, and the seven
  gods. The weather station is **the Walker** (Stations, below): its band is where the forecast is.
- **Each god's carrier** lies inside its band and moves to a fresh place each moon day, from the seed,
  so it has to be found. A signal comes in within about 3 kHz either side (`dial_width_khz`).

| God | Band, kHz | Where it stands | Worth hearing | What it says then |
|---|---|---|---|---|
| The Quartermaster | 140–175 | The black site | Through the eclipse ("blackout drill") | Bearing and range to the nearest cache, dugout, checkpoint or bunker history laid near you |
| The Walker | 230–290 | Walks the Rim, the ring road's line, 1.5 m/s, from a seeded start | Always: the forecast where the radio is. At dusk, and when a storm starts or ends at its feet, the long report too | The weather station's reading; then 40 minutes ahead, and whether there's a storm at the Walker |
| Mother Cistern | 410–450 | Sister | Dawn, 05:00–07:00 local | Frost or dew tonight with the 03:00 temperature, and the nearest cistern or stepwell |
| The Almanac | 600–660 | Frontier Ag's farm domes nearest Halfrise, on the Rim | Sunrise and sunset | The day's range, and which crops would hold through it out in the open, and which to hold back |
| The Ledger | 880–940 | Port Morgan | About midnight ("berth inventory") | Bearings and ranges to Halloran, the Rim depot and Starcom. It sends strongest |
| The Stoker | 1180–1240 | Halloran | The hot hours, 13:00–16:00 local | A countdown to the next eclipse, and the peak temperature in the next 5 minutes |
| The Eye | 1720–1790 | The observatory, at the anti-Tu point | Night where the radio is | Your latitude and longitude, and the local time |

  **Clear skies** (Hunter, 2026-10-18: a "'hold' transmission on the weather channel that plays during
  clear weather with nothing to report," "a feel good you have nothing to worry about sound that only
  plays under conditions when that is true"): while the station's reading has no storm on you and none
  due within `radio_calm_minutes`, 5, the Walker holds, playing Hunter's "Clear Skies"
  (`radio_clear_skies.ogg`) instead of report tones, its line still giving the forecast, a farther storm
  included. When a reading has a storm within those 5 minutes, it breaks off through a burst of static
  for the report. Hunter, on the first rule of none in the station's 20 minutes: "no storm for 20 minutes
  is basically impossible." Measured over six hours on three seeds, the sky where you stand is clear
  about a quarter of the time, clear for 5 minutes ahead 12–13% (about half of all clear time), and for
  20 minutes 0–1%. The **"clear_skies"** dev scenario stands you on a clear day, the next storm 9 to 14
  minutes off, with a radio on the weather station. **The
  Stoker's song** (Hunter: "use that segment on the Stoker mind's frequency"): its frequency carries
  45 s of Hunter's `modsynthpatch.wav`, from 11:15 to 12:00 (`radio_stoker.ogg`), in place of tones,
  its pitch sliding with the storm's warp, and as loud at its peaks as Clear Skies (Hunter: "stoker track
  too quiet"). Both come through like any signal: down by the root of how clean it is,
  silent while it's cut, and never started over by a dropout.
  **The relay** (Hunter, 2026-10-18: "Tie the existing music channel to an orbiting satellite, loosely
  simulate this satellite's position in orbit and give it interference just like the other freqs based on
  it's simulated position," and "Make the satellite visible in the night sky if it's overhead"): the
  music comes down from an old colonial relay satellite still playing the port's station
  (`game/radio/satellite.gd`). It orbits at 3 moon radii (`relay_altitude_radii`), a lap in 6.5 minutes
  (`relay_period_minutes`; Hunter: "The music satellite should move faster than the other stars, to create
  a noticeable parallax effect"), so it crosses the night sky two to four times as fast as the stars,
  backwards round on half the seeds; and not a whole share of a day, or it would cross the same sky at
  the same hour every time, its tilt 25–65° from the seed, while the moon turns under it once a day, so it
  rises and sets and each pass crosses the sky somewhere new. A run begins with it passing over where it
  began. It's over the horizon about 40% of the time (no one satellite can manage half), in short
  passes of a few minutes with a few minutes between. The music fades in over its first 8° (`relay_rise_degrees`). Set, the channel
  is static, the song running on silently until it rises. Its carrier slides up to 1.5 kHz
  (`relay_doppler_khz`): up as it rises, down as it sets. A storm over you garbles, slides and cuts it as
  it does a god; its signal crosses the dust 1.5 km thick (`dust_height_m`), so the lower it is, the
  farther out the storm that reaches it. Its pitch slides with its carrier (Hunter: "ensure the audio on
  the music station can actually be interfered when on the far side of the moon"): a little over a pass,
  with its coming and going, and up to 4% as a storm warps it, as the Stoker's and the Eye's do. A storm
  in its way cuts it off on the far side as anywhere; the **"far_storm"** dev scenario stands you there
  with a radio on the music, the relay 60° up and more, and a storm 1.2 km off coming at you. At night it shows in the sky as a bright moving point (brighter
  than any star) while it's over the horizon and the sun lights it, and goes out in Zan's shadow. The
  **"night"** dev scenario waits for a night with the relay sunlit 10–28° up, and faces you toward it.
  Outside its window each god talks noise in its own voice: roll calls, survey telemetry, the
  terraforming hymn, prices for goods nobody sells, empty manifests, boiler alarms, and from the Eye
  silence. Everything said in a window is read from the real systems.
- **Direction.** Each god's bearing is worked from where the radio stands to where the god is on the
  sphere, every reading, so the Walker's moves as it walks. Within 12 km it's a compass point, within
  40 km a rough one ("somewhere west"), and past that only a way across the moon: toward Tu, away from
  Tu, across the face of Tu left or right, or, near the opposite point, from everywhere.
- **Reach.** At or under 500 kHz a ground wave carries 80 km. Above it, the reach falls as the square of
  the frequency by day, and at night a sky wave comes down past a 15 km skip at 0.6 strength, real AM
  behaviour. So the Eye, high and far, comes in only at night, and the Stoker carries far only after dark.
- **Weather between you and the god.** The storm field is read at 12 points along the way toward the god,
  from 50 m out to 3 km, closest together near you, and it's the **worst** of them that counts, not the mean
  (Hunter, 2026-10-18: "Interference must be highly directionally weighted ... If a storm is very close to
  you on your east, each signal that lies to the east should be completely unreachable"). A storm that bad
  or worse than half (`storm_blocks`) anywhere on the way **cuts the signal off entirely**; less, it lets
  through the less the nearer it is to that. A storm beside you blocks only what lies its way, so which
  signals you lose says which way they lie; deep in a storm you lose them all. The more storm there is, the more of each line turns to noise glyphs (**distortion**), the
  further the carrier slides off where you tuned, up to 6 kHz either way, so you chase it (**warping**,
  with the tones wobbling too), and the more often it drops out, up to 60% of the time
  (**cutting**). A weak signal frays the same way. Below the floor it's only static.
- **Spoken reports** (Hunter: "implement text-to-speech weather broadcast readouts"): with something to
  report, the weather station reads it aloud through the system's text-to-speech (Godot's, the OS voice),
  at once as a report breaks in on Clear Skies and every 30 s after (`radio_speak_every`); never while it
  holds. Units are read in words, and words a storm garbles are lost to "...". You hear the nearest radio
  on the weather station within 30 m (`radio_voice_m`), as loud as its knob, its signal and the distance
  allow; tuned away or left behind, the voice stops. A report already reaching you is read to its end
  through a dropout. The OS voice can't be placed in the world or run through the static: it's heard
  flat, as a voice in your ear, and headless there's none.
- **The Eye's drone** (Hunter: "implement this as a random ambient track that can play from 'the eye'"):
  the Eye's frequency begins a run silent, then now and then plays Hunter's drone (`radio_eye.ogg`, 66 s)
  through once, each silence before it 2 to 8 minutes (`eye_quiet_minutes`), the seed's pick. Between
  drones there's nothing on its frequency, not even tones. Like the Eye itself it comes down by sky wave,
  so it's heard at night; by day it's on, too faint to hear. It runs on its own schedule
  (`Gods.song`), and its pitch slides with a storm's warp.
- **The meltdown** (Hunter: "make the stoker's audio not random. For now just bind it to a command called
  'meltdown'"): the Stoker's furnace song never plays by itself. The dev console's `meltdown` calls it up:
  it plays through once on the Stoker's frequency from that moment, and stops; called up again while it
  plays, it starts over. The rest of the time the Stoker talks and sounds its tones as any god does. (It
  had played through, then fallen silent for 1 to 5 minutes, over and over.)
- **Code:** `game/radio/gods.gd`, `dial.gd`, `interference.gd` and `transmissions.gd`, with `radio.gd`.
  A save keeps whether it's on, the dial and the knob. One from before the dial kept a channel, which
  moves the dial to that carrier once the radio is back in its world, the weather station's to the
  Walker's carrier that day, with the save's version unchanged.
- **Probes:** radio 6 (each god has its bearing), 7 (storms garble the gods), 8 (the dial finds each
  god), 9 (useful only in its window), 10 (the volume knob), 11 (clear skies, and the Stoker's song), 12 (the clear-skies scenario), 13 (the relay carries the music), 14 (spoken reports, and the meltdown), 15 (storms tell you which way), 16 (the Eye's drone), 17 (the relay at night), 18 (static sinks under a signal), 19 (the music goes in a far-side
  storm) and 20 (tuning shares reel in with the reel). Probes 1, 2, 4 and 5 tune by the dial, and so do Survival 12, Profile & saves 13 and
  Devices & mods 28, the power page's row.
- **Not yet:** a god's own voice beyond tones, frequencies as finds, antennas, and the far end's
  signal.

### The dial in your hands (Hunter, 2026-10-18; built)

*Hunter: "the radio dial, we should have you zoom in and turn the physical dial, and make sure we tie
our god stations to their homes."* Tuning brings the radio up close and you turn its dial itself: the
view moves in to the set and the knob turns under your hand, the needle crossing the band. Each god's
station is at its home, its signal and bearing from that landmark wherever you hear it.

- **Up close.** Reel in, pay out, the fine-tune or volume actions, or use's sweep, on the radio they
  work (one you look at, the one on a Console you look at, one standing on a deck, or one in your
  hands) ease the view in over 0.35 s (`dial_close_seconds`) to 0.45 m off its face (`dial_close_m`)
  through a 40° lens (`dial_close_fov`), against the game's 75°, so the face fills most of the view.
  It meets the face square, or as near your own line of sight as 30° off square, its up the set's own
  so the band reads level, swung round the set rather than through it and never nearer the sand than
  12 cm. It's a camera of its own, so your aim stays yours: look off the radio and the view eases back
  out at once, and 3 s (`dial_close_hold`) after the last turn it eases out anyway. The aim dot hides
  while it's in; the look-at line stays. A radio in your hands turns its face up to your eyes as it's
  closed in on. No new actions.
- **The face** (`Dress`, B's paint): across the top a band scale in a gunmetal bezel, lit while it plays,
  a tick every 100 kHz and a long one every 500, numbered 0 to 20 in hundreds as old sets were; a thin
  red needle crossing it, lit too; under it the speaker's slats, the tuning knob and a smaller volume
  knob, each black and ridged with a bone line on its cap. The tuning knob goes once round every
  100 kHz, so a notch turns it 18° clockwise and a fine step 3.6°; the volume knob sweeps three quarters
  round from silent to full. The needle and knobs follow the dial in about 0.05 s, so a sweep spins the
  knob round and you see the needle go.
- **Each god at its home.** Every god's bearing, its distance and the strength and storm it comes in
  through are worked from one point, `Gods.home`: for five gods their landmark's middle in the
  history, where its god's part stands (the Quartermaster's bunker in the black site, Mother Cistern's
  temple in Sister, the Bastion in Port Morgan, the refinery terraces at Halloran, the tower at the
  observatory). The Almanac stood at a point 6–14° along the Rim from Halfrise with nothing there; it
  now stands in Frontier Ag's farm domes nearest Halfrise, the history's own `farm_dome` settlement
  (Halfrise itself on a moon with none, which no seed tried had). **The Walker's home is its route:**
  it has no landmark, and nothing stands where it is yet (its module isn't built); its signal comes
  from where it has walked to round the Rim, the great circle 90° from under Tu that the ring road is
  laid along, 1.5 m/s from a seeded start, so its bearing turns as it goes. On seed 1234 (probe 22):

  | God | Home | From the start | Beside Port Morgan | Beside the farm domes |
  |---|---|---|---|---|
  | The Quartermaster | The black site | 28.1 km, somewhere west | 15.2 km, somewhere east | 33.2 km, somewhere east |
  | The Walker | Where it walks on the Rim | 31.1 km, somewhere south | 47.2 km, across the face of Tu, right | 56.6 km, across the face of Tu, right |
  | Mother Cistern | Sister | 60.2 km, toward Tu | 19.3 km, somewhere west | 3.4 km, south-south-west |
  | The Almanac | The farm domes nearest Halfrise | 58.3 km, toward Tu | 19.6 km, somewhere north-west | 1.2 km, west |
  | The Ledger | Port Morgan | 44.0 km, toward Tu | 1.2 km, west-north-west | 17.3 km, somewhere east |
  | The Stoker | Halloran | 26.6 km, somewhere west | 16.7 km, somewhere east | 34.7 km, somewhere east |
  | The Eye | The observatory | 50.0 km, away from Tu | 56.6 km, away from Tu | 38.7 km, somewhere west |

  The two spots beside a home stand 1.2 km from it on its Tu-ward side. Compass points within 12 km,
  rough ones within 40 km, past that a way across the moon, as above.
- **Code:** `game/player/close_up.gd` (the close view), the needle and knobs in `game/radio/radio.gd`
  and their looks in `game/look/dress.gd`, the Almanac's home in `game/radio/gods.gd`. The look-test is
  `look/dial` (`look/dial/shoot.sh`).
- **Probes:** radio 21 (tuning brings the dial close: in and out, the knob and needle by the notch, held
  and on a Console) and 22 (each god at its home, against where the world lays it).

### Stations: the Walker and the living city (agreed, 2026-10-18 spec)

From Hunter's [storms, signals & sailing spec](../storms-signals-sailing-2026-10-18.md). A station is a node with a place, a
frequency, a range and what it says; its signal falls off with distance.
- **The Walker's survey feed:** moon-wide, the strongest after the Ledger's; a dry log of bearings,
  wind readings and terrain, the planet's weather hard to read but very useful. Found by scanning.
  Its contact log records every signal it hears, indifferent to its flock: a nomad praying to it is
  a bearing, and several from different places triangulate the living city. *Its first form is
  built:* the weather station on the dial (above) is the Walker's feed, in its 230–290 kHz band,
  low enough that its ground wave carries across the whole moon, sending second only to the Ledger,
  and found by sweeping the dial. It gives the forecast where the radio stands, and at dusk or with
  storm news at its feet the long report. Not yet: a survey log's bearings and terrain, and the
  contact log.
- **The living city's chatter:** a few km, for its own scouts; coded tones, no voices ("storm
  coming, tether in", "city moving"), sometimes its own coordinates written as star positions, the
  nomads navigating by the stars. Its frequency is found by exploring (scratched on a radio in the
  dead city), its codes learned by noticing what follows them. Open: how the tones sound and how
  many messages.

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

### Distant phenomena (agreed, 2026-10-18 spec)

Gas-pocket dust plumes and far volcano plumes stay distant spectacles, never close enough to hurt
([spec](../storms-signals-sailing-2026-10-18.md)): a gentle rumble by distance and no camera shake, arriving after you see it as
thunder does after lightning (the delay sells the scale), losing its high end with distance, and
a big plume marking a vent's direction to steer by.

*Built 2026-10-18, on the `plumes` branch* (`Rumbles`, `game/weather/rumbles.gd`, under Weather; the
plumes are [Wind & storms](wind-and-storms.md#plumes)'):
- **A boom at a burst's onset**, a vent's or a gas pocket's blowout, heard within 45 km. It comes as long
  after the burst began as sound takes to come that far: sqrt(γRT/M) for nitrogen, Zan's air (γ 1.4, M
  0.028 kg/mol), at the air's temperature where you stand, so about 353 m/s at 27 °C, 337 at 0 °C and
  372 in a 60 °C afternoon. How thin the air is doesn't change it (it changes how loud a sound can be,
  not how fast it goes). So a burst 10 km off is heard half a minute after its column starts up.
- **Quieter and duller with distance.** -2 dB over its file at a kilometre for a vent's least burst,
  louder by its size, 8 dB less for a pocket's, and 6 dB less each time the distance doubles, as sound
  spreads; and through its own low-pass (the Booms bus) at 3 kHz by a kilometre, falling as distance to
  the 0.9 past it, 300 Hz at 13 km and 100 Hz past 40: air takes a sound's high end first, and thin air
  the more. Bigger bursts are lower, a pocket's blowout sharper.
- **From its way.** The boom is played 20 m off you toward its source, so it's heard from the vent's
  bearing as the column is seen there; no camera shake, sound alone.
- **A live vent's roar near:** within 2.5 km of a live vent, its steady roar, at its file's level 150 m
  off and fading with distance, harder as it vents harder, through its own low-pass (the Vents bus),
  from its way. Both buses run through Weather, so a bubble muffles them as it does the storm.
- **Sounds:** `boom.ogg` and `vent_roar.ogg`, made here with Python and ffmpeg, CC0
  ([credits](../../assets/audio/CREDITS.md)).
- **Probe** (wind & storms 17): from 3 km and from 12 km off the rift's live vent a burst's boom comes
  as long after it began as sound takes to come that far (9.35 and 36.97 s), never before; from 12 km
  it's 9 dB quieter and under half as bright (323 Hz against 1,116); it comes from the vent's way, to
  under 2°; and a jump in time past it plays nothing late.

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
  delivered (the question above). *Settled in part by the chassis (2026-10-18):* the top slots
  are gone, and a radio stuck anywhere on a Console's deck gives it the forecast and its tones.

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
