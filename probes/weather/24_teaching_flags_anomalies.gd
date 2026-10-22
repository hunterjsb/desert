extends HandsProbe
## Wind & storms probe 24: teaching the Walker. Beside it as it comes, a
## Console holding evidence of two tells uploads and teaches nothing; with
## all three, its cable's plug put in the Walker's port as it passes teaches
## it. Before, no map shows the anomaly whose heart stands 4 km off and the
## Walker's feed says nothing of it; after, the Console's map shows it with
## the weather, the feed flags it for a radio tuned to it, and the run's save
## keeps that it's taught. The heart is staged.
## Time limit: 300 s.


class Staged extends WeatherField:
	func anomalies_near(x: float, z: float, t: float, _reach: float) -> Array[Dictionary]:
		return [{"x": x + 2800.0, "z": z - 2800.0, "radius": 8000.0, "peak": t + 600.0, "strength": 1.0, "share": 0.0}]


func run() -> void:
	await load_hands()
	var scenario := Scenarios.by_key("walker")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	world.time_warp = 0.0
	await settle(true)
	var dropped := await Scenarios.lay(world, scenario, place)
	world.weather.field = Staged.new(world.run_seed, Tuning.current())
	var console: Console = dropped.filter(func(n: Node) -> bool: return n is Console)[0]
	var radio: Radio = dropped.filter(func(n: Node) -> bool: return n is Radio)[0]
	# Stuck on the deck at whatever angle; the Walker's feed, not the rod's null, is what's tested.
	Tuning.current().rod_null = 1.0
	var walker: Walker = get_tree().get_nodes_in_group(&"walker")[0]
	await physics_frames(5)
	check(_mapped(console).is_empty() and not "anomaly" in radio.said, "untaught, no map shows it and the feed says nothing")

	var kept: Dictionary = console.evidence.duplicate()
	console.evidence.erase(&"load")
	console.upload()
	check(not world.taught and "2 OF 3 TELLS" in console.screen_text(Console.Page.LOG), "two tells teach it nothing")
	console.evidence = kept

	# As it comes alongside, the plug in your hands to its port.
	world.time_warp = 1.0
	while walker.port.global_position.distance_to(eye()) > 4.0 and world.time < place.time + 120.0:
		await physics_frames(1)
	world.time_warp = 0.0
	var port := walker.port.global_position
	var out := walker.port.global_basis.z
	look(port + out * 1.2 + Vector3.UP * 0.2, port)
	await physics_frames(3)
	check(hands.grab() and walker.port.part != null, "the plug goes in its port")
	await physics_frames(3)
	print(console.screen_text(Console.Page.LOG))
	check(world.taught and "WALKER TAUGHT" in console.screen_text(Console.Page.LOG), "three tells teach it")
	await physics_frames(5)
	var mapped := _mapped(console)
	print("its map shows %d anomaly, the feed: \"%s\"" % [mapped.size(), radio.said])
	check(mapped.size() == 1, "taught, its map shows the anomaly")
	check("anomaly 4.0 km north-east" in radio.said, "and the Walker's feed flags it")
	check(Snapshot.take(world).get("taught", false), "the run's save keeps it taught")


func _mapped(console: Console) -> Array:
	return console._model(Console.Page.MAP, console.pooled_readings()).get("map", {}).get("anomalies", [])
