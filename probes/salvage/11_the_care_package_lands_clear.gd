extends HandsProbe
## Salvage probe 11: the care package never comes down inside something. A
## spot taken by a structure when the cannon fires is passed over for a clear
## one; a structure that stands under the fall by the time it lands is landed
## on, not into. It brings its supplies.
## Time limit: 120 s


func run() -> void:
	await load_hands()
	var t := world.time
	var first := Airdrop.fire(world, world.player.global_position)
	var spot := first.global_position
	first.cargo.free()
	first.free()
	var hut := _block(spot, 1.0)
	await physics_frames(2)
	world.time = t
	var drop := Airdrop.fire(world, world.player.global_position)
	var flat := Vector2(drop.global_position.x - spot.x, drop.global_position.z - spot.z)
	check(flat.length() > 1.5, "a spot a structure stands on is passed over for another (%.1f m away)" % flat.length())

	# A structure moves in under the fall while it's on its way down.
	hut.free()
	var top := drop.global_position.y + 1.0
	_block(drop.global_position, 1.0)
	await physics_frames(2)
	var cargo := drop.cargo
	var fitted := cargo.frame_sockets().filter(func(s: Socket) -> bool: return s.part != null)
	check(fitted.size() == Airdrop.SUPPLIES.size(), "it brings its supplies (%d)" % fitted.size())
	world.time = drop.lands_at + 0.05
	await physics_frames(3)
	var lowest := INF
	for child in cargo.get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null and not shape.has_meta(&"socket"):
			var box := Catalog.bounds(shape.shape)
			for i in 8:
				lowest = minf(lowest, (cargo.global_transform * shape.transform * box.get_endpoint(i)).y)
	print("landed lowest corner %.2f m against the structure's top %.2f m" % [lowest, top])
	check(drop.landed and lowest > top - 0.02, "it lands on what stands there, not inside it")


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
