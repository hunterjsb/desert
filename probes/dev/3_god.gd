extends MenuProbe
## Dev probe 3: the console's god keeps you whole. With it on, you starve and
## parch to nothing and come straight back full; off again, you're as hurt as you are.


func run() -> void:
	await open_main(false)
	await started()
	var console := main.ui.dev_console
	var vitals := world.player.vitals
	console.run("god")
	vitals.thirst = 0.0
	vitals.hunger = 0.0
	vitals.health = 10.0
	await _ticks(3)
	check(vitals.god and vitals.health == Vitals.FULL and vitals.thirst == Vitals.FULL and not vitals.dead,
		"god: parched and starved, you're whole again at once")
	console.run("god")
	vitals.health = 50.0
	await _ticks(3)
	check(not vitals.god and vitals.health < 60.0, "mortal again, hurt stays hurt (%.1f)" % vitals.health)


## A few of the vitals' ticks of world time.
func _ticks(n: int) -> void:
	var until := world.time + world.tuning.power_tick * n
	while world.time < until:
		await get_tree().physics_frame
