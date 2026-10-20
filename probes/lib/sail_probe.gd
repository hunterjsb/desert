class_name SailProbe
extends DeckProbe
## For sailing probes: a camp on runners with a mast and sail, on level sand
## running across the wind, in a wind the probe picks.

var deck: Chassis
var mast: Mast
var _working_sheet: Rope
var _outboard := 0.0
## Level sand across the run's long-term wind, world metres, and the ways
## along and across it.
var level := Vector2.ZERO
var downwind := Vector2.ZERO
var across := Vector2.ZERO
## That sand where the engine has it now: it moves as the origin shifts.
var open: Vector3:
	get:
		var at := Vector3(world.engine_x(level.x), 0.0, world.engine_z(level.y))
		at.y = world.height_under(at)
		return at


func load_sailing(run_seed := 1234) -> void:
	await load_lines(run_seed)
	level = Scenarios.open_sand(world)
	check(not is_nan(level.x), "there's level sand to sail on")
	downwind = Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	across = downwind.orthogonal()
	follow(open)
	await settle(true)
	follow(open)


## A deck two pieces by two at a place, facing `heading` (engine x, z), on
## `carried` under every piece (skates, a board plate or hover trays), a mast
## with its sail on the front piece to `windward` (1 its left, -1 its right),
## two big batteries and a battery in a frame behind it, and unless `cleated` is false the
## sheet made fast on the deck's own hook, so it holds its trim: a camp left
## to sail itself.
func rig(at: Vector3, heading: Vector2, carried := &"skates", windward := 1, cleated := true) -> Chassis:
	deck = Catalog.device(&"chassis") as Chassis
	world.content.add_child(deck)
	var yaw := atan2(-heading.x, -heading.y)
	deck.global_transform = Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * 0.5)
	var left := 0 if windward > 0 else 1
	for each: Array in [[Vector2i.ZERO, Vector2i(1, 0)], [Vector2i.ZERO, Vector2i(0, 1)], [Vector2i(1, 0), Vector2i(0, 1)]]:
		deck.join(Catalog.device(&"chassis") as Chassis, ring(deck, each[0], each[1]), 0)
	for i in 4:
		fit_part(deck, carried)
	mast = Rig.make([&"mast", [&"sail"]]) as Mast
	# Its boom swung back over the deck, as a sail mount's always had it.
	Stick.put(deck, Rig.piece(deck, Vector2i(left, 0)), Chassis.TOP, Vector2.ZERO, PI, mast)
	# The raised physical gooseneck clears the original ballast frame.
	var behind := Rig.piece(deck, Vector2i(left, 1))
	Stick.put(deck, behind, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.part(&"frame"))
	for place: Vector2 in [Vector2(-0.25, 0.0), Vector2(0.0, 0.0), Vector2(0.25, 0.0)]:
		Stick.put(deck, behind, Chassis.TOP, place, 0.0, Catalog.part(&"battery" if place.x == 0.0 else &"big_battery"))
	if cleated:
		fit_part(deck, &"hook")
		var sheet := Line.between(world, mast._tie(), deck.free_tie(deck.global_position), 0.0)
		mast.rig_sheet(sheet)
	set_down(deck)
	return deck


## The deck moored to a stake driven this far upwind of it, m, by a hook on
## the ring nearest it.
func moor(upwind := 4.0) -> void:
	fit_part(deck, &"hook")
	var at := deck.global_position - ground(downwind) * upwind
	var stake := driven_stake(Vector3(at.x, world.height_under(at), at.z))
	Line.between(world, deck.free_tie(stake.global_position), stake.free_tie(deck.global_position), 0.3)


## The lowest any corner of the deck or what's seated on it comes below the
## sand under it, m: never far.
func sunk() -> float:
	var deepest := -INF
	var riding: Array[Device] = [deck]
	while not riding.is_empty():
		var each: Device = riding.pop_back()
		riding.append_array(each.mounted())
		for child in each.get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.shape == null:
				continue
			var box := Catalog.bounds(shape.shape)
			for i in 8:
				var corner := each.global_transform * shape.transform * box.get_endpoint(i)
				deepest = maxf(deepest, world.height_under(corner) - corner.y)
	return deepest


## Sets a device down on the sand where it stands, as high as what carries it holds it.
func set_down(device: Device) -> void:
	var sand := 0.0
	var spots: Array = (device as Chassis).pieces().map(func(p: Chassis) -> Vector3: return p.pose().origin) \
		if device is Chassis else [Vector3.ZERO]
	var middle := Vector3.ZERO
	for spot: Vector3 in spots:
		sand += world.height_under(device.global_transform * spot) / spots.size()
		middle += spot / spots.size()
	device.global_position.y += sand + device.rest_height() - (device.global_transform * middle).y
	device.linear_velocity = Vector3.ZERO
	device.angular_velocity = Vector3.ZERO


## The sail up at once, its boom free to swing as far as `degrees` either way.
func hoist(degrees: float) -> void:
	mast.raised = true
	mast.raise = 1.0
	trim(degrees)


## The sheet hauled to hold the boom within `degrees` of straight back.
func trim(degrees: float) -> void:
	var sheet := mast.sheet()
	if sheet != null:
		sheet.length = _trim_length(degrees, _swing_side())
		sheet.full = maxf(sheet.full, sheet.length)


## A heading as an engine direction on the flat.
static func ground(way: Vector2) -> Vector3:
	return Vector3(way.x, 0.0, way.y)


## Where the deck is to keep heading, as you would steer it by its lines: a
## turn toward it no harder than a pull on a line could give, N·m. Unset,
## it sails where its rig takes it.
var course := Vector2.ZERO
var helm := 300.0
## Tending the sheet as a sailor would, easing or hauling it by how far the
## sail meets the wind past this angle of attack, rad, and easing it as the
## camp starts to heel; 0 leaves the trim be.
var tending := 0.0
## A helmsman on a hull chooses forward drive; a free Varran tack can retain
## its current side while its bow lines turn the rig.
var driving_sheet := false


func _steer() -> void:
	if tending > 0.0 and is_instance_valid(mast) and mast.sail() != null:
		var meet := tending if driving_sheet else tending * clampf(1.0 - (roll() - 2.0) / 4.0, 0.0, 1.0)
		var air := _apparent_air()
		if air.length() > 0.01:
			var flow := atan2(-air.x, -air.z)
			var one := wrapf(flow - meet, -PI, PI)
			var two := wrapf(flow + meet, -PI, PI)
			var want := one if absf(angle_difference(mast.boom, one)) < absf(angle_difference(mast.boom, two)) else two
			if driving_sheet:
				var across := mast.global_basis.y.cross(mast.global_basis * air)
				want = one if across.dot(-deck.global_basis.z) > 0.0 else two
			var sheet := mast.sheet()
			if sheet != null:
				var aimed := mast.eased_length(rad_to_deg(want), 1.0) if driving_sheet else _trim_length(rad_to_deg(want), 1.0)
				var length := clampf(aimed, Line.SHORTEST, sheet.full)
				sheet.length = move_toward(sheet.length, length, Reel.PACE * get_physics_process_delta_time())
	if course == Vector2.ZERO or deck == null:
		return
	var ahead := -deck.global_basis.z
	var off := Vector2(ahead.x, ahead.z).angle_to(course)
	deck.apply_torque(Vector3.UP * clampf(-off * 600.0 - deck.angular_velocity.y * 200.0, -helm, helm))


## You stand beside a place, so the ground round it stays solid and loaded.
func follow(at: Vector3) -> void:
	world.player.global_position = at + Vector3(0.0, 2.0, 0.0)


## Ticks for a span, you keeping pace with the deck; `each` after every tick.
func sail_for(seconds: float, each := Callable()) -> void:
	await simulate(seconds, func() -> void:
		follow(deck.global_position + Vector3(0.0, 0.0, 8.0))
		_steer()
		if each.is_valid():
			each.call())


## The deck's way over the sand, engine x and z.
func way() -> Vector2:
	return Vector2(deck.linear_velocity.x, deck.linear_velocity.z)


## How far it leans from level, degrees.
func heel() -> float:
	return rad_to_deg(deck.global_basis.y.normalized().angle_to(Vector3.UP))


## How far it leans to its side, degrees, whatever its nose does.
func roll() -> float:
	return rad_to_deg(asin(clampf(absf(deck.global_basis.x.normalized().y), 0.0, 1.0)))


## The engine heading a deck faces across the wind with the wind on its left
## (1) or right (-1), turned `off` degrees toward the wind.
func heading(windward := 1, off := 0.0) -> Vector2:
	return (across * windward).rotated(-deg_to_rad(off) * windward)


## The Varran settler's rig as his kit builds it, floating downwind of you
## toward `way` and lying across its lines as it flies, its sail up: a bow
## line from each of its bow hooks and its sheet at your waist, laid as the
## kit lays them, and you on a board facing `way`, still. It's turned to lie
## with the hook on its side `windward` names nearer you (1, the wind on
## your left). The lines: that bow line, the sheet, the other bow line.
## An outboard passing lane lets overrun probes test rope loads without
## racing into the mast; its ends are laid there, never teleported.
func varran(way: Vector2, windward := 1, passing_lane := 0.0) -> Array[Line]:
	var kit := Kit.named(&"varran")
	var built := Rig.build(world.content, kit.assembled.rig.rig, 1.0)
	deck = built.deck
	mast = built.named.mast
	var toward := downwind.rotated(signf(downwind.cross(way)) * deg_to_rad(45.0))
	deck.global_transform = Transform3D(Basis(Vector3.UP, atan2(toward.x, toward.y) - windward * PI * 0.5),
		open + Vector3.UP)
	set_down(deck)
	var player := world.player
	var at := open - ground(toward) * 7.0
	if passing_lane != 0.0:
		var side := way.orthogonal()
		if (-toward).dot(side) < 0.0:
			side = -side
		at += ground(side) * passing_lane
	at.y = world.height_under(at) + 0.1
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-way.x, -way.y)), at))
	player.velocity = Vector3.ZERO
	await physics_frames(10)
	var board := Catalog.device(&"board")
	world.content.add_child(board)
	fit_part(board, &"battery")
	board.global_position = player.global_position + Vector3.UP * 0.2
	await physics_frames(2)
	var hooks: Array[Socket] = []
	for socket in deck.sockets():
		if socket.kind == &"tie" and socket.part == null:
			hooks.append(socket)
	hooks.sort_custom(func(a: Socket, b: Socket) -> bool:
		return deck.to_local(a.global_position).x < deck.to_local(b.global_position).x)
	var lines: Array[Line] = [Line.to_waist(world, hooks[0] if windward > 0 else hooks[-1], kit.waist[&"bow"]),
		Line.to_waist(world, mast._tie(), kit.waist[&"mast"]),
		Line.to_waist(world, hooks[-1] if windward > 0 else hooks[0], kit.waist[&"bow_right"])]
	for line in lines:
		line.full = maxf(line.full, world.tuning.rope_coil_length)
		line.rope.full = line.full
	mast.rig_sheet(lines[1])
	player.get_on(board)
	await physics_frames(2)
	hoist(20.0)
	return lines


func _swing_side() -> float:
	var air := _apparent_air()
	return -signf(air.x) if absf(air.x) > 0.01 else 1.0


func _apparent_air() -> Vector3:
	var centre := mast.global_transform * mast._middle_at(mast.boom)
	var velocity := Vector3.ZERO
	if is_instance_valid(mast._boom_body):
		var body := mast._boom_body
		velocity = body.linear_velocity + body.angular_velocity.cross(centre - body.global_transform * body.center_of_mass)
	return mast.global_basis.inverse() * (world.weather.felt_wind(centre) - velocity)


## Tend the boom leg, preserving the paid outboard reserve. Recalculating
## the whole path from the rider's current position would winch them closer
## on every tack and silently treat that closure as another trim allowance.
func _trim_length(degrees: float, side: float) -> float:
	var sheet := mast.sheet()
	var mine: RopeEnd = mast._tie().part.get_meta(&"tip")
	var other := sheet.b if sheet.a == mine else sheet.a
	var outboard := sheet.through.global_position.distance_to(other.global_position)
	if sheet != _working_sheet:
		_working_sheet = sheet
		_outboard = outboard
	return mast.eased_length(degrees, side) - outboard + _outboard
