extends Node3D

var env: Node3D
var spawned_loot: Node3D = null  # Track the currently spawned loot
@onready var detection_area: Area3D = $DetectionArea

func _set_transform(pos: Vector3, rotation_y: float, scale_factor: float):
	global_transform.origin = pos
	rotation_degrees.y = rotation_y
	scale *= Vector3(scale_factor, scale_factor, scale_factor)

func spawn_loot(pos: Vector3):
	var rand = randi() % 100  # Generate a random number between 0 and 99

	if rand < 60:
		# 60% chance: No loot
		return
	elif rand < 90:
		# 30% chance: Spawn a carrot
		spawned_loot = preload("res://src/object/food/carrot.tscn").instantiate()
	else:
		# 10% chance: Spawn a radio
		spawned_loot = preload("res://src/object/radio.tscn").instantiate()
		spawned_loot.env = env

	# Add the loot to the parent and set position
	get_parent().add_child(spawned_loot)
	spawned_loot.call_deferred("set_global_position", pos)

	# Ensure loot is frozen initially
	if "_freeze" in spawned_loot:
		spawned_loot.call_deferred("_freeze")

func _on_body_entered(_body: Node3D) -> void:
	# Unfreeze the loot if it has the method
	if spawned_loot and "_unfreeze" in spawned_loot:
		spawned_loot._unfreeze()
