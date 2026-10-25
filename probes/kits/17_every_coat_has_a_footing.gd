extends Probe
## Every coat a structure's boxes are painted in says how it sounds
## underfoot, so a new coat can't quietly fall back to stone.

func run() -> void:
	var missing := {}
	for kind: StringName in StructureKit.kinds():
		for coat in StructureKit.piece(kind).coats:
			if not coat.is_empty() and not Footing.COATS.has(coat):
				missing[coat] = kind
	print("UNFOOTED_COATS ", JSON.stringify(missing))
	check(missing.is_empty(), "every structure coat has a footing")
