class_name StrongCable
extends Cable
## A strong cable: a cable that's also a rope, so it holds what it's plugged
## into as well as powering it. It never pops a plug; too much load snaps it,
## like rope. Each plug carries the rope's end: fitting a plug moves it into the
## device at the port with the plug's other pieces, and taking it out brings it
## back. A plug in your hand is you, as far as the rope is concerned: it pulls
## on you, not on the plug held fast in your grip.

## Where a plug ties on, in its own frame: just inside its back face.
const END_AT := Vector3(0.0, 0.0, 0.045)

var rope: Rope
var _world: World


func bind(world: World) -> void:
	_world = world
	var ends: Array[RopeEnd] = []
	for plug in plugs:
		ends.append(RopeEnd.make(plug, END_AT, false))
	# Stronger than common rope: it's meant to hold a floating camp piece in a storm.
	rope = world.ropes.tie(ends[0], ends[1], length, world.tuning.strong_cable_breaking)
	world.ropes.snapped.connect(_on_snapped)
	_wire.visible = false


## Joined only while the rope holds: a snapped strong cable carries nothing.
func joined() -> Array[Device]:
	return super() if rope != null else []


func _process(_delta: float) -> void:
	if not plugs.all(func(p: Variant) -> bool: return is_instance_valid(p)):
		if rope != null:
			# A plug gone with the land it lay on takes its end with it.
			if is_instance_valid(rope.a):
				_world.ropes.let_go(rope, rope.a)
			else:
				_world.ropes.untie(rope)
			rope = null
		queue_free()


## The rope holds instead: it never pops a plug.
func _overstretched(_a: Vector3, _b: Vector3) -> void:
	pass


## The strand draws it, sag and all, through its stake too.
func _draw(_a: Vector3, _b: Vector3) -> void:
	_wire.visible = false
	_leg.visible = false


## Its rope runs through the stake's ring too, as a line through a hook does.
func _rope_through() -> void:
	if rope == null:
		return
	rope.through = through.ring if is_instance_valid(through) else null
	rope.strand.through = rope.through


func _on_snapped(which: Rope) -> void:
	if which == rope:
		rope = null
