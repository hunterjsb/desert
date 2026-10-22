class_name RopeArticulation
extends RefCounted
## The instantaneous mass response of a carrier and its freely hinged booms.
## Jolt owns the real joints. This projects the rope's virtual velocity step
## through those same DOFs, so it cannot credit motion the hinge will block.

var bodies: Array[RopeBody] = []
var axes: Array[Vector3] = []
var tangents: Array[Vector3] = []
var masses: PackedFloat64Array
var center := Vector3.ZERO
var total := 0.0
var inverse: Array[PackedFloat64Array] = []
var _mobility: Array[Basis] = []


## Each carrier's configured assembly this tick: [root origin, model or null].
## Geometry and masses hold within a tick, while every contact changes
## velocities, so a reused model only re-reads them.
static var _kept := {}
static var _frame := -1


## A native snapshot, including untethered craft: runner support must not
## change when the last rope is untied.
static func native(root: Device) -> RopeArticulation:
	if root == null or root.freeze:
		return null
	if _frame != Engine.get_physics_frames():
		_frame = Engine.get_physics_frames()
		_kept.clear()
	var id := root.get_instance_id()
	var kept: Array = _kept.get(id, [])
	if not kept.is_empty() and kept[0] == root.global_position \
			and (kept[1] == null or (kept[1] as RopeArticulation)._live()):
		var reused: RopeArticulation = kept[1]
		if reused != null:
			reused._read_velocities()
		return reused
	var model := _snapshot(root)
	_kept[id] = [root.global_position, model]
	return model


## A boom made or freed mid-tick changes its carrier's assembly at once.
static func forget(root: Device) -> void:
	if root != null:
		_kept.erase(root.get_instance_id())


## A carrier's free booms: [bodies, hinge pivots, hinge axes], world frame.
static func hinges(root: Device) -> Array:
	var booms: Array[RigidBody3D] = []
	var pivots: Array[Vector3] = []
	var along: Array[Vector3] = []
	var mounted: Array[Device] = [root]
	while not mounted.is_empty():
		var device: Device = mounted.pop_back()
		mounted.append_array(device.mounted())
		var mast := device as Mast
		if mast != null and is_instance_valid(mast.boom_body()) and not mast.boom_body().freeze:
			booms.append(mast.boom_body())
			pivots.append(mast.global_transform * Mast.BOOM_AT)
			along.append(mast.global_basis.y.normalized())
	return [booms, pivots, along]


## Custom inertia set this tick precedes the native cache, which lags a tick.
static func inverse_inertia(rigid: RigidBody3D) -> Basis:
	if rigid.inertia == Vector3.ZERO:
		return PhysicsServer3D.body_get_direct_state(rigid.get_rid()).inverse_inertia_tensor
	var turn := rigid.global_basis.orthonormalized()
	return turn * Basis.from_scale(Vector3.ONE / rigid.inertia) * turn.transposed()


static func _snapshot(root: Device) -> RopeArticulation:
	var hinged := hinges(root)
	if hinged[0].is_empty():
		return null
	var nodes: Array[RigidBody3D] = [root]
	nodes.append_array(hinged[0])
	var on: Array[RopeBody] = []
	for rigid in nodes:
		var state := PhysicsServer3D.body_get_direct_state(rigid.get_rid())
		var body := RopeBody.new()
		body.node = rigid
		body.rigid = rigid
		body.center = rigid.global_transform * state.center_of_mass_local
		body.inv_mass = Vector3.ONE / rigid.mass
		body.inv_inertia = inverse_inertia(rigid)
		on.append(body)
	var model := RopeArticulation.new()
	model.configure(on, hinged[1], hinged[2])
	model._read_velocities()
	return model


func _live() -> bool:
	for body in bodies:
		if not is_instance_valid(body.rigid) or body.rigid.freeze:
			return false
	return true


func _read_velocities() -> void:
	for body in bodies:
		var state := PhysicsServer3D.body_get_direct_state(body.rigid.get_rid())
		body.velocity = state.linear_velocity
		body.spin = state.angular_velocity
	project_velocities(false)


## The root's translation and spin for unit force and torque impulses: its
## geometry's alone, so worked out once for the tick.
func mobility() -> Array[Basis]:
	if _mobility.is_empty():
		_mobility = _root_mobility()
	return _mobility


func _root_mobility() -> Array[Basis]:
	var root := bodies[0]
	var zero := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
	var blocks: Array[Basis] = [zero, zero, zero, zero]
	for axis in 3:
		var direction := Vector3.ZERO
		direction[axis] = 1.0
		var force: Array = response([root], [direction], [Vector3.ZERO])[0]
		blocks[0][axis] = force[1]
		blocks[1][axis] = force[2]
		var torque: Array = response([root], [Vector3.ZERO], [direction])[0]
		blocks[2][axis] = torque[1]
		blocks[3][axis] = torque[2]
	return blocks


func configure(on: Array[RopeBody], pivots: Array[Vector3], along: Array[Vector3]) -> void:
	bodies = on
	axes = along
	masses.resize(bodies.size())
	for i in bodies.size():
		masses[i] = bodies[i].rigid.mass
		total += masses[i]
		center += bodies[i].center * masses[i]
	center /= total
	var n := 3 + axes.size()
	var matrix: Array[PackedFloat64Array] = []
	for i in n:
		var row := PackedFloat64Array()
		row.resize(n)
		matrix.append(row)
	for i in bodies.size():
		var inertia := bodies[i].inv_inertia.inverse()
		var r := bodies[i].center - center
		for row in 3:
			for col in 3:
				matrix[row][col] += inertia[col][row] + masses[i] * ((r.length_squared() if row == col else 0.0) - r[row] * r[col])
	for i in axes.size():
		var body := bodies[i + 1]
		var inertia := body.inv_inertia.inverse()
		var tangent := axes[i].cross(body.center - pivots[i])
		tangents.append(tangent)
		var cross_term := inertia * axes[i] + masses[i + 1] * (body.center - center).cross(tangent)
		for j in 3:
			matrix[j][3 + i] = cross_term[j]
			matrix[3 + i][j] = cross_term[j]
		matrix[3 + i][3 + i] = axes[i].dot(inertia * axes[i]) + masses[i + 1] * tangent.length_squared()
	for i in axes.size():
		for j in axes.size():
			matrix[3 + i][3 + j] -= masses[i + 1] * masses[j + 1] / total * tangents[i].dot(tangents[j])
	inverse = _invert(matrix)
	for body in bodies:
		body.articulation = weakref(self)


## Native snapshots have no predicted external impulse; ordinary rope steps do.
func project_velocities(include_expected := true) -> void:
	var projections := [false, true] if include_expected else [false]
	for predicted in projections:
		var linear := []
		var angular := []
		for i in bodies.size():
			var body := bodies[i]
			linear.append(masses[i] * (body.expected if predicted else body.velocity))
			angular.append(body.inv_inertia.inverse() * (body.expected_spin if predicted else body.spin))
		var projected := response(bodies, linear, angular)
		for entry: Array in projected:
			var body: RopeBody = entry[0]
			if predicted:
				body.expected = entry[1]
				body.expected_spin = entry[2]
			else:
				body.velocity = entry[1]
				body.spin = entry[2]


## Unit-impulse velocities for all bodies, including the hinge reactions.
## The actual impulse is still delivered only at the real rope attachment.
func response(points: Array, linear: Array, angular: Array) -> Array:
	var forces: Array[Vector3] = []
	var torques: Array[Vector3] = []
	forces.resize(bodies.size())
	torques.resize(bodies.size())
	forces.fill(Vector3.ZERO)
	torques.fill(Vector3.ZERO)
	for i in points.size():
		var at := bodies.find(points[i])
		if at >= 0:
			forces[at] += linear[i]
			torques[at] += angular[i]
	var push := Vector3.ZERO
	var turn := Vector3.ZERO
	for i in bodies.size():
		push += forces[i]
		turn += torques[i] + (bodies[i].center - center).cross(forces[i])
	var rhs := PackedFloat64Array([turn.x, turn.y, turn.z])
	for i in axes.size():
		rhs.append(axes[i].dot(torques[i + 1]) + tangents[i].dot(forces[i + 1] - push * masses[i + 1] / total))
	var change := PackedFloat64Array()
	change.resize(rhs.size())
	for i in rhs.size():
		for j in rhs.size():
			change[i] += inverse[i][j] * rhs[j]
	var spin := Vector3(change[0], change[1], change[2])
	var counter := Vector3.ZERO
	for i in axes.size():
		counter += tangents[i] * change[3 + i] * masses[i + 1] / total
	var result := []
	for i in bodies.size():
		var velocity := push / total + spin.cross(bodies[i].center - center) - counter
		var angular_velocity := spin
		if i > 0:
			velocity += tangents[i - 1] * change[3 + i - 1]
			angular_velocity += axes[i - 1] * change[3 + i - 1]
		result.append([bodies[i], velocity, angular_velocity])
	return result


static func _invert(matrix: Array[PackedFloat64Array]) -> Array[PackedFloat64Array]:
	var n := matrix.size()
	var result: Array[PackedFloat64Array] = []
	for i in n:
		var row := PackedFloat64Array()
		row.resize(n)
		row[i] = 1.0
		result.append(row)
	for col in n:
		var pivot := col
		for i in range(col + 1, n):
			if absf(matrix[i][col]) > absf(matrix[pivot][col]):
				pivot = i
		if pivot != col:
			var swap := matrix[col]
			matrix[col] = matrix[pivot]
			matrix[pivot] = swap
			swap = result[col]
			result[col] = result[pivot]
			result[pivot] = swap
		var scale := matrix[col][col]
		assert(absf(scale) > 1e-10, "a dynamic hinged assembly has positive inertia")
		for j in n:
			matrix[col][j] /= scale
			result[col][j] /= scale
		for i in n:
			if i == col:
				continue
			var amount := matrix[i][col]
			for j in n:
				matrix[i][j] -= amount * matrix[col][j]
				result[i][j] -= amount * result[col][j]
	return result
