extends HandsProbe
## Devices probe 15: the ghost in sight. A crate on the sand has every ring
## hooked but the one on its far side. Standing by it with a hook in hand,
## that ring is offered, but its ghost doesn't show through the crate; walk
## round, and it does. A tray offered the bottom mount still shows its ghost
## under the crate.


func run() -> void:
	await load_hands()
	var crate := device(&"crate_frame", spot(0.0, -4.0), 0.27)
	var far: Socket = null
	for socket in crate.sockets():
		if socket.kind != &"ring":
			continue
		if socket.position.x < -0.3:
			far = socket
		else:
			var hook := Catalog.part(&"hook")
			world.content.add_child(hook)
			crate.fit(hook, socket)
	await simulate(1.0)
	await _hold(&"hook")
	_stand_by(crate, 1.0)
	await simulate(0.6)
	check(hands.socket == far and hands.pull > 0.0 and not hands._ghost.visible,
		"from the near side, the far ring is offered with no ghost through the crate")
	_stand_by(crate, -1.0)
	await simulate(0.6)
	check(hands.socket == far and hands._ghost.visible, "from its own side, its ghost shows")
	hands.drop()
	await _hold(&"hover_tray")
	_stand_by(crate, 1.0)
	await simulate(0.6)
	check(hands.socket != null and hands.socket.kind == &"bottom" and hands._ghost.visible,
		"a tray's ghost shows under the crate")


## A part of the catalog in your hands.
func _hold(id: StringName) -> void:
	var made := part(id, Transform3D(Basis.IDENTITY, eye() + Vector3.UP))
	hands.hold(made)
	await simulate(0.5)


## Standing a step and a half off the crate's right side (or left, for -1),
## looking at its top edge there.
func _stand_by(crate: Device, side: float) -> void:
	var foot := crate.global_position + crate.global_basis.x * 1.9 * side
	var eye_at := Vector3(foot.x, world.height_under(foot) + world.player.camera.position.y, foot.z)
	look(eye_at, crate.global_transform * Vector3(0.3 * side, 0.2, 0.0))
