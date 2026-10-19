extends ShieldProbe
## Profile & saves probe 26: an anomaly's deeds. In a storm under a running
## shield, a compass in your hands and a radio on beside you, an anomaly's
## heart comes over: the needle leans, the radio crackles and the shield
## strains, and each tell counts, so Tells is done. Its heart over you is no
## Eye of the Anomaly yet; once it has fallen back to nothing with you alive,
## it is. The anomaly is staged, as deep as asked, its heart a kilometre east.


## The field with an anomaly's hidden term as deep as asked, everywhere.
class Staged extends WeatherField:
	var deep := 0.0

	func anomaly_at(_x: float, _z: float, _t: float) -> float:
		return deep

	func anomalies_near(x: float, z: float, _t: float, reach: float) -> Array[Dictionary]:
		var out: Array[Dictionary] = []
		if deep > 0.0:
			out.append({"x": x + 1000.0, "z": z, "radius": reach, "peak": 0.0, "strength": deep, "share": deep})
		return out


func run() -> void:
	await load_storm(1.0)
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var staged := Staged.new(world.run_seed, Tuning.current())
	world.weather.field = staged
	var player := world.player
	var shield := shield_at(player.global_position)
	var compass := Catalog.part(&"compass")
	world.content.add_child(compass)
	compass.global_position = player.camera.global_position + Vector3(0.0, 0.0, -0.5)
	player.hands.hold(compass)
	var radio := spawn_device(&"radio", 2.0) as Radio
	radio.on = true
	await live(2.0, 1.0)
	check(shield.running() and player.hands.held == compass and radio.playing(),
		"a shield up over you, a compass in your hands, a radio on beside you")
	staged.deep = 1.0
	await live(3.0, 1.0)
	check(profile.did("tells") and profile.toward_count("tells") == Deeds.TELLS.size(),
		"its needle leaning, its crackle and the shield's strain: Tells")
	check(player.vitals.in_heart and not profile.did("anomaly_eye"), "in its heart, no Eye of the Anomaly yet")
	staged.deep = 0.0
	await live(2.0, 1.0)
	check(not player.vitals.dead and profile.did("anomaly_eye"), "its heart gone over, you alive: Eye of the Anomaly")
