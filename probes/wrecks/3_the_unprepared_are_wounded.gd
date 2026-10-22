extends WreckProbe
## Wreck probe 3: the unprepared are wounded. A module with a live hazard on
## it can be taken without making it safe, at a price. Grabbing a skimmer's
## power module by its live capacitor bank shocks you: health gone at once, thrown
## off it, stunned, unable to walk or close your hands, the bank spent. A
## hauler's cargo by a breached store makes you sick: health drained a little
## at a time, no healing, until it wears off, and a med kit
## cures it. With a stake laid across a bank's terminals, and sealant over a
## store's breach, both from your hands, every hazard on a pod, a lifeboat and
## a hopper is made safe and its module taken unharmed.

const APART := 70.0


func run() -> void:
	await load_salvage()
	var spot := open_sand()
	var tuning := Tuning.current()
	var vitals := world.player.vitals
	var wounds := vitals.wounds

	# Unprepared: a shock.
	var skimmer := await wreck_at(&"wreck_hull", spot.x, spot.y)
	var bank := _hazard_of(skimmer, Wreckage.ELECTRICAL)
	free_module(skimmer, bank)
	var bank_module: RigidBody3D = modules_of(skimmer)[bank]
	var health := vitals.health
	_reach(bank_module)
	hands.grab()
	await physics_frames(2)
	print("shocked: health %.1f to %.1f, stunned %.2f s" % [health, vitals.health, wounds.stun])
	check(absf(health - vitals.health - tuning.shock_harm) < 0.5 and wounds.stunned() and wounds.shocks == 1,
		"grabbing it by a live bank shocks you: %.0f health and stunned" % tuning.shock_harm)
	check(hands.held != bank_module and hands.grasp.body != bank_module and bank_module.has_meta(&"find"),
		"and throws you off it, the module still lying there")
	check(skimmer.hazard(bank) == &"" and skimmer.hazard_body(bank).has_meta(&"hazard_done"), "the bank is spent")
	hands.grab()
	check(hands.held == null and hands.grasp.body == null, "stunned, your hands won't close")
	world.player.set_physics_process(true)
	world.player.collision_layer = 1
	world.player.collision_mask = 1
	await physics_frames(20)
	var before := world.player.global_position
	Input.action_press(&"move_forward")
	await physics_frames(10)
	Input.action_release(&"move_forward")
	var moved := Vector2(world.player.global_position.x - before.x, world.player.global_position.z - before.z).length()
	print("stunned, walking forward a sixth of a second moved you %.3f m" % moved)
	check(moved < 0.05, "or carry you anywhere")
	world.player.set_physics_process(false)
	world.player.collision_layer = 0
	world.player.collision_mask = 0
	await physics_frames(roundi(tuning.shock_stun * Engine.physics_ticks_per_second) + 5)
	check(not wounds.stunned(), "the stun passes in %.1f s" % tuning.shock_stun)
	_reach(bank_module)
	hands.grab()
	await physics_frames(30)
	check(hands.held == bank_module or hands.grasp.body == bank_module, "spent, the module comes into your hands")
	hands.drop()

	# Unprepared: a sickness.
	var hauler := await wreck_at(&"tithe_hauler", spot.x + APART, spot.y)
	var store := _hazard_of(hauler, Wreckage.BIO)
	free_module(hauler, store)
	var cargo: RigidBody3D = modules_of(hauler)[store]
	_reach(cargo)
	hands.grab()
	await physics_frames(2)
	check(wounds.sick > 0.0 and wounds.sicknesses == 1 and hauler.hazard(store) == &"",
		"taking it by a breached store makes you sick")
	hands.drop()
	health = vitals.health
	for k in 4:
		world.time += 15.0
		await physics_frames(2)
	print("sick a minute: health %.2f to %.2f" % [health, vitals.health])
	check(vitals.health < health - tuning.sickness_harm * 50.0, "it takes health over time")
	var med := Catalog.part(&"med_kit")
	world.content.add_child(med)
	med.global_position = eye() - world.player.camera.global_basis.z * 0.6
	await physics_frames(5)
	hands.hold(med)
	await physics_frames(30)
	check(med.use(world.player, Vector3.ZERO) and wounds.sick == 0.0, "a med kit cures it")

	# Prepared: every hazard made safe from your hands, every module taken unharmed.
	var n := 2
	for kind: StringName in [&"freight_pod", &"lifeboat", &"hopper"]:
		var wreck := await wreck_at(kind, spot.x + (n % 5) * APART, spot.y + (n / 5) * APART)
		n += 1
		if wreck == null:
			continue
		for socket: int in wreck.plan.modules:
			free_module(wreck, socket)
		health = vitals.health
		var shocks := wounds.shocks
		var sicknesses := wounds.sicknesses
		for socket: int in wreck.plan.modules:
			var hazard := wreck.hazard(socket)
			if hazard == &"":
				continue
			var tool: RigidBody3D = Catalog.stake() if hazard == Wreckage.ELECTRICAL else Catalog.part(&"sealant")
			world.content.add_child(tool)
			tool.global_position = eye() - world.player.camera.global_basis.z * 0.6
			await physics_frames(5)
			hands.hold(tool)
			await physics_frames(30)
			var body := wreck.hazard_body(socket)
			_aim(body)
			await physics_frames(2)
			check(hands.interact() and wreck.hazard(socket) == &"", "the %s's %s is made safe" % [kind,
				"bank grounded" if hazard == Wreckage.ELECTRICAL else "store sealed"])
			if hazard == Wreckage.BIO:
				check(not is_instance_valid(tool) or tool.is_queued_for_deletion(), "the sealant used up")
			else:
				check(is_instance_valid(tool) and hands.held != tool and not (tool as Stake).driven,
					"the stake falls where it shorted the bank, yours still")
		for socket: int in wreck.plan.modules:
			var module: RigidBody3D = modules_of(wreck)[socket]
			if module != null:
				check(salvage.touched(module, world.player) == &"", "the %s's %s has nothing live on it" % [kind, module.label])
		# The day's own wear on you goes on meanwhile; a shock would take far more.
		check(vitals.health > health - tuning.shock_harm * 0.2 and wounds.shocks == shocks and wounds.sicknesses == sicknesses,
			"and you take the %s's modules unharmed" % kind)


## The socket of a wreck's first module with a hazard of a kind on it.
func _hazard_of(wreck: Wreckage, kind: StringName) -> int:
	for socket: int in wreck.plan.modules:
		if wreck.plan.modules[socket].hazard == kind:
			return socket
	return -1


## Your eyes above a module, looking down at it, empty-handed.
func _reach(module: RigidBody3D) -> void:
	var middle := middle_of(module)
	look(middle + Vector3.UP * 1.0 + Vector3(0.15, 0.0, 0.15), middle)


## Your eyes on a piece of a wreck, from just above it.
func _aim(piece: StaticBody3D) -> void:
	var middle := middle_of(piece)
	look(middle + Vector3.UP * 0.9 + Vector3(0.2, 0.0, 0.2), middle)
