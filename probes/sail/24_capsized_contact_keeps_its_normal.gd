extends SailProbe
## A capsized mast meets the sand as a real hinged assembly. Friction must
## not undo the same contact's normal support.

func run() -> void:
	await load_sailing()
	rig(open, heading())
	blow(Vector2.ZERO)
	hoist(60.0)
	await simulate(0.2)
	deck.freeze = true
	mast._boom_body.freeze = true
	deck.set_physics_process(false)
	mast.set_physics_process(false)
	var previous := deck.global_transform
	deck.global_transform = Transform3D(Basis(Vector3.FORWARD, deg_to_rad(100.0)), open + Vector3.UP * 3.0)
	mast._boom_body.global_transform = deck.global_transform * previous.affine_inverse() * mast._boom_body.global_transform
	var point := mast.global_transform * Vector3(0.0, Mast.BOOM_AT.y + Mast.LUFF * mast.extend, 0.0)
	var shift := Vector3.UP * (world.height_under(point) - point.y - 0.03)
	deck.global_position += shift
	mast._boom_body.global_position += shift
	await physics_frames(3)
	deck.freeze = false
	mast._boom_body.freeze = false
	await physics_frames(1)
	point = mast.global_transform * Vector3(0.0, Mast.BOOM_AT.y + Mast.LUFF * mast.extend, 0.0)
	shift = Vector3.UP * (world.height_under(point) - point.y - 0.03)
	deck.global_position += shift
	mast._boom_body.global_position += shift
	PhysicsServer3D.body_set_state(deck.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, deck.global_transform)
	PhysicsServer3D.body_set_state(mast._boom_body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, mast._boom_body.global_transform)
	var state := PhysicsServer3D.body_get_direct_state(deck.get_rid())
	var boom_state := PhysicsServer3D.body_get_direct_state(mast._boom_body.get_rid())
	var center := deck.global_transform * state.center_of_mass_local
	var boom_center := mast._boom_body.global_transform * boom_state.center_of_mass_local
	var velocity := Vector3(4.0, -3.0, -2.0)
	var spin := Vector3.ZERO
	deck.linear_velocity = velocity
	deck.angular_velocity = spin
	mast._boom_body.linear_velocity = velocity + spin.cross(boom_center - center)
	mast._boom_body.angular_velocity = spin
	point = mast.global_transform * Vector3(0.0, Mast.BOOM_AT.y + Mast.LUFF * mast.extend, 0.0)
	var gap := point.y - world.height_under(point)
	var before := at_point(point)
	var native_before := state.linear_velocity
	Runners.touch(deck, world, point, 0.6, 1.0 / 60.0)
	var after := at_point(point)
	var impulse := (state.linear_velocity - native_before) * deck.mass
	print("capsized mast contact: gap %.4f m, normal %.3f -> %.3f m/s" % [gap, before.y, after.y])
	check(gap < 0.0 and before.y < 0.0, "real masthead arrives in sand")
	check(absf(after.y - Runners.TOUCH_SPEED) < 0.01, "friction preserves the contact's normal recovery")
	check(impulse.y >= 0.0 and Vector2(impulse.x, impulse.z).length() <= 0.6 * impulse.y + 0.001, "ground contact pushes within its friction cone")

func at_point(point: Vector3) -> Vector3:
	var model := RopeArticulation.native(deck)
	var body := model.bodies[0]
	return body.velocity + body.spin.cross(point - body.center) + Vector3.DOWN * world.gravity / 60.0
