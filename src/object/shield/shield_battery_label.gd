extends Label3D

@onready var shield = $".."


func _process(delta: float) -> void:
	text = str(round(shield.energy))
