extends "res://look/style/style.gd"
## Look-test: storm wear. A turbine, and a chassis with its solar panel behind
## it, fresh, after one storm and after many, in a row before the camp, each
## shot close and the row whole. The storms come from the camera's left and
## wear them through Device.wear as Wear does: one storm is twelve minutes
## of full storm, a third of a turbine's life; many is three, from headings
## up to 35 degrees apart. Then the GPU's frame time with the storms' damage
## shown and hidden, alternated, close on the worst of it. --only none skips
## the shots.
##   godot --path . --disable-vsync res://look/storm_wear/storm_wear.tscn -- --look grey --capture <dir>
## look/storm_wear/shoot.sh shoots it and builds the sheet.

## The row, camp frame: name, storms (each its heading off the first, degrees), and x.
const ROW := [["fresh", [], -1.8], ["one_storm", [0.0], 0.0], ["many_storms", [0.0, 35.0, -20.0], 1.8]]
const ROW_Z := 4.5
const STORM_MINUTES := 12.0
## Where the storms come from, camp frame: the camera's left front.
const FROM := Vector3(-0.8, 0.0, 0.6)
const GPU_FRAMES := 60
const GPU_ROUNDS := 15

var _worn: Array[Device] = []


func _dress() -> void:
	generator.stand(false)
	var turn := Basis(Vector3.UP, _yaw)
	for entry: Array in ROW:
		var turbine := Catalog.device(&"turbine")
		var deck := Catalog.device(&"chassis") as Chassis
		for each: Array in [[turbine, 0.0], [deck, -1.1]]:
			var body: Device = each[0]
			world.content.add_child(body)
			var at := _to_world(Vector3(entry[2], 0.0, ROW_Z + each[1]))
			body.global_transform = Transform3D(turn, Vector3(world.engine_x(at.x),
				world.height_at(at.x, at.y) - Finds.bounds(body).position.y, world.engine_z(at.y)))
			body.freeze = true
		var panel := Catalog.part(&"solar_panel")
		world.content.add_child(panel)
		Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, panel)
		for body: Device in [turbine, deck]:
			for heading: float in entry[1]:
				var from := turn * FROM.rotated(Vector3.UP, deg_to_rad(heading))
				body.wear(STORM_MINUTES / world.tuning.storm_wreck_minutes, from)
			_worn.append(body)
			print("  %-12s %-8s %.0f%% sound, makes %.0f%% of its rating" % [entry[0], body.label, body.durability * 100.0,
				body.efficiency() * 100.0])


func _shots() -> Array:
	var out := []
	for entry: Array in ROW:
		var x: float = entry[2]
		out.append([entry[0], "midmorning", Vector3(x - 0.55, 0.75, ROW_Z + 1.05), Vector3(x, 0.12, ROW_Z - 0.45)])
	out.append(["row", "midmorning", Vector3(-0.8, 2.2, ROW_Z + 5.0), Vector3(0.0, 0.9, ROW_Z - 0.5)])
	return out


func _capture(out_dir: String, only: PackedStringArray) -> void:
	await _gpu_cost()
	await super(out_dir, only)


## Close on the many storms' pair, their damage hidden and shown in turn.
func _gpu_cost() -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var x: float = ROW[-1][2]
	var eye := _engine(Vector3(x - 0.3, 0.7, ROW_Z + 0.75))
	world.player.global_position = eye - _eye
	await _ground()
	var to := _engine(Vector3(x, 0.1, ROW_Z - 0.6)) - eye
	world.player.rotation.y = atan2(-to.x, -to.z)
	world.player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())
	world.time = _run_time(MOMENTS.midmorning)
	var sums := {"hidden": 0.0, "shown": 0.0}
	var deltas: Array[float] = []
	for round in GPU_ROUNDS:
		var got := {}
		for look: String in ["hidden", "shown"]:
			for body in _worn:
				if look == "hidden":
					for child in body.get_children():
						if Paint.is_worn(child) or child == body.rotor:
							(child as GeometryInstance3D).set_instance_shader_parameter(&"blasted", Vector4.ZERO)
				else:
					body._show_blast()
			for i in 10:
				await get_tree().process_frame
			var sum := 0.0
			for i in GPU_FRAMES:
				await get_tree().process_frame
				sum += RenderingServer.viewport_get_measured_render_time_gpu(rid)
			got[look] = sum / GPU_FRAMES
			sums[look] += got[look]
		deltas.append(got.shown - got.hidden)
	deltas.sort()
	print("storm_wear: gpu %.3f ms hidden, %.3f ms shown; median delta %+.3f ms (%+.3f to %+.3f)%s"
		% [sums.hidden / GPU_ROUNDS, sums.shown / GPU_ROUNDS, deltas[floori(GPU_ROUNDS / 2.0)], deltas[0], deltas[-1],
			_shared_gpu()])
