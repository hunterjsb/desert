extends WeatherProbe
## A high observer's sky and storm pass share the visual moon, independent of navigation.

func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var eye := world.player.camera
	world.player.global_position = Vector3(73.0, 2000.0, -91.0)
	for i in 3:
		await get_tree().physics_frame
	var sky := world.weather.sky
	var dip := float(sky.material.get_shader_parameter(&"horizon_dip"))
	print("high eye ", eye.global_position, "; dip ", rad_to_deg(dip))
	check(dip > 0.032 and dip < 0.034, "two-kilometre observer sees a roughly1.88degree visual horizon dip")
	var frame: Vector3 = world.weather.face.material.get_shader_parameter(&"surface_frame")
	check(frame.is_equal_approx(Vector3(eye.global_position.x, eye.global_position.z, 3700000.0)), "storm inverse projection is anchored to actual observer and visual radius")
	var tuning := world.tuning
	var env := eye.get_world_3d().environment
	var craft := sky.deliveryship
	craft._veil(env, Vector3.RIGHT, 10000.0)
	var ground := float(craft._overlay.get_shader_parameter(&"veil"))
	var old := tuning.moon_circumference
	tuning.moon_circumference *= 0.5
	craft._veil(env, Vector3.RIGHT, 10000.0)
	check(is_equal_approx(ground, float(craft._overlay.get_shader_parameter(&"veil"))), "compressed navigation circumference cannot change craft atmosphere")
	tuning.moon_circumference = old
	craft._veil(env, Vector3.RIGHT, 10000.0, 2000.0)
	check(float(craft._overlay.get_shader_parameter(&"veil")) < ground, "above the dust, observer altitude reduces craft extinction")

	var controlled := Environment.new()
	controlled.fog_enabled = true
	controlled.fog_density = 1.0 - exp(-1.0)
	controlled.fog_depth_end = 1000.0
	var previous_dust := tuning.dust_height_m
	tuning.dust_height_m = 1500.0
	craft._veil(controlled, Vector3.DOWN, 4000.0, 10000.0)
	var down := float(craft._overlay.get_shader_parameter(&"veil"))
	# Integral from6km to10km of exp(-h/1500), with extinction1/1000m.
	var expected := 1.0 - exp(-1.5 * (exp(-4.0) - exp(-20.0 / 3.0)))
	craft._veil(controlled, Vector3.UP, 4000.0, 6000.0)
	var up := float(craft._overlay.get_shader_parameter(&"veil"))
	check(absf(down - expected) < 0.00001 and absf(up - expected) < 0.00001,
		"downward and reversed vertical Drone paths match actual exponential atmosphere")
	craft._veil(controlled, Vector3.RIGHT, 4000.0, 10000.0)
	check(down > 4.9 * float(craft._overlay.get_shader_parameter(&"veil")),
		"descending through denser air has more dust than staying at the high observer")
	tuning.dust_height_m = previous_dust

	craft.place(Vector3(0.0, 10000.0, 0.0), Vector3.DOWN, 4000.0, Vector3.FORWARD, Vector3.UP)
	check(craft.visible, "a finite Drone at6km is visible below a10km observer")
	check(is_equal_approx(float(craft._paint.get_shader_parameter(&"sky_proxy_distance_scale")), 4000.0 / Vector3(0.0, 10000.0, 0.0).distance_to(craft.global_position)),
		"paint receives actual finite target distance")
	craft.place(Vector3(0.0, 10.0, 0.0), Vector3.DOWN, 100.0, Vector3.FORWARD, Vector3.UP)
	check(not craft.visible, "a target below the presentation surface stays hidden")
	var tangent := Vector3(1.0, -0.01, 0.0).normalized()
	check(not craft._clear_segment(10.0, tangent, 100000.0), "planet crossing hides a target even when its far endpoint rises above ground")

	var orbit: Satellite = Radio.constellation_of(world).orbits[&"thermal"]
	var orbit_at := orbit.at(world.time)
	var below := orbit_at.normalized()
	world.moon.place(rad_to_deg(Sphere.latitude(below)), rad_to_deg(Sphere.longitude(below)))
	world.player.global_position.y = 10000.0
	sky._show_satellites(world.time)
	check(craft.visible and (craft.global_position - eye.global_position).normalized().y < -0.99,
		"actual ephemeris viewed from above places the finite Drone below the observer")
	check(orbit.at(world.time).is_equal_approx(orbit_at), "observer parallax never modifies the orbit")
