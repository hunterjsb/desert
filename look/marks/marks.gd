extends "res://look/style/style.gd"
## Look-test: maker's marks. Every marked thing stood in a row in front of the
## camp with its mark toward the camera, crates of each era side by side, and
## the ruin's wall by its corner; each shot close up and from 5 m, so a sheet
## sets the game before marks beside after.
##   godot --path . --disable-vsync res://look/marks/marks.tscn -- --look grey --capture <dir>
## look/marks/shoot.sh shoots it and builds the sheets.

## The row, camp frame: catalog id, layer ("" yours, new), soundness, x, how
## it's turned to show its mark, and how deep it's buried.
const ROW := [
	[&"crate_frame", &"deep", 0.95, -3.4, &"side", 0.0],
	[&"crate_frame", &"surface", 0.5, -2.3, &"side", 0.0],
	[&"crate_frame", &"", 1.0, -1.2, &"side", 0.0],
	[&"shield", &"deep", 0.9, 0.0, &"back", 0.0],
	[&"light_shield", &"", 1.0, 0.7, &"back", 0.0],
	[&"turbine", &"deep", 0.9, 1.6, &"back", 0.0],
	[&"condenser", &"deep", 0.9, 2.65, &"back", 0.0],
	[&"board", &"deep", 0.9, 3.8, &"top", 0.45],
]
const ROW_Z := 5.0
## Shots: name, the thing's x in the row, how high its mark is over the sand,
## and how far the close shot stands off, m.
const CLOSE := [
	["crate_deep", -3.4, 0.3, 0.7],
	["crate_surface", -2.3, 0.3, 0.7],
	["crate_yours", -1.2, 0.3, 0.7],
	["shield", 0.0, 0.22, 0.55],
	["light_shield", 0.7, 0.16, 0.45],
	["turbine", 1.6, 0.15, 0.6],
	["condenser", 2.65, 0.22, 0.7],
	["board", 3.8, 0.55, 0.6],
]


func _dress() -> void:
	# The camp's bubble down: the row stands inside it.
	generator.stand(false)
	for entry: Array in ROW:
		var at := _to_world(Vector3(entry[3], 0.0, ROW_Z))
		var turn: float = {&"side": -PI / 2.0, &"back": PI, &"top": PI}[entry[4]]
		var body: RigidBody3D
		var spec := {"id": entry[0], "device": true, "layer": entry[1], "sound": entry[2], "charge": 0.6,
			"x": at.x, "z": at.y, "yaw": _yaw + turn, "lean": 0.0, "lean_by": 0.0, "bury": entry[5], "fill": []}
		if entry[1] == &"":
			body = Catalog.device(entry[0])
		else:
			body = Finds.make(spec)
		var pose := Finds.pose(body, spec, world.height_at)
		world.content.add_child(body)
		body.global_transform = Transform3D(pose.basis, Vector3(world.engine_x(pose.origin.x), pose.origin.y,
			world.engine_z(pose.origin.z)))
		body.freeze = true
		if entry[1] != &"":
			Finds.age(body, spec.sound)


func _shots() -> Array:
	var out := []
	for shot: Array in CLOSE:
		var x: float = shot[1]
		out.append([shot[0] + "_close", "midmorning", Vector3(x + 0.08, shot[2] + 0.06, ROW_Z + shot[3]),
			Vector3(x, shot[2], ROW_Z)])
		out.append([shot[0] + "_5m", "midmorning", Vector3(x + 1.0, 1.6, ROW_Z + 4.9), Vector3(x, shot[2], ROW_Z)])
	# The deep crate and the surface one side by side.
	out.append(["crates_close", "midmorning", Vector3(-2.85, 0.55, ROW_Z + 1.5), Vector3(-2.85, 0.3, ROW_Z)])
	out.append(["crates_5m", "midmorning", Vector3(-2.0, 1.6, ROW_Z + 4.9), Vector3(-2.85, 0.3, ROW_Z)])
	# The end wall's stencils by its far corner; the sand drifts 0.7 m up it.
	var mark := _camp(ruin.to_world(Vector2(Ruin.HALF.x, -Ruin.HALF.y + 2.45)))
	var out_n := _camp(ruin.to_world(Vector2(Ruin.HALF.x + 1.0, -Ruin.HALF.y + 2.45))) - mark
	for far: Array in [["ruin_close", 1.6, 0.9], ["ruin_5m", 5.0, 1.6]]:
		var eye: Vector2 = mark + out_n * far[1]
		out.append([far[0], "noon", Vector3(eye.x, far[2], eye.y), Vector3(mark.x, 0.65, mark.y)])
	return out


## A world place, x and z, in the camp's frame.
func _camp(w: Vector2) -> Vector2:
	return (w - _middle).rotated(_yaw)
