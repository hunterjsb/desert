extends LineProbe
## Survival probe 9: the board racked. The kit starts with its board racked on
## the crate, clear of everything a fully fitted crate holds. Ride at it takes
## it off and steps you on; stepped off and taken up, aimed at the rack it
## leans in and seats on take, its weight on the crate's hover load. Racked,
## it rides with the crate towed 40 m, charges from the crate's panel until
## the pool is down to the shield's reserve and not a watt-hour past it, then
## again once the panel brings the pool back. Take lifts it off. Saved racked,
## it resumes racked, its charge kept.

const AWAY := 40.0
const CROSSWIND := 8.0
const WARP := 120.0
## The most the charging may take, in days.
const DAYS := 3.0
## How close fitted shapes may come before they clash, m.
const SKIN := 0.002

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	blow(Vector2(CROSSWIND, 0.0), 0.2)
	var kit := Runs.kit(world)
	var crate: Device = kit.filter(func(n: Node) -> bool: return n is Device and (n as Device).stats().lift_kg > 0.0)[0]
	var shield: ShieldGenerator = kit.filter(func(n: Node) -> bool: return n is ShieldGenerator)[0]
	var stake: Stake = kit.filter(func(n: Node) -> bool: return n is Stake)[0]
	var board: Hoverboard = kit.filter(func(n: Node) -> bool: return n is Hoverboard)[0]
	var racks := crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"rack")
	check(racks.size() == 1, "the crate frame has a rack")
	if racks.is_empty():
		return
	var rack: Socket = racks[0]
	await simulate(2.0)
	check(shield.interact(world.player), "use switches the crate's shield on")
	var home := rack.transform * board.seat()
	check(board.host() == crate and rack.mounted == board and _off_seat(crate, board, home) < 1e-4,
		"the kit starts with its board racked on the crate, on its seat")
	var clash := _clashes()
	print("on a fully fitted crate the racked board clears everything else by %.1f cm at least, nearest the %s"
		% [clash.gap * 100.0, clash.nearest])
	check(clash.gap > SKIN, "it clashes with nothing else the crate holds, its shield, panel, hooks or their lines")

	var racked_kg := crate.mass
	look(board.global_position + rack.global_basis.z * 1.2 + Vector3.UP * 0.4, board.global_position)
	await simulate(0.05)
	check(world.player.toggle_board() and world.player.board == board and not board.racked()
		and absf(racked_kg - crate.mass - board.mass) < 1e-4,
		"ride at the racked board takes it off, its %.0f kg with it, and steps you on" % board.mass)
	world.player.step_off()
	await simulate(0.5)
	var away := flat(board.global_position - crate.global_position).normalized()
	look(board.global_position + away + Vector3.UP * 1.5, board.global_position)
	await simulate(0.05)
	check(hands.grab() and await _rack(board, rack) and absf(crate.mass - racked_kg) < 1e-4,
		"stepped off and taken up, held at the rack it leans in, take seats it, and its weight is back on the crate")

	var heading := flat(stake.global_position - crate.global_position).normalized()
	var head := stake.global_position + Vector3.UP * 0.3
	look(head - heading * 1.0 + Vector3.UP * 1.2, head)
	await simulate(0.05)
	var taken := hands.grab()
	await simulate(0.5)
	check(taken and hands.held == stake and world.player.waist.take_from_hands(),
		"you take up its stake and tie it at your waist")
	var seen := {"low": INF, "drift": 0.0, "off": 0}
	await walk_to(world.player.global_position + heading * AWAY, func() -> void:
		seen.low = minf(seen.low, clearance(crate))
		seen.drift = maxf(seen.drift, _off_seat(crate, board, home))
		seen.off += int(board.host() != crate))
	await simulate(3.0)
	print("towed %.0f m: the crate %.2f m over the sand at lowest, the board %.6f m off its seat at most"
		% [AWAY, seen.low, seen.drift])
	check(seen.low > 0.8 and seen.off == 0 and seen.drift < 1e-3, "racked, it rides with the crate in tow")

	await _charge(crate, shield, board)

	look(board.global_position + rack.global_basis.z * 1.2 + Vector3.UP * 0.4, board.global_position)
	await simulate(0.05)
	check(hands.grab(), "take at the racked board")
	await simulate(0.5)
	check(hands.held == board and not board.racked() and rack.is_open(), "lifts it off the rack into your hands")
	check(await _rack(board, rack), "and it seats again")

	var kept := board.battery().charge_wh
	check(saves.save(world), "saved")
	check(await resume(), "resumed")
	var again: Array = world.devices().filter(func(d: Device) -> bool: return d is Hoverboard)
	var back: Hoverboard = again[0] if again.size() == 1 else null
	check(back != null and back.racked() and back.host().seat_of(back).kind == &"rack"
		and relative(back.host(), back).origin.distance_to(home.origin) < 1e-4
		and absf(back.battery().charge_wh - kept) < 0.01,
		"resumed, the board is still racked on its crate with its %.1f Wh" % kept)


## Holding the board, looks away, then at the rack's seat from its open side
## until the tug leans it in, then takes it home. Whether it's racked.
func _rack(board: Hoverboard, rack: Socket) -> bool:
	if hands.held != board:
		return false
	# A socket just emptied tugs again only once you've looked away from it.
	look(eye(), eye() + Vector3.UP)
	await simulate(0.1)
	var leaned := false
	for i in 30:
		# The crate floats on its line, so you look again as it moves.
		var at := seat(rack) * board.seat()
		look(at.origin + seat(rack).basis.z * 1.2 + Vector3.UP * 0.4, at.origin)
		await simulate(1.0 / 60.0)
		leaned = hands.socket == rack and rack.is_open()
	if leaned:
		hands.grab()
	await simulate(0.2)
	return leaned and rack.mounted == board


## The kit crate's battery just above the shield's reserve, the board low,
## under the run's own sky: the board charges until the pool is down to the
## reserve, takes nothing past it while the shield runs on, and charges again
## once the panel brings the pool back. Nothing generated goes missing.
func _charge(crate: Device, shield: ShieldGenerator, board: Hoverboard) -> void:
	var power := world.power
	var cell := crate.battery()
	var own := board.battery()
	var reserve := Power.RESERVE * cell.capacity()
	cell.charge_wh = reserve + 10.0
	own.charge_wh = own.capacity() * 0.2
	var ledger: Array[float] = [power.generated_wh, power.used_wh, power.spilled_wh, power.stored_wh()]
	var seen := {"stopped": -1.0, "stopped_at": 0.0, "charged": 0.0, "again": -1.0, "took": 0.0, "dark": 0}
	var start := world.time
	var was := own.charge_wh
	world.time_warp = WARP
	for i in roundi(DAYS * world.tuning.day_minutes * 60.0 / WARP * 60.0):
		var share := cell.charge_wh / cell.capacity()
		await get_tree().physics_frame
		seen.dark += int(not shield.running())
		var gained := own.charge_wh - was
		was = own.charge_wh
		if share <= Power.RESERVE:
			seen.took += maxf(gained, 0.0)
		if seen.stopped < 0.0 and not board.powered:
			seen.stopped = world.time - start
			seen.stopped_at = cell.charge_wh
			seen.charged = own.charge_wh
		elif seen.stopped >= 0.0 and own.charge_wh > seen.charged + 1.0:
			seen.again = world.time - start
			break
	world.time_warp = 1.0
	# Days went by, and a dead run isn't saved: the rest starts fed and watered.
	world.player.vitals.fresh()
	var generated := power.generated_wh - ledger[0]
	var went := (power.used_wh - ledger[1]) + (power.spilled_wh - ledger[2]) + (power.stored_wh() - ledger[3])
	var day := world.tuning.day_minutes * 60.0
	print("racked, the board charged from 20.0 to %.2f Wh; it stopped after %.0f s with the crate at %.2f Wh (reserve %.2f),"
		% [seen.charged, seen.stopped, seen.stopped_at, reserve]
		+ " took %.4f Wh past it, and charged again after %.2f days, at %.2f Wh; ledger off by %.9f Wh of %.2f"
		% [seen.took, seen.again / day, own.charge_wh, generated - went, generated])
	check(seen.charged > own.capacity() * 0.2 + 1.0 and seen.stopped >= 0.0 and absf(seen.stopped_at - reserve) < 0.1,
		"racked, it charges from the crate until the pool is down to the shield's reserve")
	check(seen.took == 0.0 and seen.dark == 0, "it takes nothing past the reserve, and the shield keeps running")
	check(seen.again > seen.stopped, "the panel brings the pool back and it charges again")
	check(absf(generated - went) < 1e-6 * maxf(generated, 1.0), "every watt-hour it took was stored, not lost")


## A crate with every socket filled as the kit's is, a line's end on every
## hook, and the board racked: the least gap between the board and anything
## else, m, and what that is. Built off the world, in the crate's own frame.
func _clashes() -> Dictionary:
	var crate := Catalog.device(&"crate_frame")
	var board := Catalog.device(&"board")
	# As its _ready would, off the world.
	crate.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	board.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	var tops: Array[Socket] = []
	for socket in crate.sockets():
		var fill: Variant = {&"battery": &"big_battery", &"ring": &"hook", &"bottom": &"hover_tray", &"port": &"plug"}.get(socket.kind)
		if fill != null:
			crate.fit(Catalog.part(fill), socket)
		elif socket.kind == &"top":
			tops.append(socket)
	for socket in crate.sockets():
		if socket.kind == &"tie":
			crate.fit(Catalog.part(&"rope_end"), socket)
	crate.mount(Catalog.device(&"light_shield"), tops[0])
	crate.mount(Catalog.device(&"light_panel"), tops[1])
	board.fit(Catalog.part(&"battery"), board.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery")[0])
	crate.mount(board, crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"rack")[0])
	var mine := _box(board, board.transform)
	var out := {"gap": INF, "nearest": ""}
	for child in crate.get_children():
		var shape := child as CollisionShape3D
		var name := ""
		var box := AABB()
		if shape != null:
			var socket := crate.socket_of(shape)
			name = (socket.part.label if socket != null else "frame")
			box = shape.transform * Catalog.bounds(shape.shape)
		elif child is Device and child != board:
			name = (child as Device).label
			box = _box(child, (child as Device).transform)
		else:
			continue
		var apart := (box.position - mine.end).max(mine.position - box.end)
		var gap := maxf(apart.x, maxf(apart.y, apart.z))
		if gap < out.gap:
			out = {"gap": gap, "nearest": name}
	crate.free()
	return out


## A device's shapes' bounds, posed in its host's frame.
func _box(device: Node3D, pose: Transform3D) -> AABB:
	var box := AABB()
	var first := true
	for child in device.get_children():
		var shape := child as CollisionShape3D
		if shape != null:
			var each := pose * shape.transform * Catalog.bounds(shape.shape)
			box = each if first else box.merge(each)
			first = false
	return box


## How far a seated board is off its seat, m, past the tick a frozen body
## may ride behind its moving host, whichever the engine brings up to date
## last (Device's own note).
func _off_seat(crate: Device, board: Device, home: Transform3D) -> float:
	var tick := (crate.linear_velocity.length() + crate.angular_velocity.length() * home.origin.length()) \
		/ Engine.physics_ticks_per_second
	return maxf(relative(crate, board).origin.distance_to(home.origin) - tick, 0.0)
