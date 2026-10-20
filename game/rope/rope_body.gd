class_name RopeBody
extends RefCounted
## A rope end's body as the solver sees it for one tick: its mass, its velocity,
## and the push it expects from everything else. Static ends have no inverse mass.

var articulation: WeakRef
var node: Node3D
var rigid: RigidBody3D
var player: Player
var stake := false
## Per axis, so the player can feel a pull along the ground but not off it.
var inv_mass := Vector3.ZERO
## World frame.
var inv_inertia := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
var center := Vector3.ZERO
var velocity := Vector3.ZERO
var spin := Vector3.ZERO
## Velocity change from everything but rope over this tick. Wind, the hover tray
## and contacts act after the rope has solved, so it plans against last tick's.
var expected := Vector3.ZERO
var expected_spin := Vector3.ZERO
## Where the ropes left its velocity last tick, and which tick it was last solved.
var left := Vector3.ZERO
var left_spin := Vector3.ZERO
var tick := 0
