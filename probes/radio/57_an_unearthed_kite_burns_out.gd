extends KiteProbe
## Radio probe 57: an unearthed kite burns something out. Flown high in a
## breeze its charge climbs toward where gathering and leaking balance, past
## its arc threshold, and an arc jumps down the rig and burns out a piece of
## it, spending most of the charge. Its lead run through a driven stake, the
## stake's ring takes the charge to earth instead: it never climbs to an arc.


func run() -> void:
	await load_storm(0.0, 9.0)
	var tuning := Tuning.current()
	var bare := await kite_rig(false)
	var kite: AntennaKite = bare.kite
	await fly_up(kite)
	# Forty minutes of world time, time warped.
	world.time_warp = 20.0
	var t0 := world.time
	var peak := 0.0
	for i in 60 * 120:
		await get_tree().physics_frame
		peak = maxf(peak, kite.charge)
		if kite.arcs > 0 and kite.burnt != &"":
			break
	world.time_warp = 1.0
	print("unearthed, %.0f m up: charge to %.2f, %d arcs, burnt out the %s after %.0f s of world time" % [kite.height(),
		peak, kite.arcs, kite.burnt, world.time - t0])
	check(peak > tuning.kite_arc.x and kite.arcs > 0, "its charge climbs past where an arc jumps")
	check(kite.burnt != &"", "an arc burns out a piece of the rig")

	var staked := await kite_rig(true, false, Vector2(-10.0, 8.0))
	var earthed: AntennaKite = staked.kite
	await fly_up(earthed)
	world.time_warp = 20.0
	var most := 0.0
	for i in 60 * 120:
		await get_tree().physics_frame
		most = maxf(most, earthed.charge)
	world.time_warp = 1.0
	print("through a driven stake: charge at most %.2f, %d arcs, the stake took %d" % [most, earthed.arcs, earthed.grounded])
	check(earthed.arcs == 0 and most < tuning.kite_arc.x + 0.05, "through the stake it never climbs to an arc")

