extends ShieldProbe
## Survival probe 21: the bedroll unrolls. Laid out from your hands, it
## unrolls flat over a moment; looked at by its head it sleeps you as it did;
## taken, it rolls back up where it lay, then shows in your hands; and a
## save keeps it laid, coming back flat, not unrolling again.


func run() -> void:
	await load_storm(0.0)
	var player := world.player
	var hands := player.hands
	var bedroll := Catalog.device(&"bedroll") as Bedroll
	world.content.add_child(bedroll)
	bedroll.global_position = player.camera.global_position + Vector3(0.0, -0.3, -0.5)
	hands.hold(bedroll)
	await live(0.5, 1.0)
	player.camera.rotation.x = -0.9
	await physics_frames(1)
	hands.interact()
	await live(0.3, 1.0)
	var early := bedroll.opened()
	await live(1.2, 1.0)
	check(bedroll.laid and early > 0.0 and early < 0.9 and bedroll.opened() == 1.0 and not bedroll.frame_view.visible,
		"laid, it unrolls flat over a moment (%.2f, then %.2f)" % [early, bedroll.opened()])

	var head := bedroll.global_position
	_look_at(head)
	await physics_frames(2)
	check(hands.look_device == bedroll and world.sleep.refusal() == "",
		"by its head it's the bedroll, and you can sleep (%s)" % world.sleep.refusal())
	var from := world.time
	world.time_warp = 1.0
	world.sleep.fall_asleep(Sleep.HOURS, 1)
	while world.sleep.sleeping:
		await get_tree().physics_frame
	world.time_warp = 0.0
	check(world.time - from >= world.tuning.day_minutes * 60.0 / 24.0, "it sleeps you an hour (%.0f s)" % (world.time - from))

	_look_at(head)
	await physics_frames(2)
	check(hands.grab() and hands.held == bedroll, "take picks it up")
	await live(0.2, 1.0)
	var left := bedroll._spread.global_position.distance_to(head)
	var rolling := bedroll.opened()
	await live(0.8, 1.0)
	check(not bedroll.laid and rolling > 0.0 and left < 0.01 and bedroll.opened() == 0.0 and bedroll.frame_view.visible,
		"taken, it rolls up where it lay (%.2f m off it, %.2f open), then shows in your hands" % [left, rolling])

	player.camera.rotation.x = -0.9
	await physics_frames(1)
	hands.interact()
	await live(1.5, 1.0)
	var again := Catalog.device(&"bedroll") as Bedroll
	Snapshot.new(world)._set_state(again, {"state": Snapshot.new(world)._state(bedroll)})
	check(again.laid and again.opened() == 1.0 and not again.frame_view.visible, "a save keeps it laid, flat at once")
	again.free()


func _look_at(point: Vector3) -> void:
	var player := world.player
	var to := point - player.camera.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
