extends MovementProbe
## Movement probe 21: auto-walk. Turned on, it walks you on the way you faced
## at exactly the pace holding move forward does, and holds that way while the
## view turns right round. A move key held as it began is let go without
## ending it; the next one ends it. Walking into a wall ends it, and so does
## walking up a face too steep to stand on: you stop and stand.


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 10.0)
	var ahead := Vector2(0.6, 0.8)

	await place(flat.x, flat.z, ahead)
	var from := where()
	hold(["move_forward"])
	await simulate(3.0)
	var walked := _along(from, ahead)
	var pace := player.own.length()
	await place(flat.x, flat.z, ahead)
	from = where()
	_press(&"auto_walk")
	await simulate(3.0)
	var auto := _along(from, ahead)
	print("3 s from rest: %.4f m walking, %.4f m on auto-walk; %.3f and %.3f m/s" % [walked, auto,
		pace, player.own.length()])
	check(absf(auto - walked) < 0.001 and absf(player.own.length() - pace) < 0.001 and player.mode == "walk",
		"auto-walk is your walk: as far and as fast (%.4f m against %.4f)" % [auto, walked])
	_press(&"auto_walk")
	check(not player.walker.is_on(), "pressed again, it's off")

	await place(flat.x, flat.z, ahead)
	from = where()
	_press(&"auto_walk")
	await simulate(3.0, func() -> void:
		player.rotate_y(1.25 * TAU / ticks_per_second() / 3.0)
		player.camera.rotation.x = 0.4)
	var went := Vector2(where().x - from.x, where().z - from.z)
	var off := rad_to_deg(absf(went.angle_to(ahead)))
	print("the view turned 450° over 3 s: %.2f m walked, %.3f° off the way" % [went.length(), off])
	check(player.walker.is_on() and off < 0.5 and went.length() > walked * 0.9,
		"it holds its way while the view turns round (%.3f° off)" % off)
	player.camera.rotation.x = 0.0
	_press(&"auto_walk")

	await place(flat.x, flat.z, ahead)
	hold(["move_forward"])
	await simulate(0.5)
	_press(&"auto_walk")
	await simulate(0.5)
	hold([])
	await simulate(1.0)
	check(player.walker.is_on() and player.mode == "walk", "letting go of the key held as it began keeps it on")
	hold(["move_left"])
	await simulate(1.0 / ticks_per_second())
	hold([])
	await simulate(1.0)
	check(not player.walker.is_on() and player.mode == "stand", "a move of your own ends it")

	await place(flat.x, flat.z, ahead)
	var wall := _wall(ahead, 2.5)
	_press(&"auto_walk")
	await simulate(3.0)
	from = where()
	await simulate(1.0)
	var crept := Vector2(where().x - from.x, where().z - from.z).length()
	print("into a wall 2.5 m ahead: on %s, %.4f m in the last second" % [player.walker.is_on(), crept])
	check(not player.walker.is_on() and crept < 0.01 and player.mode == "stand",
		"walking into a wall ends it (%.4f m on)" % crept)
	wall.queue_free()

	var face := slope_between(flat.x, flat.z, 250.0, world.tuning.slip_angle + 2.0, 40.0, 4.0)
	check(not face.is_empty(), "a slip face near spawn")
	if face.is_empty():
		return
	var down: Vector2 = face.downhill
	var foot := _foot(face)
	await place(foot.x, foot.y, -down)
	from = where()
	_press(&"auto_walk")
	var seen := {"t": 0.0, "climbed": 0.0}
	await simulate(8.0, func() -> void:
		if player.walker.is_on():
			seen.t += 1.0 / ticks_per_second()
			seen.climbed = _along(from, -down))
	var past := Vector2(where().x - face.x, where().z - face.z).dot(-down)
	print("up a %.1f° face from %.1f m below it: walked %.2f s and %.2f m up, stopped %.2f m below its steepest, %s"
		% [face.degrees, (foot - Vector2(face.x, face.z)).length(), seen.t, seen.climbed, -past, player.mode])
	check(seen.climbed > 1.0 and not player.walker.is_on() and past < 0.5 and player.mode == "stand",
		"walking up to a face too steep to stand on ends it, and you stand below it (%.2f m past)" % past)
	set_rate(60)


## Metres from `from` along a world direction.
func _along(from: Vector3, way: Vector2) -> float:
	return Vector2(where().x - from.x, where().z - from.z).dot(way)


## Clear of a slip face's foot downhill: a few metres on from where it eases under 18°.
func _foot(face: Dictionary) -> Vector2:
	var at := Vector2(face.x, face.z)
	for i in 60:
		if degrees(gradient(at.x, at.y)) < 18.0:
			break
		at += face.downhill
	return at + face.downhill * 3.0


## The action's key down and up, as a player taps it.
func _press(action: StringName) -> void:
	var key: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	key.pressed = true
	get_viewport().push_input(key)
	key = key.duplicate()
	key.pressed = false
	get_viewport().push_input(key)


## A solid wall `metres` ahead along a world direction, across it.
func _wall(way: Vector2, metres: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	var holder := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 3.0, 0.5)
	holder.shape = box
	body.add_child(holder)
	world.content.add_child(body)
	var at := player.global_position + Vector3(way.x, 0.0, way.y) * metres
	body.global_transform = Transform3D(Basis(Vector3.UP, atan2(-way.x, -way.y)), at + Vector3.UP * 1.0)
	return body
