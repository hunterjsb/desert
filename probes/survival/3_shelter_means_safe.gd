extends ShieldProbe
## Survival probe 3: shelter means safe. In the worst storm with a gale
## behind it, ten minutes inside a base shield take nothing from you by wind
## or storm, while two minutes outside take both. The base shield doesn't hold
## back temperature, so far from the equator on a clear afternoon the heat
## reaches you inside it; inside a test-only shield that holds temperature
## back too, it doesn't, and nothing touches you at all.

const WIND := 35.0
const LATITUDE := 60.0
## Everything held back: a test-only thermal shield.
const ALL := {&"wind": 1.0, &"storm": 1.0, &"temperature": 1.0}


func run() -> void:
	await load_storm(1.0, WIND)
	var vitals := world.player.vitals
	var shield := shield_at(world.player.global_position)
	# Switched off, the gale would carry it off.
	shield.freeze = true
	await physics_frames(5)
	vitals.fresh()
	await live(600.0, 30.0)
	var inside: Dictionary = vitals.taken.duplicate()
	shield.stand(false)
	await physics_frames(5)
	vitals.fresh()
	await live(120.0, 30.0)
	var outside: Dictionary = vitals.taken.duplicate()
	print("inside %s, outside %s" % [inside, outside])
	check(inside[&"wind"] == 0.0 and inside[&"storm"] == 0.0, "inside the base shield, no wind or storm harm (%s)" % inside)
	check(outside[&"wind"] > 0.0 and outside[&"storm"] > 0.0, "outside, the wind and the storm harm you (%s)" % outside)

	# A clear afternoon near the pole, as the heat peaks.
	weather_everywhere(0.0)
	world.moon.latitude = deg_to_rad(LATITUDE)
	var tuning := Tuning.current()
	var peak := (tuning.temperature_peak - tuning.start_time_of_day) * tuning.day_minutes * 60.0
	var hot := {}
	for blocks: Dictionary in [shield.shelter.blocks.duplicate(), ALL]:
		shield.shelter.blocks = blocks
		shield.stand(true)
		world.time = peak - 60.0
		await physics_frames(5)
		vitals.fresh()
		await live(120.0, 30.0)
		hot[blocks == ALL] = [vitals.taken[&"temperature"], vitals.health]
	print("the heat inside the base shield %s, inside one that holds it back %s" % [hot[false], hot[true]])
	check(hot[false][0] > 0.0, "the base shield lets the heat through (%.2f)" % hot[false][0])
	check(hot[true][0] == 0.0 and hot[true][1] == Vitals.FULL,
		"inside a shield that holds temperature back, nothing harms you (%.2f taken, %.1f health)" % hot[true])
