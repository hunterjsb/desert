extends CampProbe
## Survival probe 1: the AFK promise, with a body. You stand idle in the
## reference camp at the equator for three days and nights of the run's own
## weather, storms and all, and it keeps you alive and unharmed: the shield
## keeps the storm off you. Going unfed is no harm, so the camp no longer
## has to feed you to keep this promise.
## Time limit: 600 s

const DAYS := 3.0


func run() -> void:
	await load_camp()
	var vitals := world.player.vitals
	var seen := {"low": vitals.health}
	await idle(DAYS, func() -> void: seen.low = minf(seen.low, vitals.health))
	var harmed := 0.0
	for harm: StringName in Vitals.HARMS:
		harmed += vitals.taken[harm]
	print("after %d days: health never below %.1f, %.3f taken" % [DAYS, seen.low, harmed])
	check(not vitals.dead and seen.low > 90.0, "you're alive after %d days (health never below %.0f)"
		% [DAYS, seen.low])
	check(harmed < 1e-6, "the shield kept every harm off you (%.3f health)" % harmed)
