# InteractableBody3D.gd
extends RigidBody3D
class_name InteractableBody3D

@export var weight: float = 5.0
@export var is_attached: bool = false

func try_pickup(player: Node) -> bool:
	# For instance, check if the player is strong enough to pick this up
	# (Assuming the player script has a "strength" variable or similar).
	# If the player is strong enough, return true, else false.

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
	# Optionally remove it from its current parent and attach to the player's "hand" or "Feet" or something
	if get_parent():
		get_parent().remove_child(self)
	var hand = player.get_node_or_null("Camera3D/HandPoint")
	if hand:
		hand.add_child(self)
		player.carried_item = self
		player.is_carrying_item = true
		# Reset local transform so it appears nicely in the hand
		transform = Transform3D()

func interact(player: Node) -> void:
	# Default "interact" behavior (many objects might override this).
	print("Interacting with base InteractableBody3D. Override me if needed!")
