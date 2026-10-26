extends Probe
## The drawn structural kit cannot protrude past where its real collision ends.
func run() -> void:
	for id: StringName in ChassisLooks.FRAMES + ChassisLooks.PARTS:
		var size: Vector3
		var part := ChassisLooks.PARTS.has(id)
		if id == &"stake": size = Vector3(0.06, Stake.LENGTH, 0.06)
		elif id == &"mast_top": size = Vector3(0.09, 2.0, 0.09)
		elif id == &"boom": size = Vector3(0.07, 0.07, Mast.BOOM)
		else: size = (Catalog.PARTS[id] if part else Catalog.DEVICES[id]).size
		var origin := Vector3(-size.x * 0.5, -size.y * 0.5, 0) if part else -size * 0.5
		if id == &"mast_top": origin.y = 0
		if id == &"boom": origin.z = 0
		var box := AABB(origin, size).grow(0.0001)
		for era: StringName in [Eras.NEW, Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER]:
			var b := Paint.Pieces.new()
			if part: ChassisLooks.part(b, id, size, era)
			else: ChassisLooks.frame(b, id, size, era)
			var mesh := b.commit()
			check(mesh.get_surface_count() == 1 and mesh.surface_get_material(0) == Paint.worn(), "%s %s keeps one shared worn surface" % [id, era])
			var bounds := mesh.get_aabb()
			check(box.encloses(bounds), "%s %s stays inside its physical box: %s" % [id, era, bounds])
			print("CHASSIS MODEL ", id, " ", era, " triangles=", mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3)
