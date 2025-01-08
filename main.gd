extends Node3D

@export var min_storms := 2
@export var max_storms := 5

@export var spawn_radius := 1000
@export var storm_area_min := 20
@export var storm_area_max := 60
@export var storm_height_min := 20
@export var storm_height_max := 40
@export var min_spawn_distance := 600 # Minimum distance from the player

@onready var wind_manager = $Environment/WindManager
@onready var sun = $Environment/Sun
@onready var moon = $Environment/Moon
@onready var player = $Player  # maybe export

func _ready() -> void:
	# Ensure random generation differs each run
	randomize()

	var storm_scene = load("res://sand_storm.tscn")

	# Randomly pick how many storms to spawn
	var storms_to_spawn = int(randf_range(min_storms, max_storms + 1))

	for i in range(storms_to_spawn):
		# Create a new storm instance
		var storm = storm_scene.instantiate()
		storm.sun = sun  # So the storm can darken the sun

		add_child(storm)
		
		# Randomize each storm's size and position
		var random_area = randf_range(storm_area_min, storm_area_max)
		var random_height = randf_range(storm_height_min, storm_height_max)

		# Ensure storm spawns far enough from the player
		var position = get_valid_storm_position(random_height)

		# Defer initialization so the node is fully added before changes
		call_deferred("_initialize_storm", storm, random_area, random_height, position.x, position.z)

func get_valid_storm_position(height: float) -> Vector3:
	var position: Vector3
	while true:
		var random_x = randf_range(-spawn_radius, spawn_radius)
		var random_z = randf_range(-spawn_radius, spawn_radius)
		position = Vector3(random_x, height + 70, random_z)
		print("POSIT... ", position.distance_to(player.global_transform.origin))
		
		# Check distance from player
		if position.distance_to(player.global_transform.origin) >= min_spawn_distance:
			break  # Position is valid
	print("GOOD POS ", position.distance_to(player.global_transform.origin))
	return position

func _initialize_storm(
		storm: Node3D,
		area: float,
		height: float,
		x: float,
		z: float
) -> void:
	# Scale the storm
	storm.scale = Vector3(area, height, area)

	# Position the storm in the world
	storm.global_transform.origin = Vector3(x, height + 70, z)
	
	# Move it up to avoid spawning underground
	var y_offset = height * 5
	storm.global_transform.origin.y += y_offset
	storm.enable_player_tracking = true
	# Scale player tracking by storm size
	storm.player_track_strength = area / (4.0 * (storm_area_max + storm_height_max))
	
	print(
		"SAND STORM spawned at (",
		x, ", ", storm.global_transform.origin.y, ", ", z,
		") with scale (", area, ", ", height, ", ", area, ")",
		" and track_strength=", storm.player_track_strength
	)
