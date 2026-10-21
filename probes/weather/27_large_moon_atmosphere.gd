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
	var craft := sky.crop_survey
	craft._veil(env, Vector3.RIGHT, 10000.0)
	var ground := float(craft._overlay.get_shader_parameter(&"veil"))
	var old := tuning.moon_circumference
	tuning.moon_circumference *= 0.5
	craft._veil(env, Vector3.RIGHT, 10000.0)
	check(is_equal_approx(ground, float(craft._overlay.get_shader_parameter(&"veil"))), "compressed navigation circumference cannot change craft atmosphere")
	tuning.moon_circumference = old
	craft._veil(env, Vector3.RIGHT, 10000.0, 2000.0)
	check(float(craft._overlay.get_shader_parameter(&"veil")) < ground, "above the dust, observer altitude reduces craft extinction")
