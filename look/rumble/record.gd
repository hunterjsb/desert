extends Node
## Listen-test: a burst's build and boom recorded as heard, in the run's own
## weather on seed 1234. Near: the "vent" scenario, 1.5 km across the rift,
## from 35 s before a burst to 25 s after. Far: 12 km across the rift from the
## same vent, the next burst in clear air, from 10 s before it to 20 s after
## its boom comes.
## Each is the whole mix (near.wav, far.wav) and the rumble's own buses
## alone (near_booms.wav, near_vents.wav and the far ones), real time, for
## ffmpeg's ebur128 meter. Headless is enough, its mixer runs:
##   godot --headless --path . res://look/rumble/record.tscn -- <dir>

const WORLD_SCENE := preload("res://game/world/world.tscn")
const FAR := 12000.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://rumble"
	DirAccess.make_dir_recursive_absolute(out)
	var own := OS.get_temp_dir().path_join("sandgame-listen-%d" % OS.get_process_id())
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = own
	Tuning.current().run_seed = 1234
	var world: World = WORLD_SCENE.instantiate()
	add_child(world)
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle():
			break
	var scenario := Scenarios.by_key("vent")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	await Scenarios.lay(world, scenario, place)
	var geology := world.shape.history.geology
	var vent: Dictionary = geology.live()[0]
	var onset := geology.next_burst(vent, world.time)
	world.time = onset - 35.0
	await _record(world, out, "near", 60.0)

	# Across the rift from it, on fresh sand, for a burst in clear air.
	var far := Sphere.toward(vent.p, vent.bearing + PI * 0.5, FAR / geology.radius)
	world.travel(rad_to_deg(Sphere.latitude(far)), rad_to_deg(Sphere.longitude(far)), world.player.rotation.y)
	var x := world.player_world_x()
	var z := world.player_world_z()
	while not world.terrain.is_settled_around(x, z):
		await get_tree().physics_frame
	for i in 120:
		await get_tree().physics_frame
	var by := Sphere.angle(Sphere.point(world.moon.latitude, world.moon.longitude), vent.p) * geology.radius
	var delay := by / world.weather.rumbles.speed()
	onset = geology.next_burst(vent, onset + 1.0)
	while world.weather.field.storm_at(x, z, onset) > 0.0 or world.weather.field.storm_at(x, z, onset + delay) > 0.0:
		onset = geology.next_burst(vent, onset + 1.0)
	world.time = onset - 10.0
	print("rumble: far, %.0f m off, its boom %.1f s after it bursts" % [by, delay])
	await _record(world, out, "far", 10.0 + delay + 20.0)
	get_tree().quit()


## Records the mix and the rumble's buses for `seconds` of real time.
func _record(world: World, out: String, name: String, seconds: float) -> void:
	var whole := _recorder(&"Master")
	var booms := _recorder(Sounds.BOOMS)
	var vents := _recorder(Sounds.VENTS)
	var started := world.time
	var most := 0.0
	var ends := Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < ends:
		await get_tree().process_frame
		most = maxf(most, world.weather.rumbles.tremble)
	for each: AudioEffectRecord in [whole, booms, vents]:
		each.set_recording_active(false)
	whole.get_recording().save_to_wav(out.path_join("%s.wav" % name))
	booms.get_recording().save_to_wav(out.path_join("%s_booms.wav" % name))
	vents.get_recording().save_to_wav(out.path_join("%s_vents.wav" % name))
	for bus: StringName in [&"Master", Sounds.BOOMS, Sounds.VENTS]:
		var i := AudioServer.get_bus_index(bus)
		AudioServer.remove_bus_effect(i, AudioServer.get_bus_effect_count(i) - 1)
	print("rumble: %s, %.0f s of world time from %.0f, the ground trembling at most %.2f, the wind %.1f m/s" % [
		name, world.time - started, started, most, world.weather.wind.length()])


func _recorder(bus: StringName) -> AudioEffectRecord:
	var record := AudioEffectRecord.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index(bus), record)
	record.set_recording_active(true)
	return record
