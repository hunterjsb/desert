extends "res://look/style/style.gd"
## Look-test: maker's marks. Every marked thing stood in a row in front of the
## camp with its mark toward the camera, chassis pieces of each era side by
## side, their stencils on their tops, and
## the ruin's wall by its corner; each shot close up and from 5 m, so a sheet
## sets the game before marks beside after.
##   godot --path . --disable-vsync res://look/marks/marks.tscn -- --look grey --capture <dir> [--motion]
## look/marks/shoot.sh shoots it and builds the sheets. --motion shoots
## instead runs of frames for spotting flicker: the camera creeping past the
## camp and the ruin's wall a couple of millimetres a frame, and then still
## with the clock running.

## The row, camp frame: catalog id, layer ("" yours, new), soundness, x, how
## it's turned to show its mark, and how deep it's buried.
const ROW := [
	[&"chassis", &"deep", 0.95, -3.4, &"top", 0.0],
	[&"chassis", &"surface", 0.5, -2.3, &"top", 0.0],
	[&"chassis", &"", 1.0, -1.2, &"top", 0.0],
	[&"shield", &"deep", 0.9, 0.0, &"back", 0.0],
	[&"light_shield", &"", 1.0, 0.7, &"back", 0.0],
	[&"turbine", &"deep", 0.9, 1.6, &"back", 0.0],
	[&"condenser", &"deep", 0.9, 2.65, &"back", 0.0],
	[&"board", &"deep", 0.9, 3.8, &"top", 0.45],
]
const ROW_Z := 5.0
## Shots: name, the thing's x in the row, how high its mark is over the sand,
## how far the close shot stands off, m, and how high it stands over the mark
## where that isn't a little (a stencil on a top is looked down on).
const CLOSE := [
	["chassis_deep", -3.4, 0.12, 0.7, 0.6],
	["chassis_surface", -2.3, 0.12, 0.7, 0.6],
	["chassis_yours", -1.2, 0.12, 0.7, 0.6],
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
		var over: float = shot[4] if shot.size() > 4 else 0.06
		out.append([shot[0] + "_close", "midmorning", Vector3(x + 0.08, shot[2] + over, ROW_Z + shot[3]),
			Vector3(x, shot[2], ROW_Z)])
		out.append([shot[0] + "_5m", "midmorning", Vector3(x + 1.0, 1.6, ROW_Z + 4.9), Vector3(x, shot[2], ROW_Z)])
	# The deep piece and the surface one side by side.
	out.append(["chassis_pair_close", "midmorning", Vector3(-2.85, 1.0, ROW_Z + 1.5), Vector3(-2.85, 0.12, ROW_Z)])
	out.append(["chassis_pair_5m", "midmorning", Vector3(-2.0, 1.6, ROW_Z + 4.9), Vector3(-2.85, 0.12, ROW_Z)])
	# The end wall's stencils by its far corner; the sand drifts 0.7 m up it.
	var mark := _camp(ruin.to_world(Vector2(Ruin.HALF.x, -Ruin.HALF.y + 2.45)))
	var out_n := _camp(ruin.to_world(Vector2(Ruin.HALF.x + 1.0, -Ruin.HALF.y + 2.45))) - mark
	for far: Array in [["ruin_close", 1.6, 0.9], ["ruin_5m", 5.0, 1.6]]:
		var eye: Vector2 = mark + out_n * far[1]
		out.append([far[0], "noon", Vector3(eye.x, far[2], eye.y), Vector3(mark.x, 0.65, mark.y)])
	return out


## Flicker runs: name, moment, camera and target in the camp's frame, and its
## creep each frame, m.
func _runs() -> Array:
	var mark := _camp(ruin.to_world(Vector2(Ruin.HALF.x, -Ruin.HALF.y + 2.45)))
	var out_n := _camp(ruin.to_world(Vector2(Ruin.HALF.x + 1.0, -Ruin.HALF.y + 2.45))) - mark
	var along := Vector3(out_n.y, 0.0, -out_n.x)
	var wall := Vector3(mark.x, 1.0, mark.y)
	return [
		["camp", "midmorning", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0), Vector3(0.002, 0.0, 0.0)],
		["row", "midmorning", Vector3(0.3, 1.2, ROW_Z + 2.2), Vector3(0.3, 0.3, ROW_Z), Vector3(0.002, 0.0, 0.0)],
		["wall8", "noon", wall + Vector3(out_n.x * 8.0, 0.7, out_n.y * 8.0), wall, along * 0.002],
		["wall15", "noon", wall + Vector3(out_n.x * 15.0 + along.x * 4.0, 0.7, out_n.y * 15.0 + along.z * 4.0), wall,
			along * 0.01],
		["clock", "midmorning", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0), Vector3.ZERO],
	]


func _capture(out_dir: String, only: PackedStringArray) -> void:
	if not OS.get_cmdline_user_args().has("--motion"):
		await super(out_dir, only)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	for run: Array in _runs():
		world.time = _run_time(MOMENTS[run[1]])
		world.time_warp = 1.0 if run[0] == "clock" else 0.0
		for i in 6:
			var eye := _engine(run[2] + run[4] * i)
			world.player.global_position = eye - _eye
			if i == 0:
				await _ground()
				for k in 20:
					await get_tree().physics_frame
				eye = _engine(run[2])
				world.player.global_position = eye - _eye
			var to := _engine(run[3] + run[4] * i) - eye
			world.player.rotation.y = atan2(-to.x, -to.z)
			world.player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())
			await get_tree().process_frame
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s_%d.png" % [run[0], i]))
	print("style: done")
	get_tree().quit()


## A world place, x and z, in the camp's frame.
func _camp(w: Vector2) -> Vector2:
	return (w - _middle).rotated(_yaw)
