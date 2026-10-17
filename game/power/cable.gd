class_name Cable
extends Node3D
## A power cable: two plugs on a fixed length of wire. Each plug is a part that
## snaps into a port like any other, so wiring is the same act as fitting.
## While its plugs sit in two different devices, Power pools them.

## How hard an overstretched wire pulls its loose end back, 1/s.
const PULL := 10.0

var plugs: Array[Part] = []
var length := 6.0
var _wire: MeshInstance3D
## Where its ends were last tick, and how fast each moved since.
var _was: Array[Vector3] = []
var _moving: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]


func _init() -> void:
	_wire = MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.012
	tube.bottom_radius = 0.012
	tube.height = 1.0
	tube.radial_segments = 6
	tube.rings = 1
	var look := StandardMaterial3D.new()
	look.albedo_color = Color(0.12, 0.1, 0.08)
	tube.material = look
	_wire.mesh = tube
	_wire.top_level = true
	add_child(_wire)


## The two devices it joins, or nothing unless both ends are plugged in apart.
func joined() -> Array[Device]:
	var ends: Array[Device] = []
	for plug in plugs:
		if is_instance_valid(plug) and plug.socket != null:
			ends.append(plug.socket.get_parent())
	if ends.size() == 2 and ends[0] != ends[1]:
		return ends
	return []


func end_of(plug: Part) -> Vector3:
	return plug.socket.global_position if plug.socket != null else plug.global_position


## The tug on the tick, so it pulls the same at any frame rate.
func _physics_process(delta: float) -> void:
	if not plugs.all(func(p: Variant) -> bool: return is_instance_valid(p)):
		return
	var a := end_of(plugs[0])
	var b := end_of(plugs[1])
	if _was.size() == 2:
		_moving = [(a - _was[0]) / delta, (b - _was[1]) / delta]
	_was = [a, b]
	if a.distance_to(b) > length:
		_overstretched(a, b)


func _process(_delta: float) -> void:
	if not plugs.all(func(p: Variant) -> bool: return is_instance_valid(p)):
		queue_free()
		return
	_draw(end_of(plugs[0]), end_of(plugs[1]))


## Too far: a loose end is pulled along, as a physical tug that the sand can
## stop, never a jump that could land it inside the sand, and never faster
## than the other end drags it, give or take a rope's closing speed, however
## long it was snagged; with both ends held fast, a plug pops out.
func _overstretched(a: Vector3, b: Vector3) -> void:
	for i in 2:
		var plug := plugs[i]
		var other := plugs[1 - i]
		if plug.socket == null and not plug.freeze:
			var anchor := end_of(other)
			var toward := (anchor - plug.global_position).normalized()
			var over := plug.global_position.distance_to(anchor) - length
			var closing := plug.linear_velocity.dot(toward)
			var drags := maxf(_moving[1 - i].dot(toward), 0.0)
			var want := minf(over * PULL, drags + Rope.CLOSING_SPEED)
			plug.linear_velocity += toward * maxf(want - closing, 0.0)
			return
	_pop()


## The first plug in a socket pops out; says whether one did.
func _pop() -> bool:
	for plug in plugs:
		if plug.socket != null:
			var device: Device = plug.socket.get_parent()
			var loose := device.take(plug.socket)
			loose.global_position += loose.global_basis.z * 0.1
			return true
	return false


func _draw(a: Vector3, b: Vector3) -> void:
	var span := a.distance_to(b)
	if span < 1e-4:
		_wire.visible = false
		return
	_wire.visible = true
	var up := (b - a) / span
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	_wire.global_transform = Transform3D(Basis(side, up, side.cross(up)).scaled_local(Vector3(1, span, 1)),
		(a + b) * 0.5)
