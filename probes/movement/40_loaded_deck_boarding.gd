extends SailProbe
## Boarding and ordinary battery touchdown keep a real loaded mixed craft usable.

var cells := {}
var cell: Battery

func run() -> void:
	await load_sailing()
	speed_up(2)
	var yaw := PI / 4.0
	var start := _uneven_start(yaw)
	follow(start)
	await settle()
	deck = piece(start)
	deck.freeze = true
	cells[Vector2i.ZERO] = deck
	for z in 6:
		for x in 6:
			var at := Vector2i(x, z)
			if at == Vector2i.ZERO or x >= 3 and z >= 3:
				continue
			var from := at - Vector2i.RIGHT if x > 0 else at - Vector2i.DOWN
			var next := Catalog.device(&"chassis") as Chassis
			deck.join(next, ring(deck, from, at - from), 0)
			cells[at] = next
	var n := 0
	for at: Vector2i in cells:
		Stick.put(deck, cells[at], Chassis.BOTTOM,
			Vector2(0.2 if n % 2 == 0 else -0.2, 0.15 if n % 3 == 0 else -0.15),
			(n % 4) * PI / 2.0, Catalog.part(&"skates" if n % 3 == 0 else &"hover_tray"))
		n += 1
	cell = Catalog.part(&"big_battery") as Battery
	cell.charge_wh = 5.0
	world.content.add_child(cell)
	Stick.put(deck, cells[Vector2i(1, 3)], Chassis.TOP, Vector2.ZERO, 0.0, cell)
	mast = Rig.make([&"mast", [&"sail"]]) as Mast
	Stick.put(deck, cells[Vector2i(2, 0)], Chassis.TOP, Vector2.ZERO, PI, mast)
	for at: Vector2i in [Vector2i(0, 0), Vector2i(5, 0), Vector2i(2, 5)]:
		var toward := Vector2i.LEFT if at.x == 0 else Vector2i.RIGHT
		deck.fit(Catalog.part(&"hook"), ring(deck, at, toward))
	deck.global_transform = Transform3D(Basis(Vector3.UP, yaw), start + Vector3.UP * 1.5)
	var sheet := Line.between(world, mast._tie(), deck.free_tie(mast.global_position), 0.1)
	mast.rig_sheet(sheet)
	hoist(45.0)
	var west := deck.global_transform * Vector3(-3, 0, 0)
	var east := deck.global_transform * Vector3(8, 0, 0)
	lay(deck, driven_stake(west), 0.5)
	lay(deck, driven_stake(east), 0.5)
	deck.freeze = false
	blow(Vector2(deck.global_basis.x.x, deck.global_basis.x.z) * 4.0)
	await simulate(4.0)
	var range := _ground_span(deck.global_transform)
	print("LOADED_BOARD_SETUP ", JSON.stringify({"pieces":cells.size(),"mass":deck.mass,"ground_span":range,
		"ropes":world.ropes.ropes.size(),"charge":cell.charge_wh,"hovering":deck.hovering(),"sheet_N":mast.sheet_n}))
	check(cells.size() == 27 and range > 0.2 and deck.hovering(), "large offset mixed supports float over real uneven sand")
	await _board("powered")
	await _capture("powered-boarded.png")
	var used := world.power.used_wh
	var charge := cell.charge_wh
	var seen := {"spin":0.0,"tilt":0.0,"speed":0.0,"touch":0.0,"airborne":0,"local_y_min":INF,"local_y_max":-INF}
	var until := world.time + 40.0
	while deck.hovering() and world.time < until:
		await physics_frames(1)
		_watch(seen)
	print("LOADED_BATTERY_TRANSITION ", JSON.stringify({"before":charge,"after":cell.charge_wh,
		"ordinary_used_Wh":world.power.used_wh-used,"hovering":deck.hovering(),"observed":seen}))
	check(not deck.hovering() and cell.charge_wh < charge and world.power.used_wh > used,
		"ordinary device demand actually ends powered lift")
	await simulate(8.0, func() -> void: _watch(seen))
	print("LOADED_AFTER_TOUCHDOWN ", JSON.stringify({"observed":seen,"final_spin":deck.angular_velocity.length(),
		"final_tilt":rad_to_deg(deck.global_basis.y.angle_to(Vector3.UP)),"support_N":deck.glider.pressed_n,
		"local_feet":deck.to_local(world.player.global_position),"floor":world.player.is_on_floor(),"charge":cell.charge_wh}))
	check(world.rescued == 0, "boarding and natural battery touchdown need no missing-ground rescue")
	await _capture("battery-touchdown.png")
	await _board("grounded")
	await _capture("grounded-boarded.png")
	var grounded := {"spin":0.0,"tilt":0.0,"speed":0.0,"touch":0.0,"airborne":0,"local_y_min":INF,"local_y_max":-INF}
	await simulate(8.0, func() -> void: _watch(grounded))
	var feet := deck.to_local(world.player.global_position)
	print("LOADED_GROUNDED_SETTLED ", JSON.stringify({"observed":grounded,"final_spin":deck.angular_velocity.length(),
		"final_tilt":rad_to_deg(deck.global_basis.y.angle_to(Vector3.UP)),"floor":world.player.is_on_floor(),"local_feet":feet}))
	check(world.player.is_on_floor() and absf(feet.y - Chassis.THICK * 0.5) < 0.08,
		"grounded boarding retains the player after ordinary settling")
	await _capture("grounded-settled.png")
	speed_up(1)

func _uneven_start(yaw: float) -> Vector3:
	var best := open
	var error := INF
	for x in range(-180, 181, 12):
		for z in range(-180, 181, 12):
			var at := open + Vector3(x, 0, z)
			var span := _ground_span(Transform3D(Basis(Vector3.UP, yaw), at))
			if absf(span - 0.6) < error:
				error = absf(span - 0.6)
				best = at
	best.y = world.height_under(best)
	return best

func _ground_span(pose: Transform3D) -> float:
	var low := INF
	var high := -INF
	for z in 6:
		for x in 6:
			if x >= 3 and z >= 3:
				continue
			var h := world.height_under(pose * Vector3(x, 0, z))
			low = minf(low, h)
			high = maxf(high, h)
	return high - low

func _board(label: String) -> void:
	var player := world.player
	var approach := deck.global_transform * Vector3(-1.6, 0, 1)
	approach.y = world.height_under(approach) + 0.03
	world.teleport(player, Transform3D(player.global_basis, approach))
	player.velocity = Vector3.ZERO
	player.own = Vector2.ZERO
	var heading := deck.global_basis.x
	player.rotation.y = atan2(-heading.x, -heading.z)
	player.collision_layer = 1
	player.collision_mask = 1
	player.set_physics_process(true)
	await simulate(0.25)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await simulate(0.15)
	Input.action_press("jump")
	var seen := {"vault":false,"spin":0.0,"tilt":0.0}
	await simulate(0.9, func() -> void:
		seen.vault = seen.vault or player.vault.active
		seen.spin = maxf(seen.spin, deck.angular_velocity.length())
		seen.tilt = maxf(seen.tilt, rad_to_deg(deck.global_basis.y.angle_to(Vector3.UP))))
	for action in ["move_forward", "sprint", "jump"]:
		Input.action_release(action)
	var feet := deck.to_local(player.global_position)
	print("LOADED_BOARD ", JSON.stringify({"stage":label,"observed":seen,"local_feet":feet,"floor":player.is_on_floor(),
		"charge":cell.charge_wh,"hovering":deck.hovering(),"runner_N":deck.glider.pressed_n,"sheet_N":mast.sheet_n}))
	check(player.is_on_floor() and absf(feet.y - Chassis.THICK * 0.5) < 0.08,
		"actual sprint/jump input boards the " + label + " mast-and-rope-loaded craft")

func _watch(seen: Dictionary) -> void:
	seen.spin = maxf(seen.spin, deck.angular_velocity.length())
	seen.tilt = maxf(seen.tilt, rad_to_deg(deck.global_basis.y.angle_to(Vector3.UP)))
	seen.speed = maxf(seen.speed, deck.linear_velocity.length())
	seen.touch = maxf(seen.touch, deck.glider.pressed_n)
	seen.airborne += int(not world.player.is_on_floor())
	var y := deck.to_local(world.player.global_position).y
	seen.local_y_min = minf(seen.local_y_min, y)
	seen.local_y_max = maxf(seen.local_y_max, y)

func _capture(_name: String) -> void:
	pass
