class_name Tuning
extends Resource
## Every tuning number in the game. Change them on res://game/tuning.tres (open
## it in the inspector), so tuning never means editing code. Probes override
## fields on current() before building what they test.

const PATH := "res://game/tuning.tres"

static var _current: Tuning

@export_group("World")
## The run's seed. 0 picks a fresh one each run.
@export var run_seed: int = 0
## Metres round the moon. The one deliberate physics cheat (docs/the-moon.md).
@export var moon_circumference: float = 150000.0
## Large-body presentation; the circumference above only compresses travel.
@export var moon_visual_radius_m: float = 3700000.0
@export var spawn_latitude_degrees: float = 0.0
@export var spawn_longitude_degrees: float = 0.0
## Surface gravity, m/s². The body research leans toward 0.4-0.5 g; F6 tries it live.
@export var gravity: float = 9.8
## How many chunks the player may stray from the engine origin before the
## world shifts back, keeping 32-bit positions precise.
@export var origin_shift_chunks: int = 4

@export_group("Stoker")
@export var stoker_burn_s: float = 30.0
@export var stoker_stock: int = 3
## How often the furnace bay looks for Halloran among the laid sites, s.
@export var stoker_poll_s: float = 0.5
## The bay's lamp: its energy burning, the flicker on that, and its glow cold.
@export var stoker_light_energy: float = 2.8
@export var stoker_light_flicker: float = 0.2
@export var stoker_light_idle: float = 0.1
@export var stoker_light_range_m: float = 16.0
## The burn's roar, dB, and how far it carries, m.
@export var stoker_sound_db: float = -17.0
@export var stoker_sound_m: float = 65.0

@export_group("Spawns")
## Every run starts this near the equator, degrees: inside it the clear's
## widest swing stays within the suit's limits.
@export var start_latitude_degrees: float = 12.0
## A Surveyor starts at least the first this far from any artery or spoke,
## m, and walking in toward Tu crosses one within the second.
@export var start_artery_m := Vector2(600.0, 3000.0)
## What a Surveyor has in sight stands this far off, m: on its horizon, not
## at its feet; a sharp eye's find, and its glint the eye's (Starts.GLINT_).
@export var start_horizon_m := Vector2(600.0, 1000.0)
## No path and no settlement comes within this of a Surveyor's start, m:
## past the ground you can see.
@export var start_deep_m: float = 600.0
## A Salvager starts within this of a skimmer wreck field's hulls, m.
@export var start_wrecks_m: float = 300.0
## A Homesteader starts on a road within this of a wayshrine, m.
@export var start_wayshrine_m: float = 100.0
## Every start has a structure in sight from where its ground begins: its
## top clear over the dunes between by this many pixels at 1080 rows,
## however deep the sand lies on it.
@export var start_sight_px: float = 3.0

@export_group("Saves")
## A Normal run saves itself after this many minutes of play since its last
## save. The first storm comes in three to eight, so dying in it leaves a save
## to go back to.
@export var autosave_minutes: float = 3.0

@export_group("Deeds")
## Over the sand on a board, m: a pop off a big crest, past what pushing off
## one flies.
@export var deed_board_height_m: float = 8.0
## One ride without stepping off, m: more than a scout round camp.
@export var deed_board_m: float = 5000.0
## Tumbled in one wipeout, m: thrown off near flat out, past what an edge
## caught in a stop throws you.
@export var deed_tumble_m: float = 12.0
## Full storm one shield holds off, minutes, over however many storms.
@export var deed_storm_minutes: float = 60.0
## Made at once in one system, W: more than the reference camp makes at its best.
@export var deed_power_w: float = 300.0
## Kinds of crop grown, planters towed at once, and chassis pieces in one deck.
@export var deed_crop_kinds: int = 3
@export var deed_planters_towed: int = 2
@export var deed_fairlead_n: float = 10.0
@export var deed_fairlead_seconds: float = 1.0
@export var deed_deck_pieces: int = 6
## A bulk release counts the live lines actually let go together.
@export var deed_release_lines: int = 2
## Ground made against the wind under one sail, m, through its tacks: a
## keeled yacht's half a day close-hauled, a camp on skates' most of one.
@export var deed_upwind_m: float = 500.0
## Sailed in one sitting at a keeled camp's helm, m: half a day on its reaches.
@export var deed_yacht_m: float = 5000.0
## Sailed on a front's outflow ahead of its wall, m, without leaving it: a
## broad reach entered at the wall, holding it as the band slips behind.
@export var deed_outflow_m: float = 3000.0
## Sites a storm has freshly bared, reached in that one storm.
@export var deed_bared_sites: int = 3
## How far off a glint was seen, m, its site reached after: past the built
## ground, where most glints in sight shine from.
@export var deed_glint_m: float = 1000.0
## How far a vent's burst is heard booming from, m: further than any start
## stands from the rift's live vents.
@export var deed_thunder_m: float = 35000.0
## Tu this near straight up, degrees, is overhead.
@export var deed_tu_overhead_degrees: float = 5.0
## Days lived in one run.
@export var deed_days: int = 10
## A deck moved this far in one day, m, from where it stood as the day began:
## a yacht's reaches over half of one, a camp on skates' all of one.
@export var deed_moved_m: float = 5000.0

@export_group("Terrain")
@export var chunk_size: int = 64
## Chunks within this many of the player's get collision.
@export var near_radius: int = 2
## Chunks within this many of the player's are drawn.
@export var view_radius: int = 8
@export var mid_step: int = 2
@export var far_step: int = 32
@export var far_radius: float = 3000.0
## The far ring sits this far below the chunks it overlaps, so they win.
@export var far_drop: float = 1.0
@export var skirt_depth: float = 2.0
## The dunes: ridges across the run's long-term wind, this far apart, m.
@export var dune_spacing: float = 260.0
## Their windward ramps where sand is plentiful, and their slip faces, degrees.
## Slip faces sit under sand's 33° so wandering crests never tip one past it.
@export var dune_windward_degrees: float = 14.0
@export var dune_slip_degrees: float = 31.5
## Crests are rounded over about this much height, m, feet a little less, so
## 1 m samples don't facet them.
@export var dune_rounding: float = 1.6
## Crest lines wander this far, m, over this length along a crest. Sharper
## wandering tips slip faces past 33°: look/dunes/measure checks.
@export var dune_wander: float = 70.0
@export var dune_wander_wavelength: float = 600.0
## Crests rise and dip along their length over about this far, m.
@export var dune_saddle_wavelength: float = 900.0
## Patches about this big, m, grow a second set of crests: where one runs into
## a ridge, the crest forks.
@export var dune_fork_wavelength: float = 700.0
## Sand supply: dune seas where it's high, bare flats where low, over about
## this far, m. Sand gathers in the land's basins.
@export var sand_wavelength: float = 2600.0
## The land under the dunes: broad basins and rises, about 1° at most.
@export var land_height: float = 12.0
@export var land_wavelength: float = 7000.0
## The sand's look: ripples on windward slopes, lighter slip faces, light on
## crests. Off is the skeleton's flat colour.
@export var sand_shader: bool = true
@export var builds_in_flight: int = 8
## Main-thread time streaming may take per frame: attaching finished chunks,
## building their collision, retiring old ground, swapping the far ring. A
## 144 Hz frame is 6.9 ms, and the GPU wants most of it.
@export var stream_budget_ms: float = 0.5
## The hitch line: no frame may spend longer than this on streaming. look/stream
## holds a real window to it; probe 7 holds headless runs to it, bar one frame.
@export var stream_frame_max_ms: float = 2.0
@export var haze_begin: float = 400.0
@export var haze_end: float = 9000.0
## Most of the view the haze ever hides, at haze_end and beyond.
@export var haze_strength: float = 0.7

@export_group("Skyline")
## What stands on the dunes past the built ground, out to the far ring's
## reach: tall structures' stand-ins, glints, and the saltbush on the roads.
## Off, nothing shows past the built ground but the dunes.
@export var skyline: bool = true
## How far it draws, m.
@export var skyline_m: float = 3000.0
## The thinnest a stand-in or a far bush is drawn, pixels, so what's far off
## never breaks into flickering bits (drawn as much fainter).
@export var skyline_thinnest_px: float = 1.5
## Where a structure's real look hands over to its stand-in, m from you:
## crossfaded between, so you never see one switch for the other.
@export var skyline_handover_m := Vector2(420.0, 500.0)
## A glint's sparkle, pixels across as it lights and at its brightest, and
## how bright, times the sun on white.
@export var glint_px := Vector2(7.0, 12.0)
@export var glint_brightness: float = 7.0
## A glint through a storm's dust off what the storm just laid bare: seen
## this far, m, and how much of the open sky's glare the dust's glow leaves it.
@export var storm_glint_m: float = 90.0
@export var storm_glint_light: float = 0.7
## The clang of what the storm just laid bare, on the wind: heard this far, m.
@export var storm_clang_m: float = 140.0

@export_group("Light")
## The sand in full light, before the sun and sky light it. Real desert sand
## sends back about a third of the light; paler pushes sunlit ground into the
## tonemap's white, where the dunes wash out.
@export var sand_color: Color = Color(0.71, 0.59, 0.43)
## The dusty sky's light on everything, beside a sun of 1. It lights every
## slope alike, so more of it flattens the dunes and lifts their shade sides.
@export var sky_fill: float = 0.75
## The camera's exposure: everything on screen, sky and storms with the ground.
@export var exposure: float = 1.0
## Its beam: brightness, how fast it fades with distance (the renderer's
## default 1; less carries further), reach, m, half-angle, degrees, how soft
## its edge is (1 the renderer's; less softer), and how far it's tilted down
## from your view, degrees, to light the ground ahead.
@export var headlamp_energy: float = 2.0
@export var headlamp_falloff: float = 0.2
@export var headlamp_range: float = 35.0
@export var headlamp_angle: float = 35.0
@export var headlamp_edge: float = 0.5
@export var headlamp_tilt: float = 5.0
## It fades on and off over this long, s.
@export var headlamp_fade_seconds: float = 1.5

@export_group("Eye")
## The camera adapts to the light as an eye does (game/weather/eye.gd). Off, it
## holds the exposure above, as the look-tests that compare lightness do.
@export var eye_adapts: bool = true
## The eye opens only on a frame dimmer than this, as its meter reads it (all
## the light in the frame, its mean luminance), so a clear day, a dusk and a
## veil of dust look as they always have; and then by this share of each stop
## dimmer.
@export var eye_dim: float = 0.033
@export var eye_share: float = 0.51
## It opens no further than keeps the brightest patch in view (Tu's disc at
## night) under this, so Tu's bands never burn out.
@export var eye_white: float = 0.6
## The most it opens, times the exposure: the floor, where a black night stays black.
@export var eye_most: float = 7.0
## Opening toward the dark, stops a second at most: the pupil opens up to
## eye_quick_stops over the retina at eye_open_rate, and the retina carries the
## rest at eye_slow_rate. Both close back toward the bright at eye_close_rate.
@export var eye_quick_stops: float = 1.0
@export var eye_open_rate: float = 0.35
@export var eye_slow_rate: float = 0.07
@export var eye_close_rate: float = 2.5

@export_group("Tracks")
## The ground round you that keeps your marks: texels a side, and metres a
## texel. Marks further off are forgotten.
@export var track_cells: int = 4096
@export var track_texel: float = 0.25
## Drawn dent depth, m, and the share of its near view-ray relief.
@export var track_depth: float = 0.08
## Extra drawn depth and loose lip for the deepest sideways board skid, m.
@export var track_gouge_depth: float = 0.08
@export var track_gouge_rim: float = 0.02
@export var track_relief: float = 1.0
## Compacted sand loses this share of its colour.
@export var track_shade: float = 0.16
## Curvature of a soft stamp that raises a full loose lip.
@export var track_rim_shape: float = 0.08
## How long the wind takes to fill a fresh, full-depth mark, minutes: in calm
## air, and in a full storm. A step still reads with a tenth of its depth left.
@export var track_calm_minutes: float = 90.0
@export var track_storm_minutes: float = 20.0

@export_group("Weather")
## One full day and night, start to finish.
@export var day_minutes: float = 20.0
## Where in the day a run begins, local time at its spawn: 0 is midnight, 0.5 is noon.
@export var start_time_of_day: float = 0.3
## Mean prevailing wind, m/s. Storms ride it, so this sets how fast walls arrive.
@export var prevailing_speed: float = 10.0
## How far the prevailing wind swings round its mean, m/s. Kept under 0.6 of
## the mean so the wind never stops or reverses.
@export var prevailing_sway: float = 4.0
@export var prevailing_sway_minutes: float = 50.0
## Size of the storm field's features: storms and the gaps between them.
@export var storm_wavelength: float = 16000.0
@export var storm_octaves: int = 3
## How fast storms grow, fade and change shape, as metres of travel through the field.
@export var storm_evolve_speed: float = 1.5
## Field level that is the front. Lower means more of the moon is stormy.
@export var storm_threshold: float = -0.15
## Field rise from the front to full intensity: smaller makes a harder wall.
@export var storm_ramp: float = 0.04
## Extra wind at full storm, m/s, along the prevailing wind.
@export var storm_outflow_speed: float = 14.0
## How far ahead of the front, in field units, the outflow starts rising.
@export var storm_outflow_lead: float = 0.04
@export var gust_strength: float = 0.25
@export var gust_storm_strength: float = 0.5
@export var gust_wavelength: float = 80.0
@export var gust_evolve_speed: float = 4.0

@export_group("Anomaly")
## The storm the Walker misjudged: at its heart the real damage is this many
## times what its clean curve, which every forecast and instrument reads,
## deals in particles, and this many times in wind, so a camp built for the
## wind is wrecked by the sand.
@export var anomaly_particles: float = 5.0
@export var anomaly_wind: float = 1.5
## Its reach from its heart, m, full within a quarter of it, riding the air
## as storms do; and how long it lives either side of its peak, hours of run
## time, full for the middle third.
@export var anomaly_radius_m: float = 8000.0
@export var anomaly_hours: float = 2.0
## One may stand in each patch of air this wide, m, in each span of its whole
## life, with this chance: one storm in ten that passes a still camp holds
## one, about one every six hours of play.
@export var anomaly_cell_m: float = 20000.0
@export var anomaly_chance: float = 0.37
## None comes in a run's first days, from its own start: ordinary storms are
## learnt first.
@export var anomaly_grace_days: float = 5.0
## How far ahead of its storm's front its hidden term reaches, in the field's
## own units (about a kilometre or two): a heart riding in on the wall shows
## its tells before it.
@export var anomaly_reach: float = 0.25

@export_group("Lee")
## The most of the wind, and of a storm's wear, a dune's lee takes, close
## under a tall slip face. The dust and the dark still come over the crest,
## so it's never a shield.
@export var lee_wind: float = 0.65
@export var lee_storm: float = 0.33
## A crest shelters fully out to this many of its own heights downwind, and
## not at all past this: real lees are strongest within a few heights and
## gone by five to ten.
@export var lee_heights: Vector2 = Vector2(2.0, 7.0)
## A crest this far above a place, m, starts to shelter it, and this far
## shelters it fully: well over your head.
@export var lee_tall: Vector2 = Vector2(1.5, 6.0)
## Ground falling from a crest this steeply, degrees, starts to throw the
## wind clear of the sand, and this steeply throws it clear. Slip faces lie
## at 31.5° and windward ramps at 14° at most, so a wind from the wrong side
## finds no lee.
@export var lee_face_degrees: Vector2 = Vector2(16.0, 26.0)
## A slope climbing into the wind this steeply, degrees, starts to catch it
## again, and this steeply catches all of it: the wind comes back down to
## the sand and speeds up a windward slope.
@export var lee_windward_degrees: Vector2 = Vector2(2.0, 8.0)
## How far upwind the ground is read, m, and at how many places, each a
## share further than the last. Seven heights of the tallest dunes is about
## 300 m; past this a crest's last faint shelter fades out.
@export var lee_reach: float = 250.0
@export var lee_samples: int = 32

@export_group("Sand on the wind")
## Wind on open sand starts to lift it at this, m/s, and lifts all it can by
## this: loose sand moves on an ordinary breezy afternoon, not only in a storm.
## For looks only (WindMap).
@export var transport_wind: Vector2 = Vector2(5.0, 8.0)
## The share of the afternoon's sand still moving at night, the air lying still
## on cold sand; a front's outflow drives it day or night.
@export var transport_night: float = 0.25

@export_group("Storm")
## How far you can see inside a storm, in metres.
@export var storm_visibility: float = 20.0
## Share of the light a full storm takes.
@export var storm_darkness: float = 0.78
@export var storm_fog_color: Color = Color(0.62, 0.4, 0.2)

@export_group("Temperature")
## The day's mean at the equator, °C, and how far it swings either side of it
## in the clear: hot enough by afternoon to boil open water, freezing by night.
@export var temperature_mean: float = 20.0
@export var temperature_swing: float = 45.0
## The hottest time of day (0.5 is noon); the coldest is half a day on.
@export var temperature_peak: float = 0.6
## Toward the poles the swing widens, by this share more at a pole.
@export var temperature_pole_widen: float = 1.0
## A full storm's dust blankets the swing by this share.
@export var temperature_storm_blanket: float = 0.5
## A bubble that holds back temperature holds this inside, °C.
@export var sheltered_temperature: float = 20.0
## How far the air would cool if the sun stayed hidden behind Tu overhead, °C.
## The air's lag, which puts the day's peak mid-afternoon, sets how much of it
## an eclipse gets.
@export var eclipse_chill: float = 40.0

@export_group("Tu")
## How wide Tu is across the sky, degrees. Physics follows the look: it sets
## how far out Tu's orbit is, and so how long the eclipse lasts and how bright
## Tu-shine is. Three are under trial (docs/the-moon.md), 6, 9 and 13, and 9
## is the default; the dev console's tu switches among them.
@export var tu_degrees: float = 9.0
## The longitude under Tu, degrees: 60° west of spawn stands Tu 30° up, due
## west, where a run begins.
@export var tu_longitude_degrees: float = -60.0
## Tu-shine on top of its physical value, so how bright a near-side night is
## can be tuned apart from Tu's size. 1 is physical.
@export var tu_shine_scale: float = 1.0
## How long Tu takes to turn once, real hours: a super-Jupiter's ten. The
## game's day stands for Zan's real lap, which Tu's size sets, so Tu turns as
## often in a game day as it would in a real one: at 9°, about 6.8 times as
## seen from Zan.
@export var tu_spin_hours: float = 10.0

@export_group("Storm wall")
## Top of a storm's dust wall, metres. It dissolves over roof_soft either side.
@export var wall_height: float = 1800.0
@export var wall_roof_soft: float = 450.0
@export var wall_dust_color: Color = Color(0.62, 0.47, 0.34)
## How bright the heart of a storm glows from light scattered many times.
@export var wall_glow: float = 0.3
## Share of the ground's light that comes straight from the sun; a wall's
## shadow takes that share away.
@export var wall_sun_share: float = 0.7
## Walls dissolve into the haze between these distances, metres.
@export var wall_fade_begin: float = 11000.0
@export var wall_fade_end: float = 15000.0
## The storm map the GPU reads: cells a side, and metres it reaches each way.
@export var storm_map_cells: int = 128
@export var storm_map_reach: float = 20000.0

@export_group("Shield")
## The base shield's bubble, metres from the generator to the shell.
@export var shield_radius: float = 7.0
## The bubble blooms open, and collapses, in this long.
@export var shield_bloom_seconds: float = 0.6
## What the base shield draws running in the clear, W: a sip.
@export var shield_clear_w: float = 10.0
## What it draws holding back a full storm, W: a base battery's 100 Wh lasts
## thirty minutes. A lesser storm costs between the two.
@export var shield_storm_w: float = 200.0
## With this little left at what it draws now, s of world time, its hum sags
## and its shell flickers.
@export var shield_warning_seconds: float = 120.0
## Placeholder wear on devices outside a bubble, until parts wear on their
## own: a full storm wrecks one in this many minutes, times its toughness.
@export var storm_wreck_minutes: float = 10.0
## Wind past this, m/s, wears devices too; a storm's blows about 24.
@export var wind_harm_speed: float = 20.0
## Wind 10 m/s past that wrecks a device by itself in this many minutes;
## harder wind, faster in proportion.
@export var wind_wreck_minutes: float = 30.0

@export_group("Player")
## About 5 km/h, the pace the moon's size was set against.
@export var walk_speed: float = 1.8
@export var sprint_speed: float = 3.9
## Speed lost per metre of rise per metre walked.
@export var uphill_slowdown: float = 1.5
@export var stamina_max: float = 100.0
@export var stamina_sprint_drain: float = 8.0
@export var stamina_uphill_drain: float = 20.0
@export var stamina_regen: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var dev_fly_speed: float = 60.0
## Wind below this, m/s, doesn't move you; above it, it shoves.
@export var wind_resist_speed: float = 12.0
## Shove, m/s, per m/s of wind beyond what you can resist.
@export var wind_push: float = 0.08
## How long your feet take to settle into a new pace, s: what a landing or a
## slide's end carries runs out over about this.
@export var pace_seconds: float = 0.1
## Crouched, you walk this fast, m/s, and the wind catches this share of you:
## its force goes with the area you show it.
@export var crouch_speed: float = 0.7
@export var crouch_catch: float = 0.45
## Takeoff is the same on any moon, so this is the height at 1 g, m; lower
## gravity throws you higher and keeps you up longer.
@export var jump_height: float = 0.45
@export var jump_stamina: float = 6.0
## A jump still works this long after the ground goes, and a press this long
## before you land jumps as you touch down, s.
@export var coyote_seconds: float = 0.12
@export var jump_buffer_seconds: float = 0.15
## How hard you can steer in the air, m/s², and never past your walking pace.
@export var air_control: float = 1.5
## Sand steeper than this, degrees, won't hold you: you slide down it. Slip
## faces lie at about 33°, windward slopes well under 20°.
@export var slip_angle: float = 28.0
## The sand's grip on a slide on your seat, and skidding on your feet: tan of
## the slope that just keeps a slide going. Steeper gains speed.
@export var slide_friction: float = 0.1
@export var slip_friction: float = 0.35
## Ploughing sand, per m: drag of speed², which sets a slope's top speed.
@export var slide_drag: float = 0.02
## Crouch this fast or faster, m/s, and you slide; slower, only downhill.
@export var slide_start_speed: float = 2.2
## The push you throw into a slide, m/s.
@export var slide_kick: float = 0.4
## A slide on the flat ends below this, m/s; on your feet you can run out anything
## slower than a sprint.
@export var slide_stop_speed: float = 0.5
## How fast you can steer a slide, rad/s, and the extra grip of digging your heels in.
@export var slide_turn: float = 0.8
@export var slide_brake: float = 0.3
## Hauling: a line has to take this share of your pace before your feet dig
## in; fully dug in you lose this share of it and tire this much faster, per s.
## You're fully dug in once it takes all the pace you'd manage dug in.
@export var haul_from: float = 0.35
@export var haul_slow: float = 0.35
@export var haul_stamina_drain: float = 10.0
## How quickly you dig in and come back up, s.
@export var haul_seconds: float = 0.4

@export_group("Ledge vault")
## Reach above the current feet, forward reach, m; jump rise is not added again.
@export var vault_height: float = 1.1
## Small clutter stays an ordinary obstacle/jump, not a full mantle.
@export var vault_min_height: float = 0.3
@export var vault_reach: float = 0.9
@export var vault_clearance: float = 0.02
## Duration of a full-height climb; shorter paths use proportionally less time.
@export var vault_seconds: float = 0.55
## Feet clear the measured top by this much while crossing it, m.
@export var vault_lift_margin: float = 0.18
@export var vault_stamina: float = 4.0
@export var vault_settle_speed: float = 0.1

@export_group("Hoverboard")
## Flat out on the flat in still air, m/s: 72 km/h, faster than any storm
## front rides the wind (the prevailing wind's 10 m/s swings up to 14).
@export var board_top_speed: float = 20.0
## The push from a standstill, m/s²; drag grows with speed² until it matches
## the push at top speed. Enough to climb a slip face at about 11 m/s.
@export var board_push: float = 6.5
## A loaded motor can tow slowly; sustained opposing load grounds the hover.
@export var board_tow_force_n: float = 90.0
@export var board_tow_work_w: float = 80.0
@export var board_tow_load_n: float = 15.0
@export var board_tow_overload_n: float = 70.0
@export var board_tow_response_s: float = 0.2
@export var board_tow_hot_s: float = 0.6
@export var board_tow_stall_speed: float = 0.1
@export var board_tow_latch: float = 0.6
@export var board_tow_ground_height: float = 0.04
@export var board_tow_ground_drag: float = 3.0
@export var board_tow_efficiency: float = 0.8
@export var board_tow_sputter_hz: float = 6.0
@export var board_tow_sputter_on: float = 0.25
@export var board_tow_hum_pitch: float = 0.55
@export var board_tow_hum_db: float = -12.0
## The share of that drag that's the air's, felt against the wind: a tailwind
## carries you faster, a headwind holds you back, and a tuck shows it less.
@export var board_air_share: float = 0.35
## Steering back against your way brakes this hard, m/s²; coasting, the
## hover's own drag slows you this much, m/s².
@export var board_brake: float = 8.0
@export var board_coast: float = 0.3
## The dig, move back: one edge drops into the sand. Slicing along its length
## the dug edge grips this many times as hard as the hover, so a carve holds;
## dragged across, as in a hockey stop, no harder than the hover. Dug, the
## sand drags this share of your speed a second, and the board rides this much
## lower, m, its low edge down to the sand.
@export var board_dig_grip: float = 2.5
@export var board_dig_drag: float = 0.25
@export var board_dig_depth: float = 0.3
## Dig times the way across the board past this, m/s, and the edge catches:
## you're thrown off, losing this much health and stamina. A full hockey stop
## from flat out catches; up to about 17 m/s it holds.
@export var board_dig_catch: float = 6.5
@export var board_wipeout_hurt: float = 5.0
@export var board_wipeout_winded: float = 25.0
## How fast the board turns under you, rad/s; the most sideways pull its
## hover grips with, m/s², before a carve slides out into a skid; and the
## share of its speed a full sideways skid bleeds a second.
@export var board_turn_rate: float = 2.5
@export var board_grip: float = 18.0
@export var board_drift_drag: float = 1.0
## A drift, crouched into a hard turn: the board swings round this fast,
## rad/s, its hover grips this hard, m/s², and a full sideways slide bleeds
## this share of its speed a second. It starts this fast or faster, m/s.
@export var board_drift_turn: float = 3.5
@export var board_drift_grip: float = 14.0
@export var board_drift_slide: float = 0.25
@export var board_drift_speed: float = 8.0
## A skid: standing, a carve past the hover's grip breaks loose this fast or
## faster, m/s, and slides on keeping this share of that grip, a full
## sideways slide bleeding this share of its speed a second, until it comes
## back near your way and bites.
@export var board_skid_speed: float = 7.0
@export var board_skid_grip: float = 0.9
@export var board_skid_drag: float = 0.6
## Flying, the board's tilt follows its path this fast, Hz: its nose up off a
## lip and down as it falls, easing to the sand it's coming down on.
@export var board_air_hertz: float = 2.5
## Landing, the speed it meets the sand at, m/s (harder crossed): past the
## first it slides out and jars you, past the second it throws you off. Into
## something solid faster than this, m/s, it throws you off.
@export var board_land_jar: float = 9.0
@export var board_land_throw: float = 15.0
@export var board_crash: float = 7.0
## A kick off the sand: m/s along the board from rest, less the faster you
## go and nothing at top speed; one this often while sprint is held, s, for
## this much stamina. Kicking, you don't get your breath back.
@export var board_kick: float = 2.5
@export var board_kick_every: float = 0.6
@export var board_kick_stamina: float = 6.0
## Standing up from a crouch lifts your weight this far over the board, m:
## against a hover pressed into a dip it adds speed, and crouching as it
## unloads over a crest does too. The wrong way round it costs.
@export var board_pump_rise: float = 0.5
## How fast the board's tilt settles onto the sand, Hz: slower and its ends
## would dip into it. And how fast it leans into a carve: slower and it
## floats, faster and it twitches.
@export var board_tilt_hertz: float = 5.0
@export var board_lean_hertz: float = 1.2
## Its underside rides this high over the sand, m, and its edges never come
## nearer than this but dug.
@export var board_ride_height: float = 0.35
@export var board_clearance: float = 0.08
## The hover's spring: stiff pressed toward the sand, softer lifting off it,
## so it skims a slope and floats off a crest; how much it bounces (1 never
## does), at the stiff spring's rate.
@export var board_hover_hertz: float = 2.5
@export var board_settle_hertz: float = 2.0
@export var board_hover_damping: float = 0.8
## The most the hover pulls you back down beyond gravity, m/s²: more and it
## hugs a crest, less and it sails off. It eases off over this far past its
## ride height, m: further and the sand's dropped away, and you fly under
## gravity alone. A hop gives that up, and falls at this share of gravity:
## floaty.
@export var board_hold: float = 15.0
@export var board_hold_reach: float = 0.5
@export var board_hop_fall: float = 0.6
## Coming down on the sand, the hover brakes your fall about this hard, m/s²,
## and never more than three times it: a landing is a firm press, never a slam.
@export var board_cushion: float = 12.0
## It reads the sand this many seconds of travel ahead and behind, so it
## rounds a dip's bottom instead of slamming into it.
@export var board_look_seconds: float = 0.45
## Maximum newly reachable solid support above the underside, m; a wall stays a wall.
@export var board_surface_rise_m: float = 0.18
## One outer-tick broadphase cap; no space queries inside the board's inner steps.
@export var board_surface_shapes: int = 64
## Bound the broadphase and nearby chunk collection even after an abnormal shove.
@export var board_surface_reach_m: float = 16.0
## A hop, m/s up, and this much more from a full crouch.
@export var board_hop: float = 4.0
@export var board_pop: float = 1.5
## What it draws, W: floating, and on top of that at full push. A base
## battery's 100 Wh lasts twenty minutes flat out, about 24 km.
@export var board_hover_w: float = 40.0
@export var board_push_w: float = 260.0
## On a deck, it charges from the camp at up to this, W: a base
## battery in two hours, as far as the camp can spare it.
@export var board_charge_w: float = 50.0

@export_group("Camp range")
## Leaving your camp behind: one warning this many seconds from losing it at
## your pace, or this near the edge, m; a last one this many seconds or
## metres from it.
@export var range_first_seconds: float = 20.0
@export var range_first_m: float = 40.0
@export var range_last_seconds: float = 8.0
@export var range_last_m: float = 12.0

@export_group("Body feel")
## Everything here moves only the camera and makes only sound, never you.
## Eye height comes down this far crouched, and sunk in hauling, m.
@export var crouch_drop: float = 0.55
@export var haul_sink: float = 0.07
## A step's length at walking pace, m; it lengthens with speed.
@export var step_length: float = 0.85
## Head bob, sway and roll at walking pace: they grow with speed.
@export var bob_height: float = 0.03
@export var bob_sway: float = 0.02
@export var bob_roll_degrees: float = 0.5
## The head's spring: how fast it swings back, and how much it bounces (1 never does).
@export var spring_hertz: float = 2.5
@export var spring_damping: float = 0.45
## Head speed, m/s, per m/s of a landing, a footfall, or a change of pace.
@export var land_dip: float = 0.3
@export var step_dip: float = 0.02
@export var lurch: float = 0.12
## Landings faster than this, m/s, thud: about a 0.8 m fall at 1 g.
@export var hard_landing: float = 4.0
## Leaning into the wind you can just stand against, m upwind and degrees of roll.
@export var wind_lean: float = 0.04
@export var wind_lean_degrees: float = 2.0
## Head speed per m/s a gust rises by.
@export var gust_nudge: float = 0.03
## Extra field of view at a sprint, and at a fast slide, degrees.
@export var sprint_fov: float = 3.0
@export var slide_fov: float = 8.0
## A walking step and a full slide, dB over how loud their files are heard.
@export var step_db: float = 0.0
@export var slide_db: float = 0.0

@export_group("Devices")
## A hover tray pushes all it can lift with its face this high over the sand
## or nearer, m, and a share of it higher up, falling off by e each
## hover_falloff m: a cushion, so every load bobs at one rate and a light one
## rides higher.
@export var hover_height: float = 0.84
@export var hover_falloff: float = 0.06
## How much the cushion's bounce dies in one swing (1 settles without bouncing).
@export var hover_damping: float = 0.8
## What hovering costs, W per kg floated. Power (Stage 4) drains it.
@export var hover_watts_per_kg: float = 2.0
## Set resting or floating again, a tray lets its device down or lifts it
## back up over this long, s.
@export var hover_settle_seconds: float = 2.0
## The magnetic tug reaches this far from a free socket, m.
@export var snap_reach: float = 0.4
## Inside this, the tug leans the part all the way into its seat, ready for
## take to seat it; nothing seats on its own, m.
@export var snap_home: float = 0.12
## Aiming within this of a small loose thing, m on top of its own size, takes
## it; things bigger than pick_small across you look right at.
@export var pick_assist: float = 0.15
@export var pick_small: float = 0.6
## Hands hold a part this far in front of the eyes, m.
@export var hold_distance: float = 0.9
## How far you can reach to grab, m.
@export var reach: float = 2.5
## A fitted part slides out of its socket in this long, s.
@export var take_seconds: float = 0.12
## The tug leans a part all the way home in this long, and lets go as fast, s.
@export var tug_seconds: float = 0.2
## A throw, m/s, on top of how you're moving.
@export var throw_speed: float = 6.0
## Your strength on what you hold too heavy to carry, or walk into, N.
@export var hand_strength: float = 400.0
## A yank is a short reel stroke, with the same strength limit as normal hauling.
@export var rope_yank_m: float = 0.5
@export var rope_yank_seconds: float = 0.2
@export var rope_yank_recover_seconds: float = 0.4
@export var rope_yank_deed_m: float = 0.1
@export var rope_yank_deed_n: float = 20.0
## Having hold of something, a throw punches it where you look instead, a
## small shove to right a tipped rig with, N·s.
@export var punch_impulse: float = 45.0
## How fast what you hold comes to where you'd have it, 1/s, and the most it
## comes faster than you, m/s, so nothing you swing round is flung.
@export var hold_rate: float = 4.0
@export var hold_speed: float = 2.0
## What you hold slips from your hands this far from where you'd have it, m.
@export var hold_slip: float = 1.5

@export_group("Sailing")
## A raised sail's push felt this long (Mast.LOAD_SECONDS) tears it past
## sail_tear_n, N, and snaps its mast past mast_snap_n: in a 10 m/s breeze a
## sail makes a quarter of the first, in a storm far past both. Set against a
## line's 1,500 N and a stake's 2,500 N, so a camp moored with its sail up
## loses the sail and then the mast before its line or its stake.
@export var sail_tear_n: float = 600.0
@export var mast_snap_n: float = 1000.0
## At the helm, the sideways moves turn the camp as a hovercraft's do: toward
## this fast a turn, rad/s, by a turning push of at most this much, N·m.
@export var helm_turn: float = 0.5
@export var helm_torque: float = 800.0
## A camp lying over drags along the sand at its edges and masthead by this
## share of what holds it up there.
@export var tipped_grip: float = 0.6

@export_group("Rope")
## A line's own weight, kg per metre. It's what makes a lightly loaded line
## droop and straighten only as the pull builds, so the load reads by eye.
@export var rope_kg_per_m: float = 0.12
## How many times a second a stretched line springs back, whatever hangs on it,
## and how much it bounces (1 settles without bouncing).
@export var rope_hertz: float = 3.0
@export var rope_damping: float = 0.7
## Share of its length a line stretches before the hard stop.
@export var rope_max_stretch: float = 0.1
## Newtons of sustained load that snap a line, and how long load is averaged
## before it breaks anything, so a shorter spike can't, s.
@export var rope_breaking: float = 1500.0
@export var strong_cable_breaking: float = 4000.0
## A hose holds this much sustained load, N, a third of a rope, and then an
## end pops out of its socket instead.
@export var hose_holding: float = 500.0
@export var rope_load_seconds: float = 0.3
## A found coil's length, m: the longest line it lays.
@export var rope_coil_length: float = 12.0
## Shared winding geometry and the gathered display's settling time.
@export var rope_coil_visual: Dictionary = {}
## A line paying out of the coil in your hand runs this much longer than the
## way from its first end to you, m.
@export var rope_pay_slack: float = 0.5
## Newtons of sustained pull a driven stake holds before it pulls out.
@export var stake_holding: float = 2500.0
## You on a line: your weight in the suit, and your feet's hold against a
## pull, which grows the faster you're dragged, as when you dig in and stumble.
@export var player_mass: float = 90.0
@export var grip: float = 4.0
@export var grip_per_speed: float = 2.0
## Tied round your waist: the share of your walking it costs, the wind it adds
## to what pulls you, and how long untying takes, s.
@export var waist_slow: float = 0.3
@export var waist_catch: float = 0.12
@export var untie_seconds: float = 1.0
## Your body between lines pulling it apart, or bent round by one, takes this
## much held, N, and past it loses this much health a second for each share
## more.
@export var fulcrum_n: float = 400.0
@export var fulcrum_hurt: float = 8.0

@export_group("Power")
## Seconds of world time per power tick.
@export var power_tick: float = 0.25
## A turbine's output, W per (m/s)³ of felt wind, up to its rating.
@export var turbine_watts_per_cubic: float = 0.0128

@export_group("Survival")
## Full to empty in the mild, in days: hunger, and thirst, which runs faster in
## the heat, from thirst_heat_from °C up to heat_thirst times as fast at the
## suit's hot limit.
@export var hunger_days: float = 2.0
@export var thirst_days: float = 1.0
@export var thirst_heat_from: float = 30.0
@export var heat_thirst: float = 2.0
## What fills you from empty: litres of water, kcal of food.
@export var thirst_litres: float = 1.5
@export var hunger_kcal: float = 2000.0
## The suit gives you water when you fall below this share, and food below
## this, back up to full.
@export var drink_below: float = 0.8
@export var eat_below: float = 0.6
## Health a second, of 100: at a full storm; per m/s of wind past
## wind_hurts_from; per degree past the suit's limits.
@export var storm_harm: float = 0.25
@export var wind_hurts_from: float = 20.0
@export var wind_harm: float = 0.01
@export var temperature_harm: float = 0.05
## Health a second with nothing left in you to eat, or to drink.
@export var starving_harm: float = 0.1
@export var parched_harm: float = 0.3
## Unharmed, fed and watered, you heal from nothing to full in this many days.
@export var heal_days: float = 1.0
## The suit keeps you safe between these, °C; past them the temperature harms you.
@export var suit_cold: float = -40.0
@export var suit_hot: float = 75.0
## What you carry besides your hands and your waist has no slots, only a
## weight: up to this much, kg, you don't feel it; past it you sink into the
## sand and slow, by this much sunk in as far as hauling digs you in, and
## slower still for every kilogram more. The kit you start with carries
## 5.9 kg, and every carryable thing of it, its stake, its board with the
## board's battery and the light panel too, 23.9 kg.
@export var carry_easy_kg: float = 30.0
@export var carry_sunk_kg: float = 60.0
## A sealed canister holds this much water, L, and a ration this much food, kcal.
@export var canister_litres: float = 2.0
@export var ration_kcal: float = 1000.0
## The crude condenser: what it draws running, W, and the water it makes at
## its best, L an hour of world time, in air at or below condenser_cold °C.
## Warmer air gives up less, down to condenser_hot_share of it at condenser_hot.
@export var condenser_w: float = 40.0
@export var condenser_litres_per_hour: float = 10.0
@export var condenser_cold: float = 0.0
@export var condenser_hot: float = 40.0
@export var condenser_hot_share: float = 0.2
## The compass needle follows Tu's weak field: it swings about it once in this
## many seconds and settles by this damping (1 would never overshoot). Tu's
## field is tipped from its spin, so the needle sways this far either way once
## each turn of Tu; a full storm's charged dust swims it up to this far. At
## an anomaly's heart it leans toward the heart, steadily, up to this far.
@export var compass_swing_seconds: float = 3.0
@export var compass_damping: float = 0.4
@export var compass_sway_degrees: float = 10.0
@export var compass_storm_degrees: float = 35.0
@export var compass_anomaly_degrees: float = 60.0
## Over the most magnetized old volcanic ground, the needle swims this far either way.
@export var compass_ground_degrees: float = 40.0

@export_group("Sleep")
## A night is lived in steps this long, s of world time: each system's own
## sums over each, the camp held still (live, they tick every power_tick).
## No sleep runs past sleep_most_days, whatever it waits for.
@export var sleep_tick: float = 10.0
@export var sleep_most_days: float = 4.0
## So many hours, of the 24 in a day, is first offered as this many.
@export var sleep_hours: int = 8
## The camp is your devices and stakes within this of you, m; it's still
## while none moves faster than this, m/s, or turns faster than this, rad/s.
@export var sleep_camp_m: float = 30.0
@export var sleep_still_speed: float = 0.5
@export var sleep_still_spin: float = 1.0
## Asleep with nothing left to drink or eat, you wake once thirst or hunger
## falls to this share.
@export var sleep_wake_need: float = 0.25

@export_group("Farming")
## A planter's water tank, L. Found empty.
@export var planter_tank_litres: float = 4.0
## Each crop's own numbers are its data in the catalog. Past what it holds
## through, a crop loses growth this many times faster than it gains it at
## its best.
@export var wilt_rate: float = 2.0
## The share of each harvest a harvester replants, to start with. A quarter
## of a harvest of four keeps every slot sown.
@export var replant_share: float = 0.25
## A planter drops food onto you from this close, m, while you carry less
## food than this, kcal.
@export var drop_reach: float = 6.0
@export var drop_until_kcal: float = 2000.0

@export_group("Feral")
## Wild plants on their habitats (Feral); each habitat's own numbers are its
## row in the table there.
@export var feral: bool = true
## Wild stock gives this share of a clean plant's harvest, never none of a part.
@export var feral_wild_yield: float = 0.5
## Wild plants fold before a storm within this far of you, m; farther lines
## hold their pose until you come nearer. Growth ticks only on ground you
## can stand on, where you can take from them.
@export var feral_fold_m: float = 400.0
## Main-thread time a frame may take laying wild plants out with the ground, ms.
@export var feral_budget_ms: float = 0.3

@export_group("Salvage")
## Ruins and finds. Probes of other systems switch them off, as ground probes
## still the air, so a buried crate never stands in what they measure.
@export var salvage: bool = true
## Loose finds in a chunk of open sand on the way, on average, and at most: a
## tenth of the 1.5 open sand held before loot moved into history's sites.
## On the way is within a path's corridor or this near a settlement's sites, m.
@export var finds_per_chunk: float = 0.15
@export var finds_most: int = 4
@export var finds_scatter_m: float = 60.0
## Drift (Drift): what a line across the wind catches in a storm's heart, an
## hour per metre of it; of what blows past, the share that snags on a line in
## the open, and how much more falls out of the slowed wind in a full lee.
@export var drift_per_m_hour: float = 1.0
@export var drift_open: float = 0.25
@export var drift_lee: float = 1.0
## Drift is drawn every this many s of world time; a line's pile holds at
## most this many things before more blows past; a catch line is at least
## this long, m.
@export var drift_tick_s: float = 20.0
@export var drift_most: int = 8
@export var drift_shortest_m: float = 1.5
## With no line at all, light things fall out in the lee of a crest near
## camp: this many an hour on a hundred square metres of full lee in a storm's
## heart, within this far of you or a deck of yours, m.
@export var drift_lee_fall: float = 0.5
@export var drift_lee_fall_m: float = 24.0
## Drift off a site a storm lays bare (Drift.from_sites): things an hour it
## sheds in a storm's heart once the storm has dug it right out; how far
## downwind the stream carries before most of it has fallen out, m; and how
## wide it leaves the site, m, spreading this much a metre downwind.
@export var site_drift_per_hour: float = 120.0
@export var site_drift_carry_m: float = 150.0
@export var site_drift_width_m: float = 4.0
@export var site_drift_spread: float = 0.15
## Share of finds from the deep layer where the weather has been calm, and
## where it has been as hard as it gets the whole time; between, by how hard
## it's been.
@export var deep_calm: float = 0.0
@export var deep_storm: float = 0.6
## How far back the weather counts toward what a place shows, hours, read
## every this many minutes of world time.
@export var exposure_hours: float = 2.0
@export var exposure_step_minutes: float = 10.0
## The storm field this far past its front counts as a storm's heart: as hard
## as storms uncover.
@export var exposure_storm_full: float = 0.4
## Wind up to this uncovers nothing, the prevailing wind's strongest, and
## this hard as much as a storm's heart, m/s.
@export var exposure_calm_wind: float = 16.0
@export var exposure_gale_wind: float = 30.0
## Scrapping a wreck (Wreckage): seconds a heat cutter's hot spot takes
## through each metre of a plate's seam (times the wreck's armour), and a
## scoop through each m³ of packed sand. The cutter draws this while it
## fires, W: its battery's 60 Wh last half an hour of cutting.
@export var cut_seconds_per_m: float = 1.5
@export var clear_seconds_per_m3: float = 0.35
@export var cutter_w: float = 120.0
## A live capacitor bank's shock: health it takes at once, and seconds you're
## stunned. A breached store's sickness: health a second it takes, for how
## many seconds of world time, and how much faster you thirst meanwhile.
@export var shock_harm: float = 25.0
@export var shock_stun: float = 1.5
@export var sickness_harm: float = 0.08
@export var sickness_seconds: float = 240.0
@export var sick_thirst: float = 1.8

@export_group("History")
## The moon's cells history is made and laid in, m across.
@export var history_cell_m: float = 500.0
## A cell or landmark is laid on the ground once any of it comes this near
## you, and lifted once all of it is this far off on the ground, m. Loaded
## ground reaches about 900 m.
@export var history_lay_m: float = 1300.0
@export var history_lift_m: float = 1800.0
## The regions, by the angle from the point under Tu, degrees: Han inside the
## first, Mon to the second, the Rim to the third, then the far side.
@export var region_han_degrees: float = 20.0
@export var region_mon_degrees: float = 75.0
@export var region_rim_degrees: float = 105.0
## How built up each region was, 0 to 1: "rich at the Rim, thinner in Mon,
## sparse and grim in Han."
@export var richness_han: float = 0.25
@export var richness_mon: float = 0.5
@export var richness_rim: float = 1.0
@export var richness_far: float = 0.12
## The line the great sites lie on leaves the point under Tu east or west,
## within this many degrees, so its Rim end stays at low latitude.
@export var axis_spread_degrees: float = 25.0
## Spokes from Port Morgan out to the ring, besides the artery.
@export var spokes: int = 5
## A structure's exposure: the weather at it over this many hours before its
## ground is built, read every this many minutes of world time.
@export var site_exposure_hours: float = 12.0
@export var site_exposure_step_minutes: float = 30.0
## Sand a storm's heart strips off a structure in a tick, and sand the wind
## lays back on it every tick, m.
@export var site_strip_m: float = 0.5
@export var site_return_m: float = 0.2
## A storm working on a site (Exposure.surge): its big dunes move off the
## site or onto it a minute at a time. Sand a storm's heart moves in a minute
## where they're moving off it, m; how long what it moved takes to come back
## once the storm lets go, minutes; and how far back its work counts, minutes.
@export var site_surge_m: float = 0.8
@export var site_surge_return_minutes: float = 5.0
## Calmer air takes longer to refill a hollow than a storm actively moving sand.
@export var site_wake_return_minutes: float = 18.0
@export var site_surge_window_minutes: float = 25.0
## Where a site lies among the dunes (Exposure.dune_at): on a windward face
## or crest the wind strips this much more, the storm's work off it too; in a
## lee or on a slip face the sand comes back this much more, the storm's work
## onto it too, each a share at its fullest.
@export var site_dune_strip: float = 1.0
@export var site_dune_bury: float = 1.0
## Where a storm's dunes move off ground or onto it (WeatherField.dune_shift_at):
## patches this many metres across, changing over this many minutes, leaning
## this far toward moving off and swinging this hard.
@export var dune_shift_m: float = 400.0
@export var dune_shift_minutes: float = 15.0
@export var dune_shift_lean: float = 0.25
@export var dune_shift_swing: float = 1.3
## Sand never comes back over a site while you or your camp stand on its
## ground; once you're off, it comes back this fast at most, m/s.
@export var site_rebury_m_s: float = 0.05

@export_group("Dune ruins")
## A ruin lies in the lee of each big dune (DuneRuins): one to a cell this
## long along its crest, m, under a dune standing at least this tall over the
## trough past its slip face, m, as deep as this, m, least and most.
@export var dune_ruin_cell_m: float = 300.0
@export var dune_ruin_big_m: float = 14.0
@export var dune_ruin_depth_m := Vector2(5.5, 6.5)
## Each is a seed until it's needed. Slower than this, m/s, for this long, s,
## you've slowed: the seeds round you are looked at out to this far, m, each
## again this often, s of world time; and one bared builds once you're this near, m.
@export var dune_ruin_slow_m_s: float = 4.5
@export var dune_ruin_slow_s: float = 2.0
@export var dune_ruin_check_m: float = 300.0
@export var dune_ruin_recheck_s: float = 15.0
@export var dune_ruin_build_m: float = 150.0
## Digging a site out with a scoop: seconds through each m³ of its sand, its
## footprint's area a metre deep, and the share of its depth the dig must take
## for it to be yours, not a storm's. A sieve sifts this many finds out of
## each m³ dug.
@export var dig_seconds_per_m3: float = 1.5
@export var dig_own_share: float = 0.5
@export var sift_per_m3: float = 0.02

@export_group("Plume")
## A live vent's seep as a buoyancy flux, m⁴/s³ at this tuning's gravity: how
## hard the hot gas it lets out climbs, lifting its column of dust 1.5 to 3
## km. Bursts multiply it (Geology).
@export var plume_buoyancy: float = 300000.0
## A plume dissolves into the distance between these, m: further than the
## storm walls, since what towers over the haze stands clear of it.
@export var plume_fade_m := Vector2(30000.0, 45000.0)

@export_group("Radio")
## What a radio draws while it's on, W.
@export var radio_w: float = 2.0
## At full volume a radio plays this much louder than the levels its tracks
## are made at, dB: a radio is meant to be heard across a camp. It's heard at
## that level out to this far, m, and fades 6 dB each time that doubles.
@export var radio_loudness_db: float = 15.0
## The volume knob spans this many dB from full to its first notch's tenth:
## a fixed step a notch (6 dB at 60), so a tenth is barely audible.
@export var radio_volume_range_db: float = 60.0
## A radio is a small speaker: everything it plays loses what's under this, Hz.
@export var radio_highpass_hz: float = 400.0
@export var radio_heard_m: float = 15.0
## The relay satellite that carries the music: how high it orbits, in the
## moon's radii, and how long a lap takes, minutes of world time. Its carrier
## slides this far either way as it comes and goes, kHz, and it fades in this
## far over the horizon, degrees. Its signal crosses the dust of a storm this
## high, m: the lower it is, the longer the way through.
@export var relay_altitude_radii: float = 3.0
## Short, so it crosses the night sky at least twice as fast as the stars and
## stands out from them, and not a whole share of a day, or it would cross
## the same sky at the same hour every time.
@export var relay_period_minutes: float = 6.5
@export var relay_doppler_khz: float = 1.5
@export var relay_rise_degrees: float = 8.0
## Zan and Tu's Lagrange points, where the relay and the Pendulum hang (a moon
## that keeps one face to its planet has no stationary orbit): this many moon
## radii from Zan's middle, toward Tu (L1) and away (L2), at the leaning size's
## real scale; each loops round its point on a halo this many radii across
## the line to Tu, once in this many minutes, about half a day as a real
## halo's is about half a month.
@export var lagrange_radii: float = 8.0
@export var halo_radii: float = 0.9
@export var halo_minutes: float = 10.0
@export var dust_height_m: float = 1500.0
## Frontier Ag's deliveryship (Deliveryship) is drawn this many times the size
## DeliveryshipLooks builds it: 2.3 makes it about 940 m tip to tip, under 2
## degrees across straight overhead from 30 km up.
@export var deliveryship_scale: float = 2.3
## The Eye's drone comes now and then out of silences of between these many
## minutes, its first one included.
@export var eye_quiet_minutes: Vector2 = Vector2(2.0, 8.0)
## How far ahead Port Morgan Tower reads the storm field at the tower, minutes,
## and how often it reads it again, s of world time.
@export var radio_forecast_minutes: float = 20.0
@export var radio_forecast_every: float = 5.0
## The gap between a report's composed words, s; and at most this often a
## god's or a beacon's changing words are read again, s of world time: the
## radio speaks only with news (Hunter, 2026-10-19: "probably announce less often").
@export var radio_word_gap_seconds: float = 0.04
@export var radio_report_every: float = 120.0
## Speech-only station character; weather and local computer speech stay unchanged.
@export var radio_voice_profiles: Dictionary = {}
## Its advisories: a sandstorm riding a prevailing wind this fast or faster,
## m/s, is fast; one lasting this long or longer, minutes, looked ahead this
## far, is large. Measured over 12 seeds and 6 hours each, the prevailing wind
## is 10.7 m/s at the median and 14.8 at the top tenth; a storm lasts 16
## minutes at the median and 54 at the top tenth.
@export var advisory_fast_ms: float = 14.5
@export var advisory_long_minutes: float = 45.0
@export var advisory_look_minutes: float = 60.0
## The weather station has nothing to report, and plays its clear-skies song,
## while no storm is on you or due within this many minutes. Clear for 5
## minutes ahead is about half of all clear time; for 20, almost never.
@export var radio_calm_minutes: float = 5.0
## How far a radio hears a beacon, m, and the share of ruins the seed left
## one running in.
@export var radio_reach_m: float = 3000.0
@export var beacon_share: float = 0.3
## The dial: a carrier comes in this wide either side, kHz (its fall to a
## sixtieth), and a notch of tuning moves it this far, or a fine step this far.
@export var dial_width_khz: float = 3.0
@export var dial_notch_khz: float = 10.0
@export var dial_fine_khz: float = 1.0
## Spun fast, the wheel goes farther a notch (gonkhub, 2026-10-19: "speed up
## frequency scrubbing with scrollwheel"; faster again, 2026-10-21): a notch
## within this long of the last, s, the same way, goes this many notches
## farther than that one did, up to this many notches at once. Fine steps
## never speed up.
@export var dial_spin_seconds: float = 0.2
@export var dial_spin_grow: float = 2.0
@export var dial_spin_most: float = 16.0
## Every broadcast is picked up near its home frequency too, at a share of its
## strength: a skirt this wide either side, kHz (its fall to a sixtieth of that
## share), so broadcasts near each other overlap and you tune in on the one
## you want (gonkhub, 2026-10-19). Within this many skirts of a carrier, the
## dial counts it as the one it hears.
@export var dial_skirt_khz: float = 20.0
## The FM band (VHF, 87.5 to 108 MHz, through an FM converter): a notch of
## tuning moves this far, MHz, or a fine step this far; a station comes in
## this wide either side, MHz.
@export var fm_notch_mhz: float = 0.1
@export var fm_fine_mhz: float = 0.02
@export var fm_width_mhz: float = 0.08
## How a VHF station reaches you, by line of sight over the moon's curve and
## the ground between: the curve as radio bends round it, against the true one
## (4/3, a standard atmosphere's); a station's margin over the noise a
## kilometre off with nothing in the way, dB; and how many points along the
## way the ground is read at.
@export var fm_bend: float = 1.3333
@export var fm_margin_db: float = 30.0
@export var fm_profile_points: int = 24
## The FM threshold: under this margin, dB, it's lost to hiss, and this many
## dB over it it's fully quiet. Two stations on one frequency: the stronger
## takes it whole once it's this many dB ahead (the capture ratio).
@export var fm_threshold_db: float = 0.0
@export var fm_quiet_db: float = 14.0
@export var fm_capture_db: float = 2.0
## Port Morgan's FM mast, m over the port's ground; the living city's, over
## its deck; a near god's, over its home.
@export var fm_mast_m: float = 60.0
@export var fm_city_mast_m: float = 20.0
@export var fm_god_mast_m: float = 30.0
## Wrecks calling SOS on the AM dial (Distress): this share of wrecks still
## call; a radio hears the nearest few within this far, m, on carriers spread
## either side of 240 kHz on longwave (Distress.KHZ), this far, kHz;
## each sends this strong (a god sends 1); and repeats its call this often, s.
@export var distress_share: float = 0.5
@export var distress_reach_m: float = 5000.0
@export var distress_spread_khz: float = 12.0
@export var distress_power: float = 0.9
@export var distress_every: float = 12.0
## The shortwave band (2 to 30 MHz, through a shortwave converter): a notch of
## tuning moves it this far, kHz; a fine step is the AM dial's.
@export var sw_notch_khz: float = 25.0
## A crystal set hears at this share of a field radio's strength, with no
## power to lift it, and plays this many dB quieter, into its earpiece, its
## knob gone; what it hears comes through no cleaner than this, of full dirt
## (Garble). A headset jacked into it, carried or in your hands, brings it
## nearer: quieter only this much, this clean (gonkhub, 2026-10-21: "much
## quieter ... hardly audible and highly distorted" without one).
@export var crystal_gain: float = 0.35
@export var crystal_quiet_db: float = 30.0
@export var crystal_dirt: float = 0.85
@export var crystal_headset_quiet_db: float = 12.0
@export var crystal_headset_dirt: float = 0.45
## An antenna reel holds this much wire, m: walked farther from its radio, its
## clip pops off the set.
@export var antenna_reel_m: float = 30.0
## A shortwave set's long wire: on its converter's terminals alone it hears
## this share of what's sent from above the ceiling; an antenna reel's wire
## strung out this long, m, hears all of it, strung low only this share,
## and fully once it's this high over the ground somewhere, m. Under the
## ceiling, on the AM dial, a wire adds nothing: the world's own noise is the
## floor there, not the set's.
@export var sw_bare: float = 0.25
@export var sw_wire_m: float = 10.0
@export var sw_wire_low: float = 0.75
@export var sw_wire_high_m: float = 3.0
## The antenna kite (AntennaKite), from the radio kit lab's charge model
## (look/radio_kit/charge_model.gd): on this much flying line, paid out and
## reeled in this fast, m/s. It flies from this wind, m/s, its line at the
## first of these angles, rising to the second in the first of its best winds
## and pressed back this many degrees each m/s past the second; the line sags
## to this share of it straight.
@export var kite_line_m: float = 120.0
@export var kite_payout_ms: float = 3.0
@export var kite_reel_ms: float = 4.0
@export var kite_lift_ms: float = 3.0
@export var kite_best_ms: Vector2 = Vector2(6.0, 12.0)
@export var kite_angle_deg: Vector2 = Vector2(25.0, 60.0)
@export var kite_pressed_deg: float = 2.0
@export var kite_sag: float = 0.85
## Its aerial on shortwave: about 10 dB a tenfold of height over the whip's
## height, m, to this many dB at most, from the set's bare terminals (sw_bare);
## heard at most this many times a full long wire.
@export var kite_whip_m: float = 0.3
@export var kite_gain_db: float = 26.0
@export var kite_gain_most: float = 2.5
## Its charge, 0 to 1 of what arcs for certain: gathered this fast a second
## at 100 m in clear air, and this fast in a front's full outflow; leaking off
## into the air over this long, s. Past the first, an arc may jump somewhere
## in the rig, its chance a second climbing with the square of how far past
## to the second at full; it spends this share of the charge, and burns out
## what it hits this share of the time (the rest it scorches). A driven stake
## its lead runs through dumps what's past this to earth, this share a
## second; a bleed resistor leaks it over this long, s.
@export var kite_charge_fair: float = 0.002
@export var kite_charge_dust: float = 0.06
@export var kite_air_tau: float = 240.0
@export var kite_arc: Vector2 = Vector2(0.25, 0.5)
@export var kite_arc_spends: float = 0.7
@export var kite_burns: float = 0.6
@export var kite_gap_at: float = 0.2
@export var kite_gap_rate: float = 0.5
@export var kite_bleed_tau: float = 20.0
## Its charge raises the set's static, at full this share of a front's.
@export var kite_static: float = 0.6
## Its wear: flying at all, over this long, s; past this wind, m/s, this
## share a second each m/s; in a sandstorm, gone in about this long, s.
@export var kite_wear_s: float = 21600.0
@export var kite_harm_ms: float = 14.0
@export var kite_wear_wind: float = 0.0011
@export var kite_storm_ruin_s: float = 75.0
## The radio's misc bay modules. The valve preamp lifts what it hears this
## many times; the static choke leaves this share of storm static, this share
## of the garbling, and this share of the signal; the direction loop's null
## is this deep, by day or night, within this much of end-on; tuned within
## this far of a carrier, kHz, a frequency counter locks on; a report heard
## dirtier than this the wire logger plays back clean; a headset's cord
## reaches this far, m, and turns the wind and storm down this many dB.
@export var preamp_gain: float = 2.0
@export var choke_static: float = 0.5
@export var choke_dirt: float = 0.6
@export var choke_signal: float = 0.8
@export var loop_null: float = 0.0
@export var loop_width: float = 0.1
@export var counter_lock_khz: float = 8.0
@export var logger_dirty: float = 0.3
@export var headset_cord_m: float = 3.0
@export var headset_duck_db: float = -14.0
## Tu's roar on shortwave: it comes in from the bottom of this span, kHz, to
## full at its top; Tu storms while Zan is within half of tu_roar_window (a
## share of a day) of one of these places round its orbit (shares of a day),
## as Io gates Jupiter's storms, and Tu's turn is within this far of bringing
## its source to face Zan, rad.
@export var tu_roar_khz: Vector2 = Vector2(15000.0, 21000.0)
@export var tu_roar_phases: PackedFloat32Array = PackedFloat32Array([0.25, 0.67])
@export var tu_roar_window: float = 0.12
@export var tu_roar_turn: float = 1.2
## The AM dial plays sound up to this, Hz: AM's narrow audio, and the FM
## converter's too, since it plays through the AM set.
@export var am_audio_hz: float = 5000.0
## A signal flare burns this long, s (Flare). The deliveryship fires its
## care-package cannon at a lit one it passes this high over, degrees, and the
## container takes this long to come down, s, landing this near the flare, m,
## the least and most (Airdrop). From 30 km up, 50 degrees is under 40 km off,
## so its boom (about two minutes coming) follows the container down.
@export var flare_burn_seconds: float = 60.0
@export var airdrop_elevation_degrees: float = 50.0
@export var airdrop_fall_seconds: float = 75.0
@export var airdrop_land_m: Vector2 = Vector2(12.0, 35.0)
## A home frequency wanders inside its band, no farther than this, kHz, from
## one moon day (or one hop) to the next (gonkhub, 2026-10-20).
@export var carrier_drift_khz: float = 5.0
@export var dial_skirt_share: float = 0.35
@export var dial_skirt_reach: float = 1.5
## Whether every tuning action brings the view in to the radio's face; off
## since gonkhub, 2026-10-19: "Stop the radio from zooming to the interface
## when interacting." The fine steps always do ("Bring back the pov zoom when
## using fine-tune shift scrolling"). It comes in this far off it, m,
## through this narrow a lens, degrees, easing in and out over about this
## long, s; it stays this long after the last turn, s, while you look at it.
@export var dial_close_up: bool = false
@export var dial_close_m: float = 0.45
@export var dial_close_fov: float = 40.0
@export var dial_close_seconds: float = 0.35
@export var dial_close_hold: float = 3.0
## A god's bearing is given to sixteen points within the first distance, m,
## to eight within the second, and past that only as a way across the moon.
@export var god_exact_m: float = 12000.0
@export var god_rough_m: float = 40000.0
## How far a ground wave carries at or under 500 kHz, m; above it the reach
## falls as the square of the frequency. At night a sky wave comes down past
## the skip, m, at this strength, for any frequency over 500 kHz.
@export var ground_wave_m: float = 80000.0
@export var skip_m: float = 15000.0
@export var sky_wave: float = 0.6
## Under this share of a clean signal, a transmission is lost in the static.
@export var signal_floor: float = 0.08
## The AM set's ferrite rod: a station end-on to it comes in at this share of
## its strength, its null; heard by sky wave at night, past the skip, only this
## deep, the sky wave coming down from above and wandering (the night effect,
## why real direction finders distrust night bearings).
@export var rod_null: float = 0.03
## The set's gain control holds a station's level as the rod turns, so it's
## heard falling away only within this much of end-on (the sine of the angle
## off its axis): a sharp null, as a real set's is.
@export var rod_width: float = 0.25
@export var rod_night_null: float = 0.45
## The storm on the path toward a god is read this far out at most, m, and
## at this many points. Through a full storm the carrier drifts this far
## either way, kHz, and the signal drops out this share of the time.
@export var interference_reach_m: float = 3000.0
@export var interference_samples: int = 12
## The way toward a signal is read from this far out, m, so a storm beside
## you blocks only what lies its way; and a storm that bad or worse on the way
## blocks a signal entirely.
@export var interference_near_m: float = 50.0
@export var storm_blocks: float = 0.5
@export var storm_warp_khz: float = 6.0
@export var storm_cuts: float = 0.6
## The Walker's pace round the Rim, m/s.
@export var walker_speed: float = 1.5

@export_group("The Walker and the living city")
## The Walker's log goes out weaker than its forecast: whole within the first
## distance, m, lost to noise past the second. It reads one entry this often,
## s: its survey, then each contact it keeps, the last this many.
@export var walker_log_m := Vector2(8000.0, 40000.0)
@export var walker_log_every: float = 8.0
@export var walker_contacts_kept: int = 6
## Taught, its feed flags an anomaly whose heart is this near the radio, m.
@export var walker_flag_m: float = 30000.0
## Where the living city keeps on the far side, degrees from under Tu; moored
## this many days at a time; each leg this long, m, made at the storms' own
## pace, m/s.
@export var city_from_tu_degrees := Vector2(105.0, 160.0)
@export var city_moored_days := Vector2(12.0, 24.0)
@export var city_leg_m := Vector2(4000.0, 9000.0)
@export var city_speed: float = 10.0
## One of its nomads prays to the Walker once in this many days.
@export var city_prayer_days := Vector2(0.6, 1.8)
## Its chatter on its own carrier in this band, kHz: whole within the first
## distance, m, and gone past the second; a motif this often, s. Storm coming
## warns this long ahead, s.
@export var city_band_khz := Vector2(1480.0, 1520.0)
@export var city_heard_m := Vector2(3000.0, 4500.0)
@export var city_chatter_every: float = 20.0
@export var city_warn_s: float = 240.0
## Its lights go out when you come this near, m: it isn't found by walking up.
@export var city_douse_m: float = 500.0
## Three noted bearings fix a place where they cross within this far of one
## another, m, none of them closer than this many degrees to another.
@export var triangulate_m: float = 3000.0
@export var triangulate_degrees: float = 8.0

@export_group("Console")
## How often a Console's instruments read the field, s of world time, and how
## often its screen looks for a change to draw, s. It draws only while someone
## stands this near, m: farther off it can't be read.
@export var console_read_every: float = 1.0
@export var console_screen_every: float = 0.25
@export var console_screen_seen_m: float = 15.0
## The air's pressure where the storm field sits at its threshold, hPa (the
## moon's thin air, the-moon.md), and how far it falls for each unit the field
## rises, hPa: so it falls as a storm comes. The barometer reads its trend over
## this long, s, and warns of a front it would reach within this long, minutes.
@export var air_pressure_hpa: float = 310.0
@export var air_pressure_fall: float = 8.0
@export var barometer_trend_seconds: float = 120.0
@export var barometer_warn_minutes: float = 15.0
## Humidity in the cold air a condenser makes its most in, 0 to 1, falling
## with its yield as the air warms; what a storm's air adds, and how far
## ahead of its front the air grows humid, in the field's own units (about a
## kilometre or two).
@export var humidity_cold: float = 0.6
@export var humidity_storm: float = 0.25
@export var humidity_reach: float = 0.25
## Sand in the air at a storm's heart, g/m³; the share of it at its wall,
## and the share a front's outflow carries ahead of the wall.
@export var sand_full_g_m3: float = 3.0
@export var sand_wall_share: float = 0.3
@export var sand_outflow_share: float = 0.1
## A radar sweeps this many bearings, one a tick, stepping out this far, m.
@export var radar_bearings: int = 36
@export var radar_step_m: float = 100.0
## The storm map's cells across: a radar alone draws this many, each other
## kind of instrument this many more, and a second radar linked half as many
## again. With no radar its other instruments only estimate a map, this
## coarse with one and this many more with each other kind, odd so that
## where it stands has a cell. It's sampled again this often, s of world time.
@export var storm_map_radar_cells: int = 8
@export var storm_map_cells_per_instrument: int = 4
@export var storm_map_second_radar: float = 1.5
@export var storm_map_estimate_cells: int = 3
@export var storm_map_estimate_per_instrument: int = 2
@export var storm_map_every: float = 1.0
## A smart shield switches itself on once the radar sees a front this near, m.
@export var smart_shield_auto_m: float = 1500.0
## A Console with a radio in its system says aloud that its battery is low,
## then critical, once each as what its pool has left to run it on falls past
## these shares: the charge above where it gives way (Power).
@export var console_battery_low: float = 0.2
@export var console_battery_critical: float = 0.05

@export_group("Loose objects")
## Wind drag per (m/s)² per m² of a thing's biggest face: half the air density
## times its drag coefficient. Matched to the rope look-test's floater, the feel
## Hunter judged, so floating things swing and drift and resting ones slide
## only when the wind beats their friction.
@export var wind_catch_per_m2: float = 0.5
## The share of its weight the sand holds a resting body by: the sand's own
## friction, as Godot's Jolt takes the lesser of two and bodies keep 1.0.
@export var sand_friction: float = 0.5
## Runner face clearance before settled spring compression, m.
@export var runner_clearance: float = 0.04

@export_group("Wind on faces")
## A face with another just upwind square across it catches this share of
## what it would alone: the one in front took the wind (Faces).
@export var face_shaded: float = 0.1
## A frame open into the wind with its back closed, and every side round
## about, catches this many times what its back would flat: a parachute's
## cup against a flat plate's drag.
@export var face_cup: float = 1.3


@export_group("Survey receiver")
@export var receiver_reach_m: float = 1200.0
@export var receiver_w: float = 0.5
@export var receiver_band_khz: float = 40.0
@export var receiver_side_gain: float = 0.08
@export var receiver_meter_steps: int = 8
@export var receiver_approach_m: float = 60.0
@export var receiver_arrive_m: float = 15.0
@export var receiver_faint: float = 0.2
@export var receiver_strong: float = 0.6
@export var receiver_signal_min: float = 0.01
@export var receiver_deed_strength: float = 0.05
@export var receiver_storm_loss: float = 0.5
@export var receiver_hiss_clear: float = 0.035
@export var receiver_hiss_empty: float = 0.15
@export var receiver_hiss_storm: float = 0.25
@export var receiver_hiss_duck: float = 0.8


## One shared instance, held here so probe overrides can't be dropped by the
## resource cache between being set and being read.
static func current() -> Tuning:
	if _current == null:
		_current = load(PATH)
	return _current

## Physical sail boom: gooseneck rotational damping and the spar's collision
## clearance round the mast, m. Sail mass remains the fitted part's mass.
@export var boom_hinge_drag: float = 0.8
@export var boom_root_clearance: float = 0.01

@export_group("Hand winch")
@export var winch_notch_m: float = 0.25
@export var winch_pace_mps: float = 0.9
@export var winch_pull_n: float = 500.0
@export var winch_min_m: float = 0.2
@export var winch_drum_radius: float = 0.09
@export var halyard_lower_seconds: float = 1.5
@export var winch_hoist_deed: float = 0.95
@export_group("Expedition horizons")
## Foot radius and summit rise, metres. Gentle broad approaches remain walkable.
@export var starcom_mountain := Vector2(2400.0, 600.0)
@export var observatory_mountain := Vector2(3600.0, 950.0)
## Cheap background ground beyond the ordinary far ring; geometric radial spacing.
@export var horizon_apron_rings: int = 20
@export var horizon_apron_sides: int = 128
@export var horizon_step := 128.0
@export var horizon_range := Vector2(24000.0, 42000.0)
@export var mountain_bedrock_depth := 40.0
@export var horizon_drop_m := 8.0
@export var mountain_rock := Color(0.38, 0.34, 0.30)
@export var mountain_rock_height := Vector2(60.0, 180.0)

@export_group("Marked Home")
## Admission limits include the camp's owned assembly and supporting terrain halo.
@export var home_max_bodies: int = 160
@export var home_span_m: float = 128.0
@export var home_support_chunks: int = 49
@export var home_signal_m: float = 2000.0
@export var home_beacon_w: float = 1.0
@export var home_depart_m: float = 700.0
@export var home_return_m: float = 30.0
## Between rebuilds of Home's membership a drifting belonging is noticed this late, s.
@export var home_sweep_s: float = 1.0
## The beacon's lamp blinks at this period while Home's ground is made ready, s.
@export var home_beacon_blink_s: float = 1.0

@export_group("Surveyor arrival")
## Provisional recovery rules for the integrated development opening.
@export var surveyor_arrival: Dictionary = {}
## Cabin preparation and bounded approach/impact choices.
@export var surveyor_preflight: Dictionary = {}


@export_group("Ground posture")
@export var posture_sit_height: float = 1.15
@export var posture_prone_height: float = 0.7
@export var posture_sit_eye: float = 1.0
@export var posture_prone_eye: float = 0.5
@export var posture_crawl_speed: float = 0.55
@export var posture_camera_seconds: float = 0.22
@export var posture_sit_catch: float = 0.6
@export var posture_prone_catch: float = 0.25
