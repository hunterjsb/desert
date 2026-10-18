extends WorldProbe
## Time limit: 900 s

func run() -> void:
	start_among(1234)
	await load_world(1234, false, true)
	var here := Vector2(world.player_world_x(), world.player_world_z())
	# The town's middle: the mean of its standing house ruins near.
	var ruins := structures_near(&"house_ruin", 900.0)
	var mid := Vector2.ZERO
	for r in ruins:
		mid += Vector2(r.x, r.z)
	mid /= maxi(ruins.size(), 1)
	var storm := StormSite.strongest(world.weather.field, world.tuning, mid.x, mid.y, 0, 100.0, 2.0)
	print("town of %d house ruins; storm work at its middle peaks at %.0f s, %.2f m" % [ruins.size(), storm.peak, storm.taken[1]])
	for phase in [["calm", storm.before - 3600.0], ["storm", storm.peak - 480.0]]:
		world.time_warp = 0.0
		world.time = phase[1]
		teleport(mid.x, mid.y)
		await settle()
		world.terrain.slowest_follow_ms = 0.0
		world.terrain.slowest_press_ms = 0.0
		world.salvage.slowest_ms = 0.0
		world.terrain.skyline.slowest_ms = 0.0
		var p0 := world.terrain.presses
		var sum := 0.0
		var frames := 0
		var live := 0
		world.time_warp = 10.0
		var started := Time.get_ticks_msec()
		for i in 2400:
			await get_tree().process_frame
			sum += world.terrain.follow_ms
			frames += 1
		world.time_warp = 0.0
		for chunk: TerrainChunk in world.terrain.chunks():
			live += chunk.structures().size()
		print("%s: %d structures standing on loaded ground; follow %.3f ms a frame on average, %.2f at most; %d presses, slowest swap %.2f ms, a press %.2f ms on its worker; salvage slowest %.2f ms, skyline %.2f ms; %d frames in %d ms; time %.0f"
			% [phase[0], live, sum / frames, world.terrain.slowest_follow_ms, world.terrain.presses - p0,
			world.terrain.slowest_press_ms, world.terrain.press_job_ms, world.salvage.slowest_ms,
			world.terrain.skyline.slowest_ms, frames, Time.get_ticks_msec() - started, world.time])
