extends ShieldProbe
## Survival probe 20: sleep is no dodge. Asleep out in the open in the run's
## own weather on the probes' seed, no bubble over you, a storm due within
## the day: its arrival wakes you, the night lived up to then and no
## further, and waking says the storm woke you.
## Time limit: 300 s

const HOURS := 24
## When the storm's due, in days, and the hour you lie down, of the day.
const DUE := Vector2(0.1, 0.3)
const MORNING := Vector2(0.3, 0.5)


func run() -> void:
	await load_world(1234, false)
	var field := world.weather.field
	var x := world.player_world_x()
	var z := world.player_world_z()
	var day := world.tuning.day_minutes * 60.0
	# Clear in the morning, a storm due in a few hours, so neither the cold
	# nor thirst wakes you first.
	var t := 0.0
	while not _within(world.weather.day.time_of_day(t, world.moon.longitude), MORNING) \
			or field.raw_storm_at(x, z, t) > 0.0 or not _within(field.next_change(x, z, t, day, 10.0) / day, DUE):
		t += 10.0
	world.time = t
	world.weather.forecast_now()
	await live(3.0, 1.0)
	check(world.sleep.refusal() == "", "you can sleep (%s)" % world.sleep.refusal())

	var from := world.time
	var comes := from + field.next_change(x, z, from, day, Weather.FORECAST_STEP)
	var thirst := world.player.vitals.thirst
	await world.sleep.fall_asleep(Sleep.HOURS, HOURS)
	var woke := world.time
	print("a storm due %.0f s on; woke %.0f s on: %s" % [comes - from, woke - from, " / ".join(world.sleep.said)])
	check(world.sleep.last.woke == &"storm" and woke >= comes - 1.0 and woke <= comes + world.tuning.sleep_tick + 1.0,
		"the storm's arrival wakes you (%.0f s from it)" % (woke - comes))
	check(world.player.vitals.thirst < thirst, "the night was lived up to then")
	check("The storm woke you" in world.sleep.said, "waking says so")



func _within(value: float, span: Vector2) -> bool:
	return value >= span.x and value <= span.y
