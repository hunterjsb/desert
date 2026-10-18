class_name Waist
extends Node3D
## Your waist: a line tied on here leaves your hands free, at the price of
## walking slower and catching more wind. Use with a line in your hand and
## nothing to work ties it on, and with your hands empty takes the last one
## back into them. Tying is instant; untying takes a moment, so a gust can
## catch you still tied on. The first sail's sheet tied here teaches its how-to.

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
## Letting go of only these, or of all when empty.
var _only: Array[RigidBody3D] = []
## The sheet's how-to has had its chance this session.
var _taught := false


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
	_player.world.ropes._towing()
	_sheet_on.call_deferred(body)


## A sail's sheet at your waist is Set Sail: asked once the line laid with
## what was tied on has been tied too.
func _sheet_on(body: RigidBody3D) -> void:
	if is_instance_valid(body) and tied.has(body) and Mast.sheet_end(body):
		Deeds.done(_player.world, &"sail_waist")


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


## The line in your hand onto your waist. Says whether there was one.
func take_from_hands() -> bool:
	var hands := _player.hands
	if untying >= 0.0 or hands.held == null or not carries_line(hands.held):
		return false
	tie(hands.stow())
	return true


## The last line tied on back into your hands, once it's untied. Says whether
## there was one to untie.
func give_back() -> bool:
	if untying >= 0.0 or tied.is_empty() or _player.hands.held != null:
		return false
	untying = _tuning.untie_seconds
	_to_hand = true
	return true


## Lets go of every line tied on, or only `these`, once they're untied. Says
## whether there was any.
func let_go(these: Array[RigidBody3D] = []) -> bool:
	if tied.is_empty() or (untying >= 0.0 and not _to_hand):
		return false
	if untying < 0.0:
		untying = _tuning.untie_seconds
	_to_hand = false
	_only = these
	return true


## Whether a body has a live line on it.
func carries_line(body: Node) -> bool:
	var ropes := _player.world.ropes
	for child in body.get_children():
		if child is RopeEnd and not ropes.lines_on(child).is_empty():
			return true
	return false


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
	if not _taught and Controls.ui != null and Controls.playing() and tied.any(Mast.sheet_end):
		_taught = true
		Controls.ui.teach(Mast.HOW_TO, Mast.HOW_TO_SAYS)
	Dev.put("player/waist", "untying %.1fs" % maxf(untying, 0.0) if untying >= 0.0
		else ("%d tied" % tied.size() if not tied.is_empty() else "-"))


func _process(_delta: float) -> void:
	_place()


func _undone() -> void:
	var hands := _player.hands
	if _to_hand and hands.held == null:
		hands.hold(untie(tied.back()))
		return
	var going: Array[RigidBody3D] = tied.duplicate()
	if not _only.is_empty():
		going.assign(_only.filter(func(b: RigidBody3D) -> bool: return tied.has(b)))
	_only = []
	for body: RigidBody3D in going:
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
