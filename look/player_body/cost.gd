extends HandsProbe
## What your suit costs to draw: paired GPU frame times with it drawn and
## not, in your own view looking down and from a little way off (its shadow
## counts in both), alternating so drift in the machine cancels.
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/player_body/cost.tscn

const ROUNDS := 9
const FRAMES := 60


func run() -> void:
	await load_hands()
	Dev.hide_overlays()
	var player := world.player
	player.set_physics_process(false)
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var outside := Camera3D.new()
	world.add_child(outside)
	outside.global_position = player.global_position + Vector3(2.5, 1.6, -2.5)
	outside.look_at(player.global_position + Vector3.UP, Vector3.UP)
	for view: String in ["your eyes, looking down", "outside"]:
		if view == "outside":
			outside.make_current()
		else:
			player.camera.rotation_degrees.x = -60.0
		var differences: Array[float] = []
		for pass_index in ROUNDS:
			var with := 0.0
			var without := 0.0
			for drawn in [true, false]:
				player.body.set_process(drawn)
				player.body.visible = drawn
				for i in 10:
					await RenderingServer.frame_post_draw
				var sum := 0.0
				for i in FRAMES:
					await RenderingServer.frame_post_draw
					sum += RenderingServer.viewport_get_measured_render_time_gpu(rid)
				if drawn:
					with = sum / FRAMES
				else:
					without = sum / FRAMES
			differences.append(with - without)
		differences.sort()
		print("BODY_COST %s: median %.3f ms (range %.3f to %.3f)" % [view, differences[ROUNDS / 2],
			differences[0], differences[-1]])
	player.body.set_process(true)
	player.body.visible = true
