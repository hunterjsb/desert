extends RefCounted
## One candidate art direction: what it draws for each frame, part, socket and
## the ruin, in place of the grey boxes. This one draws nothing, so the grey
## boxes stand: the baseline every candidate is judged against.

const Shapes := preload("res://look/style/shapes.gd")

## Downwind, world: what weathering faces away from.
var wind := Vector3(0.0, 0.0, 1.0)


func title() -> String:
	return "grey boxes (today)"


## A frame's look in its own frame, or null to keep its grey box.
func frame(_id: StringName, _size: Vector3) -> Node3D:
	return null


## A fitted part's look in its socket's frame, standing out along +Z, or null
## to keep its grey box.
func part(_id: StringName, _size: Vector3) -> Node3D:
	return null


## What marks a socket on a dressed frame, in the socket's frame, or null.
func mount(_kind: StringName) -> Node3D:
	return null


## The stake's look in its own frame, the ring at Stake.RING, or null.
func stake() -> Node3D:
	return null


## Dresses the ruin's own mesh, or stands something in its place. `frame` is
## the ruin's frame in the engine: the floor's top at its middle, turned.
func ruin(_view: MeshInstance3D, _frame: Transform3D) -> void:
	pass


## Two finds to lie half-buried near the camp, crude surface-era scrap and an
## overbuilt colonial piece, each with its foot at its origin; or none.
func finds() -> Array[Node3D]:
	return []


func rope_color() -> Color:
	return Color(0.42, 0.31, 0.2)
