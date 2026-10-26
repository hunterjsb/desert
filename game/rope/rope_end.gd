class_name RopeEnd
extends Node3D
## A fixed place a rope ties on: a ring or hook you can see, on a body, a stake
## or you. Ropes attach only here, and pull at exactly this point.

static var _ring_mesh: ArrayMesh

## What the rope pulls: the body or the player this point is fixed to.
var holder: Node3D


static func make(on: Node3D, at: Vector3, ring := true) -> RopeEnd:
	var end := RopeEnd.new()
	end.position = at
	if ring:
		var shown := ring_mesh()
		# Stood on edge, so it reads as a ring from the side.
		shown.rotation = Vector3(PI / 2.0, 0.0, 0.0)
		end.add_child(shown)
	on.add_child(end)
	return end


func _enter_tree() -> void:
	holder = get_parent() as Node3D
	# A device seated on another rides held fast on it, so its host takes the pull.
	while holder != null and (not (holder is RigidBody3D or holder is CharacterBody3D)
			or holder is Device and (holder as Device).host() != null):
		holder = holder.get_parent() as Node3D


## The ring you see, lying flat until it's turned: in the worn paint, so it
## chips and dusts with what it's on, new until that ages it.
static func ring_mesh() -> MeshInstance3D:
	if _ring_mesh == null:
		var b := Paint.Pieces.new()
		b.ring(0.035, 0.065, Vector3.ZERO, Paint.coat(Paint.STEEL, 0.5, 0.75, 0.45), Basis.IDENTITY, 6)
		_ring_mesh = b.commit()
	var ring := MeshInstance3D.new()
	ring.mesh = _ring_mesh
	ring.set_instance_shader_parameter(&"age", Paint.age_of(&"", 1.0))
	return ring
