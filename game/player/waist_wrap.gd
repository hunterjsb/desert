class_name WaistWrap
extends Node3D
## Rope wound round the suit's belt while lines are tied at your waist, with
## a short lead from its knot to the line. The tied end itself is not drawn
## there: the body draws between ticks, and the end's own pose would jitter.
var body: Body
var _views := {}
## Each waist end's meshes put out of sight while it's tied, to show again.
var _hidden := {}


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
		for child in holder.get_children():
			if child is RopeEnd and not player.world.ropes.lines_on(child).is_empty():
				active[holder.get_instance_id()] = child
				break
	for id in _views.keys():
		if not active.has(id):
			for view: MeshInstance3D in _views[id]:
				view.queue_free()
			_show_end(id)
			_views.erase(id)
	var hips := body.get_node(^"hips") as MeshInstance3D
	var index := 0
	for id in active:
		var end: RopeEnd = active[id]
		if not _views.has(id):
			var wrap := MeshInstance3D.new()
			wrap.mesh = SurveyorLooks.waist_wrap()
			hips.add_child(wrap)
			var lead := MeshInstance3D.new()
			lead.mesh = SurveyorLooks.waist_lead()
			lead.top_level = true
			add_child(lead)
			_views[id] = [wrap, lead]
			_hide_end(id, end.holder)
		var wrap := _views[id][0] as MeshInstance3D
		var lead := _views[id][1] as MeshInstance3D
		wrap.position.y = (float(index) - float(active.size() - 1) * 0.5) * float(Tuning.current().rope_coil_visual.gauge)
		wrap.visible = body.visible
		var from := wrap.to_global(SurveyorLooks.WAIST_KNOT)
		var span := player.world.ropes.shown_end(end) - from
		lead.visible = body.visible and span.length() > 0.001
		if lead.visible:
			var turn := Basis(Quaternion(Vector3.UP, span.normalized()))
			turn.y *= span.length()
			lead.global_transform = Transform3D(turn, from)
		index += 1


func _hide_end(id: int, holder: Node3D) -> void:
	_hidden[id] = []
	if not holder is RopeTip:
		return
	for child in holder.get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and mesh.visible:
			mesh.visible = false
			_hidden[id].append(mesh)


func _show_end(id: int) -> void:
	# Untyped: the end may have been freed with its line.
	for mesh in _hidden.get(id, []):
		if is_instance_valid(mesh):
			(mesh as MeshInstance3D).visible = true
	_hidden.erase(id)


func _exit_tree() -> void:
	for id in _hidden.keys():
		_show_end(id)
