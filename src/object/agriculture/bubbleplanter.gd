extends Node3D

@export var wind_manager: Node3D
@export var wind_force_multiplier: float = 1.0

@export var plant_slots_large: int = 1
@export var plant_slots_small: int = 4

@onready var body = $Mesh1_Mesh1_016

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var wind_vector = wind_manager.get_wind_vector() / 2
	body.apply_central_force(wind_vector * wind_force_multiplier)
