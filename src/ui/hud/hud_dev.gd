extends Control

@export var player: CharacterBody3D
@export var environment: Node3D
@onready var wind_man: Node3D = environment.get_node("WindManager")

@onready var coords = $CoordsLabel
@onready var time = $TimeLabel
@onready var wind = $WindLabel
@onready var hunger = $HungerLabel

var debug_enabled: bool = false

func _ready() -> void:
	# Connect to debug manager
	if DebugManager:
		DebugManager.debug_display_toggled.connect(_on_debug_toggled)
		debug_enabled = DebugManager.is_debug_enabled()
	
	# Update initial visibility
	_update_debug_visibility()

func _process(_delta: float) -> void:
	if debug_enabled and visible:
		coords.text = "%s" % snapped(player.global_position, Vector3(0.01, 0.01, 0.01))
		
		time.text = "%02dhr" % environment.day_time
		
		var wind_angle = wind_man.major_dir_angle_current
		wind.text = "Wind: %s (%d)" % [deg_to_compass(wind_angle), wind_angle]
		
		hunger.text = "Hunger: %d" % player.hunger.hunger

func _on_debug_toggled(enabled: bool) -> void:
	debug_enabled = enabled
	_update_debug_visibility()

func _update_debug_visibility() -> void:
	# Show/hide debug elements but keep health visible
	coords.visible = debug_enabled
	time.visible = debug_enabled  
	wind.visible = debug_enabled
	hunger.visible = debug_enabled
	
func deg_to_compass(degrees: float) -> String:
	var compass = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var index = int(round(degrees / 45.0)) % 8
	return compass[index]
