extends WeatherProbe
## Dev probe 1: every scenario drops you where it says. A storm 100 m away is
## 100 m upwind and you face it; deep is deep; dusk is dusk; the test kit lands
## in front of you. Checked against the field itself and against what the game
## then shows.

const SLACK := 1.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	for scenario in Scenarios.LIST:
		var place := Scenarios.find(world, scenario)
		check(not place.is_empty(), "%s: found in this run's weather" % scenario.key)
		if place.is_empty():
			continue
		world.respawn(place.x, place.z, place.yaw, place.time)
		world.time_warp = 0.0
		await physics_frames(3)
		var at := Vector2(world.player_world_x(), world.player_world_z())
		var t := world.time
		var facing := -world.player.global_basis.z
		var ahead := Vector2(facing.x, facing.z).normalized()
		var upwind := -field.prevailing_at(t).normalized()
		var hour := world.weather.day.time_of_day(t)
		var stormy := field.raw_storm_at(at.x, at.y, t) > 0.0
		var what: String = scenario.key
		check(world.weather.in_storm == stormy, "%s: the game agrees about the storm" % what)
		if scenario.has("day"):
			check(hour >= scenario.day[0] and hour <= scenario.day[1], "%s: at the right time of day (%.3f)" % [what, hour])
		match scenario.kind:
			"spawn":
				check(at.distance_to(Vector2.ONE * Tuning.current().chunk_size * 0.5) < 0.01 and t == 0.0,
					"spawn: where and when the run began")
			"clear", "kit":
				check(not stormy and field.next_change(at.x, at.y, t, 600.0, 5.0) == INF,
					"%s: no storm for 10 minutes" % what)
				if scenario.kind == "kit":
					check(field.wind_at(at.x, at.y, t).length() < scenario.calm, "kit: a calm spell")
					await _kit_lands_near_you()
				if scenario.get("survive", false):
					await _survival_starts()
			"front", "back":
				check(stormy == (scenario.kind == "back"), "%s: on the right side of the edge" % what)
				check(ahead.dot(upwind) > 0.999, "%s: facing upwind, where it comes from" % what)
				var edge := _edge(at, upwind, t, stormy)
				check(absf(edge - scenario.distance) < SLACK,
					"%s: the edge is %.0f m upwind (%.2f m)" % [what, scenario.distance, edge])
				if scenario.get("camp", false):
					await _camp_lands()
			"deep":
				check(field.storm_at(at.x, at.y, t) == 1.0, "deep: full storm")
				check(_edge(at, upwind, t, true) > 250.0 and _edge(at, -upwind, t, true) > 250.0,
					"deep: far from either edge")
			"sky":
				var sun := world.weather.day.sun_direction(t, world.moon.latitude).y
				check(not stormy, "%s: a clear sky" % what)
				check((sun > 0.0 and sun < 0.12) if what == "dusk" else sun < 0.0,
					"%s: the sun is where it should be (%.2f)" % [what, sun])


## Metres along `along` until the storm state differs from `inside`.
func _edge(from: Vector2, along: Vector2, t: float, inside: bool) -> float:
	var d := 0.0
	while d < 6000.0:
		d += 0.1
		var p := from + along * d
		if (field.raw_storm_at(p.x, p.y, t) > 0.0) != inside:
			return d
	return INF


## Two devices and every kit part land on the sand in front of you, within a
## few steps. Light parts may then slide off on the wind, which is real.
func _kit_lands_near_you() -> void:
	await settle(true)
	var kit := Scenarios.kit(world)
	await physics_frames(30)
	var player := world.player
	var ahead := -player.global_basis.z
	var devices := 0
	var parts := 0
	var strays := PackedStringArray()
	for body in kit:
		if body is Cable:
			continue
		var off := body.global_position - player.global_position
		var c := clearance(body)
		devices += 1 if body is Device else 0
		parts += 1 if body is Part else 0
		if off.dot(ahead) < 1.0 or Vector2(off.x, off.z).length() > 5.0 or c < -0.05 or c > 0.6:
			strays.append("%s %.1fm %.2fm up" % [body.get("label"), Vector2(off.x, off.z).length(), c])
	# Every part and coil, plus both cables' plugs; stakes are devices.
	check(devices == Scenarios.KIT_DEVICES.size() + Scenarios.KIT_STAKES.size()
		and parts == Scenarios.KIT_PARTS.size() + Scenarios.KIT_COILS.size() + 4,
		"kit: every device, part, stake and coil dropped")
	check(strays.is_empty(), "kit: all of it on the sand within 5 m in front of you (%s)" % ", ".join(strays))
	for body in kit:
		body.free()


## You start over on sealed water: fed, watered and whole with a fresh suit's
## kit, a condenser in front of you making water into its empty canister, a
## charged shield generator beside it, and spare rations.
func _survival_starts() -> void:
	await settle(true)
	var vitals := world.player.vitals
	vitals.health = 10.0
	vitals.thirst = 90.0
	world.player.suit.slots[2] = Catalog.part(&"battery")
	var dropped := Scenarios.survive(world)
	world.time_warp = 1.0
	await physics_frames(60)
	world.time_warp = 0.0
	var condenser: Condenser = dropped.filter(func(b: Node3D) -> bool: return b is Condenser)[0]
	var shields := dropped.filter(func(b: Node3D) -> bool: return b is ShieldGenerator and b.battery() != null \
		and b.battery().charge_wh >= b.battery().capacity())
	var rations := dropped.filter(func(b: Node3D) -> bool: return b is Supply and b.kind == &"food")
	var slots := world.player.suit.slots.map(func(p: Part) -> String: return "-" if p == null else p.label)
	check(vitals.health > 99.0 and vitals.hunger > 99.0 and vitals.thirst > 99.0
		and slots == ["Water canister", "Ration", "-", "-", "-"] and world.player.suit.supply(&"water").amount > 1.99,
		"survive: you start fed, watered and whole, on sealed water and a ration (%s)" % ", ".join(slots))
	check(condenser.powered and condenser.canister().amount > 0.0 and condenser.canister().amount < 0.01
		and condenser.stats().solar_w > 0.0, "survive: the condenser is filling its empty canister (%.4f L)"
		% condenser.canister().amount)
	check(shields.size() == 1 and rations.size() == Scenarios.SURVIVE_RATIONS.size(),
		"survive: a charged shield generator and spare rations")
	for body in dropped:
		if is_instance_valid(body):
			body.free()


## The camp floats in front of you, each piece on a line to a driven stake
## upwind, with a charged shield, spare stakes and coils at your feet.
func _camp_lands() -> void:
	await settle(true)
	var camp := Scenarios.camp(world)
	await physics_frames(180)
	var floating := camp.filter(func(b: Node3D) -> bool: return b is Device and not b is Stake \
		and b.stats().hovering and clearance(b) > 0.8)
	var driven := camp.filter(func(b: Node3D) -> bool: return b is Stake and b.driven)
	var lines := world.ropes.ropes.size()
	var spares := camp.filter(func(b: Node3D) -> bool: return (b is Stake and not b.driven) or b.has_meta(&"line"))
	check(floating.size() == Scenarios.CAMP_DEVICES.size() and driven.size() == floating.size() and lines == floating.size(),
		"camp: each piece floats on its line to a driven stake (%d floating, %d driven, %d lines)"
		% [floating.size(), driven.size(), lines])
	check(spares.size() == Scenarios.CAMP_STAKES.size() + Scenarios.CAMP_COILS.size(),
		"camp: spare stakes and coils at your feet")
	var shields := camp.filter(func(b: Node3D) -> bool: return b is ShieldGenerator and b.battery() != null \
		and b.battery().charge_wh >= b.battery().capacity())
	check(shields.size() == 1, "camp: a charged shield generator to switch on")
	for body in camp:
		if is_instance_valid(body):
			body.free()
