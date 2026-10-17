class_name Device
extends RigidBody3D
## A frame with sockets. A fitted part becomes part of the device: its shapes
## and weight join this body, never through a joint, so there's nothing left to
## wobble. Everything the device can do is computed from what's fitted. Power
## (Stage 4) says whether it's running; a dark device can't float or shine.
## Outside a bubble the weather wears it down (Wear), and wrecked it's dark
## for good.

signal parts_changed

@export var label := "device"
## The bare frame's weight, kg.
@export var frame_mass := 15.0
## What the bare frame does by itself, like a turbine's turbine_w.
@export var frame_stats: Dictionary = {}
## Small enough to pick up and carry in your hands, like a stake.
@export var carryable := false
## The socket kind it seats in, like a shield on a top mount; none for most.
@export var kind: StringName
## How much its draw matters when its pool runs short: lower ranks give way
## first, so what keeps you alive keeps its power (Power).
@export var rank := 0

## Set by Power each tick: false once its battery and sources can't meet its draw.
var powered := true
## Its charge light, showing the fitted battery's charge.
var charge_light: MeshInstance3D
## How sound it is, 1 to 0: one placeholder durability for the frame and
## everything fitted, until parts wear on their own. Its paint shows it.
var durability := 1.0:
	set(to):
		durability = to
		show_wear()
## Its painted frame.
var frame_view: MeshInstance3D

## Set by use: its hover tray draws nothing and lets it down onto the sand,
## so a camp staying put keeps its charge.
var resting := false:
	set(to):
		resting = to
		_recompute()
## How far up its tray holds it, 0 on the sand to 1 at its height: eased, so
## it settles and lifts off gently.
var lift_share := 1.0:
	set(to):
		var crossed := (to > 0.0) != (lift_share > 0.0)
		lift_share = to
		if crossed:
			_recompute()

var world: World
var _hovering := false
## The sockets with a device seated in them.
var _seats: Array[Socket] = []
## How it froze before it was seated on another device.
var _unseated_mode := RigidBody3D.FREEZE_MODE_STATIC


func _ready() -> void:
	world = World.of(self)
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	_recompute()


## Fitted parts wait off the tree, so nothing else would free them.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for socket in sockets():
			if socket.part != null:
				socket.part.free()


func sockets() -> Array[Socket]:
	var found: Array[Socket] = []
	for child in get_children():
		if child is Socket:
			found.append(child)
	return found


## Use on it while you look at it: what it does when worked, like a shield
## switching; with a hover tray and nothing else to work, it's set resting or
## floating. Only empty-handed: a line or stake in your hands keeps its own
## use. Says whether it did anything.
func interact(by: Player) -> bool:
	if by.hands.held != null or stats()["lift_kg"] <= 0.0 or wrecked():
		return false
	resting = not resting
	Sounds.play_at(self, Sounds.BOARD_OFF if resting else Sounds.BOARD_ON)
	return true


## Use while you hold it, aiming at `at`. Says whether it did anything.
func use(_by: Player, _at: Vector3) -> bool:
	return false


## The free tie socket nearest a place, or null: where a line would go.
func free_tie(near: Vector3) -> Socket:
	var best: Socket = null
	var nearest := INF
	for socket in sockets():
		var d := socket.global_position.distance_to(near)
		if socket.kind == &"tie" and socket.part == null and d < nearest:
			nearest = d
			best = socket
	return best


## The battery in its first filled battery slot, or null.
func battery() -> Battery:
	for socket in sockets():
		if socket.kind == &"battery" and socket.part is Battery:
			return socket.part
	return null


## Every battery in its battery slots.
func batteries() -> Array[Battery]:
	var found: Array[Battery] = []
	for socket in sockets():
		if socket.kind == &"battery" and socket.part is Battery:
			found.append(socket.part)
	return found


## The batteries it lends its pool (Power).
func pooled() -> Array[Battery]:
	return batteries()


## How full its batteries are together, 0 to 1; 0 with none.
func charge_share() -> float:
	var held := 0.0
	var room := 0.0
	for cell in batteries():
		held += cell.charge_wh
		room += cell.capacity()
	return held / room if room > 0.0 else 0.0


## The devices seated on its sockets.
func mounted() -> Array[Device]:
	var found: Array[Device] = []
	for socket in sockets():
		if socket.mounted != null:
			found.append(socket.mounted)
	return found


## The device it's seated on, or null.
func host() -> Device:
	return get_parent() as Device


## The socket a device is seated in on it, or null.
func seat_of(other: Device) -> Socket:
	for socket in _seats:
		if socket.mounted == other:
			return socket
	return null


## What it generates, W, from the felt weather where it stands, now or at
## world time t.
func production_w(t := NAN) -> float:
	if world == null or wrecked():
		return 0.0
	var now := stats()
	var watts: float = now["solar_w"] * world.weather.felt_light(global_position + Vector3.UP * 0.5, t)
	# A turbine works planted: resting on the sand, not floating or being carried.
	if now["turbine_w"] > 0.0 and not now["can_float"] and linear_velocity.length() < 0.3:
		var wind := world.weather.felt_wind(global_position, t).length()
		watts += minf(now["turbine_w"], world.tuning.turbine_watts_per_cubic * wind * wind * wind)
	return watts


## What it would draw, W, if it had the power, now or at world time t: some
## devices draw by the weather they hold back.
func demand_w(_t := NAN) -> float:
	if wrecked():
		return 0.0
	var now := stats()
	return now["hover_w"] + now["light_w"]


## What it does with a power tick it had the power for, `seconds` long at
## world time t, like a condenser filling its canister. Returns the Wh of
## what it drew that went into a battery of its own, stored, not used.
func work(_seconds: float, _t: float) -> float:
	return 0.0


func set_powered(on: bool) -> void:
	if on == powered:
		return
	powered = on
	_recompute()


func wrecked() -> bool:
	return durability <= 0.0


## The weather takes a share of a new device's life, less for a tough one; at
## nothing it's wrecked, dark for good.
func wear(share: float) -> void:
	if share <= 0.0 or wrecked():
		return
	durability = maxf(durability - share / frame_stats.get("toughness", 1.0), 0.0)
	if wrecked():
		set_powered(false)
		if charge_light != null:
			ChargeLight.paint(charge_light, 0.0)


## Its paint: its make's era, then what the weather took, so a deep find is
## crisp, a surface one rusty, and a wrecked frame down to the metal. Its
## maker's mark is its era's too.
func show_wear() -> void:
	var layer: StringName = get_meta(&"layer", &"")
	var amount := Paint.age_of(layer, durability)
	if frame_view != null:
		frame_view.set_instance_shader_parameter(&"age", amount)
		frame_view.set_instance_shader_parameter(&"era", Paint.era_of(layer))
	for socket in sockets():
		if socket.marker != null:
			socket.marker.set_instance_shader_parameter(&"age", amount)


func parts() -> Array[Part]:
	var found: Array[Part] = []
	for socket in sockets():
		if socket.part != null:
			found.append(socket.part)
	return found


## The socket a fitted shape or mesh belongs to, or null for the frame itself.
func socket_of(node: Node) -> Socket:
	return node.get_meta(&"socket") if node != null and node.has_meta(&"socket") else null


## Moves a part into a free socket of its kind: its shapes and meshes join this
## body at exactly the socket's pose, and the part leaves the physics world.
func fit(part: Part, socket: Socket) -> void:
	assert(socket.is_open() and socket.kind == part.kind and socket.get_parent() == self)
	for child in part.get_children():
		var node := child as Node3D
		if node == null:
			continue
		var local := node.transform
		part.remove_child(node)
		add_child(node)
		node.transform = socket.transform * local
		node.set_meta(&"socket", socket)
		socket.fitted.append(node)
	if part.get_parent() != null:
		part.get_parent().remove_child(part)
	socket.part = part
	part.socket = socket
	if socket.marker != null:
		socket.marker.visible = false
	_rise_clear_of_sand(socket.fitted)
	_recompute()


## A tray slid under a crate resting on the sand lifts the crate onto it: a
## shape left below the sand would wedge the body so nothing could move it.
func _rise_clear_of_sand(nodes: Array[Node3D]) -> void:
	if world == null:
		return
	var deepest := 0.0
	for node in nodes:
		var shape := node as CollisionShape3D
		if shape == null:
			continue
		var box := Catalog.bounds(shape.shape)
		for i in 8:
			var corner := global_transform * shape.transform * box.get_endpoint(i)
			deepest = maxf(deepest, world.height_under(corner) - corner.y)
	if deepest > 0.0:
		global_position.y += deepest + 0.01


## Where a device seated in a socket sits, in the socket's frame: upright
## along the socket's outward axis, its base on the socket's face.
func seat() -> Transform3D:
	var base := 0.0
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null and not shape.has_meta(&"socket"):
			base = maxf(base, -(shape.transform * Catalog.bounds(shape.shape)).position.y)
	return Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, 0.0, base))


## Seats a small device in a free socket of the kind it fits, as a lamp sits on
## a top mount. It stays a body of its own, held fast on this one (frozen, and
## touching nothing of it) so it carries on working as itself: it rides with
## this frame, its weight joins it, and Power pools the two.
func mount(other: Device, socket: Socket) -> void:
	assert(socket.is_open() and socket.kind == other.kind and socket.get_parent() == self)
	if other.get_parent() != null:
		other.get_parent().remove_child(other)
	add_child(other)
	other.transform = socket.transform * other.seat()
	other._unseated_mode = other.freeze_mode
	other.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	other.freeze = true
	other.linear_velocity = Vector3.ZERO
	other.angular_velocity = Vector3.ZERO
	other.add_collision_exception_with(self)
	socket.mounted = other
	_seats.append(socket)
	if socket.marker != null:
		socket.marker.visible = false
	_recompute()


## Takes a seated device off again, loose where it sat; the caller lifts it
## clear along the socket's +Z.
func dismount(socket: Socket) -> Device:
	var other := socket.mounted
	assert(other != null)
	var pose := other.global_transform
	remove_child(other)
	_holder().add_child(other)
	other.global_transform = pose
	other.remove_collision_exception_with(self)
	other.freeze_mode = other._unseated_mode
	other.freeze = false
	other.linear_velocity = linear_velocity
	socket.mounted = null
	_seats.erase(socket)
	if socket.marker != null:
		socket.marker.visible = true
	_recompute()
	return other


## Where loose things go when they come off it: whatever holds it, past any
## device it's seated on.
func _holder() -> Node:
	var at := get_parent()
	while at is Device:
		at = at.get_parent()
	return at


## Takes a fitted part back out as a body again, sitting exactly in its socket;
## the caller slides it out along the socket's +Z. Whatever sits in a socket
## the part added (a line's end on a hook's ring) comes off first, loose.
func take(socket: Socket) -> Part:
	var part := socket.part
	assert(part != null)
	for node in socket.fitted:
		var added := node as Socket
		if added != null and added.part != null:
			take(added)
	for node in socket.fitted:
		var local := socket.transform.affine_inverse() * node.transform
		remove_child(node)
		node.remove_meta(&"socket")
		part.add_child(node)
		node.transform = local
		# Out of a device, nothing powers its lamp.
		if node is Light3D:
			node.visible = false
		elif Paint.is_worn(node):
			(node as GeometryInstance3D).set_instance_shader_parameter(&"lit", 0.0)
	socket.fitted.clear()
	socket.part = null
	part.socket = null
	if socket.marker != null:
		socket.marker.visible = true
	_holder().add_child(part)
	part.global_transform = global_transform * socket.transform
	part.linear_velocity = linear_velocity
	_recompute()
	return part


## Everything the device can do, from the frame and what's fitted.
func stats() -> Dictionary:
	# The wind grabs the frame and everything fitted, by their size; a frame
	# that lies flat says what it shows the wind.
	var face: float = frame_stats.get("face_m2", Weather.biggest_face(self))
	var catch := face * world.tuning.wind_catch_per_m2 if world != null else 0.0
	var total := {"mass": mass, "catch": catch, "capacity_wh": 0.0, "hooks": 0,
		"lift_kg": 0.0, "solar_w": 0.0, "light_w": 0.0, "plants": 0, "turbine_w": 0.0}
	for source: Dictionary in [frame_stats] + parts().map(func(p: Part) -> Dictionary: return p.stats):
		for key: String in source:
			total[key] = total.get(key, 0) + source[key]
	total["can_float"] = total["lift_kg"] >= mass
	total["resting"] = resting
	total["hovering"] = total["can_float"] and powered and lift_share > 0.0
	total["hover_w"] = mass * world.tuning.hover_watts_per_kg \
		if total["can_float"] and not resting and world != null else 0.0
	var cells := batteries()
	if not cells.is_empty():
		total["charge_wh"] = cells.reduce(func(sum: float, c: Battery) -> float: return sum + c.charge_wh, 0.0)
	total["durability"] = durability
	return total


func _recompute() -> void:
	var weight := frame_mass
	var moment := Vector3.ZERO
	for socket in sockets():
		if socket.part != null:
			weight += socket.part.mass
			moment += socket.part.mass * _middle(socket.fitted)
		elif socket.mounted != null:
			weight += socket.mounted.mass
			moment += socket.mounted.mass * socket.mounted.position
	mass = weight
	center_of_mass = moment / weight
	var now := stats()
	_hovering = now["hovering"]
	# Lamps shine, and lenses and emitters glow, only while it has the power.
	var lit := 1.0 if powered else 0.0
	if frame_view != null:
		frame_view.set_instance_shader_parameter(&"lit", lit)
	for socket in sockets():
		for node in socket.fitted:
			if node is Light3D:
				node.visible = powered
			elif Paint.is_worn(node):
				(node as GeometryInstance3D).set_instance_shader_parameter(&"lit", lit)
	# A resting body sleeps, and a sleeping one ignores the tray's lift.
	can_sleep = not _hovering
	if _hovering:
		sleeping = false
	set_meta(&"wind_catch", now["catch"])
	parts_changed.emit()


## Where a fitted part's shapes sit on average, in the device's frame.
func _middle(nodes: Array[Node3D]) -> Vector3:
	var sum := Vector3.ZERO
	var count := 0
	for node in nodes:
		if node is CollisionShape3D:
			sum += node.position
			count += 1
	return Vector3.ZERO if count == 0 else (sum / count)


## A tray holds it a set height over the sand and upright, like the rope
## look-test's floater; sideways, the wind and its lines decide.
func _physics_process(delta: float) -> void:
	# What's seated rides exactly on its seat: a frozen body under a moving one
	# is left a tick behind each tick, and on a floating crate that adds up.
	for socket in _seats:
		socket.mounted.transform = socket.transform * socket.mounted.seat()
	if world == null:
		return
	var tuning := world.tuning
	var goal := 0.0 if resting else 1.0
	if lift_share != goal:
		lift_share = move_toward(lift_share, goal, delta / tuning.hover_settle_seconds)
	if freeze or not _hovering:
		return
	var omega := TAU * tuning.hover_hertz
	var low := world.height_under(global_position) + tuning.hover_height * lift_share - global_position.y
	var lift := mass * (world.gravity + omega * omega * low - 2.0 * tuning.hover_damping * omega * linear_velocity.y)
	apply_central_force(Vector3.UP * maxf(lift, 0.0))
	var state := PhysicsServer3D.body_get_direct_state(get_rid())
	var inverse := state.inverse_inertia
	var moment := 2.0 / maxf(inverse.x + inverse.z, 1e-6)
	var turn := TAU * tuning.hover_upright_hertz
	var tilt := global_basis.y.normalized().cross(Vector3.UP)
	var rocking := angular_velocity - Vector3.UP * angular_velocity.y
	apply_torque(moment * (turn * turn * tilt - 2.0 * tuning.hover_damping * turn * rocking))
