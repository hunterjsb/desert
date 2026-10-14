extends WeatherProbe
## Wind & storms probe 3: the forecast at a fixed point says when the storm
## arrives and when it clears, and the running game agrees: the player standing
## there sees it flip at the forecast time, through the real clock.

const WARP := 60.0
## One tick of the warped clock, plus the forecast's own resolution.
const TOLERANCE := 1.5


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var x := world.player_world_x()
	var z := world.player_world_z()
	# A storm arriving in 3 to 10 minutes that clears inside the readout's horizon.
	var start := find_time(func(t: float) -> bool:
		if player_storm_at(t) > 0.0:
			return false
		var arrives := field.next_change(x, z, t, 600.0, 5.0)
		return arrives > 180.0 and arrives < 600.0 \
			and field.next_change(x, z, t + arrives + 1.0, Weather.FORECAST_HORIZON - 60.0, 5.0) < INF)
	world.time = start
	for flip in ["arrives", "clears"]:
		# A fresh forecast is made at least once a second.
		await physics_frames(70)
		var forecast := world.weather.next_change_time
		var was := world.weather.in_storm
		check(forecast < INF, "the forecast sees the storm %s" % flip)
		world.time_warp = WARP
		var seen := INF
		while world.time < forecast + 120.0:
			var before := world.time
			await get_tree().physics_frame
			if world.weather.in_storm != was:
				seen = before
				break
		world.time_warp = 1.0
		print("storm %s: forecast %.1f s, seen %.1f s" % [flip, forecast - start, seen - start])
		check(absf(seen - forecast) <= TOLERANCE,
			"the storm %s when forecast (off by %.1f s)" % [flip, seen - forecast])
