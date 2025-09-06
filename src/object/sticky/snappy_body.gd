extends InteractableBody3D


@onready var snap_area = $SnapArea
var attached_tether_component: TetherComponent = null


func _ready() -> void:
	pass

func pickup(player: Node) -> void:
	# Untether before being picked up
	if attached_tether_component:
		attached_tether_component.set_tethered(false)
		attached_tether_component = null
	
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
	
	# Find the tether anchor (post) by finding the rope's start point
	var tether_anchor = find_tether_anchor()
	
	# Notify the target object that it's now tethered using the component system
	var tether_component = find_tether_component(target_object)
	
	# If not found in target, try target's parent (bubble planter main node)
	if not tether_component and target_object.get_parent():
		tether_component = find_tether_component(target_object.get_parent())
	
	if tether_component and tether_anchor:
		tether_component.set_tethered(true, tether_anchor, 10.0, self)  # Pass self as snappy_body
		attached_tether_component = tether_component  # Remember this for when we detach
		
		# Play attachment sound
		var attach_audio = get_node_or_null("AttachAudio")
		if attach_audio:
			attach_audio.play()

func find_tether_component(obj: Node) -> TetherComponent:
	# Look for TetherComponent in the object or its children
	if obj.has_method("get_tether_component"):
		return obj.get_tether_component()
	
	for child in obj.get_children():
		if child is TetherComponent:
			return child
	
	return null

func find_tether_anchor() -> Node3D:
	# The sticky body should already be connected to a rope
	# We need to find the rope that has this sticky body as end_point
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
