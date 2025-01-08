@tool
extends Node3D

const HOURS_IN_DAY : float = 24.0
const DAYS_IN_YEAR : int = 365

@export_range( 0.0, HOURS_IN_DAY, 0.0001 ) var day_time : float = 0.0 :
	set( value ) :
		day_time = value
		if day_time < 0.0 :
			day_time += HOURS_IN_DAY
			day_of_year -= 1
		elif day_time > HOURS_IN_DAY :
			day_time -= HOURS_IN_DAY
			day_of_year += 1
		_update()

@export_range( -90.0, 90.0, 0.01 ) var latitude : float = 0 :
	set( value ) :
		latitude = value
		_update()

@export_range( 1, DAYS_IN_YEAR, 1 ) var day_of_year : int = 1 :
	set( value ) :
		day_of_year = value
		_update()

@export_range( -180.0, 180.0, 0.01 ) var planet_axial_tilt : float = 23.44 :
	set( value ) :
		planet_axial_tilt = value
		_update()

@export_range( -180.0, 180.0, 0.01 ) var moon_orbital_inclination : float = 5.14:
	set( value ) :
		moon_orbital_inclination = value
		_update_moon()

@export_range( 0.1, DAYS_IN_YEAR, 0.01 ) var moon_orbital_period : float = 29.5 :
	set( value ) :
		moon_orbital_period = value
		_update_moon()

@export_range( 0.0, 1.0, 0.01 ) var clouds_cutoff : float = 0.3 :
	set( value ) :
		clouds_cutoff = value
		_update_clouds()

@export_range( 0.0, 1.0, 0.01 ) var clouds_weight : float = 0.0 :
	set( value ) :
		clouds_weight = value
		_update_clouds()

@export var use_day_time_for_shader : bool = false :
	set( value ) :
		use_day_time_for_shader = value
		_update_shader()

@export_range( 0.0, 1.0, 0.0001 ) var time_scale : float = 0.01 :
	set( value ) :
		time_scale = value

@export_range( 0.0, 10.0, 0.01 ) var sun_base_energy : float = 0.0 :
	set( value ) :
		sun_base_energy = value
		_update_shader()

@export_range( 0.0, 10.0, 0.01 ) var moon_base_enegry : float = 0.0 :
	set( value ) :
		moon_base_enegry = value
		_update_shader()

# ---------------------------------------
# NEW: This is the factor we will tween from sand_storm.gd
@export var storm_multiplier: float = 1.0
# ---------------------------------------

@onready var environment : WorldEnvironment = $WorldEnvironment
@onready var sun : DirectionalLight3D = $Sun
@onready var moon : DirectionalLight3D = $Moon

func _ready() -> void :
	if is_instance_valid(sun):
		sun.position = Vector3( 0.0, 0.0, 0.0 )
		sun.rotation = Vector3( 0.0, 0.0, 0.0 )
		sun.rotation_order = EULER_ORDER_ZXY
		if sun_base_energy == 0.0 :
			sun_base_energy = sun.light_energy
	if is_instance_valid(moon):
		moon.position = Vector3( 0.0, 0.0, 0.0 )
		moon.rotation = Vector3( 0.0, 0.0, 0.0 )
		moon.rotation_order = EULER_ORDER_ZXY
		if moon_base_enegry == 0.0 :
			moon_base_enegry = moon.light_energy
	_update()

func _process(delta: float) -> void :
	if not Engine.is_editor_hint():
		day_time += delta * time_scale

func _update() -> void :
	_update_sun()
	_update_moon()
	_update_clouds()
	_update_shader()

func _update_sun() -> void :
	if is_instance_valid(sun):
		var day_progress : float = day_time / HOURS_IN_DAY
		# Sunrise / Sunset
		sun.rotation.x = ( day_progress * 2.0 - 0.5 ) * -PI

		# Seasonal tilt
		var earth_orbit_progress = ( float(day_of_year) + 193.0 + day_progress ) / float(DAYS_IN_YEAR)
		sun.rotation.y = deg_to_rad(cos(earth_orbit_progress * PI * 2.0) * planet_axial_tilt)
		sun.rotation.z = deg_to_rad(latitude)

		var sun_direction = sun.to_global(Vector3(0.0, 0.0, 1.0)).normalized()
		# Base day-night logic
		var day_night_energy = smoothstep(-0.05, 0.1, sun_direction.y) * sun_base_energy

		# ------------------------------------------
		# Multiply by storm_multiplier, so it dims if storm_multiplier < 1
		sun.light_energy = day_night_energy * storm_multiplier
		# ------------------------------------------

func _update_moon() -> void :
	if is_instance_valid(moon):
		var day_progress : float = day_time / HOURS_IN_DAY
		var moon_orbit_progress : float = ( fmod(float(day_of_year), moon_orbital_period) + day_progress ) / moon_orbital_period
		moon.rotation.x = ((day_progress - moon_orbit_progress) * 2.0 - 1.0 ) * PI

		var axial_tilt = moon_orbital_inclination
		axial_tilt += planet_axial_tilt * sin((day_progress * 2.0 - 1.0 ) * PI)
		moon.rotation.y = deg_to_rad(axial_tilt)
		moon.rotation.z = deg_to_rad(latitude)

		var moon_direction = moon.to_global(Vector3( 0.0, 0.0, 1.0 )).normalized()
		moon.light_energy = smoothstep( -0.05, 0.1, moon_direction.y ) * moon_base_enegry

func _update_clouds() -> void :
	if is_instance_valid(environment):
		environment.environment.sky.sky_material.set_shader_parameter("clouds_cutoff", clouds_cutoff)
		environment.environment.sky.sky_material.set_shader_parameter("clouds_weight", clouds_weight)

func _update_shader() -> void :
	if is_instance_valid(environment):
		environment.environment.sky.sky_material.set_shader_parameter(
			"overwritten_time",
			( day_of_year * HOURS_IN_DAY + day_time ) * 100.0 if use_day_time_for_shader else 0.0
		)
