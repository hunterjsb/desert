extends Node
## Read-only audit from the actual Surveyor new-run morning. --baseline uses old refill.
func _ready() -> void:
	call_deferred("audit")

func audit() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	if OS.get_cmdline_user_args().has("--baseline"):
		tuning.site_wake_return_minutes = 5
		tuning.site_surge_window_minutes = 30
	for run_seed in [1234, 1, 42]:
		var world: World = preload("res://game/world/world.tscn").instantiate()
		world.run_seed = run_seed
		world.kit = Kit.standard()
		add_child(world)
		world.time_warp = 0
		world.player.set_physics_process(false)
		var runs := Runs.new()
		runs._begin(world)
		runs.free()
		var shape := world.shape
		var start := world.spawn
		var began := world.time
		var seeds := shape.sites.dunes.cells_near(start, 1000.0)
		var count := 0
		var seen := 0
		var changed := 0
		var clear_minutes := 0
		for seed in seeds:
			shape.sites.dunes.locate(seed)
			var site: Structure = seed.site
			if site == null:
				continue
			count += 1
			var initial := Exposure.level(site.depth, site.pure_taken(began))
			var peak := initial
			var clear := 0
			for minute in range(1, 61):
				var t := began + minute * 60.0
				var level := Exposure.level(site.depth, site.pure_taken(t))
				peak = maxf(peak, level)
				if level > 0.1 and site._ctx.field.raw_storm_at(site.x, site.z, t) < 0.05:
					clear += 1
			seen += int(peak > 0.1)
			changed += int(peak > initial + 0.1)
			clear_minutes += clear
		print("first-hour seed %d: %d natural dune ruins within 1km; %d visible, %d newly revealed; %d clear ruin-minutes" % [run_seed, count, seen, changed, clear_minutes])
		if is_instance_valid(world):
			world.queue_free()
		await get_tree().process_frame
	get_tree().quit()
