extends Probe
## Scratch: is the run's kit still enough to sleep by?
## Time limit: 300 s

const MAIN := preload("res://game/main.tscn")

func run() -> void:
	Tuning.current().run_seed = 1234
	var main: Main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	var world := main.world()
	while not world.has_meta(&"kit"):
		await get_tree().physics_frame
	while main.ui.is_fading():
		await get_tree().process_frame
	print("kit: %s" % [world.get_meta(&"kit")])
	print("carried: %s" % [world.player.suit.carried.map(func(t): return t.get(&"label"))])
	var most := 0.0
	for i in 600:
		await get_tree().physics_frame
		for body in world.sleep._camp():
			most = maxf(most, body.linear_velocity.length())
		if i % 60 == 0:
			print("%.1f s: refusal '%s' storm %s next %.0f most %.2f" % [world.time, world.sleep.refusal(), world.weather.in_storm, world.weather.next_change_time - world.time, most])
			most = 0.0
