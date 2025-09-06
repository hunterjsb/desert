extends Node3D

@export var wind_manager: Node3D
@export var wind_force_multiplier: float = 1.0

@export var plant_slots_large: int = 1
@export var plant_slots_small: int = 4

@onready var body = $Mesh1_Mesh1_016
@onready var tether_component: TetherComponent = null

func _ready() -> void:
	# Add tether component
	tether_component = preload("res://src/components/TetherComponent.gd").new()
	add_child(tether_component)

func _process(_delta: float) -> void:
	# Don't apply wind forces if this planter is tethered
	var is_tethered = tether_component and tether_component.is_tethered
	if not is_tethered:
		var wind_vector = wind_manager.get_wind_vector() / 2
		body.apply_central_force(wind_vector * wind_force_multiplier)

# Legacy compatibility - route to tether component
func set_tethered(tethered: bool) -> void:
	if tether_component:
		tether_component.set_tethered(tethered)

func get_tether_component() -> TetherComponent:
	return tether_component
