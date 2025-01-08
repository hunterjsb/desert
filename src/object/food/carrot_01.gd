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
