class_name GroundPosture
extends RefCounted
## Ground rest changes clearance, never the forces or moving support beneath you.

var player: Player
var shape: CollisionShape3D
var standing: CapsuleShape3D
var tuning := Tuning.current()
var standing_eye: float


func _init(by: Player) -> void:
	player = by
	standing_eye = player.camera.position.y
	shape = player.get_node("Body")
	standing = shape.shape.duplicate()
	shape.shape = standing.duplicate()


func height(pose: StringName) -> float:
	match pose:
		&"sit": return tuning.posture_sit_height
		&"prone": return tuning.posture_prone_height
	return standing.height


func clear(pose: StringName) -> bool:
	var capsule := standing.duplicate() as CapsuleShape3D
	capsule.height = maxf(capsule.radius * 2.0, height(pose) - player.safe_margin * 2.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(player.global_basis, player.global_position + Vector3.UP * (height(pose) * 0.5 + player.safe_margin * 2.0))
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	var space := player.get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	return pose != &"prone" or _room_to_lie(space)


## Lying down you stretch out behind your eyes, so the length of you needs
## room as well as your shape; the sand under you doesn't count.
func _room_to_lie(space: PhysicsDirectSpaceState3D) -> bool:
	var radius := standing.radius
	var long := maxf(tuning.posture_prone_length - radius, 0.1)
	var box := BoxShape3D.new()
	box.size = Vector3(radius * 1.4, tuning.posture_prone_height * 0.4, long)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = player.global_transform * Transform3D(Basis.IDENTITY,
		Vector3(0.0, box.size.y * 0.5 + 0.1, radius + long * 0.5))
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	for hit: Dictionary in space.intersect_shape(query, 8):
		var body := hit.collider as CollisionObject3D
		var owner := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as CollisionShape3D \
			if body != null else null
		if owner == null or not owner.shape is HeightMapShape3D:
			return false
	return true


func restore(pose: StringName) -> void:
	player.ground_pose = pose if pose in [&"sit", &"prone"] else &"stand"
	var capsule := shape.shape as CapsuleShape3D
	capsule.height = height(player.ground_pose)
	shape.position.y = capsule.height * 0.5


func change(pose: StringName) -> bool:
	if pose == player.ground_pose:
		return true
	if not clear(pose):
		return false
	restore(pose)
	player.walker.stop()
	if pose != &"stand" and player.world != null:
		Deeds.done(player.world, &"ground_rest")
	if pose == &"prone" and Controls.ui != null:
		Controls.ui.teach(Controls.REST_HOW_TO, Controls.REST_HOW_TO_SAYS)
	return true


func toggle(pose: StringName) -> bool:
	if not Controls.playing() or player.vitals.dead or player.vitals.wounds.stunned() \
			or player.flying or player.ride != null or player.helm != null or player.tumble != null \
			or player.vault.active or not player.is_on_floor():
		return false
	return change(&"stand" if player.ground_pose == pose else pose)


func eye_drop() -> float:
	match player.ground_pose:
		&"sit": return standing_eye - tuning.posture_sit_eye
		&"prone": return standing_eye - tuning.posture_prone_eye
	return 0.0


func catch_share() -> float:
	match player.ground_pose:
		&"sit": return tuning.posture_sit_catch
		&"prone": return tuning.posture_prone_catch
	return 1.0
