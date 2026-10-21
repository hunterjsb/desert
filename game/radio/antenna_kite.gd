class_name AntennaKite
extends Device
## The antenna kite (the radio-equipment lab's, look/radio_kit): a delta
## with a copper dipole sewn across its shoulder, flown on its own conductor
## line from an antenna reel's wire, so a shortwave set clipped to the reel
## hears from 60 to 90 m up instead of off a wire a few metres high. Used on a
## reel it goes up into the wind: below kite_lift it won't fly, it stands
## highest in a fair breeze and is pressed back in a gale. Reeling the reel in
## brings it down beside it, as does the wind failing.
##
## Height is signal, and charge. The air's field grows with height and the
## dust a front's outflow drives charges the line far faster (the same dust
## that raises a radio's static: WeatherField.outflow_at), so its charge
## climbs toward where gathering and leaking off balance. Past kite_arc_from
## an arc can jump somewhere in the rig, likelier the further past: most
## burn the piece out (the kite's dipole, the reel, the set's shortwave
## converter or the set), the rest only spend the charge. An earth stake set
## down near the reel or the set dumps what's past its spark gap to earth;
## the set's bleed resistor leaks it off steadily, enough in a breeze, not in
## a front. Flying wears it a little, a gale more, and a sandstorm tears it
## to pieces in about a minute.

const GROUP := &"antenna_kites"
## It finds a reel to fly from this near where you use it, m.
const FLIES_FROM := 2.5
## The line's share that stands straight; the rest sags.
const STRAIGHT := 0.85
## The line's angle, degrees: just flying, in its best wind, and the least
## it's pressed down to; and how much flatter a m/s past its best, degrees.
const ANGLE := Vector3(25.0, 60.0, 10.0)
const PRESSED := 2.0
## Its line, as drawn: thickness, m, and its braid's colour.
const THICK := 0.003
const BRAID := Color(0.42, 0.3, 0.2)
## Its height and the wind it reads follow the air this fast, /s.
const FOLLOW := 0.6
## The wind must fail for this long, s, before it comes down.
const BECALMED := 4.0
## Where a piece of the rig an arc burns out lies: [piece, how exposed].
const EXPOSED := {&"kite": 3.0, &"reel": 1.0, &"converter": 3.0, &"radio": 1.5}
## An arc shows this long, s.
const FLASH := 0.15

## The reel it flies from, or null on the ground.
var reel: AntennaReel
## How high it stands over its reel, m, and which way the wind carries it
## (unit, on the ground).
var height := 0.0
var downwind := Vector2(0.0, 1.0)
## Its charge, 0 to 1 of what arcs for certain.
var charge := 0.0
var _calm_for := 0.0
var _rng := RandomNumberGenerator.new()
var _sky: MeshInstance3D
var _sail: ShaderMaterial
var _line: MeshInstance3D
var _crackle: AudioStreamPlayer3D
var _arc: MeshInstance3D
var _arc_left := 0.0
var _tuning := Tuning.current()


func _init() -> void:
	carryable = true
	add_to_group(GROUP)


func _ready() -> void:
	super()
	_rng.seed = get_instance_id()
	_sky = MeshInstance3D.new()
	_sky.mesh = RadioKitLooks.kite()
	_sky.top_level = true
	_sky.visible = false
	# Its sail tears and glows on its own, so it has a cloth of its own.
	_sail = (_sky.mesh.surface_get_material(_sky.mesh.get_surface_count() - 1) as ShaderMaterial).duplicate()
	_sky.set_surface_override_material(_sky.mesh.get_surface_count() - 1, _sail)
	add_child(_sky)
	_line = _strand(BRAID)
	_arc = MeshInstance3D.new()
	_arc.top_level = true
	_arc.visible = false
	add_child(_arc)
	# Its corona's crackle, looping while it's charged.
	var loop := Sounds.ARC_LOOP.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = loop.data.size() / (2 * (2 if loop.stereo else 1))
	_crackle = Sounds.world_voice(loop, -80.0, 30.0)
	add_child(_crackle)


## Whether it's up.
func flying() -> bool:
	return reel != null


## In your hands, aimed at a reel: up it goes from it, if there's wind.
func use(by: Player, at: Vector3) -> bool:
	if flying() or wrecked() or world == null:
		return false
	var near := _reel_near(at)
	if near == null:
		return false
	if _wind_at(near.end()) < _tuning.kite_lift:
		return by.hands.refuse("not wind enough to fly it")
	by.hands.drop()
	launch(near)
	return true


## Up from a reel, into the wind.
func launch(from: AntennaReel) -> void:
	reel = from
	height = 0.0
	_calm_for = 0.0
	# Its arcs fall the same way for the same flight.
	_rng.seed = hash([world.run_seed, roundi(world.time)])
	world.salvage.claim(self)
	# Out of the way while it flies: its folded body waits by the reel.
	freeze = true
	visible = true
	collision_layer = 0
	collision_mask = 0
	_frame_shown(false)
	Sounds.play_at(self, Sounds.REEL)


## Down beside its reel, folded, its charge gone to ground.
func land() -> void:
	if reel == null:
		return
	var at := reel.end() + Vector3(0.6, 0.4, 0.0)
	reel = null
	charge = 0.0
	_sky.visible = false
	_line.visible = false
	_crackle.stop()
	collision_layer = 1
	collision_mask = 1
	_frame_shown(true)
	global_position = at
	freeze = false
	Sounds.play_at(self, Sounds.UNSEAT)


## The line out from the reel to it: how far, m.
func line_m() -> float:
	return _tuning.kite_line_m if flying() else 0.0


## How much it adds to a shortwave set's wire, of signal: about 10 dB a
## tenfold of height over the wire's own best, to a ceiling; nothing with
## its dipole burnt.
func gain() -> float:
	if not flying() or wrecked() or height <= _tuning.sw_wire_high_m:
		return 1.0
	return db_to_linear(minf(10.0 * log(height / _tuning.sw_wire_high_m) / log(10.0), _tuning.kite_most_db))


## Where it flies now, in the engine's space.
func aloft() -> Vector3:
	var from := reel.end()
	var out := sqrt(maxf(pow(_tuning.kite_line_m * STRAIGHT, 2.0) - height * height, 0.0))
	return from + Vector3(downwind.x, 0.0, downwind.y) * out + Vector3.UP * height


func _physics_process(delta: float) -> void:
	super(delta)
	if not flying():
		return
	if not is_instance_valid(reel) or not reel.is_inside_tree() or reel.wrecked() or wrecked():
		land()
		return
	var at := reel.end()
	var x := world.world_x(at.x)
	var z := world.world_z(at.z)
	var t := world.time
	var blow := world.weather.field.wind_at(x, z, t)
	var wind := blow.length()
	if blow.length() > 0.1:
		downwind = downwind.lerp(blow.normalized(), minf(FOLLOW * delta, 1.0)).normalized()
	_calm_for = _calm_for + delta if wind < _tuning.kite_lift else 0.0
	if _calm_for >= BECALMED:
		land()
		return
	height = lerpf(height, flies_at(wind, _tuning.kite_line_m), minf(FOLLOW * delta, 1.0))
	global_position = at + Vector3.UP * 0.3
	_wear(delta, wind, world.weather.field.storm_at(x, z, t))
	_gather(delta, world.weather.field.outflow_at(x, z, t))
	_sail.set_shader_parameter(&"torn", 1.0 - durability)
	_sail.set_shader_parameter(&"charge", charge)
	_crackle.volume_db = linear_to_db(smoothstep(0.1, 0.6, charge) + 0.0001) - 6.0
	if charge > 0.1 and not _crackle.playing:
		_crackle.play()


## How high it stands on `line` m of line in a wind of `wind` m/s, m: none
## below kite_lift; its line's angle rising to its best wind and pressed down
## past it.
func flies_at(wind: float, line: float) -> float:
	if wind < _tuning.kite_lift:
		return 0.0
	var best: Vector2 = _tuning.kite_best_wind
	var angle := lerpf(ANGLE.x, ANGLE.y, clampf((wind - _tuning.kite_lift) / (best.x - _tuning.kite_lift), 0.0, 1.0))
	angle -= maxf(wind - best.y, 0.0) * PRESSED
	return line * STRAIGHT * sin(deg_to_rad(clampf(angle, ANGLE.z, ANGLE.y)))


## Flying wears it a little, a gale more, a sandstorm most.
func _wear(delta: float, wind: float, storm: float) -> void:
	wear((1.0 / _tuning.kite_life_s + maxf(wind - _tuning.kite_harm_wind, 0.0) / _tuning.kite_wind_s
		+ storm / _tuning.kite_storm_s) * delta)


## Its charge this tick: gathered by height and dust, leaked to the air, to
## earth by a stake or a bleed resistor, and arcing past its threshold.
func _gather(delta: float, outflow: float) -> void:
	charge += (_tuning.kite_fair_rate + _tuning.kite_dust_rate * outflow) * height / 100.0 * delta
	charge -= charge * delta / _tuning.kite_air_s
	var radio := reel.radio
	if radio != null and radio.bleeds():
		charge -= charge * delta / _tuning.kite_bleed_s
	var stake := earth()
	if stake != null and charge > _tuning.kite_gap_at:
		var dumped := (charge - _tuning.kite_gap_at) * minf(_tuning.kite_gap_rate * delta, 1.0)
		charge -= dumped
		if dumped > 0.002:
			# The charge leaps the stake's spark gap: a small bright crack.
			stake.spark()
			Deeds.done(world, &"grounded")
	charge = clampf(charge, 0.0, 1.0)
	if charge > _tuning.kite_arc_from:
		var past := (charge - _tuning.kite_arc_from) / (1.0 - _tuning.kite_arc_from)
		if _rng.randf() < _tuning.kite_arc_most * past * past * delta:
			charge *= 1.0 - _tuning.kite_arc_spends
			_arc_out(_rng.randf() < _tuning.kite_burns)
	if _arc_left > 0.0:
		_arc_left -= delta
		_arc.visible = _arc_left > 0.0


## The earth stake set down near its reel or the set, or null.
func earth() -> EarthStake:
	for node in get_tree().get_nodes_in_group(EarthStake.GROUP):
		var stake := node as EarthStake
		if stake == null or not stake.earthed():
			continue
		var near := stake.global_position.distance_to(reel.end()) <= _tuning.kite_earth_m
		if reel.radio != null:
			near = near or stake.global_position.distance_to(reel.radio.global_position) <= _tuning.kite_earth_m
		if near:
			return stake
	return null


## An arc down the rig: a bolt from the line's foot into a piece by how
## exposed it is, a crack and sparks; `burns`, the piece burnt out.
func _arc_out(burns: bool) -> void:
	var radio := reel.radio
	var pieces := {&"kite": EXPOSED.kite, &"reel": EXPOSED.reel}
	if radio != null and not radio.wrecked():
		pieces[&"radio"] = EXPOSED.radio
		if radio.converter(&"sw") != null:
			pieces[&"converter"] = EXPOSED.converter
	var total := 0.0
	for each: StringName in pieces:
		total += pieces[each]
	var roll := _rng.randf() * total
	var hit := &"kite"
	for each: StringName in pieces:
		roll -= pieces[each]
		if roll <= 0.0:
			hit = each
			break
	var where: Vector3 = aloft() if hit == &"kite" else (reel.global_position if hit == &"reel" else radio.global_position)
	var b := Paint.Pieces.new()
	RadioKitLooks.arc(b, reel.end(), where if hit != &"kite" else reel.end() + (aloft() - reel.end()) * 0.2,
		_rng.randi(), 0.01)
	_arc.mesh = b.commit()
	_arc.global_transform = Transform3D.IDENTITY
	_arc.visible = true
	_arc_left = FLASH
	ScrapFx.burst(world.content, where, 30, 4.0)
	Sounds.play_at(reel, Sounds.ZAP)
	if not burns:
		return
	match hit:
		&"kite":
			wear(INF)
		&"reel":
			reel.wear(INF)
		&"converter":
			radio.burn(radio.converter(&"sw"))
		&"radio":
			radio.wear(INF)


## Its line and the kite where they fly, every frame.
func _process(_delta: float) -> void:
	if _sky == null:
		return
	_sky.visible = flying() and is_instance_valid(reel)
	_line.visible = _sky.visible
	if not _sky.visible:
		return
	var from := reel.end()
	var to := aloft()
	# Its keel to its line, its nose up: the face it flies on toward the reel.
	var back := (from - to).normalized()
	var up := (Vector3.UP - back * Vector3.UP.dot(back)).normalized()
	_sky.global_transform = Transform3D(Basis(up.cross(back), up, back), to)
	_stretch(_line, from, to)


## A thin box drawn from one point to another.
static func _stretch(view: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var span := from.distance_to(to)
	if span < 0.01:
		view.visible = false
		return
	var up := Vector3.UP if absf((to - from).normalized().dot(Vector3.UP)) < 0.99 else Vector3.BACK
	view.global_transform = Transform3D(Basis.looking_at(to - from, up).scaled(Vector3(1.0, 1.0, span)),
		(from + to) * 0.5)


func _strand(color: Color) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(THICK, THICK, 1.0)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = 0.7
	box.material = paint
	view.mesh = box
	view.top_level = true
	view.visible = false
	add_child(view)
	return view


## Its folded body shown, or hidden while it flies.
func _frame_shown(shown: bool) -> void:
	for view: MeshInstance3D in painted():
		if view != null:
			view.visible = shown


func _wind_at(at: Vector3) -> float:
	return world.weather.field.wind_at(world.world_x(at.x), world.world_z(at.z), world.time).length()


## The reel nearest a place, within FLIES_FROM, with nothing flying from it, or null.
func _reel_near(at: Vector3) -> AntennaReel:
	var best: AntennaReel = null
	var nearest := FLIES_FROM
	for node in get_tree().get_nodes_in_group(AntennaReel.GROUP):
		var each := node as AntennaReel
		if each == null or not each.is_inside_tree() or each.wrecked() or each.kite() != null:
			continue
		var d := each.global_position.distance_to(at)
		if d < nearest:
			nearest = d
			best = each
	return best
