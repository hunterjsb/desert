extends "res://look/style/style.gd"
## Look-test: lineage. A chassis piece with a battery on the sand before it for
## each era and lineage, in a row in front of the camp, each shot close up and
## from 5 m, and the row whole: the company's issue (the kit's), colonial, a
## First Kingdoms house's, the skimmer era's, remade in the Dark Age, remade
## over a house's marks and blessed, and Cistern-touched.
##   godot --path . --disable-vsync res://look/lineage/lineage.tscn -- --look grey --capture <dir>
## look/lineage/shoot.sh shoots it and builds the sheet.

## The row, camp frame: name, lineage (none: the kit's), and x.
const ROW := [
	["issued", [], -4.2],
	["colonial", [[Eras.COLONIAL, &"made", [&"tilg"]]], -2.8],
	["first", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"okafor"]]], -1.4],
	["skimmer", [[Eras.SKIMMER, &"made", []]], 0.0],
	["remade", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.DARK, &"remade", [&"plate", &"cord"]]], 1.4],
	["second", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"kessel"]],
		[Eras.DARK, &"remade", [&"wood", &"cord", &"ceramic"]], [Eras.SECOND, &"blessed", [&"tu", &"charm"]]], 2.8],
	["cistern", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.DARK, &"remade", [&"cord", &"ceramic"]],
		[Eras.SECOND, &"blessed", [&"cistern", &"charm"]]], 4.2],
]
const ROW_Z := 5.0


func _dress() -> void:
	# The camp's bubble down: the row stands inside it.
	generator.stand(false)
	for entry: Array in ROW:
		var piece := Catalog.device(&"chassis")
		var cell := Catalog.part(&"battery")
		Catalog.inherit(piece, entry[1])
		Catalog.inherit(cell, entry[1])
		for each: Array in [[piece, Vector3(entry[2], 0.0, ROW_Z), 0.0], [cell, Vector3(entry[2] + 0.1, 0.0, ROW_Z + 0.75), PI * 0.15]]:
			var body: RigidBody3D = each[0]
			var at := _to_world(each[1])
			world.content.add_child(body)
			var low := Finds.bounds(body).position.y
			# A battery lies on its back, its face up to the camera.
			var turn := Basis(Vector3.UP, _yaw + each[2]) * (Basis(Vector3.RIGHT, -PI / 2.0) if body is Part else Basis.IDENTITY)
			body.global_transform = Transform3D(turn, Vector3(world.engine_x(at.x),
				world.height_at(at.x, at.y) - (low if body is Device else -0.06), world.engine_z(at.y)))
			body.freeze = true


func _shots() -> Array:
	var out := []
	for entry: Array in ROW:
		var x: float = entry[2]
		out.append([entry[0] + "_close", "midmorning", Vector3(x + 0.5, 1.0, ROW_Z + 1.9), Vector3(x, 0.25, ROW_Z + 0.3)])
		out.append([entry[0] + "_5m", "midmorning", Vector3(x + 1.2, 1.7, ROW_Z + 4.8), Vector3(x, 0.3, ROW_Z + 0.3)])
	out.append(["row", "midmorning", Vector3(0.0, 2.2, ROW_Z + 7.5), Vector3(0.0, 0.3, ROW_Z)])
	return out
