class_name Part
extends RigidBody3D
## A part. Loose, it's an ordinary body in the world. Fitted, it stops being one:
## its shapes and meshes move into the device's body and this node waits off
## the tree until it comes back out. Its geometry sits on its +Z side, outside
## whatever it's fitted to.

## The socket kind it fits.
@export var kind: StringName
@export var label := "part"
## What it gives a device: capacity_wh, hooks, lift_kg, solar_w, light_w,
## plants, catch (wind catch).
@export var stats: Dictionary = {}
## The socket it's fitted in, or null while loose.
var socket: Socket


## Loose, the wind grabs a part by its size, so a seedling doesn't blow away in
## a breeze that leaves a deck be.
func _ready() -> void:
	if not has_meta(&"wind_catch"):
		set_meta(&"wind_catch", Tuning.current().wind_catch_per_m2 * Weather.biggest_face(self))


## What sits in its own sockets (a line's end on a loose hook) waits off the
## tree, so nothing else would free it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for child in get_children():
			var own := child as Socket
			if own != null and own.part != null and not own.has_meta(&"socket"):
				own.part.free()


## Use while you hold it, aiming at `at`. Says whether it did anything.
func use(_by: Player, _at: Vector3) -> bool:
	return false


## How far it slides out of its socket before it's clear of the device, metres.
func depth() -> float:
	var deepest := 0.0
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null:
			var box := shape.transform * Catalog.bounds(shape.shape)
			deepest = maxf(deepest, box.end.z)
	return deepest + 0.02
