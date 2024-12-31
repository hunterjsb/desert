extends Node3D

@onready var wind_manager = $Environment/WindManager

func _ready() -> void:
	var storm_scene = load("res://sand_storm.tscn")
	var storm = storm_scene.instantiate()

	call_deferred("_initialize_storm", storm)

	add_child(storm)

func _initialize_storm(storm: Node3D) -> void:
	pass
	# storm.global_transform.origin = Vector3(1, 10, 1)
