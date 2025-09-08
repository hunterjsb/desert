extends Node
class_name PlantingComponent

# Truly extensible planting component

signal crop_planted(crop_type: String)
signal crop_harvested(items: Array)

# Extensible crop configuration
@export var crop_configs: Array[CropConfig] = []

var planted_crops: Dictionary = {}

func _ready() -> void:
	# Connect to StickyArea for food detection
	var sticky_area = get_node_or_null("../StickyArea")
	if sticky_area:
		sticky_area.body_entered.connect(_on_item_entered_area)
	
	# Set up default crop configs if none provided
	if crop_configs.is_empty():
		setup_default_crops()

func setup_default_crops():
	var carrot_config = CropConfig.new()
	carrot_config.crop_name = "carrot"
	carrot_config.seed_scene_path = "res://src/object/food/carrot.tscn"
	carrot_config.yield_scene_path = "res://src/object/food/carrot.tscn"
	carrot_config.slot_type = CropConfig.SlotType.SMALL
	carrot_config.growth_time = 30.0
	carrot_config.yield_count = 4
	
	var yucca_config = CropConfig.new()
	yucca_config.crop_name = "yucca"
	yucca_config.seed_scene_path = "res://src/object/food/yucca_fruit.tscn"
	yucca_config.yield_scene_path = "res://src/object/food/yucca_fruit.tscn"
	yucca_config.plant_scene_path = "res://src/object/agriculture/yucca.tscn"
	yucca_config.slot_type = CropConfig.SlotType.LARGE
	yucca_config.growth_time = 45.0
	yucca_config.yield_count = 1
	yucca_config.is_renewable = true
	yucca_config.fruit_regeneration_time = 60.0
	
	crop_configs = [carrot_config, yucca_config]

func _on_item_entered_area(body: Node3D) -> void:
	# Find matching crop config by checking scene name
	var crop_config = find_crop_config_for_item(body)
	if not crop_config:
		return
	
	# Find available slot for this crop type
	var slot_name = find_available_slot(crop_config)
	if slot_name == "":
		return
	
	# Plant the crop
	plant_crop(slot_name, crop_config)
	body.queue_free()

func find_crop_config_for_item(item: Node3D) -> CropConfig:
	var item_name = item.name.to_lower()
	for config in crop_configs:
		if config.crop_name in item_name:
			return config
	return null

func find_available_slot(config: CropConfig) -> String:
	if config.slot_type == CropConfig.SlotType.LARGE:
		# Check if large slot is available
		if not planted_crops.has("LargePlantSlot"):
			return "LargePlantSlot"
	else:  # SMALL
		# Check all small slots
		for i in range(1, 5):
			var slot_name = "SmallPlantSlot" + str(i)
			if not planted_crops.has(slot_name):
				return slot_name
	return ""

func plant_crop(slot_name: String, config: CropConfig) -> void:
	planted_crops[slot_name] = {
		"crop_config": config,
		"phase": "GROWING",
		"timer_ref": null
	}
	
	# Start growth timer
	var timer = Timer.new()
	timer.wait_time = config.growth_time
	timer.one_shot = true
	timer.timeout.connect(_on_crop_ready.bind(slot_name, config))
	add_child(timer)
	timer.start()
	
	planted_crops[slot_name]["timer_ref"] = timer
	crop_planted.emit(config.crop_name)

func _on_crop_ready(slot_name: String, config: CropConfig) -> void:
	if config.is_renewable and config.plant_scene_path != "":
		# Spawn permanent plant that will produce fruit over time
		spawn_renewable_plant(slot_name, config)
	else:
		# Spawn consumable yield and clear slot for replanting
		spawn_consumable_yield(slot_name, config)

func spawn_renewable_plant(slot_name: String, config: CropConfig) -> void:
	# Find the slot marker
	var slot_marker = find_slot_marker(slot_name)
	if not slot_marker:
		return
	
	# Spawn the plant at slot location
	var plant = load(config.plant_scene_path).instantiate()
	slot_marker.add_child(plant)
	plant.global_position = slot_marker.global_position
	
	# Mark slot as permanently occupied by plant
	planted_crops[slot_name] = {
		"crop_config": config,
		"phase": "MATURE_PLANT",
		"timer_ref": null,
		"plant_instance": plant
	}
	
	# Start fruit generation timer
	start_fruit_regeneration(slot_name, config)
	
	print("PlantingComponent: Spawned renewable plant at ", slot_name)

func spawn_consumable_yield(slot_name: String, config: CropConfig) -> void:
	var items = []
	for i in range(config.yield_count):
		var item = load(config.yield_scene_path).instantiate()
		get_parent().get_parent().add_child(item)
		
		var angle = (i * PI * 0.5)
		var distance = 1.5
		var offset = Vector3(cos(angle) * distance, 1, sin(angle) * distance)
		item.global_position = get_parent().global_position + offset
		
		if item is RigidBody3D:
			var random_impulse = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
			item.apply_central_impulse(random_impulse)
		
		items.append(item)
	
	# Clear slot for replanting
	planted_crops.erase(slot_name)
	crop_harvested.emit(items)

func start_fruit_regeneration(slot_name: String, config: CropConfig) -> void:
	var timer = Timer.new()
	timer.wait_time = config.fruit_regeneration_time
	timer.one_shot = false  # Repeating timer for continuous fruit production
	timer.timeout.connect(_on_fruit_ready.bind(slot_name, config))
	add_child(timer)
	timer.start()
	
	planted_crops[slot_name]["timer_ref"] = timer

func _on_fruit_ready(slot_name: String, config: CropConfig) -> void:
	# Spawn fruit around the plant
	var items = []
	for i in range(config.yield_count):
		var item = load(config.yield_scene_path).instantiate()
		get_parent().get_parent().add_child(item)
		
		var angle = (i * PI * 0.5)
		var distance = 1.0  # Closer to plant
		var offset = Vector3(cos(angle) * distance, 1, sin(angle) * distance)
		item.global_position = get_parent().global_position + offset
		
		items.append(item)
	
	crop_harvested.emit(items)
	print("PlantingComponent: Yucca plant produced fruit!")

func find_slot_marker(slot_name: String) -> Marker3D:
	# Find the slot marker by searching groups
	var large_slots = get_tree().get_nodes_in_group("large_plant_slot")
	var small_slots = get_tree().get_nodes_in_group("small_plant_slot")
	
	# Check large slots
	for slot in large_slots:
		if get_parent().is_ancestor_of(slot) and slot.name == slot_name:
			return slot as Marker3D
	
	# Check small slots  
	for slot in small_slots:
		if get_parent().is_ancestor_of(slot) and slot.name == slot_name:
			return slot as Marker3D
	
	return null

func get_planting_status() -> Dictionary:
	var crops_info = []
	var has_large = false
	var small_count = 0
	
	for slot_name in planted_crops:
		var crop = planted_crops[slot_name]
		var config = crop.crop_config as CropConfig
		var timer = crop.timer_ref as Timer
		var time_remaining = timer.time_left if timer and is_instance_valid(timer) else 0.0
		
		if config.slot_type == CropConfig.SlotType.LARGE:
			has_large = true
		else:
			small_count += 1
		
		crops_info.append({
			"crop_type": config.crop_name.to_upper(),
			"phase": crop.phase,
			"time_remaining": time_remaining
		})
	
	var status_text = ""
	if has_large:
		status_text = "YUCCA planted"
	elif small_count > 0:
		status_text = "%d CARROT%s planted" % [small_count, "S" if small_count > 1 else ""]
	else:
		status_text = "Empty"
	
	return {
		"status_text": status_text,
		"occupied_slots": planted_crops.size(),
		"crops": crops_info
	}
