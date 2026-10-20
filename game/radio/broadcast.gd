class_name Broadcast
extends Node
## What the nearest radio you can hear says. The radio is sound only
## (gonkhub, 2026-10-19: "Remove all text dialogue from the radio. Audio
## only."): nothing it says is written in the view. `said` keeps what the
## nearest one in earshot would say, the weather station's reading or a
## beacon's bearing, and `logged` the Walker's log under it as it comes
## through, for the dev overlay and the probes. The weather station's voice
## comes from the radio itself.

## Heard from this far, m: anywhere in a light shield's bubble round it.
const EARSHOT := 5.0

## What the nearest radio in earshot says now, and the Walker's log under it;
## "" when none does. Never shown.
var said := ""
var logged := ""

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func _process(_delta: float) -> void:
	said = ""
	logged = ""
	var nearest := EARSHOT
	for radio: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		var far := radio.global_position.distance_to(_player.camera.global_position)
		if radio.said != "" and far < nearest:
			nearest = far
			said = radio.said
			logged = radio.logged
