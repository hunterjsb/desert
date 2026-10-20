extends "res://look/style/style.gd"
## Look-test: the paint pass. The art-direction camp as the game draws it,
## nothing drawn over it, with finds of each layer half-buried in front and
## the ruin's corner behind: shot before the pass and after, the same frames.
##   godot --path . --disable-vsync res://look/paint/paint.tscn -- --look grey --capture <dir> [--storm]
## --lineup shoots instead every frame and part in the catalog in rows behind the camp.

## Finds in the camp's frame: catalog id, layer, soundness, x, z, buried.
const LAID := [
	[&"chassis", &"surface", 0.4, -0.75, 2.55, 0.55],
	[&"chassis", &"deep", 0.95, 0.75, 2.7, 0.55],
	[&"battery", &"surface", 0.4, -0.35, 3.15, 0.0],
	[&"hook", &"deep", 0.95, 0.35, 3.2, 0.0],
]


func _dress() -> void:
	if OS.get_cmdline_user_args().has("--lineup"):
		_lineup()
		return
	for entry: Array in LAID:
		var at := _to_world(Vector3(entry[3], 0.0, entry[4]))
		var device: bool = Catalog.DEVICES.has(entry[0])
		var spec := {"id": entry[0], "device": device, "layer": entry[1], "sound": entry[2], "charge": 0.6,
			"x": at.x, "z": at.y, "yaw": _yaw + 0.5, "lean": 0.3, "lean_by": 0.15, "bury": entry[5], "fill": []}
		if device:
			# A battery stuck on its top, at its spot for one.
			spec.fill = [[Finds.holds(entry[0]).find(&"battery"), &"battery", 0.6]]
		var body := Finds.make(spec)
		var pose := Finds.pose(body, spec, world.height_at)
		world.content.add_child(body)
		body.global_transform = Transform3D(pose.basis, Vector3(world.engine_x(pose.origin.x), pose.origin.y,
			world.engine_z(pose.origin.z)))
		body.freeze = true
		if body is Device:
			Finds.age(body, spec.sound)


## Every frame, then every part on its back, in rows behind the camp.
func _lineup() -> void:
	var ids: Array = Catalog.DEVICES.keys() + [&"stake"]
	for i in ids.size():
		var device: Device = Catalog.stake() if ids[i] == &"stake" else Catalog.device(ids[i])
		_set_down(device, Vector3(-2.6 + (i % 6) * 1.05, 0.0, -6.0 - (i / 6) * 1.6), 0.4)
	var parts: Array = Catalog.PARTS.keys()
	for i in parts.size():
		_set_down(Catalog.part(parts[i]), Vector3(-2.4 + (i % 9) * 0.6, 0.0, -3.6 - (i / 9) * 0.6), 0.3, true)


func _set_down(body: RigidBody3D, at: Vector3, turn: float, on_back := false) -> void:
	world.content.add_child(body)
	var box := Finds.bounds(body)
	var lie := Basis(Vector3.UP, _yaw + PI + turn) * (Basis(Vector3.RIGHT, -PI / 2.0) if on_back else Basis.IDENTITY)
	var low := INF
	for k in 8:
		low = minf(low, (lie * box.get_endpoint(k)).y)
	body.global_transform = Transform3D(lie, _engine(at) - Vector3.UP * (low - 0.02))
	body.freeze = true


func _shots() -> Array:
	if OS.get_cmdline_user_args().has("--lineup"):
		return [["lineup_devices", "midmorning", Vector3(0.0, 1.9, -2.6), Vector3(0.0, 0.2, -6.8)],
			["lineup_parts", "midmorning", Vector3(0.0, 1.3, -1.4), Vector3(0.0, 0.0, -3.9)]]
	var corner := ruin.to_world(Vector2(Ruin.HALF))
	var c := (corner - _middle).rotated(_yaw)
	var away := -c.normalized()
	var eye := Vector3(c.x + away.x * 7.0 + away.y * 2.5, 1.7, c.y + away.y * 7.0 - away.x * 2.5)
	return [
		["camp8_morning", "morning", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0)],
		["camp8_noon", "noon", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0)],
		["camp8_dusk", "dusk", Vector3(1.6, 1.7, 8.0), Vector3(0.0, 0.5, 0.0)],
		["floater", "midmorning", Vector3(-2.5, 1.12, 2.05), Vector3(-1.9, 1.08, 0.6)],
		["floater5", "midmorning", Vector3(-3.65, 1.7, 5.3), Vector3(-1.9, 1.1, 0.6)],
		["finds", "midmorning", Vector3(0.0, 0.75, 3.95), Vector3(0.0, 0.05, 2.85)],
		["ruin_noon", "noon", eye, Vector3(c.x, 1.4, c.y)],
		["ruin_dusk", "dusk", eye, Vector3(c.x, 1.4, c.y)],
		["storm", "storm", Vector3(0.9, 1.7, 5.2), Vector3(0.0, 0.5, 0.0)],
	]
