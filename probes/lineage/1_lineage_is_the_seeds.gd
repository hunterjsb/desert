extends Probe
## Lineage probe 1: a thing's lineage is its draw's seed alone. Drawn for
## every era and site kind twice over two hundred seeds, each lineage is the
## same both times, and the seeds give many; given to two batteries from one
## seed, the same lineage, numbers and look, made once.


func run() -> void:
	var lines := {}
	var same := 0
	var draws := 0
	for kind: StringName in SiteKinds.KINDS:
		var era := SiteKinds.era(kind)
		for k in 200:
			var first := Eras.lineage(era, kind, k)
			randomize()
			if first == Eras.lineage(era, kind, k):
				same += 1
			draws += 1
			lines[Eras.key(first)] = true
	check(same == draws, "every lineage the same from its seed (%d of %d)" % [same, draws])
	check(lines.size() >= 40, "the seeds give many lineages (%d)" % lines.size())

	var one := Catalog.part(&"battery")
	var two := Catalog.part(&"battery")
	Catalog.found_in(one, Eras.SECOND, &"wayshrine", 4021)
	Catalog.found_in(two, Eras.SECOND, &"wayshrine", 4021)
	print("seed 4021 at a wayshrine: %s" % Eras.key(one.get_meta(&"lineage")))
	check(one.get_meta(&"lineage") == two.get_meta(&"lineage") and one.stats == two.stats and one.mass == two.mass,
		"one seed gives two batteries the same lineage and numbers")
	check(_look(one) == _look(two) and _look(one) != Dress.part(&"battery", Catalog.PARTS[&"battery"].size),
		"and the same look, its own with its marks")
	one.free()
	two.free()


func _look(part: Part) -> Mesh:
	for child in part.get_children():
		if child is MeshInstance3D and Paint.is_worn(child):
			return (child as MeshInstance3D).mesh
	return null
