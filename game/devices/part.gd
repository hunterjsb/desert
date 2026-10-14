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


## How far it slides out of its socket before it's clear of the device, metres.
func depth() -> float:
	var deepest := 0.0
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null:
			var box := shape.transform * shape.shape.get_debug_mesh().get_aabb()
			deepest = maxf(deepest, box.end.z)
	return deepest + 0.02
