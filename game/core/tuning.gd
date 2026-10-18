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
@export var spawn_latitude_degrees: float = 0.0
@export var spawn_longitude_degrees: float = 0.0
## Surface gravity, m/s². The body research leans toward 0.4-0.5 g; F6 tries it live.
@export var gravity: float = 9.8
## How many chunks the player may stray from the engine origin before the
## world shifts back, keeping 32-bit positions precise.
@export var origin_shift_chunks: int = 4

@export_group("Saves")
## A Normal run saves itself after this many minutes of play since its last
## save. The first storm comes in three to eight, so dying in it leaves a save
## to go back to.
@export var autosave_minutes: float = 3.0

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
@export var haul_from: float = 0.35
@export var haul_slow: float = 0.35
@export var haul_stamina_drain: float = 10.0
## How quickly you dig in and come back up, s.
@export var haul_seconds: float = 0.4

@export_group("Hoverboard")
## Flat out on the flat in still air, m/s: 72 km/h, faster than any storm
## front rides the wind (the prevailing wind's 10 m/s swings up to 14).
@export var board_top_speed: float = 20.0
## The push from a standstill, m/s²; drag grows with speed² until it matches
## the push at top speed. Enough to climb a slip face at about 11 m/s.
@export var board_push: float = 6.5
## The share of that drag that's the air's, felt against the wind: a tailwind
## carries you faster, a headwind holds you back, and a tuck shows it less.
@export var board_air_share: float = 0.35
## Move back brakes this hard, m/s²; coasting, the hover's own drag slows
## you this much, m/s².
@export var board_brake: float = 8.0
@export var board_coast: float = 0.3
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
## Its underside rides this high over the sand, m, and never comes nearer than this.
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
## A hop, m/s up, and this much more from a full crouch.
@export var board_hop: float = 4.0
@export var board_pop: float = 1.5
## What it draws, W: floating, and on top of that at full push. A base
## battery's 100 Wh lasts twenty minutes flat out, about 24 km.
@export var board_hover_w: float = 40.0
@export var board_push_w: float = 260.0
## Racked on a crate, it charges from the camp at up to this, W: a base
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
## rides higher. The kit's crate rides with its middle about 1.2 m up.
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
## How fast what you hold comes to where you'd have it, 1/s, and the most it
## comes faster than you, m/s, so nothing you swing round is flung.
@export var hold_rate: float = 4.0
@export var hold_speed: float = 2.0
## What you hold slips from your hands this far from where you'd have it, m.
@export var hold_slip: float = 1.5

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
## 2.9 kg, and every carryable thing of it, its stake, its board with the
## board's battery and the light panel too, 20.9 kg.
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

@export_group("Salvage")
## Ruins and finds. Probes of other systems switch them off, as ground probes
## still the air, so a buried crate never stands in what they measure.
@export var salvage: bool = true
## Finds in a chunk of open sand, on average, and at most.
@export var finds_per_chunk: float = 1.5
@export var finds_most: int = 4
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

@export_group("Radio")
## What a radio draws while it's on, W.
@export var radio_w: float = 2.0
## How far ahead the weather station reads the storm field, minutes, and how
## often it reads it again, s of world time.
@export var radio_forecast_minutes: float = 20.0
@export var radio_forecast_every: float = 5.0
## How far a radio hears a beacon, m, and the share of ruins the seed left
## one running in.
@export var radio_reach_m: float = 3000.0
@export var beacon_share: float = 0.3

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
## with its yield as the air warms, and what a full storm's air adds.
@export var humidity_cold: float = 0.6
@export var humidity_storm: float = 0.25
## Sand in the air at a storm's heart, g/m³; the share of it at its wall,
## and the share a front's outflow carries ahead of the wall.
@export var sand_full_g_m3: float = 3.0
@export var sand_wall_share: float = 0.3
@export var sand_outflow_share: float = 0.1
## A radar sweeps this many bearings, one a tick, stepping out this far, m.
@export var radar_bearings: int = 36
@export var radar_step_m: float = 100.0
## Cells across the storm map a full set of instruments draws.
@export var storm_map_screen_cells: int = 18
## A smart shield switches itself on once the radar sees a front this near, m.
@export var smart_shield_auto_m: float = 1500.0

@export_group("Loose objects")
## Wind drag per (m/s)² per m² of a thing's biggest face: half the air density
## times its drag coefficient. Matched to the rope look-test's floater, the feel
## Hunter judged, so floating things swing and drift and resting ones slide
## only when the wind beats their friction.
@export var wind_catch_per_m2: float = 0.5
## What something resting on the sand feels. Jolt takes the geometric mean of
## two frictions, so the sand itself is this squared, against a body's 1.0.
@export var sand_friction: float = 0.5


## One shared instance, held here so probe overrides can't be dropped by the
## resource cache between being set and being read.
static func current() -> Tuning:
	if _current == null:
		_current = load(PATH)
	return _current
