extends HandsProbe
## Devices probe 15: the ghost in sight. A planter on the sand has its back
## ring hooked and its front one, the far side, free. Standing by it with a
## hook in hand, that ring is offered, but its ghost doesn't show through the
## planter; walk round, and it does. A tray offered its tray mount still shows
## its ghost under the planter.


func run() -> void:
	await load_hands()
	var planter := device(&"planter", spot(0.0, -4.0), 0.19)
	var far: Socket = null
	for socket in planter.sockets():
		if socket.kind != &"ring":
			continue
		if socket.position.z < -0.2:
			far = socket
		else:
			var hook := Catalog.part(&"hook")
			world.content.add_child(hook)
			planter.fit(hook, socket)
	await simulate(1.0)
	await _hold(&"hook")
	_stand_by(planter, 1.0)
	await simulate(0.6)
	check(hands.socket == far and hands.pull > 0.0 and not hands._ghost.visible,
		"from the near side, the far ring is offered with no ghost through the planter")
	_stand_by(planter, -1.0)
	await simulate(0.6)
	check(hands.socket == far and hands._ghost.visible, "from its own side, its ghost shows")
	hands.drop()
	await _hold(&"hover_tray")
	_stand_by(planter, 1.0)
	await simulate(0.6)
	check(hands.socket != null and hands.socket.kind == &"bottom" and hands._ghost.visible,
		"a tray's ghost shows under the planter")


## A part of the catalog in your hands.
func _hold(id: StringName) -> void:
	var made := part(id, Transform3D(Basis.IDENTITY, eye() + Vector3.UP))
	hands.hold(made)
	await simulate(0.5)


## Standing a step and a half off the planter's back (or front, for -1),
## looking at its top edge there.
func _stand_by(planter: Device, side: float) -> void:
	var foot := planter.global_position + planter.global_basis.z * 1.9 * side
	var eye_at := Vector3(foot.x, world.height_under(foot) + world.player.camera.position.y, foot.z)
	look(eye_at, planter.global_transform * Vector3(0.0, 0.15, 0.3 * side))
