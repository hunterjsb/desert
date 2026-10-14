extends WorldProbe
## World & terrain probe 7: streaming 3 km of ground never blocks the main thread
## for longer than the per-chunk upload limit. Headless runs skip the GPU upload,
## so this bounds everything the main thread does short of rendering.


func run() -> void:
	await load_world()
	var x := world.player_world_x()
	var z := world.player_world_z()
	for i in 3000 / 16:
		x += 16.0
		teleport(x, z)
		await settle(true)
	var limit := Tuning.current().chunk_upload_max_ms
	var slowest := world.terrain.max_upload_ms
	print("slowest chunk upload %.2f ms" % slowest)
	check(slowest < limit, "no chunk upload took longer than %.1f ms (slowest %.2f)" % [limit, slowest])
