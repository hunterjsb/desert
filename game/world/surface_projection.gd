class_name SurfaceProjection
extends RefCounted
## Large-moon presentation above the local physical sheet; navigation has its own scale.

static func radius(tuning: Tuning) -> float:
	return maxf(tuning.moon_visual_radius_m, 1.0)

static func project(point: Vector3, anchor: Vector2, radius_m: float) -> Vector3:
	if radius_m <= 0.0:
		return point
	var off := Vector2(point.x, point.z) - anchor
	return Vector3(point.x, point.y - off.length_squared() / (2.0 * radius_m), point.z)

static func unproject(point: Vector3, anchor: Vector2, radius_m: float) -> Vector3:
	if radius_m <= 0.0:
		return point
	var off := Vector2(point.x, point.z) - anchor
	return Vector3(point.x, point.y + off.length_squared() / (2.0 * radius_m), point.z)

static func normal(n: Vector3, point: Vector2, anchor: Vector2, radius_m: float) -> Vector3:
	if radius_m <= 0.0:
		return n
	var slope := (point - anchor) / radius_m
	return Vector3(n.x + slope.x * n.y, n.y, n.z + slope.y * n.y).normalized()

static func horizon_distance(height_m: float, radius_m: float) -> float:
	var height := maxf(height_m, 0.0)
	return sqrt(height * (2.0 * radius_m + height))

static func horizon_dip(height_m: float, radius_m: float) -> float:
	return atan2(horizon_distance(height_m, radius_m), maxf(radius_m, 1.0))
