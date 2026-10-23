extends ShieldProbe
## Radio probe 66: the solar lid. In the radio's misc bay its cells trickle a
## charge into the set's battery by day, switched off or on (gonkhub,
## 2026-10-22: "always charge during the day, even when on"); by night, on
## Tu's light alone as any solar panel does, far less, and the set playing
## draws on its battery again.


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"solar_lid"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = false
	var day := world.weather.day
	while not day.is_day(world.time, world.moon.longitude) \
			or day.sunlight(world.time, world.moon.latitude, world.moon.longitude) < 0.6:
		world.time += 60.0
	var battery := radio.battery() as Battery
	battery.charge_wh = 10.0
	await physics_frames(2)
	world.time_warp = 60.0
	await physics_frames(600)
	world.time_warp = 1.0
	print("by day, in ten minutes warped: %.2f Wh from 10.00" % battery.charge_wh)
	var by_day := battery.charge_wh - 10.0
	check(by_day > 0.05, "by day its battery fills")
	# Out of any eclipse by Tu, in full light again.
	var top := radio.global_position + Vector3.UP * 0.5
	while world.weather.felt_light(top, world.time) < 0.6:
		world.time += 60.0
	radio.on = true
	var playing := battery.charge_wh
	world.time_warp = 60.0
	await physics_frames(600)
	world.time_warp = 1.0
	print("by day, playing: %.2f Wh from %.2f" % [battery.charge_wh, playing])
	check(battery.charge_wh > playing + 0.05, "by day it fills even while the set plays")
	radio.on = false
	while day.is_day(world.time, world.moon.longitude) or day.sunlight(world.time, world.moon.latitude, world.moon.longitude) > 0.0:
		world.time += 120.0
	var night := battery.charge_wh
	world.time_warp = 60.0
	await physics_frames(600)
	world.time_warp = 1.0
	print("by night, the same: %.3f Wh from %.3f" % [battery.charge_wh, night])
	check(battery.charge_wh - night < by_day * 0.5, "by night, far less")
