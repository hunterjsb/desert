class_name Compass
extends Part
## A compass: its needle points to the moon's north as you've walked it, so
## past a pole it turns round with the moon (MoonPosition). Read it in your
## hand, held up or flat, or in the inventory. Its needle glows,
## so it reads at night and in a storm, when the sun can't tell you.

## Where the needle turns, above its card.
const PIVOT := Vector3(0.0, 0.0, 0.034)

var needle: MeshInstance3D
var _world: World


func _enter_tree() -> void:
	_world = World.of(self)


func _process(_delta: float) -> void:
	if _world != null and needle != null:
		needle.transform = pose(turn(global_basis, _world.moon.north()))


## The needle on its pivot, turned `angle` rad clockwise from the card's top.
static func pose(angle: float) -> Transform3D:
	return Transform3D(Basis(Vector3.BACK, -angle), PIVOT)


## How far clockwise from the card's top the needle lies, rad, on a card
## facing out along `face`'s +Z, with north along `north`: as it would lie
## with the compass tipped level, so one held up to read shows north ahead
## as straight up, as one held flat does with its top ahead.
static func turn(face: Basis, north: Vector3) -> float:
	var out := face.z.normalized()
	var level := Basis.IDENTITY
	var axis := out.cross(Vector3.UP)
	if axis.length() > 1e-4:
		level = Basis(axis.normalized(), out.angle_to(Vector3.UP))
	elif out.y < 0.0:
		level = Basis(face.x.normalized(), PI)
	return atan2(north.dot(level * face.x), north.dot(level * face.y))
