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
@export var haze_begin: float = 800.0
@export var haze_end: float = 3000.0

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


## One shared instance, held here so probe overrides can't be dropped by the
## resource cache between being set and being read.
static func current() -> Tuning:
	if _current == null:
		_current = load(PATH)
	return _current
