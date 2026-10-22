class_name WaistWrap
extends Node3D
## Cord on the visual belt, joined to the existing rope drawing; never a force attachment.
var body: Body
var _views := {}
var _tips := {}

func _process(_delta: float) -> void:
	var player := body.player
	if not is_instance_valid(player) or player.world == null:
		return
	var active := {}
	var direct := player.world.ropes.waist
	if is_instance_valid(direct) and not player.world.ropes.lines_on(direct).is_empty():
		active[player.get_instance_id()] = direct
	for holder in player.waist.tied:
		if not is_instance_valid(holder) or not player.waist.carries_line(holder):
			continue
		var end: RopeEnd
		for child in holder.get_children():
			if child is RopeEnd and not player.world.ropes.lines_on(child).is_empty():
				end = child
				break
		if end != null:
			active[holder.get_instance_id()] = end
	for id in _views.keys():
		if not active.has(id):
			for view: MeshInstance3D in _views[id]:
				view.queue_free()
			_restore_tips(id)
			_views.erase(id)
	var hips := body.get_node(^"hips") as MeshInstance3D
	var index := 0
	for id in active:
		if not _views.has(id):
			var wrap := MeshInstance3D.new()
			wrap.mesh = SurveyorLooks.waist_wrap()
			hips.add_child(wrap)
			var lead := MeshInstance3D.new()
			lead.mesh = SurveyorLooks.waist_lead()
			lead.top_level = true
			add_child(lead)
			_views[id] = [wrap, lead]
			_copy_tips(id, (active[id] as RopeEnd).holder)
		var views: Array = _views[id]
		var wrap := views[0] as MeshInstance3D
		wrap.position.y = (float(index) - float(active.size() - 1) * 0.5) * float(Tuning.current().rope_coil_visual.gauge)
		var from := wrap.to_global(Vector3(0, 0.07, -0.17))
		var to := player.world.ropes._shown_end(active[id])
		var render_offset: Vector3 = to - (active[id] as RopeEnd).global_position
		for pair: Array in _tips.get(id, []):
			var copy := pair[1] as MeshInstance3D
			if not is_instance_valid(pair[0]):
				copy.visible = false
				continue
			var original := pair[0] as MeshInstance3D
			copy.global_transform = Transform3D(original.global_basis, original.global_position + render_offset)
			copy.visible = body.visible
			for key in [&"age", &"era", &"lit", &"half_size", &"round_xz", &"foot_shift"]:
				var value: Variant = original.get_instance_shader_parameter(key)
				if value != null:
					copy.set_instance_shader_parameter(key, value)
		var span := to - from
		var lead := views[1] as MeshInstance3D
		lead.visible = body.visible and span.length() > 0.001
		wrap.visible = body.visible
		if lead.visible:
			var turn := Basis(Quaternion(Vector3.UP, span.normalized()))
			turn.y *= span.length()
			lead.global_transform = Transform3D(turn, from)
		index += 1


## Only rope tips need a drawn proxy: the physical Part keeps its exact endpoint and collider.
func _copy_tips(id: int, holder: Node3D) -> void:
	_tips[id] = []
	if not holder is RopeTip:
		return
	for child in holder.get_children():
		var original := child as MeshInstance3D
		if original == null or not original.visible:
			continue
		var copy := MeshInstance3D.new()
		copy.mesh = original.mesh
		copy.material_override = original.material_override
		copy.layers = original.layers
		copy.cast_shadow = original.cast_shadow
		copy.top_level = true
		add_child(copy)
		_tips[id].append([original, copy])
		original.visible = false


func _restore_tips(id: int) -> void:
	for pair: Array in _tips.get(id, []):
		if is_instance_valid(pair[0]):
			(pair[0] as MeshInstance3D).visible = true
		if is_instance_valid(pair[1]):
			(pair[1] as MeshInstance3D).queue_free()
	_tips.erase(id)


func _exit_tree() -> void:
	for id in _tips.keys():
		_restore_tips(id)
