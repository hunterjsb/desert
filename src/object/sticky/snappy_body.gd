extends InteractableBody3D


@onready var snap_area = $SnapArea


func _ready() -> void:
	pass

func _on_snap_area_area_entered(area: Area3D) -> void:
	print(area.name)
	if not area.is_in_group("sticky"):
		print("NOT STICKY")
		return
	print("STICKYYYY")
	if carrying_player:
		carrying_player.clear_hand()
	call_deferred("reparent", area.get_parent())
	freeze = true
