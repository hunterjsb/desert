extends HandsProbe
## Survival probe 6: the inventory by mouse. A click in the world captures the
## mouse to look; the inventory action opens the view and frees it, and moving
## it lights the thing under it without turning you. Clicked empty-handed, a
## thing comes to your hands; a click anywhere on the view puts what you hold
## in. Like things stack: a second canister joins the first as one, and a
## click on the stack hands you the fuller. Take puts nothing in, and a plug
## doesn't go in. Closing the view captures the mouse, and moving it turns you
## again.


func run() -> void:
	# The view's tiles sit on a screen of a real size.
	get_window().size = Vector2i(1152, 648)
	await load_hands()
	var player := world.player
	var suit := player.suit
	await physics_frames(2)
	var facing := player.rotation.y
	click_at(Vector2(576.0, 324.0))
	check(not Controls.mouse_free and hands.held == null, "a click in the world captures the mouse")

	press(&"inventory")
	await physics_frames(1)
	check(suit.open and Controls.mouse_free, "the inventory action opens the view and frees the mouse")
	point_at(suit.tile_rect(1).get_center())
	check(suit.hover == 1 and player.rotation.y == facing, "the thing under the mouse is lit, and you don't turn")

	var canister := suit.carried[0] as Supply
	click_at(suit.tile_rect(0).get_center())
	await physics_frames(30)
	check(hands.held == canister and hands.phase == Hands.Phase.HELD and not suit.carried.has(canister),
		"clicked empty-handed, a thing comes to your hands")
	click_at(Vector2(576.0, 60.0))
	check(suit.carried.has(canister) and hands.held == null, "a click anywhere on the view puts what you hold in")
	click_at(suit.tile_rect(0).get_center())
	await physics_frames(30)
	point_at(suit.tile_rect(suit.stacks().size()).get_center())
	var on_plus := suit.hover == suit.stacks().size()
	click_at(suit.tile_rect(suit.stacks().size()).get_center())
	check(on_plus and suit.carried.has(canister) and hands.held == null, "the + after the stacks lights under the mouse, and a click there puts it in")

	var fresh := part(&"canister", player.camera.global_transform.translated_local(Vector3(0.0, -0.2, -0.5))) as Supply
	canister.drain(1.5)
	hands.hold(fresh)
	await physics_frames(30)
	click_at(suit.tile_rect(1).get_center())
	await physics_frames(1)
	var water: Array = suit.stacks()[stack_of(fresh)] if stack_of(fresh) != -1 else []
	print("stacks: %s" % ", ".join(suit.stacks().map(_said)))
	check(water.size() == 2 and water.has(canister) and suit.stacks().size() == Kit.of(world).carried.size(),
		"a second canister stacks with the first")
	click_at(suit.tile_rect(stack_of(fresh)).get_center())
	await physics_frames(30)
	check(hands.held == fresh, "a click on the stack hands you the fuller")

	var before := suit.carried.duplicate()
	press(&"hands_grab")
	await physics_frames(2)
	check(suit.carried == before and hands.held == null, "take puts nothing in: it lets go into the world")
	var plug := part(&"plug", player.camera.global_transform.translated_local(Vector3(0.0, -0.2, -0.5)))
	hands.hold(plug)
	await physics_frames(30)
	click_at(Vector2(576.0, 60.0))
	check(suit.carried == before and hands.held == plug, "a plug doesn't go in")

	press(&"inventory")
	check(not suit.open and not Controls.mouse_free, "closing the view captures the mouse")
	point_at(Vector2(700.0, 324.0))
	check(player.rotation.y != facing, "and moving it turns you again")


func _said(stack: Array) -> String:
	return "%s ×%d, %s" % [Suit._name(stack[0]), stack.size(), Suit._brief(stack)]
