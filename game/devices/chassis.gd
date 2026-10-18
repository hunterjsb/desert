class_name Chassis
extends Device
## A chassis piece: a flat square frame with a ring on each edge, a bottom
## mount for its own tray and a deck mount on top, and nothing else. Pieces
## join edge to edge by their rings into a deck. A piece brought to a free
## ring snaps flush beside it, and its frame, sockets and whatever is in them
## move into the first piece's body, as a fitted part's shapes do: a deck is
## one rigid body in whatever shape it's laid out, with nothing between its
## pieces to wobble. Off again, a bare piece the rest still holds together
## without takes back all that's its own. Its trays lift it where they are,
## and what stands on its deck mounts shares its power.

## A piece's width, m: the pitch its neighbours sit at across its rings.
const WIDTH := 1.0
const QUARTER := PI / 2.0
## The ways across a piece's four edges, in the order a deck is walked.
const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

## The pieces joined to this one, each after one it sits beside, as they
## joined or as a save rebuilds them. Each waits off the tree meanwhile, its
## own nodes living in this body.
var joined: Array[Chassis] = []
## Joined: the deck it's part of, the ring it sits across from one before it,
## its place on the first piece's grid and how many quarter turns it sits at
## there.
var deck: Chassis
var joined_at: Socket
var cell := Vector2i.ZERO
var turns := 0

## Its own frame and sockets while they live in the deck's body.
var _own: Array[Node3D] = []
## What its pieces and what's fitted to them show the wind, m², until they change.
var _flat_face := NAN


## Every piece of the deck, the first one first.
func pieces() -> Array[Chassis]:
	var all: Array[Chassis] = [self]
	all.append_array(joined)
	return all


## Whether a piece can come off: the rest of the deck still holds together
## without it. A lone piece is no deck to come off.
func outer(piece: Chassis) -> bool:
	if joined.is_empty() or not pieces().has(piece):
		return false
	var left := {}
	for each in pieces():
		if each != piece:
			left[each.cell] = true
	var start: Vector2i = left.keys()[0]
	var reached := {start: true}
	var next: Array[Vector2i] = [start]
	while not next.is_empty():
		var at: Vector2i = next.pop_back()
		for step: Vector2i in STEPS:
			if left.has(at + step) and not reached.has(at + step):
				reached[at + step] = true
				next.append(at + step)
	return reached.size() == left.size()


## Whether a piece comes off by hand: bare, nothing fitted to it and nothing
## standing on it, and outer. Take anywhere else holds the whole deck, so
## dragging a deck never takes it apart (Hunter, 2026-10-17).
func comes_off(piece: Chassis) -> bool:
	if not outer(piece):
		return false
	for socket in sockets():
		if not socket.has_meta(&"socket") and _cell_of(socket) == piece.cell \
				and (socket.part != null or socket.mounted != null):
			return false
	return true


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


## Takes an outer piece off again, with all that's its own and whatever
## stands on it, loose where it sat; the caller moves it clear across the
## ring it leaves (ring_to). The first piece is this body, so for it another
## piece takes its place first and what comes off is that one's.
func detach(piece: Chassis) -> Chassis:
	assert(outer(piece))
	if piece == self:
		piece = _reroot(joined[0])
	joined.erase(piece)
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
	piece.linear_velocity = linear_velocity + angular_velocity.cross(pose_was.origin - global_transform * center_of_mass)
	piece.angular_velocity = angular_velocity
	_reorder()
	piece._after_change()
	_after_change()
	return piece


## The ring of the deck facing a place in the world from beside it, or null:
## where a piece just off it came across.
func ring_to(point: Vector3) -> Socket:
	var local := global_transform.affine_inverse() * point
	var at := Vector2i(roundi(local.x / WIDTH), roundi(local.z / WIDTH))
	for socket in sockets():
		if socket.kind == &"ring" and not socket.has_meta(&"socket") and _cell_of(socket) + _step(socket) == at:
			return socket
	return null


## Makes a joined piece's place this body's own, everything kept where it is
## in the world: this body moves to that place, and the piece that stood
## there takes over the first piece's frame and sockets, to come off as it.
func _reroot(to: Chassis) -> Chassis:
	var pose_was := global_transform
	var shift := to.pose()
	var back := shift.affine_inverse()
	var first: Array[Node3D] = []
	for child in get_children():
		var node := child as Node3D
		if node == null:
			continue
		node.transform = back * node.transform
		if node is Device or node.has_meta(&"socket"):
			continue
		if node.get_meta(&"piece", null) == to:
			node.remove_meta(&"piece")
		elif not node.has_meta(&"piece"):
			node.set_meta(&"piece", to)
			first.append(node)
	to._own = first
	for each in joined:
		if each != to:
			_place(each, back * each.pose())
	_place(to, back)
	var view := frame_view
	frame_view = to.frame_view
	to.frame_view = view
	var layer: Variant = get_meta(&"layer", null)
	var theirs: Variant = to.get_meta(&"layer", null)
	for pair: Array in [[self, theirs], [to, layer]]:
		if pair[1] == null:
			pair[0].remove_meta(&"layer")
		else:
			pair[0].set_meta(&"layer", pair[1])
	World.of(self).teleport(self, pose_was * shift)
	_recompute()
	for seated in mounted():
		World.of(self).teleport(seated, seated.global_transform)
	return to


## A joined piece's place and turn on the grid, from its pose in the deck's frame.
static func _place(piece: Chassis, at: Transform3D) -> void:
	piece.cell = Vector2i(roundi(at.origin.x / WIDTH), roundi(at.origin.z / WIDTH))
	var yaw := atan2(at.basis.x.z, at.basis.x.x)
	piece.turns = posmod(-roundi(yaw / QUARTER), 4)


## Puts the joined pieces in an order each joins one before it, outward from
## this one, each at the ring of the one it joins: how a save rebuilds it.
func _reorder() -> void:
	var at := {}
	for piece in joined:
		at[piece.cell] = piece
	var order: Array[Chassis] = []
	var next: Array[Chassis] = [self]
	var i := 0
	while i < next.size():
		var from: Chassis = next[i]
		i += 1
		for step: Vector2i in STEPS:
			var piece: Chassis = at.get(from.cell + step)
			if piece == null or order.has(piece):
				continue
			order.append(piece)
			next.append(piece)
			for socket in sockets():
				if socket.kind == &"ring" and not socket.has_meta(&"socket") and _cell_of(socket) == from.cell \
						and _step(socket) == step:
					piece.joined_at = socket
	joined = order


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


func stats() -> Dictionary:
	var now := super()
	now["pieces"] = pieces().size()
	return now


## Flat, the wind meets its pieces and what's fitted to them side on, and
## takes what stands on it too.
func wind_catch() -> float:
	if is_nan(_flat_face):
		_flat_face = 0.0
		for piece in pieces():
			_flat_face += piece.frame_stats.get("face_m2", 0.0)
		for child in get_children():
			var shape := child as CollisionShape3D
			if shape != null and shape.has_meta(&"socket"):
				var size := (shape.transform * Catalog.bounds(shape.shape)).size
				_flat_face += maxf(size.x, size.z) * size.y
	var catch := _flat_face * world.tuning.wind_catch_per_m2 if world != null else 0.0
	for seated in mounted():
		catch += seated.wind_catch()
	return catch


func _shapes_changed() -> void:
	super()
	_flat_face = NAN


func show_wear() -> void:
	super()
	for piece in joined:
		if piece.frame_view != null:
			piece.frame_view.set_instance_shader_parameter(&"age", Paint.age_for(piece, durability))
			piece.frame_view.set_instance_shader_parameter(&"era", Paint.row_for(piece))


## Pieces joined to it wait off the tree, so nothing else would free them.
## (Device's own runs too, freeing what's fitted.)
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for piece in joined:
			if is_instance_valid(piece):
				piece.free()
