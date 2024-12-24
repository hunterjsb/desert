extends RigidBody3D

@export var tween_time = 0.6

@onready var bubble_shield_area = $BubbleShield
var is_active := false

const MIN_SCALE = 0.001

func _ready():
	bubble_shield_area.visible = false
	bubble_shield_area.monitoring = false
	bubble_shield_area.monitorable = false
	bubble_shield_area.scale = Vector3(MIN_SCALE, MIN_SCALE, MIN_SCALE)

func toggle_bubble_shield():
	is_active = !is_active
	
	if is_active:
		bubble_shield_area.visible = true
		bubble_shield_area.monitoring = true
		bubble_shield_area.monitorable = true
		bubble_shield_area.scale = Vector3(MIN_SCALE, MIN_SCALE, MIN_SCALE)

		create_tween().tween_property(
				bubble_shield_area, 
				"scale", 
				Vector3.ONE,
				tween_time
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		create_tween().tween_property(
				bubble_shield_area,
				"scale",
				Vector3(MIN_SCALE, MIN_SCALE, MIN_SCALE),
				tween_time
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		await get_tree().create_timer(tween_time).timeout
		bubble_shield_area.visible = false
		bubble_shield_area.monitoring = false
		bubble_shield_area.monitorable = false

func _process(delta):
	if global_position.y < -100:
		print("shield probably fell out of the world")
