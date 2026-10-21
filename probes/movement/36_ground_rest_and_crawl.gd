extends MovementProbe
## Runs alone
## Ground posture input remains useful movement: sit rises, prone crawls.

func run() -> void:
	await load_moving()
	set_rate(60, 2)
	blow(Vector2.ZERO)
	var base := player.global_position + Vector3.UP * 3.0
	_box(Vector3(30.0, 0.2, 30.0), base - Vector3.UP * 0.1)
	player.global_position = base + Vector3.UP * 0.03
	await simulate(0.4)
	_action("sit")
	await simulate(0.5)
	check(player.ground_pose == &"sit" and player.camera.position.y < 1.1, "sit lowers eyes on supported ground")
	hold(["move_forward"])
	await simulate(0.4)
	check(player.ground_pose == &"stand", "moving rises from sitting")
	hold([])
	await simulate(0.5)
	_action("lie_down")
	await simulate(0.5)
	var from := player.global_position
	hold(["move_forward", "sprint"])
	await simulate(1.0)
	var distance := player.global_position.distance_to(from)
	check(player.ground_pose == &"prone" and distance > 0.3 and distance < 0.8, "prone movement crawls even with sprint held")
	check(player.camera.position.y < 0.6, "crawl keeps eyes low")
	hold([])
	_action("lie_down")
	await simulate(0.5)
	check(player.ground_pose == &"stand", "lie action rises again")
	player.global_position += Vector3.UP * 3.0
	await simulate(0.05)
	_action("sit")
	check(player.ground_pose == &"stand", "cannot sit in the air")
	set_rate(60)


func _action(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	player._unhandled_input(press)


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
