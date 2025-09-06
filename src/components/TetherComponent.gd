extends Node
class_name TetherComponent

# Tethering component that can be attached to any object
# Handles tethering state and distance constraints

@export var is_tethered: bool = false
@export var tether_anchor: Node3D = null
@export var max_tether_distance: float = 5.0
@export var enable_distance_constraint: bool = true

var parent_rigidbody: RigidBody3D = null
var attached_snappy_bodies: Array[RigidBody3D] = []
var tension_audio: AudioStreamPlayer3D = null

func _ready() -> void:
	# Find the associated RigidBody3D (could be parent, sibling, or child)
	parent_rigidbody = find_rigidbody_in_hierarchy(get_parent())
	# Start with physics processing disabled for performance
	set_physics_process(false)
	
	# Create tension audio
	tension_audio = AudioStreamPlayer3D.new()
	tension_audio.stream = preload("res://audio/rope_creak_ambient-001.mp3")
	tension_audio.volume_db = -15.0
	tension_audio.autoplay = false
	add_child(tension_audio)

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
	
	# For static objects like posts, return null (they don't need physics constraints)
	return null

func set_tethered(tethered: bool, anchor: Node3D = null, distance: float = 5.0, snappy_body: RigidBody3D = null) -> void:
	if tethered:
		# Adding a new tether
		if not is_tethered:
			# First tether - set up initial state
			is_tethered = true
			tether_anchor = anchor
			max_tether_distance = distance
			set_physics_process(true)
		
		# Add this snappy body to the list if not already there
		if snappy_body and snappy_body not in attached_snappy_bodies:
			attached_snappy_bodies.append(snappy_body)
		
		print("TETHER: Added attachment, total: ", attached_snappy_bodies.size())
	else:
		# Removing a tether
		if snappy_body and snappy_body in attached_snappy_bodies:
			attached_snappy_bodies.erase(snappy_body)
			print("TETHER: Removed attachment, remaining: ", attached_snappy_bodies.size())
		
		# Only disable tethering if no attachments remain
		if attached_snappy_bodies.is_empty():
			is_tethered = false
			tether_anchor = null
			max_tether_distance = 0.0
			set_physics_process(false)
			
			# Stop tension audio when fully untethered
			if tension_audio and tension_audio.playing:
				tension_audio.stop()
			
			print("TETHER: Fully untethered")

func _physics_process(delta: float) -> void:
	# For static objects (like posts), we don't need physics processing - they serve as anchor points
	if not is_tethered or not tether_anchor or not enable_distance_constraint:
		return
	
	# If this is a static object (no parent_rigidbody), skip physics processing
	if not parent_rigidbody:
		return
	
	# Use distance_squared_to for better performance (avoids sqrt)
	var distance_sq = parent_rigidbody.global_position.distance_squared_to(tether_anchor.global_position)
	var max_distance_sq = max_tether_distance * max_tether_distance
	var current_distance = sqrt(distance_sq)
	
	# Play tension audio as we approach max distance (starts at 80% of max distance)
	# BUT only if we're actually tethered!
	var tension_threshold = max_tether_distance * 0.8
	if is_tethered and current_distance > tension_threshold:
		if tension_audio:
			var tension_amount = (current_distance - tension_threshold) / (max_tether_distance - tension_threshold)
			tension_amount = clamp(tension_amount, 0.0, 1.0)
			
			if not tension_audio.playing:
				tension_audio.play()
			
			# Modulate audio based on how close we are to max distance
			tension_audio.volume_db = lerp(-25.0, -10.0, tension_amount)  # Louder as we approach limit
			tension_audio.pitch_scale = lerp(0.8, 1.3, tension_amount)    # Higher pitch as we approach limit
	else:
		# Stop tension audio when not tethered or not under stress
		if tension_audio and tension_audio.playing:
			tension_audio.stop()
	
	# Only apply constraint if beyond max distance
	if distance_sq > max_distance_sq:
		var direction_to_anchor = (tether_anchor.global_position - parent_rigidbody.global_position) / current_distance
		var constrained_position = tether_anchor.global_position - direction_to_anchor * max_tether_distance
		
		parent_rigidbody.global_position = constrained_position
		
		# Moderate damping - enough to reduce oscillation but not kill all movement
		parent_rigidbody.linear_velocity *= 0.7  # Less aggressive damping
		parent_rigidbody.angular_velocity *= 0.7
		
		# Apply the same constraint to all attached snappy bodies
		for snappy_body in attached_snappy_bodies:
			if snappy_body and is_instance_valid(snappy_body):
				snappy_body.global_position = constrained_position
				# Moderate damping on snappy body too - don't kill all velocity
				snappy_body.linear_velocity *= 0.5  # More damping on rope end
				snappy_body.angular_velocity *= 0.5


func get_tether_status() -> Dictionary:
	return {
		"is_tethered": is_tethered,
		"anchor_name": tether_anchor.name if tether_anchor else "none",
		"distance": (parent_rigidbody.global_position - tether_anchor.global_position).length() if is_tethered and tether_anchor and parent_rigidbody else 0.0,
		"max_distance": max_tether_distance
	}
