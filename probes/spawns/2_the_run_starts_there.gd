extends MenuProbe
## Spawns probe 2: the origin chosen at New game is the run's. New game asks
## who you come as, the origin last played highlighted, the Surveyor before
## any; each origin chosen, then Normal, starts its run there: the moon at
## that origin's start, a clear morning there with the first storm three to
## eight minutes off and passing within a day, never the field's days-long
## tail, on the run's day 1 however far on the clock, its kit beside you and
## on you, and round you the
## history its start was chosen by, as the sheet lays it: nothing a path or
## settlement left near the Surveyor, the Salvager's wreck field, the
## Homesteader's road and wayshrine.


func run() -> void:
	open_every_start()
	await open_main()
	var tuning := Tuning.current()
	var origins := Kit.open_to(main.profile())
	for k in origins.size():
		var kit := origins[k]
		press(&"ui_accept")
		var menu := main.ui.top()
		var last := maxi(k - 1, 0)
		check(menu.highlighted() == last, "New game asks who you come as, the %s highlighted" % origins[last].label)
		for i in k - menu.highlighted():
			press(&"ui_down")
		press(&"ui_accept")
		press(&"ui_accept")
		await faded_in()
		await started()
		var at := world.start
		var spawn := world.spawn
		check(world.kit == kit and at == Starts.find(world.shape, kit.start, tuning)
			and Sphere.point(world.moon._spawn_latitude, world.moon._spawn_longitude).distance_to(at) < 1e-6,
			"the %s's run is the %s's, begun at its start on the moon" % [kit.label, kit.label])
		var field := world.weather.field
		var hour := world.weather.day.time_of_day(world.time, world.moon.longitude)
		var due := field.next_change(spawn.x, spawn.y, world.time, 600.0, 10.0)
		check(field.raw_storm_at(spawn.x, spawn.y, world.time) <= 0.0 and due > 120.0 and due <= 480.0
			and hour >= Runs.START.day[0] and hour <= Runs.START.day[1] + 0.01,
			"the %s begins on a clear morning (%.2f of the day), the first storm due in %.0f s" % [kit.label, hour, due])
		var day := tuning.day_minutes * 60.0
		var lasts := field.next_change(spawn.x, spawn.y, world.time + due, 30.0 * day, 10.0)
		check(lasts <= day, "the %s's first storm passes within a day (%.2f days)" % [kit.label, lasts / day])
		var today := world.weather.day.day(world.time, world.moon.longitude, world.began)
		check(today == 1, "the %s's run begins on its day 1 (day %d, %.1f days on the clock)"
			% [kit.label, today, world.time / day])
		if world.arrival_enabled:
			check(world.arrival_state.get("phase") == &"recovery" and world.arrival_state.get("materialized", false)
				and world.player.suit.carried.is_empty(), "the Surveyor lands before recovery without a duplicate carried kit")
			_check_survivors()
		else:
			var carried := PackedStringArray(world.player.suit.carried.map(func(b: Node) -> String: return str(b.get_meta(&"catalog"))))
			check(_made(world.get_meta(&"kit", [])) == _wanted(kit)
				and carried == PackedStringArray(kit.carried_ids().map(func(id: StringName) -> String: return str(id))),
				"the %s's kit is beside you (%s) and on you (%s)" % [kit.label, _made(world.get_meta(&"kit", [])), ", ".join(carried)])
		var why := _round_you(kit, spawn, tuning)
		check(why == "", "the %s's history is laid round you%s" % [kit.label, "" if why == "" else ": " + why])
		await main._quit_to_menu()


## What the kit set down standing on its own, stakes too, by catalog id and how many.
func _made(nodes: Array) -> Dictionary:
	var out := {}
	for node: Node in nodes:
		if node is Device and (node as Device).host() == null:
			var id: StringName = node.get_meta(&"catalog")
			out[id] = out.get(id, 0) + 1
	return out


## What the kit says it sets down, by catalog id and how many: a deck, its
## first piece, or a plain device.
func _wanted(kit: Kit) -> Dictionary:
	var out := {}
	for id: StringName in kit.beside:
		var spec: Dictionary = kit.assembled.get(id, {"frame": id})
		var frame: StringName = &"chassis" if spec.has("rig") else spec.frame
		if Catalog.DEVICES.has(frame) or frame == &"stake":
			out[frame] = out.get(frame, 0) + 1
	return out


## What's wrong with the history laid round where the run began, or "".
func _round_you(kit: Kit, spawn: Vector2, tuning: Tuning) -> String:
	var sites := world.shape.sites
	var near := func(kind: StringName, metres: float) -> bool:
		return sites.nearest(spawn.x, spawn.y, metres, func(site: Site) -> bool:
			return site.kind == kind, true) != null
	match kit.start:
		&"artery":
			var deep := tuning.start_deep_m
			for site in sites.query(Rect2(spawn - Vector2.ONE * deep, Vector2.ONE * deep * 2.0)):
				if site.point != Vector3.ZERO and site.distance_to(spawn.x, spawn.y) < deep \
						and not site.source in [&"grid", &"wreck_field", &"hermit"]:
					return "a %s within %.0f m" % [site.kind, deep]
			for piece in sites.paths_in(Rect2(spawn - Vector2.ONE * deep, Vector2.ONE * deep * 2.0)):
				for i in piece.points.size() - 1:
					var by := Geometry2D.get_closest_point_to_segment(spawn, piece.points[i], piece.points[i + 1]).distance_to(spawn)
					if by < deep:
						return "a path %.0f m off, within %.0f m" % [by, deep]
		&"wreck_field":
			if not near.call(&"wreck_hull", tuning.start_wrecks_m + 1.0):
				return "no wreck within %.0f m" % tuning.start_wrecks_m
		&"wayshrine":
			if not near.call(&"wayshrine", tuning.start_wayshrine_m + 1.0):
				return "no wayshrine within %.0f m" % tuning.start_wayshrine_m
			if not sites.paths_in(Rect2(spawn - Vector2.ONE * 2.0, Vector2.ONE * 4.0)).any(
					func(piece: Sites.Piece) -> bool: return piece.carries & PathNetwork.ROAD):
				return "no road underfoot"
	return ""


## A resolved survivor is actual equipment at this start, not a fresh legacy grant.
func _check_survivors() -> void:
	var count := 0
	for entry: Dictionary in world.arrival_state.structure + world.arrival_state.equipment:
		var body: Variant = world.arrival_nodes.get(entry.uid)
		if entry.survives:
			count += 1
			check(is_instance_valid(body) and body.get_meta(&"arrival_uid", &"") == entry.uid
				and body.get_meta(&"catalog", &"") == entry.id,
				"the Surveyor's surviving %s is physical with its saved identity" % entry.uid)
		else:
			check(not is_instance_valid(body), "lost cargo does not receive a physical duplicate")
	check(world.arrival_nodes.size() == count, "the Surveyor receives exactly its resolved survivors")
