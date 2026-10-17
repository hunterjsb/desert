class_name Chassis
extends Device
## A chassis piece: a flat square frame with a ring on each edge, a bottom
## mount for its own tray and a deck mount on top, and nothing else. Pieces
## join edge to edge by their rings into a deck. A piece brought to a free
## ring snaps flush beside it, and its frame, sockets and whatever is in them
## move into the first piece's body, as a fitted part's shapes do: a deck is
## one rigid body in whatever shape it's laid out, with nothing between its
## pieces to wobble. Off again, the last joined first, a piece takes back all
## that's its own. A deck floats only while every piece has its tray, and
## what stands on its deck mounts shares its power.

## A piece's width, m: the pitch its neighbours sit at across its rings.
const WIDTH := 1.0
const QUARTER := PI / 2.0

## The pieces joined to this one, in the order they joined. Each waits off
## the tree meanwhile, its own nodes living in this body.
var joined: Array[Chassis] = []
## Joined: the deck it's part of, the ring it joined at, its place on the
## first piece's grid and how many quarter turns it sits at there.
var deck: Chassis
var joined_at: Socket
var cell := Vector2i.ZERO
var turns := 0

## Its own frame and sockets while they live in the deck's body.
var _own: Array[Node3D] = []


## Every piece of the deck, the first one first.
func pieces() -> Array[Chassis]:
	var all: Array[Chassis] = [self]
	all.append_array(joined)
	return all


## The piece joined last, the one take has off first; null on its own.
func last() -> Chassis:
	return null if joined.is_empty() else joined.back()


## Where a joined piece sits in the deck's frame.
func pose() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, turns * QUARTER), Vector3(cell.x, 0.0, cell.y) * WIDTH)


## The piece of the deck under a place in the world, or null.
func piece_at(point: Vector3) -> Chassis:
	var local := global_transform.affine_inverse() * point
	var at := Vector2i(roundi(local.x / WIDTH), roundi(local.z / WIDTH))
	for piece in pieces():
		if piece.cell == at:
			return piece
	return null


func frame_sockets() -> Array[Socket]:
	var own: Array[Socket] = []
	if deck != null:
		for node in _own:
			if node is Socket:
				own.append(node)
		return own
	for socket in super():
		if not socket.has_meta(&"piece"):
			own.append(socket)
	return own


## A lone piece fits a free ring of a deck that has room beyond it.
func fits_in(socket: Socket) -> bool:
	var other := socket.get_parent() as Chassis
	return other != null and other._turns_for(self, socket, Basis.IDENTITY) >= 0


## Where a piece joined at one of this deck's rings would sit, in the ring's
## frame: flush beyond it, turned the way nearest `held`, how it's held.
func seat_in(ring: Socket, held: Basis) -> Transform3D:
	var other := ring.get_parent() as Chassis
	var k := maxi(other._turns_for(self, ring, held), 0)
	return ring.transform.affine_inverse() * other._pose_at(ring, k)


## Joins a lone piece at a free ring of this deck, turned `k` quarter turns
## (or the way it now faces): everything of it moves into this body exactly
## where it sat beside it, and it leaves the physics world.
func join(piece: Chassis, ring: Socket, k := -1) -> void:
	if k < 0:
		k = _turns_for(piece, ring, piece.global_basis)
	assert(k >= 0 and ring.get_parent() == self)
	piece.cell = _cell_of(ring) + _step(ring)
	piece.turns = k
	piece.deck = self
	piece.joined_at = ring
	var at := piece.pose()
	if piece.get_parent() != null:
		piece.get_parent().remove_child(piece)
	piece._own.clear()
	var seated: Array[Device] = []
	for child in piece.get_children():
		var node := child as Node3D
		if node == null:
			continue
		var local := node.transform
		piece.remove_child(node)
		add_child(node)
		node.transform = at * local
		if node is Device:
			seated.append(node)
		elif not node.has_meta(&"socket"):
			node.set_meta(&"piece", piece)
			piece._own.append(node)
	for each in seated:
		_take_seat(piece, self, each)
	joined.append(piece)
	# One deck, one soundness: the more worn of the two.
	durability = minf(durability, piece.durability)
	_after_change()
	var shapes: Array[Node3D] = []
	for node in piece._own:
		if node is CollisionShape3D:
			shapes.append(node)
	_rise_clear_of_sand(shapes)


## Takes the last joined piece off again, with all that's its own, loose
## where it sat; the caller moves it clear along the ring it joined at.
func unjoin() -> Chassis:
	var piece: Chassis = joined.pop_back()
	var back := piece.pose().affine_inverse()
	var nodes: Array[Node3D] = []
	for child in get_children():
		if child is Node3D and _piece_of(child) == piece:
			nodes.append(child)
	for node in nodes:
		var local := back * node.transform
		remove_child(node)
		piece.add_child(node)
		node.transform = local
		node.remove_meta(&"piece")
	for node in nodes:
		if node is Device:
			_take_seat(self, piece, node)
	var pose_was := global_transform * piece.pose()
	piece._own.clear()
	piece.deck = null
	piece.joined_at = null
	piece.cell = Vector2i.ZERO
	piece.turns = 0
	piece.durability = durability
	piece.resting = resting
	piece.lift_share = lift_share
	_holder().add_child(piece)
	World.of(self).teleport(piece, pose_was)
	piece.linear_velocity = linear_velocity
	piece.angular_velocity = angular_velocity
	piece._after_change()
	_after_change()
	return piece


## The quarter turns a piece would join at a ring at, nearest `held`, or -1
## if it can't: only a lone, sound piece joins, at a free ring with room
## beyond it, and only where no hook stands in the edges it would meet.
func _turns_for(piece: Chassis, ring: Socket, held: Basis) -> int:
	if piece == self or deck != null or piece.deck != null or not piece.joined.is_empty() \
			or ring.kind != &"ring" or not ring.is_open() or ring.get_parent() != self \
			or wrecked() or piece.wrecked():
		return -1
	var to := _cell_of(ring) + _step(ring)
	var cells := {}
	for each in pieces():
		cells[each.cell] = true
	if cells.has(to):
		return -1
	# A hook on a neighbour's edge facing the new place would stand in it.
	for socket in sockets():
		if socket.kind == &"ring" and not socket.has_meta(&"socket") and socket.part != null \
				and _cell_of(socket) + _step(socket) == to:
			return -1
	var facing := global_basis.orthonormalized().inverse() * held.orthonormalized()
	var yaw := atan2(-facing.x.z, facing.x.x) if Vector2(facing.x.x, facing.x.z).length() > 0.3 \
		else atan2(facing.z.x, facing.z.z)
	var best := -1
	var nearest := INF
	for k in 4:
		if not _bare_toward(piece, k, to, cells):
			continue
		var off := absf(angle_difference(yaw, k * QUARTER))
		if off < nearest - 1e-4:
			nearest = off
			best = k
	return best


## Whether a piece turned k quarter turns at a place has no hook on any of
## its own edges that would meet a neighbour.
func _bare_toward(piece: Chassis, k: int, at: Vector2i, cells: Dictionary) -> bool:
	var turn := Basis(Vector3.UP, k * QUARTER)
	for socket in piece.frame_sockets():
		if socket.kind != &"ring" or socket.part == null:
			continue
		var out := turn * socket.transform.basis.z
		if cells.has(at + Vector2i(roundi(out.x), roundi(out.z))):
			return false
	return true


## Where a piece joined at a ring sits in the deck's frame, turned k quarter turns.
func _pose_at(ring: Socket, k: int) -> Transform3D:
	var at := _cell_of(ring) + _step(ring)
	return Transform3D(Basis(Vector3.UP, k * QUARTER), Vector3(at.x, 0.0, at.y) * WIDTH)


## The grid place of the piece a socket of this deck belongs to; the first
## piece's is the middle of the grid.
func _cell_of(socket: Socket) -> Vector2i:
	return (socket.get_meta(&"piece") as Chassis).cell if socket.has_meta(&"piece") else cell


## The way across a ring, one place on the grid.
static func _step(ring: Socket) -> Vector2i:
	var out := ring.transform.basis.z
	return Vector2i(roundi(out.x), roundi(out.z))


## The piece a node in this body is its own, through the socket it's
## fitted in or seated on: null for the first piece.
func _piece_of(node: Node) -> Chassis:
	while node != null:
		if node.has_meta(&"piece"):
			return node.get_meta(&"piece")
		if node.has_meta(&"socket"):
			node = node.get_meta(&"socket")
		elif node is Device and node.get_parent() == self:
			node = seat_of(node)
		else:
			return null
	return null


## A device seated on a deck mount moves from one body to another with its socket.
static func _take_seat(from: Chassis, to: Chassis, seated: Device) -> void:
	var socket: Socket = null
	for each in from._seats:
		if each.mounted == seated:
			socket = each
	from._seats.erase(socket)
	to._seats.append(socket)
	seated.remove_collision_exception_with(from)
	seated.add_collision_exception_with(to)
	if seated.parts_changed.is_connected(from._recompute):
		seated.parts_changed.disconnect(from._recompute)
		seated.parts_changed.connect(to._recompute)
	seated.transform = socket.transform * seated.seat()


## Edge rings between two pieces close, the rest open; then its weight,
## look and what it can do follow.
func _after_change() -> void:
	var cells := {}
	for piece in pieces():
		cells[piece.cell] = true
	for socket in sockets():
		if socket.kind != &"ring" or socket.has_meta(&"socket"):
			continue
		socket.closed = cells.has(_cell_of(socket) + _step(socket))
		if socket.marker != null:
			socket.marker.visible = socket.is_open()
	# A deck, or one with something standing on it, is too much to carry.
	carryable = joined.is_empty() and mounted().is_empty()
	remove_meta(&"hands_box")
	show_wear()
	_recompute()


func mount(other: Device, socket: Socket) -> void:
	super(other, socket)
	carryable = false


func dismount(socket: Socket) -> Device:
	var other := super(socket)
	carryable = joined.is_empty() and mounted().is_empty()
	return other


func _frame_masses() -> Array:
	var frames := super()
	for piece in joined:
		frames.append([piece.frame_mass, piece.pose().origin])
	return frames


## Its trays lift it only while every piece has one: a tray short, and the
## whole deck rests on the sand. A deck stays level, so the wind meets its
## pieces and what's fitted to them side on, and takes what stands on it too.
func stats() -> Dictionary:
	var now := super()
	var count := pieces().size()
	var trays := 0
	var face := 0.0
	for piece in pieces():
		face += piece.frame_stats.get("face_m2", 0.0)
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.has_meta(&"socket"):
			var size := (shape.transform * Catalog.bounds(shape.shape)).size
			face += maxf(size.x, size.z) * size.y
		var socket := child as Socket
		if socket != null and socket.kind == &"bottom" and not socket.has_meta(&"socket") and socket.part != null:
			trays += 1
	var catch := face * world.tuning.wind_catch_per_m2 if world != null else 0.0
	for seated in mounted():
		catch += seated.stats()["catch"]
	now["catch"] = catch
	now["pieces"] = count
	now["trays_short"] = count - trays
	now["can_float"] = trays == count and now["lift_kg"] >= mass
	now["hovering"] = now["can_float"] and powered and lift_share > 0.0
	now["hover_w"] = mass * world.tuning.hover_watts_per_kg \
		if now["can_float"] and not resting and world != null else 0.0
	return now


func show_wear() -> void:
	super()
	for piece in joined:
		var layer: StringName = piece.get_meta(&"layer", &"")
		if piece.frame_view != null:
			piece.frame_view.set_instance_shader_parameter(&"age", Paint.age_of(layer, durability))
			piece.frame_view.set_instance_shader_parameter(&"era", Paint.era_of(layer))


## Held off the sand under its highest piece, so a long deck over a dune
## never drags an end through it.
func _hover_gap(height: float) -> float:
	var low := -INF
	for piece in pieces():
		var at := global_transform * piece.pose().origin
		low = maxf(low, world.height_under(at) + height - at.y)
	return low


## Held level by its own inertia about each axis: a long deck turns harder
## along its length than across it.
func _keep_upright(tuning: Tuning) -> void:
	var state := PhysicsServer3D.body_get_direct_state(get_rid())
	var turn := TAU * tuning.hover_upright_hertz
	var tilt := global_basis.y.normalized().cross(Vector3.UP)
	var rocking := angular_velocity - Vector3.UP * angular_velocity.y
	var torque := state.inverse_inertia_tensor.inverse() * (turn * turn * tilt - 2.0 * tuning.hover_damping * turn * rocking)
	apply_torque(torque - Vector3.UP * torque.dot(Vector3.UP))


## Pieces joined to it wait off the tree, so nothing else would free them.
## (Device's own runs too, freeing what's fitted.)
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for piece in joined:
			if is_instance_valid(piece):
				piece.free()
