extends SalvageProbe
## Salvage & ruins probe 2: every find rests at its intended depth. A buried
## one's lowest point lies under the sand at its middle by just its planned
## share of its height, enough of it shows above the sand all round, and your
## hands can take it from beside it. A loose one settles from a few
## centimetres onto the sand, or is set on a site's floor or what stands on
## it, and rests there, never through it. Over the ground round the start, a
## ruin's, and places a kilometre out; and any kind the sand or a site holds
## that none of those turned up, laid by hand.
## Time limit: 420 s

## Your eyes look at a find from this far off, from any of these many sides.
const EYE_OFF := 1.3
const SIDES := 8


## Where the finds laid by hand are set out from, once.
var _laid_from := Vector2.INF

func run() -> void:
	await load_salvage()
	var places: Array[Vector2] = [Vector2(world.player_world_x(), world.player_world_z())]
	var ruin := ruins_near()[0]
	places.append(ruin.to_world(Ruin.APPROACH))
	for k in 4:
		places.append(places[0] + Vector2(1000.0, 0.0).rotated(k * TAU / 4.0))
	var tally := {"buried": 0, "loose": 0, "floor": 0, "deep": 0, "out": 0}
	var kinds := {}
	var worst := {"depth": 0.0, "rest": 0.0}
	var seen := {}
	for place in places:
		await go(place.x, place.y)
		# The chunks round you stay solid however you step round one of their finds.
		var here := world.terrain.chunk_at(place.x, place.y)
		for body in salvage.finds():
			var coord: Vector2i = body.get_meta(&"find")[0]
			if seen.has(body) or maxi(absi(coord.x - here.x), absi(coord.y - here.y)) > 1:
				continue
			seen[body] = true
			kinds[spec_of(body).id] = true
			await _check(body, tally, worst)
	var laid := 0
	var ids: Array[StringName] = SiteLoot.ids()
	for layer: StringName in Finds.PARTS:
		for table: Array in [Finds.PARTS[layer], Finds.DEVICES[layer]]:
			for entry: Array in table:
				if not ids.has(entry[0]):
					ids.append(entry[0])
	# Each laid find still settles tick by tick; only the wall clock runs faster.
	speed_up(6)
	for id in ids:
		if not kinds.has(id):
			kinds[id] = true
			await _check_laid(id, Catalog.DEVICES.has(id) or id == &"stake", laid, tally, worst)
			laid += 1
	speed_up(1)
	print("%d buried (%d deep) and %d loose (%d on a ruin's floor), %d kinds laid by hand; worst depth error %.4f m, worst rest %.3f m"
		% [tally.buried, tally.deep, tally.loose, tally.floor, laid, worst.depth, worst.rest])
	check(tally.buried >= 20 and tally.loose >= 5 and tally.floor >= 3, "finds of every kind were checked")
	check(tally.out == 0, "every find lies where it should (%d don't)" % tally.out)


## One of a kind laid by hand on open sand near you, buried if it can be,
## and checked as one found there would be.
func _check_laid(id: StringName, device: bool, k: int, tally: Dictionary, worst: Dictionary) -> void:
	# In rows round where the first was laid: checking one walks you to it, so
	# laid from where you stand each would lead you off the loaded ground.
	if _laid_from == Vector2.INF:
		_laid_from = Vector2(world.player_world_x(), world.player_world_z())
	var at := _laid_from + Vector2(3.0 * (k % 7) - 9.0, 5.0 + 3.0 * float(k / 7))
	var short := not device and Finds._longest(id) <= Finds.SHOWING
	var spec := {"index": 900 + k, "id": id, "device": device, "layer": Finds.SURFACE, "x": at.x, "z": at.y,
		"yaw": 0.5 * k, "lean": 1.0, "lean_by": 0.1, "bury": 0.0 if short else 0.4, "loose": short,
		"sound": 0.9, "charge": 0.5, "fill": []}
	var body := salvage.lay(world.terrain.chunk_at(at.x, at.y), spec)
	await simulate(Salvage.SETTLE_SECONDS + 0.5)
	await _check(body, tally, worst, spec)
	salvage.claim(body)
	body.free()


func _check(body: RigidBody3D, tally: Dictionary, worst: Dictionary, laid := {}) -> void:
	var spec := spec_of(body) if laid.is_empty() else laid
	var label: String = body.get(&"label")
	var all := corners(body)
	var low := INF
	var high := -INF
	var showing := INF
	for c in all:
		low = minf(low, c.y)
		high = maxf(high, c.y)
	var middle := body.global_transform * Finds.bounds(body).get_center()
	var sand := world.height_under(middle)
	if spec.bury > 0.0:
		tally.buried += 1
		tally.deep += 1 if spec.layer == Finds.DEEP else 0
		var tall := high - low
		var error := absf((sand - low) - Finds.depth(spec, tall))
		worst.depth = maxf(worst.depth, error)
		# How far its top shows over the sand right under it.
		for c in all:
			if c.y > high - 0.02:
				showing = minf(showing, c.y - world.height_under(c))
		var reached := await _can_take(body, middle, high)
		if not body.freeze or error > 0.01 or showing < Finds.SHOWING * 0.5 or low > sand or not reached:
			tally.out += 1
			printerr("buried %s: frozen %s, depth off %.3f m, top shows %.3f m, lowest %.3f under, takeable %s"
				% [label, body.freeze, error, showing, sand - low, reached])
		return
	tally.loose += 1
	var rest := INF
	if spec.has("floor"):
		tally.floor += 1
		rest = low - spec.floor
	else:
		for c in all:
			rest = minf(rest, c.y - world.height_under(c))
	worst.rest = maxf(worst.rest, absf(rest))
	if not body.freeze or rest < -World.SAND_SLOP or rest > 0.03 or middle.y < sand:
		tally.out += 1
		printerr("loose %s: settled %s, resting %.3f m off what's under it" % [label, body.freeze, rest])


## Whether your hands, standing beside it on the sand, take it when you look
## at the part of it that shows.
func _can_take(body: RigidBody3D, middle: Vector3, top: float) -> bool:
	var sand := world.height_under(middle)
	var aim := Vector3(middle.x, (sand + top) * 0.5 + 0.02, middle.z)
	for k in SIDES:
		var off := Vector3(EYE_OFF, 0.0, 0.0).rotated(Vector3.UP, k * TAU / SIDES)
		var eye_at := aim + off
		eye_at.y = maxf(world.height_under(eye_at) + 1.0, aim.y + 0.4)
		look(eye_at, aim)
		await simulate(1.0 / 60.0)
		hands._look()
		if hands.look_part == body or hands.look_device == body:
			return true
	return false
