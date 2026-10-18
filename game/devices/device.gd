class_name Device
extends RigidBody3D
## A frame with sockets. A fitted part becomes part of the device: its shapes
## and weight join this body, never through a joint, so there's nothing left to
## wobble. Everything the device can do is computed from what's fitted. Power
## (Stage 4) says whether it's running; a dark device can't float or shine.
## Outside a bubble the weather wears it down (Wear), and wrecked it's dark
## for good.

signal parts_changed

## Settling, a tray's all-lifting height sinks this many falloffs below the
## sand, so what it holds is down on the sand before it stops.
const SETTLE_BELOW := 3.0

@export var label := "device"
## The bare frame's weight, kg.
@export var frame_mass := 15.0
## What the bare frame does by itself, like a turbine's turbine_w.
@export var frame_stats: Dictionary = {}
## Small enough to pick up and carry in your hands, like a stake.
@export var carryable := false
## The socket kind it seats in, like a shield on a top mount; none for most.
@export var kind: StringName
## It stands on a chassis piece's deck mount too, as a crate does.
@export var stands_on_deck := false
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
## Its painted frame, and what turns on its mast.
var frame_view: MeshInstance3D
var rotor: Rotor
## The share of its turbine's rating it made when last asked, and the wind it
## felt then: its rotor turns by the power tick's own sums.
var turbine_share := 0.0
var turbine_wind := Vector3.ZERO

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

## What its trays hold up this tick, kg: its weight floating free, less what
## the sand or a hand takes, more what a line pulls down. They draw for it.
var carried_kg := 0.0

var world: World
var _hovering := false
## Its trays, each as [kg it lifts, the corners of its face, the way it faces
## out], in its own frame: each lifts under its own spot.
var _trays: Array = []
## The sockets with a device seated in them.
var _seats: Array[Socket] = []
## How it froze before it was seated on another device.
var _unseated_mode := RigidBody3D.FREEZE_MODE_STATIC
## Its sockets and its shapes' biggest faces summed, kept until its children
## change: a deck has hundreds of children, and both are asked for every tick.
var _sockets: Array[Socket] = []
var _sockets_known := false
var _face := NAN
## All its shapes' bounds together, in its own frame, kept until its children
## change or move (a recompute): what the world holds clear of the sand.
var _bounds := AABB()
var _bounds_known := false


func _ready() -> void:
	world = World.of(self)
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	_recompute()


## Fitted parts wait off the tree, so nothing else would free them.
func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_sockets_known = false
		_shapes_changed()
	elif what == NOTIFICATION_PREDELETE:
		for socket in sockets():
			if socket.part != null:
				socket.part.free()


func sockets() -> Array[Socket]:
	if not _sockets_known:
		_sockets.clear()
		for child in get_children():
			if child is Socket:
				_sockets.append(child)
		_sockets_known = true
	return _sockets.duplicate()


## Use on it while you look at it: what it does when worked, like a shield
## switching; with a hover tray and nothing else to work, it's set resting or
## floating. Only empty-handed: a line or stake in your hands keeps its own
## use. Says whether it did anything.
func interact(by: Player) -> bool:
	# Standing on a deck, it floats with the deck, so use works the deck.
	if on_deck():
		return host().interact(by)
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


## Whether it has a hover tray fitted.
func has_tray() -> bool:
	return not _trays.is_empty()


## Seated on a chassis piece's deck mount, where it keeps its own sockets.
func on_deck() -> bool:
	var seat_in := host().seat_of(self) if host() != null else null
	return seat_in != null and seat_in.kind == &"deck"


## Whether it seats in a socket: one of the kind it fits, or a deck mount.
func fits_in(socket: Socket) -> bool:
	return socket.kind == kind or socket.kind == &"deck" and stands_on_deck


## Its frame's own sockets, in the catalog's order: what a save numbers.
func frame_sockets() -> Array[Socket]:
	var own: Array[Socket] = []
	for socket in sockets():
		if not socket.has_meta(&"socket"):
			own.append(socket)
	return own


## The socket a device is seated in on it, or null.
func seat_of(other: Device) -> Socket:
	for socket in _seats:
		if socket.mounted == other:
			return socket
	return null


## What it generates, W, from the felt weather where it stands, now or at
## world time t.
func production_w(t := NAN) -> float:
	turbine_share = 0.0
	if world == null or wrecked():
		return 0.0
	var now := stats()
	var watts: float = now["solar_w"] * world.weather.felt_light(global_position + Vector3.UP * 0.5, t)
	# A turbine works planted: resting on the sand, not floating or being carried.
	if now["turbine_w"] > 0.0 and not now["can_float"] and linear_velocity.length() < 0.3:
		turbine_wind = world.weather.felt_wind(global_position, t)
		var wind := turbine_wind.length()
		var made := minf(now["turbine_w"], world.tuning.turbine_watts_per_cubic * wind * wind * wind)
		turbine_share = made / now["turbine_w"]
		watts += made
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
	for view: MeshInstance3D in [frame_view, rotor]:
		if view != null:
			view.set_instance_shader_parameter(&"age", amount)
			view.set_instance_shader_parameter(&"era", Paint.era_of(layer))
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
	assert(socket.is_open() and other.fits_in(socket) and socket.get_parent() == self)
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
	# What stands on a deck keeps its sockets, so its weight can change there.
	if socket.kind == &"deck":
		other.parts_changed.connect(_recompute)
	_recompute()


## What sat on it freed under it, by a scenario clearing or the ground
## forgetting it: that seat is open again. Read by index, untyped, since a
## freed element can't be held in a typed loop.
func _drop_freed_seats() -> void:
	var kept: Array[Socket] = []
	for i in _seats.size():
		var socket = _seats[i]
		if is_instance_valid(socket) and is_instance_valid(socket.mounted):
			kept.append(socket)
		elif is_instance_valid(socket):
			socket.mounted = null
			if socket.marker != null:
				socket.marker.visible = true
	if kept.size() != _seats.size():
		_seats = kept
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
	if other.parts_changed.is_connected(_recompute):
		other.parts_changed.disconnect(_recompute)
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
	var total := {"mass": mass, "catch": wind_catch(), "capacity_wh": 0.0, "hooks": 0,
		"lift_kg": 0.0, "solar_w": 0.0, "light_w": 0.0, "plants": 0, "turbine_w": 0.0}
	for source: Dictionary in [frame_stats] + parts().map(func(p: Part) -> Dictionary: return p.stats):
		for key: String in source:
			total[key] = total.get(key, 0) + source[key]
	total["can_float"] = total["lift_kg"] >= mass
	total["resting"] = resting
	total["hovering"] = total["can_float"] and powered and lift_share > 0.0
	# Its trays draw for what they hold up, or dark, for its weight, what
	# lifting it again would take. Seated, its own tray holds nothing up.
	total["hover_w"] = (carried_kg if powered else mass) * world.tuning.hover_watts_per_kg \
		if total["can_float"] and not resting and world != null and host() == null else 0.0
	var cells := batteries()
	if not cells.is_empty():
		total["charge_wh"] = cells.reduce(func(sum: float, c: Battery) -> float: return sum + c.charge_wh, 0.0)
	total["durability"] = durability
	return total


func _recompute() -> void:
	_shapes_changed()
	var weight := 0.0
	var moment := Vector3.ZERO
	for frame: Array in _frame_masses():
		weight += frame[0]
		moment += frame[0] * frame[1]
	for socket in sockets():
		if socket.part != null:
			weight += socket.part.mass
			moment += socket.part.mass * _middle(socket.fitted)
		elif socket.mounted != null:
			weight += socket.mounted.mass
			moment += socket.mounted.mass * socket.mounted.position
	mass = weight
	center_of_mass = moment / weight
	_trays.clear()
	for socket in sockets():
		if socket.part != null and socket.part.stats.get("lift_kg", 0.0) > 0.0:
			_trays.append(_tray(socket))
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


## How hard the wind grabs it: the frame and everything fitted, by their
## size; a frame that lies flat says what it shows the wind.
func wind_catch() -> float:
	var face: float = frame_stats.get("face_m2", NAN)
	if is_nan(face):
		if is_nan(_face):
			_face = Weather.biggest_face(self)
		face = _face
	return face * world.tuning.wind_catch_per_m2 if world != null else 0.0


## Its shapes came, went or moved: what was worked out from them goes.
func _shapes_changed() -> void:
	_face = NAN
	_bounds_known = false


## All its shapes' bounds together, in its own frame.
func shape_bounds() -> AABB:
	if not _bounds_known:
		var first := true
		for child in get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.shape == null:
				continue
			var box := shape.transform * Catalog.bounds(shape.shape)
			_bounds = box if first else _bounds.merge(box)
			first = false
		if first:
			_bounds = AABB()
		_bounds_known = true
	return _bounds


## Its frame's weight and where it sits, in its own frame, as [kg, position]s.
func _frame_masses() -> Array:
	return [[frame_mass, Vector3.ZERO]]


## Where a fitted part's shapes sit on average, in the device's frame.
func _middle(nodes: Array[Node3D]) -> Vector3:
	var sum := Vector3.ZERO
	var count := 0
	for node in nodes:
		if node is CollisionShape3D:
			sum += node.position
			count += 1
	return Vector3.ZERO if count == 0 else (sum / count)


## Its trays lift it where they are; sideways, the wind and its lines decide.
func _physics_process(delta: float) -> void:
	# What's seated rides exactly on its seat: a frozen body under a moving one
	# is left a tick behind each tick, and on a floating crate that adds up.
	_drop_freed_seats()
	for socket in _seats:
		socket.mounted.transform = socket.transform * socket.mounted.seat()
	if world == null:
		return
	var tuning := world.tuning
	var goal := 0.0 if resting else 1.0
	if lift_share != goal:
		lift_share = move_toward(lift_share, goal, delta / tuning.hover_settle_seconds)
	carried_kg = 0.0
	if freeze or not _hovering:
		return
	_lift(tuning, delta)


## Each tray reads the sand under its face, on average, and pushes straight
## up at the face's corners, each harder the nearer it is to that: by e more
## each hover_falloff nearer, all it can lift at hover_height, and never more
## than that in all, its push then gathering at the lowest corners. So a light
## load rides higher than a heavy one, a corner with no tray under it sinks,
## and only where the trays are keeps it upright, toward level even over a
## dune's face, while a deck's trays far apart follow the dunes under them. A
## tray pushes only while it faces the sand. Settling, its all-lifting height sinks a little
## below the sand, so the device is down before the tray stops. Each corner's
## damper scales with its push, so every load settles alike, and is solved
## against the motion it leaves, so it never overshoots at any tick rate.
func _lift(tuning: Tuning, delta: float) -> void:
	var g := world.gravity
	var reach := tuning.hover_falloff
	var full := (tuning.hover_height + SETTLE_BELOW * reach) * lift_share - SETTLE_BELOW * reach
	var rate := 2.0 * tuning.hover_damping / sqrt(g * reach)
	var middle := global_transform * center_of_mass
	var turn := PhysicsServer3D.body_get_direct_state(get_rid()).inverse_inertia_tensor
	var rise_at := linear_velocity.y
	var spin := angular_velocity
	var lifted := 0.0
	var damped := 0.0
	var twist := Vector3.ZERO
	for tray: Array in _trays:
		var corners: PackedVector3Array = tray[1]
		var facing := clampf(-(global_basis * (tray[2] as Vector3)).normalized().y, 0.0, 1.0)
		var most: float = tray[0] * g * facing
		var points: Array[Vector3] = []
		var sand := 0.0
		for corner in corners:
			var at := global_transform * corner
			points.append(at)
			sand += world.height_under(at) / corners.size()
		var pushes: Array[float] = []
		var all := 0.0
		for at in points:
			var push := most / corners.size() * exp(minf((full - at.y + sand) / reach, 30.0))
			pushes.append(push)
			all += push
		var over := maxf(all / most, 1.0) if most > 0.0 else 1.0
		var spare := most - all / over
		for i in points.size():
			var push := pushes[i] / over
			apply_force(Vector3.UP * push, points[i] - global_position)
			var lever := (points[i] - middle).cross(Vector3.UP)
			var give := 1.0 / mass + lever.dot(turn * lever)
			var rise := rise_at + spin.dot(lever)
			var hold := rate * push * delta
			var stop := clampf(-hold * rise / (1.0 + hold * give), -push * delta, spare * delta)
			spare -= maxf(stop, 0.0) / delta
			rise_at += stop / mass
			spin += turn * (lever * stop)
			damped += stop
			twist += lever * stop
			lifted += push
	apply_central_impulse(Vector3.UP * damped)
	apply_torque_impulse(twist)
	carried_kg = (lifted + damped / delta) / g


## A fitted tray: what it lifts, the corners of its outer face and its way out.
func _tray(socket: Socket) -> Array:
	var corners := PackedVector3Array()
	for node in socket.fitted:
		var shape := node as CollisionShape3D
		if shape != null:
			var box := Catalog.bounds(shape.shape)
			for i in 4:
				var x := box.position.x if i % 2 == 0 else box.end.x
				var y := box.position.y if i < 2 else box.end.y
				corners.append(shape.transform * Vector3(x, y, box.end.z))
	return [socket.part.stats.lift_kg, corners, socket.transform.basis.z]


## How high its middle rides over level sand, its load shared out as its
## trays lift: where to set it down floating. Too heavy, on the sand.
func rest_height() -> float:
	var lift := 0.0
	var depth := 0.0
	var count := 0
	for tray: Array in _trays:
		lift += tray[0]
		for corner: Vector3 in tray[1]:
			depth -= corner.y
			count += 1
	if count == 0 or lift < mass:
		return -Finds.bounds(self).position.y + 0.02
	var tuning := Tuning.current()
	return tuning.hover_height + tuning.hover_falloff * log(lift / mass) + depth / count
