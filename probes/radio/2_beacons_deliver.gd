extends SalvageProbe
## Radio probe 2: beacons deliver. Tuned to the beacon out in the dunes, a
## radio gives a bearing. Carried along it a hop at a time, it keeps pointing
## on until you've walked past what it points at, and there, once its chunk
## has loaded, lies the find it named, where it said. The beacon's choice is
## the seed's alone: on a moon as stormy as it gets, the same place hears the
## same beacon, and its find is there too.
## Time limit: 600 s

## Where the walk starts, m from where the run began, out of sight of any ruin
## a beacon is in; and each hop, m.
const OUT := Vector2(-1500.0, 0.0)
const HOP := 100.0
const MOST_HOPS := 40


func run() -> void:
	await load_salvage()
	var heard := await _follow()
	if heard.is_empty():
		return

	# The whole moon in a storm as hard as storms get, all along: every chunk
	# has been as exposed as it can be.
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	Tuning.current().storm_threshold = -2.0
	await load_salvage()
	var radio := await _carried(world.spawn + OUT)
	check(radio.target == heard, "on a stormy moon the same place hears the same beacon")
	await go(heard.x, heard.z + 6.0)
	check(_named(heard) != null, "and its find is there too")


## Tunes in out in the dunes and follows the bearing; what the beacon named,
## or {} if it led nowhere.
func _follow() -> Dictionary:
	var at := world.spawn + OUT
	var radio := await _carried(at)
	var heard := radio.target.duplicate()
	check(not heard.is_empty(), "a beacon is in reach")
	if heard.is_empty():
		return {}
	var from := Vector2(heard.x, heard.z).distance_to(at)
	var bearing := radio.beacon_bearing()
	var hops := 0
	var passed := false
	while hops < MOST_HOPS and not passed:
		at += Vector2(sin(deg_to_rad(bearing)), -cos(deg_to_rad(bearing))) * HOP
		await _carry(radio, at)
		hops += 1
		var now := radio.beacon_bearing()
		passed = absf(angle_difference(deg_to_rad(now), deg_to_rad(bearing))) > PI / 2.0
		bearing = now
	print("tuned in %.0f m off, walked past it in %d hops of %d m" % [from, hops, HOP])
	check(from > 2.0 * HOP and passed, "the bearing led there: walked past it in %d hops" % hops)
	var find := _named(heard)
	check(find != null, "the find it named lies there once its chunk is loaded")
	if find != null:
		var off := Vector2(world.world_x(find.global_position.x), world.world_z(find.global_position.z)) \
			- Vector2(heard.x, heard.z)
		check(off.length() < 1.0, "where the beacon points (%.2f m off)" % off.length())
	return heard


## A radio with a battery, in your hands at a world place, tuned to the beacon there.
func _carried(at: Vector2) -> Radio:
	await go(at.x, at.y)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 1.0]) as Radio
	radio.freeze = true
	await _carry(radio, at)
	while radio.channel != Radio.BEACON:
		radio.sweep()
	return radio


func _carry(radio: Radio, at: Vector2) -> void:
	await go(at.x, at.y)
	radio.global_position = world.player.global_position + Vector3.UP


## The find of a loaded chunk's plan the beacon named, lying there; or null.
func _named(heard: Dictionary) -> RigidBody3D:
	for body in salvage.finds():
		var from: Array = body.get_meta(&"find")
		if from[0] == heard.coord and from[1] == heard.index:
			return body
	return null
