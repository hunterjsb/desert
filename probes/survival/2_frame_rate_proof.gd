extends ShieldProbe
## Survival probe 2: frame-rate proof. The same stretch of a hot afternoon,
## far enough from the equator for the heat to harm, in a light storm and a
## gale, run at 30, 60 and 120 physics ticks a second, leaves you with the
## same health, hunger and thirst, the same water and food in your slots and
## the same harm taken from each of the three harms, to the bit: needs tick
## on the world clock, not the frame. Then the same sprint and rest spends
## and wins back the same stamina.

const RATES := [30, 60, 120]
## Five minutes into a run that starts in the morning, just before the heat peaks.
const START := 300.0
const END := 700.0
const LATITUDE := 30.0
const SPRINT := 3.0
const REST := 2.0
## Ticks run this many times faster than real time, each as long as at its rate.
const SPEEDUP := 4


func run() -> void:
	var needs := {}
	var stamina := {}
	for rate: int in RATES:
		Engine.time_scale = SPEEDUP
		Engine.physics_ticks_per_second = rate * SPEEDUP
		Engine.max_physics_steps_per_frame = 8 * SPEEDUP
		weather_everywhere(0.2, 26.0)
		await load_world(1234, false)
		var player := world.player
		var vitals := player.vitals
		player.set_physics_process(false)
		# The same spot to the millimetre: the storm differs a little from place to place.
		teleport(40.0, 40.0)
		world.time_warp = 0.0
		await physics_frames(2)
		# After the move, which the moon's position follows.
		world.moon.latitude = deg_to_rad(LATITUDE)
		world.time = START
		await physics_frames(2)
		# Just above where the suit gives you water and food, so it does both.
		vitals.fresh()
		vitals.thirst = Vitals.FULL * world.tuning.drink_below + 1.0
		vitals.hunger = Vitals.FULL * world.tuning.eat_below + 1.0
		world.time_warp = 30.0
		while world.time + world.time_warp / rate <= END:
			await get_tree().physics_frame
		world.time_warp = 0.0
		world.time = END
		await physics_frames(2)
		var slots: Array = player.suit.slots.map(func(p: Part) -> float: return p.amount if p is Supply else -1.0)
		needs[rate] = [vitals.health, vitals.hunger, vitals.thirst, vitals.drunk, vitals.eaten,
			vitals.taken[&"wind"], vitals.taken[&"storm"], vitals.taken[&"temperature"]] + slots
		print("%d ticks/s: %s" % [rate, needs[rate]])

		weather_everywhere(0.0)
		player.stamina = world.tuning.stamina_max
		player.set_physics_process(true)
		for action in ["move_forward", "sprint"]:
			Input.action_press(action)
		await physics_frames(roundi(SPRINT * rate))
		var spent := player.stamina
		for action in ["move_forward", "sprint"]:
			Input.action_release(action)
		await physics_frames(roundi(REST * rate))
		stamina[rate] = [spent, player.stamina]
		print("%d ticks/s: stamina %s" % [rate, stamina[rate]])
		world.queue_free()
		await get_tree().process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8

	var tuning := Tuning.current()
	var first: Array = needs[60]
	check(first[3] > 0.0 and first[4] > 0.0 and first[5] > 0.0 and first[6] > 0.0 and first[7] > 0.0,
		"the suit gave you water and food, and every harm took health")
	for rate: int in [30, 120]:
		var apart := 0.0
		for i in first.size():
			apart = maxf(apart, absf(needs[rate][i] - first[i]))
		check(apart < 1e-9, "%d ticks/s leaves every need as 60 does (%.12f apart)" % [rate, apart])
		var tired := absf(stamina[rate][0] - stamina[60][0]) + absf(stamina[rate][1] - stamina[60][1])
		check(tired < 0.05, "%d ticks/s spends and wins back the stamina 60 does (%.3f apart)" % [rate, tired])
	check(stamina[60][0] < tuning.stamina_max - tuning.stamina_sprint_drain * SPRINT * 0.9 \
		and stamina[60][1] > stamina[60][0], "the sprint spent stamina and the rest won some back")
