extends MovementProbe
## Movement probe 32: sprint or jump boards a reachable ledge without walking
## through walls, ceilings, or repeatedly climbing beyond the jump's real rise.

var _base := Vector3.ZERO
var _ledge: Node3D


func run() -> void:
	await load_moving()
	set_rate(60, 2)
	blow(Vector2.ZERO)
	world.counts_deeds = true
	_base = player.global_position + Vector3.UP * 3.0
	var floor_body := _box(Vector3(30.0, 0.2, 30.0), _base - Vector3.UP * 0.1)
	_ledge = _box(Vector3(4.0, 0.5, 4.0), _base + Vector3(2.0, 0.25, 0.0))
	await _start()
	hold(["move_forward"])
	await simulate(1.0)
	check(player.global_position.x < _base.x, "plain walking does not automatically climb the ledge")
	await _start()
	hold(["move_forward", "sprint"])
	var saved := {"data": {}}
	await simulate(0.9, func() -> void:
		if player.vault.active and player.vault._elapsed > 0.06 and saved.data.is_empty():
			saved.data = Snapshot.take(world))
	check(not saved.data.is_empty() and absf(saved.data.player.v.y) < 0.01,
		"saving mid-climb does not store the upward climb speed as a jump")
	print("sprint landing ", player.global_position - _base, " active ", player.vault.active)
	check(player.global_position.x > _base.x + 0.3 and player.global_position.y > _base.y + 0.45,
		"sprinting vaults onto the reachable top")
	check(get_node(^"/root/Profile").did(&"up_and_over"), "a completed real vault earns its deed")

	await _start()
	var obstruction := {"wall": null}
	hold(["move_forward", "sprint"])
	await simulate(0.9, func() -> void:
		if player.vault.active and player.vault._elapsed > 0.08 and obstruction.wall == null:
			obstruction.wall = _box(Vector3(0.1, 3.0, 4.0), _base + Vector3(0.2, 1.5, 0.0)))
	check(obstruction.wall != null and not player.vault.active and player.global_position.x < _base.x,
		"a newly blocked path cancels instead of clipping through")
	if is_instance_valid(obstruction.wall):
		obstruction.wall.queue_free()

	await _start()
	var vanished := {"removed": false, "end_height": -INF, "on_floor": true}
	hold(["move_forward", "sprint"])
	await simulate(0.9, func() -> void:
		if player.vault.active and player.vault._elapsed > 0.08 and not vanished.removed:
			(_ledge.get_child(0) as CollisionShape3D).set_deferred("disabled", true)
			vanished.removed = true
		elif vanished.removed and not player.vault.active and vanished.end_height == -INF:
			vanished.end_height = player.global_position.y - _base.y
			vanished.on_floor = player.is_on_floor())
	print("vanished top ", vanished)
	check(vanished.removed and not vanished.on_floor and vanished.end_height > world.tuning.vault_clearance,
		"a vanished top leaves you to fall instead of snapping to distant ground")

	_ledge.queue_free()
	await get_tree().physics_frame
	_ledge = _box(Vector3(4.0, 2.2, 4.0), _base + Vector3(2.0, 1.1, 0.0))
	await _start()
	hold(["move_forward", "sprint", "jump"])
	await simulate(1.5)
	check(player.global_position.x < _base.x and not player.vault.active, "jumping does not climb an unreachable wall")

	_ledge.queue_free()
	await get_tree().physics_frame
	_ledge = _box(Vector3(4.0, 0.5, 4.0), _base + Vector3(2.0, 0.25, 0.0))
	var roof := _box(Vector3(8.0, 0.2, 4.0), _base + Vector3(0.0, 2.1, 0.0))
	await _start()
	hold(["move_forward", "sprint"])
	await simulate(0.9)
	check(player.global_position.x < _base.x and not player.vault.active, "a low ceiling blocks the whole capsule")
	roof.queue_free()
	_ledge.queue_free()
	await get_tree().physics_frame
	_ledge = _box(Vector3(4.0, 1.4, 4.0), _base + Vector3(2.0, 0.7, 0.0))
	await _start()
	hold(["move_forward", "sprint"])
	await simulate(0.9)
	check(player.global_position.x < _base.x, "the taller ledge is outside standing reach")
	await _start()
	hold(["move_forward"])
	await simulate(0.18)
	hold(["move_forward", "jump"])
	await simulate(1.2)
	print("jump landing ", player.global_position - _base)
	check(player.global_position.x > _base.x + 0.3 and player.global_position.y > _base.y + 1.35,
		"actual jump rise extends the same vault reach")

	_ledge.queue_free()
	await get_tree().physics_frame
	var deck := RigidBody3D.new()
	deck.mass = 200.0
	deck.gravity_scale = 0.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 0.3, 4.0)
	shape.shape = box
	deck.add_child(shape)
	world.content.add_child(deck)
	deck.global_position = _base + Vector3(2.0, 0.4, 0.0)
	await _start()
	deck.linear_velocity = Vector3(0.25, 0.0, 0.1)
	deck.angular_velocity = Vector3(0.0, 0.08, 0.0)
	hold(["move_forward", "sprint"])
	var changes := {"climb": Vector3.ZERO, "spin": Vector3.ZERO, "shifted": false}
	await simulate(0.9, func() -> void:
		if player.vault.active:
			if not changes.shifted and player.vault._elapsed > 0.1:
				world.shift_origin(Vector2i(1, 0))
				_base.x -= world.tuning.chunk_size
				changes.shifted = true
			changes.climb = deck.linear_velocity
			changes.spin = deck.angular_velocity)
	print("vault last motion ", changes)
	print("moving landing ", player.global_position - _base, " velocity ", deck.linear_velocity, " spin ", deck.angular_velocity)
	check(player.global_position.y > _base.y + 0.5 and deck.to_local(player.global_position).x > -1.7,
		"vault follows a translating and rotating deck across an origin shift")
	check(changes.climb.distance_to(Vector3(0.25, 0.0, 0.1)) < 0.02 and changes.spin.distance_to(Vector3(0.0, 0.08, 0.0)) < 0.01,
		"the climb adds no kick or spin before ordinary deck contact")
	hold([])
	deck.queue_free()
	floor_body.queue_free()
	set_rate(60)


func _start() -> void:
	hold([])
	player.vault.cancel()
	world.teleport(player, Transform3D(player.global_basis, _base + Vector3(-1.2, 0.03, 0.0)))
	player.velocity = Vector3.ZERO
	player.own = Vector2.ZERO
	player.stamina = world.tuning.stamina_max
	face(Vector2.RIGHT)
	await simulate(0.25)


func _box(size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.content.add_child(body)
	body.global_position = at
	return body
