class_name RopeEnd
extends Node3D
## A fixed place a rope ties on: a ring or hook you can see, on a body, a stake
## or you. Ropes attach only here, and pull at exactly this point.

static var _ring_mesh: TorusMesh
static var _ring_look: StandardMaterial3D

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


## The ring you see, lying flat until it's turned.
static func ring_mesh() -> MeshInstance3D:
	if _ring_mesh == null:
		_ring_mesh = TorusMesh.new()
		_ring_mesh.inner_radius = 0.035
		_ring_mesh.outer_radius = 0.065
		_ring_mesh.rings = 12
		_ring_mesh.ring_segments = 6
		_ring_look = StandardMaterial3D.new()
		_ring_look.albedo_color = Color(0.22, 0.2, 0.18)
		_ring_look.metallic = 0.8
		_ring_look.roughness = 0.45
	var ring := MeshInstance3D.new()
	ring.mesh = _ring_mesh
	ring.material_override = _ring_look
	return ring
