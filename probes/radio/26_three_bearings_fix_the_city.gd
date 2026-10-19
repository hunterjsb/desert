extends WeatherProbe
## Radio probe 26: three bearings fix the living city. A Console beside the
## Walker, a radio in its system on its carrier, notes each contact its log
## reads whole, once: two give no fix; once three cross, from far enough
## apart, they fix it within triangulate_m of where the city was, said in its
## log and marked on its chart among the bearings' lines.
## Time limit: 300 s.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var scenario := Scenarios.by_key("walker")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	world.time_warp = 0.0
	await settle(true)
	var dropped := await Scenarios.lay(world, scenario, place)
	var console: Console = dropped.filter(func(n: Node) -> bool: return n is Console)[0]
	var city := Radio.gods_of(world).city
	var every := world.tuning.walker_log_every
	var slot := ceilf(world.time / every) * every
	var fixed_at := -1
	for k in 2 * (world.tuning.walker_contacts_kept + 1):
		world.time = slot + k * every + 1.0
		await physics_frames(3)
		var fix := Chart.fix(console.bearings, world.tuning)
		if console.bearings.size() <= 2:
			check(fix.is_empty(), "%d bearings fix nothing" % console.bearings.size())
		elif fixed_at < 0 and not fix.is_empty():
			fixed_at = console.bearings.size()
			var latest: float = console.bearings[-1].t
			var off := Sphere.angle(fix.p, city.at(latest)) * world.shape.history.radius
			print("%d bearings fix it %.0f m from the city, their crossings %.0f m apart" % [fixed_at, off, fix.spread])
			check(off < world.tuning.triangulate_m, "the fix is where the city was (%.0f m off)" % off)
	check(fixed_at >= 3, "three crossing bearings fix it")
	check(console.bearings.size() == world.tuning.walker_contacts_kept, "each contact noted once (%d)" % console.bearings.size())
	var log := console.screen_text(Console.Page.LOG)
	check("CONTACT" in log and "FIX" in log, "its log notes each contact and the fix")
	var chart: Dictionary = console._model(Console.Page.CHART, console.pooled_readings()).chart
	check(chart.lines.size() == console.bearings.size() and chart.has("fix"), "its chart draws each bearing and the fix")
	print(console.screen_text(Console.Page.CHART))
