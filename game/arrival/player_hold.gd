class_name PlayerHold
extends RefCounted
## What an arrival scene takes from the player, put back exactly as it found it.
const WALK := 1
const HANDS := 2
const SUIT := 4
## The scene owns the camera: no head feel.
const EYE := 8
const BODY := 16
const VITALS := 32
## A screen or the fall fills the view: the HUD stands aside.
const FOCUS := 64
const ALL := WALK | HANDS | SUIT | EYE | BODY | VITALS | FOCUS

var _player: Player
var _taken := 0
var _was := {}


func _init(player: Player) -> void:
	_player = player


func held() -> bool:
	return _taken != 0


func take(parts: int) -> void:
	release()
	_taken = parts
	var player := _player
	if parts & WALK:
		_was.walk = player.is_physics_processing()
		_was.input = player.is_processing_unhandled_input()
		player.velocity = Vector3.ZERO
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
	if parts & HANDS:
		_was.hands = player.hands.is_processing_unhandled_input()
		player.hands.set_process_unhandled_input(false)
	if parts & SUIT:
		_was.suit = player.suit.is_processing_unhandled_input()
		player.suit.set_process_unhandled_input(false)
	if parts & EYE:
		_was.feel = player.feel.is_processing()
		player.feel.set_process(false)
	if parts & FOCUS:
		_was.focused = player.hands.display_focused
		player.hands.display_focused = true
	if parts & BODY:
		_was.shown = player.body.visible
		_was.body = player.body.is_processing()
		player.body.hide()
		player.body.set_process(false)
	if parts & VITALS:
		_was.vitals = player.vitals.is_physics_processing()
		player.vitals.set_physics_process(false)


func release() -> void:
	if _taken == 0 or not is_instance_valid(_player):
		_taken = 0
		return
	var player := _player
	if _taken & WALK:
		player.set_physics_process(_was.walk)
		player.set_process_unhandled_input(_was.input)
	if _taken & HANDS:
		player.hands.set_process_unhandled_input(_was.hands)
	if _taken & SUIT:
		player.suit.set_process_unhandled_input(_was.suit)
	if _taken & EYE:
		player.feel.set_process(_was.feel)
	if _taken & FOCUS:
		player.hands.display_focused = _was.focused
	if _taken & BODY:
		player.body.visible = _was.shown
		player.body.set_process(_was.body)
	if _taken & VITALS:
		player.vitals.set_physics_process(_was.vitals)
	_taken = 0
	_was.clear()
