extends DeviceProbe
## Devices & mods probe 2: a chassis with parts stuck all over it and a
## planter with every slot filled, thrown, towed through gusts and floated,
## keep every part exactly where it went, because a part stuck or fitted is
## the body: no joints, no bodies of its own left in the world.


func run() -> void:
	await load_world()
	var deck := spawn_device(&"chassis", 4.0, 2.0)
	for id: StringName in [&"hover_tray", &"battery", &"big_battery", &"lamp", &"solar_panel"]:
		fit_part(deck, id)
	var planter := spawn_device(&"planter", -4.0, 2.0)
	for device: Device in [deck, planter]:
		check(_loose_bits(device).is_empty(), "%s: nothing fitted is a body or joint of its own (%s)"
			% [device.label, _loose_bits(device)])
		for part in device.parts():
			check(not part.is_inside_tree(), "%s: a fitted %s has left the physics world" % [device.label, part.label])
	var before := {}
	for device: Device in [deck, planter]:
		for socket in device.sockets():
			for node in socket.fitted:
				before[node] = relative(device, node)
	await physics_frames(30)
	# Thrown, then towed through gusts, while the tray floats it.
	deck.apply_central_impulse(Vector3(80, 120, -40))
	deck.apply_torque_impulse(Vector3(20, 35, -15))
	planter.apply_central_impulse(Vector3(-60, 90, 30))
	var worst := 0.0
	for i in 600:
		for device: Device in [deck, planter]:
			device.apply_central_force(Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1)) * device.mass * 15.0)
		await get_tree().physics_frame
		for node: Node3D in before:
			var device := node.get_parent() as Node3D
			var now := relative(device, node)
			worst = maxf(worst, now.origin.distance_to(before[node].origin))
			worst = maxf(worst, (now.basis * before[node].basis.inverse()).get_rotation_quaternion().get_angle())
	check(worst < 1e-4, "fitted parts never moved relative to their device (worst %.6f)" % worst)
	check(deck.stats()["hovering"] and planter.stats()["hovering"], "both floated throughout")


## Any physics body or joint living inside a device besides the device itself.
func _loose_bits(device: Device) -> Array:
	var found := []
	for node in device.find_children("*", "", true, false):
		if node is PhysicsBody3D or node is Joint3D:
			found.append(node.name)
	return found
