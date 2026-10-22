extends MenuProbe
## An eclipsed arrival explains its free lamp using the actual binding.

func run() -> void:
	# The automatic landing fixture isolates its recovery notice and rebound action.
	Tuning.current().surveyor_preflight["enabled"] = false
	Tuning.current().run_seed = 42
	for phase in [&"orbit", &"ejection", &"descent", &"entry", &"landing"]:
		Tuning.current().surveyor_arrival[String(phase) + "_s"] = 0.12
	InputMap.action_erase_events(&"headlamp")
	var bound := InputEventKey.new()
	bound.physical_keycode = KEY_P
	InputMap.action_add_event(&"headlamp", bound)
	Tuning.current().salvage = false
	main = MAIN.instantiate()
	main.opens_on_menu = true
	add_child(main)
	await main.new_game(false, false, Kit.standard())
	world = main.world()
	await started()
	check(is_zero_approx(world.weather.day.sun_shown(world.time)), "the actual seeded landing occurs during eclipse")
	check(world.player.hands.notice.contains(Controls.key_for(&"headlamp")) and world.player.hands.notice.contains("headlamp"),
		"the recovery notice names the rebound lamp action")
	check(not world.player.headlamp.on, "the lamp stays player controlled")
	press(&"headlamp")
	await physics_frames(20)
	check(world.player.headlamp.on and world.player.headlamp.visible, "the ordinary bound action lights the recovery area")
