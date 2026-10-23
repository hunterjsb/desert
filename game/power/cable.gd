class_name Cable
extends Node3D
## A power cable: two plugs on a fixed length of wire. Each plug is a part that
## snaps into a port like any other, so wiring is the same act as fitting.
## While its plugs sit in two different devices, Power pools them. A
## plug also clips to a lead socket, a rope hook's stem: a kite's aerial lead
## (AntennaKite), which carries no power. Held at a driven stake, a cable passes
## through its ring (route), one cable through three points: set, stake, kite.

## Sockets a plug carries a signal through, never power: a kite's lead, and a
## headset's cable from its jack to a radio's misc bay.
const SIGNAL_ONLY: Array[StringName] = [&"lead", &"jack", &"radio_bay"]
## How hard an overstretched wire pulls its loose end back, 1/s.
const PULL := 10.0

var plugs: Array[Part] = []
var length := 6.0
## The driven stake it runs through, or null.
var through: Stake
var _wire: MeshInstance3D
var _leg: MeshInstance3D
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
	# Its second leg, from the stake it runs through on.
	_leg = MeshInstance3D.new()
	_leg.mesh = tube
	_leg.top_level = true
	_leg.visible = false
	add_child(_leg)


## The cable a plug is on, or null.
static func of(plug: Part, world: World) -> Cable:
	for child in world.content.get_children():
		var cable := child as Cable
		if cable != null and cable.plugs.has(plug):
			return cable
	return null


## Passes it through a driven stake's ring, or takes it off the one it runs
## through; says why not, or "". Its two legs have to fit its length.
func route(stake: Stake) -> String:
	if through == stake:
		through = null
		_rope_through()
		return ""
	if through != null:
		return "take it off its stake first"
	if not stake.driven:
		return "drive the stake in first"
	var ring := stake.global_transform * Stake.RING
	if end_of(plugs[0]).distance_to(ring) + ring.distance_to(end_of(plugs[1])) > length:
		return "the cable won't reach round it"
	through = stake
	_rope_through()
	return ""


## The way it runs end to end, m: through its stake if it runs through one.
func span() -> float:
	var a := end_of(plugs[0])
	var b := end_of(plugs[1])
	if not staked():
		return a.distance_to(b)
	var ring := through.global_transform * Stake.RING
	return a.distance_to(ring) + ring.distance_to(b)


## Whether it runs through a stake still driven where it was.
func staked() -> bool:
	return is_instance_valid(through) and through.driven and through.is_inside_tree()


## A strong cable's rope runs through the stake's ring too.
func _rope_through() -> void:
	pass


## The two devices it joins, or nothing unless both ends are plugged in apart.
func joined() -> Array[Device]:
	var ends: Array[Device] = []
	for plug in plugs:
		if is_instance_valid(plug) and plug.socket != null and plug.socket.kind not in SIGNAL_ONLY:
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
	if through != null and not staked():
		# Its stake pulled, it runs straight again.
		through = null
		_rope_through()
	if span() > length:
		_overstretched(a, b)


func _process(_delta: float) -> void:
	if not plugs.all(func(p: Variant) -> bool: return is_instance_valid(p)):
		queue_free()
		return
	if staked():
		var ring := through.global_transform * Stake.RING
		_draw(end_of(plugs[0]), ring)
		_lay(_leg, ring, end_of(plugs[1]))
	else:
		_leg.visible = false
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
			# Through a stake, a loose end is drawn toward the stake's ring.
			var anchor := through.global_transform * Stake.RING if staked() else end_of(other)
			var toward := (anchor - plug.global_position).normalized()
			var over := span() - length
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
	_lay(_wire, a, b)


## A leg of wire laid from a to b.
static func _lay(wire: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var long := a.distance_to(b)
	if long < 1e-4:
		wire.visible = false
		return
	wire.visible = true
	var up := (b - a) / long
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	wire.global_transform = Transform3D(Basis(side, up, side.cross(up)).scaled_local(Vector3(1, long, 1)),
		(a + b) * 0.5)
