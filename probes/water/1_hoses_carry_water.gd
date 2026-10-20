extends FarmProbe
## Water probe 1: hoses carry water. A condenser held at 0 °C on a staked
## plate with a battery, nothing in its water socket but a hose, is hosed to
## two planters, the second hose on the first's end: what it makes goes down
## the hoses to the emptier tank first, and none of it is lost. Its battery
## taken off and a full canister fitted on the far planter's hose end, the
## canister tops up both tanks, the emptier first, until it's empty.

## An hour of world time at 0 °C makes this many litres.
const MAKES := 10.0
## The tanks to start, L: the near one empty, the far one half full.
const TANKS := [0.0, 2.0]


func run() -> void:
	await load_storm(0.0)
	var plate := Catalog.device(&"chassis") as Chassis
	world.content.add_child(plate)
	var at := ahead(2.0)
	plate.global_position = Vector3(at.x, world.height_under(at) + 0.07, at.z)
	plate.freeze = true
	var condenser := Catalog.device(&"condenser") as Condenser
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.0, 0.15), 0.0, condenser)
	condenser.frame_stats["toughness"] = INF
	plate.frame_stats["toughness"] = INF
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.3, -0.35), 0.0, Catalog.part(&"battery"))
	var planters: Array[Planter] = [planter_at(ahead(4.5), []), planter_at(ahead(-0.5), [])]
	for i in 2:
		planters[i].tank_l = TANKS[i]
		Scenarios.plumb(world, condenser, planters[i])
	hold_temperature(condenser.global_position, 0.0)
	await clock_at(time_of(0.0))
	# A tenth of the far tank's lead, so the near one is still the emptier.
	await pass_time(0.1 * (TANKS[1] - TANKS[0]) / MAKES * 3600.0)
	var tanks := planters.map(func(p: Planter) -> float: return p.tank_l)
	print("made %.6f L; tanks %s" % [condenser.made_l, tanks])
	check(condenser.made_l > 0.0 and absf(tanks[0] - TANKS[0] - condenser.made_l) < 1e-9 and tanks[1] == TANKS[1],
		"what it made went down the hoses, all of it to the emptier tank")
	plate.unstick(plate.batteries()[0].socket).free()
	var made := condenser.made_l
	var can := fit_part(planters[1], &"canister") as Supply
	await pass_time(1.0)
	var level: float = (tanks[0] + tanks[1] + can.capacity()) / 2.0
	tanks = planters.map(func(p: Planter) -> float: return p.tank_l)
	print("from a canister: tanks %s, %.3f L left in it" % [tanks, can.amount])
	check(can.socket.has_meta(&"socket") and can.amount == 0.0 and condenser.made_l == made
		and absf(tanks[0] - level) < 1e-9 and absf(tanks[1] - level) < 1e-9,
		"a canister at the far end filled the emptier tank first, then both, until it was empty")
