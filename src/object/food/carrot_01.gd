extends InteractableBody3D

@export var hunger_restore_amount = 15


func interact(player: Node) -> void:
	if not player:
		return
	if "eat_food" in player:
		player.eat_food(hunger_restore_amount)
	queue_free()
