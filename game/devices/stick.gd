class_name Stick
extends RefCounted
## Sticking things on a chassis's sticky faces: one set of rules for your
## hands, the kits, the scenarios and the finds. A thing sits on a face by its
## base, a part's back or a device's foot, at a place on the face and turned
## about the face's way out; a frame sits square on a piece's top. The limits
## are space, which your hands test (clear), and a few rules of what goes
## where (why_not). Places edge to the face's edges and the things already on
## it, and turns settle into soft detents, never forced.

## A thing's edges come flush with a face's edge or a neighbour's within this, m.
const EDGE := 0.04
## A turn within this of a detent settles on it, rad; detents every this far.
const NEAR := deg_to_rad(3.5)
const DETENT := deg_to_rad(15.0)
## A face whose way out is this near straight up faces up.
const UPWARD := 0.7
## Things on the same face lie within this of its plane, m.
const PLANE := 0.01


## Whether a thing sticks on a chassis at all: a part that isn't for a slot
## only, or a device that sticks.
static func sticks(thing: Node) -> bool:
	var part := thing as Part
	if part != null:
		return not part.kind in Catalog.SLOT_ONLY
	var device := thing as Device
	return device != null and device.sticks


## How a thing sits on a face, in the face's frame, turned `yaw` about its way
## out at a place on it: a part on its back, a device on its foot.
static func seat(thing: Node, at: Vector2, yaw: float) -> Transform3D:
	var on := Transform3D(Basis(Vector3.BACK, yaw), Vector3(at.x, at.y, 0.0))
	return on * (thing as Device).seat() if thing is Device else on


## A thing's pose on a piece's face in the deck's frame, at a place and a turn.
static func pose_on(deck: Chassis, piece: Chassis, face: StringName, at: Vector2, yaw: float, thing: Node) -> Transform3D:
	return deck.face_frame(piece, face) * seat(thing, at, yaw)


## Sticks a thing on a piece's face at a place and turn: a frame square and
## centred. The socket it's in.
static func put(deck: Chassis, piece: Chassis, face: StringName, at: Vector2, yaw: float, thing: RigidBody3D) -> Socket:
	if thing is Frame:
		at = Vector2.ZERO
		yaw = roundf(yaw / Chassis.QUARTER) * Chassis.QUARTER
	var frame := deck.face_frame(piece, face)
	return deck.stick(thing, frame * seat(thing, at, yaw), frame.basis.z, piece)


## Why a thing can't stick on a piece's face, or "": a device that stands
## goes only on a face that faces up, and a frame only square on a top; a
## tall device and a frame never share a piece; a tray and runners never
## share a deck.
static func why_not(deck: Chassis, piece: Chassis, face: StringName, thing: Node) -> String:
	if not sticks(thing):
		return "it doesn't stick"
	var up := deck.face_frame(piece, face).basis.z.y >= UPWARD
	var device := thing as Device
	if thing is Frame:
		if face != Chassis.TOP or not up:
			return "frames go on a deck's top"
		if _on_top(deck, piece).any(func(d: Node) -> bool: return d is Device and (d as Device).tall):
			return "too tall for a frame"
		if _on_top(deck, piece).any(func(d: Node) -> bool: return d is Frame):
			return "a frame's there"
	elif device != null:
		if device.stands and not up:
			return "it stands on a deck's top"
		if device.tall and (piece.on_frame() or _on_top(deck, piece).any(func(d: Node) -> bool: return d is Frame)):
			return "too tall for a frame"
	elif thing is Part and deck.refuses(thing as Part) != "":
		return deck.refuses(thing as Part)
	return ""


## What's stuck on a piece's top.
static func _on_top(deck: Chassis, piece: Chassis) -> Array[Node]:
	var top := deck.face_frame(piece, Chassis.TOP)
	var found: Array[Node] = []
	for socket in deck.stuck():
		if deck.own_piece(socket) == piece and socket.out.dot(top.basis.z) > 0.99:
			found.append(socket.part if socket.part != null else socket.mounted)
	return found


## Why a thing at a pose in the world would clip something, or "": anything
## but the sand, you included. Its shapes are tested a little thinner, so
## resting against what it sits on doesn't count.
static func clear(thing: Node3D, pose: Transform3D, player: Node) -> String:
	var space := thing.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var back := thing.global_transform.affine_inverse()
	var skip: Array[RID] = [(thing as CollisionObject3D).get_rid()]
	query.exclude = skip
	for child in thing.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		query.shape = Hands._skin(shape.shape)
		query.transform = pose * back * shape.global_transform
		for hit in space.intersect_shape(query, Hands.TOUCHES):
			if Hands._sand(hit):
				continue
			return "you're in the way" if hit.collider == player else "blocked"
	return ""


## The sticky face a hit on a deck's shape lies on, as [piece, face], or []:
## only a piece's own plate is sticky. A hit on its edge counts as the face
## your look comes from.
static func face_hit(deck: Chassis, shape: Node, normal: Vector3, looking: Vector3) -> Array:
	if shape == null or not shape is CollisionShape3D or shape.has_meta(&"socket"):
		return []
	var piece: Chassis = shape.get_meta(&"piece") if shape.has_meta(&"piece") else deck
	var way := (deck.global_basis * piece.pose().basis).inverse() * normal
	if absf(way.y) < 0.5:
		way = -((deck.global_basis * piece.pose().basis).inverse() * looking)
	return [piece, Chassis.TOP if way.y >= 0.0 else Chassis.BOTTOM]


## Where a thing aimed at a point on a face would sit, as [place, turn]: under
## the point, turned as it's held about the face's way out, its edges edged
## flush with the face's and its neighbours' and its turn settled on a detent
## when near one. `held` is how it's turned in the world now.
static func aim(deck: Chassis, piece: Chassis, face: StringName, point: Vector3, held: Basis, thing: Node) -> Array:
	var frame := deck.global_transform * deck.face_frame(piece, face)
	var local := frame.affine_inverse() * point
	var yaw := 0.0
	if thing is Frame:
		yaw = roundf(_turn(frame.basis, held, thing) / Chassis.QUARTER) * Chassis.QUARTER
		return [Vector2.ZERO, yaw]
	yaw = _settle(_turn(frame.basis, held, thing))
	var half := WIDE_HALF
	var at := Vector2(clampf(local.x, -half, half), clampf(local.y, -half, half))
	var box := footprint(thing, yaw)
	at += _edge(deck, piece, face, at, box, thing)
	return [at, yaw]


const WIDE_HALF := Chassis.WIDTH * 0.5


## How a thing is turned about a face's way out, rad, from how it's held:
## its own x along the face, or its length where x points out of it.
static func _turn(face: Basis, held: Basis, thing: Node) -> float:
	var seat_basis := (thing as Device).seat().basis if thing is Device else Basis.IDENTITY
	# Its frame in the face's, undoing how it sits on its base.
	var on := face.orthonormalized().inverse() * held.orthonormalized() * seat_basis.inverse()
	var along := on.x
	if absf(along.z) > 0.9:
		along = on.y
	return atan2(along.y, along.x)


## A turn settled on its nearest detent when within NEAR of it.
static func _settle(yaw: float) -> float:
	var near := roundf(yaw / DETENT) * DETENT
	return near if absf(angle_difference(yaw, near)) < NEAR else yaw


## A thing's footprint on a face, turned `yaw`, about its place: [min, max] in
## the face's frame.
static func footprint(thing: Node, yaw: float) -> Rect2:
	var to_face := seat(thing, Vector2.ZERO, yaw)
	var box := Hands._shapes_box(thing.get_children())
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var p := to_face * box.get_endpoint(i)
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	return Rect2(lo, hi - lo)


## How far to move a footprint at a place so its edges come flush with the
## face's edges or a neighbour's, or its middle in line with one's, when one
## is within EDGE: the smallest such move along each way.
static func _edge(deck: Chassis, piece: Chassis, face: StringName, at: Vector2, box: Rect2, thing: Node) -> Vector2:
	var lines_x: Array[float] = [-WIDE_HALF, WIDE_HALF]
	var lines_y: Array[float] = [-WIDE_HALF, WIDE_HALF]
	var middles_x: Array[float] = []
	var middles_y: Array[float] = []
	var frame := deck.face_frame(piece, face)
	var back := frame.affine_inverse()
	for socket in deck.stuck():
		var other: Node = socket.part if socket.part != null else socket.mounted
		if other == thing or socket.out.dot(frame.basis.z) < 0.99:
			continue
		var theirs := _box_on(deck, socket, back)
		if absf(theirs[1]) > PLANE:
			continue
		var rect: Rect2 = theirs[0]
		lines_x.append_array([rect.position.x, rect.end.x])
		lines_y.append_array([rect.position.y, rect.end.y])
		middles_x.append(rect.get_center().x)
		middles_y.append(rect.get_center().y)
	var lo := at + box.position
	var hi := at + box.end
	var mid := at + box.get_center()
	return Vector2(_nearest([lo.x, hi.x], lines_x, mid.x, middles_x), _nearest([lo.y, hi.y], lines_y, mid.y, middles_y))


## The smallest move bringing one of `edges` onto a line, or `middle` onto a
## middle, within EDGE; 0 with none.
static func _nearest(edges: Array, lines: Array[float], middle: float, middles: Array[float]) -> float:
	var best := 0.0
	var nearest := EDGE
	for edge: float in edges:
		for line in lines:
			if absf(line - edge) < nearest:
				nearest = absf(line - edge)
				best = line - edge
	for line in middles:
		if absf(line - middle) < nearest:
			nearest = absf(line - middle)
			best = line - middle
	return best


## What's stuck in a socket as a footprint on a face (`back` is the face's
## frame undone), and how far its lowest point stands off the face.
static func _box_on(deck: Chassis, socket: Socket, back: Transform3D) -> Array:
	var nodes: Array = socket.fitted
	var to_face := back
	if socket.mounted != null:
		nodes = socket.mounted.get_children()
		to_face = back * socket.mounted.transform
	var box := Hands._shapes_box(nodes)
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for i in 8:
		var p := to_face * box.get_endpoint(i)
		lo = lo.min(p)
		hi = hi.max(p)
	return [Rect2(Vector2(lo.x, lo.y), Vector2(hi.x - lo.x, hi.y - lo.y)), lo.z]
