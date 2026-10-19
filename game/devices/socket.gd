class_name Socket
extends Node3D
## A defined spot on a device where one kind of part fits. Its +Z axis points
## out of the device: a part sits outside the frame along it and slides back
## out along it, so it never passes through the device. A thing stuck on a
## chassis's sticky face has a socket made for it there, of kind STUCK, whose
## transform is the thing's own pose and whose `out` is the face's way out.

const STUCK := &"stuck"

@export var kind: StringName
## The part fitted here, or null.
var part: Part
## The part's shapes and meshes while they live in the device's body.
var fitted: Array[Node3D] = []
## A device seated here instead, like a shield stuck on a deck, or null.
var mounted: Device
## A flat tell on the frame showing where this kind of part goes, hidden when full.
var marker: MeshInstance3D
## A chassis piece's edge ring with another piece joined across it, or a
## frame's face with a piece on it: nothing fits there.
var closed := false
## Stuck: the sticky face's way out, in its body's frame.
var out := Vector3.ZERO


## Nothing in it, part or device.
func is_open() -> bool:
	return part == null and mounted == null and not closed


func stuck() -> bool:
	return kind == STUCK


## Its way out of its body, in the body's frame.
func outward() -> Vector3:
	return out if kind == STUCK else transform.basis.z.normalized()
