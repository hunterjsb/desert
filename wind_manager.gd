extends Node

signal cardinal_direction_changed(new_dir: float)
signal gust_started()
signal gust_ended()

@export var base_wind_strength: float = 1.0
@export var max_wind_variation: float = 3.0

@export var gust_chance: float = 0.2
@export var gust_multiplier: float = 2.0
@export var gust_duration: float = 2.0
@export var gust_interval: float = 5.0

@export var dir_noise_freq_low: float = 0.1
@export var dir_noise_freq_high: float = 1.0

@export var strength_noise_freq_low: float = 0.3
@export var strength_noise_freq_high: float = 2.0

@export var gust_ramp_speed: float = 3.0
@export var major_dir_rotate_speed: float = 0.05
@export var major_dir_switch_interval: float = 30.0
@export var local_dir_noise_amplitude: float = 0.3

var time_elapsed: float = 0.0
var gust_timer: float = 0.0
var is_gusting = false
var current_gust_factor: float = 1.0

var current_wind_vector: Vector3 = Vector3.ZERO

# We'll define 0°, 90°, 180°, 270° as possible cardinal directions
var major_dir_angle_current: float = 0.0
var major_dir_angle_target: float = 0.0
var major_dir_switch_timer: float = 0.0

# Noise objects
var dir_noise_low = FastNoiseLite.new()
var dir_noise_high = FastNoiseLite.new()
var strength_noise_low = FastNoiseLite.new()
var strength_noise_high = FastNoiseLite.new()

func _ready():
	dir_noise_low.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	dir_noise_low.frequency = dir_noise_freq_low
	dir_noise_low.seed = randi()

	dir_noise_high.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	dir_noise_high.frequency = dir_noise_freq_high
	dir_noise_high.seed = randi() + 100

	strength_noise_low.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	strength_noise_low.frequency = strength_noise_freq_low
	strength_noise_low.seed = randi() + 200

	strength_noise_high.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	strength_noise_high.frequency = strength_noise_freq_high
	strength_noise_high.seed = randi() + 300

	major_dir_angle_current = pick_new_cardinal_angle()
	major_dir_angle_target = major_dir_angle_current

func _process(delta: float) -> void:
	time_elapsed += delta
	gust_timer -= delta

	# GUST LOGIC
	if gust_timer <= 0.0 and not is_gusting:
		gust_timer = gust_interval
		if randf() < gust_chance:
			start_gust()

	var gust_target = gust_multiplier if is_gusting else 1.0
	current_gust_factor = lerp(current_gust_factor, gust_target, delta * gust_ramp_speed)

	# SWITCH MAJOR DIRECTION LOGIC
	major_dir_switch_timer -= delta
	if major_dir_switch_timer <= 0.0:
		major_dir_switch_timer = major_dir_switch_interval
		var old_angle = major_dir_angle_target
		major_dir_angle_target = pick_new_cardinal_angle()

		# If you want to note a cardinal direction change, let's do it when we pick a new target
		if major_dir_angle_target != old_angle:
			emit_signal("cardinal_direction_changed", major_dir_angle_target)

	# LERP (SLOWLY) TOWARD THE MAJOR DIRECTION
	major_dir_angle_current = lerp_angle(major_dir_angle_current, major_dir_angle_target, delta * major_dir_rotate_speed)

	# BUILD BASE DIRECTION (XZ plane)
	var major_dir_radians = deg_to_rad(major_dir_angle_current)
	var major_direction = Vector3(cos(major_dir_radians), 0, sin(major_dir_radians))

	# LOCAL NOISE
	var local_x = dir_noise_low.get_noise_1d(time_elapsed) + 0.4 * dir_noise_high.get_noise_1d(time_elapsed * 3.0)
	var local_z = dir_noise_low.get_noise_1d(time_elapsed + 123.45) + 0.4 * dir_noise_high.get_noise_1d((time_elapsed + 123.45) * 3.0)
	var local_offset = Vector3(local_x, 0, local_z) * local_dir_noise_amplitude

	var combined_dir = (major_direction + local_offset).normalized()

	# WIND STRENGTH
	var base_variation = strength_noise_low.get_noise_1d(time_elapsed) * max_wind_variation
	var high_variation = strength_noise_high.get_noise_1d(time_elapsed * 4.0) * (max_wind_variation * 0.3)
	var total_variation = base_variation + high_variation
	var wind_strength = base_wind_strength + total_variation
	wind_strength = clamp(wind_strength, 0.0, base_wind_strength + max_wind_variation)
	wind_strength *= current_gust_factor

	current_wind_vector = combined_dir * wind_strength

func pick_new_cardinal_angle() -> float:
	var angles = [0.0, 90.0, 180.0, 270.0]
	return angles[randi() % angles.size()]

func start_gust():
	is_gusting = true
	gust_timer = gust_duration
	var t = create_timer(gust_duration)
	t.timeout.connect(_end_gust)
	emit_signal("gust_started")

func _end_gust():
	is_gusting = false
	emit_signal("gust_ended")

func get_wind_vector() -> Vector3:
	return current_wind_vector

func create_timer(wait_time: float, one_shot: bool = true) -> Timer:
	var timer = Timer.new()
	timer.one_shot = one_shot
	timer.wait_time = wait_time
	add_child(timer)
	timer.start()
	return timer
