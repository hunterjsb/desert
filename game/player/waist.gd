class_name Waist
extends Node3D
## Your waist: a line tied on here leaves your hands free, at the price of
## walking slower and catching more wind. H ties the line in your hand on, or
## with your hands empty takes the last one back into them; Q lets go of every
## line, the one in your hand at once. Tying is instant; untying takes a
## moment, so a gust can catch you still tied on.

## Where things tied on sit, in your own frame.
const AT := Vector3(0.0, 0.95, -0.15)

## What's tied on: line ends, or a stake with its lines.
var tied: Array[RigidBody3D] = []
## Seconds left untying, or -1; and whether it ends in your hand or on the sand.
var untying := -1.0
var _to_hand := false
var _player: Player
var _tuning := Tuning.current()
var _was := {}
## Let fall, and not yet clear of you.
var _falling: Array[RigidBody3D] = []


func _ready() -> void:
	_player = get_parent() as Player


func holds(body: Object) -> bool:
	return body is RigidBody3D and tied.has(body)


## Ties a body on: it rides at your waist, touching nothing.
func tie(body: RigidBody3D) -> void:
	if body == null or tied.has(body):
		return
	_was[body] = {"layer": body.collision_layer, "mask": body.collision_mask, "mode": body.freeze_mode}
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	body.freeze = true
	body.collision_layer = 0
	body.collision_mask = 0
	tied.append(body)
	_place()


## Takes a body off, a body again where it sat; returns it.
func untie(body: RigidBody3D) -> RigidBody3D:
	tied.erase(body)
	var was: Dictionary = _was.get(body, {})
	_was.erase(body)
	if is_instance_valid(body) and not was.is_empty():
		body.freeze = false
		body.freeze_mode = was.mode
		body.collision_layer = was.layer
		body.collision_mask = was.mask
	return body


## H: the line in your hand onto your waist, or the last one back into your
## hand. Says whether it did anything.
func tie_or_untie() -> bool:
	var hands := _player.hands
	if untying >= 0.0:
		return false
	if hands.held != null and carries_line(hands.held):
		tie(hands.stow())
		return true
	if hands.held == null and not tied.is_empty():
		untying = _tuning.untie_seconds
		_to_hand = true
		return true
	return false


## Q: let go of every line. Says whether there was any to let go of.
func let_go() -> bool:
	var hands := _player.hands
	var any := false
	if hands.held != null and carries_line(hands.held):
		hands.drop()
		any = true
	if not tied.is_empty() and (untying < 0.0 or _to_hand):
		untying = _tuning.untie_seconds if untying < 0.0 else untying
		_to_hand = false
		any = true
	return any


## Whether a body has a live line on it.
func carries_line(body: Node) -> bool:
	var ropes := _player.world.ropes
	for child in body.get_children():
		if child is RopeEnd and not ropes.lines_on(child).is_empty():
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tie_line"):
		if tie_or_untie():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("let_go"):
		if let_go():
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	for i in range(tied.size() - 1, -1, -1):
		if not is_instance_valid(tied[i]):
			_was.erase(tied[i])
			tied.remove_at(i)
	if untying >= 0.0:
		untying -= delta
		if tied.is_empty():
			untying = -1.0
		elif untying < 0.0:
			_undone()
	_place()
	_clear_of_you()
	Dev.put("player/waist", "untying %.1fs" % maxf(untying, 0.0) if untying >= 0.0
		else ("%d tied" % tied.size() if not tied.is_empty() else "-"))


func _process(_delta: float) -> void:
	_place()


func _undone() -> void:
	var hands := _player.hands
	if _to_hand and hands.held == null:
		hands.hold(untie(tied.back()))
		return
	for body: RigidBody3D in tied.duplicate():
		untie(body)
		# Down at your feet, moving as you were; it can't push you until it's clear.
		body.linear_velocity = _player.velocity
		body.add_collision_exception_with(_player)
		_falling.append(body)


func _clear_of_you() -> void:
	for i in range(_falling.size() - 1, -1, -1):
		if not is_instance_valid(_falling[i]):
			_falling.remove_at(i)
			continue
		var body := _falling[i]
		var off := body.global_position - _player.global_position
		if Vector2(off.x, off.z).length() > 0.8 or off.y < -0.3:
			body.remove_collision_exception_with(_player)
			_falling.remove_at(i)


## Each tied body sits with its tie point at your waist, facing out in front.
func _place() -> void:
	var facing := Basis(Vector3.UP, _player.global_rotation.y + PI)
	var at := _player.global_transform * AT
	for body in tied:
		if not is_instance_valid(body):
			continue
		var tie_at := Vector3.ZERO
		for child in body.get_children():
			if child is RopeEnd:
				tie_at = (child as RopeEnd).position
				break
		body.global_transform = Transform3D(facing, at - facing * tie_at)
