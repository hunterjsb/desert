extends RigidBody3D

@onready var theme: AudioStreamPlayer3D = $Music
@onready var static_noise: AudioStreamPlayer3D = $Static

func _ready() -> void:
	theme.play()
	static_noise.play()
	theme.volume_db = -80
	static_noise.volume_db = -80


func interact(player: CharacterBody3D) -> void:
	if theme.volume_db == 0:
		theme.volume_db = -80
	else:
		theme.volume_db = 0
	
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
