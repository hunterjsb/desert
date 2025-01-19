extends InteractableBody3D

var env: Node3D
@onready var daytheme: AudioStreamPlayer3D = $SandyAndy
@onready var nightheme: AudioStreamPlayer3D = $WaitingontheSun
@onready var static_noise: AudioStreamPlayer3D = $Static

@export var is_playing: bool = false

var last_day_state: bool

func is_day() -> bool:
	if not env:
		return true
	return env.day_time >= 6 and env.day_time < 18

func _ready() -> void:
	daytheme.play()
	nightheme.play()
	static_noise.play()
	static_noise.volume_db = -80

	# Force an initial volume update respecting is_playing and the day/night cycle
	last_day_state = not is_day()
	_update_theme_volumes(true)


func _process(_delta: float) -> void:
	if not is_playing:
		return

	var day = is_day()
	if day != last_day_state:
		last_day_state = day
		_update_theme_volumes()


func _update_theme_volumes(force: bool = false) -> void:
	if not is_playing:
		daytheme.volume_db = -80
		nightheme.volume_db = -80
		return
	
	var day = is_day()
	if force or day != last_day_state:
		if day:
			daytheme.volume_db = 0
			nightheme.volume_db = -80
		else:
			daytheme.volume_db = -80
			nightheme.volume_db = 0
		
		# Keep the last_day_state in sync if forced
		last_day_state = day


func interact(_player: Node) -> void:
	kshhh()
	toggle_sound()

func toggle_sound() -> void:
	# Flip is_playing and do a single volume update
	is_playing = not is_playing
	_update_theme_volumes(true)


func get_storm_distance() -> void:
	pass

func _on_area_3d_area_entered(_area: Area3D) -> void:
	SoundManager.randomclank(self)
	kshhh()

func kshhh() -> void:
	# play some static
	var random_offset = randf_range(0, static_noise.stream.get_length() - 1)
	static_noise.seek(random_offset)
	static_noise.volume_db = 0

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0
	add_child(timer)
	timer.start()

	timer.timeout.connect(func() -> void:
		static_noise.volume_db = -80
		timer.queue_free()
	)
