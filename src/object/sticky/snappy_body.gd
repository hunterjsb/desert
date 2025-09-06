extends InteractableBody3D

@onready var snap_area = $SnapArea
var attached_object: Node3D = null  # The object this sticky body is attached to
var anchor_object: Node3D = null    # The anchor point (other end of rope)

func _ready() -> void:
	pass

func pickup(player: Node) -> void:
	# Clean registry-based detachment
	if attached_object and TetherRegistry:
		# Find the anchor by tracing the rope connection
		var anchor = find_rope_anchor()
		if anchor:
			TetherRegistry.unregister_tether(attached_object, anchor)
	
	# Clear references
	attached_object = null
	anchor_object = null
	
	# Call parent pickup method
	super.pickup(player)

func interact(player) -> void:
	# Just call pickup - this handles both interaction and pickup scenarios
	pickup(player)

func _on_snap_area_area_entered(area: Area3D) -> void:
	if not area.is_in_group("sticky"):
		return
	
	if carrying_player:
		carrying_player.clear_hand()
	
	var target_object = area.get_parent()
	call_deferred("reparent", target_object)
	freeze = true
	
	# Store reference to attached object
	attached_object = target_object
	
	# Find the rope's other endpoint (anchor)
	var anchor = find_rope_anchor()
	if not anchor:
		print("StickyBody: Could not find rope anchor")
		return
	
	anchor_object = anchor
	
	# Register the tether in the central registry
	if TetherRegistry:
		# For static objects (posts), they become the anchor
		# For dynamic objects (bubble planters), they get constrained to the anchor
		if target_object is StaticBody3D:
			# Target is static - it serves as the anchor point
			print("StickyBody: Attached to static anchor ", target_object.name)
		else:
			# Target is dynamic - register it as tethered to the anchor
			TetherRegistry.register_tether(target_object, anchor)
			print("StickyBody: Registered tether - ", target_object.name, " -> ", anchor.name)
	
	# Play attachment sound
	var attach_audio = get_node_or_null("AttachAudio")
	if attach_audio:
		attach_audio.play()

func find_rope_anchor() -> Node3D:
	# Find the rope that has this sticky body as an endpoint
	# and return the OTHER endpoint (the anchor)
	var current_scene = get_tree().current_scene
	return find_rope_with_endpoint(current_scene, self)

func find_rope_with_endpoint(node: Node, target_endpoint: Node) -> Node3D:
	# Check if this node is a rope with our endpoint
	if node.name.to_lower().contains("rope") and node.has_method("get"):
		if node.get("end_point") == target_endpoint or node.get("start_point") == target_endpoint:
			# Return the OTHER end (if we're end_point, return start_point)
			if node.get("end_point") == target_endpoint:
				return node.get("start_point")
			else:
				return node.get("end_point")
	
	# Recursively check children
	for child in node.get_children():
		var result = find_rope_with_endpoint(child, target_endpoint)
		if result:
			return result
	
	return null
