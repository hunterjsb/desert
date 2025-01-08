extends Control

@export var player: CharacterBody3D
@export var environment: Node3D
@onready var wind_man: Node3D = environment.get_node("WindManager")

@onready var coords = $CoordsLabel
@onready var time = $TimeLabel
@onready var wind = $WindLabel


func _process(delta: float) -> void:
	coords.text = "%s" % snapped(player.global_position, Vector3(0.01, 0.01, 0.01))
	
	# var time_of_day_minutes = environment.time_of_day_minutes
	# time.text = "%02d:%02d" % [time_of_day_minutes / 60, time_of_day_minutes % 60]
	
	var wind_angle = wind_man.major_dir_angle_current
	wind.text = "Wind: %s" % deg_to_compass(wind_angle)
	
func deg_to_compass(degrees: float) -> String:
	var compass = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var index = int(round(degrees / 45.0)) % 8
	return compass[index]
