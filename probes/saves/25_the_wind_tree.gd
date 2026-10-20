extends SailProbe
## Profile & saves probe 25: the wind's deeds, sailed. At the "yacht"'s helm in
## a steady 10 m/s, got going across the wind and then held 60° off it, its
## camp makes Close-Hauled's ground upwind and Land Yacht's from the helm; no
## storm about, no Storm Runner. On a front's outflow short of its wall, it
## runs on to Storm Runner. The goals are shortened to a probe's minute.

var kit: Array[Node3D] = []
var sampled := 0
var full := 0
var lowest := 1.0


func run() -> void:
	await load_sailing()
	var tuning := world.tuning
	tuning.deed_upwind_m = 25.0
	tuning.deed_yacht_m = 90.0
	tuning.deed_outflow_m = 80.0
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	speed_up(4)
	var way := heading()
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-way.x, -way.y)), open + Vector3.UP * 0.1))
	await physics_frames(5)
	kit = Scenarios.yacht(world)
	deck = kit[0]
	mast = kit[1]
	await physics_frames(30)
	blow(downwind * 10.0)
	deck.freeze = true
	player.set_physics_process(false)
	var winch: ManualWinch
	for body in deck.mounted():
		if body is ManualWinch:
			winch = body
	look(winch.global_position + winch.global_basis * Vector3(0, 0.6, 1.2), winch.global_position)
	Controls.mouse_free = false
	await physics_frames(2)
	for i in 16:
		press(&"reel_in")
	await simulate(5.0)
	deck.freeze = false
	player.set_physics_process(true)
	trim(60.0)
	await physics_frames(2)
	check(mast.raise == 1.0 and mast.halyard() != null, "the halyard holds the sail all the way up before sailing")
	check((kit[2] as Helm).interact(player), "you sit at the helm")
	driving_sheet = true
	tending = deg_to_rad(15.0)
	var ticks := [0]
	await simulate(30.0, func() -> void:
		_steer()
		sampled += 1
		full += int(mast.raise == 1.0)
		lowest = minf(lowest, mast.raise)
		ticks[0] += 1
		_hold(heading() if ticks[0] < 480 else heading(1, 30.0)))
	print("close-hauled: %.0f m upwind, %.0f m from the helm" % [mast.upwind_m, (kit[2] as Helm).sailed_m])
	check(profile.did("close_hauled") and profile.did("land_yacht"), "close-hauled from its helm: Close-Hauled and Land Yacht")
	check(not profile.did("storm_runner"), "no storm about, no Storm Runner")

	# A front's outflow everywhere, its wall never reached.
	tuning.storm_outflow_lead = 1000.0
	wind = RopeWind.new(world.run_seed, tuning)
	world.weather.field = wind
	blow(downwind * 10.0)
	await simulate(20.0, func() -> void:
		_steer()
		sampled += 1
		full += int(mast.raise == 1.0)
		lowest = minf(lowest, mast.raise)
		_hold(heading(1, -30.0)))
	print("on the outflow: %.0f m" % mast.outflow_m)
	check(profile.did("storm_runner"), "run on a front's outflow short of its wall: Storm Runner")
	_hold(Vector2.ZERO)
	print("fully hoisted while moving: %d/%d ticks, minimum %.12f" % [full, sampled, lowest])
	check(full == sampled and lowest == 1.0, "the actual wheel brake holds full height throughout both routes")
	speed_up(1)


## The helm's keys toward a heading, as you'd steer by eye.
func _hold(want: Vector2) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if want == Vector2.ZERO:
		return
	var ahead := -deck.global_basis.z
	var turn := clampf(-Vector2(ahead.x, ahead.z).angle_to(want) * 8.0, -1.0, 1.0)
	if turn > 0.01:
		Input.action_press("move_left", turn)
	elif turn < -0.01:
		Input.action_press("move_right", -turn)
