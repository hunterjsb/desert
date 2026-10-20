extends NomadHoistProbe
## Unclaimed site rigging must not become saved or leave strands after streaming.

func run() -> void:
	await load_nomads()
	var lines := world.ropes.ropes.size()
	var strands := world.ropes.strands.size()
	var before := Snapshot.take(world)
	var deck := lay_nomad(&"runner")
	await physics_frames(3)
	var mast := mast_on(deck)
	var line: Line = mast.halyard_socket().part.get_meta(&"line")
	var data := Snapshot.take(world)
	check(data.lines.size() == before.lines.size() and data.strands.size() == before.strands.size(),
		"unclaimed rigging does not leak into the player's saved rope or strands")
	var coord: Vector2i = deck.get_meta(&"find")[0]
	var chunk: TerrainChunk = world.salvage._lots[coord].chunk
	world.salvage._on_ungrounded(chunk)
	world.salvage.stream(Time.get_ticks_usec() + 1000000)
	await physics_frames(3)
	check(not is_instance_valid(deck) and not is_instance_valid(line)
		and world.ropes.ropes.size() == lines and world.ropes.strands.size() == strands,
		"streaming the unclaimed rig away leaves no owned rope or drawn strand")
	var again := lay_nomad(&"runner")
	await physics_frames(3)
	check(mast_on(again).halyard() != null and world.ropes.ropes.size() == lines + 1,
		"laying the unclaimed rig again creates exactly one halyard")
