# InteractableBody3D.gd
extends RigidBody3D
class_name InteractableBody3D

@export var weight: float = 5.0
@export var is_attached: bool = false
var carrying_player

func try_pickup(player: Node) -> bool:
	if not "strength" in player:
		print("Warning: Player has no 'strength' property.")
		return true
	
	if player.strength >= weight:
		# Sufficient strength to pick up
		return true
	else:
		# Not enough strength
		return false

func pickup(player: Node) -> void:
	freeze = true
	if get_parent():
		get_parent().remove_child(self)
	var hand = player.get_node_or_null("Camera3D/HandPoint")
	if hand:
		carrying_player = player
		hand.add_child(self)
		player.carried_item = self
		player.is_carrying_item = true
		# Reset local transform so it appears nicely in the hand
		transform = Transform3D()

func interact(_player: Node) -> void:
	# Default "interact" behavior (many objects might override this).
	print("Interacting with base InteractableBody3D. Override me if needed!")
