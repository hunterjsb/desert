extends RopeProbe
## Rope & tethering probe 3: a rope pulls both ends equally and oppositely, at
## the attachment points. Two cubes of very different weight, tied at
## off-centre rings and flung apart spinning in still air, keep their total
## momentum and angular momentum through every jerk of the line. And a stake
## holding a floater in a steady wind feels exactly the wind's load on it.

const LIGHT := 3.0
const HEAVY := 40.0
const SIDE := 0.6


func run() -> void:
	await load_ropes()
	set_rate(60)
	await _flung_apart()
	await _anchor_feels_the_load()


func _flung_apart() -> void:
	var middle := spot(0.0, 12.0) + Vector3.UP * 25.0
	var light := _cube(LIGHT, middle + Vector3(-1.5, 0.0, 0.0))
	var heavy := _cube(HEAVY, middle + Vector3(1.5, 0.3, 0.0))
	var ring_a := RopeEnd.make(light, Vector3(SIDE, SIDE, -SIDE) * 0.5)
	var ring_b := RopeEnd.make(heavy, Vector3(-SIDE, -SIDE, SIDE) * 0.5)
	await get_tree().physics_frame
	ropes.tie(ring_a, ring_b, ring_a.global_position.distance_to(ring_b.global_position) + 0.5)
	light.linear_velocity = Vector3(-6.0, 1.0, 2.0)
	light.angular_velocity = Vector3(1.0, -2.0, 0.5)
	heavy.linear_velocity = Vector3(1.0, -0.5, -1.0)
	heavy.angular_velocity = Vector3(0.0, 0.8, -0.6)
	await get_tree().physics_frame
	var bodies: Array[RigidBody3D] = [light, heavy]
	var p0 := _momentum(bodies)
	var l0 := _angular(bodies, middle)
	# Lambdas capture by value, so the worst cases are kept in a dictionary.
	var worst := {"p": 0.0, "l": 0.0, "pull": 0.0}
	await simulate(4.0, func() -> void:
		worst.p = maxf(worst.p, (_momentum(bodies) - p0).length())
		worst.l = maxf(worst.l, (_angular(bodies, middle) - l0).length())
		worst.pull = maxf(worst.pull, ropes.ropes[0].tension))
	var worst_p: float = worst.p
	var worst_l: float = worst.l
	var pulled: float = worst.pull
	print("peak pull %.0f N; momentum drift %.4f of %.2f; angular momentum drift %.4f of %.2f"
		% [pulled, worst_p, p0.length(), worst_l, l0.length()])
	check(pulled > 100.0, "the line jerked hard (%.0f N)" % pulled)
	check(worst_p < 0.001 * p0.length(), "total momentum is kept: equal and opposite")
	check(worst_l < 0.001 * l0.length(), "total angular momentum is kept: pulled at the attachment points")
	ropes.clear()
	light.free()
	heavy.free()


func _anchor_feels_the_load() -> void:
	blow(Vector2(18.0, 0.0))
	var floater := Props.floater(world, spot(7.0, 0.0))
	stake_line(spot(0.0, 0.0), floater, 0.5)
	var stake: Node3D = ropes.ropes[0].a.holder
	await simulate(10.0)
	var at := floater.global_position
	var past := world.weather.felt_wind(at) - floater.linear_velocity
	past.y = 0.0
	var load: Vector3 = past * past.length() * floater.get_meta(&"wind_catch")
	var held := flat(stake.pull)
	print("wind load on the floater %.1f N, the stake feels %.1f N, %.2f° apart"
		% [load.length(), held.length(), rad_to_deg(held.angle_to(load))])
	check(absf(held.length() - load.length()) < 0.01 * load.length(),
		"the stake feels the floater's whole wind load")
	check(held.angle_to(load) < deg_to_rad(1.0), "pulled the way the wind blows")


## A cube in still air: no drag, no damping, no gravity, nothing but the rope.
func _cube(mass: float, at: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * SIDE
	shape.shape = box
	body.add_child(shape)
	body.mass = mass
	body.inertia = Vector3.ONE * mass * SIDE * SIDE / 6.0
	body.gravity_scale = 0.0
	body.can_sleep = false
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	body.set_meta(&"wind_catch", 0.0)
	world.content.add_child(body)
	body.global_position = at
	return body


func _momentum(bodies: Array[RigidBody3D]) -> Vector3:
	var total := Vector3.ZERO
	for body in bodies:
		total += body.linear_velocity * body.mass
	return total


## About a fixed point. Cubes spin the same about any axis, so I·ω is exact.
func _angular(bodies: Array[RigidBody3D], about: Vector3) -> Vector3:
	var total := Vector3.ZERO
	for body in bodies:
		total += (body.global_position - about).cross(body.linear_velocity * body.mass) \
			+ body.angular_velocity * body.inertia.x
	return total
