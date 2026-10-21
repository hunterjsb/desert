extends HandsProbe
## Radio probe 30: carried, it plays in your ears as loud as held close. A
## radio playing in your hands, brought as near as it comes, goes in with
## what you carry, and what it plays sounds as loud as it did there, to
## within half a dB at one level (the relay's own fading aside), straight
## ahead of you: stowing it makes no jump. Turned round, it stays ahead of
## you, and no camera turn, however fast, pans it: its voices have no
## panning while it's carried, and it again once it's out. Taken out, its voices are back on the set, at its middle.


func run() -> void:
	await load_hands()
	var player := world.player
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	radio.global_position = player.global_position + Vector3.UP
	fit_part(radio, &"battery")
	hands.hold(radio)
	await physics_frames(30)
	while radio.channel != Radio.MUSIC:
		radio.sweep()
	hands.scroll(100)
	await physics_frames(60)
	var nearest := hands.nearest_hold_of(radio)
	var level := radio.music.volume_db
	var held := _heard(radio.music, level)
	print("held at %.2f m (nearest %.2f): music %.1f dB" % [_far(radio.music), nearest, held])
	check(radio.playing() and absf(_far(radio.music) - nearest) < 0.1, "held as near as it comes, it plays")

	check(player.suit.put_in() and radio.carried(), "it goes in with what you carry")
	await physics_frames(5)
	var carried := _heard(radio.music, level)
	print("carried: music %.1f dB, %.2f m off, %.3f of it ahead" % [carried, _far(radio.music), _ahead(radio.music)])
	check(radio.playing() and absf(carried - held) < 0.5, "carried, it's as loud as held close (%.1f against %.1f dB)"
		% [carried, held])
	check(_ahead(radio.music) > 0.999, "and straight ahead of you")
	player.rotate_y(PI * 0.5)
	await physics_frames(3)
	check(_ahead(radio.music) > 0.999 and absf(_heard(radio.music, level) - held) < 0.5, "turned round, it stays so")
	var flat := true
	for voice: AudioStreamPlayer3D in [radio.music, radio.hiss, radio.crackle, radio._signal]:
		flat = flat and voice.panning_strength == 0.0
	# Looked round between ticks: the camera alone turned, nothing re-placed yet.
	player.camera.rotate_object_local(Vector3.UP, 1.2)
	await get_tree().process_frame
	check(flat and _ahead(radio.music) > 0.999, "no camera turn pans it: no panning, and ahead again by the next frame")
	player.camera.rotate_object_local(Vector3.UP, -1.2)

	check(player.suit.take_out(stack_of(radio)) and not radio.carried(), "taken out again")
	await physics_frames(3)
	var middle := Hands.middle_of(radio)
	check(radio.music.position == middle and radio.hiss.position == middle and radio.music.panning_strength == 1.0,
		"its voices are back on the set, panning as anything in the world")


## How loud a voice reaches the listener, the camera, dB: Godot's inverse
## distance, capped at its max_db, for a voice at level `db`.
func _heard(voice: AudioStreamPlayer3D, db: float) -> float:
	var at := linear_to_db(1.0 / (_far(voice) / voice.unit_size + 0.00001)) + db
	return minf(at, voice.max_db)


func _far(voice: AudioStreamPlayer3D) -> float:
	return voice.global_position.distance_to(world.player.camera.global_position)


## How square ahead of the camera a voice is: 1 dead ahead.
func _ahead(voice: AudioStreamPlayer3D) -> float:
	var eyes := world.player.camera.global_transform
	return (voice.global_position - eyes.origin).normalized().dot(-eyes.basis.z.normalized())
