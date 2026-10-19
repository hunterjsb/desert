extends DeckProbe
## Devices & mods probe 42: the wind streamer points downwind and flaps by
## the wind's strength. In your hand, in still air it hangs; in a breeze it
## streams out downwind, flapping; in a gale it stands out level, flapping
## wider and faster. Stuck on a deck sailing through still air it streams
## aft, off the air the deck goes through: a telltale. In your suit it reads
## the air where you are, less your way.

const BREEZE := 5.0
const GALE := 16.0


func run() -> void:
	await load_lines()
	var streamer := Catalog.device(&"streamer") as Streamer
	world.content.add_child(streamer)
	streamer.global_position = eye() + Vector3(0.3, -0.3, -0.5)
	hands.hold(streamer)
	await simulate(0.5)
	var still := await _read(streamer, Vector2.ZERO)
	var breeze := await _read(streamer, Vector2(BREEZE, 0.0))
	var gale := await _read(streamer, Vector2(GALE, 0.0))
	for each: Array in [["still air", still], ["%.0f m/s" % BREEZE, breeze], ["%.0f m/s" % GALE, gale]]:
		var r: Dictionary = each[1]
		print("in %s its cloth lies %.0f° below level, %.0f° off downwind, flapping %.2f m wide %.1f times a second"
			% [each[0], r.down, r.off, r.wide, r.hz])
	check(still.down > 70.0, "in still air it hangs (%.0f° below level)" % still.down)
	check(breeze.off < 25.0 and breeze.down < 55.0, "in a breeze it streams out downwind")
	check(gale.off < 15.0 and gale.down < 20.0, "in a gale it stands out level downwind")
	check(gale.wide > breeze.wide and gale.hz > breeze.hz, "flapping wider and faster the harder it blows")

	# Stuck on a deck going through still air.
	hands.drop()
	await simulate(0.3)
	blow(Vector2.ZERO)
	var deck := piece(flat_spot(0.0, -8.0, 3.0) + Vector3.UP * 0.3)
	await simulate(1.0)
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.3, 0.0), 0.0, streamer)
	deck.freeze = true
	var going := Vector3(0.0, 0.0, -4.0)
	var aft := {"off": 0.0, "n": 0}
	await simulate(2.0, func() -> void:
		deck.global_position += going / 60.0
		deck.linear_velocity = going
		var way := _cloth_way(streamer)
		aft.off += rad_to_deg(Vector2(way.x, way.z).angle_to(Vector2(-going.x, -going.z))) / 120.0)
	print("on a deck going 4 m/s through still air, its cloth streams %.0f° off straight aft" % absf(aft.off))
	check(absf(aft.off) < 25.0, "stuck on a moving deck it streams aft: a telltale")
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.part(&"battery"))
	deck.unstick(deck.seat_of(streamer))

	# In your suit.
	streamer.global_position = eye() + Vector3(0.3, -0.3, -0.5)
	hands.hold(streamer)
	await simulate(0.3)
	check(world.player.suit.put_in(), "it goes in your suit")
	blow(Vector2(BREEZE, 0.0))
	await simulate(1.0)
	var felt := streamer.air
	print("in your suit it reads %.1f m/s from %.0f° off the wind" % [felt.length(), rad_to_deg(Vector2(felt.x, felt.z).angle_to(Vector2(1.0, 0.0)))])
	check(absf(felt.length() - BREEZE) < 1.0 and Vector2(felt.x, felt.z).angle_to(Vector2(1.0, 0.0)) < 0.3,
		"in your suit it reads the air where you are")


## Its cloth over two seconds in a wind: how far below level it lies, how far
## off downwind it points, how wide its end flaps and how often, Hz.
func _read(streamer: Streamer, along: Vector2) -> Dictionary:
	blow(along)
	await simulate(1.5)
	var down := 0.0
	var off := 0.0
	var lo := INF
	var hi := -INF
	var crossings := 0
	var last := 0.0
	var mean := 0.0
	var sides: Array[float] = []
	for k in 120:
		await get_tree().physics_frame
		await get_tree().process_frame
		var way := _cloth_way(streamer)
		down += rad_to_deg(asin(clampf(-way.y, -1.0, 1.0))) / 120.0
		if along != Vector2.ZERO:
			off += rad_to_deg(absf(Vector2(way.x, way.z).angle_to(along))) / 120.0
		var side := _cloth_end(streamer).z
		sides.append(side)
		mean += side / 120.0
	for side in sides:
		lo = minf(lo, side)
		hi = maxf(hi, side)
		var now := side - mean
		crossings += int(now * last < 0.0)
		last = now
	return {"down": down, "off": off, "wide": hi - lo, "hz": crossings * 0.5 / 2.0}


## Which way the cloth runs from the wand's tip to its end, the world's.
func _cloth_way(streamer: Streamer) -> Vector3:
	return (_cloth_end(streamer) - streamer.global_transform * streamer.tip()).normalized()


func _cloth_end(streamer: Streamer) -> Vector3:
	var last: MeshInstance3D = streamer.cloth()[-1]
	return last.global_transform * Vector3(0.0, Streamer.PIECE * 0.5, 0.0)
