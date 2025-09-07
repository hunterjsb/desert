extends Node
class_name PlantingComponent

# Simple planting component - just tracks what's planted where

signal crop_planted(crop_type: String)
signal crop_harvested(items: Array)

var planted_crops: Dictionary = {}  # slot_name -> {crop_type, planted_time, growth_time}

func _ready() -> void:
	# Connect to StickyArea for food detection
	var sticky_area = get_node_or_null("../StickyArea")
	if sticky_area:
		sticky_area.body_entered.connect(_on_item_entered_area)
		print("PlantingComponent: Ready")

func _on_item_entered_area(body: Node3D) -> void:
	# Simple crop detection
	var crop_type = ""
	if "carrot" in body.name.to_lower():
		crop_type = "carrot"
	elif "yucca" in body.name.to_lower():
		crop_type = "yucca"
	
	if crop_type == "":
		return
	
	# Find available slot
	var slot_name = find_available_slot(crop_type)
	if slot_name == "":
		print("PlantingComponent: No available slots for ", crop_type)
		return
	
	# Plant the crop
	plant_crop(slot_name, crop_type)
	body.queue_free()
	
	print("PlantingComponent: Planted ", crop_type, " in ", slot_name)

func find_available_slot(crop_type: String) -> String:
	if crop_type == "yucca":
		# Check large slot
		if not planted_crops.has("LargePlantSlot"):
			return "LargePlantSlot"
	else:  # carrot
		# Check small slots
		for i in range(1, 5):
			var slot_name = "SmallPlantSlot" + str(i)
			if not planted_crops.has(slot_name):
				return slot_name
	
	return ""  # No available slots

func plant_crop(slot_name: String, crop_type: String) -> void:
	var growth_time = 30.0 if crop_type == "carrot" else 45.0
	
	planted_crops[slot_name] = {
		"crop_type": crop_type,
		"planted_time": Time.get_time_dict_from_system(),
		"growth_time": growth_time,
		"phase": "GROWING",
		"timer_ref": null  # Store timer reference for time calculation
	}
	
	# Start growth timer
	var timer = Timer.new()
	timer.wait_time = growth_time
	timer.one_shot = true
	timer.timeout.connect(_on_crop_ready.bind(slot_name, crop_type))
	add_child(timer)
	timer.start()
	
	# Store timer reference for time calculation
	planted_crops[slot_name]["timer_ref"] = timer
	
	crop_planted.emit(crop_type)

func _on_crop_ready(slot_name: String, crop_type: String) -> void:
	# Harvest the crop
	var yield_count = 4 if crop_type == "carrot" else 1
	var yield_scene = "res://src/object/food/carrot.tscn" if crop_type == "carrot" else "res://src/object/food/yucca_fruit.tscn"
	
	var items = []
	for i in range(yield_count):
		var item = load(yield_scene).instantiate()
		
		# Add to scene first
		get_parent().get_parent().add_child(item)
		
		# Spread carrots out more to avoid collision overlap
		var angle = (i * PI * 0.5)  # 90 degree intervals around planter
		var distance = 1.5  # Further from center
		var offset = Vector3(cos(angle) * distance, 1, sin(angle) * distance)
		item.global_position = get_parent().global_position + offset
		
		# Give each carrot a small random impulse so they don't stack
		if item is RigidBody3D:
			var random_impulse = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
			item.apply_central_impulse(random_impulse)
		
		items.append(item)
	
	# Clear slot
	planted_crops.erase(slot_name)
	
	crop_harvested.emit(items)
	print("PlantingComponent: Harvested ", yield_count, " ", crop_type, "s")

func get_planting_status() -> Dictionary:
	var crops_info = []
	var has_yucca = false
	var carrot_count = 0
	
	for slot_name in planted_crops:
		var crop = planted_crops[slot_name]
		var timer = crop.timer_ref as Timer
		var time_remaining = timer.time_left if timer and is_instance_valid(timer) else 0.0
		
		if crop.crop_type == "yucca":
			has_yucca = true
		else:
			carrot_count += 1
		
		crops_info.append({
			"crop_type": crop.crop_type.to_upper(),
			"phase": crop.phase,
			"time_remaining": time_remaining
		})
	
	# Build status string that makes sense  
	var status_text = ""
	if has_yucca:
		status_text = "YUCCA planted"
	elif carrot_count > 0:
		status_text = "%d CARROT%s planted" % [carrot_count, "S" if carrot_count > 1 else ""]
	else:
		status_text = "Empty"
	
	return {
		"status_text": status_text,
		"occupied_slots": planted_crops.size(),
		"crops": crops_info
	}
