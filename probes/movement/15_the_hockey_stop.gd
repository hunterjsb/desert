extends MovementProbe
## Movement probe 15: move back alone is a hockey stop. From rest it never
## moves you; riding, the board swings across your way and its edge digs in,
## stopping you far shorter than coasting, never reversing you or turning you
## off your line, even with your view turned off your way.


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 30.0)
	var across := Vector2(1.0, 0.0)
	await place(flat.x - 20.0, flat.z, across)
	await ride_here()
	hold(["move_back"])
	var seen := {"fastest": 0.0}
	await ride_for(3.0, func() -> void: seen.fastest = maxf(seen.fastest, flat_speed()))
	print("move back from rest on %.1f° sand: %.2f m/s at most" % [flat.degrees, seen.fastest])
	check(seen.fastest < 0.3, "from rest, move back never moves you (%.2f m/s)" % seen.fastest)

	var coast := await _stop(flat, [], 0.0)
	print("coasting from %.1f m/s: %.1f m in %.1f s" % [coast.from, coast.went, coast.took])
	for turned: float in [0.0, 0.6]:
		var run := await _stop(flat, ["move_back"], turned)
		print("stopping from %.1f m/s, view %.0f° off your way: %.1f m in %.2f s, the board %.0f° across, %.2f m off the line, %.2f m/s back at most"
			% [run.from, rad_to_deg(turned), run.went, run.took, rad_to_deg(run.across), run.off, run.back])
		check(run.took < 2.0 and run.went < coast.went * 0.25, "it stops you far shorter than coasting (%.1f m against %.1f)"
			% [run.went, coast.went])
		check(run.across > deg_to_rad(70.0), "the board swings across your way (%.0f°)" % rad_to_deg(run.across))
		check(run.back < 0.1 and run.off < 1.0, "and never reverses you or turns you off your line (%.2f m/s back, %.2f m off)"
			% [run.back, run.off])
	set_rate(60)


## Up to speed along +x on a fresh board, then `keys` with your view turned
## `turned` off your way, until you stop or 30 s pass: {from, went, took,
## across, off, back}.
func _stop(flat: Dictionary, keys: Array, turned: float) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 20.0, flat.z, Vector2(1.0, 0.0))
	await ride_here()
	hold(["move_forward"])
	await ride_for(2.5)
	var way := Vector2(player.velocity.x, player.velocity.z)
	var from := where()
	var line := way.normalized()
	face(line.rotated(turned))
	hold(keys)
	var run := {"from": way.length(), "went": 0.0, "took": INF, "across": 0.0, "off": 0.0, "back": 0.0, "t": 0.0}
	var each := func() -> void:
		if run.took < INF:
			return
		run.t += 1.0 / ticks_per_second()
		var v := Vector2(player.velocity.x, player.velocity.z)
		var gone := where() - from
		run.back = maxf(run.back, -v.dot(line))
		run.off = maxf(run.off, absf(Vector2(gone.x, gone.z).cross(line)))
		var off := absf(line.angle_to(player.ride.ahead))
		run.across = maxf(run.across, minf(off, PI - off))
		if v.length() < 0.1:
			run.took = run.t
			run.went = Vector2(gone.x, gone.z).length()
	while run.took == INF and run.t < 30.0 and player.ride != null:
		await ride_for(0.25, each)
	if run.took == INF:
		var gone := where() - from
		run.took = run.t
		run.went = Vector2(gone.x, gone.z).length()
	hold([])
	return run
