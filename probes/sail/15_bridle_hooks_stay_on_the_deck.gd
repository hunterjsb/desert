extends SailProbe
## Sailing probe 15: the starting kit's sheet ring rests on its actual deck,
## including after riding, reeling and resuming. Compact rigs have no tail
## under the fully hauled boom; a ring projected there would float in space.


func run() -> void:
	await load_sailing()
	world.spawn = Vector2(world.player_world_x(), world.player_world_z())
	var made := Runs.kit(world, Kit.named(&"varran"))
	var board: Device
	for node in made:
		if node is Chassis:
			deck = node
		elif node is Mast:
			mast = node
		elif node is Device and node.get_meta(&"catalog", &"") == &"board":
			board = node
	await physics_frames(10)
	check(_supported(), "the sheet's deck ring rests on a real chassis piece")
	check(world.player.get_on(board), "you ride with the bridle tied")
	await physics_frames(2)
	look(eye(), mast.global_position)
	for body in world.player.waist.tied:
		if Mast.sheet_end(body):
			hands.reel.choose(body)
	check(hands.reel.notch(2), "you haul the sheet")
	await simulate(1.0)
	check(_supported() and _attached(), "riding and hauling leave the ring supported and all three lines attached")
	check(get_node(^"/root/Saves").save(world), "saved while riding")
	check(await resume(), "resumed")
	for node in world.content.get_children():
		if node is Chassis and node.pieces().size() == 4:
			deck = node
	for device in deck.mounted():
		if device is Mast:
			mast = device
	await physics_frames(2)
	check(_supported() and _attached(), "resuming keeps the ring on the deck and all three lines attached")


func _supported() -> bool:
	if not is_instance_valid(mast) or mast.sheet() == null or not is_instance_valid(mast.sheet().through):
		return false
	var guide := mast.sheet().through
	var socket: Socket = guide.get_meta(&"socket", null)
	if socket == null or not socket.part is RopeHook or guide.holder != deck:
		return false
	var at := socket.global_position
	for piece in deck.pieces():
		var local := (deck.global_transform * piece.pose()).affine_inverse() * at
		if absf(local.x) + SheetEye.FOOT.x * 0.5 <= Chassis.WIDTH * 0.5 - Chassis.PANEL_INSET \
				and absf(local.z) + SheetEye.FOOT.y * 0.5 <= Chassis.WIDTH * 0.5 - Chassis.PANEL_INSET \
				and absf(local.y - Chassis.THICK * 0.5 + Chassis.PANEL_DROP) < 0.001:
			var points := mast.sheet().strand.shown()
			for point in points:
				if point.distance_to(guide.global_position) < 0.001:
					return true
	return false


func _attached() -> bool:
	var count := 0
	for body in world.player.waist.tied:
		var rope := ropes.line_at(body)
		if rope == null or not is_instance_valid(rope.a) or not is_instance_valid(rope.b):
			return false
		var far := rope.b if ropes.on_you(rope.a.holder) else rope.a
		if far.holder != deck and far.holder != mast._boom_body:
			return false
		count += 1
	return count == 3
