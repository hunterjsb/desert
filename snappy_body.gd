extends InteractableBody3D

@onready var snap_area = $SnapArea

# Connected to SnapArea _on_body_entered.
# SnapAreas should be on layer 4, so the area we get
# in _on_snap should be another SnapArea.
func _on_snap(area: Area3D) -> void:
	print(area)
	reparent(area)
	freeze = true
