extends DeviceProbe
## Power probe 10: a turbine's rotor turns with the power it makes, as drawn.
## Faster in a gale than in a light wind, and still while it makes nothing:
## dragged over the sand, or wrecked.


func run() -> void:
	await load_world(1234, false)
	var turbine := spawn_device(&"turbine", -3.0, 0.2, false)
	await physics_frames(60)
	# Staked, as a planted turbine will be.
	turbine.freeze = true
	turbine.linear_velocity = Vector3.ZERO
	var at := Vector2(world.world_x(turbine.global_position.x), world.world_z(turbine.global_position.z))
	var light := NAN
	var gale := NAN
	var t := 0.0
	while t < 2.0 * 24.0 * 3600.0 and (is_nan(light) or is_nan(gale)):
		var wind := world.weather.field.wind_at(at.x, at.y, t).length()
		if is_nan(light) and wind > 4.0 and wind < 8.0:
			light = t
		if is_nan(gale) and wind > 25.0:
			gale = t
		t += 10.0
	var seen := {}
	world.time = light
	seen["light"] = await _turns(turbine)
	world.time = gale
	seen["gale"] = await _turns(turbine)
	var drag := func() -> void: turbine.linear_velocity = Vector3(1.0, turbine.linear_velocity.y, 0.0)
	turbine.freeze = false
	get_tree().physics_frame.connect(drag)
	seen["dragged"] = await _turns(turbine)
	get_tree().physics_frame.disconnect(drag)
	turbine.freeze = true
	turbine.linear_velocity = Vector3.ZERO
	seen["planted again"] = await _turns(turbine)
	turbine.wear(INF)
	seen["wrecked"] = await _turns(turbine)
	print("turns a second: %s" % seen)
	check(seen["light"] > 0.0 and seen["gale"] > seen["light"] * 1.5, "it turns in a light wind, faster in a gale")
	check(seen["dragged"] == 0.0, "it's still while it's dragged")
	check(seen["planted again"] > 0.0 and seen["wrecked"] == 0.0, "it turns again planted, and stops for good wrecked")


## Turns a second its rotor makes, as drawn, once it has had time to come up
## to speed or run down.
func _turns(turbine: Device) -> float:
	await fast_forward(10.0)
	var rotor := turbine.rotor
	var turned := 0.0
	var spent := 0.0
	var was := rotor.basis.x
	while spent < 1.0:
		await get_tree().process_frame
		spent += get_process_delta_time()
		turned += absf(was.signed_angle_to(rotor.basis.x, rotor.basis.z))
		was = rotor.basis.x
	return turned / TAU / spent
