extends DeckProbe
## The ordinary take path reports the arrival object when the hands actually grip it.
class Receipt extends SurveyorArrival:
	var got: Array[Node] = []
	func recover(body: Node) -> void:
		got.append(body)

func run() -> void:
	await load_lines()
	var state := SurveyorManifest.resolve(1234, world.start)
	state.landing_world = Vector2(world.player_world_x() + 6.0, world.player_world_z())
	state.heading = 0.0
	var made := SurveyorRecovery.materialize(world, state)
	check(not made.is_empty(), "arrival gear materializes")
	if made.is_empty():
		return
	var receipt := Receipt.new()
	receipt.world = world
	world.add_child(receipt)
	world.arrival = receipt
	var beacon := made[&"beacon"] as Device
	look(beacon.global_position + Vector3(0, 0.8, 1.3), beacon.global_position)
	await physics_frames(4)
	check(hands.grab(), "normal take accepts the actual beacon")
	check(receipt.got.has(beacon) and beacon.get_meta(&"arrival_uid") == &"beacon", "gripping reports its stable arrival identity")
