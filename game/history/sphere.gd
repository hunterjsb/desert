class_name Sphere
extends RefCounted
## The moon as a sphere. A place is a unit vector in the moon's own frame, the
## one DayCycle works the sky in: x toward 0° longitude, y toward 90° east, z
## north. Distances along the ground are angles times the radius.


static func point(latitude: float, longitude: float) -> Vector3:
	return Vector3(cos(latitude) * cos(longitude), cos(latitude) * sin(longitude), sin(latitude))


static func latitude(p: Vector3) -> float:
	return asin(clampf(p.z, -1.0, 1.0))


static func longitude(p: Vector3) -> float:
	return atan2(p.y, p.x)


## The angle between two places, seen from the moon's centre, rad.
static func angle(a: Vector3, b: Vector3) -> float:
	return atan2(a.cross(b).length(), a.dot(b))


## East where a place is. At a pole every way is south, so east is taken as
## the 90° meridian's.
static func east(p: Vector3) -> Vector3:
	var e := Vector3(-p.y, p.x, 0.0)
	if e.length_squared() < 1e-12:
		return Vector3(0.0, 1.0, 0.0)
	return e.normalized()


static func north(p: Vector3) -> Vector3:
	return p.cross(east(p))


## The way from a toward b, rad clockwise from north.
static func bearing(a: Vector3, b: Vector3) -> float:
	var ahead := b - a * a.dot(b)
	return atan2(ahead.dot(east(a)), ahead.dot(north(a)))


## The place `by` rad from p, setting off along `bearing`.
static func toward(p: Vector3, bearing: float, by: float) -> Vector3:
	var way := north(p) * cos(bearing) + east(p) * sin(bearing)
	return (p * cos(by) + way * sin(by)).normalized()


## Where q lies seen from p, as (east, north) in radii: its distance and
## bearing from p kept exactly, the map the sheet lays history with.
static func flat_from(p: Vector3, q: Vector3) -> Vector2:
	var by := angle(p, q)
	if by < 1e-12:
		return Vector2.ZERO
	var b := bearing(p, q)
	return Vector2(sin(b), cos(b)) * by


## The place at (east, north) radii from p: flat_from's inverse.
static func from_flat(p: Vector3, offset: Vector2) -> Vector3:
	var by := offset.length()
	if by < 1e-12:
		return p
	return toward(p, atan2(offset.x, offset.y), by)


## How far q lies to the right of the great circle from a toward b, rad.
static func off_line(a: Vector3, b: Vector3, q: Vector3) -> float:
	var pole := a.cross(b)
	if pole.length_squared() < 1e-12:
		return angle(a, q)
	return -asin(clampf(q.dot(pole.normalized()), -1.0, 1.0))
