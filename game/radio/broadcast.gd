class_name Broadcast
extends Node
## What the nearest radio says, retained for diagnostics. Sound comes from its
## bundled reader; there is no HUD transcript or system speech.

const EARSHOT := 5.0
var said := ""
var reading := ""

func _process(_delta: float) -> void:
	said = ""
	reading = ""
	var player := get_parent() as Player
	var nearest := EARSHOT
	for radio: Radio in get_tree().get_nodes_in_group(Radio.GROUP):
		var far := radio.global_position.distance_to(player.camera.global_position)
		if radio.said != "" and far < nearest:
			nearest = far
			said = radio.said
			reading = " ".join(radio.spoken)
