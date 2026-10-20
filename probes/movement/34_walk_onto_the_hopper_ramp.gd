extends "res://probes/kits/2_walk_through_openings.gd"
## Movement probe 34: the hopper's small ramp lip is not a steep slope.
## Actual walking through the two known approaches must keep its pace;
## the capsule's rounded edge contact must not repeatedly request a slide.

func run() -> void:
	Tuning.current().site_return_m = -1.0
	await load_moving(1234, true)
	var from := Vector2(world.player_world_x(), world.player_world_z())
	var stats := {"stuck": 0, "snags": 0, "under": 0.0, "legs": 0}
	# The same two placements that exposed the failure in the full opening tour.
	for slot: int in [22, 23]:
		var near := from + Vector2(80.0 * (slot % 6) - 200.0, 90.0 * (slot / 6) + 60.0)
		var site := await _stand(&"hopper", near, slot % 2)
		check(site != null, "a hopper stands for the ramp approach")
		if site == null:
			return
		await _tour(site, false, stats)
	print("hopper ramp: %d legs, %d stuck, %d snags" % [stats.legs, stats.stuck, stats.snags])
	check(stats.stuck == 0 and stats.snags == 0, "walking keeps pace through both hopper ramp approaches")
