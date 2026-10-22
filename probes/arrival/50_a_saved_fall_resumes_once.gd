extends MenuProbe
## A fall saved to disk resumes on the same course with the same cargo, the head where
## you turned it; saved mid-impact it carries on without a second jolt or bang.

var _resumed := false


func run() -> void:
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var prep := await cabin()
	if prep == null:
		return
	await set_pulse(prep)
	await launch_pod(prep)
	await fly_to(&"descent")
	Controls.mouse_free = false
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(-4000, 1800)
	get_viewport().push_input(motion)
	await get_tree().process_frame
	var state := world.arrival_state
	var look: Vector2 = state.get("head_look", Vector2.ZERO)
	check(look.length() > 0.1 and absf(look.x) <= deg_to_rad(world.tuning.arrival_head_yaw_deg) + 0.0001,
		"looking turns the seated head within its reach")
	var course: Dictionary = state.preflight.flight_sample.duplicate(true)
	var cargo: Array = state.equipment.duplicate(true)
	var roles := _roles()
	check(main.save_run(), "the fall saves")
	await _resume()
	check(world.arrival_state.get("phase") == &"descent" and world.arrival_state.preflight.flight_sample == course
		and world.arrival_state.equipment == cargo and world.arrival_state.get("head_look") == look,
		"it resumes on the same course and cargo, the head still turned")
	check(_roles() == roles, "each saved pod body returns once")
	await fly_to(&"landing")
	check(main.save_run(), "the impact saves")
	var hit := float(world.arrival_state.elapsed)
	await _resume()
	var view := world.arrival._view
	check(world.arrival_state.get("phase") == &"landing" and float(world.arrival_state.elapsed) >= hit
		and is_instance_valid(view) and not view._voice.playing and not view._impact_roll.playing,
		"a saved impact carries on without replaying it")
	var landed := _roles()
	check(landed.all(func(uid: StringName) -> bool: return landed.count(uid) == 1 and roles.has(uid)), "no landed body is doubled")
	await fly_to(&"recovery")
	Controls.mouse_free = true


## Every body carrying a pod identity, doubles included, joined pieces and fittings too.
func _roles() -> Array:
	var roles := []
	var seen := {}
	var next: Array = world.content.get_children() + world.player.suit.carried
	while not next.is_empty():
		var node := next.pop_back() as Node
		if not is_instance_valid(node) or seen.has(node):
			continue
		seen[node] = true
		if node.has_meta(&"arrival_uid"):
			roles.append(node.get_meta(&"arrival_uid"))
		next.append_array(node.get_children())
		if node is Device:
			next.append_array(node.parts() + node.mounted())
		if node is Chassis:
			next.append_array(node.pieces())
	roles.sort()
	return roles


## Main's resume waits out the whole fall; the probe watches it come back instead.
func _resume() -> void:
	var old := world
	_resumed = false
	_run_resume()
	for i in 3600:
		world = main.world()
		if world != null and world != old and world.arrival != null and not world.get_meta(&"arrival_restoring", false) \
				and world.arrival.active() and is_instance_valid(world.arrival._view):
			return
		await get_tree().physics_frame
	check(false, "the saved fall comes back within a minute of ticks")


func _run_resume() -> void:
	await main.resume()
	_resumed = true
