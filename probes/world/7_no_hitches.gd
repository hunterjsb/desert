extends WorldProbe
## World & terrain probe 7: from the first chunk through 3 km of flight, no frame
## spends longer than the hitch line on streaming, bar one: a busy machine can
## pause the main thread mid-piece, while streaming that overruns its budget does
## it at every chunk crossed. Headless runs skip the shader compile and the GPU's
## side of an upload; look/stream holds a real window to the line, strictly.
## Runs alone: it times real frames.

var _limit := Tuning.current().stream_frame_max_ms
var _over := 0


func run() -> void:
	# After the terrain's, so every frame's streaming time is seen.
	process_priority = 1
	await load_world()
	var x := world.player_world_x()
	var z := world.player_world_z()
	for i in 3000 / 16:
		x += 16.0
		teleport(x, z)
		await settle(true)
	var slowest := world.terrain.slowest_frame_ms
	print("slowest streaming frame %.2f ms, %d over %.1f ms" % [slowest, _over, _limit])
	check(_over <= 1, "streaming stayed under %.1f ms a frame (%d frames over, slowest %.2f)"
		% [_limit, _over, slowest])


func _process(_delta: float) -> void:
	if world != null and world.terrain.frame_ms > _limit:
		_over += 1
