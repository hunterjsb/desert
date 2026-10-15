extends RefCounted
## The rope look-test's stand-ins for camp pieces, each with its rings: the
## test floater, a crate and stakes. Probes tie up the same ones. Positions
## are engine coordinates; each sits on or above the sand under it.

const Floater := preload("res://look/rope/floater.gd")
const Stake := preload("res://game/rope/stake.gd")

const FLOATER_SIZE := Vector3(1.2, 0.8, 1.2)
const FLOATER_MASS := 20.0
## Light and broad, so the wind has a lot to grab.
const FLOATER_CATCH := 0.5
const CRATE_SIZE := Vector3(1.0, 0.7, 0.7)
const CRATE_MASS := 60.0
const CRATE_CATCH := 0.15
const SAND_FRICTION := 0.5
const STAKE_HOLDING := 2500.0
## How far a stake's ring stands above the sand.
const STAKE_RING := 0.3


static func floater(world: World, at: Vector3, mass := FLOATER_MASS, catch := FLOATER_CATCH,
		size := FLOATER_SIZE) -> RigidBody3D:
	var body: RigidBody3D = Floater.new()
	body.world = world
	_box(body, size, mass, Color(0.33, 0.52, 0.6))
	body.set_meta(&"wind_catch", catch)
	# A ring a little below the middle of each side face.
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		RopeEnd.make(body, side * size * 0.5 + Vector3.DOWN * size.y * 0.15)
	_place(world, body, at, Floater.HOVER)
	return body


static func crate(world: World, at: Vector3, mass := CRATE_MASS, catch := CRATE_CATCH) -> RigidBody3D:
	var body := RigidBody3D.new()
	_box(body, CRATE_SIZE, mass, Color(0.45, 0.33, 0.22))
	body.set_meta(&"wind_catch", catch)
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.friction = SAND_FRICTION
	# Hooks on the upper edge of each face.
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		RopeEnd.make(body, side * CRATE_SIZE * 0.5 + Vector3.UP * CRATE_SIZE.y * 0.3)
	_place(world, body, at, CRATE_SIZE.y * 0.5 + 0.02)
	return body


static func stake(world: World, at: Vector3, holding := STAKE_HOLDING) -> RigidBody3D:
	var body: RigidBody3D = Stake.new()
	body.holding = holding
	body.mass = 2.0
	body.freeze = true
	body.can_sleep = false
	body.set_meta(&"wind_catch", 0.01)
	var shape := CollisionShape3D.new()
	var post := CylinderShape3D.new()
	post.radius = 0.04
	post.height = 0.8
	shape.shape = post
	body.add_child(shape)
	var look := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.02
	mesh.height = 0.8
	look.mesh = mesh
	look.material_override = _material(Color(0.3, 0.27, 0.24))
	body.add_child(look)
	body.ring = RopeEnd.make(body, Vector3.UP * (STAKE_RING - 0.1))
	# Driven in so its middle is just under the sand and the ring stands clear.
	_place(world, body, at, 0.1)
	return body


## The ring on a body that faces a place best.
static func ring_toward(body: Node3D, at: Vector3) -> RopeEnd:
	var best: RopeEnd
	var nearest := INF
	for child in body.get_children():
		var ring := child as RopeEnd
		if ring != null and ring.global_position.distance_to(at) < nearest:
			nearest = ring.global_position.distance_to(at)
			best = ring
	return best


static func _box(body: RigidBody3D, size: Vector3, mass: float, color: Color) -> void:
	body.mass = mass
	body.can_sleep = false
	# Set, not left to the engine, so the rope solver knows it from the first tick.
	body.inertia = mass / 12.0 * Vector3(size.y * size.y + size.z * size.z,
		size.x * size.x + size.z * size.z, size.x * size.x + size.y * size.y)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var look := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	look.mesh = mesh
	look.material_override = _material(color)
	body.add_child(look)


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


static func _place(world: World, body: RigidBody3D, at: Vector3, above: float) -> void:
	world.content.add_child(body)
	body.global_position = Vector3(at.x, world.height_under(at) + above, at.z)
