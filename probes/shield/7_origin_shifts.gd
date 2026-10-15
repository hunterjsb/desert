extends ShieldProbe
## Bubble shield probe 7: origin shifts are invisible, and the bubble is
## wherever its generator is. Every reading at world places in and round a
## running shield is the same before and after the engine origin shifts under
## it. Move the generator and the bubble is there at once, before another tick
## runs: shelter is asked of the distance, never told by an event. Free it
## mid-frame and the bubble is gone at once.

const WIND := 15.0


func run() -> void:
	await load_storm(1.0, WIND)
	# Set down and still, so only the shift can move anything.
	var generator := shield_at(ahead(3.0))
	await physics_frames(30)
	generator.freeze = true
	var r := generator.size
	var c := generator.shelter.global_position
	# World places on rings just inside and outside the shell, and further in and out.
	var places: Array[Vector3] = []
	for scale: float in [0.4, 0.97, 1.03, 1.6]:
		for k in 12:
			var way := Vector3.FORWARD.rotated(Vector3.UP, TAU * k / 12.0).rotated(Vector3.RIGHT, 0.3 * (k % 3 - 1))
			var p := c + way * r * scale
			places.append(Vector3(world.world_x(p.x), p.y, world.world_z(p.z)))
	var before := places.map(_readings)
	var centre := Vector3(world.world_x(c.x), c.y, world.world_z(c.z))
	world.shift_origin(Vector2i(3, -2))
	await physics_frames(2)
	var after := places.map(_readings)
	var moved := PackedStringArray()
	for i in places.size():
		if before[i] != after[i]:
			moved.append("%s: %s, then %s" % [places[i], before[i], after[i]])
	var sheltered := before.filter(func(v: Array) -> bool: return v[0] == 1.0).size()
	check(sheltered == 24, "half the places were sheltered (%d of 48)" % sheltered)
	check(moved.is_empty(), "every reading the same after the shift: %s" % "; ".join(moved.slice(0, 3)))
	var now := generator.shelter.global_position
	check(Vector3(world.world_x(now.x), now.y, world.world_z(now.z)).distance_to(centre) < 0.001 and generator.running(),
		"the bubble stands where it stood")

	# Moved, it's sheltering the new place before any tick runs.
	var from := generator.shelter.global_position
	var to := ahead(23.0)
	to.y += from.y - world.height_under(from)
	generator.global_position += to - from
	var weather := world.weather
	check(weather.shelter_at(to, &"storm") == 1.0 and weather.felt_storm(to) == 0.0 and world.wear.rate_at(to) == 0.0,
		"the bubble is at once where the generator went")
	check(weather.shelter_at(from, &"storm") == 0.0 and weather.felt_storm(from) > 0.0 and world.wear.rate_at(from) > 0.0,
		"and gone from where it was")

	# Freed partway through a frame, it's gone at once, and nothing that asks
	# after shelters, then or in the frames after, trips over it.
	generator.free()
	check(weather.shelter_at(to, &"storm") == 0.0 and world.wear.rate_at(to) > 0.0, "freed, its bubble is gone at once")
	await get_tree().process_frame
	await physics_frames(2)


## Everything that asks about shelter, at a world place.
func _readings(at: Vector3) -> Array:
	var p := Vector3(world.engine_x(at.x), at.y, world.engine_z(at.z))
	var weather := world.weather
	return [weather.shelter_at(p, &"storm"), weather.shelter_at(p, &"wind"), weather.felt_storm(p),
		weather.felt_wind(p), world.wear.rate_at(p)]
