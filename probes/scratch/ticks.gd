extends CampProbe
## Scratch: the overnight's error against live by sleep tick.
## Time limit: 900 s

func run() -> void:
	var days := float(OS.get_environment("DAYS")) if OS.get_environment("DAYS") != "" else 1.0
	var lived := await _night(-1.0, days)
	print("lived: %s" % lived)
	for tick in [2.0, 5.0, 10.0, 20.0]:
		var slept := await _night(tick, days)
		print("tick %d: stored %.2f (%.3f%%) shield %.2f (%.3f%%) held %s fed %d thirst %.2f water %.3f turbine %.4f %.0f ms" % [tick,
			slept.stored, 100.0 * (slept.stored - lived.stored) / lived.stored, slept.shield,
			100.0 * (slept.shield - lived.shield) / lived.stored, slept.held, slept.fed, slept.thirst, slept.water, slept.turbine, slept.ms])


func _night(tick: float, days: float) -> Dictionary:
	if world != null:
		await reload()
	await load_camp()
	await live(10.0, 1.0)
	var until := world.time + days * world.tuning.day_minutes * 60.0
	var started := Time.get_ticks_usec()
	if tick > 0.0:
		world.tuning.sleep_tick = tick
		world.sleep.overnight(until)
	else:
		await idle(days)
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	var fed := 0.0
	for p in planters:
		fed += p.fed_kcal + p.stored_kcal()
	return {"held": shield.running(), "stored": world.power.stored_wh(), "shield": world.power.pool_wh(shield),
		"thirst": world.player.vitals.thirst, "water": world.player.suit.stock(&"water"), "fed": fed,
		"turbine": turbine.durability, "ms": ms}
