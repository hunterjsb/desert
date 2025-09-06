extends Node

# Global tether registry singleton
# Central authority for all rope-object tether relationships
# Provides O(1) lookups and clean event-driven architecture

signal tether_registered(object: Node3D, anchor: Node3D)
signal tether_unregistered(object: Node3D, anchor: Node3D)
signal tethers_changed(object: Node3D)

# Core data structures
var tethered_objects: Dictionary = {}  # Node3D -> Array[Vector3] (anchor positions)
var object_to_anchors: Dictionary = {}  # Node3D -> Array[Node3D] (anchor nodes)

func _ready():
	print("TetherRegistry: Initialized")
	# Update anchor positions every few frames for performance
	var timer = Timer.new()
	timer.wait_time = 0.1  # Update 10 times per second
	timer.timeout.connect(update_anchor_positions)
	timer.autostart = true
	add_child(timer)

# Register a tether connection between an object and an anchor point
func register_tether(object: Node3D, anchor: Node3D) -> void:
	if not object or not anchor:
		return
	
	# Initialize arrays if first tether for this object
	if not tethered_objects.has(object):
		tethered_objects[object] = []
		object_to_anchors[object] = []
	
	# Add anchor if not already present
	var anchor_nodes = object_to_anchors[object] as Array[Node3D]
	if anchor not in anchor_nodes:
		anchor_nodes.append(anchor)
		
		# Cache anchor position for efficient physics
		var anchor_positions = tethered_objects[object] as Array[Vector3]
		anchor_positions.append(anchor.global_position)
		
		# Emit events
		tether_registered.emit(object, anchor)
		tethers_changed.emit(object)
		
		print("TetherRegistry: Registered tether - ", object.name, " -> ", anchor.name)
		print("TetherRegistry: Anchor position cached at: ", anchor.global_position)

# Unregister a tether connection
func unregister_tether(object: Node3D, anchor: Node3D) -> void:
	if not object or not anchor or not tethered_objects.has(object):
		return
	
	var anchor_nodes = object_to_anchors[object] as Array[Node3D]
	var anchor_index = anchor_nodes.find(anchor)
	
	if anchor_index != -1:
		# Remove from both arrays
		anchor_nodes.remove_at(anchor_index)
		var anchor_positions = tethered_objects[object] as Array[Vector3]
		anchor_positions.remove_at(anchor_index)
		
		# Clean up empty entries
		if anchor_nodes.is_empty():
			tethered_objects.erase(object)
			object_to_anchors.erase(object)
		
		# Emit events
		tether_unregistered.emit(object, anchor)
		tethers_changed.emit(object)
		
		print("TetherRegistry: Unregistered tether - ", object.name, " -> ", anchor.name)

# Unregister all tethers for an object (when object is destroyed/picked up)
func unregister_all_tethers(object: Node3D) -> void:
	if not object or not tethered_objects.has(object):
		return
	
	var anchor_nodes = object_to_anchors[object] as Array[Node3D]
	for anchor in anchor_nodes:
		tether_unregistered.emit(object, anchor)
	
	tethered_objects.erase(object)
	object_to_anchors.erase(object)
	tethers_changed.emit(object)
	
	print("TetherRegistry: Unregistered all tethers for ", object.name)

# Get cached anchor positions for efficient physics (O(1) lookup)
func get_anchor_positions(object: Node3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if tethered_objects.has(object):
		var positions = tethered_objects[object]
		for pos in positions:
			result.append(pos as Vector3)
		print("TetherRegistry: get_anchor_positions for ", object.name, " -> ", result.size(), " positions")
		return result
	print("TetherRegistry: get_anchor_positions for ", object.name, " -> NOT FOUND")
	return result

# Get anchor nodes (for debugging/inspection)
func get_anchor_nodes(object: Node3D) -> Array[Node3D]:
	if object_to_anchors.has(object):
		return object_to_anchors[object] as Array[Node3D]
	return []

# Check if an object is tethered
func is_tethered(object: Node3D) -> bool:
	return tethered_objects.has(object) and not tethered_objects[object].is_empty()

# Get number of tethers for an object
func get_tether_count(object: Node3D) -> int:
	if tethered_objects.has(object):
		return tethered_objects[object].size()
	return 0

# Update cached anchor positions (called periodically or when anchors move)
func update_anchor_positions() -> void:
	for object in object_to_anchors.keys():
		var anchor_nodes = object_to_anchors[object] as Array[Node3D]
		var anchor_positions = tethered_objects[object] as Array[Vector3]
		
		# Update positions in parallel
		for i in range(anchor_nodes.size()):
			if i < anchor_positions.size() and is_instance_valid(anchor_nodes[i]):
				anchor_positions[i] = anchor_nodes[i].global_position

# Debug: Print current registry state
func debug_print_state() -> void:
	print("TetherRegistry State:")
	for object in tethered_objects.keys():
		var count = get_tether_count(object)
		print("  ", object.name, ": ", count, " tethers")
