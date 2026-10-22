class_name SurveyorArrival
extends Node
## One saved Surveyor opening: the cabin, the seated fall and the landing. Physics owns its
## time; the view is drawn every frame from that saved time, so a resume never replays it.
const PHASES: Array[StringName] = [&"ejection", &"descent", &"entry", &"landing", &"recovery"]
var world: World
var restoring := false
var preflight: SurveyorPreflight
var _view: ArrivalView
var _hold: PlayerHold


func start() -> void:
	if world.arrival_state.is_empty():
		world.arrival_state = _fresh()
	restore()


func _fresh() -> Dictionary:
	return {"version": SurveyorManifest.VERSION, "seed": world.run_seed, "phase": &"preflight",
		"flight_warp": world.time_warp, "materialized": false}


func restore() -> void:
	restoring = false
	var state := world.arrival_state
	if state.is_empty():
		cancel()
		return
	# Development builds once flew without the cabin; nothing of an unlanded one exists.
	if not state.has("preflight"):
		if state.get("materialized", false):
			state.phase = &"recovery"
		else:
			world.arrival_state = _fresh()
			state = world.arrival_state
	if preparing():
		if not is_instance_valid(preflight):
			preflight = SurveyorPreflight.new()
			add_child(preflight)
			preflight.setup(self)
		_run(false)
		return
	if is_instance_valid(preflight):
		preflight.dispose()
	preflight = null
	if active():
		_take()
		if state.get("phase") == &"landing" and state.get("materialized", false):
			seat_in_pod()
		_show(0.0)
		_run(true)
	else:
		_release()
		_run(false)


func _run(on: bool) -> void:
	set_physics_process(on)
	set_process(on)


## The actual launch action owns its one-shot; restoration only resumes the flight.
func launch_sound() -> void:
	if is_instance_valid(_view):
		_view.launch_sound()


func recover(body: Node) -> void:
	if world.get_meta(&"arrival_restoring", false) or active() or not is_instance_valid(body):
		return
	var uid: StringName = body.get_meta(&"arrival_uid", &"")
	if uid == &"":
		return
	for entry: Dictionary in world.arrival_state.get("structure", []) + world.arrival_state.get("equipment", []):
		if entry.uid == uid and entry.survives and not entry.recovered:
			entry.recovered = true
			Deeds.done(world, &"first_recovery")
			return


func active() -> bool:
	return not world.arrival_state.is_empty() and world.arrival_state.get("phase", &"recovery") != &"recovery"


func preparing() -> bool:
	return world != null and world.arrival_state.get("phase", &"") == &"preflight"


func interact() -> bool:
	return preparing() and is_instance_valid(preflight) and preflight.interact()


func take() -> bool:
	return preparing() and is_instance_valid(preflight) and preflight.take()


func hint() -> String:
	return preflight.hint() if preparing() and is_instance_valid(preflight) else ""


## The sealed pod is carried by the arrival, not left to surface streaming.
func transports(body: RigidBody3D) -> bool:
	if not active() or not body.has_meta(&"arrival_uid"):
		return false
	if preparing():
		return true
	if world.arrival_state.get("materialized", false):
		return false
	var uid: StringName = body.get_meta(&"arrival_uid")
	for entry: Dictionary in world.arrival_state.get("structure", []) + world.arrival_state.get("equipment", []):
		if StringName(entry.uid) == uid:
			return true
	return false


func prepare_restore() -> void:
	if is_instance_valid(preflight):
		preflight.dispose()
	preflight = null
	_release()


func cancel() -> void:
	prepare_restore()
	_run(false)


func _physics_process(delta: float) -> void:
	if restoring or world == null or world.get_meta(&"arrival_restoring", false) or not active():
		return
	var state := world.arrival_state
	if state.phase == &"landing":
		seat_in_pod()
	state.flight_elapsed = minf(float(state.get("flight_elapsed", 0.0)) + delta, float(state.preflight.flight_s))
	world.time = float(state.preflight.departure_time) + float(state.flight_elapsed)
	state.elapsed = float(state.get("elapsed", 0.0)) + delta
	var phase: StringName = state.phase
	var duration := _seconds(phase)
	state.phase_seconds = duration
	state.progress = clampf(state.elapsed / maxf(duration, 0.001), 0.0, 1.0)
	if state.elapsed < duration:
		return
	if phase == &"entry" and not (world.terrain.is_settled_around(state.landing_world.x, state.landing_world.y) and _land()):
		state.elapsed = duration
		return
	state.phase = PHASES[PHASES.find(phase) + 1]
	state.elapsed = 0.0
	state.progress = 0.0
	state.phase_seconds = _seconds(state.phase)
	if state.phase == &"recovery":
		_release()
		_run(false)
		var line := Controls.key_for(&"move_forward") + " · crawl out"
		if is_zero_approx(world.weather.day.sun_shown(world.time)):
			line = Controls.key_for(&"headlamp") + " · headlamp"
		world.player.hands.say(line)


## Drawn every frame, a fraction of a tick ahead of the saved time it samples.
func _process(_delta: float) -> void:
	if restoring or world == null or world.get_meta(&"arrival_restoring", false) or not active():
		return
	_show(Engine.get_physics_interpolation_fraction() / Engine.physics_ticks_per_second)


func _seconds(phase: StringName) -> float:
	var profile: Dictionary = world.arrival_state.preflight.get("profile", {})
	match phase:
		&"ejection": return world.tuning.arrival_ejection_s
		&"descent": return maxf(float(profile.get("descent_s", 1.0)), 0.0)
		&"entry": return maxf(float(profile.get("entry_s", 1.0)), 0.0)
		&"landing": return world.tuning.arrival_landing_s
	return 0.0


func _land() -> bool:
	var state := world.arrival_state
	if not state.get("materialized", false):
		var counting := world.counts_deeds
		world.counts_deeds = false
		world.arrival_nodes = SurveyorRecovery.land(world, state)
		world.counts_deeds = counting
		if not state.get("materialized", false):
			return false
	seat_in_pod()
	world.set_meta(&"kit", world.arrival_nodes.values().filter(func(node: Node) -> bool: return is_instance_valid(node)))
	return true


## Prone over the landed pod's seat, facing its burst exit.
func seat_in_pod() -> void:
	var floor := world.arrival_nodes.get(&"floor_a") as Chassis
	if not is_instance_valid(floor):
		return
	var deck := floor.deck if floor.deck != null else floor
	world.teleport(world.player, deck.global_transform * floor.pose() * PodShell.landed_pose(world.tuning))
	world.player.restore_ground_pose(&"prone")
	world.player.camera.position = Vector3(0, world.tuning.arrival_seat_eye_m, 0)
	world.player.camera.rotation = Vector3(0.1, 0, 0)
	world.player.velocity = Vector3.ZERO


func _take() -> void:
	if _hold != null and _hold.held():
		return
	_hold = PlayerHold.new(world.player)
	_hold.take(PlayerHold.ALL)
	world.time_warp = 0.0


func _release() -> void:
	if is_instance_valid(_view):
		_view.dispose()
	_view = null
	if _hold == null or not _hold.held():
		return
	_hold.release()
	world.time_warp = float(world.arrival_state.get("flight_warp", 1.0))


func _show(lead: float) -> void:
	if not is_instance_valid(_view):
		_view = ArrivalView.new()
		add_child(_view)
		_view.setup(world)
	_view.present(world.arrival_state, lead)
