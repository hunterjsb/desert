extends LargeCampProbe
## Runs alone
## Time limit: 600 s
## A 108-frame camp admitted under the normal cap stays live through a board trip.

var home_at := Vector2.ZERO


const BUDGET_MS := 10.0

func run() -> void:
	await large_camp(true)
	shelter.stand(true)
	check(world.home.mark(marker) == "", "the lighter 108-frame camp fits ordinary Home limits")
	await settle()
	await simulate(2.0)
	check(world.home.supported and world.home.work_count() <= world.tuning.home_max_bodies,
		"the complete camp is admitted and its support is ready")
	var expected_work := world.home.work_count()
	print("LARGE HOME work_items=%d members=%d" % [world.home.work_count(), world.home.members.size()])
	home_at = Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
	await measure("Large Home near", BUDGET_MS)
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	var at := deck.global_position + Vector3(-4.0, 0.0, -4.0)
	at.y = world.height_under(at) + 0.1
	world.teleport(player, Transform3D(Basis.IDENTITY, at))
	var board := Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	fit_part(board, &"battery")
	board.global_position = player.global_position + Vector3.UP * 0.2
	await physics_frames(2)
	check(player.get_on(board), "the scout mounts a real powered board")
	Input.action_press(&"move_forward")
	speed_up(4)
	await _ride(false)
	speed_up(1)
	check(player.board == board and world.home.supported and not deck.freeze,
		"the distant camp remains active while the board scouts")
	var used := world.power.used_wh
	await measure("Large Home while scouting", BUDGET_MS, false)
	check(shelter.running() and world.power.used_wh > used, "remote shelter consumes real power")
	speed_up(4)
	await _ride(true)
	Input.action_release(&"move_forward")
	player.step_off()
	player.set_physics_process(false)
	speed_up(1)
	await settle()
	await measure("Large Home returned", BUDGET_MS, false)
	check(world.home.work_count() == expected_work, "all admitted fittings survive the trip")
	check(Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z)).distance_to(home_at) < 0.3,
		"the resident camp keeps its physical place through origin shifts")
	check(deck.pieces().size() == 108 and world.home.supported and shelter.running() and not deck.freeze,
		"the same complete camp is live on return")


func _ride(returning: bool) -> void:
	for i in 24000:
		var at := Vector2(world.player_world_x(), world.player_world_z())
		var distance := at.distance_to(home_at)
		if (returning and distance < 25.0) or (not returning and distance > 2100.0):
			return
		var way := (home_at - at).normalized() if returning else Vector2(0.0, -1.0)
		world.player.rotation.y = atan2(-way.x, -way.y)
		await get_tree().physics_frame
	check(false, "the powered scouting trip reaches its destination")
