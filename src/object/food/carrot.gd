extends InteractableBody3D

@export var hunger_restore_amount = 15


func interact(player: Node) -> void:
	# add food to player
	player.eat_food(hunger_restore_amount)
	
	# clear hand
	if player.is_carrying_item and player.carried_item == self:
		player.clear_hand()
		
	# delete item
	queue_free()
	
func _set_transform(position: Vector3, rotation_y: float, scale_factor: float):
	global_transform.origin = position
	rotation_degrees.y = rotation_y
	scale *= Vector3(scale_factor, scale_factor, scale_factor)

func _set_scale(scale_factor: float):
	scale = Vector3(scale_factor, scale_factor, scale_factor)

func _freeze():
	freeze = true
	
func _unfreeze():
	freeze = false
