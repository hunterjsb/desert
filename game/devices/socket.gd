class_name Socket
extends Node3D
## A defined spot on a device where one kind of part fits. Its +Z axis points
## out of the device: a part sits outside the frame along it and slides back
## out along it, so it never passes through the device.

@export var kind: StringName
## The part fitted here, or null.
var part: Part
## The part's shapes and meshes while they live in the device's body.
var fitted: Array[Node3D] = []
## A small device seated here instead, like a shield on a top mount, or null.
var mounted: Device
## A flat tell on the frame showing where this kind of part goes, hidden when full.
var marker: MeshInstance3D


## Nothing in it, part or device.
func is_open() -> bool:
	return part == null and mounted == null
