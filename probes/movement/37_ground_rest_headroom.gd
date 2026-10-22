extends "res://probes/movement/36_ground_rest_and_crawl.gd"
## Runs alone
## A crawl fits below a low roof, but standing and jumping cannot cross it;
## lying down needs the length of you clear behind.

func run() -> void:
	await load_moving()
	set_rate(60, 2)
	blow(Vector2.ZERO)
	var base := player.global_position + Vector3.UP * 3.0
	_box(Vector3(30.0, 0.2, 30.0), base - Vector3.UP * 0.1)
	player.global_position = base + Vector3.UP * 0.03
	await simulate(0.4)
	var wall := _box(Vector3(3.0, 1.0, 0.2), base + player.global_basis.z * 0.9 + Vector3.UP * 0.5)
	await simulate(0.1)
	_action("lie_down")
	check(player.ground_pose == &"stand", "a wall at your back leaves no room to lie down")
	wall.queue_free()
	await simulate(0.1)
	_action("lie_down")
	# The roof arrives while the eyes are still easing down from standing.
	var roof := _box(Vector3(5.0, 0.2, 5.0), base + Vector3.UP * 1.05)
	# One tick for the space to hold it; the eyes have barely begun to lower.
	await get_tree().physics_frame
	var highest := -INF
	for i in 8:
		await get_tree().process_frame
		highest = maxf(highest, player.camera.global_position.y)
	check(highest < base.y + 0.95, "a ceiling contains the eye during its smooth lowering")
	await simulate(0.3)
	player.feel.restore_posture()
	check(player.camera.position.y < 0.6, "restored prone eyes fit before the first rendered frame")
	_action("lie_down")
	hold(["jump"])
	await simulate(0.3)
	check(player.ground_pose == &"prone" and player.global_position.y < base.y + 0.1,
		"blocked rise keeps prone shape and does not launch through roof")
	hold([])
	var board := board_here()
	check(not player.get_on(board), "boarding cannot silently expand through the roof")
	roof.queue_free()
	await simulate(0.1)
	hold(["jump"])
	await simulate(0.15)
	check(player.ground_pose == &"stand" and player.global_position.y > base.y + 0.1,
		"clear headroom permits standing and the requested jump")
	hold([])
	set_rate(60)
