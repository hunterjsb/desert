class_name WallAtmosphere
extends Node
## Every light, sky and fog setting in the look-test, read from the storm field:
## the sun, ambient, sky, haze, and the light the storm shaders are lit by.
## Anything else driving the World's sun or environment must be off while this runs.

## [name, degrees round from where the storm comes from, degrees up]
const SUNS := [
	["over the storm", 40.0, 30.0],
	["to the side", 95.0, 32.0],
	["behind you", 170.0, 34.0],
]

@export var sun_color := Color(1.0, 0.95, 0.86)
@export var sun_energy := 1.0
@export var ambient_color := Color(0.8, 0.72, 0.62)
@export var ambient_energy := 0.75
@export var dust_color := Color(0.7, 0.56, 0.42)
@export var haze_color := Color(0.86, 0.76, 0.62)
@export var haze_begin := 400.0
@export var haze_end := 9000.0
## Most the haze ever hides, at haze_end and beyond.
@export var haze_strength := 0.7
## Share of the ground's light that comes straight from the sun.
@export var sun_share := 0.7
## Light left inside the storm, as a share of outside.
@export var inside_light := 0.22
## How bright the heart of the storm glows from light scattered many times.
@export var storm_glow := 0.3

var sun_index := 0
## What the readout shows: sun reaching the camera, sky the wall covers, how far in.
var camera_sun := 1.0
var coverage := 0.0
var inside := 0.0
var camera_sigma := 0.0

var _world: World
var _storm: WallStorm
var _env: Environment
var _sun: DirectionalLight3D


func setup(world: World, storm: WallStorm) -> void:
	_world = world
	_storm = storm
	_env = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	_sun = world.get_node("Sun")
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_depth_begin = haze_begin
	_env.fog_depth_end = haze_end
	_env.fog_depth_curve = 1.0
	_env.fog_density = haze_strength
	_env.fog_light_color = haze_color
	_sun.light_color = sun_color
	# The face pass draws the disc, so the wall can cover it.
	_sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_storm.set_light("dust_albedo", _linear(dust_color))
	_storm.set_light("storm_glow", storm_glow)
	_storm.set_light("haze", Vector4(haze_begin, haze_end, haze_strength, 1.0))
	_storm.set_light("sun_share", sun_share)


func sun_name() -> String:
	return SUNS[sun_index][0]


func next_sun() -> void:
	sun_index = (sun_index + 1) % SUNS.size()


## Toward the sun, in world axes.
func sun_direction() -> Vector3:
	var from := (-_storm.dir).rotated(deg_to_rad(SUNS[sun_index][1]))
	var up := deg_to_rad(SUNS[sun_index][2])
	return Vector3(from.x * cos(up), sin(up), from.y * cos(up)).normalized()


func apply(camera: Camera3D) -> void:
	var to_sun := sun_direction()
	_sun.global_basis = Basis.looking_at(-to_sun, Vector3.UP)

	var q := _storm.camera_frame(camera)
	var edge := _storm.edge_at(q)
	var distance := _storm.face_distance()
	# The same billow that engulfs you on screen sets the light, not a trigger.
	inside = smoothstep(0.0, 55.0, edge)
	camera_sigma = _storm.sigma * inside
	camera_sun = maxf(_storm.sun_through(_storm.sun_path(q, to_sun)), 0.02)
	# Half the sky is wall once it towers overhead; all of it once you're in.
	var towering := atan2(_storm.height - q.y, maxf(distance, 1.0)) / (PI * 0.5)
	coverage = lerpf(clampf(towering, 0.0, 1.0) * 0.5, 1.0, inside)

	var dim := lerpf(1.0, inside_light, inside)
	var sky_left := 1.0 - 0.55 * coverage
	_sun.light_energy = sun_energy * camera_sun * dim
	_env.ambient_light_color = ambient_color
	_env.ambient_light_energy = ambient_energy * sky_left * dim
	_env.background_energy_multiplier = lerpf(1.0, 0.45, coverage) * dim
	_env.fog_light_energy = sky_left * dim

	var dust := _linear(dust_color)
	var sun_light := _linear(sun_color) * sun_energy
	# A wall faces half the sky, so it gets less than open ground.
	var sky_light := _linear(ambient_color) * ambient_energy * 0.75
	_storm.set_light("sun_dir", to_sun)
	_storm.set_light("sun_light", sun_light)
	_storm.set_light("sky_light", sky_light)
	_storm.set_light("camera_sun", camera_sun)
	_storm.set_light("haze_color", _linear(haze_color) * sky_left * dim)
	# Grains catch more light than the haze they fly through.
	_storm.set_dust(dust * (sun_light * camera_sun * 0.5 + sky_light * sky_left) * dim * 1.8, camera_sigma)

	Dev.put("wall/sun", sun_name())
	Dev.put("wall/camera_sun", camera_sun)
	Dev.put("wall/coverage", coverage)
	Dev.put("wall/inside", inside)


static func _linear(color: Color) -> Vector3:
	var c := color.srgb_to_linear()
	return Vector3(c.r, c.g, c.b)
