# Sounds: sources, licences and levels

Every path is in `game/core/sounds.gd`. Each file is levelled to how loud it's heard
played at 0 dB: one-shots by their loudest 400 ms (momentary LUFS), loops by their
integrated loudness, peaks never past -6 dBTP. A hard limiter on Master holds -1 dB.

**Sources**
- **Sand Game:** Hunter's own earlier game; its recordings are on the `archive`
  branch under `audio/`.
- **Kenney:** [kenney.nl](https://kenney.nl) packs "RPG Audio", "Interface Sounds"
  and "Impact Sounds", all CC0 1.0 (public domain); credit is optional and given here.
- **Hunter's own music:** tracks Hunter made for this game (2026-10-18).
- **Made here:** made for this game with Python and ffmpeg; no third-party audio. CC0.

| File | What it is | Made from | Licence | Heard at | Peak |
|---|---|---|---|---|---|
| storm.ogg | the storm's roar | Sand Game `object_sandstorm.wav`, its harsh top eased | Sand Game | -20 LUFS full, -32 in a bubble | -9 |
| wind.ogg | the desert wind | Sand Game `ambient_desertwind.wav` | Sand Game | -30 LUFS at a gale | -11 |
| clang.ogg | metal a storm has just laid bare, banging on the wind, heard through the dust | Sand Game `object_metal_clank-001.wav`, mono, its ring kept, under two short echoes | Sand Game | -19 at 20 m | -7 |
| step_a–f.ogg | footsteps in sand | Sand Game's sand footsteps | Sand Game | -36 walking, -32 sprinting | -8 to -17 |
| slide.ogg | sliding down a slip face | Sand Game `player_slide.wav` | Sand Game | -30 at full | -16 |
| impact.ogg | a hard landing | Sand Game `player_impact1.wav` | Sand Game | -28 hardest | -8 |
| seat_a.ogg, seat_b.ogg | fitting a part or mod | Sand Game `object_metal_clank-005`/`-002`, ring cut off, under Kenney Interface `click_001`/`click_003` | Sand Game + CC0 | -30 | -11, -16 |
| unseat.ogg | taking a part out | Sand Game `object_metal_clank-005`, higher, after Kenney Interface `click_005` | Sand Game + CC0 | -32 | -14 |
| refuse.ogg | take or use refused: a slot full, a tray in the way, no room | Sand Game `object_metal_clank-007`, lowered to 0.6, its ring dulled under 1.1 kHz and cut to a 0.28 s knock | Sand Game | -36 | -21 |
| tie.ogg | a line's end tied on | a creak from Sand Game `rope_creak_ambient-001.mp3` | Sand Game | -35 | -12 |
| reel.ogg | a notch of line drawn hand over hand, lower paid out | a creak from Sand Game `rope_creak_ambient-001.mp3` (at 11.65 s), its low end cut | Sand Game | -38 | -14 |
| creak.ogg | taut rope | Sand Game `rope_creak_ambient-001.mp3` | Sand Game | -27 at full strain | -3 |
| hum.ogg | the tug toward a socket | Sand Game `object_bubbleplanter_hover.wav` | Sand Game | -36 at a full tug | -23 |
| pouch_in.ogg, pouch_out.ogg | into and out of the suit's slots | Kenney RPG Audio `cloth3`, `cloth1`, softened | CC0 | -38 | -18, -16 |
| bag_open.ogg, bag_close.ogg | the inventory opening and closing | Kenney RPG Audio `clothBelt`, `clothBelt2`, softened | CC0 | -41, -40 | -19 |
| sand_take.ogg | taking something off the sand | Sand Game `snow_footstep.wav`, softened | Sand Game | -36 | -23 |
| sand_put.ogg | something landing on the sand | Kenney Impact `footstep_snow_002` | CC0 | -34 at most | -15 |
| throw.ogg | a throw | made here: a sweep of noise | CC0 | -34 | -20 |
| stake.ogg | a stake driven in | Kenney Impact `impactSoft_heavy_001` and `footstep_snow_001` | CC0 | -30 | -12 |
| pour.ogg | water poured into a planter | made here: bubbles over a trickle | CC0 | -32 | -20 |
| pick.ogg | picking a crop | Sand Game `cartoon_pop-001.mp3`, softened, with Kenney RPG Audio `cloth4` | Sand Game + CC0 | -34 | -13 |
| food_drop.ogg | the harvester's food landing on you | Kenney Impact `impactSoft_medium_001` and RPG Audio `cloth2` | CC0 | -36 | -16 |
| drip_a.ogg, drip_b.ogg | the condenser's drip | made here: water drops | CC0 | -40 at 2 m | -24 |
| chime_first/last/lost.ogg | the camp-range warnings | made here: soft bell notes | CC0 | -32, -30, -30 | -21 to -24 |
| hover.ogg | the board's ride | Sand Game `object_bubbleplanter_hover.wav`, cut to a seamless loop | Sand Game | -34 | -21 |
| board_on.ogg, board_off.ogg | getting on and off the board; a hover tray lifting off and settling | made here: a soft rising and falling hum | CC0 | -32 | -19, -21 |
| shield_boot/hum/down.ogg | the shield | Sand Game `object_shield-boot`, `-sustain`, `-powerdown` | Sand Game | -26, -49 (the hum played 15 dB down), -28 at 4 m | -12, -22, -12 |
| radio_day.ogg | the radio's music by day, "Sandy Andy" | Sand Game `object_radio_sandy_andy.wav`, mono | Sand Game | -28 LUFS at 3 m | -13 |
| radio_night.ogg | the radio's music by night, "Waiting on the Sun" | Sand Game `object_radio_waiting_on_the_sun.wav`, mono, its silent lead-in cut | Sand Game | -28 at 3 m | -14 |
| radio_static.ogg | the radio's static, as loud as it gets in a storm | Sand Game `static.mp3` with `object_radio_interference.wav` through it, cut to a seamless loop | Sand Game | -33 at 3 m | -14 |
| radio_tune.ogg | the dial turning between stations | half a second of the same two | Sand Game | -32 | -16 |
| radio_ping.ogg | a beacon's ping | made here: a soft high note | CC0 | -34 | -21 |
| radio_tones.ogg | the weather station's tones before a reading | made here: three falling notes | CC0 | -36 | -25 |
| radio_clear_skies.ogg | the weather station's hold music, "Clear Skies", while there's nothing to report | Hunter's `A-Mx-ClearSkies.wav`, mono, levelled to the music, 50 ms fades for a seamless loop | Hunter's own | about the music's, peak-limited | -6 |
| radio_stoker.ogg | the Stoker's furnace song on its frequency | Hunter's `modsynthpatch.wav` from 11:15 to 12:00, mono, peaks at the clear-skies song's (louder than the music, by Hunter's ear), 50 ms fades | Hunter's own | about -18 at 3 m | -6 |
| radio_eye.ogg | the Eye's drone, now and then on its frequency | Hunter's `A-Mx-Drone.wav`, mono, levelled to the music, 0.5 s fades | Hunter's own | -28 at 3 m | -9 |
| menu_move/confirm/back.ogg | the menus | Kenney Interface `click_002`, `select_002`, `back_002` | CC0 | -49, -40, -43 | -21, -16, -19 |
| menu_theme.ogg | the main menu's theme, "Salt" | Hunter's `A-Mx-salt.wav`, stereo, levelled to about -20 dBFS, 20 ms fades for a seamless loop | Hunter's own | about -20 LUFS, on the UI bus | -5 |
| boom.ogg | a vent's burst or a gas pocket's blowout, from far off | made here: a short thump of air over a falling 42 Hz drop, then the blast rolling back duller nine times and a long low tail | CC0 | -18.5 (its loudest 400 ms); played by distance, -2 dB at a kilometre, 6 dB less each doubling, and low-passed | -6 |
| vent_roar.ogg | a live vent's steady roar, near | made here: brown noise under 260 Hz breathing over its 7 s, a little hiss over it, looped | CC0 | -29 at 150 m seeping | -6 |

Scrapping's sounds are made here, numpy only, by `make_scrap_sounds.py` (CC0), as WAV. Their
level is their loudest 400 ms unweighted, an estimate short of LUFS, with the voice's offset in
the game:

| File | What it is | Made from | Licence | Heard at | Peak |
|---|---|---|---|---|---|
| cutter.wav | the heat cutter firing, looped | made here: a torch's roar and hiss over a hum, crackling | CC0 | about -31 at 2 m | -12 |
| plate_free.wav | a plate coming free | made here: a groan of metal and the snap of the last weld | CC0 | about -29 at 3 m | -9 |
| plate_land.wav | a plate landing | made here: a dull clang of uneven partials and a thud | CC0 | about -28 at 3 m | -8 |
| arc_loop.wav | a live capacitor bank, looped | made here: a mains buzz and the crackle of a leak | CC0 | about -41 at 1.2 m | -14 |
| zap.wav | a shock, a bank shorted | made here: a discharge's crack and a falling buzz | CC0 | about -29 | -6 |
| hiss_loop.wav | a breached store, looped | made here: a thin hiss | CC0 | about -35 at 1.2 m | -18 |
| scoop.wav | a stroke of the scoop | made here: a blade through packed sand | CC0 | about -31 | -14 |
| seal.wav | sealant over a breach | made here: a spray and the plop of it setting | CC0 | about -30 | -14 |

The ride's sounds are made here too, numpy only, by `make_board_sounds.py` (CC0), as WAV,
levelled the same way (a loop by its whole):

| File | What it is | Made from | Licence | Heard at | Peak |
|---|---|---|---|---|---|
| board_carve.wav | a carve's hiss as the hover holds you round, looped | made here: an airy hiss over a faint rustle, breathing | CC0 | about -36 at its hardest | -21 |
| board_rush.wav | the wind's rush at speed, looped | made here: wide low noise gusting slowly, a thin whistle over it | CC0 | about -33 flat out | -20 |
| board_pop.wav | a pop off a lip, or a hop | made here: a soft low thup and a fwip of air | CC0 | about -33 | -18 |
| board_land.wav | a landing, by how hard | made here: a muffled whumph and a burst of sand | CC0 | about -31 at the jar | -17 |
| board_slam.wav | a landing past the jar | made here: a deep thud, more sand and the deck's rattle | CC0 | about -27 | -14 |
| board_knock.wav | a crash into something solid | made here: a hollow body's short-ringing knock, again as it comes back, a thud under | CC0 | about -27 | -14 |
| board_bite.wav | a skid taking hold again | made here: a short scuff and the field's chirp | CC0 | about -36 | -17 |
| hum_racer.wav | the skimmer racer's hum, looped | made here: a thin whine at 330 Hz with a buzz in it, a little vibrato | CC0 | about -35 | -31 |
| hum_patrol.wav | the Knights' patrol board's hum, looped | made here: a deep thrum at 110 Hz pulsing like a rotor, a growl under it | CC0 | about -34 | -27 |
| hum_temple.wav | the temple board's hum, looped | made here: a soft hum at 196 Hz, a ceramic ring of two beating partials, a breath of air | CC0 | about -35 | -28 |
| battery_low.wav | a board's battery low, once, about a minute from flat | made here: a soft falling two-note "do-doo" | CC0 | about -34 | -24 |
| battery_critical.wav | and critical, once, about 15 s from flat | made here: the same, lower, shorter and trembling | CC0 | about -30 | -19 |

The issue board's hum is still `hover.ogg`. The rope's snap is still made in code (`ropes.gd`), at about -28 LUFS from 8 m.
