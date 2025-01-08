extends Control

@export var player: CharacterBody3D
@export var environment: Node3D
@onready var wind_man: Node3D = environment.get_node("WindManager")

@onready var coords = $CoordsLabel
@onready var time = $TimeLabel
@onready var wind = $WindLabel
@onready var hunger = $HungerLabel


func _process(delta: float) -> void:
	if visible:
		coords.text = "%s" % snapped(player.global_position, Vector3(0.01, 0.01, 0.01))
		
		time.text = "%02dhr" % environment.day_time
		
		var wind_angle = wind_man.major_dir_angle_current
		wind.text = "Wind: %s (%d)" % [deg_to_compass(wind_angle), wind_angle]
		
		hunger.text = "Hunger: %d" % player.hunger
	
func deg_to_compass(degrees: float) -> String:
	var compass = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var index = int(round(degrees / 45.0)) % 8
	return compass[index]
