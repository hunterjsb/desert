extends ShieldProbe
## Scratch: the weather at spawn over the first days.

func run() -> void:
	await load_world(1234, false)
	var f := world.weather.field
	var x := world.player_world_x()
	var z := world.player_world_z()
	print("t0 %.1f storm %.3f wind %.1f" % [world.time, f.storm_at(x, z, world.time), f.wind_at(x, z, world.time).length()])
	var was := false
	var t := 0.0
	while t < 4800.0:
		var s := f.raw_storm_at(x, z, t) > 0.0
		if s != was:
			print("%s at %.0f s (day %.2f)" % ["storm" if s else "clear", t, t / 1200.0])
			was = s
		t += 5.0
	for k in 12:
		var tt := k * 100.0
		print("t %.0f storm %.2f steady %.1f wind %.1f" % [tt, f.storm_at(x, z, tt), f.steady_wind_at(x, z, tt).length(), f.wind_at(x, z, tt).length()])
