extends PodProbe
## A lost frame cannot support a surviving wall, which lands as recoverable loose debris.
func run() -> void:
	await load_lines()
	board_ship()
	var made := drop({"frame_survival": 0.0, "outer_survival": 1.0})
	check(state.get("materialized", false) and not made.has(&"frame_a") and not made.has(&"frame_b"), "lost frames are absent")
	if made.is_empty():
		return
	var deck := made[&"floor_a"] as Chassis
	check(deck.pieces().size() == 2 and made[&"floor_b"].deck == deck, "the two guaranteed floor panels remain joined")
	for uid: StringName in PodShell.PANELS:
		var body := made[uid] as Chassis
		check(body.deck == null and body.is_inside_tree(), "surviving %s is physical loose debris" % uid)
		var before := body.get_child_count()
		PodShell.restore_skin(body)
		PodShell.restore_skin(body)
		check(body.get_child_count() == before, "restoring its saved skin is idempotent")
		var box := body.global_transform * body.shape_bounds()
		check(box.position.y >= world.height_under(body.global_position) - 0.001, "debris is placed above sand")
