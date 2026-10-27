extends Probe
## Every kit builder stays inside its existing housing on the shared worn material.
var looks := [ChassisLooks, ShieldLooks, CampLooks, CellLooks, BoardLooks, StationLooks, HeldLooks, WorldLooks]
const ERAS := [Eras.NEW, Eras.COLONIAL, Eras.FIRST, Eras.SECOND, Eras.SKIMMER]

func run() -> void:
	var variants := 0
	for builder in looks:
		for id: StringName in builder.IDS:
			var part := Catalog.PARTS.has(id)
			var spec: Dictionary = Catalog.PARTS[id] if part else Catalog.DEVICES.get(id, {})
			var size: Vector3 = spec.get("size", Vector3.ZERO)
			if id == &"stake": size = Vector3(0.06, Stake.LENGTH, 0.06)
			elif id == &"mast_top": size = Vector3(0.09, 2.0, 0.09)
			elif id == &"boom": size = Vector3(0.07, 0.07, Mast.BOOM)
			var origin := Vector3(-size.x * 0.5, -size.y * 0.5, 0) if part else -size * 0.5
			if id == &"mast_top": origin.y = 0
			if id == &"boom": origin.z = 0
			var box := AABB(origin, size)
			box.size.y += spec.get("mast", 0.0)
			# Runner blades reach below the mounting plate by their real keel depth.
			if id == &"skates" or id == &"board_plate": box.size.z += spec.stats.keel
			# Only the hook replaces a tie ring that already stood outside its housing.
			if id == &"hook": box = box.merge(AABB(Vector3(-0.065, -0.015, 0.095), Vector3(0.13, 0.03, 0.13)))
			for era: StringName in ERAS:
				var b := Paint.Pieces.new(0.0 if part or builder == ChassisLooks or builder == ShieldLooks else -size.y * 0.5)
				var built: bool
				if builder == CampLooks:
					built = builder.frame(b, id, size, spec.get("mast", 0.0), era)
				elif part and builder == HeldLooks:
					built = builder.part(b, id, size, -1, era)
				elif part and builder == BoardLooks:
					built = builder.part(b, id, size)
				elif part:
					built = builder.part(b, id, size, era)
				else:
					built = builder.frame(b, id, size, era)
				check(built, "%s has a builder for %s" % [id, era])
				var mesh := b.commit()
				check(mesh.get_surface_count() == 1 and mesh.surface_get_material(0) == Paint.worn(), "%s %s keeps one shared worn surface" % [id, era])
				check(box.grow(0.0001).encloses(mesh.get_aabb()), "%s %s stays in its existing envelope: %s" % [id, era, mesh.get_aabb()])
				if id == &"hook" or builder == WorldLooks: print("LOOKS BUDGET ", id, " ", era, " base_triangles=", mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3)
				variants += 1
	_site_envelopes()
	print("LOOKS ENVELOPES ", variants, " variants across ", looks.size(), " builders")


## Sites have plan footprints and burial states instead of Catalog part boxes.
func _site_envelopes() -> void:
	for id: StringName in WorldLooks.SITES:
		var piece := StructureKit.piece(id)
		var solid: AABB = piece.boxes[0]
		for each: AABB in piece.boxes: solid = solid.merge(each)
		var low := solid.position.y
		if id == &"vent_mouth": low = minf(low, -GeologyKit.PIT_DEPTH)
		# The existing capstones, flanges and valve rims stand slightly past their solids.
		var box := AABB(Vector3(-piece.half.x, low, -piece.half.y), Vector3(piece.half.x * 2, solid.end.y - low, piece.half.y * 2)).merge(solid).grow(0.1)
		for state: int in [Exposure.BURIED, Exposure.PARTLY, Exposure.EXPOSED]:
			for variant in piece.looks():
				var mesh := piece.mesh(state, variant)
				check(mesh.get_surface_count() == 1 and mesh.surface_get_material(0) == Paint.worn(), "%s state %d keeps one shared worn surface" % [id, state])
				check(box.encloses(mesh.get_aabb()), "%s state %d stays in its existing site footprint: %s" % [id, state, mesh.get_aabb()])
