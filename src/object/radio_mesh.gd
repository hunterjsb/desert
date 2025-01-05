extends InteractableBody3D

var env: Node3D
@onready var daytheme: AudioStreamPlayer3D = $SandyAndy
@onready var nightheme: AudioStreamPlayer3D = $WaitingontheSun
@onready var static_noise: AudioStreamPlayer3D = $Static

func _ready() -> void:
	daytheme.play()
	nightheme.play()
	static_noise.play()
	daytheme.volume_db = -80
	static_noise.volume_db = -80

func interact(player: Node) -> void:
	if (18 > env.day_time) and (6 < env.day_time):
		daytheme.volume_db = 0
		nightheme.volume_db = -80
	else:
		daytheme.volume_db = -80
		nightheme.volume_db = 0
	
	# play some static
	var random_offset = randf_range(0, static_noise.stream.get_length() - 1)
	static_noise.seek(random_offset)
	static_noise.volume_db = 0
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0
	add_child(timer)
	timer.start()
	timer.timeout.connect(func():
		static_noise.volume_db = -80
		timer.queue_free()
	)
