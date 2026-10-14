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
## Main-thread time spent uploading finished chunks, per frame.
@export var frame_upload_budget_ms: float = 4.0
## No single chunk upload may block the main thread longer than this.
@export var chunk_upload_max_ms: float = 4.0
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

@export_group("Loose objects")
## Drag per (m/s)^2 of wind on a loose object: half the air density times drag
## coefficient times area. Thin air, a half-metre box.
@export var loose_wind_catch: float = 0.05


## One shared instance, held here so probe overrides can't be dropped by the
## resource cache between being set and being read.
static func current() -> Tuning:
	if _current == null:
		_current = load(PATH)
	return _current
