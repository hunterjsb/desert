extends ShieldProbe
## Survival probe 18: a line gives at the storm's peak. Asleep under a shield
## in the run's own weather on the probes' seed, a storm coming on in the
## night, two planters rest on the sand past its bubble, each on a line to a
## stake upwind. One line is made to hold more than the storm's peak will
## put on it and the other less, by the load the night is reckoned with:
## the first holds its planter where it was, the second gives and its
## planter is gone where the wind took it, and waking says so.
## Time limit: 300 s

## The planters stand this far out past you, and apart; their stakes this far upwind, m.
const OUT := 16.0
const APART := 6.0
const UPWIND := 3.0
## The spawn's first storm has passed by then, and the next comes on within the night.
const CLEAR := 100.0
const HOURS := 24


func run() -> void:
	await load_world(1234, false)
	world.time = CLEAR
	world.weather.forecast_now()
	var here := world.player.global_position
	var shield := _on_a_plate(here + Vector3(-1.0, 0.0, 0.0))
	shield.stand(true)
	var down := world.weather.field.prevailing_at(world.time).normalized()
	var downwind := Vector3(down.x, 0.0, down.y)
	var across := downwind.cross(Vector3.UP)
	var planters: Array[Device] = []
	var lines: Array[Rope] = []
	for side: float in [-1.0, 1.0]:
		var at := here + downwind * OUT + across * side * APART * 0.5
		var planter := Catalog.device(&"planter")
		world.content.add_child(planter)
		planter.global_position = Vector3(at.x, world.height_under(at) + 0.19, at.z)
		fit_part(planter, &"hook")
		var spot := at - downwind * UPWIND
		var stake := Catalog.stake()
		world.content.add_child(stake)
		stake.drive(spot, world.height_under(spot))
		lines.append(Line.between(world, planter.free_tie(spot), stake.free_tie(at), 0.3).rope)
		planters.append(planter)
	await live(5.0, 1.0)
	check(world.sleep.refusal() == "", "you can sleep (%s)" % world.sleep.refusal())

	# The storm's peak on each line, as the night will reckon it.
	var from := world.time
	var until := world.sleep.wake_for(Sleep.HOURS, HOURS)
	var tick := world.tuning.sleep_tick
	var peaks: Array[float] = []
	for rope in lines:
		var was := world.ropes.bearing(rope)
		var peak := 0.0
		var t := from
		while t < until:
			peak = maxf(peak, world.ropes.load_at(rope, t, tick, was))
			t += tick
		peaks.append(peak)
	print("a storm in %.0f s; the lines bear %.0f N and %.0f N, at its peak %.0f N and %.0f N" % [
		world.weather.next_change_time - from, lines[0].sustained, lines[1].sustained, peaks[0], peaks[1]])
	check(not world.weather.in_storm and world.weather.next_change_time < until
		and peaks.min() > 4.0 * maxf(lines[0].sustained, lines[1].sustained) + 50.0,
		"a storm comes in the night and loads the lines far past what they bear now")
	lines[0].breaking = peaks[0] * 1.25
	lines[1].breaking = peaks[1] * 0.75
	var where := planters.map(func(c: Device) -> Vector3: return c.global_position)

	var night := world.sleep.overnight(until)
	var said := world.sleep.summary(night)
	print("woke: %s" % " / ".join(said))
	check(lines[0] in world.ropes.ropes and planters[0].global_position.distance_to(where[0]) < 0.5,
		"the stronger line holds its planter where it was")
	var gone := not is_instance_valid(planters[1]) or planters[1].is_queued_for_deletion() \
		or planters[1].global_position.distance_to(where[1]) > Sleep.MOVED
	check(not lines[1] in world.ropes.ropes and gone, "the weaker gives, and its planter is gone where the wind took it")
	check(said.has("Planter broke loose") or said.has("Planter blew away"), "waking says so (%s)" % " / ".join(said))


## A base shield on a plate on the sand: a chassis with a big battery stuck beside it.
func _on_a_plate(at: Vector3) -> ShieldGenerator:
	var plate := Catalog.device(&"chassis") as Chassis
	world.content.add_child(plate)
	plate.global_position = Vector3(at.x, world.height_under(at) + Chassis.THICK * 0.5 + 0.01, at.z)
	var shield := Catalog.device(&"shield") as ShieldGenerator
	Stick.put(plate, plate, Chassis.TOP, Vector2.ZERO, 0.0, shield)
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.32, 0.3), 0.0, Catalog.part(&"big_battery"))
	return shield
