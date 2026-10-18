extends FarmProbe
## Farming probe 10: saltbush folds before a storm. A saltbush on the probes'
## seed in the run's own weather, at a storm whose wall reaches it with clear
## air a good while either side. Three minutes ahead its leaves are open; by
## a minute ahead they're shut, folded with the storm's lead and well before
## the wall; they stay shut through the storm, and open again once it's
## gone.
## Time limit: 400 s

## How long clear air must hold before the storm and after it, s, and how
## far ahead to look for one.
const CLEAR := 300.0
const HORIZON := 6.0 * 3600.0
const STEP := 2.0


func run() -> void:
	await load_world(1234, false)
	world.player.set_physics_process(false)
	world.player.vitals.set_physics_process(false)
	var planter := planter_at(ahead(3.0), [&"saltbush"])
	var bush: Plant = planter.plants()[0]
	var lead: float = bush.data.stages.folds * 60.0
	var field := world.weather.field
	var at := planter.global_position + Planter.CROWN
	var x := world.world_x(at.x)
	var z := world.world_z(at.z)
	# The first storm with clear air either side.
	var t := 0.0
	var arrives := INF
	var ends := INF
	while t < 3.0 * HORIZON:
		var change := field.next_change(x, z, t, HORIZON, Weather.FORECAST_STEP)
		if change == INF:
			t += HORIZON
		elif field.raw_storm_at(x, z, t) > 0.0:
			t += change
		else:
			var length := field.next_change(x, z, t + change, HORIZON, Weather.FORECAST_STEP)
			if change > CLEAR and length != INF \
					and field.next_change(x, z, t + change + length, CLEAR, Weather.FORECAST_STEP) == INF:
				arrives = t + change
				ends = arrives + length
				break
			t += change + minf(length, HORIZON)
	check(arrives < INF, "a storm with clear air either side, at %.0f s, %.0f s long" % [arrives, ends - arrives])
	if arrives == INF:
		return
	var seen := {}
	var watch := func(marks: Dictionary) -> void:
		for mark: String in marks:
			if not seen.has(mark) and world.time >= marks[mark] - 1e-6:
				seen[mark] = bush.fold
	var coming := {"three minutes ahead": arrives - lead - 60.0, "a minute ahead": arrives - 60.0, "the wall": arrives,
		"in the storm": arrives + 60.0}
	await clock_at(arrives - lead - 60.0)
	await pass_time(lead + 121.0, watch.bind(coming), STEP)
	# Its middle passes unwatched.
	var going := {"as it clears": ends - STEP, "a minute after": ends + 60.0}
	await clock_at(ends - 60.0)
	await pass_time(121.0, watch.bind(going), STEP)
	print("lead %.0f s, the storm %.0f s long: %s" % [lead, ends - arrives, seen])
	check(seen.get("three minutes ahead", -1.0) == 0.0, "three minutes ahead, its leaves are open")
	check(seen.get("a minute ahead", -1.0) == 1.0 and seen.get("the wall", -1.0) == 1.0,
		"a minute ahead of the wall they're folded shut")
	check(seen.get("in the storm", -1.0) == 1.0 and seen.get("as it clears", -1.0) == 1.0, "and stay shut in the storm")
	check(seen.get("a minute after", -1.0) == 0.0, "a minute after it's gone, they're open again")
