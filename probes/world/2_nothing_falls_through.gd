extends WorldProbe
## World & terrain probe 2: boxes dropped at random points in collision range all
## come to rest on the sand.


func run() -> void:
	await load_world()
	var tuning := Tuning.current()
	var reach := float(tuning.near_radius * tuning.chunk_size) - 1.0
	var px := world.player_world_x()
	var pz := world.player_world_z()
	var boxes: Array[RigidBody3D] = []
	for i in 100:
		boxes.append(drop_box(px + randf_range(-reach, reach) * 0.9, pz + randf_range(-reach, reach) * 0.9))
	await physics_frames(240)
	var below := 0
	var floating := 0
	var moving := 0
	for box in boxes:
		var c := clearance(box)
		if c < 0.1:
			below += 1
		elif c > 0.6:
			floating += 1
		if box.linear_velocity.length() > 0.05:
			moving += 1
	check(below == 0, "no box sank into the sand (%d did)" % below)
	check(floating == 0, "no box floats above it (%d did)" % floating)
	check(moving == 0, "every box came to rest (%d still moving)" % moving)
