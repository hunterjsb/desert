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
- **In your ears** (gonkhub, 2026-10-19: "when the radio is inside the player's inventory, play its audio
  directly to the player," and "the volume level in the inventory should match when held very close to the
  player ... that way, there is not a jump in audio when they stow it"): carried, everything it plays,
  its dial's clicks too, sounds from straight ahead of your eyes, as far off as a radio held as near as
  bring near takes it (`Hands.nearest_hold`, 0.5 m or a little more for a bigger thing), so it's as loud
  as one held that close and stowing it changes nothing you hear. It turns with you, and has no panning
  while carried (gonkhub: "ensure camera movement will not affect panning"), so however fast you look round
  it never swings from side to side; it's placed again every frame. Its voices sound
  from its middle, the point your hands hold, carried or not. Probe: radio 24.
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
- **Each god's carrier** lies inside its band and wanders each moon day, from the seed, so it has to be
  found; since 2026-10-20 never more than 5 kHz from where it was the day before (`carrier_drift_khz`;
  gonkhub: "ensure a 'home frequency' cannot shift more than 5khz from where it was last"), turning back off
  the band's edges (`Dial.walk`). The satellites' carriers wander the same way, the ghost's by the hop. A signal comes in within about 3 kHz either side (`dial_width_khz`).

| God | Band, kHz | Where it stands | Worth hearing | What it says then |
|---|---|---|---|---|
| The Quartermaster | 140–175 | The black site | Through the eclipse ("blackout drill") | Bearing and range to the nearest cache, dugout, checkpoint or bunker history laid near you |
| The Walker | 230–290 | Walks the Rim, the ring road's line, 1.5 m/s, from the point on it farthest from where the run began | Always: the forecast where the radio is. At dusk, and when a storm starts or ends at its feet, the long report too | The weather station's reading; then 40 minutes ahead, and whether there's a storm at the Walker |
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
- **Spoken reports** (Hunter's bundled-voice choice retained; the regular reports and advisories
  requested on 2026-10-19 are combined with it). The voice is the same public-domain LJ Speech voice
  on every computer: the existing 165 full phrases plus a bundled bank of 783 words and common
  fragments for dynamic readings. No system TTS or HUD transcript is used. `RadioSpeech` preserves
  exact numbers, composes short fragments and spells an unknown name rather than dropping it.
  - **Regular weather:** at tuning and every 120 s (`radio_report_every`), local time, actual wind,
    temperature and the real outlook where the set stands, with units in words. Clear Skies can
    continue under a report. The Walker's survey/contact log is included when its weaker channel
    is readable; distant log data stays unavailable.
  - **Advisories:** a fast or large sandstorm interrupts the current reading once per event.
    `advisory_fast_ms` is 14.5 m/s, `advisory_long_minutes` 45, and `advisory_look_minutes` 60.
    These follow the measured upper-tenth prevailing wind and storm duration from the earlier
    twelve-seed survey. Forecasts still never invent an anomaly warning.
  - **Gods and beacons:** their transmitted words and actual compass bearing use the same bundled
    reader. A changing transmission waits for the current one to finish; an unchanged one repeats
    at the regular interval. A god's music does not suppress its words. The living city keeps its
    existing coded tones.
  - **From the set:** its own reader follows the radio's middle or its carried position, with its
    volume knob, speaker filter and private interference chain. Interference affects the sound,
    without randomly deleting words before playback. Options' Radio voice stops all speech.
    A Console's local battery announcements use the original full recordings and bypass over-air
    interference. Reparenting preserves an in-progress reading.
  - **Compatibility:** `Radio.report` retains its short recorded-phrase form for existing callers;
    ordinary scheduled reports use the richer readout. See the integration measurements below.
- **The Eye's drone** (Hunter: "implement this as a random ambient track that can play from 'the eye'"):
  the Eye's frequency begins a run silent, then now and then plays Hunter's drone (`radio_eye.ogg`, 66 s)
  through once, each silence before it 2 to 8 minutes (`eye_quiet_minutes`), the seed's pick. **Two
  drones** (gonkhub, 2026-10-18: "put this as a random ambient track for the eye"): each time it plays,
  the seed picks it or gonkhub's tunnel ambience (`radio_eye_tunnel.ogg`, 164 s), levelled to match, and
  it plays through to its own end. Between
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
  storm), 20 (tuning shares reel in with the reel) and 23 (the voice comes from the radio). Probes 1, 2, 4 and 5 tune by the dial, and so do Survival 12, Profile & saves 13 and
  Devices & mods 28, the power page's row.
- **Not yet:** a voice for the other gods beyond tones, frequencies as finds, antennas, and the far end's
  signal.

### The dial in your hands (Hunter, 2026-10-18; built)

*Since 2026-10-19 the close-up comes only with the fine steps* (gonkhub: "Stop the radio from zooming to the
interface when interacting," then "Bring back the pov zoom when using fine-tune shift scrolling"): the
wheel's notches, use's sweep, the next mark and the volume leave the view your own, and shift's fine steps
ease it in as below; with `dial_close_up` on every tuning action does (the dial look-test turns it on to
shoot it). The tuning knob goes once round across the whole dial, 0 to 2000 kHz (gonkhub, 2026-10-20: "make
the visual for the knob turning match the bandwidth, so going from 0-20k is one full knob turn"); it went
round every 100 kHz. And the wheel is quicker (gonkhub: "speed up frequency
scrubbing with scrollwheel"): a notch is 10 kHz (`dial_notch_khz`, was 5), and spun fast, a notch within
0.15 s of the last the same way goes a notch farther than that one did, up to five at once, 50 kHz
(`dial_spin_seconds`, `dial_spin_most`); rested or turned back, a notch is a notch again. Fine steps stay
1 kHz and never speed up. Radio probe 36 checks the spin, and 21 that only a fine step closes in.

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
  it has no landmark; it walks there itself (the Walker's quest, below), and its signal comes from
  where it has walked to round the Rim, the great circle 90° from under Tu that the ring road is laid
  along, 1.5 m/s from the point on it farthest from where the run began, so its bearing turns as it
  goes. On seed 1234 (probe 22, which travels, and so begins the run afresh, at each spot):

  | God | Home | From the start | Beside Port Morgan | Beside the farm domes |
  |---|---|---|---|---|
  | The Quartermaster | The black site | 28.1 km, somewhere west | 15.2 km, somewhere east | 33.2 km, somewhere east |
  | The Walker | Where it walks on the Rim | 62.5 km, toward Tu | 20.0 km, somewhere west | 11.8 km, south |
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

### Sound only, the constellation, skirts and marks (gonkhub, 2026-10-19; built, on the `signatures` branch)

*gonkhub: "Remove all text dialogue from the radio. Audio only." "Let's have many satellites orbiting the
moon, each with different broadcasts on different frequency ranges." "Ensure each broadcast can be
picked up near its home frequency at reduced signal strength ... overlapping signals that each have a
home frequency so the player can focus on what they are trying to listen to, but the whole frequency
range is dynamic." "Most broadcasts should be cosmetic ... Many ambient tracks will be tied to some
environmental factor ... like an LFO." "Each satellite in orbit needs to be visually distinct." "Allow the
player to mark frequencies, and give them a name + color. If the player presses f when holding the radio,
they swap to their next saved frequency."*

- **Sound only.** Nothing the radio says is written in the view any more: the line low in the view is
  gone. The weather station still reads its reports aloud (that's sound), and the look-at line still names
  the dial's frequency, "Radio · 262 kHz", which is the set's own reading rather than anything said.
  What a god would say is still worked out (`Radio.said`, `reception.text`) for the spoken report, the dev
  overlay and the probes, and is never shown.
- **Skirts.** Every broadcast, the gods', the music, the beacon and the satellites', is heard whole on its
  carrier, falling off within `dial_width_khz` (3), and at a share of its strength farther out across a
  skirt: `dial_skirt_share` (0.35) over `dial_skirt_khz` (20) either side (`Dial.heard`). So 10 kHz off a
  carrier you hear about a fifth of it, at 50 kHz nothing. The dial counts the nearest god, music or beacon
  within 30 kHz (`Dial.reach`) as the one it hears, so tuning toward one brings it in faint, then whole.
- **The constellation** (`game/radio/constellation.gd`). Thirteen satellites, the relay among them, each from an
  era, in a band of its own (its carrier a fresh place inside it each moon day), on a route of its own,
  and each its own in the night sky by colour, shape (a point, a cross, a bar, a ring, a pair or a
  diamond) and size; one blinks. A radio hears each while it's over the horizon
  and on the air, through the storm on the way as the relay is, all at once (`SkyVoices`, a radio's child):
  between two near carriers you hear both, the nearer louder. Some bands overlap the gods' and each other's
  on purpose. So what's on the dial keeps changing with the hour and the sky.
- **The irregular ones** (gonkhub, 2026-10-19: "Give the remaining satellites outside the formation highly
  irregular orbits/behaviors"). The relay, the ghost and the cinder, those outside the formation, fly ellipses by
  Kepler's equation (`Satellite.at`), swooping low and fast at perigee and hanging high and slow at apogee,
  and their orbits turn as they go: the plane swings round the pole (`precess`, degrees a lap) and the
  perigee wanders round the ellipse (`apsides`), so every lap takes a new route. That's loose: a real
  moon's pull wouldn't turn an orbit so fast. On their ellipses the Doppler slide follows how fast each
  nears or draws away, so a satellite climbing outward as it rises slides down, not up.
  - **The ghost:** eccentricity 0.75, from 0.75 to over 11 radii up, sweeping 2.9°/s round the moon at
    perigee and 0.23 at apogee; its plane swings 110° a lap and its perigee 80°. It's on the air **in fits**,
    about 30% of the time, in spells of uneven length (three slow waves out of step decide it), not on a
    timetable. Its carrier **hops** round its band every 14 to 27 s, the gaps never even. It **tumbles**
    about every 3 s: its signal swells and fades to a fifth, and in the sky it dims and flashes.
  - **The relay:** eccentricity 0.3, its plane swinging 40° a lap and its perigee 70°, and a slow tumble,
    the music swelling and fading by up to 30% every 20 s and the point glinting. A run still begins with it
    over where it began; it still carries the music at 1020 kHz.
  - **The cinder** (added 2026-10-19), a spent wartime tug: its orbit **decays**, sinking 1.6 radii over five
    laps of 4.4 minutes until a burn throws it back up, over and over (`decay`), on a slight ellipse
    swinging round 160° a lap. Its roar follows how low it is (a new LFO source, `height`, 0 at the lowest
    its orbit takes it and 1 the highest): skimming the air it's bright and high (the low-pass open to
    about 6 kHz), far out a dull rumble (under 600 Hz). It spins, glinting. Its band, 1150–1175 kHz, sits
    under the Stoker's skirt. The ghost's pitch follows its height too, lower far out.
  - **The cinder's burn:** as its decay bottoms out it fires, flaring six times as bright in the night sky for
    four seconds (`Constellation.burning`), and climbs back up.
  - **Babel jams** (added 2026-10-19). The wartime jammer, though in the formation, still does its job: while
    it's up and on the air it sprays static over the dial round its carrier, up to 0.7 of full static on it
    and falling off over 60 kHz either side (`Constellation.jamming`), and whatever else is near it, a god or a
    satellite, comes through that much less clean, buried. Far along the dial there's none of it, and babel
    doesn't bury itself. Its band, 1290–1340 kHz, sits above the Stoker's and the cinder's, so when it's
    overhead those two are hard to hear.
  - **Brighter near.** Every satellite looks as bright as the square of how near it is against its mean
    distance, and a little bigger (`Satellite.nearness`, a quarter to four times): the ghost flares four times
    over at perigee and fades to a third at apogee; a circle looks the same all round.
  - **The crop survey skims low** (gonkhub, 2026-10-19: "an extremely low orbiting object. Low enough that its
    silhouette is partially visible against its own lighting, and it's much larger in the night sky than the
    others ... moving slowly near the horizon then quickly crossing the center of the sky"). Thermal left the
    formation (the sounder, a StarCom ionospheric sounder, took its plane) for an orbit of its own 1.9 km up
    (0.08 radii), a lap in 6.37 minutes, its plane swinging 37° a lap, so its track sweeps over every place in
    time instead of retracing the same lines every hour (a 6-minute lap would have). A run begins with it
    passing over. From below it crawls along near the horizon, about 2°/s, and whips overhead at 17°/s, from
    the geometry alone. That low it's in Zan's shadow nearly all night, so it lights itself: the sky draws a
    new shape, HULK, an H (gonkhub: "make it H shaped," "a thin connecting hull attached to two sharp uprights
    with lights at the ends," then "Remove the glow and dim the lights, and make it larger so it's mostly
    shadow blocking out the background stars, with only the small orange lights on the uprights"): a dark
    hull joining two broad uprights that taper to points at both ends, mostly shadow, blotting out the stars
    behind it and three quarters of the night's own glow (`HULL_SHADE`), unlit: it had a small dim orange
    light at each of its four points until gonkhub's "remove the surveyor's lights" (2026-10-20), and now
    it's only a shadow, but for its cannon's muzzle flash ([Salvage](salvage-and-ruins.md)). Drawn 16 points across overhead, as small
    as a fifth of that out toward the horizon (by how far it is from you), far bigger than any other. It's seen within about 6 km of its track,
    so from any one place it's a rare, short sight, and overhead rarer still.
  - **The lantern** (gonkhub, 2026-10-19: "a satellite orbiting Tu, its broadcast accessible when it is on the
    side of the planet facing Zan. Not visible though"): StarCom's Tu survey probe, circling Tu 60 moon radii
    off, 1.8 of Tu's radii out, a lap in 11 minutes, its plane holding the line to Zan, so it swings round in
    front of Tu and behind it. It's on the air only while it's on Zan's side of Tu, half of each lap, and only
    where Tu is over the horizon, so never on Zan's far side; it comes in at 0.6 of the others' strength, its
    tone clearest and loudest straight between Tu and Zan (a new LFO source, `facing`). The sky never draws it.
  - **By day** (gonkhub, 2026-10-20: "the closest and brightest satellites should still be visible during the
    daytime"): a satellite shows against the day sky once it looks bright enough, its light times how near
    it is, from 0.3 and fully at 0.5 (`SkyView.DAY_FROM`, `DAY_FULL`), drawn three times as bright as at
    night so it stands out (`DAY_BOOST`). So the formation, at 0.28 to 0.33, stays out of the day sky but
    for a faint gold tollgate; the relay shows as its ellipse brings it near, the ghost at its perigee and
    the cinder sinking low; and the crop survey's hull always, a dusky H against the bright sky with its
    four lights at the points.
  - The formation stays as it was, circles that don't turn, so its guarantee holds.
- **Always two overhead** (gonkhub, 2026-10-19: "there is always at least two active signals throughout a
  full day night cycle"). Eight of them fly in a formation (`Constellation.FORMATION`), laid out as real
  constellations are (a Walker pattern): eight planes 45° apart round the pole, one satellite in each,
  each 2/8 of a lap on from the last, all tilted 55°, 5 radii up, a lap in 9 minutes, always on the air.
  Searched over patterns of 5 to 8 satellites (offline, numpy), it's the least that keeps at least two of
  them 8° or more over the horizon everywhere on the moon at every moment, twice the margin asked; and
  since that holds for the formation however it stands, the moon's turn under it can't break it. The seed
  turns and mirrors the whole formation, so each run's sky is its own. They share one lap (different laps
  would drift them out of formation), so they differ by route, colour, shape and size; the relay and the
  ghost keep laps of their own. Before, on independent orbits, fewer than two were up 31.5% of the time
  and sometimes none. Now, over 16 seeds, 46 places each from pole to pole and four days every 4 s
  (radio probe 28), never fewer than two: two 20.5% of the time, three 42.5%, four 33.8%, five or six 3%.
  Storms can still cut them, as they do any signal. Use's sweep stops on the satellites overhead too.

  | Satellite | Era | Band, kHz | Looks | Orbit | Sound (placeholder) | Turned by |
  |---|---|---|---|---|---|---|
  | The relay | colonial | 1020 | white point, glinting | an ellipse (0.3) about 3 radii, 6.5 min, swinging round | the music, as before | a slow tumble: swells and fades every 20 s |
  | Thermal | Frontier Ag | 320–350 | a great dark hull against its own amber running lights | skimming 1.9 km up, 6.37 min, swinging 37° a lap; over the start as a run begins | tunnel drone | pitch by the temperature; tone by its height |
  | Sounder | StarCom | 560–590 | lime diamond | formation, plane 1 | the storm's roar | pitch wandering; brighter by day |
  | Lantern | StarCom | 1590–1620 | never seen | round Tu, 60 radii off, 11 min; heard only on Zan's side of Tu | the day song, slowed | faint; clearest straight between Tu and Zan |
  | Pendulum | StarCom | 700–730 | cyan cross | formation, plane 2 | a ping, pulsed | its tick quickening toward the eclipse |
  | Windsock | StarCom | 1032–1060 | green ring | formation, plane 3 | the wind | loudness and tone by the wind; grit by a storm |
  | Choir | colonial | 430–470 | lavender pair | formation, plane 4 | the Eye's drone | pitch sinking with the sun; tone drifting |
  | Babel | the war | 1290–1340 | red diamond, blinking | formation, plane 5 | tones, chirped | pulse and pitch wandering; grit by an anomaly |
  | Lullaby | colonial | 860–895 | small pink point | formation, plane 6 | the night song | slower in the cold; louder after dark |
  | Tollgate | Mon | 1500–1540 | large gold cross | formation, plane 7 | the shield's hum | pitch by the sun; tremolo drifting |
  | Ghost | unknown | 60–100 | dim blue ring, flashing | a wild ellipse (0.75), 0.75 to 11 radii up, 23 min, swinging round | tunnel drone, low | on in fits, hopping its band, tumbling; loudest in a storm |
  | Cinder | the war | 1150–1175 | large ember point | decaying: sinks 1.6 radii over 5 laps of 4.4 min, then burns back up; swinging round | **gonkhub's "Cinder"** (`radio_sat_cinder.ogg`, 3 min 40 s, looping) | brighter, louder and a little higher as it sinks; spinning |
  | Metronome | Frontier Ag | 1695–1735 | mint bar | formation, plane 8 | **gonkhub's "satellite1"** (`radio_sat_metronome.ogg`, a 2 s loop) | pitch rising a little with the sun (0.9 to 1.1); tone by its height |

  **The LFOs.** Each binding maps a source, 0 to 1, onto a target between two values. Sources: the
  temperature where the radio is (-40 to 70 °C), the sun (local midnight to noon), night, the wind (to
  25 m/s), the time to the next eclipse, the storm, an anomaly, the satellite's height, and a slow drift of
  its own. Targets: pitch, loudness, tone (a low-pass, swept by octaves), grit (a distortion), tremolo and
  pulse rate. Tone and grit are on a bus of the satellite's own (`RadioSky_<id>`) into the radio's. The
  thermal survey, the timing beacon and the windsock are the useful ones, by ear; the rest are flavour or
  gibberish. **Most tracks are placeholders**, sounds the game already has, until gonkhub's: each is one line
  in the roster (`sound.track`, with a trim, `sound.db`).
- **Interference as sound** (gonkhub, 2026-10-19: "Only plays static if nothing is currently playing on the
  radio. And instead of just reducing volume and increasing static for interference, let's run signals
  through distortion based on their interference ... bit crushing or just like glitchy effects ... a lot
  more layered and a lot more textured"). Each signal now has two numbers apart: how loud it plays,
  only by how near its carrier the dial stands (`share`), and how dirty it comes through (`dirt`, 0 to 1,
  `Garble.dirt`): how weak it is where it arrives, how much a storm on the way lets through, how much a
  jammer buries it, an anomaly near (up to half), and being off its carrier out on its skirt (up to a
  third). Loudness no longer falls with interference: a signal plays as loud as the dial has it, chewed up
  as dirty as it is, fading away only once it's all but lost (dirt past 0.92), or dropping out when the
  storm cuts it (`Radio.audible`).
  - **The chain** (`game/radio/garble.gd`), on the bus a signal plays through: the music, a god's song and
    tones on `RadioSignal`, each satellite on its own after its tone and grit. In order: a **narrowing band**
    (the lows thinning to 900 Hz and the highs closing from 16 kHz to 1.3 kHz, ringing a little, as weak AM
    does); a **crusher** (Godot's lo-fi distortion, the bits and the rate falling away, down to 700 Hz kept);
    **grit**, an overdrive, past a little dirt; a **warble**, a phaser sweeping up to 4 Hz; and a **smear**,
    short echoes feeding back, past a quarter dirt. Its settings **jump** in small uneven steps, a fresh roll
    every 0.09 to 0.36 s, the dirtier the oftener, so it never sits still.
  - **Glitches** (`game/radio/glitch.gd`), on each voice, past a little dirt, up to about five a second at the
    worst: it **stutters** (a fragment of 40 to 120 ms caught and repeated two to six times, then caught up
    with where it would have been, so a station keeps its time), **drops out** for a moment, **jumps** in
    pitch, or **drags** down and back like a finger on the reel.
  - **Static only when nothing plays.** The hiss, a jammer's spray and an anomaly's crackle are heard only
    while nothing comes through: gone once what the radio hears plays at 0.12 of full (from 0.02). Between
    stations, or with the way blocked, static is all there is. `radio_static_duck_db` is gone with the
    ducking it set.
  - Which god, satellite or song is useful, its window, its words and the spoken report are unchanged: they
    still go by `clean`, which still falls with all of it together.
  - One `RadioSignal` bus serves every radio, and one bus each satellite: two radios playing at once share
    their chains, the last to listen setting them. A satellite or god heard on two radios at once is rare.
- **Signal lamps** (added 2026-10-19). Under the band window a row of eight lamps, green climbing to amber,
  lights as strongly as the strongest thing the radio hears comes through, the last partly, following in
  about a tenth of a second: all lit on the music with the relay high, none between carriers, dark when off.
  So you find a station by eye as well as by ear, and still nothing is written. (`Radio.heard`, the lamps
  under `LAMPS`.)
- **The look-at line** names a mark: on a frequency you've marked, "Radio · 1040 kHz · Windsock", within a
  carrier's width of it. A radio with a battery used to show the battery's charge there instead of its
  frequency (the charge came first in `Hands._state`); its frequency now comes first, as this PRD has it.
- **Marks** (`Radio.toggle_mark`). With a radio in your hands, **M** (`mark_frequency`) marks where its dial
  stands, in a bright colour picked at random, with a soft click; pressed on a mark (within a carrier's
  width), it takes it off. No menu, nothing to type (gonkhub, 2026-10-19: "Remove the marker menu. Just
  place a randomly colored marker when m is pressed, or remove the marker if one is already present"; the
  panel with a name and eight colours it replaced is gone). A mark is named by its frequency. Marks are kept in the profile (`Profile.marks`), so they last across runs, and show on every
  radio's band as a short tick in their colour, along the top of the window over the numerals. **With marks, use (F) on a radio in your hands goes to the
  next mark** above where the dial stands, round to the lowest past the highest, in place of its sweep;
  with none, use sweeps as ever. A mark within a carrier's width of another replaces it.
- **Probes:** radio 25 (broadcasts overlap on their skirts), 26 (the constellation: distinct looks and
  routes, the dial changing over six hours, every satellite heard, the LFOs following the heat and the
  eclipse, one played overhead, the sky drawing them), 27 (marked frequencies), 28 (always two
  overhead), 29 (the irregular ones: the ghost, the relay and the cinder), 30 (the lamps and the
  mark's name), 31 (the jammer and the burn) and 32 (round Tu, and skimming low). Radio 4 is now the storm getting into the music, and 18
  static only when nothing plays. Radio 13 checks the relay's slide by nearing and drawing away. Radio 8's sweep counts
  the satellites overhead.
- **gonkhub's own tracks** (2026-10-20, from `Desktop/ableton/exports`): the cinder's "Cinder" and the
  metronome's "satellite1" are in (`assets/audio/CREDITS.md`); a radio's 400 Hz high-pass takes the low end
  off them, as off everything it plays. The cinder's pitch now swings 0.9 to 1.1 with its height, and the
  metronome's 0.9 to 1.1 with the sun, gentler than their placeholders'.
- **Not yet:** gonkhub's own tracks for the other satellites, satellites that carry spoken or encoded data, and
  marks shown anywhere but on the band and the look-at line.
- **Fixes in passing** (2026-10-19): the sky drew the relay and the satellites behind Tu, as it does the
  stars, though they orbit Zan far nearer; they show in front of it now. A radio taken out of the world
  stops its satellites' voices too. A radio works out the storm on the way only for satellites on the air,
  over the horizon and near its dial, not all of them every tick.
- **Look-test:** `look/satellites` waits on a clear night with several satellites up and lit, from over the
  dunes, and shoots each in the middle of the frame with a crop round it blown up four times, printing how
  high each is, how far from Tu and how bright it shows; `look/dial` marks three frequencies in a profile of
  its own, so their ticks and the lamps show.

### Litanies and the survey log (2026-10-18; built, on the `signatures` branch)

*Fleshing out the broadcasts.* What a god says outside its window is a liturgy with a shape, not a
shuffle. (Interval signals, a few notes of each god's own in place of the shared tones, were tried and
scrapped by gonkhub, 2026-10-19: every god still sounds the same tones, pitched apart.)

- **Litanies.** Outside its window a god recites its litany in order, one line every 6 s, and starts
  over, word for word, as its priests kept it once they no longer knew what the words were for (the
  endings session: "debugging is ritual, kept word for word"). Each opens and closes the same way, so
  where you've come in says how long until it repeats. The Quartermaster opens its net, calls the roll,
  and **challenges for a countersign nobody can give** (two phonetic words, new each round), then closes
  the net. Mother Cistern's are ration calls and the seal check as a prayer; the Almanac opens and closes
  its market; the Ledger opens and closes its book, its tallies as psalms; the Stoker's are fire calls and
  a stuck valve. Numbers in them are noise. What a god says in its window is unchanged.
- **The Walker's survey log.** After the forecast, every other 6 s on the line, the Walker sends its log:
  the leg it's on (km walked since the clock began), where it stands as latitude and longitude, and the
  steady wind at its feet, from the field there. It's true, and it's the weather far off, on the Rim where
  the Walker is. It's never in the spoken report.
- **Probe:** radio 23 (litanies and the survey log: the litany opening and closing each round with a
  new challenge; the survey log's leg and wind true, on the line and never spoken).
- **Not yet:** the living city's coded tones, a god's voice beyond its tones and its line, and the
  survey log's terrain.

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
  storm news at its feet the long report. Its survey log and contact log are built too (the
  Walker's quest, below).
- **The living city's chatter:** a few km, for its own scouts; coded tones, no voices ("storm
  coming, tether in", "city moving"), sometimes its own coordinates written as star positions, the
  nomads navigating by the stars. Its frequency is found by exploring (scratched on a radio in the
  dead city), its codes learned by noticing what follows them. Answered and built below: five
  motifs of reed tones.

### The Walker's Halloran surveys and the Stoker (agreed lore, 2026-10-20; not built)

The Walker and the Stoker remain friends from Halloran's survey work. Reports of reachable-in-principle
heat torment the Stoker because it cannot build the pipelines needed to meet its accumulated quotas.
The Walker does not intend that harm. The far-side heat connects this history to the Eye and the
existing destruction ending; [the lore](../lore-research.md#the-walker-and-the-stoker-surveys-of-unreachable-heat-agreed-2026-10-20)
separates the accepted relationship from the proposed dispatch progression.

The proposed quest starts with observations and develops into the Eye adopting the Stoker's
production priorities through packets the player carries. It must retain Starcom's protective
intervention and the need to place charges at all major vent caps. No dispatch system, friendship
state, refinery interaction or Eye-corruption gameplay is implemented by this decision. The
Walker's Rim route remains unchanged; how its earlier Halloran work and current survey information
connect to that route is still open. Do not fold this into the built anomaly-teaching quest below.

### The Walker's quest and the living city (agreed 2026-10-19; built 2026-10-19)

Hunter approved this design on 2026-10-19 ("perfect"). It is the second pass on the stations
above, and the Walker's quest line from the [storms spec](../storms-signals-sailing-2026-10-18.md).
It follows the rulings that the Walker walks alone, that finding it must never happen early, and
that teaching it takes evidence for each tell.
- **Finding the Walker.** It is a legged survey robot, partly broken, on its fixed route round the
  Rim, where its station already places it. Its feed growing stronger is the trail to it. The route
  keeps it far from where a run starts for the first ten days or more.
- **Its feed, second pass:**
  - **The survey log:** dry bearings, wind readings and terrain notes.
  - **The contact log:** each nomad who prays to it is a bearing, taken from where the Walker stood
    then. Bearings you note go on the Console's map as lines, and three that cross from different
    places triangulate the living city.
- **The living city's chatter** answers the spec's open question:
  - **Five motifs,** each three or four reed-like tones and no voice: storm coming, tether in, city
    moving, all clear, and a longer run giving its position in star positions.
  - **Learned** by what follows each one.
  - **Range:** a few km.
- **Seeing it.** The deed is seeing its lights: within its chatter's range, its back-lit decks
  crossing the dark, silhouettes only. Being found by it, its tether landing at camp, stays the
  nomad city ending.
- **Teaching the Walker.** A Console on your deck with the right sensors keeps evidence of each tell
  it witnessed through an anomaly: the compass's drift, the radio's crackle and a shield's load. Plug
  that Console into the Walker to teach it. From then on anomalies show on your map, and the
  Walker's feed flags them for anyone listening.
- **Its deeds** (Profile & saves, round two, step 4):
  - **Triangulated:** three crossing bearings;
  - **The Living City:** seeing its lights;
  - **Taught:** the teaching, which is hidden.
- **Not this round:**
  - taking the Walker (its core, its whole body, copying its data);
  - pilgrimage and aggro;
  - nomad reputation, and the gate it puts on reaching the Walker;
  - singing stones as a second kind of evidence;
  - the ghost relay.

**As built (2026-10-19).** The numbers were tuned from what the probes measured, on seed 1234 unless said.
- **The Walker in the world** (`Walker`, `game/radio/walker.gd`; its look `WalkerLooks`). Tilg's survey
  walker in the colonial survey style: a chamfered off-white hull of modular panels over a grey belly,
  safety orange at its corners and joints, the Tilg consignment stencil and its unit number, 05, on its
  right flank; a survey head out front with an amber lens strip lit; a mast bent part way up with a dish
  and an anemometer's cups. Six legs on a tripod gait, a 1.3 m stride, each foot planted while the hull
  passes over it, the gait worked from how far it has walked so it's the same at any frame rate. Partly
  broken: its left rear leg is snapped short and dragged, the hull lists toward it, the left flank's
  middle panel is gone to its frame. It stands where `Gods.home(&"walker", t)` puts it, on the ground as
  the sheet lays history, its hips 1.75 m over the sand. You can walk up to it: its hull is solid, and it
  walks on at its pace whatever is in its way.
- **Its route keeps it far early.** As a run begins it stands at the point on the Rim farthest from where
  the run began, and walks on (`Gods.place_walker`): for any start that's 90° round the moon or more,
  37.5 km at the least, for the first three weeks. Over 30 seeds, each of the three origins' starts and a
  run begun anywhere from day 3 to day 30 of the clock (probe 24): never nearer than 39.8 km in the first
  ten days, and within 30 km soonest on day 25. A save keeps it (the run's start and `began` place it); so
  does a death in Normal, which loads the save. A start under Tu, where every point on the Rim is as far,
  keeps the seed's own.
- **Far off, the Skyline's rules.** Out to the skyline's 3 km it's drawn; past its hand-over (420 to 500
  m) its real look dithers away as its stand-in comes in: six boxes of its own size and coats (the hull,
  the mast, the legs as they stand), drawn in the skyline's own shader, so nothing thinner than 1.5 px and
  as much fainter, standing on the far ring's ground, and hidden by a storm between, read once a second
  (`Plume.seen_through`). At 1.2 km it's a few pixels on the horizon: a sharp eye finds it.
- **Its port.** A data port on its right flank, an orange ring: a socket a cable's plug fits as any port
  does, the take action with the plug in your hands. Put in while its other plug sits in a Console's
  port, the Console uploads what it holds (below). Walking on, it pulls the cable taut and a plug pops
  out a few seconds later. It's no thing of yours: no save, wear or power pool has it.
- **Its feed growing stronger is the trail.** The forecast still carries the whole moon. Under it,
  a second line low in the view, comes its log, sent weaker: whole within 8 km, lost to noise past 40
  (`walker_log_m`), the more of it garbled the farther off, as a storm garbles a line. It reads one entry
  each 8 s (`walker_log_every`): its survey, then each contact it keeps, latest first, the last six
  (`walker_contacts_kept`).
  - **The survey log:** `survey 2140 · hdg 182 · wind 9 m/s ene · low dunes, sand thin · fix 4.1n 150.0w`:
    its leg (the km it has walked), its heading, the steady wind at its feet, the ground under it (flats,
    low dunes or dunes and slip faces; the sand deep or thin) and its fix, latitude and longitude to a
    tenth. The fix and its heading are the trail; the Eye gives you your own at night.
  - **The contact log:** `contact · 4 d ago · from 18.4n 150.0w · brg 262`: when a nomad prayed, where the
    Walker stood then and the bearing from there to the city, to a degree. A nomad prays once in 0.6 to
    1.8 days (`city_prayer_days`), so its six span about a week of the Walker's walk, 10 to 15 km of Rim.
    As written, each passes the city within about 160 m (probe 25), 45 km off.
- **Noting a bearing: the Console does it, plainly.** A Console with a radio in its system tuned to the
  Walker notes each contact the log reads whole (98% clean or better), once: `CONTACT · 18.4N 150.0W ·
  BRG 262` in its log, and a line on its chart. It keeps the last twelve. Three that cross, ahead of each
  other, none closer than 8° (`triangulate_degrees`), their three crossings within 3 km of one another
  (`triangulate_m`), fix a place: `!FIX · 3 BEARINGS · 43.9 km WSW` in its log, how far and which way from
  it. Beside the Walker on the probes' seed, the six it keeps fix the city 153 m from where it was, their
  crossings 68 m apart; the first few, a day or two apart, cross too finely, and it takes four or five
  (probe 26). Contacts from either side of one of the city's legs don't cross where it is; three from one
  mooring do.
- **The chart** (`Chart`, `game/devices/chart.gd`, a Console page): the moon round the Console north up,
  out as far as what's on it and no less than 10 km, rings every 10 km; the Rim and Tu-ward; each noted
  bearing a line from where the Walker stood along its half of the moon, that spot a dot; the fix a ring;
  and once the Walker's taught, the anomalies. Its tab joins the Console's once it has noted a bearing or
  the Walker's taught. Under it: how many bearings, the fix's distance and way, and its evidence, n of 3.
  It's what the one map's navigation filter shows once that's built (Devices & mods, one map with
  filters), and its anomalies the weather filter's.
- **The living city** (`LivingCity`, `game/radio/city.gd`): seeded and stateless, worked from the seed and
  the clock alone, so a save keeps nothing of it. It keeps on the far side, 105° to 160° from under Tu,
  moored 12 to 24 days at a time (`city_moored_days`), then making a leg of 4 to 9 km (`city_leg_m`) on
  with the water, away from Tu give or take a right angle and kept in that band, at 10 m/s, the storms'
  own pace (`city_speed`), so a storm behind it doesn't gain. On the probes' seed it sits near 158°, 45 km
  from the Walker. It doesn't read the storms to move: the storm field is laid on the flat world, and
  where a far place lies on it depends on how you walked there, so a city moved by it couldn't be pure.
  Its chatter reads them, where it is as the world lays it.
- **Its chatter** on a carrier of its own, 1480 to 1520 kHz, the seed's (`city_band_khz`), on the dial
  with the gods, a sweep stopping there as at any carrier: heard whole within 3 km and gone past 4.5
  (`city_heard_m`), garbled, slid and cut by storms between as a god is, no sky wave. A motif each 20 s
  (`city_chatter_every`), its tones once at the head of the slot through the radio's speaker like a god's,
  and its line showing them by how they run, high `¯`, middle `-` and low `_`:
  - **storm coming** `¯ - _`, three falling: a storm reaches it within 4 minutes out of clear air
    (`city_warn_s`); first, over everything;
  - **city moving** `_ - ¯`, three rising: it's under way;
  - **tether in** `_ _ - -`: a storm on it, moored;
  - **all clear** `- ¯ ¯ -`: clear air, none due, moored;
  - **its position** `_ - ¯ - _ ¯ - ¯`, a run of eight, every fourth slot unless a storm's due or it's under
    way, its place written in star positions after it: `pole 31° · turn 142°` (or `pair` south of the
    line, for the southern pair): the pole star's height over it, its latitude to a degree, and how far
    the stars have turned over it since its midnight, which set against your own sky's turn is its
    longitude, to a degree, about 400 m.
  Each tells the truth (probe 27): round a 6.3 km leg over a day and a half on the far side, 91 slots,
  11 storm coming, 20 city moving, 44 tether in, 1 all clear and 15 positions, every one so at the city.
  The far side storms most of the time, so all clear is the rare one. The tones are reed tones made here
  (`make_city_motifs.py`, CC0), A minor pentatonic over 440 Hz to clear the speaker's high-pass, about
  -36 LUFS like the station's tones (`assets/audio/CREDITS.md`).
- **Seeing it** (`CityLights`, `game/radio/city_lights.gd`): nothing by day; at night (the sun down where
  you are), within its chatter's 4.5 km, its lights: lamps along its rafts' edges and in their openings,
  a turbine's red lamp at each hub, its shields' pale blue, and the glow its decks throw up, each lamp
  never under 2.5 px so it reads kilometres off, dimmed by the haze and hidden by a storm between; and
  against the glow its silhouettes, eighteen rafts of chassis 14 to 40 m across, eight with a second tier,
  five turbines 26 to 40 m tall, three shield domes and its people on their decks, in ink, never a face.
  Laid out from the seed, about 110 m by 260 m, along its way, floating over the highest sand across it
  so no dune buries a deck. Come within 500 m (`city_douse_m`) and its
  lights go out: it isn't found by walking up to it (probe 28). Being found by it, its tether landing at
  camp, stays the ending.
- **Evidence** (Chart, on a Console): each tell its system witnesses through an anomaly, by the sensor that
  sees it, kept once with when, and logged:
  - **the compass's drift:** a compass stuck on its deck leaning 10° or more off north (Compass's tell),
    read against the north the Console knows; `TELL · COMPASS 60° OFF NORTH`;
  - **the radio's crackle:** a radio on its deck, playing, crackling a quarter deep or more;
    `TELL · RADIO CRACKLE 100%`;
  - **the shield's load:** a shield on its deck running with its load past a full storm's, while the
    Console's particle sensor reads the sand, which an ordinary storm's would match;
    `TELL · SHIELD LOAD 500% · SAND 3.0 g/m³`.
  With all three, `EVIDENCE · 3 OF 3 TELLS`. Without a compass on its deck, or without a particle sensor,
  that tell goes unwitnessed (Wind & storms probe 23). A save keeps it with the Console.
- **The teach** (`Console.upload`): plugged into the Walker's port, a running Console with evidence of all
  three teaches it: `!WALKER TAUGHT · 3 TELLS UPLOADED`. With fewer, `WALKER · 2 OF 3 TELLS · NOTHING
  TAUGHT`. From then on every Console's radar map and chart show each anomaly whose heart stands near, a
  violet ring as wide as it reaches, and the Walker's feed flags the nearest within 30 km of the radio
  (`walker_flag_m`) after its forecast: `anomaly 4.0 km north-east, full in 10 min` (Wind & storms probe
  24). It's a world flag, `World.taught`, kept in the run's save.
- **Deeds** (Profile & saves probe 35): Triangulated where the Console fixes the city; The Living City
  where its lights show for your eye, in view, over the dunes (its middle or either end, 12 m up, where its
  upper decks' lamps hang) and past the storms; Taught where the Console teaches it.
- **The "walker" scenario:** where the run's start puts the Walker on a clear day, 60 m ahead of it on its
  route and 4.5 m off its right, facing it as it comes; a deck of two resting on the sand beside you with a
  Console (its screen, an anemometer and a particle sensor) holding evidence of all three tells, a radio on
  the Walker's carrier, the base shield and a compass stuck on it; a cable in the Console's port and its
  other plug in your hands, to put in the Walker's port as it passes.
- **Probes:** radio 24 (far from the start early), 25 (a contact points at the city), 26 (three bearings
  fix it), 27 (each motif tells the truth), 28 (the city shows only within range, at night); Wind & storms
  23 (evidence needs each tell) and 24 (teaching flags anomalies); Profile & saves 35 (the deeds); dev
  probe 1 starts the scenario. The look-test is `look/walker` (`look/walker/shoot.sh`).

### The nomads' tones follow a thief (Agreed, session 5; not built)

*[Session 5](../lore-session-2026-10-18-mitchell-wow-shoemaker.md), "Nomad reputation." The whole
relationship with the nomads runs through gifts, shrines and radio tones, so they stay secret
([the vision](../vision.md#nomad-reputation-agreed-session-5-not-built)).* Steal from them and **their
short-range radio tones follow you around, getting ruder.**

Readings, not in the session:
- **They are the living city's coded tones** (above): short range, no voices, learned by noticing what
  follows them. Their usual run is free early warning ("storm coming, tether in"); a thief's run is the same
  code turned against you, and "ruder" is a pattern the player learns to read, not words.
- **They follow by range:** a few km, wherever you are within it, so a camp inside their reach hears them
  and one outside doesn't.
- **Not said:** what a ruder tone sounds like, how many steps there are between polite and rude, and
  whether rep ever recovers the way a returned sail earns a gift.

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
  spreads, never louder than its file however near (2026-10-19: felt, not loud); and through its own
  low-pass (the Booms bus) at 3 kHz by a kilometre, falling as distance to
  the 0.9 past it, 300 Hz at 13 km and 100 Hz past 40: air takes a sound's high end first, and thin air
  the more. Bigger bursts are lower, a pocket's blowout sharper.
- **Its low end rolls on** (2026-10-19, Hunter's playtest: "lean into the rumble more"). Each boom
  plays with a roll under it, 16 s of low rumble surging back off the rift's walls and the dunes,
  6 dB under the thump at a kilometre. Its low end carries along the ground: past a kilometre it
  spreads 1.5 dB a doubling less than the thump and plays 7% lower and longer a doubling, three
  quarters as high past 11 km, so far off the boom is bigger and longer, mostly roll.
- **From its way.** The boom is played 20 m off you toward its source, so it's heard from the vent's
  bearing as the column is seen there. Far off it's sound alone; near a live vent its build and
  its ground are felt too ([Wind & storms](wind-and-storms.md#plumes), "Felt near").
- **A live vent's roar near:** within 2.5 km of a live vent, its steady roar, at its file's level 150 m
  off and fading with distance, harder as it vents harder, through its own low-pass (the Vents bus),
  from its way. Both buses run through Weather, so a bubble muffles them as it does the storm.
- **Sounds:** `boom.ogg` and `vent_roar.ogg`, made here with Python and ffmpeg, and `boom_roll.ogg`
  and the build's `vent_build.ogg` (`make_rumble_sounds.py`), all CC0
  ([credits](../../assets/audio/CREDITS.md)). The build plays from the vent's way through the Vents
  bus, as the roar does.
- **Probe** (wind & storms 17): from 3 km and from 12 km off the rift's live vent a burst's boom comes
  as long after it began as sound takes to come that far (9.35 and 36.97 s), never before; from 12 km
  it's 9 dB quieter and under half as bright (323 Hz against 1,116), its roll lower, longer and more
  of it against the thump; it comes from the vent's way, to under 2°; and a jump in time past it
  plays nothing late. Wind & storms 23 is the felt part.

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
  *Session 5, ruled by Hunter (2026-10-18): the gods do have links. Mother Cistern can switch Mitchell off,
  so "no link" is read as "most links lost."*
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

### Review repairs (2026-10-20; built on the PR branch)

Sound-only output must carry the gods' transmitted words and a loot beacon's
bearing as well as weather reports. Include the Walker's log in its regular
report; a song does not suppress a god's words. Read a newly tuned station at once, with
bounded repeats for changing readings; never speak an unreadable signal. Keep
interference effect buses private to each radio, including satellite buses,
and release those buses when their radio is freed. A second set cannot alter
the first set's reception. The bundled-voice integration below is now implemented.

Measured: radio 39 checks actual god reception and beacon bearings reaching the
speech consumer; radio 40 checks independent effects and bus cleanup. Both pass
in 4 s. Existing volume, static and scheduled weather checks pass; weather
counts begin after the Stoker's newly audible transmissions. Satellite chains
are allocated only when their signal reaches the dial.
### Dropout continuity check (2026-10-19)

The Stoker's song must keep the same active playback when a storm cuts its signal. Radio probe
11 now checks the non-null `AudioStreamPlayback` instance and that it remains playing, alongside
its existing song and gain assertions. Advancing the audio clock across eight physics ticks is
not the contract: headless audio mixes on a separate clock. The pinned Godot implementation
creates a new playback for each `AudioStreamPlayer3D.play()` call, so playback identity directly
detects a restart even when its new cursor has already advanced. No radio behaviour changes.

Measured on Linux with Godot 4.7.2: the original focused check passed normally. An external
diagnostic compressed only the storm observation's physics ticks between audio mixes: the
cursor stayed at 0.09578231 s, the playback instance stayed identical, and the old assertion
failed. The corrected probe passed; temporarily forcing `music.play(0.0)` on storm entry made
it fail specifically at the continuity assertion. After removing that mutation it passed again.
Native macOS verification remains required; Linux diagnostics explain the timing assumption
but do not establish the failed runner's exact audio schedule.

### Scheduled-song continuity under slow simulation (2026-10-20)

A receiver must keep the same playback throughout one scheduled song occurrence,
even when the real audio mixer advances faster than capped simulation ticks.
World time still selects the occurrence and the phase joined on tuning in. A new
occurrence of the same recording starts a new playback; signal strength, weather
and normal mixer/simulation drift must not repeatedly restart it.

The previous same-recording path compared the mixer position with world elapsed
seconds and replayed whenever they differed by more than 1.5 s. A focused
regression reproduces the resulting identity change by allowing 2.2 real seconds
of mixing while advancing the scheduled station clock by only 0.1 s. Keep the
existing weather-transition playback-identity check unchanged.

As built: identify an explicit scheduled occurrence by its start world time
(`t - into`), using an absolute near-zero comparison. Mixer position no longer
restarts the same occurrence. The clock-lag regression fails on the old code
and passes with the fix (5 s), including a distinct replay of the same asset.
The unchanged weather/Stoker continuity check and Eye song check pass (6 s each).

### Interference fragments keep the same decoder (2026-10-20)

The designed stutter intentionally repeats a short fragment, then catches up to
where that fragment would have ended. Godot's high-level player seek stops and
replays its stream, so this can change playback identity even when the scheduled
song itself has not restarted. Keep those fragment and catch-up positions, but
seek the existing stream playback under the audio-server lock so the Vorbis
decoder cannot be changed while the mixer reads it. A pending voice without an
active playback has nothing to seek yet.

A forced-stutter regression passes the intended public cursor positions on the
old code while failing identity preservation at both repeat and catch-up. Keep
that position coverage alongside identity, and keep the separate scheduled-clock
regression and original weather-transition continuity check unchanged.

As built: both stutter seeks use the existing AudioStreamPlayback under the
audio-server lock. The forced imported-Vorbis repeat/catch-up check passes (2 s);
the unchanged weather/Stoker continuity, scheduled-clock drift, Eye song and
independent-radio effect checks also pass (5 s each). Public player cursors
follow both intended seek targets without replacing the playback.

## Survey receiver (agreed and built 2026-10-20)

An early, cheaper receiver hears only existing ruin loot beacons. It shares the radio's
battery, mounting, carry-use, wheel/fine tuning and volume controls, but a narrow beacon
band and shorter tuned reach are data. Use powers it on and acquires one real untaken
beacon; it keeps that target through power cycling and saving until the target is invalid.
A subsequent explicit power-on can acquire again. Taking the find or leaving range stops
reception; no moving or invented beacon replaces it silently.

Turn the case's loop while holding it, carrying it or on a deck: two opposite signal
lobes vary a coarse strength needle and pulse cadence/level. It is not a compass bearing
or distance meter, and has no music, gods, weather forecast or map. Empty battery/off
clears its sound and needle. A new Signals deed records arriving at a valid acquired
beacon from at least 60 m away while personally carrying or holding the live receiver.
It comes from shallow finds and the creative menu; a developer receiver scenario places
one with a battery among real ruins, without manufacturing a beacon.

### As built and measured

`SurveyReceiver` reuses the physical Radio controls and power contract, with a
0.5 W draw, 1200 m reach, 1930 ± 40 kHz band and eight needle intervals, all in
`tuning.tres`. It adds a soft static bed: detuning and dust raise it, a stronger
real signal ducks it. Pulse cadence and level follow strength. Volume zero mutes
the pulse, static, switch and tuning sounds. Both lobes remain intentional;
the player must compare readings while moving rather than read a hidden bearing.
Console voice/forecast instruments and weather-station sleep exclude this tier;
its local Console power/volume controls still work.

Focused existing checks passed: radio 2 (real beacon finds), 10 (volume), 20
(tuning/reeling), saves 1 (round trip), and devices 30 (Console battery voice).
An unseen 1280×720 input diagnostic acquired a real generated beacon 299.15 m
away through Use. A quarter turn changed strength 0.8664 → 0.06929 and the
needle from interval 7 → 1. Coarse/fine actions moved 1930 → 1935 → 1934 kHz;
volume zero put both static and pulse at −80 dB. Carry Use switched off; empty
cells immediately cleared needle/static/pulse. Save/resume retained the exact
target, acquired-from distance, frequency, power switch and volume. Leaving
range silenced reception without replacing the target. Taking its actual ruin
find through Hands Grab marked it taken and silenced the receiver.

A separate normal-run diagnostic, with an isolated profile and real generated
ruins, triggered `follow_signal` on arrival after acquisition 282.18 m away.
The fixture used scripted travel and spawned receiver equipment; this checks
the real action's deed path, not an unassisted player expedition. The developer
scenario correctly awarded no deeds. A mounted receiver's quarter turn changed
strength 0.8759 → 0.07008; its Console found zero forecast radios and did not
speak through the receiver. The held and carry views and four-line 20 px action
hint were inspected at 720p. Capture audio was muted; subjective sound quality
still needs listening in play.

### Combining the sound-only radio with the bundled voice (2026-10-20)

Preserve the bundled LJ Speech voice and the Console's local announcements.
The new regular weather reports, god messages and beacon bearings play from
the radio's own reader through its private interference chain. No system TTS
or HUD transcript is restored. Keep the existing full-phrase recordings; add
a bundled vocabulary and common fragments for dynamic readouts, with exact
numbers assembled from recorded words. Unknown proper names can be spelled
with recorded letters, so a missing word never silently discards information.
Reports use the new two-minute cadence and urgent advisories interrupt; an
ordinary transmission waits for the current one to finish. Keep the newer
Walker's contacts, living-city channel and receiver tier. This integration
supersedes older descriptions of OS speech and the weather-only reader.

Combined checks: radio 14 (schedule/advisories), 23 (native reader), 25 (Walker
contacts), 29 (litanies), 33 (bookmarks), 39/40 (messages/effects) and 41
(receiver controls and carried-speaker placement) pass, as does devices 30
(Console battery speech). The receiver retains its own loop/needle controls,
but shares the radio's camera-relative carried sound and physical speaker when taken out.
Three real speech plans were exported and checked with speech recognition: wind
16 m/s, temperature minus 3, north-north-west, bearing 173 and range 1.2 km
remain intelligible. This is a recognition check, not a substitute for listening
in play. The added PCM bank is 24.4 MB; its import stays uncompressed so its
sample ranges are exact. Full recordings are reused whenever available.
