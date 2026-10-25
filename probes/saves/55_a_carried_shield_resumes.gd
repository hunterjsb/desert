extends SavesProbe
## Profile & saves probe 55: a carried shield resumes. A personal shield,
## switched on in your suit, runs its battery flat there and goes down, still
## switched on and a little worn, and the run is saved. Resumed, it is carried
## just as it was: switched on, down since the same moment, as worn, silent.


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_world(1234)
	var suit := world.player.suit
	var shield := Catalog.device(&"personal_shield") as ShieldGenerator
	world.content.add_child(shield)
	shield.global_position = world.player.global_position + Vector3.UP
	var cell := fit_part(shield, &"battery") as Battery
	world.player.hands.hold(shield)
	await physics_frames(30)
	check(suit.put_in() and shield.interact(world.player), "a personal shield goes in your suit, switched on")
	await physics_frames(30)
	check(shield.running() and shield.hum.playing, "it runs there, humming")
	cell.charge_wh = 0.0
	shield.durability = 0.8
	await physics_frames(60)
	var since := shield._since
	var worn := shield.durability
	check(shield.on and not shield._up and is_finite(since) and not shield.hum.playing,
		"its battery flat, it's down and silent, still switched on")
	check(saves.save(world), "saved")

	check(await resume(), "resumed")
	var back: Array = world.player.suit.carried.filter(func(b: Node) -> bool: return b is ShieldGenerator)
	check(back.size() == 1, "it's carried")
	if back.is_empty():
		return
	var again: ShieldGenerator = back[0]
	print("resumed: on %s, up %s, down %.2f s (saved %.2f), durability %.3f, hum %s" % [again.on, again._up,
		again._since, since, again.durability, "playing" if again.hum != null and again.hum.playing else "silent"])
	check(again.on and not again._up and again._since >= since and again._since < since + 0.5,
		"switched on, down since the same moment")
	check(absf(again.durability - worn) < 1e-4, "as worn")
	check(again.get_parent() == world.player and not again.hum.playing, "silent in your suit")
