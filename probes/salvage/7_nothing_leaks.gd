extends SalvageProbe
## Salvage & ruins probe 7: nothing leaks. On world probe 3's 20 km walk, half
## straight and half wandering, taking a find every kilometre and leaving it
## behind: every find in memory lies in a chunk whose ground is solid, there
## are never more than those chunks can hold, the chunks remembered are never
## more than are loaded, and the object count and memory stay flat as finds
## are laid out ahead and forgotten behind: back where the count began,
## arriving the same way, it's the count it was.

const STEP := 32.0


func run() -> void:
	await load_salvage()
	var tuning := Tuning.current()
	# The most a solid chunk holds, with a ruin's floor besides.
	var solid := (2 * tuning.near_radius + 3) ** 2
	var most_finds := solid * tuning.finds_most + 2 * (Finds.RUIN_FINDS.y + 1)
	var most_lots := (2 * tuning.view_radius + 3) ** 2
	var x := world.player_world_x()
	var z := world.player_world_z()
	var heading := 0.0
	var walked := 0.0
	var next_take := 1000.0
	var taken := 0
	var biggest := 0
	var lots := 0
	var adrift := 0
	var baseline_objects := 0
	var baseline_memory := 0.0
	var base := Vector2.ZERO
	while walked < 20000.0:
		if walked >= 10000.0 and fmod(walked, 512.0) < STEP:
			heading = randf() * TAU
		x += cos(heading) * STEP
		z += sin(heading) * STEP
		walked += STEP
		teleport(x, z)
		await settle(true)
		await physics_frames(2)
		var finds := salvage.finds()
		biggest = maxi(biggest, finds.size())
		lots = maxi(lots, salvage.lots())
		for body in finds:
			var at := body.global_position
			if not world.terrain.has_collision_at(world.world_x(at.x), world.world_z(at.z)):
				adrift += 1
		if walked >= next_take and not finds.is_empty():
			next_take += 1000.0
			# Taken up out of the sand: yours now, and left behind.
			salvage.unbury(finds[0])
			taken += 1
		if baseline_objects == 0 and walked >= 2000.0:
			base = Vector2(x, z)
			await _arrive(base)
			baseline_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
			baseline_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	await _arrive(base)
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory := Performance.get_monitor(Performance.MEMORY_STATIC)
	print("finds in memory <= %d (of %d allowed), chunks remembered <= %d, %d taken, objects %d -> %d, memory %.1f -> %.1f MB"
		% [biggest, most_finds, lots, taken, baseline_objects, objects, baseline_memory / 1048576.0, memory / 1048576.0])
	check(biggest > 0 and biggest <= most_finds, "finds in memory stay bounded (most at once %d)" % biggest)
	check(adrift == 0, "every find in memory lies on solid ground (%d didn't)" % adrift)
	check(lots <= most_lots, "chunks remembered are never more than are loaded (%d)" % lots)
	check(taken >= 15, "finds were taken along the way (%d)" % taken)
	check(objects < baseline_objects * 1.1, "object count stays flat (%d -> %d)" % [baseline_objects, objects])
	check(memory < baseline_memory + 64.0 * 1048576.0, "memory stays flat")


## Arrives at a place from far off, everything built and laid out: what's
## loaded then depends on the place alone, not on the way you came.
func _arrive(at: Vector2) -> void:
	for x in [at.x + 3000.0, at.x]:
		teleport(x, at.y)
		await settle()
		await settle_finds()
