extends WeatherProbe
## Dev probe 1: every scenario drops you where it says. A storm 100 m away is
## 100 m upwind and you face it; deep is deep; dusk is dusk; the test kit lands
## in front of you; going looking stands you before a ruin's door with finds
## round it; the farm stands in front of you growing; a charged board lies at
## your feet by a small camp; a radio and a shield stand in front of you with a
## beacon in reach; the reference camp stands round you on its deck,
## running; the lee
## stands you under a tall slip face, facing up it into the wind over its
## crest, the wind on you cut and a storm due; chassis pieces, their trays,
## a charged crate and a condenser lie in front of you; the eclipse faces Tu
## just before the sun goes behind it; the far side has no Tu. Checked against
## the field itself and against what the game then shows.

const SLACK := 1.0


func run() -> void:
	await load_weather(1234, true)
	world.player.set_physics_process(false)
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
			"clear", "kit", "ruin":
				if scenario.has("due"):
					var due := field.next_change(at.x, at.y, t, 600.0, 5.0)
					check(not stormy and due >= scenario.due[0] - 10.0 and due <= scenario.due[1] + 10.0,
						"%s: clear, with a storm due in %d to %d s (%.0f s)" % [what, scenario.due[0], scenario.due[1], due])
				else:
					check(not stormy and field.next_change(at.x, at.y, t, 600.0, 5.0) == INF,
						"%s: no storm for 10 minutes" % what)
				if scenario.kind == "ruin":
					check(field.wind_at(at.x, at.y, t).length() < scenario.calm, "ruin: a calm spell")
					await _ruin_ahead(at, ahead)
				if scenario.kind == "kit":
					check(field.wind_at(at.x, at.y, t).length() < scenario.calm, "kit: a calm spell")
					await _kit_lands_near_you()
				if scenario.get("survive", false):
					await _survival_starts()
				if scenario.get("farm", false):
					await _farm_lands()
				if scenario.get("board", false):
					check(field.wind_at(at.x, at.y, t).length() < scenario.calm, "board: a calm spell")
					await _board_lands()
				if scenario.get("afk", false):
					await _afk_lands()
				if scenario.get("chassis", false):
					check(field.wind_at(at.x, at.y, t).length() < scenario.calm, "chassis: a calm spell")
					await _chassis_lands()
			"front", "back":
				check(stormy == (scenario.kind == "back"), "%s: on the right side of the edge" % what)
				check(ahead.dot(upwind) > 0.999, "%s: facing upwind, where it comes from" % what)
				var edge := _edge(at, upwind, t, stormy)
				check(absf(edge - scenario.distance) < SLACK,
					"%s: the edge is %.0f m upwind (%.2f m)" % [what, scenario.distance, edge])
				if scenario.get("camp", false):
					await _camp_lands()
				if scenario.get("radio", false):
					await _radio_lands()
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
## off, by a charged shield generator, switched off; tuned to the beacon
## there, it hears one.
func _radio_lands() -> void:
	await settle(true)
	var dropped := Scenarios.radio(world)
	await physics_frames(30)
	var player := world.player
	var radio: Radio = dropped[0]
	var shield: ShieldGenerator = dropped[1]
	var off := radio.global_position - player.global_position
	check(off.dot(-player.global_basis.z) > 0.5 and Vector2(off.x, off.z).length() < 3.0 and radio.channel == Radio.OFF
		and radio.battery() != null and radio.charge_share() >= 1.0, "radio: in front of you, charged and off")
	check(not shield.on and shield.battery().charge_wh >= shield.battery().capacity(), "radio: a charged shield beside it")
	while radio.channel != Radio.BEACON:
		radio.interact(player)
	check(not radio.target.is_empty(), "radio: a beacon in reach from there")
	for body in dropped:
		body.free()


## The reference camp stands round you, running, on its deck: a tray under
## every piece floats the deck level, the condenser, the shield and two
## crates standing on it, their own trays off; it and the turbine are one
## pool, its bank full; the bubble takes you, the deck and the planters, the
## turbine out beyond it on its strong cable; the deck is moored to a driven
## stake and each planter to its own; the planters float, sown, watered and
## harvesting, near enough to drop food onto you, on hoses from the
## condenser; you're fed and watered, carrying canisters, spare stakes, a
## coil and a hose, and no food.
func _afk_lands() -> void:
	await settle(true)
	var dropped := Scenarios.afk(world)
	await physics_frames(60)
	var player := world.player
	var deck: Chassis = dropped.filter(func(b: Node) -> bool: return b is Chassis)[0]
	var shield: ShieldGenerator = dropped.filter(func(b: Node) -> bool: return b is ShieldGenerator)[0]
	var planters := dropped.filter(func(b: Node) -> bool: return b is Planter)
	var turbine: Device = dropped.filter(func(b: Node) -> bool: return b is Device and b.stats().turbine_w > 0.0)[0]
	var condenser: Condenser = dropped.filter(func(b: Node) -> bool: return b is Condenser)[0]
	var standing := deck.mounted()
	var crates := standing.filter(func(d: Device) -> bool: return d.label == "Crate frame")
	var tilt := rad_to_deg(deck.global_basis.y.normalized().angle_to(Vector3.UP))
	check(deck.pieces().size() == 4 and deck.stats().lift_kg >= 4.0 * 80.0 and deck.stats().hovering and tilt < 2.5
		and standing.size() == 4 and crates.size() == 2 and standing.has(shield) and standing.has(condenser)
		and not standing.any(func(d: Device) -> bool: return d.has_tray()),
		"afk: a tray under every piece floats the deck level (%.1f°), four devices standing on it, their trays off" % tilt)
	var room := 0.0
	for device: Device in standing + [turbine]:
		for cell in device.batteries():
			room += cell.capacity()
	var bank := world.power.pool_wh(deck)
	var pooled := standing.all(func(d: Device) -> bool: return world.power.pool_wh(d) == bank)
	var panelled := func(c: Device) -> bool: return c.stats().solar_w > 0.0 and c.mounted().any(func(d: Device) -> bool: return d.stats().solar_w > 0.0)
	check(pooled and bank == world.power.pool_wh(turbine) and absf(bank - room) < 1e-6 and crates.any(panelled),
		"afk: the deck, all on it and the turbine share one full bank, a crate with two panels (%.0f Wh)" % bank)
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
	for body in dropped:
		if is_instance_valid(body):
			body.free()


## Bare chassis pieces lie flat on the sand in front of you, a tray before
## each, with a crate frame holding two charged batteries and a condenser
## with a battery and an empty canister, all within a few steps.
func _chassis_lands() -> void:
	await settle(true)
	var dropped := Scenarios.chassis(world)
	await physics_frames(60)
	var player := world.player
	var near := func(b: Node3D) -> bool:
		var off := b.global_position - player.global_position
		return off.dot(-player.global_basis.z) > 1.0 and Vector2(off.x, off.z).length() < 5.0 and clearance(b) < 0.6
	var pieces := dropped.filter(func(b: Node3D) -> bool: return b is Chassis)
	var trays := dropped.filter(func(b: Node3D) -> bool: return b is Part and b.kind == &"bottom")
	check(pieces.size() == Scenarios.CHASSIS_PIECES.size() and trays.size() == pieces.size()
		and pieces.all(func(p: Chassis) -> bool: return p.parts().is_empty() and p.global_basis.y.dot(Vector3.UP) > 0.99),
		"chassis: bare pieces lying flat, a tray for each")
	var crate: Device = dropped.filter(func(b: Node3D) -> bool: return b is Device and b.label == "Crate frame")[0]
	var condenser: Condenser = dropped.filter(func(b: Node3D) -> bool: return b is Condenser)[0]
	check(crate.batteries().size() == 2 and crate.charge_share() >= 1.0 and condenser.battery() != null
		and condenser.canister() != null, "chassis: a crate with two charged batteries, and a condenser")
	check(dropped.all(near), "chassis: all of it on the sand within 5 m in front of you")
	for body in dropped:
		if is_instance_valid(body):
			body.free()


## A hoverboard lies at your feet in front of you, nose ahead, a full battery
## in it, and the ride action takes you onto it; beside you stand a charged
## shield generator, switched off, and a crate frame: the camp the range
## warnings watch, with none of them warning yet.
func _board_lands() -> void:
	await settle(true)
	var dropped := Scenarios.board(world)
	await physics_frames(60)
	var player := world.player
	var ahead := -player.global_basis.z
	var board: Hoverboard = dropped[0]
	var off := board.global_position - player.global_position
	check(off.dot(ahead) > 0.5 and Vector2(off.x, off.z).length() < 2.0 and clearance(board) < 0.2,
		"board: lying at your feet in front of you (%.1f m)" % Vector2(off.x, off.z).length())
	check(board.battery() != null and board.battery().charge_wh >= board.battery().capacity() and board.can_run(),
		"board: charged, ready to ride")
	var shield: ShieldGenerator = dropped[1]
	check(not shield.on and shield.battery().charge_wh >= shield.battery().capacity()
		and dropped[2].label == "Crate frame" and dropped.all(func(b: Node3D) -> bool:
			return b.global_position.distance_to(player.global_position) < 6.0),
		"board: a small camp beside you, a charged shield and a crate")
	check(player.camp_range.camp().size() == dropped.size() and player.camp_range.told == 0,
		"board: the range warnings watch it, quiet so near")
	check(player.toggle_board() and player.board == board, "board: the ride action takes you onto it")
	player.step_off()
	for body in dropped:
		if is_instance_valid(body):
			body.free()


## Two planters float in front of you, each on its line to a driven stake,
## sown and part grown, one with a harvester and a full tank, the other's
## half full, their carrots growing in the clear; a charged shield generator
## stands between them, switched off, near enough for its bubble to take
## them, with a full canister by your feet and a spare carrot carried.
## In the wind, nothing slides off or drifts past its line.
func _farm_lands() -> void:
	await settle(true)
	var dropped := Scenarios.farm(world)
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
	for planter: Planter in planters:
		for plant in planter.plants():
			growing += 1 if plant.crop == &"carrot" and plant.state == Plant.GROWING and plant.growth > 0.85 else 0
			check(plant.growth >= 0.5 and not plant.ripe(), "farm: %s sown part grown (%.2f)" % [plant.label, plant.growth])
		check(planter.plants().size() == 4 and planter.stats().hovering and clearance(planter) > 0.8
			and planter.global_position.distance_to(shield.global_position) < radius - 1.0,
			"farm: a planter sown and floating, inside where the bubble will stand")
	check(moved < 1.0 and world.ropes.ropes.size() == planters.size(),
		"farm: each on its line to a stake, none drifted off (%.2f m at most)" % moved)
	check(planters.size() == 2 and planters.filter(func(p: Planter) -> bool: return p.harvests()).size() == 1
		and tanks.has(1.0) and tanks.has(0.5), "farm: two planters, one with a harvester, tanks full and half (%s)" % [tanks])
	check(growing == 6, "farm: the carrots are growing in the clear (%d)" % growing)
	check(not shield.on and shield.battery().charge_wh >= shield.battery().capacity(),
		"farm: a charged shield generator, switched off")
	var loose := dropped.filter(func(b: Node3D) -> bool: return b is Supply and b.kind == &"water" and b.amount >= 2.0)
	check(loose.size() == 1 and world.player.suit.carried.any(func(p: RigidBody3D) -> bool: return p is Plant),
		"farm: a full canister, and a spare carrot carried")
	for body in dropped:
		if is_instance_valid(body):
			body.free()


## A ruin's front door stands in front of you, finds lie round it, one on
## its floor a device with parts to strip, and your own bare frame lands
## beside you.
func _ruin_ahead(at: Vector2, ahead: Vector2) -> void:
	var ruin := world.shape.ruins.around(at.x, at.y, 30.0)
	check(not ruin.is_empty(), "ruin: a ruin stands near you")
	if ruin.is_empty():
		return
	var door := ruin[0].to_world(Ruin.DOORS[0][0]) - at
	check(ahead.dot(door.normalized()) > 0.999 and door.length() < 20.0,
		"ruin: its front door is in front of you (%.1f m)" % door.length())
	await settle(true)
	for i in 600:
		if world.salvage.is_idle():
			break
		await get_tree().process_frame
	var mine := Scenarios.yours(world)
	var coord := world.terrain.chunk_at(ruin[0].center.x, ruin[0].center.y)
	var finds := world.salvage.finds()
	var on_floor := finds.filter(func(b: Node) -> bool:
		return b.get_meta(&"find")[0] == coord and b.get_meta(&"find")[1] >= Finds.IN_RUIN)
	var strippable := on_floor.filter(func(b: Node) -> bool: return b is Device and not (b as Device).parts().is_empty())
	check(finds.size() >= 5 and on_floor.size() >= 3 and not strippable.is_empty(),
		"ruin: finds lie round you (%d), on its floor (%d), a device among them with parts to strip"
		% [finds.size(), on_floor.size()])
	check(mine.size() == 1 and mine[0] is Device and (mine[0] as Device).parts().is_empty() and clearance(mine[0]) < 0.6,
		"ruin: your own bare frame lands beside you")
	for body in mine:
		body.free()


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
	# Every part and coil, plus both cables' plugs and the hose's ends; stakes are devices.
	check(devices == Scenarios.KIT_DEVICES.size() + Scenarios.KIT_STAKES.size()
		and parts == Scenarios.KIT_PARTS.size() + Scenarios.KIT_COILS.size() + 6,
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
	world.player.suit.carried.append(Catalog.part(&"battery"))
	var dropped := Scenarios.survive(world)
	world.time_warp = 1.0
	await physics_frames(60)
	world.time_warp = 0.0
	var condenser: Condenser = dropped.filter(func(b: Node3D) -> bool: return b is Condenser)[0]
	var shields := dropped.filter(func(b: Node3D) -> bool: return b is ShieldGenerator and b.battery() != null \
		and b.battery().charge_wh >= b.battery().capacity())
	var rations := dropped.filter(func(b: Node3D) -> bool: return b is Supply and b.kind == &"food")
	var carried := world.player.suit.carried.map(func(p: RigidBody3D) -> String: return p.label)
	check(vitals.health > 99.0 and vitals.hunger > 99.0 and vitals.thirst > 99.0
		and carried == ["Water canister", "Ration"] and world.player.suit.supply(&"water").amount > 1.99,
		"survive: you start fed, watered and whole, on sealed water and a ration (%s)" % ", ".join(carried))
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
