extends MenuProbe
## Profile & saves probe 8: a Normal run saves itself. Saved by hand, then
## left to play, no save lands until the autosave period is up, and one does
## just after it, a period of play later on the run's clock. Dead, the run
## never saves itself; nor does an Ironman run, nor a dev scenario's.

## Shorter than the game's, so the probe needn't play for minutes.
const PERIOD_MINUTES := 0.25


func run() -> void:
	Tuning.current().autosave_minutes = PERIOD_MINUTES
	await open_main(false)
	# At time zero, however long the ground took to build.
	await started()
	world.respawn(world.spawn.x, world.spawn.y, 0.0, 0.0)
	var period := roundi(PERIOD_MINUTES * 60.0 * Engine.physics_ticks_per_second)
	check(main.save_run(), "saved by hand")
	var by_hand := _saved_at()
	await _play(period - 10)
	check(_saved_at() == by_hand, "nothing saves before the period is up")
	await _play(20)
	var auto := _saved_at()
	print("saved by hand at %.2f s on the run's clock, by itself at %.2f s" % [by_hand, auto])
	check(absf(auto - by_hand - PERIOD_MINUTES * 60.0) < 0.5 and not main.ironman(),
		"a Normal run saves itself a period of play after the last save")

	# Dead, with the death screen up.
	var player := world.player
	for part in player.suit.slots:
		if part is Supply and part.kind == &"water":
			part.drain(INF)
	player.vitals.thirst = 0.0
	player.vitals.health = 0.01
	await _play(period * 2)
	check(player.vitals.dead and main.ui.is_open() and _saved_at() == auto, "dead, the run never saves itself")

	main.new_game(true)
	await faded_in()
	await _play(period * 2)
	check(main.ironman() and not saves().has_run(), "an Ironman run never saves itself")

	main.new_game(false)
	await faded_in()
	main.set(&"_scenario", true)
	await _play(period * 2)
	check(not saves().has_run() and not main.save_run(), "a dev scenario's run never saves, by itself or by hand")


## Ticks of play, ten to a frame: each tick as long as ever, so the autosave
## counts them as it would at real speed.
func _play(ticks: int) -> void:
	var rate := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = rate * 10
	Engine.time_scale = 10
	Engine.max_physics_steps_per_frame = 14
	await physics_frames(ticks)
	Engine.physics_ticks_per_second = rate
	Engine.time_scale = 1.0
	Engine.max_physics_steps_per_frame = 8


## The run's clock in the save on disk, once any save being written has
## landed; -1 with none.
func _saved_at() -> float:
	if not saves().has_run():
		return -1.0
	return SaveFile.read(saves().path(), saves().KIND, saves().VERSION).data.time
