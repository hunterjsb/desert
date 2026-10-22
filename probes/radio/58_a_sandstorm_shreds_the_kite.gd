extends KiteProbe
## Radio probe 58: a sandstorm shreds the kite. Flown in clear air it hardly
## wears; flown in a sandstorm it's torn to rags in about kite_storm_ruin_s,
## and comes down, hearing nothing.


func run() -> void:
	await load_storm(0.0, 9.0)
	var tuning := Tuning.current()
	# Staked, so no arc burns it first.
	var rig := await kite_rig(true)
	var kite: AntennaKite = rig.kite
	await fly_up(kite)
	world.time_warp = 10.0
	var t0 := world.time
	await physics_frames(600)
	var clear_wear := 1.0 - kite.durability
	var clear_s := world.time - t0
	print("clear air, %.0f s of world time: worn %.4f" % [clear_s, clear_wear])
	check(clear_wear < 0.02, "in clear air it hardly wears")
	# Under the harm wind, so the storm alone wears it.
	weather_everywhere(1.0, 12.0)
	t0 = world.time
	for i in 60 * 60:
		await get_tree().physics_frame
		if kite.wrecked():
			break
	var ruined := world.time - t0
	world.time_warp = 1.0
	await physics_frames(240)
	print("in a sandstorm: torn to rags after %.0f s of world time, now %.1f m up" % [ruined, kite.height()])
	check(kite.wrecked() and absf(ruined - tuning.kite_storm_ruin_s) < tuning.kite_storm_ruin_s * 0.3,
		"in a sandstorm it's torn to rags in about %d s" % roundi(tuning.kite_storm_ruin_s))
	check(not kite.up() and (rig.radio as Radio).kite().up() == false, "and comes down, hearing nothing")
