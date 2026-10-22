class_name TerrainResidency
extends RefCounted
## Ground construction and body lifetime must agree about the area being kept.
## Collision retires one chunk late so crossing a boundary cannot expose a hole.


static func distance(coord: Vector2i, center: Vector2i) -> int:
	return maxi(absi(coord.x - center.x), absi(coord.y - center.y))


static func keeps_ground(coord: Vector2i, center: Vector2i, tuning: Tuning) -> bool:
	return distance(coord, center) <= tuning.view_radius + 1


static func needs_collision(coord: Vector2i, center: Vector2i, tuning: Tuning) -> bool:
	return distance(coord, center) <= tuning.near_radius


static func keeps_collision(coord: Vector2i, center: Vector2i, tuning: Tuning) -> bool:
	return distance(coord, center) <= tuning.near_radius + 1


## One frame's policy copies its radii and camp cells, rather than live tuning.
class Policy:
	var center: Vector2i
	var view_radius: int
	var near_radius: int
	var camp_collision := Rect2i()
	var camp_keep := Rect2i()

	func keeps_ground(coord: Vector2i) -> bool:
		return TerrainResidency.distance(coord, center) <= view_radius + 1 or camp_keep.has_point(coord)

	func needs_collision(coord: Vector2i) -> bool:
		return TerrainResidency.distance(coord, center) <= near_radius or camp_collision.has_point(coord)

	func keeps_collision(coord: Vector2i) -> bool:
		return TerrainResidency.distance(coord, center) <= near_radius + 1 or camp_keep.has_point(coord)

	func same_as(other: Policy) -> bool:
		return other != null and center == other.center and view_radius == other.view_radius \
			and near_radius == other.near_radius and camp_collision == other.camp_collision \
			and camp_keep == other.camp_keep

	func history_rect(side: int) -> Rect2:
		return Rect2(Vector2(camp_keep.position) * side, Vector2(camp_keep.size) * side)


static func cells(rect: Rect2, side: int) -> Rect2i:
	if not rect.has_area():
		return Rect2i()
	var first := Vector2i(floori(rect.position.x / side), floori(rect.position.y / side))
	var last := Vector2i(floori(rect.end.x / side), floori(rect.end.y / side))
	return Rect2i(first, last - first + Vector2i.ONE)


static func plan(center: Vector2i, tuning: Tuning, camp := Rect2()) -> Policy:
	var policy := Policy.new()
	policy.center = center
	policy.view_radius = tuning.view_radius
	policy.near_radius = tuning.near_radius
	var occupied := cells(camp, tuning.chunk_size)
	if occupied.has_area():
		# Moving bodies get collision ahead of their footprint; old support retires later.
		policy.camp_collision = occupied.grow(1)
		policy.camp_keep = policy.camp_collision.grow(1)
	return policy
