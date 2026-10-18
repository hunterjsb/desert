extends ShieldProbe
## Survival probe 16: only a still camp sleeps. In a full storm, under a
## running shield with a crate floating beside you, you can. With the crate
## swinging, or set swinging as the screen goes dark, or with you out in the
## storm, you can't: it says why, and no night passes.

const AWAY := 20.0


func run() -> void:
	await load_storm(1.0)
	var sleep := world.sleep
	shield_at(ahead(1.0))
	var crate := spawn_device(&"crate_frame", 3.0, world.tuning.hover_height, false)
	fit_part(crate, &"hover_tray")
	fit_part(crate, &"battery")
	await live(3.0, 1.0)
	check(sleep.refusal() == "", "still, under the shield, you can sleep (%s)" % sleep.refusal())

	crate.linear_velocity = Vector3(1.5, 0.0, 0.0)
	await _refused(func() -> void: pass)
	await _settle(crate)
	check(sleep.refusal() == "", "settled again (%s)" % sleep.refusal())
	await _refused(func() -> void: pass)

	await _settle(crate)
	world.player.global_position += Vector3(AWAY, 0.0, 0.0)
	await _refused(func() -> void: pass, "no shield")


func _settle(crate: Device) -> void:
	crate.linear_velocity = Vector3.ZERO
	crate.angular_velocity = Vector3.ZERO
	await live(3.0, 1.0)


## Falling asleep with `meanwhile` done as the screen goes dark: no night
## passes, and use's line says why.
func _refused(meanwhile: Callable, why := "moving") -> void:
	var from := world.time
	world.time_warp = 1.0
	world.sleep.fall_asleep(Sleep.HOURS, 8)
	await physics_frames(5)
	meanwhile.call()
	while world.sleep.sleeping:
		await get_tree().physics_frame
	world.time_warp = 0.0
	var said := world.player.hands.notice
	check(world.time - from < 5.0 and said.ends_with(why), "no night passes, and it says why (%.0f s, %s)"
		% [world.time - from, said])
