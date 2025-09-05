extends Node
class_name TetherComponent

# Tethering component that can be attached to any object
# Handles tethering state and distance constraints

@export var is_tethered: bool = false
@export var tether_anchor: Node3D = null
@export var max_tether_distance: float = 5.0
@export var enable_distance_constraint: bool = true

var parent_rigidbody: RigidBody3D = null
var attached_snappy_body: RigidBody3D = null

func _ready() -> void:
	# Find the associated RigidBody3D (could be parent, sibling, or child)
	parent_rigidbody = find_rigidbody_in_hierarchy(get_parent())

func find_rigidbody_in_hierarchy(node: Node) -> RigidBody3D:
	if not node:
		return null
	
	# Check the node itself
	if node is RigidBody3D:
		return node
	
	# Check children first (for bubble planter structure)
	for child in node.get_children():
		if child is RigidBody3D:
			return child
	
	# Check parent if not found
	var parent = node.get_parent()
	if parent:
		return find_rigidbody_in_hierarchy(parent)
	
	return null

func set_tethered(tethered: bool, anchor: Node3D = null, distance: float = 5.0, snappy_body: RigidBody3D = null) -> void:
	is_tethered = tethered
	
	if is_tethered:
		tether_anchor = anchor
		max_tether_distance = distance
		attached_snappy_body = snappy_body
	else:
		# Clear anchor and distance when untethering
		tether_anchor = null
		max_tether_distance = 0.0
		attached_snappy_body = null

func _physics_process(delta: float) -> void:
	if not is_tethered or not tether_anchor or not parent_rigidbody or not enable_distance_constraint:
		return
	
	var current_distance = (parent_rigidbody.global_position - tether_anchor.global_position).length()
	
	# Hard constraint: don't let object go beyond tether distance
	if current_distance > max_tether_distance:
		var direction_to_anchor = (tether_anchor.global_position - parent_rigidbody.global_position).normalized()
		var constrained_position = tether_anchor.global_position - direction_to_anchor * max_tether_distance
		
		parent_rigidbody.global_position = constrained_position
		# Damp velocity to prevent bouncing
		parent_rigidbody.linear_velocity *= 0.5
		parent_rigidbody.angular_velocity *= 0.7
		
		# Apply the same constraint to the attached snappy body
		if attached_snappy_body:
			attached_snappy_body.global_position = constrained_position
			attached_snappy_body.linear_velocity = Vector3.ZERO
			attached_snappy_body.angular_velocity = Vector3.ZERO


func get_tether_status() -> Dictionary:
	return {
		"is_tethered": is_tethered,
		"anchor_name": tether_anchor.name if tether_anchor else "none",
		"distance": (parent_rigidbody.global_position - tether_anchor.global_position).length() if is_tethered and tether_anchor and parent_rigidbody else 0.0,
		"max_distance": max_tether_distance
	}
