extends Probe
## Decorative camp kit stays inside its fixed housing, including the old turbine mast.
func run() -> void:
	for id: StringName in CampLooks.IDS:
		var spec: Dictionary = Catalog.DEVICES[id]
		var size: Vector3 = spec.size
		var box := AABB(-size * 0.5, size)
		box.size.y += spec.get("mast", 0.0)
		for era: StringName in [Eras.NEW, Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER]:
			var b := Paint.Pieces.new(-size.y * 0.5)
			CampLooks.frame(b, id, size, spec.get("mast", 0.0), era)
			var mesh := b.commit()
			check(box.grow(0.0001).encloses(mesh.get_aabb()), "%s %s respects its existing physical envelope: %s" % [id, era, mesh.get_aabb()])
			print("CAMP BUDGET ", id, " ", era, " triangles=", mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3)
