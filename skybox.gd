extends Node3D

@onready var wind_manager = $Environment/WindManager
@onready var sun = $Environment/Sun

func _ready() -> void:
	pass
	#var storm_scene = load("res://sand_storm.tscn")
	#var storm = storm_scene.instantiate()
	#
	## set up env
	#storm.wind_manager = wind_manager
	#storm.sun = sun
#
	#call_deferred("_initialize_storm", storm)
	#add_child(storm)

func _initialize_storm(storm: Node3D) -> void:
	pass
	# storm.global_transform.origin = Vector3(1, 10, 1)
