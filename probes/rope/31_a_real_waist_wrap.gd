extends LineProbe
## A live waist tie wraps the actual suit; returning it restores the same
## held spare coil without changing the rope or adding physics geometry.

func run() -> void:
	await load_lines()
	var player := world.player
	var stake := driven_stake(player.global_position + Vector3(0, 0, -5))
	var line := Line.to_waist(world, stake.free_tie(player.global_position), 2.0)
	var end := line.ends[1]
	world.ropes.set_physics_process(false)
	line.rope.haul_gathered = 1.0
	hands.reel.choose(end)
	await get_tree().process_frame
	await get_tree().process_frame
	var wrap := player.body.get_node(^"WaistWrap") as WaistWrap
	check(wrap._views.size() == 1 and not hands.reel._coil.visible,
		"a real waist tie has a belt wrap instead of a floating item coil")
	var tips: Array = wrap._tips[end.get_instance_id()]
	check(not tips.is_empty(), "the real tip has a render copy at the waist")
	for pair: Array in tips:
		check(not (pair[0] as MeshInstance3D).visible
			and (pair[1] as MeshInstance3D).mesh == (pair[0] as MeshInstance3D).mesh,
			"the waist tip reuses its original mesh without drawing the physics pose twice")
	var pose := end.global_transform
	var velocity := end.linear_velocity
	var length := line.rope.length
	var full := line.rope.full
	var mass := end.mass
	var a := line.rope.a
	var b := line.rope.b
	for i in 10:
		wrap._process(1.0 / 60.0)
	check(end.global_transform == pose and end.linear_velocity == velocity and end.mass == mass
		and line.rope.length == length and line.rope.full == full and line.rope.a == a and line.rope.b == b
		and wrap.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"rendering the wrap changes no physical endpoint, mass, length or attachment")
	var lead := wrap._views.values()[0][1] as MeshInstance3D
	check(lead.to_global(Vector3.UP).distance_to(world.ropes._shown_end(Line._tip(end))) < 0.001,
		"the visual belt lead reaches the unchanged drawn rope endpoint")
	var mesh := (wrap._views.values()[0][0] as MeshInstance3D).mesh
	check(mesh == SurveyorLooks.waist_wrap(), "waist ties share their cached cord geometry")
	look(eye(), eye() + Vector3(0, 5, -10))
	check(player.waist.give_back(), "the ordinary untie returns the actual end")
	await simulate(world.tuning.untie_seconds + Hands.ARRIVE + 0.2)
	await get_tree().process_frame
	await get_tree().process_frame
	check(hands.held == end and wrap._views.is_empty() and hands.reel._coil.visible,
		"returning that end removes the wrap and restores the existing held coil")
	for pair: Array in tips:
		check(is_instance_valid(pair[0]) and (pair[0] as MeshInstance3D).visible,
			"returning the held end restores its original visible mesh")
	check(world.ropes.ropes.has(line.rope) and line.ends[1] == end and line.rope.length == length
		and line.rope.full == full and hands.reel._coil.mesh == Dress.coil(),
		"the original line and current item coil remain intact")
