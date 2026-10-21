extends "res://look/sandlight/sandlight.gd"
## Existing alternating GPU measurement, including the apron only in the new draw.
func _wear(look: String) -> void:
	super._wear(look)
	world.terrain._apron.visible = look != "before"


func _moving(name: String, t: float, yaw: float, pitch: float, step: Vector3) -> void:
	await super._moving(name, t, yaw, pitch, step)
	if name != "walk":
		return
	# The inherited capture finishes with this sample, then requests exit.
	world.queue_free()
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
