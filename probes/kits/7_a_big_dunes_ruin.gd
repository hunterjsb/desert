extends Probe
## Structure kits probe 7: a big dune's ruin bares only past an intense storm.
## Round the start, most big dunes hold a ruin in their lee, seeded, the same
## found twice. Through two days of their weather, a storm that never brings
## its heart over one leaves it under the sand, near enough always; one whose
## heart holds over it half an hour or more lays nearly every one bare.

const SEED := 1234
const RADIUS := 1500.0
const RUINS := 30
const DAYS := 2.0
## A heart this hard counts toward an intense storm, for this many minutes.
const HEART := 0.9
const INTENSE := 30


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(SEED, tuning)
	shape.sites.set_clock(func() -> float: return 0.0)
	var dunes := shape.sites.dunes
	var big := 0
	var ruins: Array[Structure] = []
	var same := true
	for seed in dunes.cells_near(Vector2.ZERO, RADIUS):
		dunes.locate(seed)
		big += int(seed.crest >= tuning.dune_ruin_big_m)
		if seed.site != null:
			ruins.append(seed.site)
			var again := DuneRuins.Seed.new()
			again.key = seed.key
			again.id = seed.id
			dunes.locate(again)
			same = same and again.site != null and again.site.x == seed.site.x and again.site.depth == seed.site.depth
	print("%d big dunes within %.0f m, %d with a ruin in their lee" % [big, RADIUS, ruins.size()])
	check(ruins.size() >= big * 0.7, "most big dunes hold a ruin")
	check(same, "each found the same twice")
	var field := WeatherField.new(SEED, tuning)
	# [storms, bared] for those whose heart never came over, and the intense.
	var weak := [0, 0]
	var intense := [0, 0]
	for site in ruins.slice(0, RUINS):
		var hard := 0
		var last_heart := -10000
		var stormy := false
		var bared := false
		for m in range(30, roundi(DAYS * 24.0 * 60.0)):
			var heart := clampf(field.raw_storm_at(site.x, site.z, m * 60.0) / tuning.exposure_storm_full, 0.0, 1.0)
			if heart >= HEART:
				last_heart = m
			if heart > 0.0 or stormy:
				bared = bared or Exposure.level(site.depth, site.pure_taken(m * 60.0)) > 0.0
			if heart > 0.0:
				stormy = true
				hard += int(heart >= HEART)
			elif stormy:
				var counts: Array = intense if hard >= INTENSE else (weak if hard == 0 and m - last_heart > tuning.site_surge_window_minutes else [0, 0])
				counts[0] += 1
				counts[1] += int(bared)
				stormy = false
				bared = false
				hard = 0
	print("bared by storms whose heart never came over it: %d of %d; by intense ones: %d of %d"
		% [weak[1], weak[0], intense[1], intense[0]])
	check(weak[0] > 0 and weak[1] <= weak[0] * 0.05, "under the sand through storms that never bring their heart over")
	check(intense[0] > 0 and intense[1] >= intense[0] * 0.75, "laid bare by nearly every intense one")
