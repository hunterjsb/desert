extends LineProbe
## Rope & tethering probe 12: last on, first off. Aimed at a hook with a line
## tied to it, take unties the line and leaves the hook; once the hook is bare,
## take has the hook.


func run() -> void:
	await load_lines()
	var planter := floating(&"planter", spot(0.0, 2.0))
	var stake := driven_stake(spot(0.0, 6.0))
	var line := lay(planter, stake, 0.3)
	await simulate(1.0)
	var ring: Socket
	for socket in planter.sockets():
		if socket.kind == &"ring" and socket.part != null and _tied(socket):
			ring = socket
	var hook := ring.part
	# The hook's own body, not the line's end on its tip.
	var at := Vector3.ZERO
	for node in ring.fitted:
		if node is CollisionShape3D:
			at = (node as Node3D).global_position
	var eye_at := at + seat(ring).basis.z * 1.0 + Vector3.UP * 0.6
	look(eye_at, at)
	await simulate(2.0 / 60.0)
	check(hands.look_socket != null and hands.look_socket.part == line.ends[0], "aimed at the hook, take means the line's end")
	check(hands.grab(), "and takes it")
	await simulate(0.4)
	check(hands.held == line.ends[0] and ring.part == hook, "the line comes off, the hook stays on")
	hands.drop()
	await simulate(0.5)
	look(eye_at, at)
	await simulate(2.0 / 60.0)
	check(hands.grab() and ring.part == null, "bare, take has the hook")


## Whether a line is tied to the tie socket this ring's hook added.
func _tied(ring: Socket) -> bool:
	for node in ring.fitted:
		if node is Socket and (node as Socket).part != null:
			return true
	return false
