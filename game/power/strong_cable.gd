class_name StrongCable
extends Cable
## A strong cable: a cable that's also a rope, so it holds what it's plugged
## into as well as powering it. It never pops a plug; too much load snaps it,
## like rope. Each plug carries the rope's end: fitting a plug moves it into the
## device at the port with the plug's other pieces, and taking it out brings it
## back. Only your hand needs a hand-off: while you hold a plug, the rope pulls
## on you, not on the plug held fast in your grip.

## Stronger than common rope: it's meant to hold a floating camp piece in a storm.
const BREAKING := 4000.0

var rope: Rope
var _world: World
## Each plug's own end of the rope.
var _plug_ends: Array[RopeEnd] = []
## Which plug is in your hand, or -1.
var _in_hand := -1


func bind(world: World) -> void:
	_world = world
	for plug in plugs:
		_plug_ends.append(RopeEnd.make(plug, Vector3(0.0, 0.0, 0.045), false))
	rope = world.ropes.tie(_plug_ends[0], _plug_ends[1], length, BREAKING)
	world.ropes.snapped.connect(_on_snapped)
	_wire.visible = false


## Joined only while the rope holds: a snapped strong cable carries nothing.
func joined() -> Array[Device]:
	return super() if rope != null else []


func _ready() -> void:
	# The hand-off happens before the ropes are solved each tick.
	process_physics_priority = -20


func _process(_delta: float) -> void:
	if not plugs.all(func(p: Part) -> bool: return is_instance_valid(p)):
		if rope != null:
			_world.ropes.let_go(rope, rope.a)
			rope = null
		queue_free()


func _physics_process(_delta: float) -> void:
	if rope == null or not plugs.all(func(p: Part) -> bool: return is_instance_valid(p)):
		return
	var holding := plugs.find(_world.player.hands.held)
	if holding == _in_hand:
		return
	var hand := _world.ropes.hand
	if _in_hand != -1:
		_world.ropes.move_end(rope, hand, _plug_ends[_in_hand])
	if holding != -1:
		_world.ropes.move_end(rope, _plug_ends[holding], hand)
	_in_hand = holding


## The rope holds instead: it never pops a plug.
func _overstretched(_a: Vector3, _b: Vector3) -> void:
	pass


## The strand draws it, sag and all.
func _draw(_a: Vector3, _b: Vector3) -> void:
	_wire.visible = false


func _on_snapped(which: Rope) -> void:
	if which == rope:
		rope = null
