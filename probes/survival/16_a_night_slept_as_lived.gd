extends CampProbe
## Survival probe 16: a night slept comes out as lived. The reference camp on
## the probes' seed is left a day and a night of the run's own weather, a
## storm through it, once lived at the time warp's fastest and once slept,
## the camp held still and the clock stepped: its batteries, its shield's
## charge and whether the shield held come out the same, within a small share.
## Time limit: 600 s

const DAYS := 1.0
## Of all the charge stored.
const SHARE := 0.01


func run() -> void:
	var lived := await _night(false)
	var slept := await _night(true)
	print("lived: %s" % lived)
	print("slept: %s" % slept)
	check(lived.storm > 0.2, "a storm through it (%d%% of the day)" % roundi(lived.storm * 100.0))
	check(slept.held == lived.held, "the shield held, or gave out, the same (%s)" % lived.held)
	check(absf(slept.stored - lived.stored) <= SHARE * lived.stored,
		"the batteries hold the same, %.1f Wh against %.1f" % [slept.stored, lived.stored])
	check(absf(slept.shield - lived.shield) <= SHARE * lived.stored,
		"the shield's pool the same, %.1f Wh against %.1f" % [slept.shield, lived.shield])


## The camp parked and settled, then a day and a night lived or slept.
func _night(asleep: bool) -> Dictionary:
	if world != null:
		await reload()
	await load_camp()
	await live(10.0, 1.0)
	var from := world.time
	var until := from + DAYS * world.tuning.day_minutes * 60.0
	var started := Time.get_ticks_usec()
	if asleep:
		world.sleep.overnight(until)
	else:
		await idle(DAYS)
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	var stormy := 0
	for k in 100:
		stormy += 1 if world.weather.field_storm(shield.global_position, lerpf(from, until, k / 100.0)) > 0.0 else 0
	return {"held": shield.running(), "stored": world.power.stored_wh(), "shield": world.power.pool_wh(shield),
		"storm": stormy / 100.0, "ms": roundi(ms)}
