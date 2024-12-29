extends RigidBody3D

@onready var theme: AudioStreamPlayer3D = $Music
@onready var static_noise: AudioStreamPlayer3D = $Static

func _ready() -> void:
	theme.play()
	static_noise.play()
	theme.volume_db = -80
	static_noise.volume_db = -80


func interact(player: CharacterBody3D) -> void:
	# --- 1) Toggle (mute/unmute) the main track ---
	if theme.volume_db == 0:
		# Currently unmuted, so mute it
		theme.volume_db = -80
	else:
		# Currently muted, so unmute it
		theme.volume_db = 0

	# --- 2) Play one random second of static noise ---
	var random_offset = randf_range(0, static_noise.stream.get_length() - 1)
	static_noise.seek(random_offset)

	# Unmute static noise
	static_noise.volume_db = 0

	# Use a temporary Timer to remute it after 1 second
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0
	add_child(timer)
	timer.start()

	# When timer finishes, remute the static
	timer.timeout.connect(func():
		static_noise.volume_db = -80
		timer.queue_free()
	)
