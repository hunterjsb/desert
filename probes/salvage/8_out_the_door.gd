extends SalvageProbe
## Salvage & ruins probe 8: out the door. At the ruin "go looking" stands you
## before, you walk on held keys. A crate found on the hall's floor, as heavy
## as anything is ever found and still within your strength to drag, has a
## part taken out of it, is taken hold of and backed out of the front door,
## never slipping from your hands. A crate found in a roofed room has a line
## tied to its hook through your hands, tied at your waist a step off, and is
## dragged into the room's middle and towed out of the back door.

## Out means this far past the outer wall, m.
const OUT := 3.0
## Reached means this near, m, and each leg of a walk may take this long, s.
const NEAR := 0.4
const LEG := 15.0
## You take hold standing this far from a find, m.
const STAND := 1.3
const KEYS := ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "crouch"]

var ruin: Ruin


func run() -> void:
	await load_salvage()
	world.time_warp = 0.0
	ruin = await go_looking()
	world.time_warp = 0.0
	var inside := ruin.to_world(Vector2(-3.0, 0.0))
	await go(inside.x, inside.y)
	await _held_out()
	await _towed_out()


## The heaviest find: a crate with every socket the deep layer fills, its
## batteries flat so its tray can't lift it.
func _held_out() -> void:
	var fill := []
	var sockets: Array = Catalog.DEVICES[&"crate_frame"].sockets
	for i in sockets.size():
		var kinds: Array = Finds.FILLS[Finds.DEEP].get(sockets[i][0], [])
		if not kinds.is_empty():
			fill.append([i, kinds[0], 0.0])
	var crate := await _found(990, Vector2(-5.0, -2.0), fill)
	# The floor is the sand's own body: against a find's friction of 1, it's sand_friction.
	var drag := crate.mass * world.gravity * world.tuning.sand_friction
	var kg := crate.mass
	var door := Vector2(-3.0, 2.0)
	await _stand(crate, door)
	check(await _strip(crate), "a part comes out of the found crate")
	check(await _take_hold(crate), "you take hold of the crate you took from")
	_moving(true)
	var slipped := {"at": INF}
	var watch := func() -> void:
		if hands.grasp.body != crate and slipped.at == INF:
			slipped.at = _plan_of(crate).y
	var walked := await _walk([door, Vector2(-3.0, Ruin.HALF.y + OUT + STAND + 2.0)], true, watch)
	_moving(false)
	var out := _plan_of(crate).y - Ruin.HALF.y
	print("the heaviest find, a crate of %.1f kg (%.0f N to drag, your strength %.0f N), a part taken out,"
		% [kg, drag, world.tuning.hand_strength] + " taken hold of and backed out of the front door: %.1f m out, %s"
		% [out, "held" if slipped.at == INF else "slipped at %.1f m" % (slipped.at - Ruin.HALF.y)])
	check(kg >= _heaviest(), "no find is heavier (%.1f kg)" % _heaviest())
	check(drag < world.tuning.hand_strength, "the heaviest find drags within your strength (%.0f N)" % drag)
	check(walked and out > OUT and slipped.at == INF, "taken hold of, it comes out of the front door (%.1f m out)" % out)
	hands.grasp.let_go()


## A crate in the back room, beside the way to the back door: its line tied
## on through your hands, then at your waist, you drag it into line with the
## door, as you would anything through a doorway, and walk out.
func _towed_out() -> void:
	var crate := await _found(991, Vector2(6.8, -1.4), [[0, &"battery", 0.3], [1, &"hook", 0.0], [2, &"hook", 0.0],
		[4, &"solar_panel", 0.0]])
	await _stand(crate, Vector2(5.0, -1.4))
	var line := Line.make(world, world.tuning.rope_coil_length)
	line.coil.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), _floor(_plan_of(world.player) + Vector2(0.0, -0.5), 0.05))
	await simulate(0.5)
	look(eye(), line.coil.global_transform * middle(line.coil))
	await simulate(1.0 / 60.0)
	check(hands.grab(), "you take up a coil")
	await simulate(0.3)
	var tie := crate.free_tie(world.player.global_position)
	var at := seat(tie)
	look(at.origin + at.basis.z * 0.9 + Vector3.UP * 0.5, at.origin)
	for i in 30:
		await simulate(1.0 / 60.0)
		if tie.part != null:
			break
	if tie.part == null and hands.socket == tie:
		hands.grab()
	await simulate(0.2)
	check(tie.part != null and line.state == Line.State.PAYING, "you tie its first end to the crate's hook")
	_moving(true)
	await _walk([Vector2(5.7, -1.0)], false)
	look(eye(), _floor(Vector2(5.0, -1.0)))
	await simulate(1.0 / 60.0)
	check(hands.interact() and world.player.waist.holds(line.ends[1]), "you tie the line at your waist")
	var walked := await _walk([Vector2(2.6, -1.0), Vector2(5.0, -2.4), Vector2(5.0, -4.0),
		Vector2(5.0, -Ruin.HALF.y - OUT - line.rope.length - 1.0)], false)
	_moving(false)
	var out := -Ruin.HALF.y - _plan_of(crate).y
	print("a found crate of %.1f kg towed out of the back door on a %.1f m line: %.1f m out"
		% [crate.mass, line.rope.length, out])
	check(walked and out > OUT, "towed, it comes out of the back door (%.1f m out)" % out)


## The most any found device weighs, kg: its frame and the heaviest part
## either layer could have filled each socket with.
func _heaviest() -> float:
	var most := 0.0
	for layer: StringName in Finds.LAYER:
		for entry: Array in Finds.DEVICES[layer] + Finds.IN_RUINS[layer].devices:
			var spec: Dictionary = Catalog.DEVICES.get(entry[0], {"mass": 0.0, "sockets": []})
			var kg: float = spec.mass
			for socket: Array in spec.sockets:
				var best := 0.0
				for fills: Dictionary in [Finds.FILLS[Finds.SURFACE], Finds.FILLS[Finds.DEEP], Finds.SURVIVAL_KIT]:
					for id: StringName in fills.get(socket[0], []):
						best = maxf(best, Catalog.PARTS[id].mass)
				kg += best
			most = maxf(most, kg)
	return most


## A crate found lying on the ruin's floor at a plan point, settled, turned
## with the ruin as it lay in the one this was first walked in, a quarter turn
## round: which hook a line ties to is which faces you.
func _found(index: int, p: Vector2, fill: Array) -> Device:
	var at := ruin.to_world(p)
	var spec := {"index": index, "id": &"crate_frame", "device": true, "layer": Finds.DEEP, "x": at.x,
		"z": at.y, "yaw": 0.3 + (ruin.turn - 1) * PI * 0.5, "lean": 0.0, "lean_by": 0.0, "bury": 0.0, "loose": true, "sound": 0.9, "charge": 0.0,
		"floor": ruin.floor_y, "fill": fill}
	var crate := salvage.lay(world.terrain.chunk_at(at.x, at.y), spec) as Device
	await simulate(Salvage.SETTLE_SECONDS)
	return crate


## On the floor beside a find, toward a plan point, looking at it.
func _stand(body: Node3D, toward: Vector2) -> void:
	var p := _plan_of(body)
	look(_floor(p + (toward - p).normalized() * STAND, world.player.camera.position.y), body.global_position)
	await simulate(1.0 / 60.0)


## Takes out the first part of a device your eyes can see the socket of, and
## sets it aside. Whether one came out.
func _strip(device: Device) -> bool:
	var from := eye()
	for part in device.parts():
		look(from, seat(part.socket) * Vector3(0.0, 0.0, 0.05))
		await simulate(1.0 / 60.0)
		hands._look()
		if hands.look_socket != part.socket or not hands.grab():
			continue
		for i in 60:
			await simulate(1.0 / 60.0)
			if hands.phase == Hands.Phase.HELD:
				hands.stow().queue_free()
				look(from, device.global_position)
				await simulate(0.2)
				return true
	return false


## Aims at a device's frame, not a part in it, and takes hold.
func _take_hold(device: Device) -> bool:
	var from := eye()
	for dy in [0.0, -0.1, 0.1, -0.2]:
		for dx in [0.0, 0.15, -0.15, 0.3, -0.3]:
			look(from, device.global_transform * Vector3(dx, dy, 0.0))
			await simulate(1.0 / 60.0)
			hands._look()
			if hands.look_device == device and hands.look_socket == null:
				return hands.grab() and hands.grasp.body == device
	return false


## Walks through plan points on held keys, facing each, or backing toward it
## facing away. Whether you reached them all.
func _walk(points: Array, backing: bool, each := Callable()) -> bool:
	for to: Vector2 in points:
		var reached := false
		for i in roundi(LEG * 60.0):
			var here := _plan_of(world.player)
			if here.distance_to(to) < NEAR:
				reached = true
				break
			var w := ruin.to_world(here - to if backing else to - here) - ruin.to_world(Vector2.ZERO)
			world.player.rotation.y = atan2(-w.x, -w.y)
			_hold(["move_back"] if backing else ["move_forward"])
			await simulate(1.0 / 60.0, each)
		_hold([])
		if not reached:
			printerr("never reached %s, stopped at %s" % [to, _plan_of(world.player)])
			return false
	return true


func _hold(actions: Array) -> void:
	for action: String in KEYS:
		if actions.has(action):
			Input.action_press(action)
		else:
			Input.action_release(action)


## You walk as you really do, or go where the probe puts you.
func _moving(on: bool) -> void:
	var player := world.player
	player.set_physics_process(on)
	player.collision_layer = 1 if on else 0
	player.collision_mask = 1 if on else 0


func _plan_of(body: Node3D) -> Vector2:
	var p := body.global_position
	return ruin.plan(world.world_x(p.x) - ruin.center.x, world.world_z(p.z) - ruin.center.y)


func _floor(p: Vector2, up := 0.0) -> Vector3:
	return on_floor(ruin, p) + Vector3.UP * up
