extends WorldProbe
## Loot probe 7: what a storm lays bare blows downwind. A house ruin stood by
## hand where a storm will lay it bare, and catch lines across the wind round
## it, read tick by tick through the storm as lines there would catch:
## downwind, the site's own lesser things arrive, falling just past the line,
## more near than far; upwind, off to the side and past the stream's reach,
## nothing of the site's; and nothing before the storm lays it bare.

const LINE := 8.0
## Where the lines stand from the site, m: [downwind, across the wind].
const NEAR := Vector2(30.0, 0.0)
const FAR := Vector2(200.0, 0.0)
const PAST := Vector2(600.0, 0.0)
const UPWIND := Vector2(-60.0, 0.0)
const ASIDE := Vector2(50.0, 70.0)


func run() -> void:
	await load_world(1234, false, true)
	world.time_warp = 0.0
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x() + 300.0, world.player_world_z())
	var stands := func(at: Vector2) -> bool: return sites.by_hand(&"house_ruin", at.x, at.y, 0.0, 0.0).stands()
	var storm := StormSite.strongest(world.weather.field, world.tuning, from.x, from.y, 2, 100.0, 1.0, stands)
	check(not storm.is_empty(), "a storm that lays a ruin bare")
	if storm.is_empty():
		return
	var site := sites.by_hand(&"house_ruin", storm.x, storm.z, 0.0, storm.depth)
	sites.add(site)
	world.time = storm.peak
	teleport(site.x + site.reach + 30.0, site.z)
	await settle()
	var wind := world.weather.field.wind_at(site.x, site.z, storm.peak).normalized()
	var lines := {}
	for name: String in ["near", "far", "past", "upwind", "aside"]:
		var at: Vector2 = {"near": NEAR, "far": FAR, "past": PAST, "upwind": UPWIND, "aside": ASIDE}[name]
		var mid := Vector2(site.x, site.z) + wind * at.x + wind.orthogonal() * at.y
		lines[name] = [mid - wind.orthogonal() * LINE * 0.5, mid + wind.orthogonal() * LINE * 0.5, 0, 0.0]
	var own := Drift.carried_from(site).map(func(entry: Array) -> StringName: return entry[0])
	var tick_s := world.tuning.drift_tick_s
	var early := 0
	var astray := 0
	var unlike := 0
	for k in range(floori(storm.before / tick_s), floori(storm.after / tick_s)):
		for name: String in lines:
			var line: Array = lines[name]
			var spec := Drift.caught(world, line[0], line[1], k)
			for each in Drift.from_sites(world, line[0], line[1], k * tick_s):
				if each[0] == site:
					line[3] += each[1] * tick_s / 3600.0
			if spec.get("site", -1) != site.id:
				continue
			line[2] += 1
			var t := k * tick_s
			early += int(site.bared_at(t) <= 0.0 and site.bared_at(t - 30.0) <= 0.0)
			unlike += int(not own.has(spec.id))
			# Fallen just past the line, downwind of it.
			var fell := Vector2(spec.x, spec.z)
			var on: Vector2 = Geometry2D.get_closest_point_to_segment(fell, line[0], line[1])
			var blowing := world.weather.field.wind_at((line[0].x + line[1].x) * 0.5, (line[0].y + line[1].y) * 0.5, t)
			astray += int(fell.distance_to(on) > Drift.FALLS.y + 0.01 or (fell - on).dot(blowing) <= 0.0)
	var said := PackedStringArray()
	for name: String in lines:
		said.append("%s %d (%.2f expected)" % [name, lines[name][2], lines[name][3]])
	print("off a house ruin %.1f m deep through its storm, caught on 8 m lines: %s" % [site.depth, ", ".join(said)])
	check(lines.near[2] > 0 and lines.near[3] > lines.far[3] and lines.far[3] > 0.0,
		"downwind its things arrive, more near than far")
	check(lines.upwind[3] == 0.0 and lines.aside[3] < lines.near[3] * 0.01 and lines.past[3] == 0.0
		and lines.upwind[2] + lines.past[2] == 0, "upwind, aside and past its reach, nothing of the site's")
	check(early == 0 and unlike == 0 and astray == 0,
		"only once it's laid bare, only its lesser things, fallen just past the line (%d, %d, %d)" % [early, unlike, astray])
