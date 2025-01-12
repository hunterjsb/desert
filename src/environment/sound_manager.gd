extends Node


var collision_cooldown = 1
var last_collision_time = 0
@export var collision_sounds: Array[AudioStream] = [
	preload("res://audio/object_metal_clank-001.wav"),
	preload("res://audio/object_metal_clank-002.wav"),
	preload("res://audio/object_metal_clank-003.wav"),
	preload("res://audio/object_metal_clank-004.wav"),
	preload("res://audio/object_metal_clank-005.wav"),
	preload("res://audio/object_metal_clank-006.wav"),
	preload("res://audio/object_metal_clank-007.wav"),
	preload("res://audio/object_metal_clank-008.wav"),
	preload("res://audio/object_metal_clank-009.wav"),
]

func randomclank(body: InteractableBody3D):
	var audio_player = AudioStreamPlayer3D.new()
	body.add_child(audio_player)
	audio_player.stream = collision_sounds[randi() % collision_sounds.size()]
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.volume_db = -24
