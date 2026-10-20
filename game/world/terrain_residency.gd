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
