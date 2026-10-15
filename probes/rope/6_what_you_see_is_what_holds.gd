extends LineProbe
## Rope & tethering probe 6: what you see is what holds. Lines laid through
## your hands (a stake taken up and driven into the sand where you look, a
## coil picked up, its first end snapped onto a floating planter's hook, the
## rest paid out as you walk to the stake and snapped onto its ring), and one
## taken back off its stake into your hand, in a wind that
## rises from calm through a breeze to a gusting storm, through which you tow
## the line in your hand back and forth. Every drawn frame each strand's ends
## sit on its line's attachment points, held or not, and its drawn length
## matches the line. A hanging line sags as far as its weight and pull say:
## lightly loaded it droops, under real load it runs straight.

## Drawn ends this close to their rings, m; drawn length this close to the
## line's, as a share of it; drawn sag this close to the weight's, m.
const ON_RING := 0.01
const LENGTH := 0.03
const SAG := 0.02
## Real load, as a share of a line's strength, runs this straight: sag as a
## share of the span. A light load droops at least this much.
const LOADED := 0.15
const STRAIGHT := 0.01
const LIGHT := 0.03
const DROOPS := 0.015

var _seen := {"frames": 0, "ring": 0.0, "length": 0.0, "sag": 0.0, "loaded": 0, "bent": 0.0,
	"light": 0, "droop": INF}


## Runs after every other node's _process in a frame.
class LastInFrame extends Node:
	var each: Callable

	func _ready() -> void:
		process_priority = 1000

	func _process(_delta: float) -> void:
		each.call()


func run() -> void:
	await load_lines()
	speed_up(2)
	# Downwind is +z: planters float downwind of their stakes.
	var planter := floating(&"planter", spot(-2.0, -2.0))
	var other := floating(&"planter", spot(3.0, -2.0))
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.global_transform = Transform3D(Basis(Vector3.BACK, PI / 2.0), spot(-1.2, -5.0) + Vector3.UP * 0.04)
	var far_stake := driven_stake(spot(3.0, -9.0))
	var coil := Line.make(world, world.tuning.rope_coil_length)
	coil.coil.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), spot(-1.2, -3.2) + Vector3.UP * 0.05)
	look(spot(-1.2, -4.2) + Vector3.UP * 1.65, coil.coil.global_position)
	await simulate(1.0)

	# A stake taken up and driven with use where you look.
	check(await take(stake), "you take up a stake")
	await simulate(0.4)
	look(spot(-2.0, -7.5) + Vector3.UP * 1.65, spot(-2.0, -9.0))
	await simulate(0.1)
	check(hands.interact() and stake.driven and hands.held == null, "F drives it into the sand where you look")
	look(spot(-1.2, -4.2) + Vector3.UP * 1.65, coil.coil.global_position)
	await simulate(0.2)

	# Laid through the hands, ring to ring.
	check(await take(coil.coil), "you pick up the coil")
	await simulate(0.3)
	check(hands.held != null and hands.held.has_meta(&"line"), "and hold its first end")
	check(await snap_onto(planter.free_tie(stake.global_position)), "its first end snaps onto the planter's hook")
	await simulate(0.3)
	check(coil.state == Line.State.PAYING and hands.held == coil.ends[1], "the coil comes to your hand, paying out")
	await walk_to(stake.global_position + Vector3(0.6, 0.0, 0.8))
	check(await snap_onto(stake.free_tie(planter.global_position)), "its other end snaps onto the stake's ring")
	var span := coil.rope.a.global_position.distance_to(coil.rope.b.global_position)
	var laid := coil.rope.length
	await walk_to(stake.global_position + Vector3(2.0, 0.0, 0.0))
	print("laid through the hands: a %.2f m line between rings %.2f m apart, %s"
		% [laid, span, Line.State.keys()[coil.state]])
	check(coil.state == Line.State.LAID and absf(laid - span - world.tuning.rope_pay_slack) < 0.05,
		"laid at the length it paid out to")
	check(coil.rope.length == laid, "and that length is set")

	# The other planter's line, taken off its stake into your hand.
	var held := lay(other, far_stake, 0.4)
	look(far_stake.global_position + Vector3(0.0, 1.4, 0.9), far_stake.global_position + Vector3.UP * 0.45)
	await simulate(0.3)
	check(hands.grab(), "you take a line's end off a stake")
	await simulate(0.5)
	check(hands.held == held.ends[1] and held.state == Line.State.LAID, "and hold it")
	var watch := LastInFrame.new()
	watch.each = _watch
	add_child(watch)

	for phase: Array in [["calm", 0.0, 0.0, 6.0], ["breeze", wind.breeze_speed(), 0.0, 12.0],
			["storm", wind.storm_speed(), world.tuning.gust_storm_strength, 10.0]]:
		blow(Vector2(0.0, phase[1]), phase[2])
		await simulate(phase[3])
		print("%-6s %s" % [phase[0], "  ".join(ropes.ropes.map(func(r: Rope) -> String:
			return "%d%% %.2fm sag" % [roundi(r.share() * 100.0), _drawn_sag(r.strand.points)]))])
	# Towing it across the wind and back, the end in your hand moving with you.
	var from := world.player.global_position
	for leg in [Vector3(-3.0, 0.0, 0.0), Vector3.ZERO]:
		await walk_to(from + leg)
	watch.queue_free()
	print("%d frames: drawn ends at most %.4f m off their rings, length %.2f%% off, sag %.4f m off its weight's;"
		% [_seen.frames, _seen.ring, _seen.length * 100.0, _seen.sag]
		+ " loaded lines sag at most %.2f%% of the span (%d seen), light ones at least %.2f%% (%d seen)"
		% [_seen.bent * 100.0, _seen.loaded, _seen.droop * 100.0, _seen.light])
	check(_seen.ring < ON_RING, "drawn ends sit on their rings every frame, held or not (%.4f m)" % _seen.ring)
	check(_seen.length < LENGTH, "the drawn length matches the line (%.2f%%)" % (_seen.length * 100.0))
	check(_seen.sag < SAG, "a hanging line sags as far as its weight and pull say (%.4f m)" % _seen.sag)
	check(_seen.loaded > 0 and _seen.bent < STRAIGHT, "under real load a line runs straight")
	check(_seen.light > 0 and _seen.droop > DROOPS, "lightly loaded, it droops")


func _watch() -> void:
	_seen.frames += 1
	for rope in ropes.ropes:
		var points := rope.strand.points
		var n := points.size()
		_seen.ring = maxf(_seen.ring, maxf(points[0].distance_to(rope.a.global_position),
			points[n - 1].distance_to(rope.b.global_position)))
		var chord := points[0].distance_to(points[n - 1])
		var drawn := 0.0
		for i in n - 1:
			drawn += points[i].distance_to(points[i + 1])
		_seen.length = maxf(_seen.length, absf(drawn - maxf(rope.length, chord)) / rope.length)
		var sag := _drawn_sag(points)
		if is_finite(rope.sag) and rope.sag / chord < RopeStrand.HANG_TIGHT and not _on_sand(points):
			_seen.sag = maxf(_seen.sag, absf(sag - rope.sag))
		if rope.share() >= LOADED:
			_seen.loaded += 1
			_seen.bent = maxf(_seen.bent, sag / chord)
		elif rope.is_taut() and rope.share() < LIGHT and rope.share() > 0.005:
			_seen.light += 1
			_seen.droop = minf(_seen.droop, sag / chord)


## How far the drawn middle hangs off the line between the drawn ends.
func _drawn_sag(points: PackedVector3Array) -> float:
	var n := points.size()
	var middle := points[(n - 1) / 2]
	var from := points[0]
	var along := (points[n - 1] - from).normalized()
	var off := middle - from
	return (off - along * off.dot(along)).length()


func _on_sand(points: PackedVector3Array) -> bool:
	for p in points:
		if p.y < world.height_under(p) + RopeStrand.RADIUS + 0.005:
			return true
	return false
