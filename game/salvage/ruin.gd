class_name Ruin
extends Site
## The house ruin, the first kind with a kit (the second age's, SiteKinds): a
## thick-walled building of three rooms, a hall open to
## the sky and two roofed rooms behind it, with a door front and back. Boxes
## and slabs built for walking, never scaled, never moved. Its footprint is
## part of the ground's one function: inside, the sand lies just under its
## floor; outside, it drifts up the walls, falls away at the doors and blends
## back into the dunes.
##
## Plan coordinates are metres: u along its length, v across, the floor's top
## at 0. Outer walls stand on whole metres and are a metre thick, so the
## lattice's rows meet their faces and the sand's rise from floor to drift
## happens inside a wall, where nobody sees it.

## Half its length and width to the outer faces, m.
const HALF := Vector2i(9, 6)
const WALL := 1.0
const PARTITION := 0.4
const HEIGHT := 3.0
const DOOR_WIDTH := 1.4
const DOOR_HEIGHT := 2.3
## Walls reach this far under the floor, so no drift ever shows their foot.
const FOOT := 0.6
const SLAB := 0.3
const ROOF := 0.3
## Inside, the sand lies this far under the floor's top, so the floor shows.
const SAND_UNDER := 0.03
## Sand drifts this high against the walls and is gone this far out; this
## far out the dunes have their own shape back.
const DRIFT := 0.7
const DRIFT_REACH := 4.0
const APRON := 12.0
## The drift rises beside a door over this far, m.
const DOOR_SIDE := 2.7
## How far its ground reaches from its middle either way, m.
const REACH := 21
## Doors in the outer walls: the middle of the doorway on the outer face, and outward.
const DOORS := [[Vector2(-3.0, 6.0), Vector2(0.0, 1.0)], [Vector2(5.0, -6.0), Vector2(0.0, -1.0)]]
## Rooms, as plan rects: the hall, then the two roofed rooms.
const ROOMS := [Rect2(-8.0, -5.0, 9.8, 10.0), Rect2(2.2, -5.0, 5.8, 4.8), Rect2(2.2, 0.2, 5.8, 4.8)]
## A walk in the front door, through every room and doorway, out the back,
## and back in and out the front: plan points on the floor.
const TOUR := [Vector2(-3.0, 10.0), Vector2(-3.0, 4.0), Vector2(-4.5, -2.5), Vector2(0.5, 2.5),
	Vector2(4.5, 2.5), Vector2(5.0, 1.2), Vector2(5.0, -1.5), Vector2(5.0, -4.3), Vector2(5.0, -10.0),
	Vector2(5.0, -4.0), Vector2(3.5, -2.5), Vector2(0.0, -2.5), Vector2(-3.0, 3.0), Vector2(-3.0, 10.0)]
## Where finds lie on its floor, out of the way between doors: the first is
## the hall's, where a whole device stands.
const SPOTS := [Vector2(-6.6, 0.0), Vector2(-7.3, -4.3), Vector2(-7.3, 4.3), Vector2(-0.8, -4.3),
	Vector2(7.3, 4.3), Vector2(7.3, 0.9), Vector2(7.3, -4.3), Vector2(2.8, -4.4)]
## Where a scenario stands you to look at it: out in front of the front door.
const APPROACH := Vector2(-3.0, 18.0)

static var _boxes: Array[AABB] = []
static var _shapes: Array[BoxShape3D] = []
static var _mesh: ArrayMesh

## Its middle, world metres on the lattice; its quarter turns from the plan
## are Site's turn; the floor's top, world height.
var center: Vector2i
var floor_y: float
var _pad: float
## Half its ground's extent along world x and z.
var _reach: Vector2


func _init(at: Vector2i, quarter_turns: int, floor_top: float) -> void:
	center = at
	turn = quarter_turns
	floor_y = floor_top
	_pad = floor_top - SAND_UNDER
	_reach = Vector2(half_on(turn)) + Vector2.ONE * APRON
	# As the index holds it: the ground's own grid places it, for now.
	kind = &"house_ruin"
	era = SiteKinds.era(kind)
	x = at.x
	z = at.y
	bearing = fposmod(-turn * PI * 0.5, TAU)
	reach = REACH
	id = (at.x & 0xffffffff) << 32 | (at.y & 0xffffffff)
	source = &"grid"
	planned = false


## Its ground is a rectangle, its apron round its walls.
func touches(rect: Rect2) -> bool:
	return rect.intersects(Rect2(Vector2(center) - _reach, _reach * 2.0), true)


## Half its outer extent along world x and z, turned.
static func half_on(quarter_turns: int) -> Vector2i:
	return HALF if quarter_turns % 2 == 0 else Vector2i(HALF.y, HALF.x)


## The sand at a lattice point, given what the dunes alone would be there.
func sand(x: float, z: float, dunes: float) -> float:
	var dx := x - center.x
	var dz := z - center.y
	if absf(dx) > _reach.x or absf(dz) > _reach.y:
		return dunes
	var p := plan(dx, dz)
	var au := absf(p.x)
	var av := absf(p.y)
	if au <= HALF.x - WALL and av <= HALF.y - WALL:
		return _pad
	var d := Vector2(maxf(au - HALF.x, 0.0), maxf(av - HALF.y, 0.0)).length()
	var drift := DRIFT * (1.0 - smoothstep(0.0, DRIFT_REACH, d)) * _clear_of_doors(p)
	return lerpf(_pad + drift, dunes, smoothstep(DRIFT_REACH, APRON, d))


## Whether a world place is on its ground, within `margin` m beyond it.
func reaches(x: float, z: float, margin := 0.0) -> bool:
	return absf(x - center.x) <= _reach.x + margin and absf(z - center.y) <= _reach.y + margin


## The sand stays low in front of each outer door, so you walk in level.
static func _clear_of_doors(p: Vector2) -> float:
	var clear := 1.0
	for door: Array in DOORS:
		var at: Vector2 = door[0]
		var out: Vector2 = door[1]
		if (p - at).dot(out) >= -WALL:
			var along := absf((p - at).dot(Vector2(out.y, -out.x)))
			clear = minf(clear, smoothstep(DOOR_WIDTH * 0.5 + 0.3, DOOR_WIDTH * 0.5 + 0.3 + DOOR_SIDE, along))
	return clear


## A world offset from its middle, in plan coordinates.
func plan(dx: float, dz: float) -> Vector2:
	match turn:
		0:
			return Vector2(dx, dz)
		1:
			return Vector2(-dz, dx)
		2:
			return Vector2(-dx, -dz)
	return Vector2(dz, -dx)


## A plan point as a world place, metres.
func to_world(p: Vector2) -> Vector2:
	match turn:
		0:
			return Vector2(center) + p
		1:
			return Vector2(center) + Vector2(p.y, -p.x)
		2:
			return Vector2(center) - p
	return Vector2(center) + Vector2(-p.y, p.x)


## Its frame in world metres: the floor's top at its middle, turned.
func frame() -> Transform3D:
	return Transform3D(_turned(turn), Vector3(center.x, floor_y, center.y))


## The boxes it's built of, as plan AABBs: floor, walls with their doorways
## and lintels, roof.
static func boxes() -> Array[AABB]:
	if _boxes.is_empty():
		var f := Vector2(HALF)
		var inner := f - Vector2.ONE * WALL
		_boxes.append(AABB(Vector3(-f.x, -SLAB, -f.y), Vector3(f.x * 2.0, SLAB, f.y * 2.0)))
		_boxes.append_array(_wall(true, inner.y, f.y, -f.x, f.x, [DOORS[0][0].x]))
		_boxes.append_array(_wall(true, -f.y, -inner.y, -f.x, f.x, [DOORS[1][0].x]))
		_boxes.append_array(_wall(false, -f.x, -inner.x, -inner.y, inner.y, []))
		_boxes.append_array(_wall(false, inner.x, f.x, -inner.y, inner.y, []))
		_boxes.append_array(_wall(false, 1.8, 2.2, -inner.y, inner.y, [-2.5, 2.5]))
		_boxes.append_array(_wall(true, -0.2, 0.2, 2.2, inner.x, [5.0]))
		_boxes.append(AABB(Vector3(1.8, HEIGHT, -f.y), Vector3(f.x - 1.8, ROOF, f.y * 2.0)))
	return _boxes


## A wall from `a0` to `a1` along u (or v), `b0` to `b1` thick, with a door
## and a lintel over it at each of `doors` along it.
static func _wall(along_u: bool, b0: float, b1: float, a0: float, a1: float, doors: Array) -> Array[AABB]:
	var out: Array[AABB] = []
	var at := a0
	for door: float in doors:
		out.append(_span(along_u, at, door - DOOR_WIDTH * 0.5, b0, b1, -FOOT, HEIGHT))
		out.append(_span(along_u, door - DOOR_WIDTH * 0.5, door + DOOR_WIDTH * 0.5, b0, b1, DOOR_HEIGHT, HEIGHT))
		at = door + DOOR_WIDTH * 0.5
	out.append(_span(along_u, at, a1, b0, b1, -FOOT, HEIGHT))
	return out


static func _span(along_u: bool, a0: float, a1: float, b0: float, b1: float, y0: float, y1: float) -> AABB:
	if along_u:
		return AABB(Vector3(a0, y0, b0), Vector3(a1 - a0, y1 - y0, b1 - b0))
	return AABB(Vector3(b0, y0, a0), Vector3(b1 - b0, y1 - y0, a1 - a0))


## Builds what every ruin shares, its look and its shapes, so the first chunk
## with a ruin doesn't pay for it inside the streaming budget.
static func prepare() -> void:
	_shared_mesh()
	_shared_shapes()


## Its look, placed at `at` in its chunk's frame: one mesh every ruin shares.
func view(at: Vector3) -> MeshInstance3D:
	var made := MeshInstance3D.new()
	made.mesh = _shared_mesh()
	made.transform = Transform3D(_turned(turn), at)
	return made


## Its collision joins a chunk's: a box for each of its boxes, `at` in the
## body's frame. The sand and the ruin are one ground.
func add_shapes(body: StaticBody3D, at: Vector3) -> void:
	var all := boxes()
	var shapes := _shared_shapes()
	var placed := Transform3D(_turned(turn), at)
	for i in all.size():
		var holder := CollisionShape3D.new()
		holder.shape = shapes[i]
		holder.transform = placed.translated_local(all[i].get_center())
		body.add_child(holder)


static func _shared_shapes() -> Array[BoxShape3D]:
	if _shapes.is_empty():
		for box in boxes():
			var shape := BoxShape3D.new()
			shape.size = box.size
			_shapes.append(shape)
	return _shapes


## A quarter-turn basis, exact.
static func _turned(quarter_turns: int) -> Basis:
	var b := Basis(Vector3.UP, quarter_turns * PI * 0.5)
	return Basis(b.x.round(), b.y.round(), b.z.round())


static func _shared_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var all := boxes()
	for i in all.size():
		# The floor a shade darker than the walls, so rooms read.
		tool.set_color(Color(0.36, 0.33, 0.29) if i == 0 else Color(0.52, 0.47, 0.4))
		_add_box(tool, all[i])
	tool.index()
	_mesh = tool.commit()
	# Poured concrete; the floor's darker colour tells the shader it's floor.
	_mesh.surface_set_material(0, Paint.ruin())
	return _mesh


static func _add_box(tool: SurfaceTool, box: AABB) -> void:
	for axis in 3:
		for side in [-1.0, 1.0]:
			var normal := Vector3.ZERO
			normal[axis] = side
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = 1.0
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = 1.0
			var middle := box.get_center() + normal * box.size[axis] * 0.5
			var du := u * box.size[(axis + 1) % 3] * 0.5
			var dv := v * box.size[(axis + 2) % 3] * 0.5
			var corners := [middle - du - dv, middle + du - dv, middle + du + dv, middle - du + dv]
			# Wound so the face looks out along its normal.
			var order := [0, 1, 2, 0, 2, 3] if side < 0.0 else [0, 2, 1, 0, 3, 2]
			tool.set_normal(normal)
			for k in order:
				tool.add_vertex(corners[k])
