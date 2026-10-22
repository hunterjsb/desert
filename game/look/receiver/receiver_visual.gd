class_name ReceiverVisual
extends Node3D
## The model owns its pivots; the receiver supplies only instrument state.

@export var shell: MeshInstance3D
@export var meter: Node3D
@export var tuning: Node3D
@export var volume: Node3D
@export var reading: Node3D
@export var painted_meshes: Array[MeshInstance3D] = []

var _rest := {}


func usable() -> bool:
	for node: Node3D in [shell, meter, tuning, volume, reading]:
		if node == null or not is_ancestor_of(node):
			return false
	for view in painted_meshes:
		if view == null or not is_ancestor_of(view):
			return false
	return shell.mesh != null


func prepare() -> void:
	if painted_meshes.is_empty():
		for view: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
			painted_meshes.append(view)
	for node: Node3D in [meter, tuning, volume]:
		_rest[node] = node.transform


func present(strength: float, tuning_angle: float, volume_angle: float) -> void:
	meter.transform = _turned(meter, lerpf(PI / 3.0, -PI / 3.0, strength))
	tuning.transform = _turned(tuning, tuning_angle)
	volume.transform = _turned(volume, volume_angle)


func _turned(node: Node3D, angle: float) -> Transform3D:
	var rest: Transform3D = _rest[node]
	return rest * Transform3D(Basis(Vector3.BACK, angle), Vector3.ZERO)


## A carry preview reads the actual meter without waiting for its spring.
func preview_pose(view: MeshInstance3D, strength: float) -> Transform3D:
	var pose := Transform3D.IDENTITY
	var node: Node = view
	while node != self:
		var local: Transform3D = (node as Node3D).transform
		if node == meter:
			local = _turned(meter, lerpf(PI / 3.0, -PI / 3.0, strength))
		pose = local * pose
		node = node.get_parent()
	return transform * pose


## Imported scenes keep their authored shell. Procedural scenes may rebuild it.
func apply_frame_look(_mesh: ArrayMesh) -> void:
	pass


## Imported material adapters can override this without touching the receiver.
func appearance(age: float, era: float, lit: float) -> void:
	for view in painted_meshes:
		view.set_instance_shader_parameter(&"age", age)
		view.set_instance_shader_parameter(&"era", era)
		view.set_instance_shader_parameter(&"lit", lit)
