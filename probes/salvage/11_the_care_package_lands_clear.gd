extends HandsProbe
## Salvage probe 11: the care package never comes down inside something, and
## brings loot that is the drop's own. A spot taken by a structure when the
## cannon fires is passed over for a clear one; a structure that stands under
## the fall by the time it lands is landed on, not into. The same drop fired
## again holds the same loot, laid in its sockets.
## Time limit: 120 s


func run() -> void:
	await load_hands()
	var t := world.time
	var first := Airdrop.fire(world, world.player.global_position)
	var spot := first.global_position
	var held := _loot(first.cargo)
	first.cargo.free()
	first.free()
	var hut := _block(spot, 1.0)
	await physics_frames(2)
	world.time = t
	var drop := Airdrop.fire(world, world.player.global_position)
	var flat := Vector2(drop.global_position.x - spot.x, drop.global_position.z - spot.z)
	check(flat.length() > 1.5, "a spot a structure stands on is passed over for another (%.1f m away)" % flat.length())
	print("loot: %s" % [held])
	check(held.size() >= Airdrop.LEAST and _loot(drop.cargo) == held,
		"it holds loot, and the same drop holds the same")

	# A structure moves in under the fall while it's on its way down.
	hut.free()
	var top := drop.global_position.y + 1.0
	_block(drop.global_position, 1.0)
	await physics_frames(2)
	var cargo := drop.cargo
	world.time = drop.lands_at + 0.05
	for i in 60:
		await get_tree().process_frame
		if drop.landed:
			break
	var lowest := INF
	for child in cargo.get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null and not shape.has_meta(&"socket"):
			var box := Catalog.bounds(shape.shape)
			for i in 8:
				lowest = minf(lowest, (cargo.global_transform * shape.transform * box.get_endpoint(i)).y)
	print("landed lowest corner %.2f m against the structure's top %.2f m" % [lowest, top])
	check(drop.landed and lowest > top - 0.02, "it lands on what stands there, not inside it")


## What a container holds, socket by socket.
func _loot(cargo: Device) -> Array[StringName]:
	var out: Array[StringName] = []
	for socket in cargo.frame_sockets():
		if socket.part != null:
			out.append(socket.part.get_meta(&"catalog"))
	return out


## A solid block over the sand at a place, `tall` m high.
func _block(at: Vector3, tall: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(2.5, tall, 2.5)
	body.add_child(shape)
	world.content.add_child(body)
	body.global_position = at + Vector3.UP * tall * 0.5
	return body
