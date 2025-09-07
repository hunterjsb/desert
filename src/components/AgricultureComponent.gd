extends Node
class_name AgricultureComponent

# ECS component for plant growth behavior
# Defines how plants grow, what they yield, and when they're ready to harvest

signal growth_completed()
signal ready_to_harvest()
signal harvested(items: Array)

enum CropType { CARROT, YUCCA }
enum GrowthPhase { SEED, SPROUT, GROWING, MATURE, HARVESTABLE }

@export var crop_type: CropType = CropType.CARROT
@export var growth_time: float = 30.0  # Time in seconds to full maturity
@export var auto_harvest: bool = true  # Automatically harvest when ready

var current_phase: GrowthPhase = GrowthPhase.SEED
var growth_timer: float = 0.0
var is_growing: bool = false

# Growth configuration per crop type
var crop_configs = {
	CropType.CARROT: {
		"yield_count": 4,
		"yield_scene": "res://src/object/food/carrot.tscn",
		"plant_scene": null,  # Carrots don't become plants, just multiply
		"growth_phases": [
			{"name": "seed", "duration": 0.2},
			{"name": "sprout", "duration": 0.3}, 
			{"name": "growing", "duration": 0.3},
			{"name": "harvestable", "duration": 0.2}
		]
	},
	CropType.YUCCA: {
		"yield_count": 1,
		"yield_scene": "res://src/object/food/yucca_fruit.tscn",
		"plant_scene": "res://src/object/agriculture/yucca.tscn",
		"growth_phases": [
			{"name": "seed", "duration": 0.3},
			{"name": "sprout", "duration": 0.2},
			{"name": "growing", "duration": 0.3},
			{"name": "harvestable", "duration": 0.2}
		]
	}
}

func _ready() -> void:
	# Start growing immediately when added to scene
	start_growth()

func start_growth() -> void:
	is_growing = true
	current_phase = GrowthPhase.SEED
	growth_timer = 0.0
	set_process(true)

func _process(delta: float) -> void:
	if not is_growing:
		return
	
	growth_timer += delta
	
	# Check if we should advance to next growth phase
	var config = crop_configs[crop_type]
	var phases = config["growth_phases"]
	var current_phase_config = phases[current_phase]
	var phase_duration = current_phase_config["duration"] * growth_time
	
	if growth_timer >= phase_duration:
		advance_growth_phase()

func advance_growth_phase() -> void:
	growth_timer = 0.0
	
	match current_phase:
		GrowthPhase.SEED:
			current_phase = GrowthPhase.SPROUT
		GrowthPhase.SPROUT:
			current_phase = GrowthPhase.GROWING
		GrowthPhase.GROWING:
			current_phase = GrowthPhase.MATURE
		GrowthPhase.MATURE:
			current_phase = GrowthPhase.HARVESTABLE
			growth_completed.emit()
			if auto_harvest:
				harvest()
		GrowthPhase.HARVESTABLE:
			ready_to_harvest.emit()

func harvest() -> Array:
	if current_phase != GrowthPhase.HARVESTABLE:
		return []
	
	var config = crop_configs[crop_type]
	var yield_items = []
	
	# Create yield items
	var yield_scene_path = config["yield_scene"]
	var yield_count = config["yield_count"]
	
	for i in range(yield_count):
		var item = load(yield_scene_path).instantiate()
		yield_items.append(item)
	
	# For yucca, also spawn the plant if it grows into one
	if crop_type == CropType.YUCCA and config["plant_scene"]:
		var plant = load(config["plant_scene"]).instantiate()
		# Plant stays in the slot, fruit is the harvestable yield
		get_parent().add_child(plant)
		plant.global_position = get_parent().global_position
	
	is_growing = false
	set_process(false)
	harvested.emit(yield_items)
	
	return yield_items

func get_growth_progress() -> float:
	if not is_growing:
		return 1.0
	
	var config = crop_configs[crop_type]
	var phases = config["growth_phases"]
	
	# Calculate total progress across all phases
	var total_progress = 0.0
	for i in range(current_phase):
		total_progress += phases[i]["duration"]
	
	# Add current phase progress
	var current_phase_config = phases[current_phase]
	var phase_duration = current_phase_config["duration"] * growth_time
	total_progress += (growth_timer / phase_duration) * current_phase_config["duration"]
	
	return total_progress

func get_crop_info() -> Dictionary:
	return {
		"crop_type": CropType.keys()[crop_type],
		"phase": GrowthPhase.keys()[current_phase],
		"progress": get_growth_progress(),
		"is_growing": is_growing,
		"time_remaining": get_time_remaining()
	}

func get_time_remaining() -> float:
	if not is_growing:
		return 0.0
	
	var config = crop_configs[crop_type]
	var phases = config["growth_phases"]
	
	var remaining_time = 0.0
	# Time left in current phase
	var current_phase_config = phases[current_phase]
	var phase_duration = current_phase_config["duration"] * growth_time
	remaining_time += phase_duration - growth_timer
	
	# Time for remaining phases
	for i in range(current_phase + 1, phases.size()):
		remaining_time += phases[i]["duration"] * growth_time
	
	return remaining_time
