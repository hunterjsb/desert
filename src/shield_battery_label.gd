extends Label3D

@onready var shield = $".."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = str(round(shield.energy))
