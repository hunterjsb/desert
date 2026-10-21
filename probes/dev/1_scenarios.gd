extends WeatherProbe
## Dev probe 1: every scenario starts, as the console starts it, where it
## says, and lays what it stages without an error. A storm 100 m away is 100 m
## upwind and you face it; deep is deep; dusk is dusk; going looking stands you
## before a ruin's door with finds round it; the farm stands in front of you
## growing; a board of every make lies charged at your feet by a small camp; a
## radio and a shield on its plate stand in front of you with a beacon in
## reach; the reference camp stands round you on its deck, running; the lee
## stands you under a tall slip face, facing up it into the wind over its
## crest, the wind on you cut and a storm due; chassis pieces, their trays, a
## frame and a spare piece, charged batteries, a light shield, a condenser,
## hooks and a coil lie in front of you, one piece's hook moored to a stake; a
## Console on a floating deck shows its finest map and every reading, the
## storm coming, its shield smart and off; the anomaly stands you where its
## heart comes over minutes after its wall, by a camp built for wind, and is
## found on other seeds' weather too; scrapping stands every wreck in a fan
## ahead of you, dug out, with what strips them at your feet; the still camp
## lets you sleep at dusk; the vent's plume stands ahead of you a minute
## before it bursts; the eclipse faces Tu just before the sun goes behind it;
## the far side has no Tu; the Walker comes at you on its route, a Console
## holding three tells beside you, its plug in your hands. Checked against
## the field itself and against what the game then shows.

const SLACK := 1.0

## The ruin the scenario stood you by.
var _ruin: Ruin


func run() -> void:
	await load_weather(1234, true)
	world.player.set_physics_process(false)
	_anomaly_on_other_weather()
	for scenario in Scenarios.LIST:
		var place := Scenarios.find(world, scenario)
		check(not place.is_empty(), "%s: found in this run's weather" % scenario.key)
		if place.is_empty():
			continue
		Scenarios.stand(world, scenario, place)
		world.time_warp = 0.0
		await physics_frames(3)
		var at := Vector2(world.player_world_x(), world.player_world_z())
		var t := world.time
		var facing := -world.player.global_basis.z
		var ahead := Vector2(facing.x, facing.z).normalized()
		var upwind := -field.prevailing_at(t).normalized()
		var hour := world.weather.day.time_of_day(t, world.moon.longitude)
		var stormy := field.raw_storm_at(at.x, at.y, t) > 0.0
		var what: String = scenario.key
		check(world.weather.in_storm == stormy, "%s: the game agrees about the storm" % what)
		if scenario.has("day"):
			check(hour >= scenario.day[0] and hour <= scenario.day[1], "%s: at the right time of day (%.3f)" % [what, hour])
		match scenario.kind:
			"spawn":
				check(at.distance_to(world.spawn) < 0.01 and t == 0.0,
					"spawn: where and when the run began")
			"clear", "ruin":
				if scenario.has("due"):
					var due := field.next_change(at.x, at.y, t, 600.0, 5.0)
					check(not stormy and due >= scenario.due[0] - 10.0 and due <= scenario.due[1] + 10.0,
						"%s: clear, with a storm due in %d to %d s (%.0f s)" % [what, scenario.due[0], scenario.due[1], due])
				else:
					check(not stormy and field.next_change(at.x, at.y, t, 600.0, 5.0) == INF,
						"%s: no storm for 10 minutes" % what)
				if scenario.has("calm"):
					check(field.wind_at(at.x, at.y, t).length() < scenario.calm, "%s: a calm spell" % what)
				if scenario.kind == "ruin":
					_ruin_ahead(at, ahead)
			"front", "back":
				check(stormy == (scenario.kind == "back"), "%s: on the right side of the edge" % what)
				check(ahead.dot(upwind) > 0.999, "%s: facing upwind, where it comes from" % what)
				var edge := _edge(at, upwind, t, stormy)
				check(absf(edge - scenario.distance) < SLACK,
					"%s: the edge is %.0f m upwind (%.2f m)" % [what, scenario.distance, edge])
			"lee":
				var due := field.next_change(at.x, at.y, t, 600.0, 5.0)
				check(not stormy and due >= scenario.due[0] - 10.0 and due <= scenario.due[1] + 10.0,
					"lee: clear, with a storm due in %d to %d s (%.0f s)" % [scenario.due[0], scenario.due[1], due])
				check(ahead.dot(upwind) > 0.999, "lee: facing upwind, up the face")
				var crest := -INF
				for d in range(0, 81, 2):
					crest = maxf(crest, world.height_at(at.x + upwind.x * d, at.y + upwind.y * d))
				check(crest - world.height_at(at.x, at.y) >= Scenarios.LEE_TALL,
					"lee: its crest stands %.0f m above you (%.1f)" % [Scenarios.LEE_TALL, crest - world.height_at(at.x, at.y)])
				var cut := 1.0 - world.weather.wind.length() / world.weather.field_wind(world.player.global_position).length()
				check(cut >= Scenarios.LEE_SHARE * Tuning.current().lee_wind and Dev.read("weather/lee") != "-",
					"lee: the wind on you is cut by its lee, and the overlay says so (%.2f)" % cut)
			"anomaly":
				var due := field.next_change(at.x, at.y, t, 600.0, 5.0)
				check(not stormy and due >= scenario.due[0] - 10.0 and due <= scenario.due[1] + 10.0,
					"anomaly: clear, its storm due in %d to %d s (%.0f s)" % [scenario.due[0], scenario.due[1], due])
				var full := INF
				var s := 0.0
				while s <= due + Scenarios.ANOMALY_WALL + 10.0 and full == INF:
					full = s if field.anomaly_at(at.x, at.y, t + s) >= 1.0 else INF
					s += 5.0
				check(full - due <= Scenarios.ANOMALY_WALL + 10.0 and ahead.dot(upwind) > 0.999,
					"anomaly: facing upwind, its heart over you within %d s of the wall (%.0f s)" % [Scenarios.ANOMALY_WALL, full - due])
			"vent":
				var vent: Dictionary = world.shape.history.geology.live()[0]
				var burst := world.shape.history.geology.next_burst(vent, t) - t
				check(not stormy and absf(burst - Scenarios.VENT_LEAD) < 1.0
					and world.weather.day.sun_shown(t + burst) == 1.0,
					"vent: clear, the vent bursting in sunlight in %d s (%.0f s)" % [Scenarios.VENT_LEAD, burst])
			"deep":
				check(field.storm_at(at.x, at.y, t) == 1.0, "deep: full storm")
				check(_edge(at, upwind, t, true) > 250.0 and _edge(at, -upwind, t, true) > 250.0,
					"deep: far from either edge")
			"sky":
				var sun := world.weather.day.sun_direction(t, world.moon.latitude, world.moon.longitude).y
				check(not stormy, "%s: a clear sky" % what)
				check((sun > 0.0 and sun < 0.12) if what == "dusk" else sun < 0.0,
					"%s: the sun is where it should be (%.2f)" % [what, sun])
		var day := world.weather.day
		var tu := day.tu_direction(t, world.moon.latitude, world.moon.longitude)
		if scenario.has("eclipse"):
			var mid: float = t + scenario.eclipse + day.totality() * 0.5
			check(day.sun_shown(t) == 1.0 and day.sun_shown(mid) == 0.0 and day.next_eclipse(t) - mid < 0.5,
				"eclipse: the sun goes behind Tu %d s on" % scenario.eclipse)
			check(ahead.dot(Vector2(tu.x, tu.z).normalized()) > 0.999 and tu.y > 0.0, "eclipse: facing Tu")
		if scenario.has("moon"):
			check(is_equal_approx(rad_to_deg(world.moon.latitude), scenario.moon[0]) and tu.y < -sin(day.tu_radius()),
				"%s: %d° north, where Tu never rises" % [what, scenario.moon[0]])
		if scenario.get("lays") == &"survive":
			_hurt_and_burdened()
		var dropped := await Scenarios.lay(world, scenario, place)
		check(dropped.is_empty() != scenario.has("lays"), "%s: lays what it stages, %d things" % [what, dropped.size()])
		match scenario.get("lays", &""):
			&"clear":
				check(world.player.hands.held is Flare and world.player.hands.held in dropped,
					"clear: the deliveryship flare starts in your hands")
				check(dropped.any(func(n: Node) -> bool: return n is Radio and n.channel == Radio.WEATHER),
					"clear: the weather radio shares the delivery setup")
			&"yours": await _ruin_finds(dropped)
			&"survive": await _survival_starts(dropped)
			&"farm": await _farm_lands(dropped)
			&"board": await _board_lands(dropped)
			&"radio": await _radio_lands(dropped)
			&"afk": await _afk_lands(dropped)
			&"catch_line": _catch_line_lands(dropped, upwind)
			&"chassis": await _chassis_lands(dropped)
			&"console": await _console_lands(dropped)
			&"anomaly_camp": await _anomaly_camp_lands(dropped)
			&"walker_camp": await _walker_camp_lands(dropped)
			&"wrecks": _wrecks_stand(dropped)
			&"sleep": await _sleep_comes(dropped, upwind)
			&"vent": await _plume_ahead(ahead)
		# Cleared as the next scenario would, and gone before it lays its own.
		# Each independent setup starts empty-handed; scenario changes preserve held gear.
		world.player.hands.drop()
		Scenarios._clear(world, &"scenario_kit", false)
		await physics_frames(2)


## The anomaly's search finds one on the weather of seeds where it once came
## up empty, one the windowed game met: as far as it looks from where the run began.
func _anomaly_on_other_weather() -> void:
	var own := world.weather.field
	for each in [2239642621, 15838, 142542]:
		world.weather.field = WeatherField.new(each, world.tuning)
		check(not Scenarios.find(world, Scenarios.by_key("anomaly")).is_empty(), "anomaly: found on seed %d's weather" % each)
	world.weather.field = own


## Metres along `along` until the storm state differs from `inside`.
func _edge(from: Vector2, along: Vector2, t: float, inside: bool) -> float:
	var d := 0.0
	while d < 6000.0:
		d += 0.1
		var p := from + along * d
		if (field.raw_storm_at(p.x, p.y, t) > 0.0) != inside:
			return d
	return INF


## A radio stands in front of you, a full battery in it, switched
## off, by a charged shield on its plate, switched off; tuned to the beacon
## there, it hears one.
func _radio_lands(dropped: Array[Node3D]) -> void:
	await physics_frames(30)
	var player := world.player
	var radio: Radio = dropped[0]
	var shield: ShieldGenerator = _first(dropped, ShieldGenerator)
	var off := radio.global_position - player.global_position
	check(off.dot(-player.global_basis.z) > 0.5 and Vector2(off.x, off.z).length() < 3.0 and radio.channel == Radio.OFF
		and radio.battery() != null and radio.charge_share() >= 1.0, "radio: in front of you, charged and off")
	check(not shield.on and _charged(shield), "radio: a charged shield beside it, on its plate")
	while radio.channel != Radio.BEACON:
		radio.sweep()
	check(not radio.target.is_empty(), "radio: a beacon in reach from there")


## The camp built for wind stands round you: its deck moored to a driven
## stake, its shield running on one battery, the turbine out beyond the
## bubble in the same pool, a Console reading wind and sand, the radio on
## the deck playing; a compass in your suit.
func _anomaly_camp_lands(dropped: Array[Node3D]) -> void:
	await physics_frames(60)
	var deck: Chassis = dropped[0]
	var console: Console = _first(dropped, Console)
	var radio: Radio = _first(dropped, Radio)
	var shield: ShieldGenerator = _first(dropped, ShieldGenerator)
	var stake: Stake = _first(dropped, Stake)
	var turbine: Device = dropped.filter(func(b: Node) -> bool: return b is Device and b.stats().turbine_w > 0.0)[0]
	check(deck.pieces().size() == 4 and stake.driven and shield.running() and shield.host() == deck
		and deck.batteries().size() == 1 and world.power.pool_wh(turbine) == world.power.pool_wh(shield)
		and turbine.global_position.distance_to(shield.global_position) > shield.size + 0.5,
		"anomaly: a moored deck, its shield running on one battery, the turbine beyond the bubble in its pool")
	check(console.running() and console.gear().has("anemometer") and console.gear().has("particle_sensor")
		and radio.playing() and world.player.suit.carried.any(func(p: RigidBody3D) -> bool: return p is Compass),
		"anomaly: a Console reading wind and sand, the radio playing, a compass in your suit")


## Beside the Walker: it walks toward you along its route, and its Console
## holds all three tells, a cable in its port and the other plug in your hands.
func _walker_camp_lands(dropped: Array[Node3D]) -> void:
	await physics_frames(10)
	var walker: Walker = get_tree().get_nodes_in_group(&"walker")[0]
	var console: Console = _first(dropped, Console)
	var plug := world.player.hands.held as Part
	var off := walker.global_position - world.player.global_position
	check(walker.visible and Vector2(off.x, off.z).length() < Scenarios.WALKER_AHEAD + 5.0
		and Vector2(off.x, off.z).normalized().dot(Vector2(-world.player.global_basis.z.x, -world.player.global_basis.z.z).normalized()) > 0.9,
		"walker: the Walker ahead of you, coming (%.0f m)" % Vector2(off.x, off.z).length())
	check(console.running() and console.evidence.size() == Deeds.TELLS.size() and plug != null and plug.kind == &"port"
		and console.parts().any(func(p: Part) -> bool: return p.kind == &"port"), "walker: a Console holding three tells, its plug in your hands")


## The reference camp stands round you, running, on its deck: a tray under
## every piece floats the deck level, the condenser, the shield and the
## light panel stuck on it among the bank's batteries and the panels; it and
## the turbine are one pool, its bank full and 210 W of panels; the bubble
## takes you, the deck and the planters, the
## turbine out beyond it on its strong cable; the deck is moored to a driven
## stake and each planter to its own; the planters float, sown, watered and
## harvesting, near enough to drop food onto you, on hoses from the
## condenser; you're fed and watered, carrying canisters, spare stakes, a
## coil and a hose, and no food.
func _afk_lands(dropped: Array[Node3D]) -> void:
	await physics_frames(60)
	var player := world.player
	var deck: Chassis = dropped.filter(func(b: Node) -> bool: return b is Chassis)[0]
	var shield: ShieldGenerator = dropped.filter(func(b: Node) -> bool: return b is ShieldGenerator)[0]
	var planters := dropped.filter(func(b: Node) -> bool: return b is Planter)
	var turbine: Device = dropped.filter(func(b: Node) -> bool: return b is Device and b.stats().turbine_w > 0.0)[0]
	var condenser: Condenser = dropped.filter(func(b: Node) -> bool: return b is Condenser)[0]
	var standing := deck.mounted()
	var tilt := rad_to_deg(deck.global_basis.y.normalized().angle_to(Vector3.UP))
	check(deck.pieces().size() == 4 and deck.stats().lift_kg >= 4.0 * 80.0 and deck.stats().hovering and tilt < 2.5
		and standing.size() == 3 and standing.has(shield) and standing.has(condenser),
		"afk: a tray under every piece floats the deck level (%.1f°), the shield, condenser and light panel stuck on it" % tilt)
	var room := 0.0
	for device: Device in [deck, turbine]:
		for cell in device.batteries():
			room += cell.capacity()
	var bank := world.power.pool_wh(deck)
	var pooled := standing.all(func(d: Device) -> bool: return world.power.pool_wh(d) == bank)
	var panels: float = deck.stats().solar_w
	for device in standing:
		panels += device.stats().solar_w
	check(pooled and bank == world.power.pool_wh(turbine) and absf(bank - room) < 1e-6 and is_equal_approx(panels, 210.0),
		"afk: the deck, all on it and the turbine share one full bank (%.0f Wh), 210 W of panels (%.0f W)" % [bank, panels])
	var inside := func(b: Node3D) -> bool: return b.global_position.distance_to(shield.global_position) < shield.size - 0.5
	check(shield.running() and inside.call(player) and planters.all(inside)
		and turbine.global_position.distance_to(shield.global_position) > shield.size + 0.5 and clearance(turbine) < 0.3,
		"afk: the bubble takes you and the planters, the turbine on the sand out beyond it")
	var farming := func(p: Planter) -> bool:
		return p.harvests() and p.plants().size() == 4 and p.tank_l >= world.tuning.planter_tank_litres \
			and p.stats().hovering and clearance(p) > 0.8 \
			and p.global_position.distance_to(player.global_position) < world.tuning.drop_reach
	check(planters.size() == 2 and planters.all(farming),
		"afk: two planters floating, sown, watered and harvesting, near enough to drop food onto you")
	var watered := Water.network(world, condenser)
	check(planters.all(func(p: Planter) -> bool: return watered.has(p)) and condenser.powered,
		"afk: both on hoses from the condenser, running")
	var stakes := dropped.filter(func(b: Node) -> bool: return b is Stake and b.driven)
	check(stakes.size() == 1 + planters.size() and world.ropes.ropes.size() == 2 + 2 * planters.size(),
		"afk: the deck and each planter moored to a driven stake, the turbine on its strong cable, the planters on their hoses")
	var carried := player.suit.carried.map(func(p: RigidBody3D) -> String: return Suit._name(p))
	check(player.vitals.health > 99.0 and player.vitals.hunger > 99.0 and player.vitals.thirst > 99.0
		and carried.count("Water canister") == Scenarios.AFK_CANISTERS and carried.count("Stake") == Scenarios.AFK_STAKES
		and carried.count("Rope coil") == 1 and carried.count("Hose") == 1
		and carried.size() == Scenarios.AFK_CANISTERS + Scenarios.AFK_STAKES + 2,
		"afk: you start fed and watered, carrying water, spare stakes, a coil and a hose (%s)" % ", ".join(carried))


## Chassis pieces lie flat on the sand in front of you, a tray before each,
## a spare piece and a frame for a wall, two charged batteries, the light
## shield, a condenser with an empty canister, and two hooks and a coil, all
## within a few steps. All the pieces are bare but the first, whose hook is
## moored to a stake, and another piece is offered that ring with room to
## join there.
func _chassis_lands(dropped: Array[Node3D]) -> void:
	await physics_frames(60)
	var player := world.player
	var near := func(b: Node3D) -> bool:
		var off := b.global_position - player.global_position
		return off.dot(-player.global_basis.z) > 1.0 and Vector2(off.x, off.z).length() < 6.5 and clearance(b) < 0.6
	var pieces := dropped.filter(func(b: Node3D) -> bool: return b is Chassis)
	var trays := dropped.filter(func(b: Node3D) -> bool: return b is Part and b.kind == &"bottom")
	check(pieces.size() == Scenarios.CHASSIS_PIECES.size() + 1 and trays.size() == Scenarios.CHASSIS_PIECES.size()
		and pieces.all(func(p: Chassis) -> bool: return p.global_basis.y.dot(Vector3.UP) > 0.99)
		and pieces.slice(1).all(func(p: Chassis) -> bool: return p.parts().is_empty()),
		"chassis: pieces lying flat, a tray for each of the row and a spare, all bare but the first")
	var stake: Stake = dropped.filter(func(b: Node3D) -> bool: return b is Stake)[0]
	var first: Chassis = pieces[0]
	var outer := Rig.ring_of(first, Vector2i.ZERO, Vector2i(-1, 0))
	check(world.ropes.ropes.any(func(r: Rope) -> bool: return [r.a.holder, r.b.holder] in [[first, stake], [stake, first]])
		and pieces[1].fits_in(outer)
		and first.room_for(pieces[1], first.global_transform * first._pose_at(outer, 0)),
		"chassis: the first piece's hook moored to a stake, a piece offered its ring and room there")
	check(dropped.filter(func(b: Node3D) -> bool: return b is Part and b.kind == &"ring").size() == 2
		and dropped.any(func(b: Node3D) -> bool: return b is Part and b.kind == &"coil"), "chassis: two hooks and a coil")
	var cells := dropped.filter(func(b: Node3D) -> bool: return b is Battery and b.charge_wh >= b.capacity())
	var condenser: Condenser = _first(dropped, Condenser)
	check(cells.size() == 2 and dropped.any(func(b: Node3D) -> bool: return b is Frame)
		and dropped.any(func(b: Node3D) -> bool: return b is ShieldGenerator)
		and condenser.canister() != null and condenser.canister().amount == 0.0,
		"chassis: a frame, two charged batteries, the light shield and a condenser with an empty canister")
	check(dropped.all(near), "chassis: all of it on the sand within a few steps in front of you")


## A Console stands on a two-piece deck floating in front of you, its screen
## to you at about your eyes, every instrument in it and a radio behind it,
## and a shield on the other piece, switched off and smart from it; the deck moored
## to a driven stake; its map at its finest for one Console, its stats every
## reading, the storm on its way.
func _console_lands(dropped: Array[Node3D]) -> void:
	await physics_frames(120)
	var player := world.player
	var deck: Chassis = dropped[0]
	var made: Console = _first(dropped, Console)
	var shield: ShieldGenerator = _first(dropped, ShieldGenerator)
	var screen := made.global_basis * Vector3.FORWARD
	var eyes := player.camera.global_position.y - made.global_position.y
	check(made.on_deck() and made.host() == deck and shield.host() == deck and not shield.on and shield.smart
		and made.smart_shields().size() == 1 and made.smart_shields()[0] == shield
		and screen.dot(player.global_position - made.global_position) > 0.0 and deck.stats().hovering and absf(eyes) < 0.5,
		"console: on a floating deck, its screen to you at your eyes (%.2f m off), the shield beside it off and smart" % eyes)
	var stats := made.screen_text(Console.Page.STATS)
	var shown := ["WIND", "PRESS", "HUMID", "SAND", "FRONT", "FCST", "SHIELD"].all(func(l: String) -> bool: return l in stats)
	var full := Tuning.current().storm_map_radar_cells + 5 * Tuning.current().storm_map_cells_per_instrument
	check(shown and made.map_cells() == full and made._map.size() == full * full,
		"console: every reading on its stats, and its map at %d cells across:\n%s" % [made.map_cells(), stats])
	check(made.pooled_readings().forecast.change < INF and (_first(dropped, Stake) as Stake).driven and world.ropes.ropes.size() == 1,
		"console: the storm on its way, the deck moored")


## Every wreck kind stands ahead of you within reach of a walk, dug out, its
## way in turned to you, and at your feet a charged heat cutter, a scoop, two
## sealant canisters, two stakes and a med kit.
func _wrecks_stand(dropped: Array[Node3D]) -> void:
	var me := Vector2(world.player_world_x(), world.player_world_z())
	var kinds := {}
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if site is Structure and site.source == &"hand" and site.piece.wreck != null and site.stands() \
					and site.distance_to(me.x, me.y) < 160.0:
				kinds[site.kind] = site
	var all := StructureKit.kinds().filter(func(k: StringName) -> bool: return StructureKit.piece(k).wreck != null)
	check(kinds.size() == all.size(), "wreck: every kind stands ahead of you (%d of %d: %s)" % [kinds.size(), all.size(),
		", ".join(kinds.keys())])
	var ids := dropped.map(func(b: Node3D) -> StringName: return b.get_meta(&"catalog", &"stake" if b is Stake else &""))
	var cutter := dropped.filter(func(b: Node3D) -> bool: return b is Cutter)
	check(not cutter.is_empty() and (cutter[0] as Cutter).battery() != null
		and ids.count(&"sand_scoop") == 1 and ids.count(&"sealant") == 2 and ids.count(&"med_kit") == 1
		and dropped.filter(func(b: Node3D) -> bool: return b is Stake).size() == 2,
		"wreck: a charged cutter, a scoop, two sealants, two stakes and a med kit at your feet")
	var near := dropped.all(func(b: Node3D) -> bool: return b.global_position.distance_to(world.player.global_position) < 3.0)
	check(near, "wreck: all of it at your feet")


## A board of each make lies at your feet in front of you, nose ahead, the
## issue nearest, each with a full battery, and the ride action takes you onto
## the issue; beside you a deck of two rests on the sand, a charged shield on
## it switched off: the camp the range warnings watch, with none of them
## warning yet.
func _board_lands(dropped: Array[Node3D]) -> void:
	await physics_frames(60)
	var player := world.player
	var ahead := -player.global_basis.z
	var boards := dropped.filter(func(b: Node3D) -> bool: return b is Hoverboard)
	var board: Hoverboard = dropped[0]
	var off := board.global_position - player.global_position
	check(BoardMakes.make_of(board) == BoardMakes.ISSUE and off.dot(ahead) > 0.5 and Vector2(off.x, off.z).length() < 2.0
		and clearance(board) < 0.2, "board: the issue lying at your feet in front of you (%.1f m)" % Vector2(off.x, off.z).length())
	check(boards.map(BoardMakes.make_of) == BoardMakes.ALL and boards.all(func(b: Hoverboard) -> bool:
			return b.battery() != null and b.battery().charge_wh >= b.battery().capacity() and b.can_run()),
		"board: one of each make, charged, ready to ride")
	var shield: ShieldGenerator = _first(dropped, ShieldGenerator)
	var deck: Chassis = _first(dropped, Chassis)
	check(not shield.on and _charged(shield) and shield.host() == deck and deck.pieces().size() == 2 and deck.resting
		and dropped.all(func(b: Node3D) -> bool: return b.global_position.distance_to(player.global_position) < 6.0),
		"board: a small camp beside you, a charged shield on a deck of two resting on the sand")
	var standing := dropped.filter(func(b: Node3D) -> bool: return (b as Device).host() == null)
	check(player.camp_range.camp().size() == standing.size() and player.camp_range.told == 0,
		"board: the range warnings watch it, quiet so near")
	check(player.toggle_board() and player.board == board, "board: the ride action takes you onto the issue")
	player.step_off()


## Two planters float in front of you, each on its line to a driven stake,
## sown and part grown, one with a harvester and a full tank, the other's
## half full and a saltbush in it, their root-tubers growing in the clear and
## the saltbush's leaves open with the storm still minutes off; a charged
## shield on its plate stands between them, switched off, near enough for its
## bubble to take them, with a full canister by your feet and a spare
## root-tuber carried. In the wind, nothing slides off or drifts past its line.
func _farm_lands(dropped: Array[Node3D]) -> void:
	var set_down := dropped.map(func(b: Node3D) -> Vector3: return b.global_position)
	world.time_warp = 1.0
	await physics_frames(180)
	world.time_warp = 0.0
	var planters := dropped.filter(func(b: Node3D) -> bool: return b is Planter)
	var shield: ShieldGenerator = dropped.filter(func(b: Node3D) -> bool: return b is ShieldGenerator)[0]
	var radius := world.tuning.shield_radius
	var tanks := planters.map(func(p: Planter) -> float: return snappedf(p.tank_l / world.tuning.planter_tank_litres, 0.1))
	var moved := 0.0
	for i in dropped.size():
		moved = maxf(moved, dropped[i].global_position.distance_to(set_down[i]))
	var growing := 0
	var open := 0
	for planter: Planter in planters:
		for plant in planter.plants():
			growing += 1 if plant.crop == &"root_tuber" and plant.state == Plant.GROWING and plant.growth > 0.85 else 0
			open += 1 if plant.crop == &"saltbush" and plant.fold == 0.0 else 0
			check(plant.growth >= 0.5 and not plant.ripe(), "farm: %s sown part grown (%.2f)" % [plant.label, plant.growth])
		check(planter.plants().size() == 4 and planter.stats().hovering and clearance(planter) > 0.8
			and planter.global_position.distance_to(shield.global_position) < radius - 1.0,
			"farm: a planter sown and floating, inside where the bubble will stand")
	check(moved < 1.0 and world.ropes.ropes.size() == planters.size(),
		"farm: each on its line to a stake, none drifted off (%.2f m at most)" % moved)
	check(planters.size() == 2 and planters.filter(func(p: Planter) -> bool: return p.harvests()).size() == 1
		and tanks.has(1.0) and tanks.has(0.5), "farm: two planters, one with a harvester, tanks full and half (%s)" % [tanks])
	check(growing == 5, "farm: the root-tubers are growing in the clear (%d)" % growing)
	check(open == 1, "farm: a saltbush, its leaves open with the storm minutes off")
	check(not shield.on and _charged(shield), "farm: a charged shield on its plate, switched off")
	var loose := dropped.filter(func(b: Node3D) -> bool: return b is Supply and b.kind == &"water" and b.amount >= 2.0)
	check(loose.size() == 1 and world.player.suit.carried.any(func(p: RigidBody3D) -> bool: return p is Plant),
		"farm: a full canister, and a spare root-tuber carried")


## A ruin's front door stands in front of you.
func _ruin_ahead(at: Vector2, ahead: Vector2) -> void:
	var ruin := world.shape.sites.query(Rect2(at.x - 30.0, at.y - 30.0, 60.0, 60.0), false).filter(
		func(s: Site) -> bool: return s is Ruin and world.shape.sites.covering(s.x, s.z) == s)
	check(not ruin.is_empty(), "ruin: a ruin stands near you")
	_ruin = null if ruin.is_empty() else ruin[0]
	if _ruin == null:
		return
	var door := _ruin.to_world(Ruin.DOORS[0][0]) - at
	check(ahead.dot(door.normalized()) > 0.999 and door.length() < 20.0,
		"ruin: its front door is in front of you (%.1f m)" % door.length())


## Finds lie round the ruin, one on its floor a device with parts to strip,
## and your own bare chassis lands beside you.
func _ruin_finds(mine: Array[Node3D]) -> void:
	for i in 600:
		if world.salvage.is_idle():
			break
		await get_tree().process_frame
	if _ruin == null:
		return
	var finds := world.salvage.finds()
	var on_floor := finds.filter(func(b: Node) -> bool:
		return b.get_meta(&"find").size() > 2 and b.get_meta(&"find")[2] == _ruin.id)
	var strippable := on_floor.filter(func(b: Node) -> bool: return b is Device and not (b as Device).parts().is_empty())
	check(finds.size() >= 5 and on_floor.size() >= 3 and not strippable.is_empty(),
		"ruin: finds lie round you (%d), on its floor (%d), a device among them with parts to strip"
		% [finds.size(), on_floor.size()])
	check(mine.size() == 1 and mine[0] is Chassis and (mine[0] as Device).parts().is_empty() and clearance(mine[0]) < 0.6,
		"ruin: your own bare chassis lands beside you")


## Two stakes driven a few steps ahead with a line strung between them,
## across the wind: a catch line for the drift.
func _catch_line_lands(dropped: Array[Node3D], upwind: Vector2) -> void:
	var lines := Drift.lines(world)
	check(dropped.size() == 3 and lines.size() == 1 and absf((lines[0][2] - lines[0][1]).normalized().dot(upwind)) < 0.05,
		"lee: a catch line strung across the wind")


## Hurt, thirsty and carrying a battery, as a fresh start mustn't leave you.
func _hurt_and_burdened() -> void:
	world.player.vitals.health = 10.0
	world.player.vitals.thirst = 90.0
	world.player.suit.carried.append(Catalog.part(&"battery"))


## You start over on sealed water: fed, watered and whole with a fresh suit's
## kit, a deck in front of you with a condenser making water into its empty
## canister on the deck's panel and batteries, a charged shield beside it,
## and spare rations.
func _survival_starts(dropped: Array[Node3D]) -> void:
	var vitals := world.player.vitals
	world.time_warp = 1.0
	await physics_frames(60)
	world.time_warp = 0.0
	var condenser: Condenser = dropped.filter(func(b: Node3D) -> bool: return b is Condenser)[0]
	var shields := dropped.filter(func(b: Node3D) -> bool: return b is ShieldGenerator and _charged(b))
	var rations := dropped.filter(func(b: Node3D) -> bool: return b is Supply and b.kind == &"food")
	var carried := world.player.suit.carried.map(func(p: RigidBody3D) -> String: return p.label)
	check(vitals.health > 99.0 and vitals.hunger > 99.0 and vitals.thirst > 99.0
		and carried == ["Water canister", "Ration", "Bedroll", "Surveyor's Guide", "Home beacon"] and world.player.suit.supply(&"water").amount > 1.99,
		"survive: you start fed, watered and whole, on sealed water and a ration (%s)" % ", ".join(carried))
	check(condenser.powered and condenser.canister().amount > 0.0 and condenser.canister().amount < 0.01
		and condenser.host().stats().solar_w > 0.0 and condenser.host() == _first(dropped, ShieldGenerator).host(),
		"survive: the condenser is filling its empty canister on its deck's panel, beside the shield (%.4f L)"
		% condenser.canister().amount)
	check(shields.size() == 1 and rations.size() == Scenarios.SURVIVE_RATIONS.size(),
		"survive: a charged shield and spare rations")


## At dusk by the still camp you can sleep: its deck rests on the sand, the
## shield on it running and its bubble round you, the bedroll stuck on it, a
## wall on its frame facing upwind, and the radio playing the weather station.
func _sleep_comes(dropped: Array[Node3D], upwind: Vector2) -> void:
	await physics_frames(60)
	var deck: Chassis = dropped[0]
	var shield: ShieldGenerator = _first(dropped, ShieldGenerator)
	var radio: Radio = _first(dropped, Radio)
	var walls := deck.plates().filter(func(p: Array) -> bool:
		var out := deck.global_basis * (p[1] as Vector3)
		return Vector2(out.x, out.z).normalized().dot(upwind) > 0.99)
	check(deck.resting and _first(dropped, Bedroll) != null and _first(dropped, Bedroll).host() == deck
		and walls.size() == 1 and radio.playing(), "sleep: a bedroll on a deck resting on the sand, a wall to windward, the station on")
	check(shield.running() and world.player.global_position.distance_to(shield.global_position) < shield.size - 0.5
		and world.sleep.refusal() == "", "sleep: the shield running round you, and you can sleep (%s)" % world.sleep.refusal())


## The vent's plume stands ahead of you, drawn.
func _plume_ahead(ahead: Vector2) -> void:
	var plume := world.weather.plume_for(world.shape.history.geology.live()[0].id)
	for i in 10:
		await get_tree().process_frame
	var to := Vector2(plume.root.x - world.player_world_x(), plume.root.z - world.player_world_z())
	check(plume.visible and ahead.dot(to.normalized()) > 0.99 and absf(to.length() - Scenarios.VENT_OFF) < 300.0,
		"vent: its plume ahead of you, %.0f m off" % to.length())


## The first of a kind among what a scenario dropped, or null.
static func _first(dropped: Array, kind: Variant) -> Node:
	for body: Node in dropped:
		if is_instance_of(body, kind):
			return body
	return null


## Whether a shield's deck holds batteries all but full: what else is on the
## deck may have drawn a little since.
static func _charged(shield: ShieldGenerator) -> bool:
	var deck := shield.host()
	return deck != null and not deck.batteries().is_empty() and deck.charge_share() >= 0.99
