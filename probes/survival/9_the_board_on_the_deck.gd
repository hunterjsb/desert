extends DeckProbe
## Survival probe 9: the board on the deck. The kit starts with its board
## hung on the wall of its deck's frame, clear of everything else on the
## deck. Ride at it takes it off and steps you on; stepped off and taken up,
## held to the wall it's shown there and take sticks it, its weight on the
## deck's hover load again. On the deck it rides with it towed 40 m, charges
## from the deck's pool until the pool is down to the shield's reserve and
## not a watt-hour past it, then again once the panel brings the pool back.
## Take lifts it off. Saved on the deck, it resumes there, its charge kept.

const AWAY := 40.0
const CROSSWIND := 8.0
const WARP := 120.0
## The most the charging may take, in days.
const DAYS := 3.0

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	blow(Vector2(CROSSWIND, 0.0), 0.2)
	var kit := Runs.kit(world)
	var deck: Chassis = kit.filter(func(n: Node) -> bool: return n is Chassis)[0]
	var shield: ShieldGenerator = kit.filter(func(n: Node) -> bool: return n is ShieldGenerator)[0]
	var stake: Stake = kit.filter(func(n: Node) -> bool: return n is Stake)[0]
	var board: Hoverboard = kit.filter(func(n: Node) -> bool: return n is Hoverboard)[0]
	var walls := deck.joined.filter(func(p: Chassis) -> bool: return p.on_frame())
	check(walls.size() == 1, "the kit's deck has a wall on its frame")
	if walls.is_empty():
		return
	var wall: Chassis = walls[0]
	await simulate(2.0)
	check(shield.interact(world.player), "use switches the deck's shield on")
	var home := deck.seat_of(board).transform
	check(board.host() == deck and deck.own_piece(deck.seat_of(board)) == wall and _off_seat(deck, board, home) < 1e-4,
		"the kit starts with its board hung on the wall")
	var clash := Stick.clear(board, board.global_transform, world.player)
	check(clash == "", "clear of everything else on the deck (%s)" % clash)

	var out := deck.global_basis * wall.pose().basis.y
	var hung_kg := deck.mass
	look(board.global_position + out * 1.2 + Vector3.UP * 0.2, board.global_position)
	await simulate(0.05)
	check(world.player.toggle_board() and world.player.board == board and not board.on_deck()
		and absf(hung_kg - deck.mass - board.mass) < 1e-4,
		"ride at the hung board takes it off, its %.0f kg with it, and steps you on" % board.mass)
	world.player.step_off()
	await simulate(0.5)
	var away := flat(board.global_position - deck.global_position).normalized()
	look(board.global_position + away + Vector3.UP * 1.5, board.global_position)
	await simulate(0.05)
	check(hands.grab() and await _hang(deck, wall, board) and absf(deck.mass - hung_kg) < 1e-4,
		"stepped off and taken up, held to the wall it's shown there, take sticks it, and its weight is back on the deck")
	home = deck.seat_of(board).transform

	var heading := flat(stake.global_position - deck.global_position).normalized()
	var head := stake.global_position + Vector3.UP * 0.3
	look(head - heading * 1.0 + Vector3.UP * 1.2, head)
	await simulate(0.05)
	var taken := hands.grab()
	await simulate(0.5)
	check(taken and hands.held == stake and world.player.waist.take_from_hands(),
		"you take up its stake and tie it at your waist")
	var seen := {"low": INF, "drift": 0.0, "off": 0}
	# To level sand: set down on a dune's face, the camp tips in the crosswind.
	await walk_to(_level(world.player.global_position, heading), func() -> void:
		seen.low = minf(seen.low, clearance(deck))
		seen.drift = maxf(seen.drift, _off_seat(deck, board, home))
		seen.off += int(board.host() != deck))
	await simulate(3.0)
	print("towed %.0f m: the deck %.2f m over the sand at lowest, the board %.6f m off its place at most"
		% [AWAY, seen.low, seen.drift])
	check(seen.low > 0.6 and seen.off == 0 and seen.drift < 1e-3, "on the deck, it rides with it in tow")

	# Camped, the deck set down to rest, as you'd leave it for days: floating
	# still on a slack line, its pool's last charge would drop it mid-swing.
	deck.rest(true)
	await simulate(3.0)
	await _charge(deck, shield, board)

	out = deck.global_basis * wall.pose().basis.y
	look(board.global_position + out * 1.2 + Vector3.UP * 0.2, board.global_position)
	await simulate(0.05)
	check(hands.grab(), "take at the hung board")
	await simulate(0.5)
	check(hands.held == board and not board.on_deck(), "lifts it off the wall into your hands")
	check(await _hang(deck, wall, board), "and it sticks there again")
	home = deck.seat_of(board).transform

	var kept := board.battery().charge_wh
	check(saves.save(world), "saved")
	check(await resume(), "resumed")
	var again: Array = world.devices().filter(func(d: Device) -> bool: return d is Hoverboard)
	var back: Hoverboard = again[0] if again.size() == 1 else null
	check(back != null and back.on_deck() and back.host().seat_of(back).stuck()
		and relative(back.host(), back).origin.distance_to(home.origin) < 1e-4
		and absf(back.battery().charge_wh - kept) < 0.01,
		"resumed, the board is still on its deck with its %.1f Wh" % kept)


## Holding the board, aims at the middle of the wall's outer face, as the
## floating deck moves, until it's shown there clear, then takes. Whether
## it's on the deck.
func _hang(deck: Chassis, wall: Chassis, board: Hoverboard) -> bool:
	if hands.held != board:
		return false
	var shown := false
	for i in 30:
		var at := on_face(deck, wall, Chassis.TOP, Vector2(0.0, 0.12))
		look(at + deck.global_basis * wall.pose().basis.y * 1.2 + Vector3.UP * 0.2, at)
		await simulate(1.0 / 60.0)
		shown = not hands.sticking.is_empty() and hands.sticking.why == "" and hands.sticking.piece == wall
	if shown:
		hands.grab()
	await simulate(0.2)
	return shown and board.host() == deck


## The levellest sand AWAY m from `from`, within 60° either side of `heading`,
## over the span a camp trailing on its line may rest in.
func _level(from: Vector3, heading: Vector3) -> Vector3:
	var best := from + heading * AWAY
	var least := INF
	for k in range(-6, 7):
		var at := from + heading.rotated(Vector3.UP, deg_to_rad(10.0 * k)) * AWAY
		var low := INF
		var high := -INF
		for i in 25:
			var h := world.height_under(at + Vector3((i % 5 - 2) * 4.0, 0.0, (floori(i / 5.0) - 2) * 4.0))
			low = minf(low, h)
			high = maxf(high, h)
		if high - low < least:
			least = high - low
			best = at
	return best


## The deck's loose battery just above the shield's reserve, the board low,
## under the run's own sky: the board charges until the pool is down to the
## reserve, takes nothing past it while the shield runs on, and charges again
## once the panel brings the pool back. Nothing generated goes missing.
func _charge(deck: Chassis, shield: ShieldGenerator, board: Hoverboard) -> void:
	var power := world.power
	var cell := deck.battery()
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
	print("on the deck, the board charged from 20.0 to %.2f Wh; it stopped after %.0f s with the deck at %.2f Wh (reserve %.2f),"
		% [seen.charged, seen.stopped, seen.stopped_at, reserve]
		+ " took %.4f Wh past it, and charged again after %.2f days, at %.2f Wh; ledger off by %.9f Wh of %.2f"
		% [seen.took, seen.again / day, own.charge_wh, generated - went, generated])
	check(seen.charged > own.capacity() * 0.2 + 1.0 and seen.stopped >= 0.0 and absf(seen.stopped_at - reserve) < 0.1,
		"on the deck, it charges from its pool until the pool is down to the shield's reserve")
	check(seen.took == 0.0 and seen.dark == 0, "it takes nothing past the reserve, and the shield keeps running")
	check(seen.again > seen.stopped, "the panel brings the pool back and it charges again")
	check(absf(generated - went) < 1e-6 * maxf(generated, 1.0), "every watt-hour it took was stored, not lost")


## How far a stuck board is off its place, m, past the tick a frozen body
## may ride behind its moving host, whichever the engine brings up to date
## last (Device's own note).
func _off_seat(deck: Device, board: Device, home: Transform3D) -> float:
	var tick := (deck.linear_velocity.length() + deck.angular_velocity.length() * home.origin.length()) \
		/ Engine.physics_ticks_per_second
	return maxf(relative(deck, board).origin.distance_to(home.origin) - tick, 0.0)
