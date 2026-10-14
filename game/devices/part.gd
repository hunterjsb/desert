class_name Part
extends RigidBody3D
## A part. Loose, it's an ordinary body in the world. Fitted, it stops being one:
## its shapes and meshes move into the device's body and this node waits off
## the tree until it comes back out. Its geometry sits on its +Z side, outside
## whatever it's fitted to.

## The loose-object catch is for a half-metre box, a quarter square metre.
const CATCH_AREA := 0.25

## The socket kind it fits.
@export var kind: StringName
@export var label := "part"
## What it gives a device: capacity_wh, hooks, lift_kg, solar_w, light_w,
## plants, catch (wind catch).
@export var stats: Dictionary = {}
## The socket it's fitted in, or null while loose.
var socket: Socket


## Loose, the wind grabs a part by its size, so a seedling doesn't blow away in
## a breeze that leaves a crate be.
func _ready() -> void:
	if not has_meta(&"wind_catch"):
		set_meta(&"wind_catch", Tuning.current().loose_wind_catch * _face_area() / CATCH_AREA)


## Its biggest face, m²: what it shows the wind at worst.
func _face_area() -> float:
	var biggest := 0.0
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape is BoxShape3D:
			var size: Vector3 = shape.shape.size
			biggest = maxf(biggest, maxf(size.x * size.y, maxf(size.y * size.z, size.x * size.z)))
	return biggest


## How far it slides out of its socket before it's clear of the device, metres.
func depth() -> float:
	var deepest := 0.0
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null:
			var box := shape.transform * shape.shape.get_debug_mesh().get_aabb()
			deepest = maxf(deepest, box.end.z)
	return deepest + 0.02
