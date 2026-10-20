extends Node
## Read-only audit of natural dune ruins near actual starting ground.
func _ready() -> void:
	call_deferred("audit")

func audit() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	for run_seed in [1234, 1, 42]:
		var shape := TerrainShape.new(run_seed, tuning)
		var p := Starts.find(shape, &"artery", tuning)
		var start := Starts.ground(shape, tuning, &"artery", p)
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
			var initial := Exposure.level(site.depth, site.pure_taken(0.0))
			var peak := initial
			var clear := 0
			for minute in range(1, 61):
				var t := minute * 60.0
				var level := Exposure.level(site.depth, site.pure_taken(t))
				peak = maxf(peak, level)
				if level > 0.1 and site._ctx.field.raw_storm_at(site.x, site.z, t) < 0.05:
					clear += 1
			seen += int(peak > 0.1)
			changed += int(peak > initial + 0.1)
			clear_minutes += clear
		print("first-hour seed %d: %d natural dune ruins within 1km; %d visible, %d newly revealed; %d clear ruin-minutes" % [run_seed, count, seen, changed, clear_minutes])
	get_tree().quit()
