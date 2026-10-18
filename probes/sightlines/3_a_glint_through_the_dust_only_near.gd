extends WorldProbe
## Sightlines probe 3: a glint shows through the dust only near. A hab pod
## stood by hand where a storm will lay it bare, read inside that storm as it
## works hardest: the clear sky's glints are hidden, and from beside it its
## windows, bared by the storm, glint through the dust, and only those the
## storm bared; from past the dust's reach, none of its. Once the storm has
## let go and it's back under, none through the dust; nor out of the storm.

const KIND := &"hab_pod"


func run() -> void:
	await load_world(1234, true, true)
	world.time_warp = 0.0
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x() + 320.0, world.player_world_z())
	var stands := func(at: Vector2) -> bool: return sites.by_hand(KIND, at.x, at.y, 0.0, 0.0).stands()
	var storm := StormSite.find(world.weather.field, world.tuning, from.x, from.y, 3, 100.0, 1.0, 0.0, stands)
	check(not storm.is_empty(), "a storm that lays a hab pod bare")
	if storm.is_empty():
		return
	var site := sites.by_hand(KIND, storm.x, storm.z, 0.0, storm.depth)
	sites.add(site)
	var reach := world.tuning.storm_glint_m
	var skyline := world.terrain.skyline
	var seen := []
	for at: Array in [[storm.peak, 40.0], [storm.peak, reach + 40.0], [storm.after, 40.0]]:
		world.time = at[0]
		teleport(site.x + site.reach + at[1], site.z)
		await settle()
		await physics_frames(30)
		var bare := site.bare_glints_at(site.level()).filter(func(g: Array) -> bool:
			return not site.bare_glints_at(Exposure.level(site.depth, site.settled())).any(
				func(h: Array) -> bool: return h[3] == g[3]))
		var near := skyline.dust_glints().filter(func(g: Array) -> bool:
			return Vector2(g[0].x, g[0].z).distance_to(Vector2(site.x, site.z)) < site.reach)
		seen.append([world.weather.in_storm, world.terrain.is_far_shown(), bare.size(), near.size()])
	print("in the storm, far shown, bared by it, glinting through the dust: beside it %s, past the dust's reach %s, by morning %s"
		% seen)
	check(seen[0][0] and not seen[0][1], "inside the storm, the clear sky's glints are hidden")
	check(seen[0][2] > 0 and seen[0][3] == seen[0][2], "from beside it, what the storm bared glints through the dust, only that")
	check(seen[1][3] == 0, "from past the dust's reach, none of its")
	check(seen[2][3] == 0, "back under by morning, none")
