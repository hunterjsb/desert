extends Probe
## Omitting the zero native external step must leave ordinary predicted rope motion intact.
func run() -> void:
	var complete := _model()
	var native_only := _model()
	complete.project_velocities()
	native_only.project_velocities(false)
	for i in complete.bodies.size():
		var a := complete.bodies[i]
		var b := native_only.bodies[i]
		check(a.velocity == b.velocity and a.spin == b.spin and a.expected == Vector3.ZERO
			and a.expected_spin == Vector3.ZERO and b.expected == a.expected and b.expected_spin == a.expected_spin,
			"zero external terms leave exactly the same projected actual velocities")
	var ordinary := _model()
	ordinary.bodies[0].expected = Vector3(0.7, -0.2, 0.3)
	ordinary.bodies[0].expected_spin = Vector3(0.1, 0.2, -0.3)
	ordinary.bodies[1].expected = Vector3(-0.3, 0.9, -0.4)
	ordinary.bodies[1].expected_spin = Vector3(-0.2, 0.8, 0.4)
	var before := _momentum(ordinary)
	ordinary.project_velocities()
	var after := _momentum(ordinary)
	var pivot := Vector3(0, 1, 0)
	var carrier := ordinary.bodies[0]
	var boom := ordinary.bodies[1]
	var root_at := carrier.expected + carrier.expected_spin.cross(pivot - carrier.center)
	var boom_at := boom.expected + boom.expected_spin.cross(pivot - boom.center)
	check((before[0] - after[0]).length() < 0.00001 and (before[1] - after[1]).length() < 0.00001
		and root_at.distance_to(boom_at) < 0.00001
		and (boom.expected_spin - carrier.expected_spin).slide(Vector3.UP).length() < 0.00001
		and boom.expected.length() > 0.01, "ordinary nonzero external motion conserves momentum and obeys the real hinge")
	for model in [complete, native_only, ordinary]:
		for body in model.bodies:
			body.rigid.free()

func _model() -> RopeArticulation:
	var root := _body(6.0, Vector3.ZERO, Vector3(2, 3, 4))
	var boom := _body(2.0, Vector3(0, 1, 2), Vector3(1, 2, 3))
	root.velocity = Vector3(0.5, 0.2, -0.3)
	root.spin = Vector3(-0.1, 0.2, 0.3)
	boom.velocity = Vector3(0.2, -0.5, 0.8)
	boom.spin = Vector3(0.4, -0.6, 0.1)
	var model := RopeArticulation.new()
	model.configure([root, boom], [Vector3(0, 1, 0)], [Vector3.UP])
	return model

func _body(mass: float, center: Vector3, inertia: Vector3) -> RopeBody:
	var body := RopeBody.new()
	body.rigid = RigidBody3D.new()
	body.rigid.mass = mass
	body.center = center
	body.inv_mass = Vector3.ONE / mass
	body.inv_inertia = Basis.from_scale(Vector3.ONE / inertia)
	return body

func _momentum(model: RopeArticulation) -> Array[Vector3]:
	var linear := Vector3.ZERO
	var angular := Vector3.ZERO
	for body in model.bodies:
		var impulse := body.expected * body.rigid.mass
		linear += impulse
		angular += body.inv_inertia.inverse() * body.expected_spin + (body.center - model.center).cross(impulse)
	return [linear, angular]
