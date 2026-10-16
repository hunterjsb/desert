extends HandsProbe
## Survival probe 6: the inventory by mouse. A click in the world captures the
## mouse to look; the inventory action opens the view and frees it, and moving
## it lights the slot under it without turning you. Clicked empty-handed, a
## full slot gives you what's in it; an empty one takes what you hold, and a
## full one swaps with it. Take puts nothing in, and a plug doesn't fit.
## Closing the view captures the mouse, and moving it turns you again.


func run() -> void:
	# The view's slots sit on a screen of a real size.
	get_window().size = Vector2i(1152, 648)
	await load_hands()
	var player := world.player
	var suit := player.suit
	await physics_frames(2)
	var facing := player.rotation.y
	_click_at(Vector2(576.0, 324.0))
	check(not Controls.mouse_free and hands.held == null, "a click in the world captures the mouse")

	_press(&"inventory")
	check(suit.open and Controls.mouse_free, "the inventory action opens the view and frees the mouse")
	_move(suit.slot_rect(2).get_center())
	check(suit.hover == 2 and player.rotation.y == facing, "the slot under the mouse is lit, and you don't turn")

	var canister := suit.slots[0]
	var ration := suit.slots[1]
	_click(suit, 0)
	await physics_frames(30)
	check(hands.held == canister and hands.phase == Hands.Phase.HELD and suit.slots[0] == null,
		"clicked empty-handed, a full slot gives you what's in it")
	_click(suit, 3)
	check(suit.slots[3] == canister and hands.held == null, "an empty slot takes what you hold")
	_click(suit, 1)
	await physics_frames(30)
	_click(suit, 3)
	await physics_frames(30)
	check(suit.slots[3] == ration and hands.held == canister and suit.slots[1] == null,
		"a full slot swaps with what you hold")

	var before := suit.slots.duplicate()
	_press(&"hands_grab")
	await physics_frames(2)
	check(suit.slots == before and hands.held == null, "take puts nothing in: it lets go into the world")
	var plug := part(&"plug", player.camera.global_transform.translated_local(Vector3(0.0, -0.2, -0.5)))
	hands.hold(plug)
	await physics_frames(30)
	_click(suit, 1)
	check(suit.slots[1] == null and hands.held == plug, "a plug doesn't fit")

	_press(&"inventory")
	check(not suit.open and not Controls.mouse_free, "closing the view captures the mouse")
	_move(suit.slot_rect(4).get_center())
	check(player.rotation.y != facing, "and moving it turns you again")


## The key bound to an action, pressed and let go.
func _press(action: StringName) -> void:
	var key: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	key.pressed = true
	get_viewport().push_input(key)
	key = key.duplicate()
	key.pressed = false
	get_viewport().push_input(key)


func _move(to: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.global_position = to
	motion.relative = Vector2(120.0, 0.0)
	get_viewport().push_input(motion)


func _click(suit: Suit, slot: int) -> void:
	_click_at(suit.slot_rect(slot).get_center())


func _click_at(point: Vector2) -> void:
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = point
		click.global_position = point
		get_viewport().push_input(click)
