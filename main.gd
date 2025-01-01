extends Node3D

@export var storm_area: int = 40
@export var storm_height: int = 25

@onready var wind_manager = $Environment/WindManager
@onready var sun = $Environment/Sun
@onready var moon = $Environment/Moon

func _ready() -> void:
	var storm_scene = load("res://sand_storm.tscn")
	var storm = storm_scene.instantiate()
	
	storm.sun = sun  # the storm darkens the sun on entry

	add_child(storm)
	call_deferred("_initialize_storm", storm)

func _initialize_storm(storm: Node3D) -> void:
	# spawn somewhere, TODO randomize
	storm.global_transform.origin = Vector3(500, 70 + storm_height, -500)
	
	# scale the storm, TODO randomize
	storm.scale = Vector3(storm_area, storm_height, storm_area)
	
	# move it up lest it spawn under the map
	var y_offset = storm_height * 5
	storm.global_transform.origin.y += y_offset
