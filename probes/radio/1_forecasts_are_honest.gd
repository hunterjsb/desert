extends WeatherProbe
## Radio probe 1: forecasts are honest. A radio tuned to the weather station,
## standing off on its own away from you, says when the next storm reaches it,
## when that storm clears, its strongest steady wind and the way storms come
## from. Then the clock runs and the storm field does just that where the
## radio is: the storm reaches a place that way first, and one the other way last.

const WARP := 60.0
## One tick of the warped clock, plus the forecast's own resolution.
const TOLERANCE := 1.5
## Where the radio stands, m east of you, and how far either way of it the
## storm's way is checked, m.
const AWAY := 300.0
const ASIDE := 500.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var x := world.player_world_x() + AWAY
	var z := world.player_world_z()
	var horizon := Tuning.current().radio_forecast_minutes * 60.0
	# A storm reaching the radio in 3 to 10 minutes that clears inside the station's horizon.
	var start := find_time(func(t: float) -> bool:
		if field.raw_storm_at(x, z, t) > 0.0:
			return false
		var arrives := field.next_change(x, z, t, 600.0, 5.0)
		return arrives > 180.0 and arrives < 600.0 \
			and field.next_change(x, z, t + arrives + 1.0, horizon - arrives - 60.0, 5.0) < INF)
	world.time = start
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.global_position = Vector3(world.engine_x(x), world.height_at(x, z) + 0.2, world.engine_z(z))
	while radio.channel != Radio.WEATHER:
		radio.sweep()
	await physics_frames(2)
	var said := radio.reading.duplicate()
	check(not said.is_empty() and not said.stormy and said.change < INF and said.back < INF,
		"the station sees the storm coming and clearing")
	if said.is_empty() or said.back == INF:
		return

	world.time_warp = WARP
	var arrived := INF
	var cleared := INF
	var strongest := 0.0
	while world.time < said.back + 120.0 and cleared == INF:
		await get_tree().physics_frame
		var t := world.time
		if field.raw_storm_at(x, z, t) > 0.0:
			arrived = minf(arrived, t)
			strongest = maxf(strongest, field.steady_wind_at(x, z, t).length())
		elif arrived < INF:
			cleared = t
	world.time_warp = 1.0
	print("said: arrives %.1f s, clears %.1f s, winds %.1f m/s; seen: %.1f s, %.1f s, %.1f m/s"
		% [said.change - start, said.back - start, said.wind, arrived - start, cleared - start, strongest])
	check(absf(arrived - said.change) <= TOLERANCE, "the storm arrived when said (off by %.1f s)" % (arrived - said.change))
	check(absf(cleared - said.back) <= TOLERANCE, "the storm cleared when said (off by %.1f s)" % (cleared - said.back))
	check(absf(strongest - said.wind) <= said.wind * 0.02,
		"its winds were as strong as said (%.1f m/s, said %.1f)" % [strongest, said.wind])

	# Storms ride in from where it says: the storm reaches the side it named first.
	var way := Vector2(sin(deg_to_rad(said.from)), -cos(deg_to_rad(said.from))) * ASIDE
	var upwind := field.next_change(x + way.x, z + way.y, start, horizon, 1.0)
	var downwind := field.next_change(x - way.x, z - way.y, start, horizon, 1.0)
	check(upwind < said.change - start and said.change - start < downwind,
		"it comes from the %s: %d m that way it arrives %.0f s sooner, the other way %.0f s later"
		% [Radio.compass(said.from), ASIDE, said.change - start - upwind, downwind - (said.change - start)])
