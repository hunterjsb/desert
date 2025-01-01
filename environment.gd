extends Node3D

@export var day_length_seconds := 300
@export var time_of_day_minutes := 0  # Start at midnight by default
@export var update_interval := 1

@onready var time_accumulated = 0

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var moon: DirectionalLight3D = $MoonDirectionalLight3D
# @onready var stars: MeshInstance3D = $Stars

var dawn_color = Color(0.9, 0.7, 0.4)
var noon_color = Color(1.0, 1.0, 0.9)
var dusk_color = Color(0.6, 0.4, 0.5)
var night_color = Color(0.1, 0.1, 0.2)

func _ready():
	# Just to ensure our nodes start at zero rotation in code:
	sun.rotation_degrees = Vector3.ZERO
	moon.rotation_degrees = Vector3.ZERO

func _process(delta):
	time_accumulated += delta
	if time_accumulated >= update_interval:
		time_accumulated -= update_interval
		_update_time()

func _update_time():
	var total_day_minutes = 24 * 60
	var minutes_per_interval = total_day_minutes / (day_length_seconds / update_interval)
	time_of_day_minutes = (time_of_day_minutes + minutes_per_interval) % total_day_minutes

	# --------------------------------------------------
	# 1) Compute "day progress" from 0..1
	#    - 0 == midnight, 0.5 == noon, 1 == next midnight
	# --------------------------------------------------
	var day_progress := time_of_day_minutes / float(total_day_minutes)

	# --------------------------------------------------
	# 2) Calculate Sun's position:
	#    - We spin the azimuth 360° across the full day
	#    - A sine wave for altitude is more "realistic":
	#      altitude = +some_degrees during day, -some_degrees at night
	#      You can tweak the amplitude or offset to taste.
	# --------------------------------------------------
	var sun_azimuth := day_progress * 360.0  # East-to-West spin
	var sun_altitude := 45.0 * sin(day_progress * TAU)  # peaks ~ noon

	# Optional offset to ensure sunrise at ~east:
	# If you consider "day_progress=0" as midnight,
	# you might shift azimuth so that at day_progress=0.25, you get sunrise in the East:
	# sun_azimuth = (day_progress * 360.0) - 90.0
	# Adjust if you prefer a different offset.

	sun.rotation_degrees = Vector3(sun_altitude, sun_azimuth, 0)

	# --------------------------------------------------
	# 3) Calculate Moon's position:
	#    - Typically opposite the sun by ~180 degrees,
	#      but you can also vary altitude with a phase offset.
	#    - For simplicity, let's keep the same "sine" amplitude
	#      and shift day_progress by +0.5 (12 hours out of phase).
	# --------------------------------------------------
	var moon_day_progress := fmod((day_progress + 0.5), 1.0)
	var moon_azimuth := moon_day_progress * 360.0
	var moon_altitude := 45.0 * sin(moon_day_progress * TAU)

	moon.rotation_degrees = Vector3(moon_altitude, moon_azimuth, 0)

	# --------------------------------------------------
	# 4) Update environment sky & lighting
	# --------------------------------------------------
	var sky_color = get_sky_color()
	world_environment.environment.volumetric_fog_albedo = sky_color
	world_environment.environment.ambient_light_color = sky_color.darkened(0.5)

	var sun_energy = get_light_energy()
	sun.light_energy = sun_energy
	world_environment.environment.ambient_light_energy = sun_energy * 0.5

	# Stars fade
	var fade = _get_star_fade()
	# stars.visible = fade > 0.0
	# stars.material_override.set("shader_param/opacity", fade)

func get_sky_color():
	# Use the same time-of-day thresholds from your snippet
	if time_of_day_minutes < 360:
		return lerp(night_color, dawn_color, time_of_day_minutes / 360.0)
	elif time_of_day_minutes < 720:
		return lerp(dawn_color, noon_color, (time_of_day_minutes - 360) / 360.0)
	elif time_of_day_minutes < 1080:
		return lerp(noon_color, dusk_color, (time_of_day_minutes - 720) / 360.0)
	else:
		return lerp(dusk_color, night_color, (time_of_day_minutes - 1080) / 360.0)

func get_light_energy():
	if time_of_day_minutes < 360:
		return lerp(0.1, 1.0, time_of_day_minutes / 360.0)
	elif time_of_day_minutes < 720:
		return lerp(1.0, 1.5, (time_of_day_minutes - 360) / 360.0)
	elif time_of_day_minutes < 1080:
		return lerp(1.5, 1.0, (time_of_day_minutes - 720) / 360.0)
	else:
		return lerp(1.0, 0.1, (time_of_day_minutes - 1080) / 360.0)

func _get_star_fade():
	# From your snippet, just extracted for clarity
	# Fades in stars at night (00:00-06:00) and after 18:00
	# "360" = 6 hours, "1080" = 18 hours, "720" = 12 hours
	if time_of_day_minutes < 360 or time_of_day_minutes > 1080:
		return 1.0
	else:
		# Fade out from 06:00 -> 12:00 and 12:00 -> 18:00
		return clamp(1.0 - abs(720 - time_of_day_minutes) / 360.0, 0.0, 1.0)
