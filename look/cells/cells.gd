extends "res://look/paint/paint.gd"
## Look-test: the commodity parts (CellLooks). Each in the five looks a
## lineage gives it, laid on the sand in front of the camp and shot from about
## a metre at midmorning and dusk, and through a narrow lens; the camp with
## them seated (cells on the decks, a lamp, a canister on a hose, a cable and a
## strong cable) at 5 m and 2 m, and under its bubble in a storm.
##   scripts/unseen.sh --path . --disable-vsync res://look/cells/cells.tscn -- --look grey --capture <dir> [--storm]
## look/cells/shoot.sh shoots both runs and builds the sheets.

const IDS: Array[StringName] = [&"battery", &"big_battery", &"plug", &"strong_plug", &"hose_end", &"hook", &"canister",
	&"lamp"]
const LINES := [
	["issued", []],
	["colonial", [[Eras.COLONIAL, &"made", [&"tilg"]]]],
	["first", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"haberjack"]]]],
	["skimmer", [[Eras.SKIMMER, &"made", []]]],
	["second", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"pellicott"]],
		[Eras.DARK, &"remade", [&"wood", &"cord", &"ceramic"]], [Eras.SECOND, &"blessed", [&"tu", &"charm"]]]],
]
## Each id's row, camp frame: two columns, four rows, well in front of the camp.
const ROW_Z := 10.0
const ROW_STEP := 1.3
const COLUMN_X := 1.7
## The cells lie face up; the rest on their side, shown in profile.
const FACE_UP: Array[StringName] = [&"battery", &"big_battery"]
## The detail shots' lens, degrees: about twice the eye's reach.
const CLOSE_FOV := 40.0


func _dress() -> void:
	for i in IDS.size():
		var middle := _row(i)
		for k in LINES.size():
			var part := Catalog.part(IDS[i])
			Catalog.inherit(part, LINES[k][1])
			var up := FACE_UP.has(IDS[i])
			_set_down(part, Vector3(middle.x + (k - 2) * _gap(IDS[i]), 0.0, middle.y), 0.35 if up else -PI / 2.0 + 0.3, up)
	_seat()


## The row of the i-th id, camp frame (x, z).
func _row(i: int) -> Vector2:
	return Vector2(-COLUMN_X + (i % 2) * COLUMN_X * 2.0, ROW_Z + (i / 2) * ROW_STEP)


## How far apart an id's copies lie: its width face up, its length on its side;
## a hook's ring reaches past its box.
func _gap(id: StringName) -> float:
	var size: Vector3 = Catalog.PARTS[id].size
	return (size.x + 0.1) if FACE_UP.has(id) else (0.3 if id == &"hook" else size.z + 0.08)


## The camp's gear seated: a lamp and a big battery on the decks, a condenser
## watering the planter by hose with its canister on the hose's end, a cable
## from the planter to the condenser, a turbine on its big battery and a
## strong cable from it to the shield.
func _seat() -> void:
	var decks := camp.filter(func(d: Device) -> bool: return d is Chassis)
	var planter: Device = camp.filter(func(d: Device) -> bool: return d is Planter)[0]
	var store := decks[1] as Chassis
	Stick.put(store, store, Chassis.TOP, ON_TOP[2], 0.4, _loose(&"lamp"))
	var plate := decks[2] as Chassis
	Stick.put(plate, plate, Chassis.TOP, Vector2(-0.3, 0.3), 0.2, _loose(&"big_battery"))
	var condenser := _stand(&"condenser", Vector3(3.4, 0.0, -0.7), -20.0)
	Scenarios.plumb(world, condenser, planter)
	condenser.fit(_loose(&"canister"), Scenarios._free(condenser, &"water"))
	Scenarios.wire(world, planter, condenser)
	var turbine := _stand(&"turbine", Vector3(-1.2, 0.0, -2.6), 15.0)
	turbine.fit(_loose(&"big_battery"), Scenarios._free(turbine, &"battery"))
	Scenarios.wire(world, turbine, generator, true)


func _loose(id: StringName) -> Part:
	var part := Catalog.part(id)
	world.content.add_child(part)
	return part


func _stand(id: StringName, at: Vector3, yaw: float) -> Device:
	var device := Catalog.device(id)
	world.content.add_child(device)
	var size: Vector3 = Catalog.DEVICES[id].size
	device.global_transform = Transform3D(Basis(Vector3.UP, _yaw + deg_to_rad(yaw)), _engine(at + Vector3.UP * (size.y * 0.5 + 0.02)))
	device.freeze = true
	camp.append(device)
	return device


func _shots() -> Array:
	var out := []
	# Each row from a metre or so, then through a narrow lens for its detail.
	for shot in [["midmorning", 0.75, 0.15], ["dusk", 0.75, 0.15], ["close", 0.8, 0.0]]:
		for i in IDS.size():
			# On its side a part's middle is half its length from its socket's.
			var row := _row(i) + Vector2(0.0 if FACE_UP.has(IDS[i]) else Catalog.PARTS[IDS[i]].size.z * 0.45, 0.0)
			var d: float = _gap(IDS[i]) * 5.0 * shot[1] + shot[2]
			out.append(["%s_%s" % [IDS[i], shot[0]], "midmorning" if shot[0] == "close" else shot[0],
				Vector3(row.x + 0.05, d * 0.5 + 0.1, row.y + d * 0.9), Vector3(row.x, 0.04, row.y - 0.05)])
	out.append(["camp5", "midmorning", Vector3(1.4, 1.7, 4.6), Vector3(-0.3, 0.35, -0.5)])
	out.append(["camp5_dusk", "dusk", Vector3(1.4, 1.7, 4.6), Vector3(-0.3, 0.35, -0.5)])
	out.append(["camp5_side", "midmorning", Vector3(4.6, 1.5, 2.6), Vector3(1.6, 0.3, -0.4)])
	out.append(["camp2", "midmorning", Vector3(1.7, 1.3, 1.1), Vector3(0.5, 0.25, -0.8)])
	out.append(["bubble5", "storm", Vector3(1.4, 1.7, 4.6), Vector3(-0.3, 0.35, -0.5)])
	out.append(["bubble2", "storm", Vector3(1.7, 1.3, 1.1), Vector3(0.5, 0.25, -0.8)])
	return out


## Each shot from a camera of its own at exactly the asked place: the eye
## eases and springs after the body, and close up that misses a 6 cm plug.
func _capture(out_dir: String, only: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var lens := Camera3D.new()
	lens.fov = world.player.camera.fov
	lens.near = 0.02
	add_child(lens)
	lens.current = true
	world.player.visible = false
	var storm_at := world.time
	for shot: Array in _shots():
		if (shot[1] == "storm") != storm or (not only.is_empty() and not only.has(shot[0])):
			continue
		var cell := generator.host().battery()
		cell.charge_wh = cell.capacity()
		world.player.global_position = _engine(shot[2]) - _eye
		await _ground()
		if storm:
			world.time = storm_at - 1.6
			world.time_warp = 1.0
			await get_tree().create_timer(0.8).timeout
		else:
			world.time = _run_time(MOMENTS[shot[1]])
			world.time_warp = 0.0
			for i in 20:
				await get_tree().physics_frame
		var eye := _engine(shot[2])
		lens.fov = CLOSE_FOV if (shot[0] as String).ends_with("_close") else world.player.camera.fov
		lens.global_transform = Transform3D(Basis.looking_at(_engine(shot[3]) - eye), eye)
		for i in 12:
			await get_tree().process_frame
		var calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(shot[0] + ".png"))
		print("  %-22s draws %5d" % [shot[0], calls])
	print("style: done")
	get_tree().quit()
