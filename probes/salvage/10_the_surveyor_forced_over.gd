extends WeatherProbe
## Salvage probe 10: the Surveyor forced over. The "surveyor" scenario puts a
## flare in your hands and turns the Surveyor's orbit to bring it straight
## over you SURVEYOR_LEAD s later, its height and lap as they were: below the
## cannon's height now, near the zenith then. Lit as it comes over, the flare
## brings its cannon down. The dev console's surveyor does the same, as soon
## as asked.
## Time limit: 240 s


func run() -> void:
	await load_weather()
	await Scenarios.apply(world, Scenarios.by_key("surveyor"))
	await physics_frames(5)
	var player := world.player
	var flare := player.hands.held as Flare
	check(flare != null and not flare.lit, "the scenario puts an unlit flare in your hands")
	var start := world.time
	var orbit: Satellite = Radio.constellation_of(world).orbits[Airdrop.SURVEYOR]
	var high := deg_to_rad(world.tuning.airdrop_elevation_degrees)
	var over := Airdrop.surveyor(world, player.global_position, start + Scenarios.SURVEYOR_LEAD - 5.0)
	var peak := 0.0
	var when := 0.0
	var t := start
	while t < start + Scenarios.SURVEYOR_LEAD * 2.0:
		var up: float = Airdrop.surveyor(world, player.global_position, t).up
		if up > peak:
			peak = up
			when = t - start
		t += 0.25
	print("the Surveyor %.0f° up as the scenario begins, %.1f° at its highest, %.1f s on; %.0f m up" % [
		rad_to_deg(Airdrop.surveyor(world, player.global_position, start).up), rad_to_deg(peak), when,
		orbit.height(start) * orbit.radius])
	check(Airdrop.surveyor(world, player.global_position, start).up < high, "below the cannon's height as it begins")
	check(rad_to_deg(peak) > 85.0 and absf(when - Scenarios.SURVEYOR_LEAD) < 1.0,
		"straight over you %d s later" % roundi(Scenarios.SURVEYOR_LEAD))
	check(absf(orbit.height(start) * orbit.radius - 1910.0) < 30.0, "its height as it was")

	# Lit as it comes over, its cannon fires.
	world.time = start + Scenarios.SURVEYOR_LEAD - 6.0
	flare.use(player, Vector3.ZERO)
	var fired := false
	for i in 900:
		await get_tree().physics_frame
		if flare.called:
			fired = true
			break
	print("the flare lit %.0f° under it; fired at %.0f°" % [rad_to_deg(over.up),
		rad_to_deg(Airdrop.surveyor(world, player.global_position, world.time).up)])
	check(fired, "lit as it comes over, the flare brings its cannon down")

	# The console's surveyor, as soon as asked.
	Scenarios.surveyor_over(world, 10.0)
	var soon := Airdrop.surveyor(world, player.global_position, world.time + 10.0)
	check(rad_to_deg(soon.up) > 85.0, "the console's surveyor brings it over when asked (%.1f°)" % rad_to_deg(soon.up))
	check(DevConsole.COMMANDS.has("surveyor"), "the dev console has surveyor")
