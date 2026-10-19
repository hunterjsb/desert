extends MovementProbe
## Devices probe 12: rotate turns what you hold. Held down with a part in your
## hands, the mouse turns the part and not your view; let go, the mouse looks
## again. A condenser and a planter tipped on their sides, taken hold of, roll
## back upright with it and stand once let go; a shield generator lying on its
## side is picked up, turned upright and set down standing. Having hold of a
## condenser, looking up lifts it, unless it's too heavy for your strength.

const AHEAD := Vector2(1.0, 0.0)


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	Controls.free_mouse(false)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 6.0)
	await place(flat.x, flat.z, AHEAD)
	var quarter := PI / 2.0 / world.tuning.mouse_sensitivity

	var battery := Catalog.part(&"battery")
	world.content.add_child(battery)
	battery.global_position = player.camera.global_position - player.camera.global_basis.z * 0.5
	player.hands.hold(battery)
	await simulate(0.5)
	var view := Vector2(player.rotation.y, player.camera.rotation.x)
	var was := _in_view(battery)
	Input.action_press(&"hands_rotate")
	await _drag(Vector2(quarter, 0.0))
	var turned := rad_to_deg(was.get_rotation_quaternion().angle_to(_in_view(battery).get_rotation_quaternion()))
	var still := view == Vector2(player.rotation.y, player.camera.rotation.x)
	Input.action_release(&"hands_rotate")
	was = _in_view(battery)
	await _drag(Vector2(quarter * 0.5, 0.0))
	var looked := rad_to_deg(angle_difference(view.x, player.rotation.y))
	print("rotating, a held battery turned %.1f° and your view %s; let go, the mouse turned you %.1f°"
		% [turned, "held still" if still else "moved", looked])
	check(absf(turned - 90.0) < 1.0 and still, "rotating, the mouse turns what you hold, not your view")
	check(absf(looked + 45.0) < 1.0 and _in_view(battery).is_equal_approx(was), "let go, the mouse looks again")
	player.hands.drop()
	await simulate(1.0)

	for id: StringName in [&"condenser", &"planter"]:
		var tipped := _tipped(id)
		await simulate(1.5)
		_look_at(tipped)
		check(player.hands.grab() and player.hands.grasp.body == tipped, "you take hold of a tipped %s" % tipped.label)
		Input.action_press(&"hands_rotate")
		# Its top faces you: the near side comes up with the mouse.
		await _drag(Vector2(0.0, -quarter))
		await simulate(1.0)
		Input.action_release(&"hands_rotate")
		player.hands.grab()
		await simulate(3.0)
		var tilt := _tilt(tipped)
		print("a %s on its side, rolled a quarter turn and let go, stands %.1f° from upright, at %.2f rad/s"
			% [tipped.label, tilt, tipped.angular_velocity.length()])
		check(tilt < 3.0 and tipped.angular_velocity.length() < 0.05, "a %s rolled upright stays upright" % tipped.label)
		tipped.queue_free()

	var shield := _tipped(&"shield")
	await simulate(1.5)
	_look_at(shield)
	check(player.hands.grab() and player.hands.held == shield, "you pick up a shield generator lying on its side")
	await simulate(0.5)
	Input.action_press(&"hands_rotate")
	await _drag(Vector2(0.0, -quarter))
	Input.action_release(&"hands_rotate")
	player.hands.grab()
	await simulate(3.0)
	print("a shield generator picked up on its side, turned and put down, stands %.1f° from upright" % _tilt(shield))
	check(_tilt(shield) < 3.0, "a shield generator turned upright in your hands is set down standing")
	shield.queue_free()

	var rises := []
	for kg: float in [15.0, 60.0]:
		var heavy := _resting(&"condenser", 1.6, kg)
		await simulate(1.0)
		_look_at(heavy)
		check(player.hands.grab() and player.hands.grasp.body == heavy, "you take hold of a %d kg condenser" % kg)
		var low := heavy.global_position.y
		await _drag(Vector2(0.0, -quarter / 3.0))
		await simulate(2.0)
		rises.append(heavy.global_position.y - low)
		player.hands.grab()
		heavy.queue_free()
		_look_at(null)
	print("looking up 30°, a 15 kg condenser rose %.2f m and a 60 kg one %.2f m" % rises)
	check(rises[0] > 0.5, "looking up lifts a condenser you can take the weight of (%.2f m)" % rises[0])
	check(rises[1] < 0.05, "but not one too heavy for your strength (%.2f m)" % rises[1])


## The mouse moved `by` pixels over a second, a tick at a time.
func _drag(by: Vector2) -> void:
	var ticks := ticks_per_second()
	for i in ticks:
		var motion := InputEventMouseMotion.new()
		motion.relative = by / ticks
		get_viewport().push_input(motion)
		await simulate(1.0 / ticks)


## How a body is turned relative to your view's heading.
func _in_view(body: Node3D) -> Basis:
	return Basis(Vector3.UP, -player.rotation.y) * body.global_basis.orthonormalized()


## A catalog device lying on its side 1.6 m in front of you, its top toward you.
func _tipped(id: StringName) -> Device:
	var made := Catalog.device(id)
	world.content.add_child(made)
	made.global_transform = Transform3D(Basis(Vector3.UP, player.rotation.y) * Basis(Vector3.RIGHT, PI / 2.0),
		_before_you(1.6) + Vector3.UP * (Catalog.DEVICES[id].size.z * 0.5 + 0.02))
	return made


## A catalog device weighing `kg`, resting on the sand `ahead` m in front of you.
func _resting(id: StringName, ahead: float, kg: float) -> Device:
	var made := Catalog.device(id)
	made.frame_mass = kg
	world.content.add_child(made)
	made.global_position = _before_you(ahead) + Vector3.UP * (Catalog.DEVICES[id].size.y * 0.5 + 0.02)
	return made


func _before_you(ahead: float) -> Vector3:
	var at := player.global_position - player.global_basis.z * ahead
	at.y = world.height_under(at)
	return at


## Turns you to look at a body, or level along AHEAD with none.
func _look_at(body: Node3D) -> void:
	if body == null:
		face(AHEAD)
		player.camera.rotation.x = 0.0
		return
	var to := body.global_position - player.camera.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())


## How far a body leans from upright, degrees.
func _tilt(body: Node3D) -> float:
	return rad_to_deg(body.global_basis.y.normalized().angle_to(Vector3.UP))
