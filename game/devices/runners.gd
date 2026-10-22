class_name Runners
extends RefCounted
## Runners on the sand: skates or a board plate in a device's bottom mounts.
## Each rides the ground's one function, never the sand's collision, so no
## dune's lattice or chunk seam can catch it. They slide easily along their
## length and grip hard across it, as a land yacht's do, so a sail drives a
## camp on runners forward where a floating one only drifts. Each corner of a
## runner's face is a spring on the sand with a damper solved against the
## motion it leaves, so the load shares out by how hard each corner presses,
## a heavy load sinks a little and a gust heels it smoothly, at any tick rate.

## Farther off the sand than this, a corner is in the air, m; coming down,
## it presses in no deeper than this in a tick before it's stopped, m.
const REACH := 0.25
const LANDING := 0.03
## Its whole load at rest presses its corners this far into the sand, m, and
## the bob that leaves dies away this much in one swing (1 settles without one).
const SINK := 0.01
const RATIO := 1.0
## Sideways, a runner ploughs: it takes out the sideways way it's going this
## fast, s, as far as its grip holds, so a steady pull turns a camp smoothly
## and it never stalls on a turn the way stuck blades would.
const PLOUGH := 0.04
## Along its length a runner at rest holds its hold stat's share of its load,
## settled in the sand, and sliding this fast drags only its glide's, m/s.
const SETTLED := Vector2(0.02, 0.2)
## A point meeting the sand is pushed out of it this share of the way a
## tick, never faster than this, m/s: it settles back up, never flung.
const TOUCH_OUT := 0.3
const TOUCH_SPEED := 0.5
## Resting on several points, they're met together this many times over.
const REST_SWEEPS := 3

## Each runner as [corners of its face, its length's way, glide, plough, grip,
## hold], in its device's frame.
var runners: Array = []
## Corners on the sand last tick, and their whole push, N: what the probes and
## the readout see.
var touching := 0
var pressed_n := 0.0
## What a tick of them costs, µs, on average.
var cost_us := 0.0


## The runners fitted to a device, from its sockets: each part with a glide
## stat in a bottom mount. A runner fitted across its device's length (a deck
## piece turned on the grid) is turned along it, so a deck's runners agree.
static func of(device: Device) -> Array:
	var found: Array = []
	for socket in device.sockets():
		if socket.part == null or not socket.part.stats.has("glide"):
			continue
		var shape := _lengthwise(socket)
		if shape == null:
			continue
		var along := shape.transform.basis.y.normalized()
		var box := Catalog.bounds(shape.shape)
		var stats: Dictionary = socket.part.stats
		var corners := PackedVector3Array()
		for i in 4:
			var x := box.position.x * 0.85 if i % 2 == 0 else box.end.x * 0.85
			var y := box.position.y * 0.9 if i < 2 else box.end.y * 0.9
			corners.append(shape.transform * Vector3(x, y, box.end.z + stats.get("keel", 0.0)))
		found.append([corners, along, stats.glide, stats.get("plough", 0.0), stats.get("grip", 0.0),
			stats.get("hold", stats.glide)])
	return found


## The hover fins fitted to a device, as [the middle of its face, its length's
## way, keel, keel_drag], in its device's frame, turned along its length as
## runners are. A runner's own keel stat measures blade penetration, not hover grip.
static func keels(device: Device) -> Array:
	var found: Array = []
	for socket in device.sockets():
		if socket.part == null or socket.part.stats.get("lift_kg", 0.0) <= 0.0 or not socket.part.stats.has("keel"):
			continue
		var shape := _lengthwise(socket)
		if shape == null:
			continue
		var face := Vector3(0.0, 0.0, Catalog.bounds(shape.shape).end.z)
		found.append([shape.transform * face, shape.transform.basis.y.normalized(), socket.part.stats.keel,
			socket.part.stats.get("keel_drag", 0.0)])
	return found


## A bottom mount's part, its length (its shape's y) turned along its
## device's, so a deck's runners and keels agree however its pieces sit; its
## shape, or null.
static func _lengthwise(socket: Socket) -> CollisionShape3D:
	var shape: CollisionShape3D = null
	for node in socket.fitted:
		if node is CollisionShape3D:
			shape = node
	if shape == null:
		return null
	if absf(shape.transform.basis.y.normalized().z) < 0.7:
		var out := socket.transform.basis.z.normalized()
		var turn := Transform3D(Basis(out, PI / 2.0), Vector3.ZERO)
		var pivot := Transform3D(Basis.IDENTITY, socket.position)
		for node in socket.fitted:
			node.transform = pivot * turn * pivot.affine_inverse() * node.transform
	return shape


## A keel's bite on the camp it floats, `weight` N of it: across its length
## its slip goes as a runner's plough takes it, exactly over the tick by the
## mass it meets there, so it never overshoots at any tick rate, as far as
## its keel share of the weight; along it, it drags its keel_drag share.
static func bite(body: RigidBody3D, keel: Array, weight: float, h: float) -> void:
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	var turn := state.inverse_inertia_tensor
	var at := body.global_transform * (keel[0] as Vector3)
	var length := body.global_basis * (keel[1] as Vector3)
	var along := Vector3(length.x, 0.0, length.z).normalized()
	if along == Vector3.ZERO:
		return
	var across := Vector3(-along.z, 0.0, along.x)
	var arm := at - body.global_transform * body.center_of_mass
	var moving := state.linear_velocity + state.angular_velocity.cross(arm)
	var inv_mass := 1.0 / body.mass
	var most: float = keel[2] * weight * h
	var held := clampf(-_mass(inv_mass, turn, arm, across) * moving.dot(across) * (1.0 - exp(-h / PLOUGH)), -most, most)
	var slide := moving.dot(along)
	var drag := -signf(slide) * minf(_mass(inv_mass, turn, arm, along) * absf(slide), keel[3] * weight * h)
	body.apply_impulse(across * held + along * drag, at - body.global_position)


## How high a device on these runners rides over level sand: its middle,
## where to set it down.
func rest_height() -> float:
	var depth := 0.0
	var count := 0
	for runner: Array in runners:
		for corner: Vector3 in runner[0]:
			depth -= corner.y
			count += 1
	return Tuning.current().runner_clearance + depth / maxi(count, 1)


## One tick on the sand: each corner pressed into it pushes back along the
## sand's slope, a spring sharing out the load by how far each is pressed,
## with a damper that takes the bob out, solved against the motion it
## leaves. Along the runner each corner drags its share of its push, more the
## faster it slides; across, they plough together. Solved on the body's own
## velocity as it stands now, gravity's pull this tick included, and handed
## to the body as impulses.
func glide(body: RigidBody3D, world: World, h: float) -> void:
	var started := Time.get_ticks_usec()
	touching = 0
	pressed_n = 0.0
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	var inv_mass := 1.0 / body.mass
	var turn := state.inverse_inertia_tensor
	var middle := body.global_transform * body.center_of_mass
	var v := state.linear_velocity + Vector3.DOWN * world.gravity * h
	var w := state.angular_velocity
	var linear_force := Basis.from_scale(Vector3.ONE * inv_mass)
	var angular_force := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
	var linear_torque := angular_force
	var angular_torque := turn
	var supported_mass := body.mass
	var model := RopeArticulation.native(body as Device)
	if model != null:
		var coupled := model.bodies[0]
		middle = coupled.center
		v = coupled.velocity + Vector3.DOWN * world.gravity * h
		w = coupled.spin
		supported_mass = model.total
		var mobility := model.mobility()
		linear_force = mobility[0]
		angular_force = mobility[1]
		linear_torque = mobility[2]
		angular_torque = mobility[3]
	var answers := Basis(Vector3(linear_force.y.y, angular_force.y.x, angular_force.y.z),
		Vector3(linear_torque.x.y, angular_torque.x.x, angular_torque.x.z),
		Vector3(linear_torque.z.y, angular_torque.z.x, angular_torque.z.z))
	# Each corner's spring and damper, a share of what holds up the whole load.
	var corners_all := runners.size() * 4
	var stiff := supported_mass * world.gravity / (SINK * corners_all)
	var damp := 2.0 * RATIO * sqrt(stiff * supported_mass / corners_all)
	# Each touching corner's three ways (up the sand's slope, along the
	# runner, across it), the lever each has on the body and how that turns
	# it, the mass each meets, and what it may push; packed, as this runs
	# every tick for every corner.
	var ways := PackedVector3Array()
	var levers := PackedVector3Array()
	var turns := PackedVector3Array()
	var movements := PackedVector3Array()
	var masses := PackedFloat64Array()
	var gaps := PackedFloat64Array()
	var limits := PackedFloat64Array()
	var basis := body.global_basis
	for runner: Array in runners:
		var corners: PackedVector3Array = runner[0]
		var at: Array[Vector3] = []
		var sand: Array[float] = []
		for corner in corners:
			var p := body.global_transform * corner
			at.append(p)
			sand.append(world.height_at(world.world_x(p.x), world.world_z(p.z)))
		# The sand's slope under the runner, from its corners' own sand.
		var one := Vector3(at[3].x - at[0].x, sand[3] - sand[0], at[3].z - at[0].z)
		var two := Vector3(at[2].x - at[1].x, sand[2] - sand[1], at[2].z - at[1].z)
		var normal := one.cross(two).normalized()
		if normal.y < 0.0:
			normal = -normal
		if normal.y < 0.2:
			normal = Vector3.UP
		var length := (basis * (runner[1] as Vector3))
		var along := (length - normal * length.dot(normal)).normalized()
		var across := normal.cross(along)
		for i in at.size():
			var gap := (at[i].y - sand[i]) * normal.y - world.tuning.runner_clearance
			if gap > REACH:
				continue
			var arm := at[i] - middle
			for way: Vector3 in [normal, along, across]:
				var lever := arm.cross(way)
				var spin := angular_force * way + angular_torque * lever
				var drift := linear_force * way + linear_torque * lever
				ways.append(way)
				levers.append(lever)
				turns.append(spin)
				movements.append(drift)
				masses.append(1.0 / (way.dot(drift) + lever.dot(spin)))
			var slide := absf(v.dot(along) + w.dot(levers[levers.size() - 2]))
			gaps.append(gap)
			limits.append(lerpf(runner[5], runner[2] + runner[3] * slide, smoothstep(SETTLED.x, SETTLED.y, slide)))
			limits.append(runner[4])
	var count := gaps.size()
	var pushes := _support(count, ways, levers, gaps, v, w, answers, stiff, damp, h)
	var impulse := Vector3.ZERO
	var twist := Vector3.ZERO
	for i in count:
		var k := i * 3
		var pushed := pushes[i]
		# Off the sand and coming down hard: only what would carry it deeper
		# this tick than its springs can take; the springs meet the rest.
		if gaps[i] > 0.0:
			pushed = maxf(0.0, -masses[k] * (v.dot(ways[k]) + w.dot(levers[k]) + (gaps[i] + LANDING) / h))
			pushes[i] = pushed
		v += movements[k] * pushed
		w += turns[k] * pushed
		impulse += ways[k] * pushed
		twist += levers[k] * pushed
	for i in count:
		var k := i * 3
		# Along: held up to its share of its push, dragged past it.
		var most := limits[i * 2] * pushes[i]
		var held := clampf(-masses[k + 1] * (v.dot(ways[k + 1]) + w.dot(levers[k + 1])), -most, most)
		v += movements[k + 1] * held
		w += turns[k + 1] * held
		impulse += ways[k + 1] * held
		twist += levers[k + 1] * held
	# Across: every corner ploughs together, each by the load on it.
	if count > 0:
		var ploughed := _plough(count, ways, levers, pushes, limits, body.linear_velocity, body.angular_velocity, world.gravity)
		impulse += ploughed[0]
		twist += ploughed[1]
		body.apply_central_impulse(impulse)
		body.apply_torque_impulse(twist)
	for i in count:
		if pushes[i] > 0.0:
			touching += 1
			pressed_n += pushes[i] / h
	cost_us += (Time.get_ticks_usec() - started - cost_us) * 0.05


## The corners pressed into the sand hold the body up together: each a
## spring by how far it's pressed and a damper on how fast, solved for the
## body's rise and its tilt both ways at once, implicitly, so the load shares
## out as the springs say and settles where they say at any tick rate. A
## corner that would have to pull lets go, and the rest are solved again.
## Returns each corner's push up, N·s.
static func _support(count: int, ways: PackedVector3Array, levers: PackedVector3Array, gaps: PackedFloat64Array,
		v: Vector3, w: Vector3, answers: Basis, stiff: float, damp: float, h: float) -> PackedFloat64Array:
	var pushes := PackedFloat64Array()
	pushes.resize(count)
	var on := PackedByteArray()
	on.resize(count)
	for i in count:
		on[i] = 1 if gaps[i] <= 0.0 else 0
	# The ways the body answers a push up: rising, and tipping about x and z.
	var give := (stiff * h + damp) * h
	for attempt in 3:
		var rows: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
		var wanted := Vector3.ZERO
		for i in count:
			if on[i] == 0:
				continue
			var k := i * 3
			var rate := Vector3(ways[k].y, levers[k].x, levers[k].z)
			for r in 3:
				rows[r] += rate * (rate[r] * give)
			var into := ways[k].dot(v) + levers[k].dot(w)
			wanted += rate * ((-stiff * gaps[i] - (stiff * h + damp) * into) * h)
		var solve := Basis(Vector3.RIGHT + answers * rows[0], Vector3.UP + answers * rows[1],
			Vector3.BACK + answers * rows[2])
		var change := solve.inverse() * (answers * wanted)
		var pulled := false
		for i in count:
			if on[i] == 0:
				pushes[i] = 0.0
				continue
			var k := i * 3
			var into := ways[k].dot(v) + levers[k].dot(w) + Vector3(ways[k].y, levers[k].x, levers[k].z).dot(change)
			pushes[i] = (-stiff * gaps[i] - (stiff * h + damp) * into) * h
			if pushes[i] < 0.0:
				on[i] = 0
				pulled = true
		if not pulled:
			break
	for i in count:
		pushes[i] = maxf(pushes[i], 0.0)
	return pushes


## Across, the runners plough: each corner holds back the sideways way it
## went this tick by the load on it, as if that load came to rest across in
## PLOUGH s, as far as its grip holds, so the camp slides and turns about
## where its weight bears on its runners, as a real one does. Read from the
## way it went, before anything pushed it this tick, so a steady pull slides
## and turns it the same at any tick rate. Returns the impulse and its twist.
static func _plough(count: int, ways: PackedVector3Array, levers: PackedVector3Array, pushes: PackedFloat64Array,
		limits: PackedFloat64Array, went: Vector3, turned: Vector3, g: float) -> Array:
	var impulse := Vector3.ZERO
	var twist := Vector3.ZERO
	for i in count:
		var k := i * 3 + 2
		var slip := ways[k].dot(went) + levers[k].dot(turned)
		var most := limits[i * 2 + 1] * pushes[i]
		var held := clampf(-pushes[i] / (g * PLOUGH) * slip, -most, most)
		impulse += ways[k] * held
		twist += levers[k] * held
	return [impulse, twist]


## The mass a push along `way` at `arm` from the middle meets: the body's own
## and its turning, together.
static func _mass(inv_mass: float, turn: Basis, arm: Vector3, way: Vector3) -> float:
	var lever := arm.cross(way)
	return 1.0 / (inv_mass + lever.dot(turn * lever))


## Something of a body's meeting the sand at a point, not a runner: it stops
## dead there, pushed back out of the sand over a few ticks with no bounce,
## and drags along it `grip` of that push whichever way it slides. A camp
## going over comes to rest on its masthead so.
static func touch(body: RigidBody3D, world: World, point: Vector3, grip: float, h: float, clearance := 0.0, ground_height := NAN) -> bool:
	var sand := world.height_at(world.world_x(point.x), world.world_z(point.z)) if is_nan(ground_height) else ground_height
	var gap := point.y - sand - clearance
	if gap > REACH:
		return false
	var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
	var inv_mass := 1.0 / body.mass
	var turn := state.inverse_inertia_tensor
	var middle := body.global_transform * body.center_of_mass
	var velocity := state.linear_velocity
	var spin := state.angular_velocity
	var model := RopeArticulation.native(body as Device)
	if model != null:
		var coupled := model.bodies[0]
		middle = coupled.center
		velocity = coupled.velocity
		spin = coupled.spin
	var arm := point - middle
	var moving := velocity + Vector3.DOWN * world.gravity * h + spin.cross(arm)
	var normal := _contact_response(model, inv_mass, turn, arm, Vector3.UP)
	if normal.y <= 0.0:
		return false
	var pushed := maxf(0.0, -(moving.y + (gap / h if gap > 0.0 else maxf(gap * TOUCH_OUT / h, -TOUCH_SPEED))) / normal.y)
	if pushed <= 0.0:
		return false
	var supported := moving + normal * pushed
	var flat := Vector3(supported.x, 0.0, supported.z)
	var way := flat.normalized() if flat.length() > 1e-4 else Vector3.ZERO
	var drag := 0.0
	if way != Vector3.ZERO:
		var friction := _contact_response(model, inv_mass, turn, arm, way)
		# Friction's normal response is supplied by the same contact's support.
		var response := friction - normal * (friction.y / normal.y)
		var slip_response := way.dot(response)
		if slip_response > 0.0:
			drag = flat.length() / slip_response
			# N = N0 + D*Knt/Knn; D <= grip*N gives this sliding bound.
			var cone := 1.0 - grip * friction.y / normal.y
			if cone > 0.0:
				drag = minf(drag, grip * pushed / cone)
			pushed += drag * friction.y / normal.y
	body.apply_impulse(Vector3.UP * pushed - way * drag, point - body.global_position)
	return true


## Several points of one body meeting the sand at once, as a camp lying over
## rests on its frame edges and masthead: each met in turn, and swept again,
## so the last one met never undoes the first. Only those within reach of
## the sand are met, and only those pushing are swept again; `clearances`
## pairs with `points`.
static func rest_on(body: RigidBody3D, world: World, points: PackedVector3Array, clearances: PackedFloat32Array,
		grip: float, h: float) -> void:
	var near: Array[int] = []
	# Coordinates and ground hold during the sweeps; each impulse still re-reads velocity.
	var origin_x := world.world_x(0.0)
	var origin_z := world.world_z(0.0)
	var sand := PackedFloat64Array()
	sand.resize(points.size())
	for i in points.size():
		var p := points[i]
		var height := world.height_at(origin_x + p.x, origin_z + p.z)
		sand[i] = height
		if p.y - height - clearances[i] <= REACH:
			near.append(i)
	for sweep in REST_SWEEPS:
		var pushing: Array[int] = []
		for i in near:
			if touch(body, world, points[i], grip, h, clearances[i], sand[i]):
				pushing.append(i)
		near = pushing


## A point's velocity response includes its freely hinged load through the joint.
static func _contact_response(model: RopeArticulation, inv_mass: float, turn: Basis, arm: Vector3, way: Vector3) -> Vector3:
	var lever := arm.cross(way)
	if model == null:
		return way * inv_mass + (turn * lever).cross(arm)
	var blocks := model.mobility()
	return blocks[0] * way + blocks[2] * lever + (blocks[1] * way + blocks[3] * lever).cross(arm)
