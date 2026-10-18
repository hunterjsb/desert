extends WeatherProbe
## Wind & storms probe 15: a live vent's plume rises from its mouth and the
## run's wind shapes it. What left the vent at each moment lies where the
## field's drift has carried it since; in a strong wind the plume bends over
## low and runs out long, in a light one it stands taller; and a storm
## between you and it hides it, where clear air shows it.

## How far downwind the bend is compared, m.
const DOWNWIND := 300.0


func run() -> void:
	await load_weather(1234, true)
	await beside_vent(400.0)
	var plume := world.weather.plume
	var root := plume.root
	world.time_warp = 0.0
	var clear := func(t: float) -> bool: return field.raw_storm_at(root.x, root.z, t) < -0.06 \
		and field.raw_storm_at(root.x, root.z, t - 600.0) < -0.06
	var light := find_time(func(t: float) -> bool: return clear.call(t) and field.steady_wind_at(root.x, root.z, t).length() < 6.5)
	var strong := find_time(func(t: float) -> bool: return clear.call(t) and field.steady_wind_at(root.x, root.z, t).length() > 14.0)
	var shapes := []
	for t: float in [light, strong]:
		await _at(t)
		var off := 0.0
		for k in range(4, Plume.POINTS):
			var age := Plume.OLDEST * pow(float(k) / (Plume.POINTS - 1), Plume.CROWD)
			var drift := field.drift_at(t) - field.drift_at(t - age)
			var went := Vector2(plume.line[k].x, plume.line[k].z)
			off = maxf(off, rad_to_deg(absf(went.angle_to(drift))))
		check(off < 3.0, "what left the vent lies where the drift carried it (%.1f° off at most)" % off)
		shapes.append([_height_at(plume, DOWNWIND), Vector2(plume.line[Plume.POINTS - 1].x, plume.line[Plume.POINTS - 1].z).length()])
	print("at %.0f m downwind it stands %.0f m in a light wind and %.0f m in a strong one; it runs %.1f and %.1f km out"
		% [DOWNWIND, shapes[0][0], shapes[1][0], shapes[0][1] / 1000.0, shapes[1][1] / 1000.0])
	check(shapes[1][0] < shapes[0][0] * 0.75, "a strong wind bends it over low")
	check(shapes[1][1] > shapes[0][1] * 1.5, "and draws it out long")

	# 3 km off across the wind: a storm between hides it, clear air shows it.
	var wind := field.steady_wind_at(root.x, root.z, light).normalized()
	var eye := Vector2(root.x, root.z) + Vector2(-wind.y, wind.x) * 3000.0
	teleport(eye.x, eye.y)
	await settle(true)
	var mid := (eye + Vector2(root.x, root.z)) * 0.5
	var between := find_time(func(t: float) -> bool: return field.raw_storm_at(mid.x, mid.y, t) > 0.05
		and field.raw_storm_at(eye.x, eye.y, t) < -0.05)
	var open := find_time(func(t: float) -> bool: return clear.call(t) and field.raw_storm_at(mid.x, mid.y, t) < -0.06
		and field.raw_storm_at(eye.x, eye.y, t) < -0.06)
	await _at(between)
	var hidden := plume.seen[0].x
	await _at(open)
	var shown := plume.seen[0].x
	print("its mouth seen through a storm between %.2f, through clear air %.2f" % [hidden, shown])
	check(hidden < 0.05, "a storm between hides it")
	check(shown > 0.9, "clear air shows it")


## The clock at t, and every one of the plume's reads made there.
func _at(t: float) -> void:
	world.time = t
	world.weather.forecast_now()
	await physics_frames(3)
	await get_tree().process_frame


## How high it stands where it's this far downwind of its mouth, m.
func _height_at(plume: Plume, metres: float) -> float:
	for k in Plume.POINTS - 1:
		var a := Vector2(plume.line[k].x, plume.line[k].z).length()
		var b := Vector2(plume.line[k + 1].x, plume.line[k + 1].z).length()
		if metres >= a and metres <= b:
			return lerpf(plume.line[k].y, plume.line[k + 1].y, (metres - a) / maxf(b - a, 1e-3))
	return plume.line[Plume.POINTS - 1].y

