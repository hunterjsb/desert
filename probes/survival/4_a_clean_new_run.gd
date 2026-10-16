extends WorldProbe
## Survival probe 4: a clean new run. The game as it runs, with a run lived
## in: the sealed-water start set down, its shield up, a line between two
## stakes, a ration in your hands, a canister half drunk, the clock days on.
## Then you die, by your own body's tick. A new run starts on a new seed, and
## nothing of the old one is left anywhere, not a device, a part, a line, a
## bubble or a watt-hour. You start at the beginning, fed and watered, with
## only a fresh suit's kit in your slots.

const MAIN := preload("res://game/run.tscn")
const DAYS := 3.0


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
	check(world.ropes.ropes.size() == 1 and player.hands.held == ration and world.weather.shelters().size() == 1,
		"the old run has a line, a ration in hand and a bubble up")

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
	var strays := world.content.get_children().filter(func(n: Node) -> bool: return n != world.player)
	check(strays.is_empty() and world.ropes.ropes.is_empty() and get_tree().get_nodes_in_group(Shelter.GROUP).is_empty()
		and world.power.stored_wh() == 0.0 and world.power.generated_wh == 0.0,
		"the new world has nothing in it but you (%d things, %d lines)" % [strays.size(), world.ropes.ropes.size()])
	print("the new run began with %s" % fresh)
	check(fresh.get("you") == [Vitals.FULL, Vitals.FULL, Vitals.FULL, false, 0.0, 0.0, 0.0, 0.0, 0.0, null, 0]
		and fresh.get("spawn", INF) < 1.0 and fresh.get("time", INF) == 0.0,
		"you start fresh, empty-handed, at the run's beginning")
	check(fresh.get("slots") == ["Water canister 1.00", "Ration 1.00", "-", "-", "-"],
		"your slots hold only a fresh suit's kit")


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
