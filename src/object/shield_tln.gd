extends Node3D

@export var gravity: float = 9.8
@export var is_active: bool = false

@onready var body: RigidBody3D = $Mesh0

func _ready() -> void:
	body.gravity_scale = gravity
	body.is_active = is_active
