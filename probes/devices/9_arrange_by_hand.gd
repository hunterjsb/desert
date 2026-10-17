extends MovementProbe
## Devices probe 9: you arrange a camp by hand. Walk into a floating device and
## it goes on ahead of you, never faster than you push it. Take hold of one too
## heavy to carry and it follows as you back away and turns round with you;
## let go and it stops rather than flies. One too heavy to drag on the sand
## barely moves, and slips from your hands as you walk off.

const AHEAD := Vector2(1.0, 0.0)


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var t := world.tuning
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 6.0)
	await place(flat.x, flat.z, AHEAD)

	var planter := _floating(&"planter", 1.3)
	await simulate(1.0)
	var from := planter.global_position
	var seen := {"fastest": 0.0}
	var watch := func() -> void:
		seen.fastest = maxf(seen.fastest, Vector2(planter.linear_velocity.x, planter.linear_velocity.z).length())
	hold(["move_forward"])
	await simulate(3.0, watch)
	hold([])
	var pushed := (planter.global_position - from).x
	print("walking into a floating planter pushed it %.2f m, at most %.2f m/s" % [pushed, seen.fastest])
	check(pushed > 2.5, "walking into a floating device pushes it along (%.2f m)" % pushed)
	check(seen.fastest < t.walk_speed + 0.5, "no faster than you walk (%.2f m/s)" % seen.fastest)

	await simulate(1.0)
	_look_at(planter)
	check(player.hands.grab() and player.hands.grasp.body == planter, "you take hold of a device too heavy to carry")
	from = planter.global_position
	seen.fastest = 0.0
	hold(["move_back"])
	await simulate(3.0, watch)
	hold([])
	var followed := (from - planter.global_position).x
	var swing_from := _bearing(planter)
	for i in 60:
		player.rotation.y += PI / 2.0 / 60.0
		await simulate(1.0 / 60.0)
	await simulate(1.0)
	var swung := rad_to_deg(absf(angle_difference(swing_from, _bearing(planter))))
	print("held, it followed %.2f m as you backed away, at most %.2f m/s, and swung %.0f° as you turned"
		% [followed, seen.fastest, swung])
	check(followed > 2.0, "held, it follows as you back away (%.2f m)" % followed)
	check(swung > 70.0, "and swings round as you turn (%.0f°)" % swung)
	check(player.hands.grab() and player.hands.grasp.body == null, "taking again lets go")
	await simulate(1.5)
	var after := Vector2(planter.linear_velocity.x, planter.linear_velocity.z).length()
	check(seen.fastest < t.walk_speed + t.hold_speed and after < 0.5,
		"nothing is flung: at most %.2f m/s as you walk it, %.2f m/s after" % [seen.fastest, after])

	var crate := _resting(&"crate_frame", 1.6, 200.0)
	await simulate(1.0)
	_look_at(crate)
	check(player.hands.grab() and player.hands.grasp.body == crate, "you take hold of a heavy crate on the sand")
	from = crate.global_position
	hold(["move_back"])
	await simulate(3.0)
	hold([])
	var dragged := (crate.global_position - from).length()
	print("a 200 kg crate on the sand moved %.2f m; your grip %s" % [dragged,
		"held" if player.hands.grasp.body != null else "slipped"])
	check(dragged < 0.5 and player.hands.grasp.body == null,
		"one too heavy to drag barely moves (%.2f m) and slips from your hands" % dragged)


## A catalog device floating on its tray `ahead` m in front of you, battery in.
func _floating(id: StringName, ahead: float) -> Device:
	var made := Catalog.device(id)
	world.content.add_child(made)
	made.global_position = _before_you(ahead) + Vector3.UP * world.tuning.hover_height
	for socket in made.sockets():
		var fill: Variant = {&"battery": &"battery", &"bottom": &"hover_tray"}.get(socket.kind)
		if fill != null:
			var part := Catalog.part(fill)
			world.content.add_child(part)
			made.fit(part, socket)
	made.global_position.y += made.rest_height() - world.tuning.hover_height
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


func _look_at(body: Node3D) -> void:
	var to := body.global_position - player.camera.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())


## Which way it lies from you, flat, rad.
func _bearing(body: Node3D) -> float:
	var to := body.global_position - player.global_position
	return atan2(to.x, to.z)
