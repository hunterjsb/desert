extends WorldProbe
## Time limit: 900 s

const KINDS := [&"house_ruin", &"hab_pod", &"cistern", &"pipe_wall_hut", &"wayshrine", &"dugout", &"watchtower", &"wreck_hull"]

func run() -> void:
	await load_world(1234, false, true)
	world.time_warp = 0.0
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x() + 300.0, world.player_world_z())
	var storm := StormSite.strongest(world.weather.field, world.tuning, from.x, from.y, 1, 100.0, 1.0)
	print("storm peak %.0f at %.0f,%.0f: %s" % [storm.peak, storm.x, storm.z, str(storm.taken)])
	var made := 0
	for k in 40:
		var kind: StringName = KINDS[k % KINDS.size()]
		var at := Vector2(storm.x, storm.z) + Vector2.from_angle(k * 2.4) * (20.0 + k * 9.0)
		var site := sites.by_hand(kind, at.x, at.y, k * 0.7, 0.0)
		if not site.stands():
			continue
		var taken := site.pure_taken(storm.peak)
		var before := site.pure_taken(storm.before)
		# Deep enough to come out of the sand during the rise.
		site.depth = clampf(lerpf(before * 3.2, taken * 0.9, float(k % 5) / 5.0), 0.2, 8.0)
		sites.add(site)
		made += 1
	print("%d sites laid by hand round it" % made)
	for phase in [["1x rise", storm.peak - 420.0, 1.0, 3600], ["10x rise", storm.peak - 420.0, 10.0, 2400]]:
		world.time_warp = 0.0
		world.time = phase[1]
		teleport(storm.x + 15.0, storm.z + 15.0)
		await settle()
		world.terrain.slowest_follow_ms = 0.0
		world.terrain.slowest_press_ms = 0.0
		world.salvage.slowest_ms = 0.0
		world.terrain.skyline.slowest_ms = 0.0
		world.terrain.slowest_frame_ms = 0.0
		var p0 := world.terrain.presses
		var sum := 0.0
		var sky := 0.0
		var frames := 0
		var live := 0
		var jobs := 0.0
		world.time_warp = phase[2]
		for i in phase[3]:
			await get_tree().process_frame
			sum += world.terrain.follow_ms
			sky += world.terrain.skyline.frame_ms
			jobs = maxf(jobs, world.terrain.press_job_ms)
			frames += 1
		world.time_warp = 0.0
		for chunk: TerrainChunk in world.terrain.chunks():
			live += chunk.structures().size()
		print("%s: %d structures on loaded ground; follow %.3f ms a frame on average, %.2f at most; %d presses, slowest swap %.2f ms, a press up to %.2f ms on its worker; salvage slowest %.2f ms; skyline %.3f ms a frame, %.2f at most; terrain's slowest frame %.2f ms; %s in storm"
			% [phase[0], live, sum / frames, world.terrain.slowest_follow_ms, world.terrain.presses - p0,
			world.terrain.slowest_press_ms, jobs, world.salvage.slowest_ms, sky / frames,
			world.terrain.skyline.slowest_ms, world.terrain.slowest_frame_ms, world.weather.in_storm])
	# One-off reads.
	world.time = storm.peak
	var x: float = storm.x + 15.0
	var z: float = storm.z + 15.0
	var t0 := Time.get_ticks_usec()
	var n := 0
	for i in 100:
		n += world.shape.sites.newly_exposed(x, z, 140.0).size()
	print("newly_exposed within 140 m: %.1f us a call, %d sites" % [(Time.get_ticks_usec() - t0) / 100.0, n / 100])
	var a := Vector2(x + 40.0, z - 4.0)
	var b := Vector2(x + 40.0, z + 4.0)
	t0 = Time.get_ticks_usec()
	var near := []
	for i in 20:
		near = Drift.near_line(world, a, b)
	print("near_line: %.1f us, %d sites" % [(Time.get_ticks_usec() - t0) / 20.0, near.size()])
	t0 = Time.get_ticks_usec()
	for i in 100:
		Drift.caught(world, a, b, floori(storm.peak / 20.0) + i, near)
	print("a drift tick for a line among them: %.1f us" % [(Time.get_ticks_usec() - t0) / 100.0])
	t0 = Time.get_ticks_usec()
	for i in 100:
		Drift.caught(world, a, b, floori(storm.peak / 20.0) + i, [])
	print("and with no sites near: %.1f us" % [(Time.get_ticks_usec() - t0) / 100.0])
	var sky := world.terrain.skyline
	for name: String in ["_draw_dust", "_draw_own", "_draw", "_launch"]:
		var most := 0.0
		var sum := 0.0
		for i in 20:
			var t1 := Time.get_ticks_usec()
			sky.call(name)
			var took := (Time.get_ticks_usec() - t1) / 1000.0
			most = maxf(most, took)
			sum += took
			await get_tree().process_frame
		print("skyline %s: %.3f ms on average, %.3f at most" % [name, sum / 20.0, most])
