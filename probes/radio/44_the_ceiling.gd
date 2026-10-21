extends ShieldProbe
## Radio probe 44: the ceiling. What's in orbit sends down above the few MHz
## the air turns back, so with satellites overhead the AM dial hears none of
## them anywhere along it; with a shortwave converter, tuned to one overhead,
## it's there.


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	await physics_frames(2)
	var sky := Radio.constellation_of(world)
	var p := radio.point_at(world.world_x(radio.global_position.x), world.world_z(radio.global_position.z))
	var overhead := sky.carriers(p, world.time)
	check(overhead.size() >= 2, "satellites are overhead (%d)" % overhead.size())
	var loudest := 0.0
	var khz := Dial.LOWEST
	while khz <= Dial.HIGHEST:
		radio.frequency = khz
		await physics_frames(1)
		for level: float in radio.sky.levels.values():
			loudest = maxf(loudest, level)
		khz += 40.0
	check(loudest == 0.0, "along the whole AM dial not one is heard")
	radio.switch_band()
	radio.frequency = overhead[0][0]
	await physics_frames(3)
	var id: StringName = overhead[0][1]
	print("on shortwave at %.0f kHz: the %s at %.2f" % [radio.frequency, id, radio.sky.levels.get(id, 0.0)])
	check(radio.band == Radio.SW_BAND and radio.sky.levels.get(id, 0.0) > 0.5,
		"on shortwave, tuned to one overhead, it's there")
