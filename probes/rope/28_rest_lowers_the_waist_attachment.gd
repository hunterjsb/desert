extends "res://probes/rope/25_the_paying_coil_follows_your_hand.gd"
## A low body must carry its actual waist attachment below its own clearance.
func run() -> void:
	await super.run()
	var player := world.player
	var body: RigidBody3D = player.waist.tied[0]
	var tip := Line._tip(body)
	for pose: StringName in [&"sit", &"prone"]:
		player.restore_ground_pose(pose)
		player.waist._place()
		check(tip.global_position.y - player.global_position.y < player.posture.height(pose),
			"waist lines stay on the supported low body")
	player.restore_ground_pose(&"stand")
	player.waist._place()
	check(absf(tip.global_position.y - player.global_position.y - Waist.AT.y) < 0.001,
		"standing restores the existing belt attachment")
