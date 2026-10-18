extends WeatherProbe
## Devices & mods probe 29: the gyro points Tu-ward. A Console with an
## anemometer, carried round the moon: on the near side, the Rim and the far
## side its gyro marks the way Tu stands in the sky, or would past the horizon.

## Latitude and degrees east of the point under Tu, and where that is.
const PLACES := [[0.0, 60.0, "near side, where a run begins"], [35.0, -25.0, "near side, north"],
	[-10.0, 90.0, "the Rim"], [20.0, 150.0, "far side"], [-50.0, -165.0, "far side, south"]]


func run() -> void:
	await load_weather()
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	var made := Scenarios.standing(world, &"console", [&"battery", &"screen", &"anemometer"], [0.0, 2.0]) as Console
	made.freeze = true
	await physics_frames(120)
	var day := world.weather.day
	for place: Array in PLACES:
		world.moon.place(place[0], world.tuning.tu_longitude_degrees + place[1])
		world.time += 97.0
		await physics_frames(2)
		var gyro: Dictionary = made._model(Console.Page.STATS, made.pooled_readings()).get("gyro", {})
		var tu := day.tu_direction(world.time, world.moon.latitude, world.moon.longitude)
		var sky := Radio.bearing(Vector2(tu.x, tu.z))
		var off := absf(wrapf(gyro.get("tu", INF) - sky, -180.0, 180.0))
		check(off <= 0.6, "%s: Tu-ward %s°, Tu stands at %.1f°, %.0f° up" % [place[2], gyro.get("tu", "none"), sky,
			rad_to_deg(asin(tu.y))])
