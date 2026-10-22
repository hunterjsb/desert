class_name Chassis
extends Device
## A chassis piece: a flat square whose whole top and bottom are sticky, with
## a ring on each edge, and nothing else. Anything sticks anywhere it fits on
## its faces (Stick): parts join its body as fitted parts do, devices stay
## bodies of their own held fast on it, and all of it is one power pool.
## Pieces join edge to edge by their rings into a deck; a frame stuck square
## on a piece takes a piece on each of its other faces, upright as a wall or
## flat as a shelf. A piece brought to a free ring snaps flush beside it, any
## hook in its way popping off and any loose part there moved clear, a line on
## either still tied, and its frame, sockets and whatever is on them move into
## the first piece's body, as a fitted part's shapes do: a deck is one rigid
## body in whatever shape it's laid out, with nothing between its pieces to
## wobble. Off again, a bare piece the rest still holds together without takes
## back all that's its own. Its trays lift it where they are, toward the sand
## they face.

## A piece's width, m: the pitch its neighbours sit at across its rings, and
## how thick it is.
const WIDTH := 1.0
const THICK := 0.12
## The visible inset panel sits below its surrounding rails and corner caps.
const PANEL_INSET := 0.08
const PANEL_DROP := 0.02
const QUARTER := PI / 2.0
## What a join moves out of its way lands this far past the deck's edge, m.
const CLEAR := 0.1
## The ways across a piece's four edges, in the order a deck is walked.
const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## Its two sticky faces, in its own frame: +Z out of the face, +X along the
## piece's own, so a thing's place on one is (x, y) in it.
const TOP := &"top"
const BOTTOM := &"bottom"
const FACES := {
	TOP: Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0.0, THICK * 0.5, 0.0)),
	BOTTOM: Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, -THICK * 0.5, 0.0)),
}
## Off the grid, a piece on a frame has no grid place: far off it.
const OFF_GRID := Vector2i(1 << 20, 1 << 20)
## A lone piece carries in your hands at most this heavy, kg: bare, or with
## a tray or a battery stuck on it; more, and you take hold of it to drag it.
const CARRIES_KG := 16.0

## The pieces joined to this one, each after one it sits beside or on a
## frame it hangs from, as they joined or as a save rebuilds them. Each waits
## off the tree meanwhile, its own nodes living in this body.
var joined: Array[Chassis] = []
## Joined: the deck it's part of, the ring it sits across from one before it
## or the frame's face it's on, its place on the first piece's grid and how
## many quarter turns it sits at there.
var deck: Chassis
var joined_at: Socket
var cell := Vector2i.ZERO
var turns := 0

## Its own frame and sockets while they live in the deck's body.
var _own: Array[Node3D] = []
## As a camp: the day it's moving in, where you are, and where it stood as
## that day began, world metres.
var _today := -1
var _day_from := Vector2.ZERO
## What the wind grabs of it but its whole faces, until they change.
var _loose := NAN
## The wind on its whole faces, and the lee they cast.
var faces := Faces.new()

class FrameContact:
	var shape: CollisionShape3D
	var source: Shape3D
	var corners := PackedVector3Array()

var _contact_frames: Array[FrameContact] = []
var _contact_resources: Array[Shape3D] = []
var _contact_frames_known := false


## Every piece of the deck, the first one first.
func pieces() -> Array[Chassis]:
	var all: Array[Chassis] = [self]
	all.append_array(joined)
	return all


## The deck as your camp: its pieces, every part fitted to them, frames
## among them, and every device stuck on it with what's fitted to that, all
## the way up. One pool, as its power is.
func camp() -> Array[Node]:
	var all: Array[Node] = []
	all.append_array(pieces())
	var devices: Array[Device] = [self]
	while not devices.is_empty():
		var each: Device = devices.pop_back()
		if each != self:
			all.append(each)
		all.append_array(each.parts())
		devices.append_array(each.mounted())
	return all


## The pieces that lie flat on the deck's grid, joined edge to edge.
func grid() -> Array[Chassis]:
	return pieces().filter(func(p: Chassis) -> bool: return not p.on_frame())


## Joined on a frame's face: a wall, or a shelf.
func on_frame() -> bool:
	return joined_at != null and joined_at.kind == &"face"


## Whether a piece can come off: the rest of the deck still holds together
## without it. A lone piece is no deck to come off; one on a frame holds
## nothing else up.
func outer(piece: Chassis) -> bool:
	if joined.is_empty() or not pieces().has(piece):
		return false
	if piece.on_frame():
		return true
	var left := {}
	for each in grid():
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
## stuck on it, and outer. Take anywhere else holds the whole deck, so
## dragging a deck never takes it apart (Hunter, 2026-10-17).
func comes_off(piece: Chassis) -> bool:
	if piece == null or not outer(piece):
		return false
	for socket in sockets():
		if not socket.has_meta(&"socket") and own_piece(socket) == piece \
				and (socket.part != null or socket.mounted != null):
			return false
	return true


## Why what's in a socket won't come out by hand, or "": a frame holds the
## walls and shelf on its faces.
func holds(socket: Socket) -> String:
	var frame := socket.part as Frame
	if frame != null and frame.faces().values().any(func(f: Socket) -> bool: return f.closed):
		return "take its walls off first"
	return ""


## Where a joined piece sits in the deck's frame: on the grid, or on its
## frame's face.
func pose() -> Transform3D:
	if on_frame():
		return joined_at.transform * Frame.piece_seat()
	return Transform3D(Basis(Vector3.UP, turns * QUARTER), Vector3(cell.x, 0.0, cell.y) * WIDTH)


## A piece's sticky face in the deck's frame.
func face_frame(piece: Chassis, face: StringName) -> Transform3D:
	return piece.pose() * FACES[face]


## The piece of the deck a place in the world is on or in, or null: whichever
## plate it's nearest inside, else the grid place under it.
func piece_at(point: Vector3) -> Chassis:
	var best: Chassis = null
	var nearest := INF
	for piece in pieces():
		var local := (global_transform * piece.pose()).affine_inverse() * point
		if absf(local.x) <= WIDTH * 0.5 + 0.02 and absf(local.z) <= WIDTH * 0.5 + 0.02 \
				and absf(local.y) < nearest and absf(local.y) <= THICK:
			nearest = absf(local.y)
			best = piece
	if best != null:
		return best
	var local := global_transform.affine_inverse() * point
	var at := Vector2i(roundi(local.x / WIDTH), roundi(local.z / WIDTH))
	for piece in grid():
		if piece.cell == at:
			return piece
	return null


## The piece a socket of this deck is its own, through what it's fitted in.
func sticking_frame(piece: Device, face: StringName) -> Transform3D:
	return face_frame(piece as Chassis, face)


func sticking_piece(socket: Socket) -> Device:
	return own_piece(socket)


func own_piece(socket: Socket) -> Chassis:
	var piece := _piece_of(socket)
	return piece if piece != null else self


func frame_sockets() -> Array[Socket]:
	var own: Array[Socket] = []
	if deck != null:
		for node in _own:
			if is_instance_valid(node) and node is Socket and not (node as Socket).stuck():
				own.append(node)
		return own
	for socket in super():
		if not socket.has_meta(&"piece"):
			own.append(socket)
	return own


## A lone piece fits a free ring of a deck that has room beyond it, or a free
## face of a frame on one.
func fits_in(socket: Socket) -> bool:
	var other := socket.get_parent() as Chassis
	if other == null:
		return false
	if socket.kind == &"face":
		return other._takes_on_face(self, socket)
	return other._turns_for(self, socket, Basis.IDENTITY) >= 0


## Where a piece joined at one of this deck's rings or frames' faces would
## sit, in that socket's frame: flush beyond a ring, turned the way nearest
## `held`, how it's held, or flat on a face.
func seat_in(ring: Socket, held: Basis) -> Transform3D:
	var other := ring.get_parent() as Chassis
	if ring.kind == &"face":
		return Frame.piece_seat()
	var k := maxi(other._turns_for(self, ring, held), 0)
	return ring.transform.affine_inverse() * other._pose_at(ring, k)


## Joins a lone piece at a free ring of this deck, turned `k` quarter turns
## (or the way it now faces), or on a frame's free face: everything of it
## moves into this body exactly where it sat beside it, and it leaves the
## physics world.
func join(piece: Chassis, ring: Socket, k := -1) -> void:
	var facing := ring.kind == &"face"
	if facing:
		assert(_takes_on_face(piece, ring))
		k = 0
	elif k < 0:
		k = _turns_for(piece, ring, piece.global_basis)
	assert(k >= 0 and ring.get_parent() == self)
	if not facing:
		_make_way(piece, ring, k)
	piece.cell = OFF_GRID if facing else _cell_of(ring) + _step(ring)
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
	deeds()


## Takes an outer piece off again, with all that's its own and whatever is
## stuck on it, loose where it sat; the caller moves it clear across the
## ring or off the face it leaves (ring_to, its joined_at). The first piece
## is this body, so for it another piece takes its place first and what
## comes off is that one's.
func detach(piece: Chassis) -> Chassis:
	assert(outer(piece))
	if piece == self:
		piece = _reroot(_first_on_grid())
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


## The first joined piece on the grid beside this one, to take its place.
func _first_on_grid() -> Chassis:
	for piece in joined:
		if not piece.on_frame():
			return piece
	return joined[0]


## The ring of the deck facing a place in the world from beside it, or null:
## where a piece just off it came across.
func ring_to(point: Vector3) -> Socket:
	var local := global_transform.affine_inverse() * point
	var at := Vector2i(roundi(local.x / WIDTH), roundi(local.z / WIDTH))
	for socket in sockets():
		if socket.kind == &"ring" and not socket.has_meta(&"socket") and not own_piece(socket).on_frame() \
				and _cell_of(socket) + _step(socket) == at:
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
		if node.has_meta(&"piece") and node.get_meta(&"piece") == to:
			node.remove_meta(&"piece")
		elif not node.has_meta(&"piece"):
			node.set_meta(&"piece", to)
			first.append(node)
	to._own = first
	for each in joined:
		if each != to and not each.on_frame():
			_place(each, back * each.pose())
	_place(to, back)
	var view := frame_view
	frame_view = to.frame_view
	to.frame_view = view
	# Lineage and arrival roles belong to the panel, not the body's current root.
	for key in [&"layer", &"arrival_uid", &"pod_skin"]:
		var mine: Variant = get_meta(key) if has_meta(key) else null
		var theirs: Variant = to.get_meta(key) if to.has_meta(key) else null
		for pair: Array in [[self, theirs], [to, mine]]:
			if pair[1] == null:
				pair[0].remove_meta(key)
			else:
				pair[0].set_meta(key, pair[1])
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
## this one, each at the ring of the one it joins, then those on frames after
## the piece their frame stands on: how a save rebuilds it.
func _reorder() -> void:
	var at := {}
	for piece in joined:
		if not piece.on_frame():
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
						and own_piece(socket) == from and _step(socket) == step:
					piece.joined_at = socket
	var hanging := joined.filter(func(p: Chassis) -> bool: return p.on_frame())
	while not hanging.is_empty():
		var placed := false
		for piece: Chassis in hanging.duplicate():
			var host := own_piece(piece.joined_at)
			if host == self or order.has(host):
				order.append(piece)
				hanging.erase(piece)
				placed = true
		if not placed:
			order.append_array(hanging)
			break
	joined = order


## The quarter turns a piece would join at a ring at, nearest `held`, or -1
## if it can't: only a lone, sound piece joins, at a free ring with room
## beyond it. A hook in the way pops off as it joins.
func _turns_for(piece: Chassis, ring: Socket, held: Basis) -> int:
	if piece == self or deck != null or piece.deck != null or not piece.joined.is_empty() \
			or not free_ring(ring) or ring.get_parent() != self or wrecked() or piece.wrecked():
		return -1
	var to := _cell_of(ring) + _step(ring)
	for each in grid():
		if each.cell == to:
			return -1
	var facing := global_basis.orthonormalized().inverse() * held.orthonormalized()
	var yaw := atan2(-facing.x.z, facing.x.x) if Vector2(facing.x.x, facing.x.z).length() > 0.3 \
		else atan2(facing.z.x, facing.z.z)
	var best := 0
	var nearest := INF
	for k in 4:
		var off := absf(angle_difference(yaw, k * QUARTER))
		if off < nearest - 1e-4:
			nearest = off
			best = k
	return best


## Whether a lone, sound piece could go on a frame's face of this deck: the
## face free, nothing standing too tall under a shelf.
func _takes_on_face(piece: Chassis, face: Socket) -> bool:
	return face.kind == &"face" and face.get_parent() == self and face.is_open() and piece != self \
		and deck == null and piece.deck == null and piece.joined.is_empty() and not wrecked() and not piece.wrecked()


## Whether a piece could join across a ring: a deck edge's own on its grid,
## with no piece beyond it and nothing seated there. A hook on it pops off
## (Hunter, 2026-10-17).
static func free_ring(ring: Socket) -> bool:
	if ring.kind != &"ring" or ring.has_meta(&"socket") or ring.closed or ring.mounted != null:
		return false
	var deck := ring.get_parent() as Chassis
	return deck == null or not deck.own_piece(ring).on_frame()


## Hooks where a piece joins pop off onto the sand just outside the deck, any
## line on them still tied: on the deck's edges facing its place, and on its
## own edges that will meet the deck. Loose parts lying where it goes move
## out the same way, so a row of pieces is never held up by what the last
## join dropped. A save rebuilds a deck off the tree, with nothing in its way,
## and a deck outside a world has no sand to drop anything on.
func _make_way(piece: Chassis, ring: Socket, k: int) -> void:
	if world == null or not is_inside_tree() or not piece.is_inside_tree():
		return
	var to := _cell_of(ring) + _step(ring)
	var cells := {to: true}
	for each in grid():
		cells[each.cell] = true
	for socket in sockets():
		if socket.kind == &"ring" and not socket.has_meta(&"socket") and socket.part != null \
				and not own_piece(socket).on_frame() and _cell_of(socket) + _step(socket) == to:
			_put_outside(pop(socket), socket.position, cells)
	var at := _pose_at(ring, k)
	for socket in piece.frame_sockets():
		var out := at.basis * socket.transform.basis.z
		if socket.kind == &"ring" and socket.part != null and cells.has(to + Vector2i(roundi(out.x), roundi(out.z))):
			_put_outside(piece.pop(socket), at * socket.position, cells)
	var back := global_transform.affine_inverse()
	for body in in_the_way(piece, global_transform * at):
		if _moves_aside(body):
			_put_outside(body, back * body.global_position, cells)


## What a piece, and all that stands on it, would meet joined at a pose in
## the world, the sand aside.
func in_the_way(piece: Chassis, pose: Transform3D) -> Array[CollisionObject3D]:
	var query := PhysicsShapeQueryParameters3D.new()
	var skip: Array[RID] = [get_rid()]
	if world != null and world.player != null:
		skip.append(world.player.get_rid())
	var shapes: Array[CollisionShape3D] = []
	var riding: Array[Device] = [piece]
	while not riding.is_empty():
		var each: Device = riding.pop_back()
		skip.append(each.get_rid())
		riding.append_array(each.mounted())
		for child in each.get_children():
			if child is CollisionShape3D and (child as CollisionShape3D).shape != null:
				shapes.append(child)
	query.exclude = skip
	var back := piece.global_transform.affine_inverse()
	var found: Array[CollisionObject3D] = []
	for shape in shapes:
		query.shape = Hands._skin(shape.shape)
		query.transform = pose * back * shape.global_transform
		for hit in get_world_3d().direct_space_state.intersect_shape(query, Hands.TOUCHES):
			if not Hands._sand(hit) and not found.has(hit.collider):
				found.append(hit.collider)
	return found


## Whether a piece has room to join at a pose: nothing there but the sand and
## loose parts, which it moves clear.
func room_for(piece: Chassis, pose: Transform3D) -> bool:
	return in_the_way(piece, pose).all(func(body: Object) -> bool: return _moves_aside(body))


## A loose part moves aside for a joining piece; a device, a deck, a wall or
## a find still in the sand stands in its way.
static func _moves_aside(body: Object) -> bool:
	return body is Part and not (body as Part).has_meta(&"buried")


## What a join moves out of its way lands just past the deck's edge, facing
## out: nearest where its line leads, or with none, where it was (`was`, in
## the deck's frame).
func _put_outside(part: Part, was: Vector3, cells: Dictionary) -> void:
	var back := global_transform.affine_inverse()
	var toward := was
	var tips: Array[RopeEnd] = []
	for child in part.get_children():
		if child is RopeEnd:
			tips.append(child)
			for rope in world.ropes.lines_on(child):
				toward = back * (rope.b if rope.a == child else rope.a).global_position
	var reach := WIDTH * 0.5 + CLEAR
	var best := Vector3.ZERO
	var out := Vector3.ZERO
	var nearest := INF
	for at: Vector2i in cells:
		var middle := Vector3(at.x, 0.0, at.y) * WIDTH
		for step: Vector2i in STEPS:
			if cells.has(at + step):
				continue
			var normal := Vector3(step.x, 0.0, step.y)
			var side := Vector3(-step.y, 0.0, step.x)
			var spot := middle + normal * reach + side * clampf((toward - middle).dot(side), -reach, reach)
			var d := Vector2(spot.x - toward.x, spot.z - toward.z).length()
			if d < nearest and not _inside(spot, cells, reach):
				nearest = d
				best = spot
				out = normal
	var land := global_transform * best
	land.y = world.height_under(land) - Finds.bounds(part).position.y + 0.01
	var facing := global_basis * out
	world.teleport(part, Transform3D(Basis.looking_at(-Vector3(facing.x, 0.0, facing.z), Vector3.UP), land))
	for tip in tips:
		world.ropes.let_out(tip)


## Whether a point in the deck's frame is within `reach` of a piece's middle, across and along.
static func _inside(point: Vector3, cells: Dictionary, reach: float) -> bool:
	for at: Vector2i in cells:
		if absf(point.x - at.x * WIDTH) < reach - 1e-3 and absf(point.z - at.y * WIDTH) < reach - 1e-3:
			return true
	return false


## Where a piece joined at a ring sits in the deck's frame, turned k quarter turns.
func _pose_at(ring: Socket, k: int) -> Transform3D:
	var at := _cell_of(ring) + _step(ring)
	return Transform3D(Basis(Vector3.UP, k * QUARTER), Vector3(at.x, 0.0, at.y) * WIDTH)


## The grid place of the piece a socket of this deck belongs to; the first
## piece's is the middle of the grid.
func _cell_of(socket: Socket) -> Vector2i:
	return own_piece(socket).cell


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


## A device stuck on a deck moves from one body to another with its socket.
static func _take_seat(from: Chassis, to: Chassis, seated: Device) -> void:
	var socket: Socket = null
	for each in from._seats:
		if each.mounted == seated:
			socket = each
	from._seats.erase(socket)
	to._seats.append(socket)
	seated.touch_none_of(from, false)
	seated.touch_none_of(to, true)
	if seated.parts_changed.is_connected(from._recompute):
		seated.parts_changed.disconnect(from._recompute)
		seated.parts_changed.connect(to._recompute)
	seated.transform = socket.transform * seated.seat_for(socket)


## Edge rings between two pieces on the grid close, and a frame's face with a
## piece on it, the rest open; then its weight, look and what it can do follow.
func _after_change() -> void:
	var cells := {}
	for piece in grid():
		cells[piece.cell] = true
	var filled := {}
	for piece in joined:
		if piece.on_frame():
			filled[piece.joined_at] = true
	for socket in sockets():
		if socket.kind == &"face":
			socket.closed = filled.has(socket)
		elif socket.kind != &"ring" or socket.has_meta(&"socket"):
			continue
		else:
			socket.closed = not own_piece(socket).on_frame() and cells.has(_cell_of(socket) + _step(socket))
		if socket.marker != null:
			socket.marker.visible = socket.is_open()
	remove_meta(&"hands_box")
	show_wear()
	_recompute()


## A deck, a piece with a device on it, or one loaded past what your hands
## carry, is too much to carry: you take hold of it instead.
func _recompute() -> void:
	super()
	carryable = joined.is_empty() and mounted().is_empty() and mass <= CARRIES_KG


func _physics_process(delta: float) -> void:
	super(delta)
	if world != null and world.counts_deeds and not freeze:
		_move_house()


## How far it has come as a camp since the day began where you are, from
## where it stood then; carried in your hands, it's no camp moving.
func _move_house() -> void:
	if not Deeds.waiting(world, &"moved_house") or world.player.hands.held == self:
		return
	var at := Vector2(world.world_x(global_position.x), world.world_z(global_position.z))
	var today := world.weather.day.day(world.time, world.moon.longitude, world.began)
	if today != _today:
		_today = today
		_day_from = at
	Deeds.measure(world, &"moved_house", at.distance_to(_day_from))


func mount(other: Device, socket: Socket) -> void:
	super(other, socket)
	deeds()


func fit(part: Part, socket: Socket) -> void:
	super(part, socket)
	if socket.stuck():
		deeds()


## The deck's deeds as it grows: enough pieces in one, a home's three on
## it, and the archaeology setup's, its ground radar fitted to a Console on it.
func deeds() -> void:
	if world == null or not world.counts_deeds:
		return
	Deeds.measure(world, &"deck_pieces", pieces().size())
	var on := []
	for socket in stuck():
		var thing: Node = socket.part if socket.part != null else socket.mounted
		on.append(thing.get_meta(&"catalog", &""))
		if thing is Console and (thing as Console).stats().get("ground_radar", 0) > 0:
			on.append(&"ground_radar")
	Deeds.measure(world, &"deck_home", Deeds.HOME.filter(func(id: StringName) -> bool: return on.has(id)).size())
	Deeds.measure(world, &"dig_setup", Deeds.SETUP.filter(func(id: StringName) -> bool: return on.has(id)).size())


func _unmade(socket: Socket) -> void:
	if socket.stuck() and socket.get_parent() == self:
		# Joined pieces retain their original socket order, including custom mounts.
		own_piece(socket)._own.erase(socket)
	super(socket)


func dismount(socket: Socket) -> Device:
	return super(socket)


func _frame_masses() -> Array:
	var frames := super()
	for piece in joined:
		frames.append([piece.frame_mass, piece.pose().origin])
	return frames


func stats() -> Dictionary:
	var now := super()
	now["pieces"] = pieces().size()
	return now


## Its whole-face plates in its own frame, each as [middle, way out, m², what
## it is, half its width and half its height along it, the frame's face it's
## on]: the pieces on its frames' faces and what fills the rest. Wind on
## faces reads them (Faces).
func plates() -> Array:
	var out := []
	for piece in joined:
		if piece.on_frame():
			var at := piece.pose()
			out.append([at.origin, at.basis.y.normalized(), WIDTH * WIDTH, &"chassis",
				at.basis.x.normalized() * WIDTH * 0.5, at.basis.z.normalized() * WIDTH * 0.5, piece.joined_at])
	for socket in sockets():
		if socket.kind == &"face" and socket.part != null:
			var id: StringName = socket.part.get_meta(&"catalog", &"")
			var size: Vector3 = Catalog.PARTS[id].size
			var b := socket.transform.basis.orthonormalized()
			out.append([socket.position + b.z * size.z * 0.5, b.z, size.x * size.y, id,
				b.x * size.x * 0.5, b.y * size.y * 0.5, socket])
	return out


## What the wind grabs of it as a loose body's catch counts it: its whole
## faces at the wind's way now, and the rest less what their lee keeps from
## it (Faces).
func wind_catch() -> float:
	return middle_catch() + faces.catch_now


## What the wind pushes at its middle now: all but its whole faces, less
## what their lee keeps from what stands behind them.
func middle_catch() -> float:
	return loose_catch() if is_nan(faces.loose_now) else faces.loose_now


## What the wind grabs of it but its whole faces, as if none stood.
func loose_catch() -> float:
	if is_nan(_loose):
		_loose = 0.0
		for item: Array in loose_items():
			_loose += item[1]
	return _loose


## What the wind grabs of it but its whole faces, each as [where in its
## frame, its catch]: flat, the wind meets its pieces and what's fitted to
## them side on, and takes what stands on it too.
func loose_items() -> Array:
	var items := []
	if world == null:
		return items
	var rate := world.tuning.wind_catch_per_m2
	for piece in pieces():
		items.append([piece.pose().origin, piece.frame_stats.get("face_m2", 0.0) * rate])
	# What's fitted, a part at a time, where its shapes are on average.
	var parts := {}
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.has_meta(&"socket") and (shape.get_meta(&"socket") as Socket).kind != &"face":
			var box := shape.transform * Catalog.bounds(shape.shape)
			var catch := maxf(box.size.x, box.size.z) * box.size.y * rate
			var item: Array = parts.get_or_add(shape.get_meta(&"socket"), [Vector3.ZERO, 0.0])
			item[0] = (item[0] * item[1] + box.get_center() * catch) / maxf(item[1] + catch, 1e-9)
			item[1] += catch
	items.append_array(parts.values())
	for seated in mounted():
		items.append([seated.position, seated.wind_catch()])
	return items


func _shapes_changed() -> void:
	super()
	_loose = NAN
	faces.forget()
	_forget_contact_frames()


func _forget_contact_frames() -> void:
	_contact_frames_known = false


## Chassis children are numerous; only their ordered frame shapes meet tipped sand.
func _frame_contacts() -> Array[FrameContact]:
	if not _contact_frames_known:
		for resource in _contact_resources:
			resource.changed.disconnect(_forget_contact_frames)
		_contact_resources.clear()
		_contact_frames.clear()
		for child in get_children():
			if child is CollisionShape3D:
				var frame := FrameContact.new()
				frame.shape = child
				_contact_frames.append(frame)
		_contact_frames_known = true
	return _contact_frames


func _read_contact_corners(frame: FrameContact) -> void:
	frame.source = frame.shape.shape
	var box := Catalog.bounds(frame.source)
	frame.corners.resize(8)
	for i in 8:
		frame.corners[i] = box.get_endpoint(i)
	if not frame.source.changed.is_connected(_forget_contact_frames):
		frame.source.changed.connect(_forget_contact_frames)
		_contact_resources.append(frame.source)


## Its joined frames' real corners, for resting tipped over on them.
func frame_contact_points(points: PackedVector3Array, clearances: PackedFloat32Array, clearance: float) -> void:
	for frame in _frame_contacts():
		var shape := frame.shape
		# Replacing a shape has no child-order notification; use it immediately.
		if frame.source != null and frame.source != shape.shape:
			_forget_contact_frames()
		if shape.shape == null or shape.disabled or shape.has_meta(&"socket"):
			continue
		if frame.source != shape.shape or frame.corners.is_empty():
			_read_contact_corners(frame)
		var to_world := global_transform * shape.transform
		for corner in frame.corners:
			points.append(to_world * corner)
			clearances.append(clearance)


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
