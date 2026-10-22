extends WeatherProbe
## Radio probe 38: round Tu, and skimming low. The lantern orbits Tu, not
## Zan: it's on the air only while it's on Zan's side of the planet, about
## half of each lap; heard from under Tu, never from Zan's far side, where Tu
## never rises; fainter than the rest; and never drawn in the sky. The
## deliveryship flies about thirty km up: from below it crosses the sky faster
## overhead than near the horizon; it's modelled (Deliveryship),
## not drawn on the sky, bigger overhead than low down, and shows even in
## Zan's shadow. By day only the nearest and brightest show: the low hull
## always, the dim ones never.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var tuning := Tuning.current()
	var sky := Radio.constellation_of(world)
	var lantern: Satellite = sky.orbits[&"lantern"]
	var under_tu := Sphere.point(0.0, deg_to_rad(tuning.tu_longitude_degrees))

	# Round Tu: on the air half of each lap, while it faces Zan.
	var facing := 0
	var samples := 0
	var agree := true
	var t := 0.0
	while t < lantern.period * 3.0:
		var on := sky.on_air(&"lantern", t)
		facing += int(on)
		samples += 1
		agree = agree and on == (lantern.facing(t) > 0.0)
		t += 2.0
	var share := float(facing) / samples
	print("the lantern faces Zan %.0f%% of three laps" % (100.0 * share))
	check(agree and absf(share - 0.5) < 0.05, "on the air only while on Zan's side of Tu, about half of each lap")
	var near := 99.0
	var far := -99.0
	t = 0.0
	while t < lantern.period:
		near = minf(near, rad_to_deg(lantern.seen_from(under_tu, t).elevation))
		far = maxf(far, rad_to_deg(lantern.seen_from(-under_tu, t).elevation))
		t += 5.0
	print("from under Tu it stands at least %.0f° up; from Zan's far side at most %.0f°" % [near, far])
	check(near > 70.0 and far < 0.0, "heard from under Tu, never from Zan's far side")
	check(sky.tumble(&"lantern", 0.0) < 1.0, "fainter than the rest, from so far")
	var index := Constellation.voiced().find(&"lantern")
	var material := world.weather.sky.material
	var never := true
	for k in 6:
		world.time += 200.0
		await physics_frames(2)
		never = never and (material.get_shader_parameter("sat_color") as PackedColorArray)[index].a == 0.0
	check(never, "and never drawn in the sky")

	# Flying low: crawling at the horizon, sweeping overhead.
	var survey: Satellite = sky.orbits[&"deliveryship"]
	print("the deliveryship flies %.0f to %.0f m up" % [survey.height(0.0) * survey.radius,
		survey.height(survey.period * 0.5) * survey.radius])
	check(absf(survey.height(0.0) * survey.radius - 30000.0) < 2000.0, "the deliveryship flies about thirty km up")
	var p := world.start
	var overhead := 0.0
	var low := 0.0
	t = -survey.period * 0.25
	while t < survey.period * 0.25:
		var e: float = survey.seen_from(p, t).elevation
		var rate := rad_to_deg(_sky_dir(survey, p, t).angle_to(_sky_dir(survey, p, t + 0.5))) / 0.5
		if e > deg_to_rad(75.0):
			overhead = maxf(overhead, rate)
		elif e > deg_to_rad(3.0) and e < deg_to_rad(10.0):
			low = maxf(low, rate)
		t += 0.25
	print("crossing the sky at %.2f°/s near the horizon, %.2f°/s overhead" % [low, overhead])
	check(low > 0.0 and overhead > low * 1.3, "it crosses the sky faster overhead than near the horizon")

	# Modelled, bigger overhead than low down, and shown sunlit or not.
	var at := Constellation.voiced().find(&"deliveryship")
	var craft := world.weather.sky.deliveryship
	var up_at := _first(func(u: float) -> bool: return survey.seen_from(p, u).elevation > deg_to_rad(80.0))
	world.time = up_at
	await physics_frames(3)
	var big := _across(craft)
	var shown := craft.visible
	var on_sky: float = (material.get_shader_parameter("sat_color") as PackedColorArray)[at].a
	var down_at := _first(func(u: float) -> bool:
		var e: float = survey.seen_from(p, u).elevation
		return e > deg_to_rad(5.0) and e < deg_to_rad(12.0), up_at)
	world.time = down_at
	await physics_frames(3)
	var small := _across(craft)
	print("%.2f° across overhead, %.2f° low down; shown %s overhead, sunlit %s" % [big, small, shown,
		survey.sunlit(up_at, world.weather.day.sun_toward(up_at))])
	check(big > small * 1.3 and big > 1.0, "bigger overhead than low down, and plain to see")
	check(shown and on_sky == 0.0, "shown as its model, sunlit or not, and not drawn on the sky")
	var shade := _first(func(u: float) -> bool:
		return survey.seen_from(p, u).elevation > deg_to_rad(30.0) and not survey.sunlit(u, world.weather.day.sun_toward(u)))
	world.time = shade
	await physics_frames(3)
	check(craft.visible, "even in Zan's shadow")

	# By day: only the nearest and brightest.
	var noon := _first(func(u: float) -> bool:
		return world.weather.day.is_day(u, world.moon.longitude) and survey.seen_from(p, u).elevation > deg_to_rad(20.0))
	world.time = noon
	await physics_frames(3)
	var forms := material.get_shader_parameter("sat_form") as PackedVector3Array
	var dim := Constellation.voiced().find(&"windsock")
	print("by day: the survey hull shows %s, the windsock %.2f" % [craft.visible, forms[dim].z])
	check(craft.visible and forms[dim].z == 0.0, "by day the low hull shows, a dim one doesn't")


## How many degrees across the deliveryship's model looks from the camera.
func _across(craft: Deliveryship) -> float:
	var eye := get_viewport().get_camera_3d().global_position
	var size := craft.global_basis.get_scale().x * DeliveryshipLooks.SPAN
	return rad_to_deg(2.0 * atan(size * 0.5 / eye.distance_to(craft.global_position)))


## Which way it is in the sky from point p at world time t.
func _sky_dir(orbit: Satellite, p: Vector3, t: float) -> Vector3:
	return (orbit.at(t) - p).normalized()


func _first(wanted: Callable, from := 0.0) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 1.0
	check(false, "found a moment")
	return from
