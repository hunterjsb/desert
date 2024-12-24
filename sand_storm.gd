extends Area3D

@export var damage = 1              # The amount of damage each tick
@export var damage_ticks = 5        # Number of damage "ticks" per second

var players_in_storm: Array = []
var time_accum = 0.0

func _ready() -> void:
	# Use the correct syntax for connecting signals:
	body_entered.connect(_on_sand_storm_body_entered)
	body_exited.connect(_on_sand_storm_body_exited)

func _process(delta: float) -> void:
	# Accumulate time and deal damage at intervals
	time_accum += delta
	var tick_interval = 1.0 / float(damage_ticks)

	# If enough time has passed for a "tick," deal damage
	while time_accum >= tick_interval:
		time_accum -= tick_interval

		# Damage any players in the storm who are NOT protected by the shield
		for player in players_in_storm:
			if not player.is_in_bubble_shield:
				player.take_damage(damage)

func _on_sand_storm_body_entered(body: Node):
	if body.name == "Player":
		# The object is the player; store a reference
		players_in_storm.append(body)
		print("Player entered the Sand Storm")

func _on_sand_storm_body_exited(body: Node):
	if body.name == "Player":
		# Remove the player from the list
		players_in_storm.erase(body)
		print("Player exited the Sand Storm")
