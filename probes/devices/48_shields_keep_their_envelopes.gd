extends Probe
## The drawn shields cannot protrude past where their real collision ends, in
## any era's shape, and each stays one shared worn surface.
func run() -> void:
	for id: StringName in [&"shield", &"light_shield"]:
		var size: Vector3 = Catalog.DEVICES[id].size
		var box := AABB(-size * 0.5, size).grow(0.0001)
		for era: StringName in [Eras.NEW, Eras.COLONIAL, Eras.SKIMMER, Eras.FIRST, Eras.SECOND]:
			var b := Paint.Pieces.new()
			ShieldLooks.frame(b, id, size, era)
			var mesh := b.commit()
			check(mesh.get_surface_count() == 1 and mesh.surface_get_material(0) == Paint.worn(),
				"%s %s keeps one shared worn surface" % [id, era])
			check(box.encloses(mesh.get_aabb()), "%s %s stays inside its physical box: %s" % [id, era, mesh.get_aabb()])
