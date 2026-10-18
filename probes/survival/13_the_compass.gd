extends HandsProbe
## Survival probe 13: the compass reads the moon's north. Held flat, its
## needle points north along the ground whichever way you face. Taken out
## of the inventory it's held up to read: the needle points up its card as
## you face north, and across to your right with north on your right. Carried,
## the inventory shows the same, live as you turn. Walk over a pole and the
## moon's north turns round, and the needle with it, in your hand and in the
## inventory. Tu's sway, a storm's swim and the needle's slow swing are
## tuned out here, so it reads true at once; probe 15 has them.

## How far off the needle may be, degrees.
const TRUE := 1.0


func run() -> void:
	get_window().size = Vector2i(1152, 648)
	await load_hands()
	world.tuning.compass_sway_degrees = 0.0
	world.tuning.compass_storm_degrees = 0.0
	world.tuning.compass_swing_seconds = 0.2
	world.tuning.compass_damping = 1.0
	var player := world.player
	var suit := player.suit
	var compass := Catalog.part(&"compass") as Compass
	world.content.add_child(compass)
	# Lying face up, as a find does, and taken up so.
	compass.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), player.global_position + Vector3.UP)
	hands.hold(compass)
	await physics_frames(30)
	var off := 0.0
	for yaw in [0.0, 90.0, 200.0]:
		player.rotation.y = deg_to_rad(yaw)
		await physics_frames(20)
		off = maxf(off, rad_to_deg(_flat(compass.needle.global_basis.y).angle_to(Vector3.FORWARD)))
	print("held flat, the needle is %.2f° off north at worst" % off)
	check(off < TRUE, "held flat, it points north whichever way you face")

	press(&"inventory")
	click_at(Vector2(576.0, 60.0))
	click_at(suit.tile_rect(stack_of(compass)).get_center())
	await physics_frames(30)
	check(hands.held == compass, "out of the inventory, it's in your hands")
	player.rotation.y = 0.0
	await physics_frames(20)
	var ahead := _reading(compass.needle.transform)
	player.rotation.y = deg_to_rad(90.0)
	await physics_frames(20)
	var right := _reading(compass.needle.transform)
	print("held up: facing north it reads %.1f°, facing west %.1f°" % [ahead, right])
	check(absf(ahead) < TRUE and absf(right - 90.0) < TRUE, "held up, north ahead is up its card and north on your right is right")

	click_at(Vector2(576.0, 60.0))
	await physics_frames(20)
	var shown := suit.look_of(stack_of(compass))
	var west := _reading(shown.needle.transform) if shown != null and shown.needle != null else NAN
	player.rotation.y = deg_to_rad(180.0)
	await physics_frames(20)
	var south := _reading(shown.needle.transform) if shown != null and shown.needle != null else NAN
	print("carried: facing west it reads %.1f°, facing south %.1f°" % [west, south])
	check(absf(west - 90.0) < TRUE and absf(absf(south) - 180.0) < TRUE, "carried, the view reads the same, live as you turn")

	# Over the north pole, walking on: north is now behind you.
	world.moon.latitude = PI / 2.0 - 1e-6
	world.moon.advance(0.0, 1.0)
	player.rotation.y = 0.0
	await physics_frames(20)
	var past := _reading(shown.needle.transform) if shown != null and shown.needle != null else NAN
	click_at(suit.tile_rect(stack_of(compass)).get_center())
	await physics_frames(30)
	var held := _reading(compass.needle.transform)
	print("over a pole, facing as you walked on: %.1f° in the view, %.1f° in your hand" % [past, held])
	check(absf(absf(past) - 180.0) < TRUE and absf(absf(held) - 180.0) < TRUE, "over a pole, the needle turns round with north")


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z).normalized()


## Where a needle points on its card, degrees clockwise from the card's top.
static func _reading(pose: Transform3D) -> float:
	var tip := pose.basis.y
	return rad_to_deg(atan2(tip.x, tip.y))
