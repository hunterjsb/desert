extends WorldProbe
## Survival probe 4: a clean new run. The game as it runs: the run starts
## with its kit (Kit, data) beside you: a crate floating on its hover tray,
## its battery half charged, the light shield and the light solar panel
## seated on its two top mounts clear of each other, moored by its hook to a
## driven stake on the kit's short line, and a hoverboard racked on it ready
## to ride; none of it overlaps you or each other, and none of it goes in
## with what you carry while it's seated on the crate, nor the crate, too
## heavy to carry; a loose shield generator does.
## The light shield is clearly weaker than a found one. Switched on, it runs
## the run's first day and into the next morning in its own weather on the
## crate's power without going dark: the crate floats until the battery is
## down to its last quarter, then settles and leaves it to the shield. Then a
## run lived in: the sealed-water start set down, its shield up, a line
## between two stakes, a ration in your hands, a canister half drunk, the
## clock days on.
## Then you die, by your own body's tick. A new run starts on a new seed, and
## nothing of the old one is left anywhere, not a device, a part, a line, a
## bubble or a watt-hour. You start at the beginning, fed and watered, with
## only what the kit carries on you and the rest of it beside you.

const MAIN := preload("res://game/run.tscn")
const DAYS := 3.0
## How long the kit's shield runs on, in days, and the world's time warp
## while it does: past the first day, to when its tray gives way.
const KIT_DAYS := 1.25
const WARP := 60.0


func run() -> void:
	Tuning.current().run_seed = 1234
	# Nothing found lies in the old run to count among what it left.
	Tuning.current().salvage = false
	var main := MAIN.instantiate()
	add_child(main)
	world = _world_in(main)
	await settle(true)
	var player := world.player
	var lived: Array = []
	var kit := await _kit_in(world)
	_check_kit(kit, "the first run")
	await _run_the_day(kit)
	lived.append_array(kit)
	# The sealed-water start goes down clear of the kit, well behind you.
	var behind := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y)) + player.global_basis.z * 20.0
	teleport(world.world_x(behind.x), world.world_z(behind.z))
	await physics_frames(5)
	lived.append_array(Scenarios.survive(world))
	await physics_frames(30)
	for body: Node in lived:
		if body is ShieldGenerator:
			check(body.interact(player), "the old run's shield switched on")
	var stakes: Array[Stake] = []
	for right in [-2.0, 2.0]:
		var stake := Catalog.stake()
		world.content.add_child(stake)
		var at := player.global_position + Vector3(right, 0.0, 2.0)
		stake.drive(at, world.height_under(at))
		stakes.append(stake)
	lived.append_array(stakes)
	lived.append(Line.between(world, stakes[0].free_tie(stakes[1].global_position),
		stakes[1].free_tie(stakes[0].global_position)))
	var ration: Part = lived.filter(func(b: Node) -> bool: return b is Supply)[0]
	player.hands.hold(ration)
	(player.suit.supply(&"water") as Supply).drain(1.0)
	lived.append_array(player.suit.carried)
	lived.append_array([player, player.suit, world])
	world.time += DAYS * world.tuning.day_minutes * 60.0
	await physics_frames(10)
	var old := world
	var old_seed := world.run_seed
	check(world.ropes.ropes.size() == 2 and player.hands.held == ration and world.weather.shelters().size() == 2,
		"the old run has its lines, a ration in hand and its shields")

	# What the new run holds the moment it starts, before its own weather touches it.
	var fresh := {}
	for child in main.get_children():
		if child is Runs:
			child.started.connect(func(next: World) -> void: fresh.merge(_start_of(next)))
	# Dying of thirst, on the next tick.
	for part in player.suit.carried:
		if part is Supply and part.kind == &"water":
			part.drain(INF)
	player.vitals.thirst = 0.0
	player.vitals.health = 0.01
	for i in 120:
		await get_tree().physics_frame
		if _world_in(main) != old:
			break
	world = _world_in(main)
	await settle(true)
	check(world != old and not is_instance_valid(old) and world.run_seed != old_seed,
		"dying started a new run on a new seed (%d after %d)" % [world.run_seed, old_seed])
	var left := 0
	for thing in lived:
		left += int(is_instance_valid(thing))
	check(left == 0, "nothing of the old run is left (%d things)" % left)
	var fresh_kit := await _kit_in(world)
	var strays := world.content.get_children().filter(func(n: Node) -> bool:
		return n != world.player and not fresh_kit.has(n))
	var bubbles := get_tree().get_nodes_in_group(Shelter.GROUP)
	var pieces := _pieces(fresh_kit)
	var kit_wh := 0.0
	for node: Node in fresh_kit:
		if node is Device:
			for cell in (node as Device).batteries():
				kit_wh += cell.capacity() * Kit.standard().charge
	check(strays.is_empty() and world.ropes.ropes.size() == 1 and bubbles.size() == 1
		and bubbles[0].get_parent() == pieces.get("shield") and world.power.stored_wh() <= kit_wh + 1e-6
		and world.power.stored_wh() >= kit_wh - 1.0,
		"the new world has nothing in it but you and the kit (%d things, %d lines)" % [strays.size(), world.ropes.ropes.size()])
	print("the new run began with %s" % fresh)
	check(fresh.get("you") == [Vitals.FULL, Vitals.FULL, Vitals.FULL, false, 0.0, 0.0, 0.0, 0.0, 0.0, null, 0]
		and fresh.get("spawn", INF) < 1.0 and fresh.get("time", INF) == 0.0,
		"you start fresh, empty-handed, at the run's beginning")
	check(fresh.get("carried") == ["Water canister 1.00", "Ration 1.00"],
		"you carry only what the kit carries")
	_check_kit(fresh_kit, "the run after death")


## You, what you carry, where you stand and the clock, as a run begins.
func _start_of(next: World) -> Dictionary:
	var you := next.player
	var vitals := you.vitals
	var carried := []
	for part in you.suit.carried:
		carried.append("%s %.2f" % [part.label,
			(part as Supply).amount / (part as Supply).capacity() if part is Supply else -1.0])
	return {
		"you": [vitals.health, vitals.hunger, vitals.thirst, vitals.dead, vitals.drunk, vitals.eaten]
			+ vitals.taken.values() + [you.hands.held, you.waist.tied.size()],
		"carried": carried,
		"spawn": Vector2(next.player_world_x(), next.player_world_z()).distance_to(next.spawn),
		"time": next.time,
	}


## The world the game is running now: a new run brings a new one.
func _world_in(main: Node) -> World:
	for child in main.get_children():
		if child is World and not child.is_queued_for_deletion():
			return child
	return null


## The run's kit once it's down beside where the run began, all it made.
func _kit_in(at: World) -> Array:
	for i in 600:
		if at.has_meta(&"kit"):
			return at.get_meta(&"kit")
		await get_tree().physics_frame
	return []


## A kit's crate, shield, panel, board, stake and line by name, or {} if any is missing.
func _pieces(kit: Array) -> Dictionary:
	var found := {}
	for node: Node in kit:
		if node is ShieldGenerator:
			found.shield = node
		elif node is Hoverboard:
			found.board = node
		elif node is Stake:
			found.stake = node
		elif node is Line:
			found.line = node
		elif node is Device and (node as Device).stats().solar_w > 0.0:
			found.panel = node
		elif node is Device and (node as Device).stats().lift_kg > 0.0:
			found.crate = node
	return found if found.size() == 6 else {}


func _check_kit(kit: Array, run: String) -> void:
	# A clear morning, the first storm minutes off: time to set up, not a storm on arrival.
	var field := world.weather.field
	var hour := world.weather.day.time_of_day(world.time)
	var due := field.next_change(world.spawn.x, world.spawn.y, world.time, 600.0, 10.0)
	check(field.raw_storm_at(world.spawn.x, world.spawn.y, world.time) <= 0.0 and due > 120.0 and due <= 480.0
		and hour >= 0.33 and hour <= 0.46,
		"%s begins on a clear morning (%.2f of the day), the first storm due in %.0f s" % [run, hour, due])
	var standard := Kit.standard()
	var pieces := _pieces(kit)
	check(not pieces.is_empty(), "%s starts with a crate, a light shield, a light panel, a board, a stake and a line" % run)
	if pieces.is_empty():
		return
	var crate: Device = pieces.crate
	var shield: ShieldGenerator = pieces.shield
	var panel: Device = pieces.panel
	var board: Hoverboard = pieces.board
	var stake: Stake = pieces.stake
	var line: Line = pieces.line
	var now := crate.stats()
	check(now.hovering and absf(clearance(crate) - world.tuning.hover_height) < 0.1 and now.hooks == 1
		and crate.charge_share() >= standard.charge - 0.01 and crate.charge_share() <= standard.charge,
		"%s: the crate floats %.2f m up on its tray, a hook fitted, its battery %d%% charged"
			% [run, clearance(crate), roundi(standard.charge * 100.0)])
	check(shield.host() == crate and panel.host() == crate and not shield.on and shield.battery() == null,
		"%s: the light shield, switched off, and the light panel are seated on the crate, on its power" % run)
	check(line.state == Line.State.LAID and absf(line.full - standard.rope_m) < 1e-3 and stake.driven
		and line.ends.any(func(e: Part) -> bool: return e.socket.get_parent() == crate)
		and line.ends.any(func(e: Part) -> bool: return e.socket.get_parent() == stake),
		"%s: the crate is moored by its hook to a driven stake on a %d m line" % [run, roundi(standard.rope_m)])
	check(board.host() == crate and board.racked() and board.battery() != null and board.can_run()
		and board.charge_share() >= standard.charge - 0.01,
		"%s: the hoverboard is racked on the crate, its battery %d%% charged, ready to ride"
			% [run, roundi(standard.charge * 100.0)])
	var start := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y))
	check([crate, board].all(func(b: Node3D) -> bool:
		return Vector2(b.global_position.x - start.x, b.global_position.z - start.z).length() < 3.5),
		"%s: the crate and the board are beside you" % run)
	# Seated side by side, nothing of one inside the other or the crate.
	var tops := [_box_in(crate, shield), _box_in(crate, panel)]
	var racked := _box_in(crate, board)
	var frame := Finds.bounds(crate).grow(-1e-4)
	check(not tops[0].intersects(tops[1]) and tops.all(func(b: AABB) -> bool: return not b.intersects(frame)),
		"%s: the shield and the panel sit clear on the two top mounts (%.3f m apart)"
			% [run, maxf(tops[1].position.z - tops[0].end.z, tops[0].position.z - tops[1].end.z)])
	check(not racked.intersects(frame) and tops.all(func(b: AABB) -> bool: return not b.intersects(racked)),
		"%s: the board sits clear of the crate, its shield and its panel in the rack" % run)
	var bodies: Array[AABB] = [_box_in(null, world.player), _box_in(null, crate), _box_in(null, shield),
		_box_in(null, panel), _box_in(null, board), _box_in(null, stake)]
	var clashes := 0
	for i in bodies.size():
		for j in range(i + 1, bodies.size()):
			# What's seated touches its crate by design.
			if i >= 1 and i <= 4 and j <= 4:
				continue
			clashes += int(bodies[i].intersects(bodies[j]))
	check(clashes == 0, "%s: none of the kit overlaps you or anything else of it (%d)" % [run, clashes])
	var base := Catalog.device(&"shield") as ShieldGenerator
	var deep_panel := Catalog.part(&"solar_panel")
	world.content.add_child(base)
	check(shield.size < base.size * 0.7 and shield.shelter.blocks[&"wind"] < 1.0
		and panel.stats().solar_w <= deep_panel.stats.solar_w * 0.5,
		"%s: the kit's shield and panel are clearly weaker than found ones (%.0f m against %.0f m, %d W against %d W)"
			% [run, shield.size, base.size, panel.stats().solar_w, deep_panel.stats.solar_w])
	var suit := world.player.suit
	check([crate, board, shield, panel].all(func(b: Object) -> bool: return not suit.fits(b)) and suit.fits(base),
		"%s: nothing of the kit goes in with what you carry while it's on the crate, nor the crate; a loose shield does"
			% run)
	base.free()
	deep_panel.free()


## A body's shapes' bounds, in another's frame, or in the world's given null.
func _box_in(frame: Node3D, body: Node3D) -> AABB:
	var to := body.global_transform if frame == null else frame.global_transform.affine_inverse() * body.global_transform
	return (to * Finds.bounds(body)).grow(-1e-4)


## Switched on, the kit's shield runs a day of the run's own weather from its
## start without going dark, on the crate's battery and the light panel: the
## crate floats while the battery holds more than its reserve, then settles
## onto the sand and leaves the rest to the shield.
func _run_the_day(kit: Array) -> void:
	var pieces := _pieces(kit)
	if pieces.is_empty():
		return
	var crate: Device = pieces.crate
	var shield: ShieldGenerator = pieces.shield
	var cell := crate.battery()
	# The run's own moment, with the kit as it was laid: the ground took as
	# long to build as the machine took.
	var begin: Dictionary = Scenarios.find(world, Runs.START)
	world.respawn(world.spawn.x, world.spawn.y, world.player.global_rotation.y, begin.time)
	cell.charge_wh = cell.capacity() * Kit.standard().charge
	# The day is the kit's: nothing of yours ends it.
	world.player.vitals.set_physics_process(false)
	await physics_frames(2)
	check(shield.interact(world.player), "use switches the kit's shield on")
	var made := world.power.generated_wh
	var from := cell.charge_wh
	var lowest := INF
	var floating_low := INF
	var dark := 0
	var stormy := 0
	var floated := 0
	var settled := -1.0
	var storm_at := -1.0
	var shield_wh := 0.0
	var ticks := Engine.physics_ticks_per_second
	var frames := roundi(KIT_DAYS * world.tuning.day_minutes * 60.0 / WARP * ticks)
	var step := WARP / ticks / 3600.0
	world.time_warp = WARP
	for i in frames:
		await get_tree().physics_frame
		lowest = minf(lowest, cell.charge_wh)
		dark += int(not shield.running())
		var storm := world.weather.field_storm(shield.global_position) > 0.0
		stormy += int(storm)
		if storm and storm_at < 0.0:
			storm_at = float(i) / frames
		shield_wh += shield.demand_w() * step * int(shield.running())
		if crate.powered:
			floated += 1
			floating_low = minf(floating_low, cell.charge_wh)
		elif settled < 0.0:
			settled = float(i) / frames
	world.time_warp = 1.0
	world.player.vitals.set_physics_process(true)
	var end := cell.charge_wh
	var reserve := Power.RESERVE * cell.capacity()
	print(("the kit's first %.2f days, %d%% of it under a storm from %.2f days: the crate floated %d%% of it%s; its battery %.1f to %.1f Wh"
		+ " (lowest %.1f, floating %.1f); the panel made %.1f Wh, the shield drew %.1f")
		% [KIT_DAYS, roundi(100.0 * stormy / frames), storm_at * KIT_DAYS, roundi(100.0 * floated / frames),
			", settling at %.2f days" % (settled * KIT_DAYS) if settled >= 0.0 else "", from, end, lowest, floating_low,
			world.power.generated_wh - made, shield_wh])
	check(dark == 0, "the kit keeps its shield up all day (%d frames dark)" % dark)
	check(settled >= 0.0 and floating_low >= reserve - 0.1 and lowest < reserve,
		"the tray gives way at the shield's reserve (floating down to %.2f Wh) and the shield runs on" % floating_low)
	shield.interact(world.player)
