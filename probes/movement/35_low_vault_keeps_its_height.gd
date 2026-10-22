extends MovementProbe
## Small ground clutter stays ordinary collision and jumping, without a mantle.


func run() -> void:
	await load_moving()
	set_rate(60, 2)
	blow(Vector2.ZERO)
	var base := player.global_position + Vector3.UP * 3.0
	_box(Vector3(30.0, 0.2, 30.0), base - Vector3.UP * 0.1)
	_box(Vector3(4.0, 0.2, 4.0), base + Vector3(2.0, 0.1, 0.0))
	world.teleport(player, Transform3D(player.global_basis, base + Vector3(-1.2, 0.03, 0.0)))
	player.velocity = Vector3.ZERO
	player.own = Vector2.ZERO
	face(Vector2.RIGHT)
	await simulate(0.3)
	var climb := {"seen": false, "peak": 0.0}
	hold(["move_forward", "sprint"])
	await simulate(0.8, func() -> void:
		climb.seen = climb.seen or player.vault.active
		climb.peak = maxf(climb.peak, player.global_position.y - base.y))
	print("low ledge peak ", climb.peak, ", landing ", player.global_position - base)
	check(not climb.seen, "sprinting into small ground clutter never activates a mantle")
	hold([])
	world.teleport(player, Transform3D(player.global_basis, base + Vector3(-1.2, 0.03, 0.0)))
	player.velocity = Vector3.ZERO
	player.own = Vector2.ZERO
	await simulate(0.3)
	climb.seen = false
	hold(["move_forward", "sprint"])
	await simulate(0.15)
	hold(["move_forward", "sprint", "jump"])
	await simulate(0.8, func() -> void: climb.seen = climb.seen or player.vault.active)
	check(not climb.seen and player.global_position.x > base.x + 0.3,
		"an ordinary jump crosses small clutter without entering the mantle")
	hold([])
	set_rate(60)


func _box(size: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.content.add_child(body)
	body.global_position = at
