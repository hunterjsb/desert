extends WeatherProbe
## Wind & storms probe 20: the anomaly's tells rise with its hidden term,
## from the clear well ahead of its wall, to where it reaches a half, to its
## heart: the compass leans toward the heart and the radio crackles, more
## at each; and at the heart the shield's load on the Console's stats is past
## three full storms' while its wind and sand read an ordinary one.


func run() -> void:
	await load_weather()
	var met := await meet_anomaly()
	if met.is_empty():
		return
	var console: Console = met.camp.filter(func(n: Node) -> bool: return n is Console)[0]
	var radio: Radio = met.camp.filter(func(n: Node) -> bool: return n is Radio)[0]
	var shield: ShieldGenerator = met.camp.filter(func(n: Node) -> bool: return n is ShieldGenerator)[0]
	var here := world.player.global_position
	# Between carriers, so no signal ducks the static.
	while radio.channel != Radio.STATIC:
		radio.tune(1)
	var tells := []
	for moment: float in [met.before, met.half, met.heart]:
		# At a moment a crackle's burst sounds, so its loudness says how much.
		var t := moment
		while Interference.crackle(t).x < 1.0:
			t += Interference.CRACKLE
		world.time = t
		await physics_frames(10)
		var deep := field.anomaly_at(world.player_world_x(), world.player_world_z(), t)
		# With north a quarter turn off the heart's way, how far the needle leans.
		var hearts := field.anomalies_near(world.player_world_x(), world.player_world_z(), t, world.tuning.anomaly_radius_m)
		var lean := 0.0
		if not hearts.is_empty():
			var away := Vector2(hearts[0].x - world.player_world_x(), hearts[0].z - world.player_world_z())
			lean = absf(Compass.anomaly_lean(world, here, t, atan2(away.x, -away.y) + PI * 0.5))
		tells.append({"deep": deep, "lean": rad_to_deg(lean), "crackle": radio.crackle.volume_db,
			"load": _load(console), "wind": console.readings.get("wind", {}).get("steady", NAN),
			"sand": console.readings.get("sand", {}).get("g_m3", NAN)})
		print("hidden %.2f: compass leans %.0f°, crackle %.0f dB, shield load %d %%, wind %.1f m/s, sand %.2f g/m³" % [
			deep, rad_to_deg(lean), radio.crackle.volume_db, tells[-1].load, tells[-1].wind, tells[-1].sand])
	check(radio.playing() and shield.running(), "the radio plays and the shield runs")
	check(tells[0].deep == 0.0 and tells[0].lean == 0.0 and tells[0].crackle < -40.0 and tells[0].load <= 100,
		"well ahead of its wall, no tell")
	for key: String in ["deep", "lean", "crackle"]:
		check(tells[2][key] > tells[1][key] and tells[1][key] > tells[0][key],
			"%s rises with the hidden term (%s)" % [key, [tells[0][key], tells[1][key], tells[2][key]]])
	var ordinary := world.tuning.prevailing_speed + world.tuning.prevailing_sway + world.tuning.storm_outflow_speed
	check(tells[2].load > 300 and tells[2].wind <= ordinary and tells[2].sand <= world.tuning.sand_full_g_m3,
		"at its heart the shield's load is past three full storms' while the wind and sand read ordinary")


## The shield's load, %, as the Console's stats show it.
func _load(console: Console) -> int:
	for row in console.screen_text(Console.Page.STATS).split("\n"):
		if row.strip_edges().begins_with("load "):
			return row.strip_edges().get_slice(" ", 1).to_int()
	return -1
