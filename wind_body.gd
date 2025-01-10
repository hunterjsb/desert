extends RigidBody3D

@onready var wind_manager = $"../../Environment/WindManager"
@onready var velocity_label_3d = $VelocityLabel3D

@export var wind_force_multiplier: float = 2.0

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	# Get wind vector and apply force
	var wind_vector = wind_manager.get_wind_vector()
	apply_central_force(wind_vector * wind_force_multiplier)

	# Format the dashboard text
	var dashboard_text = ""
	dashboard_text += "=== WIND DASHBOARD ===\n"
	dashboard_text += "WIND VECTOR: " + str((wind_vector * 100).round()) + " cm/s\n"
	dashboard_text += "GUST FACTOR: " + str(round(wind_manager.current_gust_factor * 100)) + "%\n"
	dashboard_text += "CARDINAL DIRECTION: " + deg_to_compass(wind_manager.major_dir_angle_current) + "\n"

	velocity_label_3d.text = dashboard_text

func _on_gust_started() -> void:
	# Display a message or highlight gust status
	print("[WindyBody] A gust has started!")
	velocity_label_3d.text += "GUST: ACTIVE\n"

func _on_gust_ended() -> void:
	# Display a message or update gust status
	print("[WindyBody] The gust has ended.")
	velocity_label_3d.text += "GUST: INACTIVE\n"

func _on_cardinal_direction_changed(new_dir: float) -> void:
	# Update direction info and display
	var direction_text = deg_to_compass(new_dir)
	print("[WindyBody] Wind direction changed to:", direction_text)
	velocity_label_3d.text += "DIRECTION: " + direction_text + "\n"

func deg_to_compass(degrees: float) -> String:
	var compass = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var index = int(round(degrees / 45.0)) % 8
	return compass[index]
