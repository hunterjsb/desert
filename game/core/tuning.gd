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

@export_group("Terrain")
@export var chunk_size: int = 64
## Chunks within this many of the player's get collision.
@export var near_radius: int = 2
## Chunks within this many of the player's are drawn.
@export var view_radius: int = 8
@export var mid_step: int = 4
@export var far_step: int = 32
@export var far_radius: float = 3000.0
## The far ring sits this far below the chunks it overlaps, so they win.
@export var far_drop: float = 1.0
@export var skirt_depth: float = 2.0
@export var dune_amplitude: float = 6.0
@export var dune_wavelength: float = 160.0
@export var dune_octaves: int = 3
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

@export_group("Weather")
## One full day and night, start to finish.
@export var day_minutes: float = 20.0
## Where in the day a run begins: 0 is midnight, 0.5 is noon.
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

@export_group("Storm")
## How far you can see inside a storm, in metres.
@export var storm_visibility: float = 20.0
## Share of the light a full storm takes.
@export var storm_darkness: float = 0.78
@export var storm_fog_color: Color = Color(0.62, 0.4, 0.2)
## Placeholder harm per second at full storm, until Survival has health.
@export var storm_harm_rate: float = 1.0

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

@export_group("Player")
## About 5 km/h, the pace the moon's size was set against.
@export var walk_speed: float = 1.4
@export var sprint_speed: float = 3.0
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

@export_group("Devices")
## A hover tray holds a device's middle this high over the sand, m.
@export var hover_height: float = 1.2
@export var hover_hertz: float = 1.0
@export var hover_damping: float = 0.8
@export var hover_upright_hertz: float = 1.6
## What hovering costs, W per kg floated. Power (Stage 4) drains it.
@export var hover_watts_per_kg: float = 2.0
## The magnetic tug reaches this far from a free socket, m.
@export var snap_reach: float = 0.3
## Inside this, the part snaps home on its own, m.
@export var snap_home: float = 0.04
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

@export_group("Power")
## Seconds of world time per power tick.
@export var power_tick: float = 0.25
## A turbine's output, W per (m/s)³ of felt wind, up to its rating.
@export var turbine_watts_per_cubic: float = 0.0128

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
