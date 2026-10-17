extends FarmProbe
## Farming probe 7: frame-rate proof. The same day of the run's own weather,
## a clear morning into the noon heat, a cold clear night and a storm, run at
## 30, 60 and 120 physics ticks a second, leaves the same farm to the bit: a
## planter left to ripen and one with a harvester dropping food onto you, the
## same growth in every slot, the same water in every tank, and the same
## harvests ripened, replanted, stored and dropped. Growth ticks on the world
## clock, not the frame.

const RATES := [30, 60, 120]
const START := 60.0
const END := 1500.0
const CROPS := [&"carrot", &"carrot", &"carrot", &"fungus"]
## Ticks run this many times faster than real time, each as long as at its rate.
const SPEEDUP := 4


func run() -> void:
	var farms := {}
	for rate: int in RATES:
		Engine.time_scale = SPEEDUP
		Engine.physics_ticks_per_second = rate * SPEEDUP
		Engine.max_physics_steps_per_frame = 8 * SPEEDUP
		await load_world(1234, false)
		var player := world.player
		player.set_physics_process(false)
		# The food dropped onto you stays with what you carry.
		player.vitals.set_physics_process(false)
		teleport(40.0, 40.0)
		world.time_warp = 0.0
		await physics_frames(2)
		world.moon.latitude = 0.0
		world.time = START
		await physics_frames(2)
		var planters: Array[Planter] = [planter_at(ahead(2.0), CROPS), planter_at(ahead(-2.0), CROPS, true)]
		for planter in planters:
			for plant in planter.plants():
				plant.set_growth(0.5)
		world.time_warp = 30.0
		while world.time + world.time_warp / rate <= END:
			await get_tree().physics_frame
		world.time_warp = 0.0
		world.time = END
		await physics_frames(2)
		var farm := [player.suit.stock(&"food")]
		for planter in planters:
			farm.append(planter.tank_l)
			farm.append_array(planter.plants().map(func(p: Plant) -> float: return p.growth))
			for tally: Dictionary in [planter.ripened, planter.replanted, planter.banked, planter.dropped, planter.seeds]:
				farm.append_array(tally.values())
		farms[rate] = farm
		print("%d ticks/s: %s" % [rate, farm])
		world.queue_free()
		await get_tree().process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8

	var first: Array = farms[60]
	check(first.size() > 12 and first[0] > Tuning.current().ration_kcal, "the harvester harvested and dropped food onto you")
	for rate: int in [30, 120]:
		var same: bool = farms[rate].size() == first.size()
		var apart := 0.0
		for i in mini(first.size(), farms[rate].size()):
			apart = maxf(apart, absf(farms[rate][i] - first[i]))
		check(same and apart == 0.0, "%d ticks/s leaves the farm as 60 does (%.12f apart)" % [rate, apart])
