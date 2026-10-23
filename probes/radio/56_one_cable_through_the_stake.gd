extends KiteProbe
## Radio probe 56: one cable through three points. A cable from the radio's top
## hook to the kite's reel passes through a driven stake between them, its two
## legs measured round it, and that earths the kite's lead; a stake not driven
## won't take it, nor one too far round for its length; a strong cable's rope
## runs through the stake's ring too; and a lead carries no power.


func run() -> void:
	await load_storm(0.0, 9.0)
	var rig := await kite_rig(true)
	var cable: Cable = rig.cable
	var stake: Stake = rig.stake
	var kite: AntennaKite = rig.kite
	await physics_frames(2)
	var straight := cable.end_of(cable.plugs[0]).distance_to(cable.end_of(cable.plugs[1]))
	print("straight %.2f m, round the stake %.2f m" % [straight, cable.span()])
	check(cable.through == stake and cable.span() > straight, "it runs through the stake, measured round it")
	check(kite.earthed(), "and that earths the kite's lead")
	check(cable.joined().is_empty(), "a lead carries no power")
	check(cable.route(stake) == "" and cable.through == null and not kite.earthed(), "passed again, it comes off")
	var loose := Catalog.stake()
	world.content.add_child(loose)
	loose.global_position = cable.end_of(cable.plugs[0]) + Vector3(1.0, 0.5, 0.0)
	check(cable.route(loose) != "" and cable.through == null, "a stake not driven won't take it")
	var far := Catalog.stake()
	world.content.add_child(far)
	var at := cable.end_of(cable.plugs[0]) + Vector3(0.0, 0.0, 8.0)
	far.drive(at, world.height_under(at))
	check(cable.route(far) != "" and cable.through == null, "nor one too far round for its length")
	var strong := await kite_rig(true, true, Vector2(-8.0, 6.0))
	var rope := (strong.cable as StrongCable).rope
	check(rope != null and rope.through == (strong.stake as Stake).ring, "a strong cable's rope runs through the ring")
