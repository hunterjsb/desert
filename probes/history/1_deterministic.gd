extends Probe
## World system probe 1: the history pass is the seed's alone. The same seed
## gives the same landmarks, paths, settlements and sites, laid on the ground
## the same from the same place; another seed gives another history.


func run() -> void:
	var tuning := Tuning.current()
	var first := _whole(History.new(1234, tuning))
	var again := _whole(History.new(1234, tuning))
	var other := _whole(History.new(7, tuning))
	check(first == again, "the same seed makes the same history (%d things)" % first.size())
	var shared := 0
	for i in mini(first.size(), other.size()):
		if first[i] == other[i]:
			shared += 1
	check(shared < first.size() / 10, "another seed makes another (%d of %d the same)" % [shared, first.size()])

	# Laid from the same place twice, beside a Rim town, everything lands in
	# the same world metres.
	var laid: Array[PackedStringArray] = []
	var history := History.new(1234, tuning)
	var town: Vector3 = history.settlements.filter(func(t: Dictionary) -> bool: return t.kind == &"rim_town")[0].p
	for k in 2:
		var shape := TerrainShape.new(1234, tuning)
		shape.sites.follow(300.0, -200.0, Sphere.latitude(town), Sphere.longitude(town), 1.0, 1300.0)
		var lines := PackedStringArray()
		for site in shape.sites.query(Rect2(-1000.0, -1500.0, 2600.0, 2600.0)):
			lines.append("%d %.4f %.4f %.4f" % [site.id, site.x, site.z, site.bearing])
		lines.sort()
		laid.append(lines)
	check(laid[0] == laid[1] and laid[0].size() > 5, "laid twice, the same sites in the same places (%d)" % laid[0].size())

	# The save's sheet: laid from its memories, the same sites in the same places
	# as where it was laid, though the anchor has moved on.
	var walked := TerrainShape.new(1234, tuning)
	var rim: Vector3 = walked.history.landmark(&"halfrise").p
	var on := Sphere.toward(rim, 0.0, 400.0 / walked.history.radius)
	walked.sites.follow(300.0, -200.0, Sphere.latitude(rim), Sphere.longitude(rim), 1.0, 1300.0)
	walked.sites.follow(300.0, -600.0, Sphere.latitude(on), Sphere.longitude(on), 1.0, 1300.0)
	var resumed := TerrainShape.new(1234, tuning)
	resumed.sites.recall(walked.sites.memories())
	check(_laid(walked) == _laid(resumed) and _laid(walked).size() > 5,
		"a sheet recalled from its save lays what it had, where it had it (%d)" % _laid(walked).size())


func _laid(shape: TerrainShape) -> PackedStringArray:
	var lines := PackedStringArray()
	for unit in shape.sites.units():
		for site in unit.sites:
			lines.append("%d %.4f %.4f" % [site.id, site.x, site.z])
	lines.sort()
	return lines


## Everything the pass made, as lines: landmarks, paths, settlements, and the
## sites of every hundredth cell and of every cell a path reaches.
func _whole(history: History) -> PackedStringArray:
	var lines := PackedStringArray()
	for each in history.landmarks:
		lines.append("%s %s" % [each.id, each.p])
	for path in history.network.paths:
		lines.append("%s %d %.3f %s" % [path.kind, path.eras, path.length(), path.points[path.points.size() / 2]])
	for each in history.settlements:
		lines.append("%s %s" % [each.kind, each.p])
	var cells: Array = history._cell_paths.keys()
	cells.sort()
	for cell in range(0, history.cells.count, 100) + cells:
		for site in history.sites_in_cell(cell):
			lines.append("%d %s %s %.4f" % [site.id, site.kind, site.p, site.depth])
	return lines
