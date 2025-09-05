extends Node3D

@export var start_point : Node3D
@export var start_is_rigidbody = false
@export var end_point : Node3D
@export var end_is_rigidbody = true
@export_range(1,50,1) var number_of_segments = 10
@export_range(0, 100.0, 0.1) var cable_length = 5.0
@export var cable_gravity_amp = 0.245
@export var cable_thickness = 0.1
@export var cable_springiness = 9.81*2
@onready var cable_mesh := preload("res://src/object/rope/mesh_instance_3d.tscn")
var segment_stretch: float
# instances
var segments : Array
var joints : Array
# debug display
var debug_label : Label3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure parameters have valid values
	if number_of_segments == null or number_of_segments <= 0:
		number_of_segments = 10
	if cable_length == null or cable_length <= 0:
		cable_length = 5.0
	if cable_gravity_amp == null:
		cable_gravity_amp = 0.245
	if cable_thickness == null:
		cable_thickness = 0.1
	if cable_springiness == null:
		cable_springiness = 9.81 * 2
	
	# Calculate segment stretch
	segment_stretch = float(cable_length) / float(number_of_segments)
	
	var distance = (end_point.global_position - start_point.global_position).length()
	var direction = (end_point.global_position - start_point.global_position).normalized()
	
	# Notify attachment points that they're tethered
	if start_point.has_method("set_tethered"):
		start_point.set_tethered(true)
	if end_point.has_method("set_tethered"):
		end_point.set_tethered(true)
	
	# start at start point
	joints.append(start_point)
	# create joints
	for j in (number_of_segments - 1):
		joints.append(Node3D.new())
		self.add_child(joints[j+1])
		# position nodes evenly between the two points
		joints[j+1].global_position = start_point.global_position + direction * (j + 1) * distance / (number_of_segments - 1)
	# end at end point
	joints.append(end_point)
	# create cable segments
	for s in number_of_segments:
		segments.append(cable_mesh.instantiate())
		self.add_child(segments[s])
		# position segments between the joints
		segments[s].global_position = joints[s].global_position + (joints[s+1].global_position - joints[s].global_position)/2
		segments[s].get_child(0).mesh.top_radius = cable_thickness/2.0
		segments[s].get_child(0).mesh.bottom_radius = cable_thickness/2.0
	
	# Create debug label
	debug_label = Label3D.new()
	debug_label.text = "Distance: 0.0"
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	self.add_child(debug_label)

func _process(_delta: float) -> void:
	# Make segments point at their target and stretch/squash to their desired length
	for i in number_of_segments:
		# set position between joints
		segments[i].global_position = joints[i].global_position + (joints[i+1].global_position - joints[i].global_position)/2
		# look at next joint
		safe_look_at(segments[i], joints[i+1].global_position + Vector3(0.0001, 0, -0.0001))
		# set length to the distance between the joints
		segments[i].get_child(0).mesh.height = (joints[i+1].global_position - joints[i].global_position).length()
	
	# Update debug display - show tether component status
	if debug_label and start_point and end_point:
		var current_distance = (end_point.global_position - start_point.global_position).length()
		var tether_info = get_tether_component_info(end_point)
		
		
		debug_label.text = "Rope Dist: %.1f\n%s" % [current_distance, tether_info]
		debug_label.global_position = start_point.global_position + (end_point.global_position - start_point.global_position) * 0.5


func get_tether_component_info(node: Node) -> String:
	# Look for tether component in the node hierarchy
	var tether_component = find_tether_component_in_hierarchy(node)
	
	if tether_component:
		var status = tether_component.get_tether_status()
		return "Tethered: %s\nTo: %s\nDist: %.1f/%.1f" % [
			status.is_tethered, 
			status.anchor_name, 
			status.distance, 
			status.max_distance
		]
	else:
		return "No Tether Component"

func find_tether_component_in_hierarchy(node: Node) -> TetherComponent:
	if not node:
		return null
		
	# Check the node itself
	if node.has_method("get_tether_component"):
		return node.get_tether_component()
	
	# Check direct children
	for child in node.get_children():
		if child is TetherComponent:
			return child
	
	# IMPORTANT: Check parent (for sticky body attached to bubble planter)
	var parent = node.get_parent()
	if parent and not parent is Window:
		var parent_component = find_tether_component_in_hierarchy(parent)
		if parent_component:
			return parent_component
	
	return null

func _physics_process(delta: float) -> void:
	# fake physics
	for i in number_of_segments:
		if i != 0:
			# collision
			var query = PhysicsRayQueryParameters3D.create(joints[i].global_position, joints[i].global_position - Vector3(0,cable_thickness, 0))
			var raycast = get_world_3d().direct_space_state.intersect_ray(query)
			# Gravity
			if raycast.get("collider") == null:
				joints[i].global_position.y = lerp(joints[i].global_position.y, joints[i].global_position.y - 1, cable_gravity_amp * delta/2.0)
			# stretch
			joints[i].global_position = lerp(joints[i].global_position, joints[i-1].global_position + (joints[i+1].global_position - joints[i-1].global_position)/2.0, cable_springiness * delta)
	# Calculate distance for rope physics
	var current_distance = (end_point.global_position - start_point.global_position).length()
	
	# Simple debug display for now - no tethering logic in rope
	if debug_label:
		debug_label.modulate = Color.WHITE
	
	# Retract with damping to reduce oscillation (existing soft constraint)
	if end_is_rigidbody:
		if current_distance >= segment_stretch * number_of_segments:
			var modifier = current_distance - segment_stretch * number_of_segments
			modifier = clamp(modifier, 0.0, cable_springiness)
			var force = (end_point.global_position - joints[-2].global_position) * modifier * 0.5  # Add damping
			end_point.linear_velocity -= force
	if start_is_rigidbody:
		if current_distance >= segment_stretch * number_of_segments:
			var modifier = current_distance - segment_stretch * number_of_segments
			modifier = clamp(modifier, 0.0, cable_springiness)
			var force = (joints[0].global_position - joints[1].global_position) * modifier * 0.5  # Add damping
			joints[0].linear_velocity -= force


func safe_look_at(node : Node3D, target : Vector3) -> void:
	var origin : Vector3 = node.global_transform.origin
	var v_z := (origin - target).normalized()

	# Just return if at same position
	if origin == target:
		return

	# Find an up vector that we can rotate around
	var up := Vector3.ZERO
	for entry in [Vector3.UP, Vector3.RIGHT, Vector3.BACK]:
		var v_x : Vector3 = entry.cross(v_z).normalized()
		if v_x.length() != 0:
			up = entry
			break

	# Look at the target
	if up != Vector3.ZERO:
		node.look_at(target, up)
