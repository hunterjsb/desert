extends MovementProbe
## Walking off the sand onto a deck, your steps go from sand to metal.

var deck: Chassis


func run() -> void:
	await load_moving()
	blow(Vector2.ZERO)
	var level := Scenarios.open_sand(world)
	await place(level.x, level.y, Vector2.RIGHT)
	var on_sand := await _walk(1.6)
	check(_all_in(on_sand, Footing.SAND), "steps on open sand sound sand")

	# A frozen strip of deck five pieces long, lying flat beside you.
	deck = Rig.build(world.content, [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(2, 0)],
		[&"piece", Vector2i(3, 0)], [&"piece", Vector2i(4, 0)]]).deck
	deck.freeze = true
	var at := player.global_position + Vector3(0.0, 0.0, 4.0)
	at.y = world.height_under(at) + 0.6
	deck.global_transform = Transform3D(Basis.IDENTITY, at)
	await physics_frames(2)
	var top := deck.global_transform * Vector3(0.0, Chassis.THICK * 0.5 + 0.05, 0.0)
	world.teleport(player, Transform3D(Basis.IDENTITY, top))
	player.velocity = Vector3.ZERO
	player.own = Vector2.ZERO
	face(Vector2.RIGHT)
	await simulate(0.5)
	var on_deck := await _walk(1.6)
	print("FOOTSTEPS ", JSON.stringify({"sand": on_sand.size(), "deck": on_deck.size(),
		"footing": player.underfoot(), "floor": player.is_on_floor()}))
	check(_all_in(on_deck, Footing.METAL), "steps on a deck sound metal")


## Walks ahead for `seconds`, and the step sounds started meanwhile.
func _walk(seconds: float) -> Array:
	var heard: Array = []
	# A step still sounding from before counts as heard already, not as one of these.
	var playing := {}
	for foot: AudioStreamPlayer in player.feel._feet:
		playing[foot] = foot.playing
	hold(["move_forward"])
	await simulate(seconds, func() -> void:
		for foot: AudioStreamPlayer in player.feel._feet:
			if foot.playing and not playing.get(foot, false):
				heard.append(foot.stream)
			playing[foot] = foot.playing)
	hold([])
	return heard


func _all_in(heard: Array, footing: StringName) -> bool:
	return not heard.is_empty() and heard.all(func(s: AudioStream) -> bool: return Sounds.STEPS[footing].has(s))
