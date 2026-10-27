class_name Device
extends RigidBody3D
## A frame with its few sockets: plugs, water taps and what's its own. A
## fitted part, or one stuck on a chassis's sticky face, becomes part of the
## body: its shapes and weight join it, never through a joint, so there's
## nothing left to wobble. A device stuck on a chassis stays a body of its own
## held fast there, in the deck's power pool. Everything a body can do is
## computed from what's on it. Power says whether it's running; a dark device
## can't float or shine. Outside a bubble the weather wears it down (Wear),
## and wrecked it's dark for good.

signal parts_changed

## Settling, a tray's all-lifting height sinks this many falloffs below the
## sand, so what it holds is down on the sand before it stops.
const SETTLE_BELOW := 3.0
## Leaning past this far, rad, what's seated on it can meet the sand.
const TIPPED := deg_to_rad(25.0)

@export var label := "device"
## The bare frame's weight, kg, and where it sits in its own frame: a tall
## frame built heavy at its foot says so.
@export var frame_mass := 15.0
@export var frame_middle := Vector3.ZERO
## What the bare frame does by itself, like a turbine's turbine_w.
@export var frame_stats: Dictionary = {}
## Small enough to pick up and carry in your hands, like a stake.
@export var carryable := false
## It sticks on a chassis's sticky face; standing, only upright on one that
## faces up; tall, too tall to stand under a frame.
@export var sticks := false
@export var stands := false
@export var tall := false
## How much its draw matters when its pool runs short: lower ranks give way
## first, so what keeps you alive keeps its power (Power).
@export var rank := 0
## Set from a Console through a power box that allows it: its own rank in its
## pool's order (-1 for its kind's), and switched off, a draw the pool skips.
## Only while a box in its pool allows them (Power.control).
var priority := -1
var switched_off := false

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
## Its wear by the way the weather blew, in its own frame: xyz each share of
## its life the sand took, toward where it came from; w those shares. Its
## paint shows it where it hit (Paint.show_blast), whatever look it wears.
var weathered := Vector4.ZERO
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
## Whether its lamps are switched on: a Console's screen switches them.
var lamps := true:
	set(to):
		lamps = to
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
## What resting tipped over on its edges costs a tick, µs, on average.
var rest_us := 0.0

var world: World
## Its runners, if it rides the sand on any, or null.
var glider: Runners
var _hovering := false
## Its trays, each as [kg it lifts, the corners of its face, the way it faces
## out], in its own frame: each lifts under its own spot, toward the sand it
## faces.
var _trays: Array = []
## Its keels, as Runners.keels has them: floating, each holds it across.
var _keels: Array = []
## The sockets with a device seated in them.
var _seats: Array[Socket] = []
## How it froze before it was seated on another device.
var _unseated_mode := RigidBody3D.FREEZE_MODE_STATIC
## Its sockets and its shapes' biggest faces summed, kept until its children
## change: a deck has hundreds of children, and both are asked for every tick.
var _sockets: Array[Socket] = []
var _sockets_known := false
## What those sockets hold, kept until one changes or what's in one does
## (Socket): a deck's are asked for its devices and batteries many times a tick.
var _parts: Array[Part] = []
var _filled: Array[Socket] = []
var _mounted: Array[Device] = []
var _batteries: Array[Battery] = []
var _stuck: Array[Socket] = []
var _held_known := false
var _face := NAN
## All its shapes' bounds together, in its own frame, kept until its children
## change or move (a recompute): what the world holds clear of the sand.
var _bounds := AABB()
var _bounds_known := false
## Its collision shapes in child order, kept until its shapes change: the
## world holds each of a deck's hundreds clear of the sand every tick.
var _collision: Array[CollisionShape3D] = []
var _collision_known := false


func _ready() -> void:
	world = World.of(self)
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	_recompute()


## Fitted parts wait off the tree, so nothing else would free them.
func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_sockets_known = false
		_held_known = false
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
	if by.hands.held != null:
		return false
	return rest(not resting)


## Sets its trays resting or floating, as use does; a Console's screen too.
## Says whether it changed.
func rest(down: bool) -> bool:
	if down == resting or stats()["lift_kg"] <= 0.0 or wrecked():
		return false
	# Removing a dark tray's demand can power it again; it must not lift on the way off.
	if down and not hovering():
		lift_share = 0.0
	resting = down
	Sounds.play_at(self, Sounds.BOARD_OFF if resting else Sounds.BOARD_ON)
	return true


## What its lamps draw switched on, W; none without a lamp.
func lamp_w() -> float:
	var watts := 0.0
	for part in parts():
		watts += part.stats.get("light_w", 0.0)
	return watts


## Switches its lamps, from a Console's screen. Says whether it changed.
func switch_lamps(on: bool) -> bool:
	if on == lamps or lamp_w() <= 0.0:
		return false
	lamps = on
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


## The battery in its first filled battery slot, or stuck on it, or null.
func battery() -> Battery:
	var all := batteries()
	return all[0] if not all.is_empty() else null


## Every battery in its battery slots, and loose on its sticky faces.
func batteries() -> Array[Battery]:
	_read_held()
	return _batteries.duplicate()


## The batteries it lends its pool (Power).
func pooled() -> Array[Battery]:
	return batteries()


## Those of them its pool may draw on: a bay held to charge only gives nothing.
func supplies() -> Array[Battery]:
	return pooled()


## Its charge where it's shown, after each power tick.
func show_charge() -> void:
	if charge_light != null:
		ChargeLight.paint(charge_light, charge_share())


## How full its batteries are together, 0 to 1; 0 with none.
func charge_share() -> float:
	var held := 0.0
	var room := 0.0
	for cell in batteries():
		held += cell.charge_wh
		room += cell.capacity()
	return held / room if room > 0.0 else 0.0


## The devices seated on its sockets, or stuck on it.
func mounted() -> Array[Device]:
	_read_held()
	return _mounted.duplicate()


## A sticky face of this host as Stick sets things on it, in its own frame:
## only decks and standing masts have them (Chassis, Mast).
func sticking_frame(_piece: Device, _face: StringName) -> Transform3D:
	return Transform3D.IDENTITY


## Where on such a face a thing may sit, [min, max] in the face's frame.
func sticking_room(_face: StringName) -> Rect2:
	return Rect2(-Vector2.ONE * Stick.WIDE_HALF, Vector2.ONE * Stick.WIDE_HALF * 2.0)


## The device it's seated on, or null.
func host() -> Device:
	return get_parent() as Device


## Early-working devices need their seats before the carrier's later callback:
## fresh kinematic bodies can otherwise report the previous world pose.
func follow_mount() -> void:
	var on := host()
	if on == null:
		return
	on.follow_mount()
	for i in on._seats.size():
		var socket = on._seats[i]
		if is_instance_valid(socket) and socket.mounted == self:
			transform = socket.transform * seat_for(socket)
			return


## Whether its trays hold it up now: they lift its weight, and have the power.
func hovering() -> bool:
	return _hovering


## Whether it has a hover tray fitted.
func has_tray() -> bool:
	return not _trays.is_empty()


## What a part in a bottom mount carries its device on, or none.
static func carries(part: Part) -> StringName:
	return &"tray" if part.stats.get("lift_kg", 0.0) > 0.0 else (&"runner" if part.stats.has("glide") else &"")


## Stuck on a chassis, where it keeps its own sockets.
func on_deck() -> bool:
	return host() is Chassis


## Whether it seats in a socket: none takes a device but a chassis's own
## ways of joining (Chassis).
func fits_in(_socket: Socket) -> bool:
	return false


## Its frame's own sockets, in the catalog's order: what a save numbers.
## What's stuck on it isn't the catalog's.
func frame_sockets() -> Array[Socket]:
	var own: Array[Socket] = []
	for socket in sockets():
		if not socket.has_meta(&"socket") and not socket.stuck():
			own.append(socket)
	return own


## What's stuck on its sticky faces, as their sockets.
func stuck() -> Array[Socket]:
	_read_held()
	return _stuck.duplicate()


## Sticks a part or a device on it at a pose in its frame, on a sticky face
## whose way out is `out`, belonging to one of a deck's pieces: a socket is
## made there for it, and it's fitted or seated there as in any socket.
func stick(thing: RigidBody3D, pose: Transform3D, out: Vector3, piece: Device = null) -> Socket:
	var socket := Socket.new()
	socket.kind = Socket.STUCK
	socket.transform = pose
	socket.out = out.normalized()
	if piece != null and piece != self:
		socket.set_meta(&"piece", piece)
	add_child(socket)
	if thing is Part:
		fit(thing as Part, socket)
	else:
		mount(thing as Device, socket)
	return socket


## Takes what's stuck in a socket off again, loose where it was, and the
## socket made for it goes. What came off.
func unstick(socket: Socket) -> RigidBody3D:
	return take(socket) if socket.part != null else dismount(socket)


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
	# The light is read only where there's a panel to take it.
	var watts := 0.0
	if now["solar_w"] != 0.0:
		watts = now["solar_w"] * world.weather.felt_light(global_position + Vector3.UP * 0.5, t)
	# A turbine works planted: resting on the sand, not floating or being carried.
	if now["turbine_w"] > 0.0 and not now["can_float"] and linear_velocity.length() < 0.3:
		turbine_wind = world.weather.felt_wind(global_position, t)
		var wind := turbine_wind.length()
		var made := minf(now["turbine_w"], world.tuning.turbine_watts_per_cubic * wind * wind * wind)
		turbine_share = made / now["turbine_w"]
		watts += made
	return watts * efficiency()


## Energy actually supplied this tick; finite sources consume their store here,
## never when the Console merely asks for a watts reading.
func generate_wh(seconds: float, t: float) -> float:
	return production_w(t) * seconds / 3600.0


## What it would draw, W, if it had the power, now or at world time t: some
## devices draw by the weather they hold back, and parts that compute draw
## while they run.
func demand_w(_t := NAN) -> float:
	if wrecked():
		return 0.0
	var now := stats()
	return now["hover_w"] + now["light_w"] + now.get("draw_w", 0.0)


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
## nothing it's wrecked, dark for good. Sand blown from a way, world, marks the
## faces it struck.
func wear(share: float, from := Vector3.ZERO) -> void:
	if share <= 0.0 or wrecked():
		return
	var lost := minf(share / frame_stats.get("toughness", 1.0), durability)
	if from != Vector3.ZERO:
		var own := from.normalized() * global_basis * lost
		weathered += Vector4(own.x, own.y, own.z, lost)
	durability -= lost
	if wrecked():
		set_powered(false)
		if charge_light != null:
			ChargeLight.paint(charge_light, 0.0)


## What of its rating its wear leaves it: sand-pitted cells and a scoured
## rotor make less, and a shield draws more to hold the weather back.
func efficiency() -> float:
	return 1.0 - Tuning.current().worn_loss * (1.0 - durability)


## An appearance may adapt the generated lineage without replacing imported art.
func apply_frame_look(mesh: ArrayMesh) -> void:
	if frame_view != null:
		frame_view.mesh = mesh


## What of it wears its paint: its frame and what turns on its mast.
func painted() -> Array[MeshInstance3D]:
	return [frame_view, rotor]


## Its paint: its make's era, then what the weather took, so a deep find is
## crisp, a surface one rusty, and a wrecked frame down to the metal. Its
## maker's mark is its era's too.
func show_wear() -> void:
	var amount := Paint.age_for(self, durability)
	for view: MeshInstance3D in painted():
		if view != null:
			view.set_instance_shader_parameter(&"age", amount)
			view.set_instance_shader_parameter(&"era", Paint.row_for(self))
	for socket in sockets():
		if socket.marker != null:
			socket.marker.set_instance_shader_parameter(&"age", amount)
	_show_blast()


## The storms' damage on everything painted on it, fitted parts and joined
## pieces too: one deck, one condition.
func _show_blast() -> void:
	for child in get_children():
		if child == rotor or Paint.is_worn(child):
			Paint.show_blast(child, self, weathered, child == rotor)


func parts() -> Array[Part]:
	_read_held()
	return _parts.duplicate()


## Its sockets' parts, seated devices, batteries and stuck things, in socket order.
func _read_held() -> void:
	if _held_known:
		return
	_parts.clear()
	_filled.clear()
	_mounted.clear()
	_batteries.clear()
	_stuck.clear()
	for socket in sockets():
		var part := socket.part
		if part != null:
			_parts.append(part)
			_filled.append(socket)
		if socket.mounted != null:
			_mounted.append(socket.mounted)
		if (socket.kind == &"battery" or socket.kind == Socket.STUCK) and part is Battery:
			_batteries.append(part)
		if socket.stuck() and (part != null or socket.mounted != null):
			_stuck.append(socket)
	_held_known = true


## The socket a fitted shape or mesh belongs to, or null for the frame itself.
func socket_of(node: Node) -> Socket:
	return node.get_meta(&"socket") if node != null and node.has_meta(&"socket") else null


## Moves a part into a free socket of its kind, or one made where it sticks:
## its shapes and meshes join this body at exactly the socket's pose, and the
## part leaves the physics world.
func fit(part: Part, socket: Socket) -> void:
	assert(socket.is_open() and socket.get_parent() == self)
	Device.seat_part(part, socket)
	if socket.marker != null:
		socket.marker.visible = false
	_rise_clear_of_sand(socket.fitted)
	_recompute()


## Moves a part's shapes and meshes into the body a socket is on, at exactly
## the socket's pose, and the part leaves the tree. What sits in a socket the
## part added (a line's end on a loose hook) stays in that one.
static func seat_part(part: Part, socket: Socket) -> void:
	var body := socket.get_parent()
	for child in part.get_children():
		var node := child as Node3D
		if node == null:
			continue
		var local := node.transform
		part.remove_child(node)
		body.add_child(node)
		node.transform = socket.transform * local
		if not node.has_meta(&"socket"):
			node.set_meta(&"socket", socket)
			socket.fitted.append(node)
	if part.get_parent() != null:
		part.get_parent().remove_child(part)
	socket.part = part
	part.socket = socket


## A tray stuck under a deck resting on the sand lifts the deck onto it: a
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


## Where a device seated in a socket sits, in the socket's frame: a socket
## made where it sticks is its pose already.
func seat_for(socket: Socket) -> Transform3D:
	return Transform3D.IDENTITY if socket.stuck() else seat()


## Upright along a face's outward axis, its base on the face: how it stands
## where it's stuck, in the face's frame.
func seat() -> Transform3D:
	var base := 0.0
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null and not shape.has_meta(&"socket"):
			base = maxf(base, -(shape.transform * Catalog.bounds(shape.shape)).position.y)
	return Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, 0.0, base))


## Seats a device in a socket made where it sticks. It stays a body of its
## own, held fast on this one (frozen, and touching nothing of it) so it
## carries on working as itself: it rides with this frame, its weight joins
## it, and Power pools the two.
func mount(other: Device, socket: Socket) -> void:
	assert(socket.is_open() and socket.get_parent() == self)
	if other.get_parent() != null:
		other.get_parent().remove_child(other)
	add_child(other)
	other.transform = socket.transform * other.seat_for(socket)
	other._unseated_mode = other.freeze_mode
	other.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	other.freeze = true
	other.linear_velocity = Vector3.ZERO
	other.angular_velocity = Vector3.ZERO
	other.touch_none_of(self, true)
	socket.mounted = other
	_seats.append(socket)
	if socket.marker != null:
		socket.marker.visible = false
	# What's stuck on keeps its sockets, so its weight can change there.
	other.parts_changed.connect(_recompute)
	_recompute()


## Seated, it and what's seated on it touch nothing of what carries it, all
## the way down; unseated, they touch it again.
func touch_none_of(host: Device, seated: bool) -> void:
	var riding: Array[Device] = [self]
	while not riding.is_empty():
		var each: Device = riding.pop_back()
		riding.append_array(each.mounted())
		var at := host
		while at != null:
			if seated:
				each.add_collision_exception_with(at)
			else:
				each.remove_collision_exception_with(at)
			at = at.host()


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
			_unmade(socket)
	if kept.size() != _seats.size():
		_seats = kept
		_recompute()


## Takes a seated device off again, loose where it sat; the caller lifts it
## clear along the socket's way out. A socket made for it goes with it.
func dismount(socket: Socket) -> Device:
	var other := socket.mounted
	assert(other != null)
	var pose := other.global_transform
	remove_child(other)
	_holder().add_child(other)
	other.global_transform = pose
	other.touch_none_of(self, false)
	other.freeze_mode = other._unseated_mode
	other.freeze = false
	other.linear_velocity = linear_velocity
	if other.parts_changed.is_connected(_recompute):
		other.parts_changed.disconnect(_recompute)
	socket.mounted = null
	_seats.erase(socket)
	if socket.marker != null:
		socket.marker.visible = true
	_unmade(socket)
	_recompute()
	return other


## A socket made where something stuck goes once it's empty.
func _unmade(socket: Socket) -> void:
	if socket.stuck() and socket.get_parent() == self:
		remove_child(socket)
		socket.queue_free()


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
	return _unfit(socket, false)


## Takes a fitted part out as take does, but whatever sits in the sockets it
## added stays on it: a hook popped off a deck keeps its line.
func pop(socket: Socket) -> Part:
	return _unfit(socket, true)


func _unfit(socket: Socket, whole: bool) -> Part:
	var part := socket.part
	assert(part != null)
	var nodes: Array[Node3D] = []
	nodes.append_array(socket.fitted)
	for node in socket.fitted:
		var added := node as Socket
		if added != null and added.part != null:
			if whole:
				nodes.append_array(_held_in(added))
			else:
				take(added)
	for node in nodes:
		var local := socket.transform.affine_inverse() * node.transform
		remove_child(node)
		if node.get_meta(&"socket") == socket:
			node.remove_meta(&"socket")
		part.add_child(node)
		node.transform = local
		# Out of a device, nothing powers its lamp.
		if node is Light3D:
			node.visible = false
		elif Paint.is_worn(node):
			(node as GeometryInstance3D).set_instance_shader_parameter(&"lit", 0.0)
			# A part has no condition of its own yet: it leaves the device's marks behind.
			(node as GeometryInstance3D).set_instance_shader_parameter(&"blasted", Vector4.ZERO)
	socket.fitted.clear()
	socket.part = null
	part.socket = null
	if socket.marker != null:
		socket.marker.visible = true
	_holder().add_child(part)
	part.global_transform = global_transform * socket.transform
	part.linear_velocity = linear_velocity
	_unmade(socket)
	_recompute()
	return part


## Everything fitted in a socket a part added, and in any that one added.
static func _held_in(added: Socket) -> Array[Node3D]:
	var found: Array[Node3D] = []
	found.append_array(added.fitted)
	for node in added.fitted:
		if node is Socket and (node as Socket).part != null:
			found.append_array(_held_in(node))
	return found


## Everything the device can do, from the frame and what's fitted.
func stats() -> Dictionary:
	var total := {"mass": mass, "catch": wind_catch(), "capacity_wh": 0.0, "hooks": 0,
		"lift_kg": 0.0, "solar_w": 0.0, "light_w": 0.0, "plants": 0, "turbine_w": 0.0}
	# The frame's, then each part's in its socket's order, as parts() lists them.
	_sum_into(total, frame_stats)
	var charge := 0.0
	var cells := 0
	# A tray lifts as far as it faces down in its body, none on a wall: what
	# it lifts counts that share. A lossier make's draws more a kilogram.
	var lifts := 0.0
	var draws_kg := 0.0
	# Only a socket with a part adds anything: a deck's thousand are mostly empty.
	_read_held()
	for socket in _filled:
		var part := socket.part
		_sum_into(total, part.stats)
		var lift: float = part.stats.get("lift_kg", 0.0) * Device.facing_down(socket.outward())
		lifts += lift
		draws_kg += lift * part.stats.get("hover_draw", 1.0)
		if (socket.kind == &"battery" or socket.stuck()) and part is Battery:
			charge += (part as Battery).charge_wh
			cells += 1
	total["lift_kg"] = lifts
	if not lamps:
		total["light_w"] = 0.0
	total["runners"] = glider.runners.size() if glider != null else 0
	total["hover_draw"] = draws_kg / total["lift_kg"] if total["lift_kg"] > 0.0 else 1.0
	total["can_float"] = total["lift_kg"] >= mass
	total["resting"] = resting
	total["hovering"] = total["can_float"] and powered and lift_share > 0.0
	# Its trays draw for what they hold up, or dark, for its weight, what
	# lifting it again would take. Seated, its own tray holds nothing up.
	total["hover_w"] = (carried_kg if powered else mass) * world.tuning.hover_watts_per_kg * total["hover_draw"] \
		if total["can_float"] and not resting and world != null and host() == null else 0.0
	if cells > 0:
		total["charge_wh"] = charge
	total["durability"] = durability
	return total


## How squarely a way out faces down, 1 straight down to 0 level or up.
static func facing_down(out: Vector3) -> float:
	return clampf(-out.normalized().y, 0.0, 1.0)


static func _sum_into(total: Dictionary, source: Dictionary) -> void:
	for key: String in source:
		total[key] = total.get(key, 0) + source[key]


func _recompute() -> void:
	_shapes_changed()
	var weight := 0.0
	var moment := Vector3.ZERO
	for frame: Array in _frame_masses():
		weight += frame[0]
		moment += frame[0] * frame[1]
	for socket in sockets():
		if socket.part != null:
			weight += _fitted_mass(socket)
			moment += _fitted_mass(socket) * _middle(socket.fitted)
		elif socket.mounted != null:
			# Where its weight is: what's stuck high on it raises its host's middle.
			weight += socket.mounted.mass
			moment += socket.mounted.mass * (socket.mounted.transform * socket.mounted.center_of_mass)
	mass = weight
	center_of_mass = moment / weight
	_trays.clear()
	for socket in sockets():
		if socket.part != null and socket.part.stats.get("lift_kg", 0.0) > 0.0:
			_trays.append(_tray(socket))
	_keels = Runners.keels(self)
	var runners := Runners.of(self)
	if runners.is_empty():
		glider = null
	else:
		if glider == null:
			glider = Runners.new()
		glider.runners = runners
	var now := stats()
	_hovering = now["hovering"]
	_show_blast()
	# Lamps shine, and lenses and emitters glow, only while it has the power,
	# and a lamp only while it's switched on.
	if frame_view != null:
		frame_view.set_instance_shader_parameter(&"lit", 1.0 if powered else 0.0)
	for socket in sockets():
		var shines: bool = powered and (lamps or socket.part == null or socket.part.stats.get("light_w", 0.0) <= 0.0)
		for node in socket.fitted:
			if node is Light3D:
				node.visible = shines
			elif Paint.is_worn(node):
				(node as GeometryInstance3D).set_instance_shader_parameter(&"lit", 1.0 if shines else 0.0)
	# A resting body sleeps, and a sleeping one ignores the tray's lift and
	# the runners' hold.
	can_sleep = not _hovering and glider == null
	if not can_sleep:
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
	_collision_known = false


## Its collision shapes, in child order, without walking its other children.
func collision_shapes() -> Array[CollisionShape3D]:
	if not _collision_known:
		_collision.clear()
		for child in get_children():
			if child is CollisionShape3D:
				_collision.append(child)
		_collision_known = true
	return _collision.duplicate()


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


## What a fitted part adds to its host's weight; a mast's sail, simulated
## apart, adds none (Mast).
func _fitted_mass(socket: Socket) -> float:
	return socket.part.mass


## Its frame's weight and where it sits, in its own frame, as [kg, position]s.
func _frame_masses() -> Array:
	return [[frame_mass, frame_middle]]


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
	# is left a tick behind each tick, and on a floating deck that adds up.
	_drop_freed_seats()
	for socket in _seats:
		socket.mounted.transform = socket.transform * socket.mounted.seat_for(socket)
	if world == null:
		return
	var tuning := world.tuning
	var goal := 0.0 if resting else 1.0
	if lift_share != goal:
		lift_share = move_toward(lift_share, goal, delta / tuning.hover_settle_seconds)
	carried_kg = 0.0
	if freeze:
		return
	if glider != null:
		glider.glide(self, world, delta)
	if _hovering:
		_lift(tuning, delta)
		for keel: Array in _keels:
			Runners.bite(self, keel, carried_kg * world.gravity / _keels.size(), delta)
	if not _seats.is_empty() and global_basis.y.normalized().dot(Vector3.UP) < cos(TIPPED):
		_rest_seated(delta)


## Tipped over, a chassis and its seated devices meet the sand at their
## real frame corners and a mast at its head, all together, so the camp rests
## on its edges and masthead rather than through sand.
func _rest_seated(h: float) -> void:
	var started := Time.get_ticks_usec()
	var points := PackedVector3Array()
	var clearances := PackedFloat32Array()
	var riding: Array[Device] = []
	if self is Chassis:
		riding.append(self)
	else:
		riding.append_array(mounted())
	while not riding.is_empty():
		var each: Device = riding.pop_back()
		riding.append_array(each.mounted())
		# The native carrier stays ahead of terrain speculation; seated frames are frozen.
		var clearance := world.tuning.runner_clearance if each == self else 0.0
		if each is Mast:
			points.append((each as Mast).masthead())
			clearances.append(0.0)
		if each == self and self is Chassis:
			(self as Chassis).frame_contact_points(points, clearances, clearance)
			continue
		var pose := each.global_transform
		for child in each.get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.shape == null or shape.disabled or shape.has_meta(&"socket"):
				continue
			var box := Catalog.bounds(shape.shape)
			var to_world := pose * shape.transform
			for i in 8:
				points.append(to_world * box.get_endpoint(i))
				clearances.append(clearance)
	Runners.rest_on(self, world, points, clearances, world.tuning.tipped_grip, h)
	rest_us += (Time.get_ticks_usec() - started - rest_us) * 0.05


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
	# The pose holds through the tick: read once, not per corner.
	var frame := global_transform
	var middle := frame * center_of_mass
	var turn := PhysicsServer3D.body_get_direct_state(get_rid()).inverse_inertia_tensor
	var rise_at := linear_velocity.y
	var spin := angular_velocity
	var lifted := 0.0
	var damped := 0.0
	var twist := Vector3.ZERO
	var pushes := PackedFloat64Array()
	for tray: Array in _trays:
		var corners: PackedVector3Array = tray[1]
		var facing := clampf(-(frame.basis * (tray[2] as Vector3)).normalized().y, 0.0, 1.0)
		var most: float = tray[0] * g * facing
		var points := frame * corners
		pushes.resize(corners.size())
		var sand := 0.0
		for at in points:
			sand += world.height_under(at) / corners.size()
		var all := 0.0
		for i in points.size():
			var push := most / corners.size() * exp(minf((full - points[i].y + sand) / reach, 30.0))
			pushes[i] = push
			all += push
		var over := maxf(all / most, 1.0) if most > 0.0 else 1.0
		var spare := most - all / over
		for i in points.size():
			var push := pushes[i] / over
			apply_force(Vector3.UP * push, points[i] - frame.origin)
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
	return [socket.part.stats.lift_kg, corners, socket.outward()]


## How high its middle rides over level sand, its load shared out as its
## trays lift: where to set it down floating. Too heavy, on the sand.
func rest_height() -> float:
	if glider != null:
		return glider.rest_height()
	var lift := 0.0
	var depth := 0.0
	var count := 0
	for tray: Array in _trays:
		lift += tray[0] * Device.facing_down(tray[2])
		for corner: Vector3 in tray[1]:
			depth -= corner.y
			count += 1
	if count == 0 or lift < mass:
		return -Finds.bounds(self).position.y + 0.02
	var tuning := Tuning.current()
	return tuning.hover_height + tuning.hover_falloff * log(lift / mass) + depth / count
