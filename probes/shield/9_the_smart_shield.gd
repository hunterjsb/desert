extends WeatherProbe
## Bubble shield & camp probe 9: the smart shield. A Console with a radar
## stands on a deck beside a shield, switched off, with a storm on its way.
## While the radar's front is farther than the smart shield's distance the
## shield stays off; once it's within it, the shield switches itself on and
## the screen logs it. A shield off on its own plate nearby, not on the deck,
## stays off. Switched off from the screen's power page, it stays off while
## the front holds near; switched on there, it's on.

## How fast the clock runs meanwhile.
const WARP := 10.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var rig := Scenarios.rig_at(world, [[&"piece", Vector2i(1, 0)],
		[&"stick", Vector2i.ZERO, &"top", Vector2.ZERO, 180.0, [&"console", [&"screen", &"radar"]], &"console"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(-0.2, 0.2), 0.0, &"shield", &"shield"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(0.25, -0.25), 0.0, &"big_battery"]], [0.0, 2.5], false)
	var made: Console = rig.named.console
	var shield: ShieldGenerator = rig.named.shield
	var apart: ShieldGenerator = Scenarios.plate(world, [&"shield", &"battery"], [-3.0, 2.5])[1]
	var x := world.world_x(made.global_position.x)
	var z := world.world_z(made.global_position.z)
	var near := Tuning.current().smart_shield_auto_m
	world.time = find_time(func(t: float) -> bool:
		if field.raw_storm_at(x, z, t) > -0.02:
			return false
		var due := field.next_change(x, z, t, 600.0, 5.0)
		return due > 240.0 and due < 480.0 and _nearest(x, z, t) > near + 500.0)
	await physics_frames(60)
	check(not shield.on and made.smart_shields().size() == 1 and made.smart_shields()[0] == shield, "the deck's shield is smart, and off")

	world.time_warp = WARP
	var on_at := INF
	var waited := 0
	while not shield.on and waited < 60 * 120:
		var front: Dictionary = made.readings.get("front", {})
		on_at = front.get("d", INF)
		waited += 1
		await get_tree().physics_frame
	print("switched on with the front %.0f m off" % on_at)
	check(shield.on and on_at <= near + 20.0 * WARP, "it switches itself on as the front comes within %d m (%.0f m)" % [near, on_at])
	check(on_at > near * 0.5, "not long after (%.0f m)" % on_at)
	check("SHIELD AUTO-ON" in made.screen_text(Console.Page.LOG), "the screen logs it")
	check(not apart.on, "a shield off the deck stays off")

	made.page = Console.Page.POWER
	_press(made, shield, &"off")
	world.time_warp = 1.0
	await physics_frames(120)
	check(not shield.on and "SHIELD OFF" in made.screen_text(Console.Page.LOG),
		"switched off from the screen, it stays off")
	_press(made, shield, &"on")
	await physics_frames(10)
	check(shield.on, "and on again")


## Presses the power page's switch that works a device toward a state, where it's drawn.
func _press(made: Console, device: Device, to: StringName) -> void:
	for key: Dictionary in made.keys():
		if key.device == device and key.to is StringName and key.to == to:
			made.press((key.box as Rect2).get_center() / Vector2(Console.PIXELS))
			return
	check(false, "a switch for %s" % to)


## The nearest stormy ground to a place, on the radar's own bearings, m.
func _nearest(x: float, z: float, t: float) -> float:
	var best := INF
	for i in 36:
		var along := Vector2(sin(TAU * i / 36.0), -cos(TAU * i / 36.0))
		best = minf(best, Console.edge(field, x, z, t, along, 6000.0, 100.0))
	return best
