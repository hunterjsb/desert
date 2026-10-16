extends WorldProbe
## Survival probe 4: a clean new run. The game as it runs: the run starts
## with its kit (Kit, data) on the sand beside you, a light shield, clearly
## weaker than a found one, with its battery half charged, the light solar
## panel cabled into it, and a short coil; no shield of any kind goes in the
## suit's slots. Switched on, the light shield runs the run's first day in its
## own weather, the panel keeping its battery up. Then a run lived
## in: the sealed-water start set down, its shield up, a line between two
## stakes, a ration in your hands, a canister half drunk, the clock days on.
## Then you die, by your own body's tick. A new run starts on a new seed, and
## nothing of the old one is left anywhere, not a device, a part, a line, a
## bubble or a watt-hour. You start at the beginning, fed and watered, with
## only what the kit carries in your slots and the rest of it beside you.

const MAIN := preload("res://game/main.tscn")
const DAYS := 3.0
## How long the kit's shield runs on, in days, and the world's time warp
## while it does.
const KIT_DAYS := 1.0
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
	# The sealed-water start goes down clear of the kit.
	teleport(world.spawn.x, world.spawn.y + 12.0)
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
	lived.append_array(player.suit.slots.filter(func(p: Part) -> bool: return p != null))
	lived.append_array([player, player.suit, world])
	world.time += DAYS * world.tuning.day_minutes * 60.0
	await physics_frames(10)
	var old := world
	var old_seed := world.run_seed
	check(world.ropes.ropes.size() == 1 and player.hands.held == ration and world.weather.shelters().size() == 2,
		"the old run has a line, a ration in hand and its shields")

	# What the new run holds the moment it starts, before its own weather touches it.
	var fresh := {}
	for child in main.get_children():
		if child is Runs:
			child.started.connect(func(next: World) -> void: fresh.merge(_start_of(next)))
	# Dying of thirst, on the next tick.
	for part in player.suit.slots:
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
	var kit_shield: Node = _pieces(fresh_kit)[0] if _pieces(fresh_kit).size() == 3 else null
	check(strays.is_empty() and world.ropes.ropes.is_empty() and bubbles.size() == 1
		and bubbles[0].get_parent() == kit_shield and world.power.stored_wh() <= 100.0 + 1e-6
		and world.power.stored_wh() >= 100.0 * Kit.standard().charge - 1e-6,
		"the new world has nothing in it but you and the kit (%d things, %d lines)" % [strays.size(), world.ropes.ropes.size()])
	print("the new run began with %s" % fresh)
	check(fresh.get("you") == [Vitals.FULL, Vitals.FULL, Vitals.FULL, false, 0.0, 0.0, 0.0, 0.0, 0.0, null, 0]
		and fresh.get("spawn", INF) < 1.0 and fresh.get("time", INF) == 0.0,
		"you start fresh, empty-handed, at the run's beginning")
	check(fresh.get("slots") == ["Water canister 1.00", "Ration 1.00", "-", "-", "-"],
		"your slots hold only what the kit carries")
	_check_kit(fresh_kit, "the run after death")


## You, your slots, where you stand and the clock, as a run begins.
func _start_of(next: World) -> Dictionary:
	var you := next.player
	var vitals := you.vitals
	var slots := []
	for part in you.suit.slots:
		slots.append("-" if part == null else "%s %.2f" % [part.label,
			(part as Supply).amount / (part as Supply).capacity() if part is Supply else -1.0])
	return {
		"you": [vitals.health, vitals.hunger, vitals.thirst, vitals.dead, vitals.drunk, vitals.eaten]
			+ vitals.taken.values() + [you.hands.held, you.waist.tied.size()],
		"slots": slots,
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


## [the shield, the panel, the line] of a kit, or [] if any is missing.
func _pieces(kit: Array) -> Array:
	var found := [null, null, null]
	for node: Node in kit:
		if node is ShieldGenerator:
			found[0] = node
		elif node is Device and (node as Device).stats().solar_w > 0.0:
			found[1] = node
		elif node is Line:
			found[2] = node
	return [] if found.has(null) else found


func _check_kit(kit: Array, run: String) -> void:
	var standard := Kit.standard()
	var pieces := _pieces(kit)
	check(pieces.size() == 3, "%s starts with the light shield, the light panel and a coil beside you" % run)
	if pieces.size() != 3:
		return
	var shield: ShieldGenerator = pieces[0]
	var panel: Device = pieces[1]
	var line: Line = pieces[2]
	var cable: Cable = null
	for node: Node in kit:
		if node is Cable:
			cable = node
	var start := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y))
	var near := [shield, panel, line.coil].all(func(b: Node3D) -> bool:
		return Vector2(b.global_position.x - start.x, b.global_position.z - start.z).length() < 3.5)
	check(near and shield.battery() != null and shield.charge_share() >= standard.charge - 1e-6 and not shield.on
		and panel.carryable and cable != null and cable.joined().has(shield) and cable.joined().has(panel)
		and line.state == Line.State.COILED and line.full == standard.rope_m,
		"%s: the shield's battery %d%% charged, switched off, cabled to a panel you can pick up, and a %d m coil"
			% [run, roundi(standard.charge * 100.0), roundi(standard.rope_m)])
	var base := Catalog.device(&"shield") as ShieldGenerator
	var deep_panel := Catalog.part(&"solar_panel")
	world.content.add_child(base)
	check(shield.size < base.size * 0.7 and shield.shelter.blocks[&"wind"] < 1.0
		and panel.stats().solar_w <= deep_panel.stats.solar_w * 0.5,
		"%s: the kit's shield and panel are clearly weaker than found ones (%.0f m against %.0f m, %d W against %d W)"
			% [run, shield.size, base.size, panel.stats().solar_w, deep_panel.stats.solar_w])
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	var seated := Catalog.device(&"shield")
	world.content.add_child(seated)
	crate.mount(seated, crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"top")[0])
	check(not world.player.suit.fits(shield) and not world.player.suit.fits(base) and not world.player.suit.fits(seated),
		"%s: no shield goes in the suit's slots, the kit's, a found one or one seated on a crate" % run)
	base.free()
	deep_panel.free()
	crate.free()


## Switched on, the kit's shield runs a day of the run's own weather at the
## spawn without going dark, and the light panel keeps it going: its battery
## ends the day no lower than it began.
func _run_the_day(kit: Array) -> void:
	var pieces := _pieces(kit)
	if pieces.size() != 3:
		return
	var shield: ShieldGenerator = pieces[0]
	# The ground took as long to build as the machine took: the day starts at time zero.
	world.respawn(world.spawn.x, world.spawn.y, 0.0, 0.0)
	await physics_frames(2)
	check(shield.interact(world.player), "use switches the kit's shield on")
	var made := world.power.generated_wh
	var used := world.power.used_wh
	var from := shield.battery().charge_wh
	var lowest := INF
	var dark := 0
	var stormy := 0
	var ticks := Engine.physics_ticks_per_second
	var frames := roundi(KIT_DAYS * world.tuning.day_minutes * 60.0 / WARP * ticks)
	world.time_warp = WARP
	for i in frames:
		await get_tree().physics_frame
		lowest = minf(lowest, shield.battery().charge_wh)
		dark += int(not shield.running())
		stormy += int(world.weather.field_storm(shield.global_position) > 0.0)
	world.time_warp = 1.0
	var end := shield.battery().charge_wh
	print("the kit's shield ran %.1f day, %d%% of it under a storm: its battery %.2f to %.2f Wh (lowest %.2f); the panel made %.2f Wh, the shield drew %.2f"
		% [KIT_DAYS, roundi(100.0 * stormy / frames), from, end, lowest, world.power.generated_wh - made,
			world.power.used_wh - used])
	check(dark == 0, "the kit keeps its shield up for a day (%d frames dark)" % dark)
	check(end >= from, "the light panel keeps the light shield going: the day ends no lower than it began (%.2f to %.2f Wh)" % [from, end])
	shield.interact(world.player)
