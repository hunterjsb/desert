extends DeviceProbe
## Water probe 2: pulled too hard, a hose pops. In a 20 m/s wind a floating
## planter on a hose to a staked condenser pops an end out of a water socket
## and blows away, the hose dragged after it. Tied to the condenser by a rope
## as well, the same pull is the rope's: it holds the planter, and the hose
## stays in.

const WIND := 20.0


func run() -> void:
	await load_world(1234, false)
	var tuning := Tuning.current()
	tuning.prevailing_speed = WIND
	tuning.storm_outflow_speed = 0.0
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	var wind := world.weather.field.prevailing_at(world.time)
	var downwind := Vector3(wind.x, 0.0, wind.y).normalized()
	world.time_warp = 0.0
	var hosed := _rig(false, Vector3(downwind.z, 0, -downwind.x) * 6.0, downwind)
	var roped := _rig(true, Vector3(-downwind.z, 0, downwind.x) * 6.0, downwind)
	await physics_frames(20 * 60)
	var gone: float = hosed.condenser.global_position.distance_to(hosed.planter.global_position)
	var held: float = roped.condenser.global_position.distance_to(roped.planter.global_position)
	print("hose alone: %.1f m off, joined %s; with a rope: %.2f m off, joined %s, rope %s"
		% [gone, hosed.hose.joined().size() == 2, held, roped.hose.joined().size() == 2, roped.line.rope != null])
	check(hosed.hose.joined().is_empty() and gone > 15.0, "the hose alone popped an end, and its planter blew away")
	var with_it := func(p: Part) -> bool:
		return p.global_position.distance_to(hosed.planter.global_position) < hosed.hose.length + 1.0
	check(hosed.hose.plugs.all(with_it), "the hose went with it, dragged after it")
	check(roped.line.rope != null and held < roped.line.full + 1.5 and roped.hose.joined().size() == 2,
		"the rope held the same pull, and the hose stayed in")


## A staked condenser and a floating planter 3 m downwind of it, hosed water
## socket to water socket, and tied hook to hook as well if `tied`.
func _rig(tied: bool, offset: Vector3, downwind: Vector3) -> Dictionary:
	var condenser := spawn_device(&"condenser", 0.0, 0.35, false)
	condenser.global_position += offset
	condenser.freeze = true
	var planter := spawn_device(&"planter", 0.0, 1.2, false)
	planter.global_position = condenser.global_position + downwind * 3.0 + Vector3.UP * 1.2
	fit_part(planter, &"hover_tray")
	fit_part(planter, &"battery")
	var out := {"condenser": condenser, "planter": planter, "hose": Scenarios.plumb(world, condenser, planter)}
	if tied:
		fit_part(condenser, &"hook")
		fit_part(planter, &"hook")
		var a := planter.free_tie(condenser.global_position)
		out.line = Line.between(world, a, condenser.free_tie(a.global_position), 0.3)
	return out
