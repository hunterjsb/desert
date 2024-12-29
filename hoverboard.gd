extends Node3D

@onready var collision = $CollisionShape3D


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass
	

func interact(player: Node):
	print("he he that tickles")
