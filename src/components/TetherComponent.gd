extends Node
class_name TetherComponent

# Simple, reliable tether component
# Direct registry queries, position-based constraints, center-to-center measurements

@export var max_tether_distance: float = 10.0
@export var enable_distance_constraint: bool = true

var parent_rigidbody: RigidBody3D = null
var tension_audio: AudioStreamPlayer3D = null

func _ready() -> void:
	# Find the associated RigidBody3D
	parent_rigidbody = find_rigidbody_in_hierarchy(get_parent())
	
	# Create tension audio
	tension_audio = AudioStreamPlayer3D.new()
	tension_audio.stream = preload("res://audio/rope_creak_ambient-001.mp3")
	tension_audio.volume_db = -15.0
	tension_audio.autoplay = false
	add_child(tension_audio)
	
	# Enable physics processing only if we have a rigidbody to constrain
	set_physics_process(parent_rigidbody != null)
	

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

func _physics_process(delta: float) -> void:
	# Early exit if no physics body to constrain
	if not enable_distance_constraint or not parent_rigidbody:
		return
	
	# Direct registry query - no caching complexity
	if not TetherRegistry:
		return
	
	# The registry stores the RigidBody3D, not parent nodes
	# So check if our RigidBody3D is tethered, not the parent
	if not TetherRegistry.is_tethered(parent_rigidbody):
		# Stop audio if not tethered
		if tension_audio and tension_audio.playing:
			tension_audio.stop()
		return
	
	# Get current anchor positions directly from registry using the RigidBody3D
	var anchor_positions = TetherRegistry.get_anchor_positions(parent_rigidbody)
	if anchor_positions.is_empty():
		return
	
	var object_center = parent_rigidbody.global_position
	var max_tension = 0.0
	var closest_distance = max_tether_distance
	var needs_constraint = false
	var closest_anchor: Vector3
	
	# Check all anchors for constraint violations
	for anchor_pos in anchor_positions:
		var distance = object_center.distance_to(anchor_pos)
		
		if distance > max_tether_distance:
			needs_constraint = true
			if distance < closest_distance or closest_distance == max_tether_distance:
				closest_distance = distance
				closest_anchor = anchor_pos
		
		# Track tension for audio (even if not violating)
		if distance > max_tether_distance * 0.8:
			var tension = (distance - max_tether_distance * 0.8) / (max_tether_distance * 0.2)
			max_tension = max(max_tension, tension)
	
	# Apply gradual spring forces instead of teleportation
	if needs_constraint:
		# Calculate total spring force from all violating anchors
		var total_spring_force = Vector3.ZERO
		
		for anchor_pos in anchor_positions:
			var to_anchor = anchor_pos - object_center
			var distance = to_anchor.length()
			
			if distance > max_tether_distance:
				var violation = distance - max_tether_distance
				var direction = to_anchor / distance  # Normalized direction
				
				# Strong spring force proportional to violation distance
				var spring_force = direction * violation * 100.0  # Spring constant
				total_spring_force += spring_force
		
		# Apply accumulated spring forces
		parent_rigidbody.apply_central_force(total_spring_force)
		
		# Progressive damping based on constraint violation severity
		var max_violation = closest_distance - max_tether_distance
		var damping = lerp(0.98, 0.85, clamp(max_violation / max_tether_distance, 0.0, 1.0))
		parent_rigidbody.linear_velocity *= damping
		parent_rigidbody.angular_velocity *= damping
		
	
	# Handle audio based on tension
	if max_tension > 0.1:
		if tension_audio and not tension_audio.playing:
			tension_audio.play()
		
		if tension_audio:
			tension_audio.volume_db = lerp(-25.0, -10.0, clamp(max_tension, 0.0, 1.0))
			tension_audio.pitch_scale = lerp(0.8, 1.3, clamp(max_tension, 0.0, 1.0))
	else:
		if tension_audio and tension_audio.playing:
			tension_audio.stop()

# Simple API for debugging
func get_tether_status() -> Dictionary:
	# Use the RigidBody3D for registry queries, not the parent
	var is_tethered_val = TetherRegistry and TetherRegistry.is_tethered(parent_rigidbody)
	var tether_count = 0
	var closest_distance = 0.0
	
	if is_tethered_val and parent_rigidbody:
		tether_count = TetherRegistry.get_tether_count(parent_rigidbody)
		var anchors = TetherRegistry.get_anchor_positions(parent_rigidbody)
		for anchor_pos in anchors:
			var dist = parent_rigidbody.global_position.distance_to(anchor_pos)
			closest_distance = min(closest_distance, dist) if closest_distance > 0 else dist
	
	return {
		"is_tethered": is_tethered_val,
		"tether_count": tether_count,
		"distance": closest_distance,
		"max_distance": max_tether_distance
	}

func _exit_tree() -> void:
	# Clean up when destroyed
	if TetherRegistry:
		TetherRegistry.unregister_all_tethers(get_parent())
