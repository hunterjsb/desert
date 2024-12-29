extends Node3D

@onready var collision = $CollisionShape3D

var attached: bool = false
var _attached_mod: int = 1

var prev_walk_sway: float
var prev_sprint_sway: float

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func interact(player: Node):
	# Determine if we are attaching or detaching
	var old_global_transform = self.global_transform

	# -1 if currently attached (=> detaching), otherwise +1 for attaching
	_attached_mod = -1 if attached else 1
	player.sprint_multiplier += _attached_mod * 2
	
	# Remove from old parent
	var old_parent = self.get_parent()
	old_parent.remove_child(self)

	var new_parent = player.get_node("Feet") if not attached else player.get_parent()
	new_parent.add_child(self)
	
	# === Only reset transform if attaching ===
	if !attached:
		# *Attaching* => optionally reset local position
		self.transform = Transform3D()
		prev_sprint_sway = player.sprint_sway_intensity
		prev_walk_sway  = player.walk_sway_intensity
		player.sprint_sway_intensity = 0
		player.walk_sway_intensity   = 0
	else:
		# *Detaching* => keep the hoverboard in the same place in the world
		self.global_transform = old_global_transform
		player.sprint_sway_intensity = prev_sprint_sway
		player.walk_sway_intensity   = prev_walk_sway

	self.freeze = !attached
	attached = !attached
	
func on_pickup(player: Node):
	if attached:
		interact(player)
