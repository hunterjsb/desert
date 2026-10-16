extends FarmProbe
## Farming probe 1: growth follows conditions. A carrot and a fungus in one
## planter, the felt temperature held by a test-only shelter, at a time of day
## and in a storm picked for their light. Over 25 seconds each grows at its
## full rate where light and temperature suit it, at part of it in part
## light, not at all where it's too dark, too bright, too hot or too cold, and
## past its hardy limits it wilts back at the wilting rate. Ripe, it stops and
## holds through weather that would wilt it, until it's picked: taken by hand,
## its harvest comes out as food and its slot is free.

const SPAN := 25.0
## [what, storm, time of day, °C, the carrot's rate, the fungus's], as shares
## of its full rate; "part" is between none and full, "wilt" the wilting rate.
const CASES := [
	["clear noon, mild", 0.0, 0.5, 20.0, 1.0, 0.0],
	["full storm at noon, mild", 1.0, 0.5, 20.0, 0.0, 1.0],
	["clear midnight, mild", 0.0, 0.0, 20.0, 0.0, 1.0],
	["light storm at noon", 0.6, 0.5, 20.0, "part", 0.0],
	["heavy storm at noon", 0.85, 0.5, 20.0, "part", "part"],
	["clear noon, 65 °C", 0.0, 0.5, 65.0, 0.0, "wilt"],
	["clear noon, 75 °C", 0.0, 0.5, 75.0, "wilt", "wilt"],
	["full storm at noon, 50 °C", 1.0, 0.5, 50.0, 0.0, 0.0],
	["clear midnight, -10 °C", 0.0, 0.0, -10.0, 0.0, 0.0],
	["clear midnight, -20 °C", 0.0, 0.0, -20.0, 0.0, "wilt"],
	["clear midnight, -35 °C", 0.0, 0.0, -35.0, "wilt", "wilt"],
]


func run() -> void:
	await load_storm(0.0)
	world.moon.latitude = 0.0
	var planter := planter_at(ahead(3.0), [&"carrot", &"fungus"])
	hold_temperature(planter.global_position, 20.0)
	var plants := planter.plants()
	var wilt := Tuning.current().wilt_rate
	for case: Array in CASES:
		weather_everywhere(case[1])
		Tuning.current().sheltered_temperature = case[3]
		await clock_at(time_of(case[2]) - SPAN * 0.5)
		for plant in plants:
			plant.set_growth(0.5)
		await pass_time(SPAN)
		var line := PackedStringArray()
		for i in plants.size():
			var plant := plants[i]
			var rate := (plant.growth - 0.5) / (SPAN / plant.ripen_seconds)
			var want: Variant = case[4 + i]
			var ok: bool = rate > 0.0 and rate < 1.0 if want is String and want == "part" \
				else absf(rate - (-wilt if want is String else float(want))) < 1e-9
			check(ok, "%s: the %s grows at %s of its full rate (%.6f, %s)" % [case[0], plant.label, want, rate, plant.state])
			line.append("%s %.3f %s" % [plant.label, rate, plant.state])
		print("%s: %s" % [case[0], ", ".join(line)])

	# Nearly ripe in the clear noon, then a heat that would wilt it.
	weather_everywhere(0.0)
	Tuning.current().sheltered_temperature = 20.0
	await clock_at(time_of(0.5) - SPAN * 0.5)
	var carrot := plants[0]
	carrot.set_growth(0.98)
	await pass_time(SPAN)
	check(carrot.ripe() and carrot.growth == 1.0 and carrot.state == Plant.RIPE, "ripe, the carrot stops at ripe")
	Tuning.current().sheltered_temperature = 75.0
	await pass_time(SPAN)
	check(carrot.growth == 1.0, "ripe, it holds through heat that wilts the growing")

	var socket := carrot.socket
	var harvest := carrot.harvest * carrot.kcal
	var units := carrot.harvest
	var at := middle_of(socket)
	aim(at + Vector3(0.0, 0.9, 0.5), at)
	await physics_frames(2)
	var hands := world.player.hands
	check(hands.grab(), "you take the ripe carrot")
	await physics_frames(40)
	var food := hands.held as Supply
	print("picked by hand: %s" % (Hands.describe(food.label, food.mass, food.stats) if food != null else "nothing"))
	check(food != null and food.kind == &"food" and food.amount == harvest and hands.phase == Hands.Phase.HELD,
		"its harvest comes to your hands as food, %d kcal" % harvest)
	check(socket.part == null and planter.picked.get(&"carrot", 0) == units, "and its slot is free")
