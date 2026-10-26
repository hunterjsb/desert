extends "res://look/style/style.gd"
## Look-test: the shield by era (art direction, "Shape by era"). A row on the
## sand before the camp: the company's issue, a colonial find, a skimmer-era
## one, a First Kingdoms house's and a second-age remake of a house's, then the
## light shield; another light
## shield stands on the floating deck, and a third is carried in your own view.
## The camp's bubble is down for the row unless --bubble; --storm shoots inside
## it in a storm, every shield running.
##   godot --path . --disable-vsync res://look/shield/eras.tscn -- --look grey --capture <dir> [--bubble] [--storm]
## look/shield/shoot.sh shoots it and builds the sheet.

## The row, camp frame: name, catalog id, lineage (none: the company's), x.
const ROW := [
	["issued", &"shield", [], -3.0],
	["colonial", &"shield", [[Eras.COLONIAL, &"made", [&"rmc"]]], -1.8],
	["skimmer", &"shield", [[Eras.SKIMMER, &"made", []]], -0.6],
	["first", &"shield", [[Eras.COLONIAL, &"made", [&"rmc"]], [Eras.FIRST, &"marked", [&"haberjack"]]], 0.6],
	["second", &"shield", [[Eras.COLONIAL, &"made", [&"rmc"]], [Eras.FIRST, &"marked", [&"pellicott"]],
		[Eras.DARK, &"remade", [&"cord", &"ceramic"]], [Eras.SECOND, &"blessed", [&"tu"]]], 1.8],
	["light", &"light_shield", [], 3.0],
]
const ROW_Z := 3.0

var _row: Array[ShieldGenerator] = []
var _deck_light: ShieldGenerator


func _dress() -> void:
	var args := OS.get_cmdline_user_args()
	generator.stand(storm or args.has("--bubble"))
	# The aim dot and its line, which the hands show again every frame: off screen.
	world.player.hands._hud.offset = Vector2(1e5, 1e5)
	for entry: Array in ROW:
		var made := Catalog.device(entry[1]) as ShieldGenerator
		Catalog.inherit(made, entry[2])
		var at := _to_world(Vector3(entry[3], 0.0, ROW_Z))
		world.content.add_child(made)
		var low := Finds.bounds(made).position.y
		made.global_transform = Transform3D(Basis(Vector3.UP, _yaw - 0.55),
			Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) - low, world.engine_z(at.y)))
		made.freeze = true
		_row.append(made)
		var look: ArrayMesh = made.frame_view.mesh
		var tris := 0
		for s in look.get_surface_count():
			var index := look.surface_get_array_index_len(s)
			tris += (index if index > 0 else look.surface_get_array_len(s)) / 3
		print("  %-10s %s: %d triangles in %d surfaces" % [entry[0], entry[1], tris, look.get_surface_count()])
	# Where the Surveyor's starts: on the floating deck beside its battery.
	_deck_light = Catalog.device(&"light_shield") as ShieldGenerator
	world.content.add_child(_deck_light)
	Stick.put(camp[0], camp[0], Chassis.TOP, ON_TOP[1], 0.4, _deck_light)
	if storm:
		_deck_light.stand(true)


## The light shield in your hands first, looking a little down over the camp;
## then the rest.
func _capture(out_dir: String, only: PackedStringArray) -> void:
	if not storm and (only.is_empty() or only.has("light_carried")):
		DirAccess.make_dir_recursive_absolute(out_dir)
		var held := Catalog.device(&"light_shield")
		world.content.add_child(held)
		var eye := _engine(Vector3(1.4, 1.65, 5.6))
		world.player.global_position = eye - _eye
		await _ground()
		world.player.global_position = _engine(Vector3(1.4, 1.65, 5.6)) - _eye
		held.global_position = world.player.global_position + Vector3.UP
		var to := _engine(Vector3.ZERO) - eye
		world.player.rotation.y = atan2(-to.x, -to.z)
		world.player.camera.rotation_degrees.x = -40.0
		world.time = _run_time(MOMENTS.midmorning)
		world.time_warp = 0.0
		world.player.hands.hold(held)
		for i in 60:
			await get_tree().physics_frame
		for i in 6:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("light_carried.png"))
		print("  %-18s held" % "light_carried")
		world.player.hands.drop()
		held.queue_free()
		for i in 4:
			await get_tree().physics_frame
	await super(out_dir, only)


func _shots() -> Array:
	var out := [
		["eras_5m", "midmorning", Vector3(0.0, 1.7, ROW_Z + 5.0), Vector3(0.0, 0.2, ROW_Z)],
		["eras_close", "midmorning", Vector3(0.0, 1.1, ROW_Z + 3.0), Vector3(0.0, 0.15, ROW_Z)],
		["eras_dusk", "dusk", Vector3(0.0, 1.7, ROW_Z + 5.0), Vector3(0.0, 0.2, ROW_Z)],
		["eras_morning", "morning", Vector3(0.0, 1.7, ROW_Z + 5.0), Vector3(0.0, 0.2, ROW_Z)],
		["camp20", "midmorning", Vector3(7.0, 2.6, 19.0), Vector3(0.0, 0.5, 0.0)],
		["light_placed", "midmorning", Vector3(-1.4, 1.4, 1.5), Vector3(-1.85, 0.95, 0.45)],
		["storm_in", "storm", Vector3(1.0, 1.5, ROW_Z + 1.9), Vector3(0.1, 0.3, 1.2)],
		["storm_light", "storm", Vector3(-0.7, 1.35, 2.6), Vector3(-1.85, 0.85, 0.45)],
	]
	for entry: Array in ROW:
		var x: float = entry[3]
		out.append([entry[0] + "_close", "midmorning", Vector3(x + 0.2, 0.62, ROW_Z + 0.8), Vector3(x, 0.17, ROW_Z)])
		out.append([entry[0] + "_back", "midmorning", Vector3(x - 0.25, 0.65, ROW_Z - 0.8), Vector3(x, 0.17, ROW_Z)])
	return out
