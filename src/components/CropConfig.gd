class_name CropConfig
extends Resource

# Configuration resource for crop types in planting systems

enum SlotType { SMALL, LARGE }

@export var crop_name: String = ""
@export var seed_scene_path: String = ""
@export var yield_scene_path: String = ""
@export var slot_type: SlotType = SlotType.SMALL
@export var growth_time: float = 30.0
@export var yield_count: int = 1

# Plant behavior configuration
@export var plant_scene_path: String = ""  # If set, grows into a permanent plant
@export var is_renewable: bool = false     # If true, plant produces fruit over time
@export var fruit_regeneration_time: float = 60.0  # Time between fruit harvests