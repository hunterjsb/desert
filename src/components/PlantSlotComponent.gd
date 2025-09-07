extends Node
class_name PlantSlotComponent

# Simple data component for plant slots
# Tracks slot type, occupancy, and planted crop reference

enum SlotType { SMALL, LARGE }

@export var slot_type: SlotType = SlotType.SMALL
@export var is_occupied: bool = false
var planted_crop: Node3D = null

func can_plant_crop(crop_type: String) -> bool:
	# Check if slot is available and size matches
	if is_occupied:
		return false
	
	match crop_type:
		"carrot":
			return slot_type == SlotType.SMALL
		"yucca":
			return slot_type == SlotType.LARGE
		_:
			return false

func plant_crop(crop: Node3D) -> bool:
	if is_occupied:
		return false
	
	is_occupied = true
	planted_crop = crop
	return true

func harvest_crop() -> Node3D:
	if not is_occupied:
		return null
	
	var crop = planted_crop
	is_occupied = false
	planted_crop = null
	return crop

func clear_slot() -> void:
	is_occupied = false
	if planted_crop:
		planted_crop.queue_free()
	planted_crop = null

func get_crop() -> Node3D:
	return planted_crop