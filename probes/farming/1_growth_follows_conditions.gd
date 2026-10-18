extends FarmProbe
## Farming probe 1: growth follows conditions. A root-tuber and a vat fungus
## in one planter, the felt temperature held by a test-only shelter, at a time
## of day and in a storm picked for their light. Over 25 seconds each grows at
## its full rate where light and temperature suit it, at part of it in part
## light, not at all where it's too dark, too bright, too hot or too cold, and
## past its hardy limits it wilts back at the wilting rate. Ripe, it stops and
## holds through weather that would wilt it, until it's picked: taken by hand,
## its harvest comes out as food and the farm goes on. A root-tuber's seed
## goes in with what you carry, and the fungus stays in its slot and grows
## again.

const SPAN := 25.0
## [what, storm, time of day, °C, the root-tuber's rate, the fungus's], as shares
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
	var planter := planter_at(ahead(3.0), [&"root_tuber", &"vat_fungus"])
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
	var tuber := plants[0]
	tuber.set_growth(0.98)
	await pass_time(SPAN)
	check(tuber.ripe() and tuber.growth == 1.0 and tuber.state == Plant.RIPE, "ripe, the root-tuber stops at ripe")
	Tuning.current().sheltered_temperature = 75.0
	await pass_time(SPAN)
	check(tuber.growth == 1.0, "ripe, it holds through heat that wilts the growing")

	var socket := tuber.socket
	var harvest := tuber.harvest * tuber.kcal
	var units := tuber.harvest
	var at := middle_of(socket)
	aim(at + Vector3(0.0, 0.9, 0.5), at)
	await physics_frames(2)
	var hands := world.player.hands
	check(hands.grab(), "you take the ripe root-tuber")
	await physics_frames(40)
	var food := hands.held as Supply
	print("picked by hand: %s" % (Hands.describe(food.label, food.mass, food.stats) if food != null else "nothing"))
	check(food != null and food.kind == &"food" and food.amount == harvest and hands.phase == Hands.Phase.HELD,
		"its harvest comes to your hands as food, %d kcal" % harvest)
	var seeds := world.player.suit.carried.filter(func(p: RigidBody3D) -> bool: return p is Plant)
	check(socket.part == null and planter.picked.get(&"root_tuber", 0) == units and seeds.size() == 1
		and seeds[0].crop == &"root_tuber" and seeds[0].growth == 0.0, "its slot is free and its seed is carried")

	hands.stow().free()
	var fungus := plants[1]
	fungus.set_growth(1.0)
	fungus.fruit = 1.0
	at = middle_of(fungus.socket)
	aim(at + Vector3(0.0, 0.9, 0.5), at)
	await physics_frames(2)
	check(hands.grab(), "you take the ripe fungus")
	await physics_frames(40)
	var caps := hands.held as Supply
	print("picked by hand: %s" % (Hands.describe(caps.label, caps.mass, caps.stats) if caps != null else "nothing"))
	check(caps != null and caps.amount == fungus.harvest * fungus.kcal and hands.phase == Hands.Phase.HELD,
		"its caps come to your hands, %d kcal" % (fungus.harvest * fungus.kcal))
	check(fungus.socket != null and fungus.growth == 0.0 and planter.picked.get(&"vat_fungus", 0) == fungus.harvest,
		"and what's left of it stays in its slot")
	weather_everywhere(1.0)
	Tuning.current().sheltered_temperature = 20.0
	await pass_time(SPAN)
	print("picked fungus after %d s in the dark: %.3f %s" % [SPAN, fungus.growth, fungus.state])
	check(is_equal_approx(fungus.growth, SPAN / fungus.ripen_seconds), "it grows again, at its full rate in the dark")
