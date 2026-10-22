extends SailProbe
## A contained kite flies on one ordinary waist line and pulls a board without motor input.


func run() -> void:
	await load_sailing()
	blow(downwind * 10.0)
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-downwind.x, -downwind.y)), open + Vector3.UP * 0.1))
	var board := Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	fit_part(board, &"battery")
	board.global_position = player.global_position + Vector3.UP * 0.2
	await physics_frames(2)
	var kite := Catalog.device(&"salvage_kite") as SalvageKite
	world.content.add_child(kite)
	kite.global_position = player.global_position + Vector3.UP * 1.5
	check(kite.use(player, kite.global_position), "the kite launches")
	var line := kite.laid()
	check(player.get_on(board) and player.board == board, "the rider boards without untying the flying kite")
	check(line != null and player.waist.tied.size() == 1, "one ordinary waist line holds the kite")
	var began := player.global_position
	var seen := {"peak": 0.0}
	await simulate(35.0, func() -> void:
		seen.peak = maxf(seen.peak, line.rope.tension))
	var moved := Vector2(player.global_position.x - began.x, player.global_position.z - began.z).dot(downwind)
	var height := kite.global_position.y - world.height_under(kite.global_position)
	print("kite: %.1f m downwind, %.1f m aloft, %.1f N peak, player %.2f m/s, %d waist lines" % [moved, height, seen.peak, player.velocity.length(), player.waist.tied.size()])
	metric("motor-off downwind", moved, "m")
	metric("height", height, "m")
	metric("peak pull", seen.peak, "N")
	check(moved > 10.0 and seen.peak > 20.0 and player.board == board, "wind tows the rider with no motor input")
	check(height > 5.0 and kite.flying, "the kite flies above the rider")
	var was := line.rope.length
	check(hands.reel.notch(1), "the sole waist line reels without selecting it")
	await simulate(1.0)
	check(not kite.paying and line.rope.length < was, "manual reeling holds the launch line short")
