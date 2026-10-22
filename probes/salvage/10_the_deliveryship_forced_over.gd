extends WeatherProbe
## Salvage probe 10: the deliveryship forced over. The "deliveryship" scenario puts a
## flare in your hands and turns the deliveryship's orbit to bring it straight
## over you DELIVERYSHIP_LEAD s later, its height and lap as they were: below the
## cannon's height now, near the zenith then. Lit as it comes over, the flare
## brings its cannon down. The dev console's deliveryship does the same, as soon
## as asked.
## Time limit: 240 s


func run() -> void:
	await load_weather()
	await Scenarios.apply(world, Scenarios.by_key("deliveryship"))
	await physics_frames(5)
	var player := world.player
	var flare := player.hands.held as Flare
	check(flare != null and not flare.lit, "the scenario puts an unlit flare in your hands")
	var start := world.time
	var orbit: Satellite = Radio.constellation_of(world).orbits[Airdrop.DELIVERYSHIP]
	var high := deg_to_rad(world.tuning.airdrop_elevation_degrees)
	var over := Airdrop.deliveryship(world, player.global_position, start + Scenarios.DELIVERYSHIP_LEAD - 5.0)
	var peak := 0.0
	var when := 0.0
	var t := start
	while t < start + Scenarios.DELIVERYSHIP_LEAD * 2.0:
		var up: float = Airdrop.deliveryship(world, player.global_position, t).up
		if up > peak:
			peak = up
			when = t - start
		t += 0.25
	print("the deliveryship %.0f° up as the scenario begins, %.1f° at its highest, %.1f s on; %.0f m up" % [
		rad_to_deg(Airdrop.deliveryship(world, player.global_position, start).up), rad_to_deg(peak), when,
		orbit.height(start) * orbit.radius])
	check(Airdrop.deliveryship(world, player.global_position, start).up < high, "below the cannon's height as it begins")
	check(rad_to_deg(peak) > 85.0 and absf(when - Scenarios.DELIVERYSHIP_LEAD) < 1.0,
		"straight over you %d s later" % roundi(Scenarios.DELIVERYSHIP_LEAD))
	var kept: float = Constellation.ROSTER.filter(func(e: Dictionary) -> bool: return e.id == Airdrop.DELIVERYSHIP)[0].orbit.altitude
	check(absf(orbit.height(start) - kept) < 0.002, "its height as it was")

	# Lit as it comes over, its cannon fires.
	world.time = start + Scenarios.DELIVERYSHIP_LEAD - 6.0
	flare.use(player, Vector3.ZERO)
	var fired := false
	for i in 900:
		await get_tree().physics_frame
		if flare.called:
			fired = true
			break
	print("the flare lit %.0f° under it; fired at %.0f°" % [rad_to_deg(over.up),
		rad_to_deg(Airdrop.deliveryship(world, player.global_position, world.time).up)])
	check(fired, "lit as it comes over, the flare brings its cannon down")

	# The console's deliveryship, as soon as asked.
	Scenarios.deliveryship_over(world, 10.0)
	var soon := Airdrop.deliveryship(world, player.global_position, world.time + 10.0)
	check(rad_to_deg(soon.up) > 85.0, "the console's deliveryship brings it over when asked (%.1f°)" % rad_to_deg(soon.up))
	check(DevConsole.COMMANDS.has("deliveryship"), "the dev console has deliveryship")
