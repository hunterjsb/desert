extends DeckProbe
## Removing an original joined mount must leave the assembly saveable and detachable.
func run() -> void:
	await load_lines()
	var root := piece(world.player.global_position + Vector3(0, 0, -3))
	var second := piece(root.global_position + Vector3.RIGHT)
	var marker := Catalog.device(&"home_beacon")
	world.content.add_child(marker)
	Stick.put(second, second, Chassis.TOP, Vector2.ZERO, 0.0, marker)
	root.join(second, ring(root, Vector2i.ZERO, Vector2i.RIGHT))
	check(root.dismount(root.seat_of(marker)) == marker, "ordinary removal releases the original mounted device")
	await physics_frames(2)
	check(get_node(^"/root/Saves").save(world), "the assembled camp saves after its custom socket has been freed")
	root.detach(second)
	check(second.deck == null and second.is_inside_tree(), "the same joined piece still separates normally")
	check(get_node(^"/root/Saves").save(world), "the separated original pieces remain saveable")
