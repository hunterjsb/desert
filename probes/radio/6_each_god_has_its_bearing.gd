extends WeatherProbe
## Radio probe 6: each god has its bearing. Wherever a radio stands, it knows
## which way each of the seven gods lies and how far: carried a few hundred
## metres the way it says, it comes nearer by about that much. The Walker
## never stops, so its bearing moves on with the clock while the others hold.
## Near gods come as compass points; one past god_rough_m only as a way
## across the moon.

## How far the radio is carried toward each god, m.
const STEP := 400.0
## The Walker's walk is checked over this much world time, s.
const LATER := 600.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var tuning := Tuning.current()
	var home := radio.global_position
	for id in Gods.ids():
		radio.global_position = home
		var way := radio.god_way(id)
		var dir := Vector2(sin(deg_to_rad(way.bearing)), -cos(deg_to_rad(way.bearing)))
		radio.global_position = home + Vector3(dir.x, 0.0, dir.y) * STEP
		var nearer: float = way.metres - radio.god_way(id).metres
		print("%s: %.1f km, %s; %d m its way comes %.0f m nearer" % [Gods.title(id), way.metres / 1000.0, way.way,
			roundi(STEP), nearer])
		check(nearer > STEP * 0.9 and nearer < STEP * 1.01, "%s lies the way it says" % Gods.title(id))
		var said: String = way.way
		var a_point := Radio.POINTS.any(func(point: String) -> bool: return said.ends_with(point))
		if way.metres <= tuning.god_rough_m:
			check(a_point, "%s, %.0f km off, comes as a compass point" % [Gods.title(id), way.metres / 1000.0])
		else:
			check(not a_point, "%s, %.0f km off, comes only as a way across the moon" % [Gods.title(id),
				way.metres / 1000.0])
	radio.global_position = home

	var walker := radio.god_way(&"walker")
	var ledger := radio.god_way(&"ledger")
	world.time += LATER
	var walked := radio.god_way(&"walker")
	var held := radio.god_way(&"ledger")
	print("over %d s the Walker went from %.0f° %.0f m to %.0f° %.0f m" % [roundi(LATER), walker.bearing,
		walker.metres, walked.bearing, walked.metres])
	check(absf(walked.metres - walker.metres) > 100.0 or absf(angle_difference(deg_to_rad(walked.bearing),
		deg_to_rad(walker.bearing))) > deg_to_rad(0.2), "the Walker moves on with the clock")
	check(is_equal_approx(held.metres, ledger.metres) and is_equal_approx(held.bearing, ledger.bearing),
		"the Ledger stays where it stands")
