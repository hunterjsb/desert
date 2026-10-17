extends FarmProbe
## Farming probe 5: no water, no growth. A carrot growing at its full rate on
## a clear noon, held at 20 °C, from a planter with two centilitres left:
## it grows until the tank runs dry, drinking what it should, and then stops
## where the water ran out. A canister with two centilitres in it, fitted by
## hand to the planter's water socket, waters it again until both run dry; a
## full one keeps the tank full, losing just what the carrot drinks.

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
	can.drain(can.amount - LEFT)
	world.content.add_child(can)
	hands.hold(can)
	await physics_frames(30)
	var socket: Socket = planter.sockets().filter(func(s: Socket) -> bool: return s.kind == &"water")[0]
	aim(socket.global_position + Vector3(0.0, 0.5, 0.9), socket.global_position)
	await physics_frames(5)
	check(hands.socket == socket and hands.grab() and socket.part == can, "take fits the canister to the water socket")
	await pass_time(SPAN)
	var again := carrot.growth - dry
	print("watered again: %.6f grown, %.6f expected, tank %.6f L, canister %.6f L, %s"
		% [again, water_lasts, planter.tank_l, can.amount, carrot.state])
	check(absf(again - water_lasts) < 1e-9 and can.amount == 0.0 and planter.tank_l == 0.0 and carrot.state == Plant.DRY,
		"it grew as far as the canister's water took it, and both ran dry")

	can.fill(INF)
	planter.tank_l = world.tuning.planter_tank_litres
	var before := carrot.growth
	await pass_time(SPAN)
	var drunk := (carrot.growth - before) * carrot.litres
	print("kept full: drank %.6f L, the canister lost %.6f L, the tank holds %.6f L"
		% [drunk, can.capacity() - can.amount, planter.tank_l])
	check(drunk > 0.0 and planter.tank_l == world.tuning.planter_tank_litres
		and absf(can.capacity() - can.amount - drunk) < 1e-9, "a full canister keeps the tank full, losing what the carrot drinks")
