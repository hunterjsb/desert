extends "res://look/board_body_view/board_body_view.gd"
## The same low-frame-rate ride with an ordinary waist line towing a loose stake.
var line: Line
var samples := 0
var body_error := 0.0
var lead_error := 0.0
var fastest := 0.0

func run() -> void:
	RenderingServer.frame_post_draw.connect(_measure)
	await super.run()
	RenderingServer.frame_post_draw.disconnect(_measure)
	print("BOARD_WAIST ", JSON.stringify({"frames":samples,"body_board_error":body_error,
		"lead_error":lead_error,"speed":fastest,"render_cap":Engine.max_fps,
		"physics_hz":Engine.physics_ticks_per_second}))
	world.queue_free()
	world = null
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func load_moving(run_seed := 1234, salvage := false) -> void:
	Tuning.current().eye_adapts = false
	await super.load_moving(run_seed, salvage)
	world.time_warp = 0.0
	world.time = fposmod(0.42 - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) * world.tuning.day_minutes * 60.0

func ride_here(cell := &"battery", make := BoardMakes.ISSUE) -> Hoverboard:
	var board := await super.ride_here(cell, make)
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.global_position = player.global_position + Vector3(0.5, 0.4, 1.8)
	line = Line.to_waist(world, stake.free_tie(player.global_position), 2.0)
	player.hands.reel.choose(line.ends[1])
	return board

func _measure() -> void:
	if player == null or player.ride == null or line == null:
		return
	var wrap := player.body.get_node(^"WaistWrap") as WaistWrap
	if wrap._views.is_empty():
		return
	var origin := player.board.global_position + Vector3.UP * float(Catalog.DEVICES[&"board"].size.y) * 0.5
	body_error = maxf(body_error, player.body.global_position.distance_to(origin))
	var lead := wrap._views.values()[0][1] as MeshInstance3D
	lead_error = maxf(lead_error, lead.to_global(Vector3.UP).distance_to(world.ropes._shown_end(Line._tip(line.ends[1]))))
	fastest = maxf(fastest, player.ride.velocity.length())
	samples += 1
