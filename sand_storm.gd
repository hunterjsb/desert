extends Area3D

@export_group("Environment")
@export var wind_manager: Node3D
@export var environment_parent: String = "main"  # for fallback
@export var sun: DirectionalLight3D

@export_group("Damage")
@export var damage = 1
@export var damage_ticks = 3

@export_group("Lighting")
@export var storm_darkening = 0.8
@export var storm_darkening_time = 1.0

@export_group("Movement")
@export var min_speed = 0.5            # Minimum speed the storm travels
@export var velocity_lerp_factor = 2.0 # How fast the storm velocity lerps to the new wind velocity
@export var unusual_velocity_threshold = 10.0

@export_group("Player Tracking")
@export var enable_player_tracking: bool = false
@export var player_track_strength: float = 0.2

var players_in_storm: Array = []
var time_accum = 0.0
var velocity: Vector3 = Vector3.ZERO

@onready var storm_audio = $SandStormAudio


func _ready() -> void:
	storm_audio.bus = "Storm"
	
	if not wind_manager:
		wind_manager = get_node("/root/%s/Environment/WindManager" % environment_parent)
		print("windman fallback to ", wind_manager)
	wind_manager.cardinal_direction_changed.connect(_on_wind_cardinal_change)
	wind_manager.gust_started.connect(_on_wind_gust_started)
	wind_manager.gust_ended.connect(_on_wind_gust_ended)
	
	if not sun:
		sun = get_node("/root/%s/Environment/Sun" % environment_parent)
		print("sun fallback to ", sun)

	# Update velocity to match current wind at spawn
	velocity = wind_manager.get_wind_vector()
	if velocity.length() < min_speed:
		velocity = velocity.normalized() * min_speed

	# Connect body_entered / exited signals for damage logic
	body_entered.connect(_on_sand_storm_body_entered)
	body_exited.connect(_on_sand_storm_body_exited)


func _process(delta: float) -> void:
	# 1) Lerp velocity towards current wind
	var target_wind = wind_manager.get_wind_vector()
	velocity = velocity.lerp(target_wind, velocity_lerp_factor * delta)

	# 2) Add a small "pull" toward the player if enabled
	if enable_player_tracking:
		var players_list = get_tree().get_nodes_in_group("Player")
		if players_list.size() > 0:
			var target_player = players_list[0]
			var to_player = target_player.global_transform.origin - global_transform.origin
			velocity += to_player.normalized() * player_track_strength

	# 3) Enforce minimum speed
	var spd = velocity.length()
	if spd < min_speed and spd > 0.001:
		velocity = velocity.normalized() * min_speed

	# 4) Move the storm by velocity
	global_transform.origin += velocity * delta

	# 5) Check for unusual velocity and remove y component
	velocity *= Vector3(1, 0, 1)
	if velocity.length() > unusual_velocity_threshold:
		print("[Sandstorm] Unusual velocity detected! v=", velocity)

	# 6) Damage Ticking
	time_accum += delta
	var tick_interval = 1.0 / float(damage_ticks)
	while time_accum >= tick_interval:
		time_accum -= tick_interval
		for player in players_in_storm:
			if not player.is_in_bubble_shield:
				player.take_damage(damage)


### SIGNAL HANDLERS
func _on_wind_cardinal_change(new_dir: float) -> void:
	print("[Sandstorm] Cardinal wind direction changed to: ", new_dir)

func _on_wind_gust_started() -> void:
	pass
	# print("[Sandstorm] Gust started! Watch out!")

func _on_wind_gust_ended() -> void:
	pass
	# print("[Sandstorm] Gust ended.")


### AREA3D callbacks
func _on_sand_storm_body_entered(body: Node):
	if body.name == "Player":
		body.is_in_storm = true
		players_in_storm.append(body)
		print("Player entered the Sand Storm")

		var t = create_tween()
		t.tween_property(sun, "light_energy", sun.light_energy*(1 - storm_darkening), storm_darkening_time)

		if not storm_audio.playing:
			storm_audio.play()

		# IMPORTANT: Update player's Storm audio state
		if "update_storm_audio" in body:
			body.update_storm_audio()


func _on_sand_storm_body_exited(body: Node):
	if body.name == "Player":
		body.is_in_storm = false
		players_in_storm.erase(body)
		print("Player exited the Sand Storm")

		var t = create_tween()
		t.tween_property(sun, "light_energy", 1, storm_darkening_time)

		if players_in_storm.size() == 0:
			storm_audio.stop()

		# IMPORTANT: Update player's Storm audio state
		if "update_storm_audio" in body:
			body.update_storm_audio()
