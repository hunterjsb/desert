extends LineProbe
## Rope probe 20: the yank input hauls only the worked line, through the reel.


func run() -> void:
	await load_lines()
	world.counts_deeds = true
	var player := world.player
	var at := player.global_position
	var left := driven_stake(at + Vector3(-3.0, 0.0, -3.0))
	var right := driven_stake(at + Vector3(3.0, 0.0, -3.0))
	var chosen := Line.to_waist(world, left.free_tie(at), 0.4)
	var other := Line.to_waist(world, right.free_tie(at), 0.4)
	await physics_frames(2)
	hands.reel.choose(chosen.ends[1])
	Controls.mouse_free = false
	var before := chosen.rope.length
	var left_be := other.rope.length
	press(&"rope_yank")
	check(hands.reel.rope == chosen.rope and hands.reel._yank_left > 0.0,
		"the yank input starts a stroke on the chosen line")
	var wanted := hands.reel.wanted
	press(&"rope_yank")
	check(hands.reel.wanted == wanted, "repeated input cannot stack yank strokes during recovery")
	await simulate(world.tuning.rope_yank_seconds + 0.1)
	var hauled := before - chosen.rope.length
	print("yank hauled=", hauled, " peak=", hands.reel._yank_n, " deed=", get_node(^"/root/Profile").did(&"quick_haul"))
	check(hauled > 0.0 and hauled <= world.tuning.rope_yank_m + 0.001
		and absf(other.rope.length - left_be) < 0.001,
		"the real selected line shortens by at most one stroke; the other line keeps its length")
	check(get_node(^"/root/Profile").did(&"quick_haul"), "an actual haul against load records Quick Haul")
	var finished := chosen.rope.length
	await simulate(world.tuning.rope_yank_recover_seconds + 0.1)
	check(absf(chosen.rope.length - finished) < 0.001, "a finished yank does not keep hauling")
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	hands.hold(cell)
	press(&"rope_yank")
	check(hands.reel._yank_left == 0.0, "rotating an ordinary held part does not yank a waist line")
