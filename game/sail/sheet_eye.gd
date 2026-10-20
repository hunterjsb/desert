class_name SheetEye
extends RefCounted
## A bolted deck eye: its whole foot belongs on a visible panel, clear of
## gear. Only its visual seat is chosen here; the sail keeps its force model.

const FOOT := Vector2(0.18, 0.14)
const EYE_UP := 0.077
const HEIGHT := 0.142
const CLEAR := 0.01
static var _mesh: ArrayMesh


static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var b := Paint.Pieces.new()
	var steel := Paint.coat(Paint.STEEL, 0.8, 0.6)
	var bolts := Paint.coat(Paint.STEEL, 0.75, 0.35)
	b.box(Vector3(FOOT.x, 0.012, FOOT.y), Vector3(0.0, 0.006, 0.0), steel, 0.005)
	# Cast feet join the eye's lower arc to the plate, above the deck skin.
	for x in [-0.025, 0.025]:
		b.box(Vector3(0.03, 0.035, 0.04), Vector3(x, 0.022, 0.0), steel, 0.004)
	b.ring(0.035, 0.065, Vector3.UP * EYE_UP, steel, Basis(Vector3.RIGHT, PI / 2.0), 16)
	for x in [-0.065, 0.065]:
		for z in [-0.045, 0.045]:
			b.drum(0.009, 0.006, Vector3(x, 0.015, z), bolts, Basis.IDENTITY, 6)
	_mesh = b.commit()
	return _mesh


## A seat in the carrier's coordinates, with its origin at the eye opening.
## Panel ribs and equipment stay clear of the complete mounting volume.
static func seat(on: Chassis, want: Vector3) -> Array[Transform3D]:
	var obstacles: Array[AABB] = []
	var back := on.global_transform.affine_inverse()
	var riding: Array[Device] = [on]
	while not riding.is_empty():
		var each: Device = riding.pop_back()
		riding.append_array(each.mounted())
		for child in each.get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.shape == null:
				continue
			# The deck skin is our support; its fitted parts remain obstacles.
			if each is Chassis and not shape.has_meta(&"socket"):
				continue
			obstacles.append(back * shape.global_transform * Catalog.bounds(shape.shape))
	var nearest := INF
	var found: Array[Transform3D] = []
	var margin := Vector2.ONE * (Chassis.WIDTH * 0.5 - Chassis.PANEL_INSET - CLEAR) - FOOT * 0.5
	for piece in on.pieces():
		var pose := piece.pose()
		var local := (on.global_transform * pose).affine_inverse() * want
		var aimed := Vector2(clampf(local.x, -margin.x, margin.x), clampf(local.z, -margin.y, margin.y))
		var choices: Array[Vector2] = [aimed]
		for x in [-margin.x, -margin.x * 0.5, 0.0, margin.x * 0.5, margin.x]:
			for z in [-margin.y, 0.0, margin.y]:
				choices.append(Vector2(x, z))
		for at in choices:
			# The narrow raised panel ribs cross at these two positions.
			if absf(absf(at.y) - 0.2) < FOOT.y * 0.5 + 0.007 + CLEAR:
				continue
			var base := Vector3(at.x, Chassis.THICK * 0.5 - Chassis.PANEL_DROP, at.y)
			var box := pose * AABB(base - Vector3(FOOT.x * 0.5, 0.0, FOOT.y * 0.5), Vector3(FOOT.x, HEIGHT, FOOT.y))
			if obstacles.any(func(obstacle: AABB) -> bool: return box.grow(CLEAR).intersects(obstacle)):
				continue
			var apart := (on.global_transform * pose * base).distance_squared_to(want)
			if apart < nearest:
				nearest = apart
				found = [pose * Transform3D(Basis.IDENTITY, base + Vector3.UP * EYE_UP)]
	return found
