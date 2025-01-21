# Hunger.gd

extends Node
class_name Hunger

@export var max_hunger: int = 100
@export var hunger_tick_rate: float = 5.0

signal hunger_state_changed(new_state: String, old_state: String)
signal hunger_changed(hunger_value: int)

var hunger: int
var previous_hunger_state: String = ""
var hunger_timer: float = 0.0

func _ready() -> void:
	hunger = max_hunger
	previous_hunger_state = get_hunger_state()

func _process(delta: float) -> void:
	hunger_timer += delta
	if hunger_timer >= hunger_tick_rate:
		hunger_timer = 0.0
		# Decrease hunger by 1, but never below 0
		hunger = max(hunger - 1, 0)
		emit_signal("hunger_changed", hunger)
		
		var current_state = get_hunger_state()
		if current_state != previous_hunger_state:
			emit_signal("hunger_state_changed", current_state, previous_hunger_state)
			previous_hunger_state = current_state

func add_hunger(amount: int) -> void:
	# For e.g. eating food
	hunger = clamp(hunger + amount, 0, max_hunger)
	emit_signal("hunger_changed", hunger)
	
	var current_state = get_hunger_state()
	if current_state != previous_hunger_state:
		emit_signal("hunger_state_changed", current_state, previous_hunger_state)
		previous_hunger_state = current_state

func get_hunger_state() -> String:
	if hunger <= 25:
		return "You are starving"
	elif hunger <= 75:
		return "You are hungry"
	else:
		return "You are full"

func get_damage_multiplier() -> float:
	# 1.0 = normal damage, 1.1 = 10% more, 1.2 = 20% more
	match get_hunger_state():
		"You are starving":
			return 1.2
		"You are hungry":
			return 1.1
		_:
			return 1.0
