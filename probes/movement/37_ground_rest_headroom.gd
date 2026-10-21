extends "res://probes/movement/36_ground_rest_and_crawl.gd"
## Runs alone
## A crawl fits below a low roof, but standing and jumping cannot cross it.

func run() -> void:
	await load_moving()
	set_rate(60, 2)
	blow(Vector2.ZERO)
	var base := player.global_position + Vector3.UP * 3.0
	_box(Vector3(30.0, 0.2, 30.0), base - Vector3.UP * 0.1)
	player.global_position = base + Vector3.UP * 0.03
	await simulate(0.4)
	_action("lie_down")
	await simulate(0.3)
	var roof := _box(Vector3(5.0, 0.2, 5.0), base + Vector3.UP * 1.05)
	await simulate(0.1)
	player.feel.restore_posture()
	check(player.camera.position.y < 0.6, "restored prone eyes fit before the first rendered frame")
	player.feel._drop = 0.0
	player.feel._process(0.001)
	check(player.camera.global_position.y < base.y + 0.95, "a ceiling contains the eye during its smooth lowering")
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
