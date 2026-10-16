extends FarmProbe
## Farming probe 5: no water, no growth. A carrot growing at its full rate on
## a clear noon, held at 20 °C, from a planter with two centilitres left:
## it grows until the tank runs dry, drinking what it should, and then stops
## where the water ran out. A canister poured in by hand, by use with it
## aimed at the planter, fills the tank by what the canister lost, and the
## carrot grows again.

const LEFT := 0.02
const SPAN := 20.0


func run() -> void:
	await load_storm(0.0)
	world.moon.latitude = 0.0
	var planter := planter_at(ahead(2.0), [&"carrot"])
	var carrot: Plant = planter.plants()[0]
	hold_temperature(planter.global_position, 20.0)
	await clock_at(time_of(0.5) - SPAN)
	planter.tank_l = LEFT
	await pass_time(SPAN)
	var dry := carrot.growth
	var water_lasts := LEFT / carrot.litres
	print("dry at %.6f grown, %.6f expected, tank %.6f L, %s" % [dry, water_lasts, planter.tank_l, carrot.state])
	check(dry < SPAN / carrot.ripen_seconds, "it ran dry before the time was up")
	check(absf(dry - water_lasts) < 1e-9 and planter.tank_l == 0.0 and carrot.state == Plant.DRY,
		"it grew as far as the water took it (%.6f of %.6f) and stopped, dry" % [dry, water_lasts])
	await pass_time(SPAN)
	check(carrot.growth == dry, "dry, it grows no further")

	var hands := world.player.hands
	var can := Catalog.part(&"canister") as Supply
	world.content.add_child(can)
	hands.hold(can)
	await physics_frames(30)
	var at := planter.global_position + Vector3(0.0, 0.05, 0.0)
	aim(at + Vector3(0.0, 0.8, 1.2), at)
	await physics_frames(2)
	var full := can.amount
	check(hands.interact(), "use, aimed at the planter with a canister in hand, pours it in")
	print("poured %.3f L, the tank holds %.3f L" % [full - can.amount, planter.tank_l])
	check(planter.tank_l == minf(full, world.tuning.planter_tank_litres) and can.amount == full - planter.tank_l,
		"the tank gained what the canister lost (%.3f L)" % planter.tank_l)
	await pass_time(SPAN)
	check(carrot.growth > dry and carrot.state == Plant.GROWING, "watered, it grows again")
