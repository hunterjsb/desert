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
research](../world/lore-research.md).

## The radio

A device you carry or mount ([Devices & mods](devices-and-mods.md)). Its reach is huge, and better sets and
antennas hear more clearly. Tune it, and you find:

- **Music, for the vibes:** Sand Game's "Sandy Andy" by day and "Waiting on the Sun" by night.
- **Weather broadcasts,** automated, read from the real storm field; better equipment hears further ahead.
  The Console's instrument table has the radio as a row
  ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)).
- **Loot beacons:** a bearing to something worth finding.
- **Lore:** garbled fragments that hint and never state.
- **The gods** (the lore session's squatting oracles): degraded local models on dead StarCom stations. As
  scripture it's noise; decoded, it's real information, so **decoding the signal is a skill** (rule 1).
- **Maybe a voice:** a hint that someone might still be out there ([Salvage & ruins](salvage-and-ruins.md)),
  never confirmed.

**New channels are finds,** a frequency scratched on something or stored in a device. **Storms get into the
signal:** crackly music while a storm roars outside is the cozy moment. **It's a physical object with
charm:** switch it on and it gives a burst of static; bump it and it crackles.

### The set (built 2026-10-17)

- **A device:** 2.5 kg, a battery slot on its back and a port. Carry it, set it down or stick it on a deck
  as the shield sticks; it plays from where it is, drawing 2 W from its battery or the deck's pool (a base
  battery runs it 50 hours). On a Console's deck it's the Console's voice, and its power-page row is the
  dial's own controls, with a SWEEP to the next carrier ([Devices & mods](devices-and-mods.md)). Found on
  the surface and in ruins; no starting kit has one.
- **Use switches it on or off** where its dial stands, with a click (gonkhub, 2026-10-21: "ALWAYS toggle
  radios on/off"), looked at or in your hands.
- **Carried** (Survival, 2026-10-17): it rides on you out of sight on its own battery; use on it in the
  inventory works it too. Its spoken bearings are by the moon's north, so past a pole they agree with the
  compass.
- **In your ears** (gonkhub, 2026-10-19: "when the radio is inside the player's inventory, play its audio
  directly to the player," "the volume level in the inventory should match when held very close to the
  player ... that way, there is not a jump in audio when they stow it," and "ensure camera movement will
  not affect panning"): carried, it sounds from straight ahead of your eyes at a held radio's distance
  (`Hands.nearest_hold`), so stowing it changes nothing and turning never swings it. Its voices sound from
  its middle, carried or not.
- **Static** comes in with a storm front's outflow, before the wall and full inside it, in a bubble too:
  it's the sand charging up (the lore research), not the storm's sound.
- **An anomaly's crackle:** short pitched-up bursts as deep as its hidden term, which no forecast speaks of
  ([Wind & storms](wind-and-storms.md#the-anomaly-as-built-2026-10-18)). It's the agreed tell, so it stays
  audible under whatever the radio plays, never ducked away by a station, and counts as the crackle tell
  only during a burst you can hear.
- **A save** keeps whether it's on, each band's place and the knob; an old save on the weather or the music
  goes to its new station. **Code:** `game/radio/radio.gd`, with `gods.gd`, `dial.gd`, `interference.gd`,
  `transmissions.gd`. **Not yet:** bumps crackling, lore, frequencies as finds.

### The dial and the gods on the air (Hunter, 2026-10-18; built)

*Hunter: "Each god [has] its own dynamic direction tracked relative to the player's position. A radio may
tune its frequency from 0 to 2000 kHz. Assign each god a frequency range, and world position. Some are so
far away you may reduce it to an abstract direction. Weather interference between the radio and the god
will cause distortion, warping, and cutting of the transmission. Transmissions will vary. The difference
between noise and useful information is if the player knows when to listen." And: "use the weather god for
the weather station." Use the music, weather and beacon "but don't explicitly name each channel for what
it is."* The gods broadcast, past the lore's "speak only through terminals", by Hunter's call.

- **The AM dial runs longwave and mediumwave, 150–280 and 530–1700 kHz** (gonkhub, 2026-10-21: "update this
  to reflect a more realistic AM radio bandwidth range and one that fits with the setting better, just like
  the other ones are"): a real set's two AM scales, as the colonial makers would have built it. Tuning across
  the gap comes out on the other side (`Dial.on_dial`).
- **Tuning** (reel in, pay out) moves it `dial_notch_khz` (10 kHz) a notch, fine tuning 1 kHz. Spun fast,
  each notch goes farther than the last, up to sixteen at once (`dial_spin_seconds`, `dial_spin_grow`,
  `dial_spin_most`; gonkhub, 2026-10-20: "speed up frequency scrubbing with scrollwheel", then 2026-10-21:
  "Increase scrub speed when mouse wheel scrolling"); fine steps never speed up. Reel in and pay out are one
  rule with rope ([Rope & tethering](rope-and-tethering.md)): the line in your hand first; else the radio you
  look at (or one on a Console you look at); else the waist line you look along; else a radio you hold.
  Bring near and push out never turn a dial.
- **A volume knob** (Hunter: "give the radio also an adjustable volume knob"; "10% should be barely
  audible, and 100% should be louder than most other sounds in the game"; "100% volume needs to be much
  much louder in game"; "Sound falls off too quickly"): a tenth a notch, each the same 6 dB step
  (`radio_volume_range_db`). Full is `radio_loudness_db` (15 dB) over the tracks' level, past the cap other
  things have, heard at that level to `radio_heard_m` (15 m), then 6 dB less a doubling.
- **A small speaker** (Hunter: "The radio also needs a hi pass filter on it"): everything goes through the
  radio's own bus with a high-pass at `radio_highpass_hz` (400 Hz), into the world's sound.
- **Quiet static** (Hunter: "Quiet down the ambient radio static a lot unless there is nothing currently
  playing"): the hiss is heard only while nothing comes through (Sound only, below).
- **On the AM dial** (`Dial.carriers`): the four far gods, the beacon at 530 kHz (mediumwave's bottom, where a
  road beacon would sit) and wrecks calling SOS (Bands). Nothing names a carrier: the look-at line reads only
  "Radio · 262 kHz", or "Radio · off". Each god's carrier wanders inside its band each moon day, from the
  seed, never more than `carrier_drift_khz` (5) from the day before (gonkhub, 2026-10-20: "ensure a 'home
  frequency' cannot shift more than 5khz from where it was last"; `Dial.walk`). A signal comes in whole
  within `dial_width_khz` (3).

| God | Heard on | Home | Worth hearing | What it says then |
|---|---|---|---|---|
| The Quartermaster | AM, 152–172 kHz | The black site's bunker | Through the eclipse ("blackout drill") | Bearing and range to the nearest cache, dugout, checkpoint or bunker history laid near you |
| The Walker | FM, from where it walks | Where it walks on the Rim | Always | Its log: survey and contacts (Stations) |
| Mother Cistern | AM, 590–630 kHz | Sister's temple | Dawn, 05:00–07:00 local | Frost or dew tonight with the 03:00 temperature, and the nearest cistern or stepwell |
| The Almanac | AM, 680–740 kHz | Frontier Ag's farm domes nearest Halfrise | Sunrise and sunset | The day's range, and which crops would hold through it in the open |
| The Ledger | FM, from its home | The Bastion, Port Morgan | About midnight ("berth inventory") | Bearings and ranges to Halloran, the Rim depot and Starcom. It sends strongest |
| The Stoker | FM, from its home | Halloran's refinery terraces | The hot hours, 13:00–16:00 local | A countdown to the next eclipse, and the peak temperature in the next 5 minutes |
| The Eye | AM, 1620–1690 kHz | The observatory, at the anti-Tu point | Night where the radio is | Your latitude and longitude, and the local time |

- **Litanies.** Outside its window a god recites its litany, a line every 6 s in order, then over word for
  word, as its priests kept it once they no longer knew what the words were for (the endings session:
  "debugging is ritual, kept word for word"). Each opens and closes the same way, so where you came in says
  how long until it repeats. The Quartermaster calls the roll and **challenges for a countersign nobody can
  give** (two phonetic words, new each round); Mother Cistern's are ration calls and the seal check as a
  prayer; the Almanac opens and closes its market, the Ledger its book, tallies as psalms; the Stoker's are
  fire calls and a stuck valve; the Eye is silent. Numbers in them are noise; everything said in a window is
  read from the real systems. Every god sounds the same tones, pitched apart (gonkhub scrapped interval
  signals of their own, 2026-10-19).
- **Direction.** Each bearing is worked from the radio to the god's home on the sphere (`Gods.home`), every
  reading: within 12 km a compass point, within 40 km a rough one ("somewhere west"), past that a way
  across the moon (toward Tu, away, across its face left or right, or from everywhere near the opposite
  point).
- **Reach on AM.** Longwave's ground wave carries farthest, so it keeps the Quartermaster and the distress
  calls; higher up, reach falls as the square of the frequency by day, and at night a sky wave comes down
  past a 15 km skip, as real AM does. So the Eye comes in only at night.
- **Weather between you and the god** (Hunter: "Interference must be highly directionally weighted ... If a
  storm is very close to you on your east, each signal that lies to the east should be completely
  unreachable"): the storm field is read at 12 points toward the god out to 3 km, and the **worst** counts.
  Past `storm_blocks` it **cuts the signal off**; less, it lets less through the nearer it is to that, so
  which signals you lose says which way a storm lies. More storm means more **distortion**, a carrier
  **warping** up to 6 kHz off so you chase it, and **cutting** up to 60% of the time. A weak signal frays
  the same way. FM keeps clear of storms (Bands).
- **Songs on the air** play on their station's clock whether anyone listens, so you tune in mid-song.
  Weather, a dropout or a glitch never restarts one: at a glitch's end it catches back up to where its
  station is. A new play of a song (another meltdown) starts fresh.
- **The Stoker's song** (Hunter: "use that segment on the Stoker mind's frequency"; "stoker track too
  quiet"): 45 s of Hunter's `modsynthpatch.wav` (`radio_stoker.ogg`), as loud at its peaks as Clear Skies,
  on the Stoker's FM station. It never plays by itself (Hunter: "make the stoker's audio not random. For now
  just bind it to a command called 'meltdown'"): the dev console's `meltdown` plays it once.
- **The Eye's drones** (Hunter: "implement this as a random ambient track that can play from 'the eye'";
  gonkhub, 2026-10-18: "put this as a random ambient track for the eye"): after a silence of
  `eye_quiet_minutes`, the Eye plays through Hunter's drone (`radio_eye.ogg`) or gonkhub's tunnel ambience
  (`radio_eye_tunnel.ogg`), the seed's pick; between them, not even tones. Heard by sky wave, so at night.
  They are the Eye's alone.

### The dial in your hands (Hunter, 2026-10-18; built)

*Hunter: "the radio dial, we should have you zoom in and turn the physical dial, and make sure we tie our
god stations to their homes." gonkhub, 2026-10-19: "Stop the radio from zooming to the interface when
interacting," then "Bring back the pov zoom when using fine-tune shift scrolling"; 2026-10-20: "make the
visual for the knob turning match the bandwidth, so going from 0-20k is one full knob turn."*

- **Up close, only for fine tuning.** Fine tuning eases the view in to the set's face (`dial_close_seconds`,
  `dial_close_m`, `dial_close_fov`) so it fills most of the view; tuning, use and the volume leave the view
  your own (`dial_close_up` closes in for all of them, as the dial look-test does). It meets the face square,
  or within 30° of your line of sight, the band level. It's a camera of its own, so your aim stays yours:
  look off and it eases out, and `dial_close_hold` after the last turn anyway. A radio in your hands turns
  its face up to your eyes.
- **The face** (`Dress`): a lit band window with a thin red needle; under it the speaker's slats, the tuning
  knob and a smaller volume knob, black and ridged with a bone line on each cap. The tuning knob goes once
  round across the whole AM dial; the volume knob sweeps three quarters round. Each band's printed scale
  marks its real limits along the needle's travel.
- **A reminder of the actions:** the close view shows a few short lines naming tuning, fine tuning, volume,
  mark and on/off with their current bindings (from `Controls`, in the shared UI type), the mark line only on
  a set with marks. It fades with the close view, hides under a menu, never covers the dial and is never
  permanent carried-radio text.
- **Each god at its home** (`Gods.home`): its landmark's middle in the history, as the table says. The
  Almanac's is the history's `farm_dome` settlement nearest Halfrise; the Walker's is where it has walked
  to (Stations). Seed 1234, from the start: the Quartermaster 28.1 km somewhere west. Code:
  `game/player/close_up.gd`, `game/look/dress.gd`; look-test `look/dial`.

### Sound only, skirts, marks and lamps (gonkhub, 2026-10-19; built)

*gonkhub: "Remove all text dialogue from the radio. Audio only." "Ensure each broadcast can be picked up
near its home frequency at reduced signal strength ... overlapping signals that each have a home frequency
so the player can focus on what they are trying to listen to, but the whole frequency range is dynamic."
"Allow the player to mark frequencies, and give them a name + color." Then: "Remove the marker menu. Just
place a randomly colored marker when m is pressed, or remove the marker if one is already present."*

- **Sound only.** Nothing the radio says is written in the view; the look-at line names only the
  frequency, the set's own reading. What a station says is still worked out (`Radio.said`,
  `reception.text`) for speech, the dev overlay and the probes.
- **Skirts.** A broadcast is whole on its carrier and heard at `dial_skirt_share` of its strength out across
  `dial_skirt_khz` either side (`Dial.heard`): 10 kHz off, about a fifth. The nearest station within 30 kHz
  is the one the dial hears (`Dial.reach`), so tuning toward one brings it in faint, then whole; between two
  near carriers you hear both.
- **Interference as sound** (gonkhub: "Only plays static if nothing is currently playing on the radio. And
  instead of just reducing volume and increasing static for interference, let's run signals through
  distortion based on their interference ... bit crushing or just like glitchy effects ... a lot more
  layered and a lot more textured"). A signal plays as loud as the dial's nearness to its carrier has it
  (`share`) and as dirty as it comes through (`Garble.dirt`: weakness, storm on the way, a jammer, an
  anomaly near, being out on its skirt), fading only once it's all but lost, or dropping out when a storm
  cuts it (`Radio.audible`). The chain (`garble.gd`) narrows the band, crushes bits, adds grit, a warble
  and a smear, its settings jumping in uneven steps; glitches (`glitch.gd`) stutter, drop out, jump in
  pitch or drag down and back like a finger on the reel. Each radio has its own chain and buses,
  satellites' too: a second set never changes the first's sound. Usefulness, windows and speech go by
  `clean`, which falls with all of it.
- **Static only when nothing plays:** the hiss and a jammer's spray are heard only while nothing comes
  through, and are all there is between stations or with the way blocked. The anomaly's crackle is the
  exception (The set).
- **Signal lamps:** under the band window eight lamps, green climbing to amber, light as strongly as the
  strongest thing heard comes through (`Radio.heard`), so you find a station by eye too.
- **Marks** (`Radio.toggle_mark`): with a radio in your hands, mark puts a mark where its dial stands, in a
  bright random colour, with a soft click; on a mark it takes it off. No menu; a mark is named by its
  frequency. Marks belong to the run, kept in the run's save, and show as a tick in their colour on every
  radio's band. On a mark the look-at line reads "Radio · 1040 kHz · Windsock". Marks are ticks and names
  alone: use only switches the set on or off.

## Bands and tiers

*Hunter: "Multiple tiers of receivers is a must." From a research session with gonkhub, 2026-10-20:
"distinguish between frequency ranges and radio technology as a progression lever ... add more sonic areas
to unlock and explore," and "I want this to feel grounded in actual tech." The pitch was approved whole:
"all your suggestions look good."*

Two rules from real radio carry this. **The band decides how far a signal goes; the modulation decides what
it takes to hear it and how it sounds.** And **the air has a ceiling:** the charged layer high in Zan's air
(fed by Tu's belts) that bounces the night sky wave down also turns back anything under a few MHz sent from
above. So nothing in orbit is heard on the AM dial; under the ceiling is the ground's.

**The band map** (agreed direction; what's built is in the sections after it):

| Band | Gets there | Hearing it | Draw | Who's on it |
|---|---|---|---|---|
| LW/MW, 150–280 and 530–1700 kHz (the AM dial) | ground wave, and at night past the skip | crystal set, then the field radio | 0, then 2 W | the far gods; the beacon; wrecks calling SOS; the nomads' ghost relay; beacons sending their names in Morse |
| Shortwave, 2–30 MHz | skip, with a dead zone between | the bare terminals, then a kite | ~1 W | every satellite; the relay repeating Port Morgan Tower; Tu's roar on a timetable; weather maps by fax; numbers stations |
| VHF/UHF, 30 MHz–1 GHz | line of sight: height is range | the FM converter, then an FM set; a whip; a handheld beam | 0.5–2 W | Port Morgan Tower and the port's music; the living city's chatter and music; the near gods; ruin intercoms; the skimmer field's navigation beacon |
| L/S, 1–4 GHz | space | dish, LNB and decoder | 5–10 W | a digital bundle; the drone's downlink |
| X, 8 GHz and up | deep space | a big dish and a cooled amplifier | high | Varran, and the far end of the lane, from the far side's quiet |

Natural radio, under 30 kHz, was built and then cut with the realistic AM dial (gonkhub: "Cut it"): it's
below any real set's scales.

**Three sounds, one a technology.** AM hisses and crackles in a storm, whooshes as it fades at night, whistles
where two carriers beat, and is thin. FM is near silent and full range; the stronger of two takes a frequency
whole (capture), and at its fringe hiss breaks in at once. Digital is perfect or nothing, warbling and
stuttering between (the glitch chain is digital's).

**The set is a chain of parts:** antenna, front end (a converter or an LNB), set, decoder, and a speaker or a
printer, each a find or a build that plugs in. Receiving is cheap, so upgrades are **gain** (antenna size and
aim), **quiet** (amplifiers; cold nights really are quieter), **knowing** (time, place and an orbit's elements
to aim a dish: the Eye and the Pendulum become prerequisites) and **talking back**, where the power goes:
with machines only (no NPCs), commanding the drone's cannon or a satellite's stored dump. It's also
how Daventry could hear you. The FM converter is the first step, as 1960s converters for AM car radios were;
a real FM set the second.

**Built so far:** the crystal set and the field radio in makers' looks; the realistic AM dial; the FM
converter and band, playing FM clear; the shortwave converter and band; the kite; the misc bay's modules;
the ferrite rod's null; the survey receiver. **Still direction:** the dish, decoder and digital, the uplink.

### The bands rebuilt (gonkhub, 2026-10-21; built)

*gonkhub: "Let's just scrap and rebuild our radio frequencies from what we now have. Here is where
everything should be sorted into: AM: Distress Signals, half the gods, and long distance beacons. FM: Combine
Weather Station and deliveryship Control Tower frequencies into one Port Morgan Tower station. Also on this
band: living city misc chatter, Living city music radio, and half the gods. Shortwave (Satellite): All
satellites or otherwise offworld transmissions." Then: "On FM, you must be near the tower to hear the weather
broadcast. You need Shortwave upgrade to hear a satellite rebroadcast of it, greatly increasing effective range
for players with a nice setup. Weather channel reports should be reformatted to give the report from the
tower's perspective. Wind speed, time, and temperature at the tower's location. When reading out reports for
weather advisories for anomalous storms, extreme storms, etc, it should give a bearing and distance from the
tower." Settled with it: distress means wrecks calling SOS; the far gods go on AM and the near ones on FM;
the port's music is on FM only; the relay repeats the tower on shortwave.*

- **AM, the barest:** the Quartermaster, Mother Cistern, the Almanac and the Eye; the beacon; wrecks calling
  SOS. The port's music left AM, so it no longer reaches the far side; Hunter's ask that the music "can
  actually be interfered when on the far side of the moon" now falls to the far gods (the "far_storm"
  scenario tunes the Almanac's night sky wave).
- **Wrecks calling SOS** (`game/radio/distress.gd`): of the freight pods, lifeboats, hulls, tithe haulers,
  hoppers and nomad rigs in the sand, `distress_share` still call. A radio hears the nearest three within
  `distress_reach_m`, each on a whole kHz within `distress_spread_khz` of 240, a low longwave ground wave
  through the storm and the rod's null as a god is. Each `distress_every` it sends SOS in Morse (placeholder
  pings), then speaks "S O S. S O S. Latitude … Longitude …", the wreck's own fix, so a call leads to
  salvage. The deed **Mayday**: hear one come through whole.
- **FM, near and clean** (`Fm.stations`): seven stations, each locked on its own odd tenth of a MHz the seed
  picks, at least `Fm.APART` apart: Port Morgan Tower and the port's music on the port's `fm_mast_m` mast; the
  living city's chatter and its reed music from a `fm_city_mast_m` mast wherever the city is; and the Ledger,
  the Stoker and the Walker, each from a `fm_god_mast_m` mast at its home, so heard only near it, the Walker's
  moving as it walks. Changing station clears the last one's queued words.
- **Shortwave, the sky's:** every satellite and Tu's roar, and **the relay** at L1 on 7250 kHz, repeating Port
  Morgan Tower. It's heard as a satellite is (`Radio.receive_from`): faint on a bare shortwave converter
  unless near overhead, far better by a kite. So the weather near the port is FM's, and anywhere on the
  near side with a good rig.
- **Not yet:** the sleep offer "Until a storm's called" still wakes you by the storm at your camp, while the
  radio it tunes reads the tower's weather.

### The radio's tiers and makers' looks (2026-10-21; built)

*From the radio-equipment lab (`look/radio_kit`, its README the proposal): gonkhub asked for "three tiers of
radio and several visual styles," each band its own colour (`game/look/radio_kit_looks.gd`,
`radio_band_looks.gd`).*

- **The crystal set** (`crystal_set`), tier 0: a coil wound on a can, a cat's whisker on a crystal and an
  earpiece on a scrap tray. No power: it draws nothing and runs on what it hears, at `crystal_gain` of a field
  radio's strength, so only strong carriers near come through. AM only, no marks, its own face. The deed
  **Foxhole Radio**: hear a god in its window on one.
- **Quiet, and the headset** (gonkhub, 2026-10-21: "Crystal set should have no adjustable audio, and needs to
  be much quieter. If the player has the headphones module, they can attach it ... to hear more clearly.
  Otherwise, transmissions should remain hardly audible and highly distorted"): no volume knob; it plays
  `crystal_quiet_db` down and at least `crystal_dirt` dirty. Its tray has one bay; a headset on a cable from it,
  worn, brings it to `crystal_headset_quiet_db` and `crystal_headset_dirt`. Powered
  modules don't run on it. The deed **Close Listening**: hear a god in its window on a crystal set through a
  headset.
- **The field radio in makers' looks:** the radio the game always had is company issue (teal and gunmetal),
  and four more are their own catalog devices, the same set: colonial survey (`radio_colonial`, off-white and
  orange), skimmer crew (`radio_skimmer`, olive, a plate riveted over a crack, tape), First Kingdoms
  (`radio_kingdoms`, enamel red, hardwood and brass) and second age (`radio_second_age`, ceramic and saltwood,
  cord), each wearing the lab's body with the set's own live needle, knobs, lamps and window.
- **Its band window recolours as it switches** (`Radio._show_window`): amber for AM, sea green for FM, violet
  for shortwave, each numbered for its band with its name in the corner; under it three tells, AM, FM and
  SW, lit on the band it's on, dim on one its converters reach, capped black on one they don't.
- **The survey set is scrapped** (gonkhub, 2026-10-21): a colonial three-band set with FM built in, it was
  tier 2. Saves that had one wake it as the colonial field radio.
- In the creative menu beside the radio. **Not yet:** the crystal set's slider turning as it tunes; finds
  for the new sets in ruins.

### The FM band (built 2026-10-20)

- **The FM converter** (`fm_converter`), a radio mod: 0.6 kg, no power of its own (Radio upgrades vetted,
  below), in a socket on the radio's left side (kind `radio_mod`). A fairly easy midgame find: First Kingdom
  shelves (weighted 2), skimmer-era and colonial shelves, and relay mast cabinets.
- **The band switch** works the radio the tuning actions work: round AM, FM and shortwave through a burst
  of static, skipping a band without its converter. Each band keeps its place; take a converter off and the
  radio goes back to the AM dial.
- **The FM dial** runs 87.5–108 MHz (`fm_notch_mhz`, `fm_fine_mhz`), a station whole within `fm_width_mhz`
  and no skirt: "Radio · 96.7 MHz". Marks work on any band.
- **Line of sight** (`Fm.margin`): a station clears the noise by `fm_margin_db` a kilometre off, less 6 dB a
  doubling, less the worst edge between, the ground read along the way and raised by the moon's curve as
  radio sees it (`fm_bend`), scored by knife-edge diffraction (ITU-R P.526), so a station fades in as you
  crest a rise. Seed 1234: 29.5 dB 800 m from the port; -16 dB 9 km off on the ground; 10.9 dB 9 km off and
  2.5 km up.
- **Its sound.** Over `fm_threshold_db` it quiets over `fm_quiet_db`; under, hiss takes it. No storm static,
  no anomaly crackle. Ground bounce fades it as the radio moves (`Fm.fade_db`), so near the threshold it
  flutters as you walk. Two within `fm_capture_db` fight. Through the converter it plays FM's full range,
  clear, while the AM dial and shortwave play up to `am_audio_hz` (5 kHz) (Radio upgrades vetted, below).
- **The converters' look** (`Dress._converter`): another maker's add-ons after 1960s car-radio FM converters,
  black enamel boxes bolted to the set's side, each with a chrome-rimmed bone face, small dial and needle, a
  knob, a chrome throw and its band's name; the FM one has a three-section whip, the shortwave one brass
  aerial and ground posts.
- **The deed** Line of Sight: hear an FM station come through quiet. **Not yet:** an FM set that plays wide.

### Shortwave and Tu's roar (built 2026-10-20)

- **The shortwave converter** (`sw_converter`), the FM converter's sibling, 0.6 kg, no power of its own; the radio's left
  side takes two mods. Late-game tech: found only among the colonial and skimmer eras' best, the deepest
  sockets of their sites.
- **The band** runs 2–30 MHz, the dial going on in kHz past the AM dial (`Shortwave`, `sw_notch_khz`, fine
  tuning 1 kHz): "Radio · 29.07 MHz". AM and shortwave share one `frequency`, each keeping its place
  (`am_khz`, `sw_khz`), so skirts and the jammer work unchanged. Nothing on the ground sends here.
- **Tu's roar** (`Shortwave.roar`): from 15 MHz, full from 21 (`tu_roar_khz`), wherever Tu is up. Tu storms
  only while Zan is near two points of its orbit (`tu_roar_phases`, `tu_roar_window`), as Io gates Jupiter's
  loudest storms, and while Tu's turn faces its source to Zan (`tu_roar_turn`): a timetable to learn. In a
  storm it comes in slow swells. Seed 1234 at the start, 22 MHz: 13 dB in a storm, silent out of one. The
  deed **Storm on Tu**: hear it.
- **Not yet:** Tu's "popcorn" bursts; the roar's own sound. Shortwave is for space; no ground stations
  (gonkhub, 2026-10-22).

### The antenna reel (built 2026-10-21; scrapped 2026-10-22)

*gonkhub, walking through the radio's upgrades, 2026-10-22: "scrap this."* The reel of aerial wire and its
deed, Long Wire, are gone; Radio upgrades vetted, below, has what changed.

### The antenna kite and the radio's modules (gonkhub, 2026-10-21; built)

*gonkhub: "The kite needs to be able to be connected to the top of the radio with a rope hook as its
connection point. The player can connect them using a cable or a strong cable ... a cable needs to be able to
first be run to a stake first and then to the kite ... we can just use the normal stake that's already in the
game ... I want you to give all of the upgrades effects. Make them functional, give them a purpose in the
world." Asked, gonkhub chose: the kite on its own reel of line, the cable as its lead; burnouts unless earthed,
the stake earthing it; the kite placed by the wind rather than flown by physics. The rope-hook kite won over
an earlier reel-flown one.* Numbers from the radio kit lab ([look/radio_kit](../../look/radio_kit/README.md)),
now in `tuning.tres` (`kite_*`).

- **The rig.** The radio's top has an **aerial clip** (socket kind `lead`), and so do a crystal set's tray
  and the kite's reel; no hook (Radio upgrades vetted, below). A cable's plug, plain or strong, fits a lead
  clip as it fits a port: one plug on the set, the other on the kite's reel, and the kite is the set's aerial
  on every band (`AntennaKite.find_rig`). A lead carries no power. Holding a plug at a **driven stake**,
  use passes the cable through the stake's ring or takes it off, one cable through set, stake and kite, its
  legs measured against its length (`Cable.route`). A snapped strong cable keeps its plugs but connects and
  earths nothing.
- **The kite** (`antenna_kite`, `AntennaKite`, `KiteLooks`): a delta 1.4 m across, shortwave violet with
  survey-orange chevrons and a copper dipole, on a drum of `kite_line_m` of line. Use it in a wind of
  `kite_lift_ms` or more and it goes up, paying out; use it again and it reels in. Placed by the wind: its
  line stands steeper in its best winds and pressed back past them, sagging, so on its full line in 9 m/s it
  flies about 90 m up (measured 87 m), and it sways. Under the lift wind it comes down. It keeps its place in
  the world as the world's origin shifts.
- **Height is signal:** on shortwave the kite adds about 10 dB a tenfold of height over the whip, to
  `kite_gain_db`, capped at `kite_gain_most` (1 is a satellite heard whole),
  so a satellite low over the horizon comes through that the bare terminals lose. On the AM dial it is a
  long wire hung high (`Radio.aerial_am`): what the set hears rises to `kite_am_most` by `kite_am_full_m`
  up, heard all ways round, so the rod's null is gone while it flies. On FM its height is the set's aerial's,
  less `kite_fm_feed_db` down its lead (`Radio.receive_fm`). Seed 1234: the Quartermaster 0.70 on an upright
  rod, 1.41 on the kite; Port Morgan's station 4.5 km off, -0.4 dB on the whip, 6.2 dB on the kite 86 m up
  (radio probe 78). The deed **Over the Horizon**: hear an FM station clear on a kite that the whip can't.
- **Static.** Flown high it gathers charge, little in clear air and fast in a front's outflow or a storm, and
  it raises the set's static (`kite_static`). Past `kite_arc` an arc may jump; it burns out or scorches one piece
  of the chain, any one alike: the kite's dipole, the lead, the converter the set hears it through (none on
  AM), or the set. A crack of sparks, a violet
  flash and a zap. **Its lead through a driven stake** dumps the charge to earth, so it never climbs to an arc
  (the deed **Grounded**). Unearthed in a 9 m/s breeze the charge arcs within minutes; staked it never does.
- **Wear,** as a sail's, faster past `kite_harm_ms`; a sandstorm tears it to rags in about 75 s. Its sail
  tears in its shader, and its dipole and edges glow as it charges.
- **The misc bay** on the radio's right side, over its power port, takes one module (`radio_bay`,
  `Dress._module`). Powered ones need the set's power (none on a crystal set):
  - **Bleed resistor:** leaks a kite's charge off (`kite_bleed_tau`), so a breeze never arcs it unearthed; a
    dust front outruns it.
  - **Valve preamp:** lifts everything heard `preamp_gain` times, so a far god lost in the hiss comes through.
  - **Static choke:** takes out all of a storm's interference: no storm static, anomaly crackle, garbling,
    cuts or sliding between the set and what it hears (`Radio.storm_along`). Other static (a jammer's, a
    kite's) at half, other garbling at 0.6, the signal at 0.8. Seed 1234, the Ledger through a thin storm:
    dirt 0.62 bare, 0.16 choked (radio probe 62).
  - **Wire logger:** writes out what comes in over the air: each phrase of a report, an advisory, a god's
    words or a distress call floats over the set as a subtitle while it's read, clean whatever the signal
    came through, and stays `logger_hold_s` after (`Radio._show_transcript`). The same size on screen near
    or far, over the set's whip and any dune between, out to 15 m. A crystal set can't run it (radio
    probes 63, 73). It no longer plays reports back.
  - **A headset's cable** (not a module): a cable's plug fits the bay, its other end a headset's jack (below).
  - **Solar lid:** `solar_w` of cells fill a switched-off set's battery by day, far less on Tu's light.
- **Found** on skimmer-era floors (the kite), colonial and First Kingdom shelves and relay mast cabinets
  (the modules). **High Wire:** hear a satellite clear on a kite flown 50 m up. Scenario `kite`. **Not
  yet:** the kite's pull on its reel; a drawn arc down the lead.

### Radio upgrades vetted (gonkhub, 2026-10-22)

*Walking through the radio's upgrades one by one. gonkhub: "make upgrades cost no additional power for
now," and the FM converter "should be a fairly easy to find midgame upgrade for the radio." Then: "just
let the fm converter have clear quality." On the shortwave converter: "If the satellite is directly
overhead, let the signal come through decently, sure"; "Late game tech upgrade. Should be rare or
restricted to late game areas"; keep the risk of a kite's arc burning it out; "drop the ground stations.
SW is for space stuff."*

- **No upgrade draws power** for now: the converters, valve preamp and wire logger carry no
  `draw_w` (they were 0.5, 0.5, 4 and 0.2 W). The powered ones still need a powered set, so a
  crystal set can't run them (radio probe 73).
- **The antenna reel is scrapped** ("scrap this"): its item, its deed Long Wire (the roster is 71), and
  the wire's gain. Shortwave hears on the bare terminals, better near overhead, or by a kite. Saves holding
  a reel wake with an antenna kite (`Catalog.RENAMED`; saves probe 47). The weather scenario and radio
  probes 13 and 14 lift the relay with a valve preamp in place of the reel's wire.
- **The FM converter is a midgame find:** First Kingdom shelves weight it 2, and skimmer-era shelves now
  hold it too, beside colonial shelves and relay mast cabinets.
- **FM plays clear:** through the converter FM keeps its full range; AM and shortwave stay narrow.
- **A satellite overhead on bare terminals:** from 60° up the converter's terminals alone hear more, to 0.6
  by 80° (`sw_bare_overhead`). Seed 1234: the deliveryship overhead 0.60, the windsock low 0.25 (radio
  probe 77). A wire or kite still does better.
- **The shortwave converter is late-game:** off skimmer shelves and relay mast cabinets, onto the colonial
  and skimmer eras' best tables, the deepest sockets.
- **No ground stations on shortwave:** the planned skip and dead zones are dropped.

*Then, on the kite: "If it's reasonable from a realism perspective to use the kite to amplify AM/FM signals,
then expand it to also be able to affect those frequencies"; "remove the hook from the setup. Allow a cable
to connect straight to the top of the radio"; "If an arc charge happens, pick a random equipment in the
chain. Only one piece is ever damaged"; and "There is another implementation of a kite from Hunter's
implementations yesterday.. we should act to consolidate approaches and keep things consistent."*

- **The kite on every band.** Realistic: a long wire hung high is the classic mediumwave aerial (Marconi's
  1901 transatlantic reception hung one from a kite), louder than a ferrite rod but without its null; on
  VHF, height is line of sight, though a long lead loses some at FM. So on AM it lifts what's heard to 2×
  and hears all ways round; on FM it lends the set its height, less 2 dB down the lead. On a moon 24 km
  round, 80 m of height takes Port Morgan's station from about 4 km to about 5.
- **No hook:** a cable plugs straight into the radio's top aerial clip; a crystal set's tray has one too,
  a crystal set on a long wire being what they were for. The `radio_top` mount and the hook's lead clip
  are gone. The kite patch never shipped, so no player save has a hook on a radio.
- **An arc hits one piece of the chain at random** (`AntennaKite.chain`), all alike.
- **Consolidating with the salvage kite** (Spaceport): open; Hunter's prototype isn't in the repository.
- **The bleed resistor stays as it is:** "a stake is stationary," so the bleed is the kite's protection on
  the move, as the stake is at camp.
- **The direction loop is scrapped** ("scrap this one"): the ferrite rod is the set's only direction
  finder. Saves holding one wake with a static choke (`Catalog.RENAMED`). Radio probe 61 went with it.
- **The static choke eliminates storm interference:** "have it eliminate ALL interference from storms.
  otherwise good." Its signal cost stays.
- **The wire logger gives a transcript:** "The wire logger should give a text transcript that shows as a
  subtitle floating above the radio." It replaces the logger's playback. Real Forward+ captures at 1.6, 6
  and 12 m checked it reads, clear of the whip, over a dune's lip.
- **The frequency counter is scrapped** ("scrap this one"): tuning stays by ear. Saves holding one wake
  with a valve preamp (`Catalog.RENAMED`). Radio probe 64 went with it.
- **The headset is an item of its own** (`headset`): "just a headset item, that can attach a cable. The
  other end of the cable can attach to a radio misc mod slot"; and "Common, easy to find upgrade." Two cups
  on a band, a jack on one. A cable, plain or strong, from its jack to a radio's misc bay carries no power
  (`Cable.SIGNAL_ONLY`); worn in the suit with its cable in, or in your hands, the set playing is in your ears
  from where it stands, no panning, the wind and storm 14 dB down (`headset_duck_db`), and a crystal set
  nearer and cleaner. The cable is the cord: walk past its length and a plug pulls out. On every era's
  shelves and in relay mast cabinets. Saves with the old jack module wake with a valve preamp. Radio probes
  65 and 67; saves probe 48 (worn, it survives a save).
- **Idea, not built:** "a better radio with more slots, possibly a chassis mounted large receiver," so the
  one misc bay stops forcing a choice between modules.

### The ferrite rod's null (built 2026-10-20)

- **The radio is its own direction finder** (`Radio.rod`): its rod lies along the set's width, or across
  your view while carried. On the AM dial a station comes in whole broadside until within about 15° of
  end-on (`rod_width`) it falls into the null (`rod_null`). Turning finds a station's line by its silence;
  the line runs both ways.
- **The night effect** (`Dial.by_sky`): a sky-wave station comes down from above and wanders, so its null is
  only `rod_night_null` deep: night bearings can't be trusted, as real direction finders found.
- **The deed** Null: turn a radio until a god you hear falls silent. **Not yet:** a sense antenna for which
  way along the line; no rod on shortwave or FM.

### The survey receiver (agreed and built 2026-10-20)

An early, cheaper set that hears only real ruin loot beacons: no music, gods, forecast or map, and no compass
bearing or distance. `SurveyReceiver` reuses the radio's physical controls and power contract: battery,
mounting, carrying, tuning, fine tuning and volume, with its draw, reach, a band `receiver_band_khz` either
side of the beacon's 530 kHz and its needle steps in the `receiver_*` fields.

- **Acquiring:** use powers it on and takes one real untaken beacon in its band and reach, kept through power
  and saves until it's invalid; taking the find or leaving range stops it, and nothing replaces it silently.
  A receiver saved on the old 1930 kHz beacon wakes on 530, as detuned as it was.
- **The loop:** turn the case, held, carried or on a deck: two opposite lobes move a coarse strength needle
  and the pulse's cadence and level (a quarter turn took one from 0.87 to 0.07), so you compare readings as
  you move. A soft static bed rises with detuning and dust. Off or a dead battery clears sound and needle.
- **Not a forecast set:** Console forecasts and the weather station's sleep clock don't count it. A shallow
  find. **The deed** Follow the Signal: arrive at an acquired beacon from `receiver_approach_m` or more away,
  carrying or holding it live.

## Stations

From Hunter's [storms, signals & sailing spec](../briefs/storms-signals-sailing-2026-10-18.md): a station is a
node with a place, a frequency, a range and what it says; its signal falls off with distance.

### Port Morgan Tower: the weather and the drone (gonkhub, 2026-10-21; built)

*gonkhub, before the bands rebuild: "the surveyor flyer's shortwave broadcast needs to inform the player of
when its flyover will occur"; "Let's just give Port Morgan a Surveyor schedule announcement every 5mins on an
FM channel. Port Morgan Control Tower can be an FM broadcast that we use for this and other worldbuilding
tracks"; "Remove the 'here now' announcement from the surveyor ... For its flight plan announcement, it should
report its current speed, altitude (fluff ...) and ETA to Port Morgan." The rebuild then combined the weather
station into it (The bands rebuilt).*

- **One FM station on the port's mast** (`Fm.TOWER`, `Radio._tower_air`), heard by line of sight, and
  repeated on shortwave by the relay. It reads the storm field at the tower (`Radio.tower_at`), 20 minutes
  ahead, every `radio_forecast_every`: the weather where the tower stands, not where the radio does. What it
  says, and when, is in Speech.
- **Clear Skies** (Hunter, 2026-10-18: a "'hold' transmission on the weather channel that plays during clear
  weather with nothing to report," "a feel good you have nothing to worry about sound that only plays under
  conditions when that is true"; "no storm for 20 minutes is basically impossible"): with no storm on the
  tower and none due within `radio_calm_minutes`, it plays Hunter's "Clear Skies" (`radio_clear_skies.ogg`)
  and says no weather; a storm coming breaks it off through static. Over six hours on three seeds a place's
  sky is clear about a quarter of the time, clear 5 minutes ahead 12–13%, 20 minutes ahead 0–1%.
- **The drone's schedule:** its altitude (wandering about its true 30 km, for flavour), its true speed
  and how long until it's over the port: the deed **Flight Plan**. Other worldbuilding tracks are to come.

### The Walker's feed (FM)

The spec: moon-wide, the strongest after the Ledger's; a dry log of bearings, wind readings and terrain, hard
to read but very useful, found by scanning. Its contact log records every signal it hears, indifferent to its
flock: a nomad praying to it is a bearing. As built it's an FM station from a mast on the Walker, heard only
near it as it walks, so its feed is the trail to it.

- **Its log:** an entry each `walker_log_every`, its survey, then its last `walker_contacts_kept` contacts,
  latest first.
  - **The survey log:** its leg (km walked), heading, the steady wind at its feet, the ground under it and
    its fix: true, and the weather far off on the Rim.
  - **The contact log:** when a nomad prayed, where the Walker stood and the bearing from there to the city,
    to a degree. A nomad prays once in `city_prayer_days`; each bearing passes within about 160 m of the city.
- **Taught** (below), it flags the nearest anomaly within `walker_flag_m`, and the tower adds an anomaly
  advisory.

### The Walker's quest (agreed 2026-10-19, Hunter: "perfect"; built)

The spec's quest line, keeping the rulings that the Walker walks alone, that finding it must never happen
early, and that teaching it takes evidence for each tell.

- **The Walker** (`game/radio/walker.gd`, `WalkerLooks`): Tilg's survey walker in the colonial style, an
  off-white chamfered hull with safety orange at its joints and unit 05 stencilled on its flank, a survey
  head with an amber lens strip, a bent mast with a dish and an anemometer. Six legs on a tripod gait;
  partly broken, its left rear leg snapped and dragged, the hull listing, a panel gone. Solid; it walks on
  at 1.5 m/s whatever is in its way.
- **Far early:** it walks the Rim, the great circle 90° from under Tu that the ring road follows, from the
  point farthest from where the run began (`Gods.place_walker`). Over 30 seeds and starts on days 3 to 30:
  never nearer than 39.8 km in the first ten days. A save keeps it. Past the skyline's hand-over it's a
  stand-in hidden by a storm between; at 1.2 km a sharp eye finds it.
- **Its port:** an orange-ringed data port; a cable from a Console uploads what the Console holds. Walking
  on, it pulls the cable taut and a plug pops out.
- **Noting bearings:** a Console with a radio tuned to the Walker notes each contact the log reads whole,
  once, in its log and as a line on its chart. Three that cross, none closer than `triangulate_degrees`,
  their crossings within `triangulate_m`, fix a place; on seed 1234 the six fix the city 153 m off.
- **The chart** (`game/devices/chart.gd`, a Console page): north up, rings every 10 km, the Rim, each bearing
  a line, the fix a ring and, once taught, the anomalies; under it the bearings, the fix and the evidence.
  It's what the one map's navigation filter will show ([Devices & mods](devices-and-mods.md)).
- **Evidence** (on a Console): each tell its deck witnesses through an anomaly: a compass on it 10° or more
  off north; a radio on it playing with the crackle a quarter deep or more; a shield on it loaded past a full
  storm's while its particle sensor reads ordinary sand. A save keeps it with the Console.
- **The teach** (`Console.upload`): plugged into the Walker, a Console holding all three teaches it; from
  then on every Console's map and chart ring each anomaly near, and its feed flags them (`World.taught`).
- **Deeds:** Triangulated, The Living City (seeing its lights), Taught (hidden). **Not this round:** taking
  the Walker (its core, body, data); pilgrimage and aggro; nomad reputation as a gate on reaching it; singing
  stones as evidence; the ghost relay.

### The living city

The spec: its chatter carries a few km, for its scouts; coded tones, no voices ("storm coming, tether in",
"city moving"), sometimes its coordinates as star positions. Its frequency is found by exploring (scratched
on a radio in the dead city), its codes learned by noticing what follows them.

- **The city** (`game/radio/city.gd`), seeded and stateless: on the far side, 105° to 160° from under Tu,
  moored `city_moored_days`, then a leg of `city_leg_m` away from Tu at `city_speed`, the storms' own pace.
  It doesn't read the storms to move, or it couldn't be pure; its chatter reads them.
- **Its chatter,** an FM station from the city's own mast, so line of sight sets how near you must be: a
  motif each `city_chatter_every`, three or four reed tones (high ¯, middle -, low _):
  - **storm coming** `¯ - _`: a storm reaches it within `city_warn_s`; first, over all;
  - **city moving** `_ - ¯`: under way;
  - **tether in** `_ _ - -`: a storm on it, moored;
  - **all clear** `- ¯ ¯ -`: clear air, none due, moored (rare: the far side storms most of the time);
  - **its position** `_ - ¯ - _ ¯ - ¯`, every fourth slot when calm, then the pole star's height over it (its
    latitude) and how far the stars have turned since its midnight (its longitude), each to a degree.
  Each tells the truth: 91 slots over a day and a half, every one so at the city. Reed tones made here
  (`make_city_motifs.py`, CC0), A minor pentatonic over 440 Hz to clear the speaker's high-pass.
- **Its music,** a second FM station beside the chatter, strings the motifs into a phrase every 1.6 s on a
  pentatonic scale, in an order the seed and the hour pick (`Radio._reed`).
- **Seeing it** (`CityLights`): at night within `city_heard_m`, lamps along its rafts, a turbine's red lamp at
  each hub, its shields' pale blue and its decks' glow, hidden by a storm; against the glow its rafts,
  turbines, domes and people in ink, never a face. Within `city_douse_m` its lights go out: it isn't found
  by walking up to it. Being found by it, its tether landing at camp, stays the nomad city ending.

### Stations agreed in lore, not built

- **The Walker and the Stoker** (agreed lore, 2026-10-20): friends from Halloran's survey work. Reports of
  reachable-in-principle heat torment the Stoker, which can't build the pipelines its quotas need; the Walker
  means no harm. The far-side heat ties this to the Eye and the destruction ending
  ([the lore](../world/lore-research.md#the-walker-and-the-stoker-surveys-of-unreachable-heat-agreed-2026-10-20)).
  The proposed quest has the Eye adopting the Stoker's priorities through packets you carry, keeping
  Starcom's intervention and the charges at every major vent cap. It isn't the anomaly-teaching quest.
- **The nomads' tones follow a thief** (agreed, session 5; [the
  vision](../vision.md#nomad-reputation-agreed-session-5-not-built)): steal from them and **their short-range
  radio tones follow you around, getting ruder.** Read as the city's coded tones turned against you, "ruder" a
  pattern to learn, not words. Not said: what ruder sounds like, how many steps, whether it recovers.
- **The ghost relay** (agreed, session 4, part 2; loose): a nomad relay still sending storm and water reports
  in Zan-Han-Mon slang long after its builders died
  ([the lore](../world/lore-research.md#the-decline-nomads-and-the-moving-city-agreed-session-4-part-2)).
  Read: its storm reports read the real field in the slang (Monward, Hanmen, Zanborn, the tu- prefix); its
  water reports wait for a water field; its frequency is a find. The loose radio ending, "the right
  frequencies to reach Tilg or the last town" ([the vision](../vision.md#landmarks-and-endings)), isn't
  designed.
- **Second-age broadcasts** ([endings and radio](../briefs/endings-and-radio-2026-10-17.md);
  [the lore](../world/lore-research.md#second-age-radio-and-its-priests-agreed-and-idea-endings-session)).
  *Agreed:* **debugging is ritual, kept word for word**; radio priest is a role inside each god's cult, so
  broadcasts sound like ritualised procedure (a "prayer" might be an old Tilg maintenance checklist), which
  the litanies build; the Ledger has the strongest signal, so whoever holds Mon controls the loudest voice
  on Zan. They air at reliable times and can serve as a sleep clock ([Survival](survival.md#sleep-proposed)).
- **Offstage states on the air** (agreed, session 4, part 3;
  [the lore](../world/lore-research.md#the-wars-end-the-wall-and-the-states-of-the-players-time-agreed-session-4-part-3)):
  the war, Varran and Daventry come only as faint radio. **Varran** is heard only from the orbital station;
  the Varran settler's radio is "tuned to home frequencies it can't hear from the surface." **Daventry:**
  "hearing a Daventry broadcast hints they can hear you," its loudness rising with dead-lane transmissions
  ([Profile & saves](profile-and-saves.md#ending-flags-proposed)).

## Speech

*Hunter chose the bundled voice: the same public-domain LJ Speech voice on every computer, no system TTS and
no transcript in the view ("AI voice sounds good").* **Playtest (Hunter, 2026-10-19):** "Voice is better,
just make the sentences shorter still. and probably announce less often." Decided: two to four words a
sentence, and a report spoken only when it has news: a storm newly due or arriving, or its clearing. A calm
repeat stays unspoken.

- **Port Morgan Tower** reads its short report (`Radio.report`) of the tower's sky when you tune in to news
  and whenever its news changes, clear → storm coming → storm here → clear: "Storm coming. From the
  north-east. Four minutes." / "Storm here. Clearing, ten minutes." / "All clear. Next storm, twenty
  minutes." Tuned in to calm, Clear Skies plays and no weather is said. There is no timed report.
- **Advisories** (`game/radio/advisories.gd`): a fast or a large sandstorm breaks in once per event, in short
  sentences from the tower's place: "Weather advisory. Fast sandstorm. From the north. Bearing …, …
  kilometres from the tower. In four minutes. Lasting … minutes. Take shelter." (`advisory_fast_ms`,
  `advisory_long_minutes`, `advisory_look_minutes`, from the upper tenth of a twelve-seed survey). Once the
  Walker's taught, an anomalous storm within `walker_flag_m` of the tower gets one too, ending "Keep clear."
  A forecast never invents an anomaly warning.
- **The drone's schedule:** "Drone. Altitude 30000. Speed …. Port Morgan, two minutes.", read
  as you tune in and once for each new pass over the port.
- **A god, and the Walker's log,** read their words when you tune in, and again only when they change, at
  most once per `radio_report_every`; an unchanged line is never repeated. Outside its window a god reads its
  litany's current line once as you tune in, then only its tones sound. A god's song doesn't silence its
  words. A **beacon's** bearing works like a god's words.
- **From the set:** each radio's reader plays from its middle, or as carried, through its knob, speaker filter
  and own interference chain. It speaks only while the signal reaches you, and reads whole: interference
  roughens the sound but never drops words. An ordinary reading waits for the one playing; an advisory breaks
  in; a new station clears the last one's queue. Options' Radio voice stops all speech. A Console's own
  announcements ("Battery low.", "Battery critical.") use full recordings and skip over-air interference and
  station voices.
- **Station voices** (Hunter: "let's get some variety in the voice we use! match the lore"): each speaking
  station has its own machine treatment of the same voice, pitch, cadence and speech-only EQ on the radio's
  own bus (`radio_voice_profiles`), not new actors: Mother Cistern warmer and slower, the Quartermaster
  clipped and commanding, the Ledger lower and measured, the Almanac brisk, the Stoker urgent and metallic,
  the beacon its own. The tower, the Walker and the Console keep the plain voice; the Eye stays silent; the
  living city stays coded tones. Every profile stayed intelligible to speech recognition, without clipping
  (`look/radio_voices/record.tscn`).
- **The words** (`RadioSpeech`): full recorded phrases where they exist, otherwise sentences composed from one
  QOA-compressed word bank (`assets/audio/voice/word_bank.res`, a clip per word), rendered by `make_words.py`
  and packed by `pack_words.gd` from a hand-kept list (`assets/audio/voice/words.txt`). Numbers are exact,
  assembled from recorded words; an unknown name is spelled out, never dropped. As built (2026-10-22): 484
  entries, 3.1 MB on disk (the uncompressed PCM bank it replaced was 24.4 MB); it loads in about 10 ms when a
  set is made, and a word's first use costs about 1 µs.

## Satellites

*The satellites' names, makers and eras are gonkhub's and **loose lore until Hunter formalises them**.* So is
his retcon (2026-10-21: "all the satellites are colonial era in age"): StarCom and Frontier Ag are colonial
makers, babel is Port Morgan's spectrum guard still jamming unlicensed traffic, the cinder a Halloran ore tug,
the ghost on no registry.

*gonkhub, 2026-10-19: "Let's have many satellites orbiting the moon, each with different broadcasts on
different frequency ranges." "Most broadcasts should be cosmetic ... Many ambient tracks will be tied to some
environmental factor ... like an LFO." "Each satellite in orbit needs to be visually distinct." "Give the
remaining satellites outside the formation highly irregular orbits/behaviors." 2026-10-21: "we almost
certainly don't need as many satellites as we currently have. Put them back on unique and variable orbits,
rolling back to '2 in the sky at once' rule"; then "scrap tollgate, sounder, and lullaby."*

**The relay** (Hunter, 2026-10-18: "Tie the existing music channel to an orbiting satellite, loosely simulate
this satellite's position in orbit and give it interference just like the other freqs based on it's
simulated position," and "Make the satellite visible in the night sky if it's overhead"; and "The music
satellite should move faster than the other stars, to create a noticeable parallax effect"): an old colonial
relay. The bands session hung it at L1; the bands rebuild has it repeat Port Morgan Tower on shortwave rather
than carry the music (Open questions).

Eleven are in the sky (`ROSTER` in `game/radio/constellation.gd`): the relay at L1 and the Pendulum at L2;
the lantern round Tu, never seen; and eight crossing the sky on orbits of their own: the drone, the
ghost, the cinder, the sextant, the windsock, the choir, babel and the metronome. A radio with a shortwave
converter hears each while it's up and on the air, through the storm on the way, all at once (`SkyVoices`).

| Satellite | Maker | Band, kHz | Looks | Orbit | Sound | Turned by |
|---|---|---|---|---|---|---|
| The relay | colonial | 7250 | white point, glinting | hung at L1 beside Tu, a halo 0.9 radii across, 10 min | Port Morgan Tower, repeated | a slow tumble: its glint |
| The drone | Frontier Ag | 14200–14300 | the modelled H-shaped craft | 30 km up, 7.95 min, over Port Morgan every lap, its route swinging 37° a lap | its own (`radio_sat_drone.ogg`) | pitch by the temperature; tone by how high it stands |
| The Pendulum | StarCom | 10000 exactly (a time signal, as WWV's is) | cyan cross | hung at L2 over the far side's middle, on a halo | a ping, pulsed | its tick quickening toward the eclipse |
| The lantern | StarCom | 21500–21600 | never seen | round Tu, 60 radii off, 11 min | the day song, slowed | faint; heard only on Zan's side of Tu, clearest straight between |
| The sextant | StarCom | 29030–29050 | pale blue point | ellipse (0.35), 1.8 radii, 26.6 min | a quick double ping | pitch by how high it stands |
| The windsock | StarCom | 29060–29080 | a tiny green ring (gonkhub, 2026-10-21: "much, much smaller") | circle, 0.9 radii, 14.9 min | the wind | loudness and tone by the wind; grit by a storm |
| The choir | colonial | 29090–29110 | lavender pair | circle, 1.4 radii, 21.1 min | its own (`radio_sat_choir.ogg`) | pitch sinking with the sun; tone drifting |
| Babel | Port Morgan's spectrum guard | 29120–29150 | red diamond, blinking | ellipse (0.2), 1.2 radii, 18.5 min | tones, chirped | pulse and pitch wandering; grit by an anomaly; jams |
| The ghost | on no registry | 3200–3500 | dim blue ring, flashing | wild ellipse (0.75), 0.75 to 11 radii, 23 min | its own (`radio_sat_ghost.ogg`) | in fits, hopping its band, tumbling; loudest in a storm; lower far out |
| The cinder | a Halloran ore tug | 7100–7175 | large ember point | decaying: sinks 1.6 radii over 5 laps of 4.4 min, then burns back up | gonkhub's "Cinder" (`radio_sat_cinder.ogg`) | brighter, louder and higher as it sinks; spinning |
| The metronome | Frontier Ag | 29220–29240 | mint bar | near-polar circle, 1.0 radii, 16.1 min | gonkhub's "satellite1" (`radio_sat_metronome.ogg`, a 2 s loop) | pitch rising a little with the sun; tone by how high it stands |

- **About two in the sky.** The crossing orbits differ in height, lap (by Kepler's third law), tilt and plane
  swing. Over 8 seeds, 15 places and two days, 1.90 of the eight are up at once on average: none 13.9% of
  the time, one 26.7%, two 28.9%, three 19.7%, four or more 10.8%; on the near side the relay is up besides.
  A satellite is heard only while it's up, faint and chewed up low over the horizon.
- **The Lagrange points.** A tidally locked moon has no stationary orbit, so the answer is halo orbits: L1,
  `lagrange_radii` toward Tu, hangs beside Tu in the near side's sky; L2, as far behind, over the observatory,
  as Queqiao hangs for Chang'e 4; each loops on a halo (`halo_radii`, `halo_minutes`). The Rim sees both, low
  on opposite horizons. The relay never sets on the near side; the Pendulum is heard only from the far side
  and the Rim.
- **The irregular ones** fly ellipses by Kepler's equation (`Satellite.at`), their planes and perigees
  swinging each lap (`precess`, `apsides`), looser than a real moon's pull; their Doppler follows how fast
  each nears or draws away. **The ghost** is on the air in fits, about 30% of the time, its carrier hopping
  every 14 to 27 s, tumbling about every 3 s. **The cinder** sinks over five laps (`decay`), then fires,
  flaring six times as bright for four seconds (`Constellation.burning`), and climbs. **Babel jams:** while
  up it sprays static round its carrier over 60 kHz (`Constellation.jamming`), burying its neighbours; the
  five at 29 MHz sit 30 kHz apart, so their skirts overlap.
- **The lantern** (gonkhub, 2026-10-19: "a satellite orbiting Tu, its broadcast accessible when it is on the
  side of the planet facing Zan. Not visible though"): StarCom's Tu survey probe, on the air only on Zan's
  side of Tu and where Tu is up, at 0.6 strength, clearest straight between (the LFO source `facing`).
- **Brighter near:** each looks as bright as the square of its nearness against its mean distance, and a
  little bigger (`Satellite.nearness`). **By day** (gonkhub, 2026-10-20: "the closest and brightest
  satellites should still be visible during the daytime"): one shows once it looks bright enough
  (`SkyView.DAY_FROM`, `DAY_FULL`, `DAY_BOOST`): the ghost at perigee, the cinder sinking low, the
  drone always.
- **The LFOs** map a source onto a target. Sources: the temperature, the sun, night, the wind, the time to the
  eclipse, the storm, an anomaly, how high it stands in your sky, its height in its orbit, facing, a slow
  drift. Targets: pitch, loudness, tone, grit, tremolo and pulse rate, on the satellite's own bus. The
  drone, the Pendulum and the windsock are useful by ear; the rest flavour or gibberish. Most sounds
  are placeholders, one line each in the roster (`sound.track`, `sound.db`).
- **gonkhub's tracks** ("Cinder", "satellite1" and the tunnel ambience) are made by gonkhub for Desert, used
  with his permission ([credits](../../assets/audio/CREDITS.md)). Look-test: `look/satellites`. **Not
  yet:** gonkhub's sounds for the rest; satellites carrying spoken or encoded data.

### The drone

*gonkhub, 2026-10-21: "The Surveyor flying craft needs to be renamed. Change all references in docs or
commands/code to call it deliveryship" (Hunter: "the drone for now", so it is the drone in what you hear and read; the code keeps `deliveryship`). Frontier Ag's
craft. gonkhub, 2026-10-19: "an extremely low orbiting object. Low enough that its silhouette is partially
visible against its own lighting, and it's much larger in the night sky than the others ... moving slowly
near the horizon then quickly crossing the center of the sky"; 2026-10-20: "make it H shaped," "a thin
connecting hull attached to two sharp uprights"; "remove the surveyor's lights"; "ship appearance still too
flat. Needs to be modeled out fully this low to the ground, especially with how clearly it can be seen in
the daytime"; and of its height, "6km is better", then 2026-10-21: "needs to be much much higher in the air";
and "Update its flight path to ensure it always passes over Port Morgan, letting its path rotate around the
moon otherwise."*

- **Its flight:** 30 km up, a lap in 7.95 minutes, about 710 m/s, crossing overhead at roughly 1.4°/s (worked
  out, not measured). A run begins with it passing over the start. The old drone and surveyor dev commands
  and scenario names still reach it.
- **Its route:** a great circle through Port Morgan, flown on the moon rather than among the stars
  (`Satellite._through`), its plane swinging 37° a lap round the port so its track sweeps every place in
  time (`Satellite.until_through`: when it's next over the port). It's above the horizon within about 27 km
  of its track. Its care-package cannon is [Salvage's](salvage-and-ruins.md).
- **Its model** (`DeliveryshipLooks`, drawn by `Deliveryship` from `SkyView`): the H, two faceted nacelles
  sharp at both ends, survey lenses under each keel, a fin and dome on top, tanks outboard; between them a
  ribbed spine with trusses, four solar arrays, an uplink dish and the cannon, a drum ringed with packages,
  its muzzle flashing as it fires. No lights of its own: by night a shadow blotting out the stars, by day a
  dusky H.
- **How it's drawn:** at its true angular size inside the camera's reach, belly to Zan's centre and nose along
  its track; `deliveryship_scale` makes it about 940 m tip to tip, under 2° across overhead from 30 km. An
  overlay (`deliveryship.gdshader`) adds the sand's light on its belly, the sky's on its sides and the dust
  along the real line of sight, crisp overhead and pale low down. Its depth against the ground is
  [World & terrain's](world-and-terrain.md#combined-surface-sky-and-atmosphere-acceptance-2026-10-21).
- **Its cost:** a far mesh under 260 px across (3,222 triangles) adds 0.7% to a ground-view frame's
  primitives, a near one over 320 px (13,304) 2.9%. It casts no shadow.

## Sound

Everything that matters can be heard, so you can read the world by ear:

- **The storm:** a roar that rises before the wall arrives, and is muffled inside the shield.
- **The wind:** always present, with its strength audible, and humming in taut ropes.
- **Rope:** a creak that rises with load, and the crack of a snap.
- **The shield:** boot, hum and shutdown, and a hum that sags when power runs low.
- **You:** footsteps in sand, sliding down slip faces, the board's hover hum.
- **Parts:** the clunk of a snap, and clanks when things knock together.

**Kept from Sand Game:** the radio tracks and the "this isn't a beach, this is a desert!" clip; the storm and
desert-wind recordings; the shield's boot, sustain and power-down; the rope creak, metal clanks, static and
radio interference; the sand footsteps and slide, and the planter's hover hum.

**As built (2026-10-16):**
- **Soft hands:** fitting a part is a soft seat with a small click, taking one out its lighter match, a
  line's end tied on a creak; taking from the sand a sift, putting down or throwing a soft crunch, a throw a
  whoosh. **Softer suit:** what you carry goes in and out as a pouch does, the inventory with a cloth
  rustle, the quietest things in the world.
- **New:** a stake driven in, water poured, a crop picked, the harvester's food, the condenser's drip, soft
  chimes for camp-range warnings, the board's ride pitched by speed and a tick in its last minute of
  battery. The menus click very quietly.
- **The mix:** buses World (and Weather inside it, whose low-pass is the bubble's muffle) and UI, under a
  limiter on Master, whose volume the options set; the main menu mutes World only. Every file is levelled to
  how loud it's heard (the table in `assets/audio/CREDITS.md`). The radio is in the world, not the weather,
  so a bubble never muffles it. Every sound's file is named once, in `game/core/sounds.gd`.
- **Not yet:** a turbine's whir by its speed, and clanks when things knock together.

### Distant phenomena (agreed, 2026-10-18 spec; built)

Gas-pocket dust plumes and far volcano plumes stay distant spectacles, never close enough to hurt
([spec](../briefs/storms-signals-sailing-2026-10-18.md)): a gentle rumble by distance and no camera shake,
arriving after you see it as thunder does after lightning (the delay sells the scale), losing its high end
with distance, and a big plume marking a vent's direction to steer by. Built as `Rumbles`
(`game/weather/rumbles.gd`; the plumes are [Wind & storms](wind-and-storms.md#plumes)'):

- **A boom at a burst's onset,** heard within 45 km, as late as sound takes to come that far: sqrt(γRT/M) for
  nitrogen at the air's temperature where you stand, about 353 m/s at 27 °C. A burst 10 km off is heard half
  a minute after its column starts up.
- **Quieter and duller with distance,** 6 dB a doubling and never louder than its file (felt, not loud),
  through its own low-pass (the Booms bus), since air takes a sound's high end first.
- **Its low end rolls on** (Hunter's playtest, 2026-10-19: "lean into the rumble more"): 16 s of low rumble
  under each boom, surging back off the rift's walls and the dunes, lower and longer with distance.
- **From its way,** so it's heard from the vent's bearing as the column is seen. **A live vent's roar**
  within 2.5 km, harder as it vents harder (the Vents bus). Both buses run through Weather, so a bubble
  muffles them. Sounds made here (`make_rumble_sounds.py`, CC0). From 12 km a boom comes 36.97 s late, 9 dB
  quieter and under half as bright as from 3 km.

## Atmosphere

- **Clear skies:** big, lonely views, heat shimmer at the horizon, and quiet apart from the wind.
- **Inside a storm:** the world outside the bubble is dark and roaring, the camp is lit warm inside it, and
  the radio crackles.
- **The day:** a 20-minute cycle of scorching noon, long shadows, a freezing night under the stars, and frost
  glittering at dawn (see the water rhythm in Survival). On the near side Tu hangs over it all, and once a day
  it eclipses the sun ([the moon](../world/the-moon.md#day-length)). The day and night music follow the sun
  where you are, so they change at your local sunrise and sunset, and the eclipse's dark is still the day.

## Rules

1. **Broadcasts read the real systems.** Weather forecasts sample the storm field, and loot beacons point at
   finds the world will actually generate. The radio may crackle, but it never makes things up.
2. **A beacon's target is guaranteed.** It's decided from the seed when you tune in, and the chunk it sits in
   is certain to contain it when it loads, whatever the weather there.
3. **Sound reads the felt weather.** Storm and wind sounds muffle inside a shield by the same shelter test
   everything else uses.
4. **The important things are audible:** rope load, shield power, a storm on its way.
5. **A set is cheap to leave playing.** It reads the gods, the sky, the weather and the ground every physics
   tick on the main thread, so each lookup that changes slowly is worked out only when it changes: the dial's
   carriers once a moon day, the Walker's log once a second, a line's distortion once a slice, the jammer once
   a tick, and the sky not at all on the AM dial, under the ceiling. A tick's mean cost, measured
   2026-10-22 on the shared dev machine under load: on Port Morgan Tower 530 µs, on a far god 397, on
   shortwave under a satellite 625 (on the weather 1340 and a god 969 before these were cached). Reading
   the forecast, every `radio_forecast_every`, costs about 250 µs more once. Probe 76 holds it under 900 µs.

## Skeleton version

- A radio with three channels: music (the two tracks, by day and by night), weather, and a loot beacon.
  Weather and beacon readouts can be crude.
- Static that rises with the storm.
- Storm roar muffled inside the shield, rope creak, shield sounds and footsteps.
- The probes below, all passing.

## Full version

- **More music channels,** with more tracks from Hunter.
- **Lore channels and signal decoding, and the maybe-voice;** the ghost relay, second-age broadcasts and
  faint offstage states (Stations) are more.
- **Frequencies as finds,** and the rest of the bands' parts.
- **The storm's approach staged in sound,** to match the wall.
- **The look of both moods,** shaped by Hunter's vision as we go.

## Probes

One real failure each, in `probes/radio/`:

- **Honest stations:** forecasts match the storm field (1); beacons lead to finds (2); each god in its band
  and home, useful only in its window (6, 8, 9, 22, 24); the living city's motifs and fixes tell the truth
  (25–28); litanies keep their shape (29); each band holds its own stations (68).
- **What you hear:** static with the storm, only when nothing plays (4, 18); storms garble and cut (7, 15,
  19); day and night music, the relay at L1 (5, 13, 17); Clear Skies and the Stoker (11, 12, 14); the Eye's
  drones (16); skirts overlap (31); the jammer and the burn (37); FM line of sight and capture (42, 48);
  Tu's roar (50); the rod's null (52); a satellite overhead on bare terminals (77).
- **Speech:** only with news, short sentences, advisories once (14); every phrase recorded, from the set's
  own speaker (23); a god's and a beacon's words reach speech (39); station voices keep their timing (46);
  the tower's drone schedule (47); a new FM station clears the old one's words (72).
- **The set in your hands:** volume (10), tuning and the close view (20, 21), carried in your ears (30),
  marks and lamps (33, 36), the survey receiver's controls (41), the printed dial (74).
- **Tiers and modules:** the crystal set and its headset (67); each misc-bay module (59, 60, 62, 63, 65, 66); powered modules
  need power (73).
- **The kite:** it flies on the wind (55); one cable through the stake (56); unearthed it burns out (57); a
  sandstorm shreds it (58); it follows the world's origin (69); a broken lead can't earth it (70); it's the
  set's aerial on AM and FM (78).
- **The sky:** satellites distinct and heard (32), about two up at once (34), the lantern and the
  drone (38).
- **Frame:** sets don't share effects (40); a song keeps its occurrence and catches up after a glitch (43,
  44); an old survey receiver keeps its tuning (71); the run's marks survive a save;
  the tick stays cheap on every band (76, runs alone).

## Out of scope

- Voice acting for characters. There are no NPCs.

## Open questions

- **The weather station: the Walker's feed, or Port Morgan Tower?** Hunter, 2026-10-18: "use the weather god
  for the weather station," and the weather station was agreed as the Walker's feed. gonkhub's bands rebuild
  (2026-10-21) combined it into Port Morgan Tower on FM, reporting from the tower, with the Walker an FM
  station heard only near it; it also moved the music off the relay Hunter tied it to. Built as gonkhub's;
  Hunter to confirm or reverse.
- **The craft's name.** *Decided:* the drone (Hunter: "the drone for now"), heard and read so; gonkhub's
  rename to "deliveryship" (2026-10-21) stays the code's id (`deliveryship`, `Deliveryship`) until Hunter
  names it for good.
- **How are broadcasts delivered?** *Answered:* sound only (gonkhub, 2026-10-19), in the bundled voice with a
  machine treatment per station, and in tones (Speech).
- **How far does a radio reach, and how much does an antenna add?** A beacon is heard from 3 km. Under the
  ceiling a bigger antenna adds little, since the world's noise sets the floor; above it an antenna is gain
  (the kite), and the price of gain is aim.
- **Do religious broadcasts have a voice?** Left open: whether they "still have a voice or are just tones and
  numbers," and whether the Ledger still broadcasts. *Answered for the gods:* they are on the air and speak,
  by Hunter's call. Open: whether a second-age broadcast is a god's or its priests'.
- **When the broadcasts air.** The session: they "still air at reliable times," so they can serve as clocks
  ([Survival](survival.md#sleep-proposed)). Here the gods' windows keep the eclipse, dawn and the hot hours,
  and a litany repeats on a fixed round. Not said: what airs as a clock, and whether it's a found channel.
- **How the radio reaches the Console's screen.** A radio stuck anywhere on a Console's deck gives it the
  forecast, and nothing is written in the view. Not said what of a broadcast the screen shows.
- **The gods on the air against "no link."** The lore: the gods "speak only through terminals" and "have no
  link to each other any more"; the Launch ending needs "bridging Mon and Han across open desert." Session 4,
  part 5: gods "rarely reach each other," through a repaired Starcom, the Walker's route, rare storm windows
  with "fragments of gods arguing" (back burner) and dispatches you carry
  ([the lore](../world/lore-research.md#dispatches-how-gods-talk-agreed-session-4-part-5)). *Ruled by Hunter,
  session 5 (2026-10-18):* the gods have links (Mother Cistern can switch Mitchell off), so "no link" reads as
  "most links lost." Not said what the bridge adds if a god is already on the air.
- **Ritual text against rule 1.** "Broadcasts read the real systems," yet the proposed voices include Mother
  Cistern's calls "tied to rations and rain" when it has never rained, and the Quartermaster's
  "authentication challenge nobody can answer." Not said whether these are real documents or invented ritual.
- **The Walker's bearings against "never early."** *Answered by its route:* it starts far and stays far for
  the first ten days or more, and its FM feed is heard only near it.
- **A plant the radio hears, and a radio that carries better in some storms** (session 4, part 4; direction):
  "with a console nearby the radio picks up faint patterns" from quietbloom
  ([Farming](farming.md#each-crop-ancestor-engineering-drift-and-hooks-agreed)), and "the radio carries
  better in some storms" ([Wind & storms](wind-and-storms.md#storm-only-mechanics-back-burner), back burner).
  Not said what a pattern sounds like, whether it needs the Console, or which storms carry better.
