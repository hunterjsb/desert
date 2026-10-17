class_name Broadcast
extends Node
## What the nearest radio you can hear says, as one line low in the view: the
## weather station's reading or a beacon's bearing, while you're in earshot of
## a radio tuned to one. A stand-in for a voice (Radio PRD, open question).

## Heard from this far, m: anywhere in a light shield's bubble round it.
const EARSHOT := 5.0

## What the line says now, "" when it's down.
var said := ""

var _player: Player
var _line: Label


func _ready() -> void:
	_player = get_parent() as Player
	var layer := CanvasLayer.new()
	layer.layer = 98
	add_child(layer)
	_line = Label.new()
	_line.theme_type_variation = &"Readout"
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_line.offset_left = -400.0
	_line.offset_right = 400.0
	_line.offset_top = -64.0
	_line.offset_bottom = -44.0
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.modulate.a = 0.0
	layer.add_child(_line)


func _process(delta: float) -> void:
	said = ""
	var nearest := EARSHOT
	for radio: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		var far := radio.global_position.distance_to(_player.camera.global_position)
		if radio.said != "" and far < nearest:
			nearest = far
			said = radio.said
	if said != "":
		_line.text = said
	_line.modulate.a = move_toward(_line.modulate.a, 1.0 if said != "" else 0.0, delta * 6.0)
