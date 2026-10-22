extends LineProbe
## A line tied at your waist pulls from the knot the suit's belt draws, with
## the cord wound round the belt; its end isn't drawn floating there, and it
## shows again once it's back in your hand.

func run() -> void:
	await load_lines()
	var player := world.player
	var stake := driven_stake(player.global_position + Vector3(0, 0, -5))
	var line := Line.to_waist(world, stake.free_tie(player.global_position), 2.0)
	var end := line.ends[1]
	hands.reel.choose(end)
	await physics_frames(4)
	await get_tree().process_frame
	var knot := (player.body.get_node(^"hips") as Node3D).global_transform * SurveyorLooks.WAIST_KNOT
	var tied := Line._tip(end).global_position
	print("waist end %.3f m from the belt knot" % tied.distance_to(knot))
	check(tied.distance_to(knot) < 0.03, "the line pulls from the belt's drawn knot")
	var meshes := end.find_children("*", "MeshInstance3D", false, false)
	check(not meshes.is_empty() and meshes.all(func(m: Node) -> bool: return not (m as MeshInstance3D).visible),
		"its end isn't drawn floating at the waist")
	look(eye(), eye() + Vector3(0, 5, -10))
	check(player.waist.give_back(), "untying takes the end back")
	await simulate(world.tuning.untie_seconds + Hands.ARRIVE + 0.2)
	await get_tree().process_frame
	check(hands.held == end and meshes.all(func(m: Node) -> bool: return is_instance_valid(m) and (m as MeshInstance3D).visible),
		"back in your hand, the end is drawn again")
