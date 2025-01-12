extends InteractableBody3D

var env: Node3D
@onready var daytheme: AudioStreamPlayer3D = $SandyAndy
@onready var nightheme: AudioStreamPlayer3D = $WaitingontheSun
@onready var static_noise: AudioStreamPlayer3D = $Static

@export var is_playing: bool = true

func is_day():
	return (18 > env.day_time) and (6 < env.day_time)

func _ready():
	daytheme.play()
	nightheme.play()
	static_noise.play()
	static_noise.volume_db = -80

func _process(delta: float) -> void:
	if is_playing and not is_day():
		daytheme.volume_db = -80
		nightheme.volume_db = 0
	if is_day() and is_playing:
		daytheme.volume_db = 0
		nightheme.volume_db = -80
func interact(_player: Node) -> void:
	kshhh()
	if not is_playing:
		is_playing = true
		if is_day():
			daytheme.volume_db = 0
		else:
			nightheme.volume_db = 0
	else:
		is_playing = false
		daytheme.volume_db = -80
		nightheme.volume_db = -80

func get_storm_distance():
	pass

func _on_area_3d_area_entered(_area):
	SoundManager.randomclank(self)
	kshhh()

func kshhh():
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
	
