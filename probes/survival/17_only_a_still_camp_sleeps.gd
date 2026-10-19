extends ShieldProbe
## Survival probe 17: only a still camp sleeps. In a full storm, under a
## running shield with a deck floating beside you, you can. With the deck
## swinging, or set swinging as the screen goes dark, or with you out in the
## storm, you can't: it says why, naming what moves, and no night passes. The
## bedroll goes down whatever the camp does: with the deck swinging, use in
## your hands lays it out on the sand, and use on it then says the deck's
## still moving.

const AWAY := 20.0
const MOVING := "the deck's still moving"


func run() -> void:
	await load_storm(1.0)
	var sleep := world.sleep
	shield_at(ahead(1.0))
	var deck := spawn_device(&"chassis", 3.0, world.tuning.hover_height, false)
	fit_part(deck, &"hover_tray")
	fit_part(deck, &"battery")
	await live(3.0, 1.0)
	check(sleep.refusal() == "", "still, under the shield, you can sleep (%s)" % sleep.refusal())

	deck.linear_velocity = Vector3(1.5, 0.0, 0.0)
	await _refused(func() -> void: pass)
	await _settle(deck)
	check(sleep.refusal() == "", "settled again (%s)" % sleep.refusal())
	await _refused(func() -> void: deck.apply_central_impulse(Vector3(0.0, 0.0, deck.mass)))

	await _settle(deck)
	await _lay_bedroll(deck)

	await _settle(deck)
	world.player.global_position += Vector3(AWAY, 0.0, 0.0)
	await _refused(func() -> void: pass, "no shield")


func _settle(deck: Device) -> void:
	deck.linear_velocity = Vector3.ZERO
	deck.angular_velocity = Vector3.ZERO
	await live(3.0, 1.0)


## Facing away from the camp, looking down at the sand ahead, a bedroll in
## your hands: use lays it there with the deck swinging, and use on it
## then is refused.
func _lay_bedroll(deck: Device) -> void:
	var player := world.player
	var hands := player.hands
	var bedroll := Catalog.device(&"bedroll")
	world.content.add_child(bedroll)
	bedroll.global_position = player.camera.global_position + Vector3(0.0, -0.3, -0.5)
	hands.hold(bedroll)
	await live(0.5, 1.0)
	player.rotation.y = PI / 2.0
	player.camera.rotation.x = -0.9
	deck.linear_velocity = Vector3(1.5, 0.0, 0.0)
	await physics_frames(1)
	hands.interact()
	await live(1.0, 1.0)
	var off := bedroll.global_position - player.global_position
	check(hands.held == null and Vector2(off.x, off.z).length() < world.tuning.reach and off.x < 0.0
		and clearance(bedroll) < 0.2, "the bedroll is laid on the sand ahead with the deck swinging (%.2f m up)"
		% clearance(bedroll))
	var from := world.time
	deck.linear_velocity = Vector3(1.5, 0.0, 0.0)
	await physics_frames(1)
	hands.interact()
	check(hands.notice == MOVING and world.time - from < 1.0 and not world.sleep.sleeping,
		"use on it says %s (%s)" % [MOVING, hands.notice])


## Falling asleep with `meanwhile` done as the screen goes dark: no night
## passes, and use's line says why.
func _refused(meanwhile: Callable, why := MOVING) -> void:
	var from := world.time
	world.time_warp = 1.0
	world.sleep.fall_asleep(Sleep.HOURS, 8)
	await physics_frames(5)
	meanwhile.call()
	while world.sleep.sleeping:
		await get_tree().physics_frame
	world.time_warp = 0.0
	var said := world.player.hands.notice
	check(world.time - from < 5.0 and said == why, "no night passes, and it says why (%.0f s, %s)"
		% [world.time - from, said])
