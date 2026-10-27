class_name AntennaKite
extends Device
## An antenna kite on its own reel of flying line, its lead plugged straight
## into a radio's top (gonkhub, 2026-10-22: "remove the hook from the setup").
## Use it and it flies up on the wind, paying
## out its line, kite_line_m of it; use it again and it reels in. Placed by the
## wind, not flown by physics: its line stands at an angle that rises with the
## wind (kite_angle_deg), so it flies 50 to 90 m up on its full line, and
## comes down below kite_lift_ms.
##
## A cable, plain or strong, from a radio's aerial clip to the reel's lead
## terminal makes the kite that set's aerial on every band: on shortwave the
## higher, the more it hears (Radio.antenna_gain); on AM a long wire's lift,
## heard all ways round (Radio.aerial_am); on FM its height is the set's
## (Radio.receive_fm). The cable can run through a driven stake on the way,
## one cable through all three points, and that earths it.
##
## Flown high it gathers charge, the more so in the dust a front drives, and
## past a point an arc jumps down the chain and burns out one piece of it, any
## one alike (gonkhub, 2026-10-22): the kite's dipole, the lead, the converter
## the set hears it through, or the set itself. Its lead through a driven stake, the stake's ring dumps the charge to
## earth; a bleed resistor in the set's misc bay leaks it off. It wears as a
## sail does, a little flying at all, fast past a harm wind, and a sandstorm
## shreds it in about a minute. (From the radio kit lab: look/radio_kit, and its
## numbers from charge_model.gd.)

const GROUP := &"antenna_kites"
## Where its line leaves the reel, in its own frame.
const LINE_FROM := Vector3(0.0, 0.0, 0.0)
## Carried in the suit, its line runs from about this high on you, m.
const ON_YOU := Vector3(0.0, 1.0, 0.0)
## A scorch takes this much of a device's soundness.
const SCORCH := 0.15
## Flying lower than this over the ground, m, it's on the sand, not up.
const LOW := 1.0
## Charge past which it crackles, and its corona shows.
const CRACKLE := 0.12
const LINE_THICK := 0.003

## Whether it's flying (or being sent up), and how much line is out, m.
var flying := false
var line_out := 0.0
## Its charge, 0 to 1 of what arcs for certain.
var charge := 0.0
## Where the kite is, in the world's engine frame.
var kite_at := Vector3.ZERO
## How many arcs the stake took and the rig took, for probes and the lamps.
var grounded := 0
var arcs := 0
## What the last arc burnt out, or &"".
var burnt := &""

var _kite: MeshInstance3D
var _line: MeshInstance3D
var _crackle: AudioStreamPlayer3D
var _flash: OmniLight3D
var _flash_left := 0.0
var _placed := false
var _seed := 0.0
## Its rig as last found: {radio, cable}, read each tick.
var rig := {}


func _init() -> void:
	carryable = true
	add_to_group(GROUP)


func _ready() -> void:
	super()
	_seed = float(hash(get_instance_id()) % 1000) * 0.01
	if world != null:
		world.origin_shifted.connect(_origin_shifted)


func _origin_shifted(by: Vector2i) -> void:
	var offset := Vector3(by.x * world.tuning.chunk_size, 0.0, by.y * world.tuning.chunk_size)
	kite_at -= offset
	# Top-level aerial effects do not inherit their reel's displacement.
	for visual in [_kite, _line, _flash]:
		if is_instance_valid(visual) and visual.is_inside_tree():
			visual.global_position -= offset


## Its kite, line, crackle and flash, made the first time it flies: a kite
## found packed in a ruin costs nothing till then.
func _dress() -> void:
	if _kite != null:
		return
	_kite = MeshInstance3D.new()
	_kite.mesh = KiteLooks.kite()
	_kite.top_level = true
	_kite.visible = false
	add_child(_kite)
	_line = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(LINE_THICK, LINE_THICK, 1.0)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.85, 0.82, 0.74)
	paint.roughness = 0.8
	box.material = paint
	_line.mesh = box
	_line.top_level = true
	_line.visible = false
	add_child(_line)
	_crackle = Sounds.world_voice(Sounds.looping(Sounds.ARC_LOOP), -80.0)
	add_child(_crackle)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(0.75, 0.6, 1.0)
	_flash.omni_range = 4.0
	_flash.light_energy = 0.0
	_flash.top_level = true
	add_child(_flash)


## Looked at with empty hands: flies it or reels it in; else as any device.
func interact(by: Player) -> bool:
	if by.hands.held == null:
		return _toggle(by)
	return super(by)


## In your hands: flies it or reels it in.
func use(by: Player, _at: Vector3) -> bool:
	return _toggle(by)


func _toggle(by: Player) -> bool:
	if flying or line_out > 0.0:
		reel_in()
		return true
	if wrecked():
		return by.hands.refuse("torn to rags")
	if wind() < Tuning.current().kite_lift_ms:
		return by.hands.refuse("too little wind to fly it")
	fly()
	return true


## Sent up on the wind, its line paying out.
func fly() -> void:
	flying = true
	if line_out <= 0.0:
		kite_at = anchor() + Vector3.UP * 1.5
	Sounds.play_at(self, Sounds.REEL)


## Wound back in: its line comes in and the kite comes down to the reel.
func reel_in() -> void:
	flying = false
	Sounds.play_at(self, Sounds.REEL)


## Where its line leaves from: the reel, or you while it's carried.
func anchor() -> Vector3:
	if has_meta(&"carried") and world != null:
		return world.player.global_position + ON_YOU
	return global_transform * LINE_FROM


## The wind where it flies, m/s: the open wind over its reel.
func wind() -> float:
	return _wind_at().length()


func _wind_at() -> Vector2:
	if world == null:
		return Vector2.ZERO
	var at := anchor()
	return world.weather.field.wind_at(world.world_x(at.x), world.world_z(at.z), world.time)


## How high the kite flies over the ground under it, m; none packed.
func height() -> float:
	if world == null or line_out <= 0.0:
		return 0.0
	return maxf(kite_at.y - world.height_under(kite_at), 0.0)


## Whether it's up in the air, and sound.
func up() -> bool:
	return line_out > 0.0 and not wrecked() and height() > LOW


## The line's angle over the ground, degrees, in a wind of `w` m/s: none
## below kite_lift_ms, rising to its best, pressed back past it.
static func angle(w: float, tuning: Tuning) -> float:
	return KiteFlight.angle(w, tuning)


## How high it flies on `line` m in a wind of `w`, m (charge_model's height).
static func height_in(w: float, line: float, tuning: Tuning) -> float:
	var a := angle(w, tuning)
	return 0.0 if a <= 0.0 else line * tuning.kite_sag * sin(deg_to_rad(a))


## What it adds to a shortwave set's aerial, as a share of a full long wire:
## about 10 dB a tenfold of height over the whip's, from the bare terminals.
static func gain(h: float, tuning: Tuning) -> float:
	var db := minf(10.0 * log(maxf(h, tuning.kite_whip_m) / tuning.kite_whip_m) / log(10.0), tuning.kite_gain_db)
	return minf(tuning.sw_bare * pow(10.0, db / 20.0), tuning.kite_gain_most)


## The radio and cable its lead runs to: the cable with a plug in its lead
## terminal and the other in a radio's aerial clip. {} if its lead goes nowhere.
func find_rig() -> Dictionary:
	if world == null:
		return {}
	var mine: Socket = null
	for socket in sockets():
		if socket.kind == &"lead":
			mine = socket
	if mine == null or mine.part == null:
		return {}
	var cable := Cable.of(mine.part, world)
	if cable == null or cable is StrongCable and (cable as StrongCable).rope == null:
		return {}
	for plug in cable.plugs:
		if plug == mine.part or not is_instance_valid(plug) or plug.socket == null or plug.socket.kind != &"lead":
			continue
		var radio := plug.socket.get_parent() as Radio
		if radio != null and not radio is SurveyReceiver:
			return {"radio": radio, "cable": cable}
	return {}


## Whether its lead runs through a driven stake: earthed.
func earthed() -> bool:
	var cable: Variant = rig.get("cable")
	if not is_instance_valid(cable):
		return false
	return not (cable is StrongCable and (cable as StrongCable).rope == null) and cable.staked()


func stats() -> Dictionary:
	var now := super()
	if line_out > 0.0:
		now["rope_m"] = line_out
		now["height_m"] = height()
	return now


func _physics_process(delta: float) -> void:
	super(delta)
	if world == null:
		return
	var tuning := Tuning.current()
	rig = find_rig()
	var w := _wind_at()
	var speed := w.length()
	# Its line: paid out while it flies on enough wind, wound in when not.
	if flying and speed >= tuning.kite_lift_ms and not wrecked():
		line_out = minf(line_out + tuning.kite_payout_ms * delta, tuning.kite_line_m)
	elif not flying:
		line_out = maxf(line_out - tuning.kite_reel_ms * delta, 0.0)
	if line_out <= 0.0:
		line_out = 0.0
		flying = flying and not wrecked()
		charge = 0.0
		_placed = false
		return
	_place(w, delta, tuning)
	if up():
		_weather(speed, delta, tuning)
	else:
		charge = maxf(charge - charge * delta / tuning.kite_air_tau * 10.0, 0.0)
	if wrecked():
		flying = false


## Where the wind puts it at the end of its line, swaying, settling there.
func _place(w: Vector2, delta: float, tuning: Tuning) -> void:
	var from := anchor()
	var direction := KiteFlight.direction(w, world.time, _seed, tuning, not wrecked())
	var target := from + direction * line_out * tuning.kite_sag
	target.y = maxf(target.y, world.height_under(target) + 0.3)
	if not _placed or kite_at == Vector3.ZERO:
		kite_at = target if line_out > 2.0 else from + Vector3.UP * 0.5
		_placed = true
	kite_at = kite_at.lerp(target, KiteFlight.settling(delta))


## Its wear and charge aloft, a tick of `real` s (by world time, so time
## warped they go as fast): and the arcs its charge may throw.
func _weather(speed: float, real: float, tuning: Tuning) -> void:
	var delta := real * world.time_warp
	var field := world.weather.field
	var x := world.world_x(kite_at.x)
	var z := world.world_z(kite_at.z)
	var t := world.time
	var storm := field.raw_storm_at(x, z, t)
	var dust := maxf(field.outflow_at(x, z, t), storm)
	wear(KiteFlight.wear_rate(speed, storm, tuning) * delta)
	var h := height()
	charge += (tuning.kite_charge_fair + tuning.kite_charge_dust * dust) * (h / 100.0) * delta
	charge -= charge * delta / tuning.kite_air_tau
	var radio: Radio = rig.get("radio")
	if radio != null and radio.bleeds():
		charge -= charge * delta / tuning.kite_bleed_tau
	if earthed() and charge > tuning.kite_gap_at:
		var was := charge
		charge -= (charge - tuning.kite_gap_at) * minf(tuning.kite_gap_rate * delta, 1.0)
		# The stake takes what would have arced: a crack at its ring.
		if was > tuning.kite_arc.x and randf() < 2.0 * delta:
			_spark_at((rig.cable as Cable).through.global_transform * Stake.RING, 8, false)
			grounded += 1
			Deeds.done(world, &"grounded")
	charge = clampf(charge, 0.0, 1.0)
	if charge > tuning.kite_arc.x:
		var past := (charge - tuning.kite_arc.x) / (1.0 - tuning.kite_arc.x)
		if randf() < tuning.kite_arc.y * past * past * delta:
			arc(randf() < tuning.kite_burns)


## An arc down the rig: it spends most of the charge and burns out, or only
## scorches, one piece of the chain, picked at random.
func arc(burns: bool) -> void:
	var tuning := Tuning.current()
	charge *= 1.0 - tuning.kite_arc_spends
	arcs += 1
	var piece := _pick()
	var at := kite_at
	var radio: Radio = rig.get("radio")
	match piece:
		&"lead":
			var cable: Cable = rig.cable
			at = (cable.end_of(cable.plugs[0]) + cable.end_of(cable.plugs[1])) * 0.5
			if burns:
				for plug in cable.plugs:
					if is_instance_valid(plug):
						if plug.socket != null:
							(plug.socket.get_parent() as Device).take(plug.socket)
						plug.queue_free()
		&"converter":
			var socket := radio.converter_socket(_converts(radio))
			at = socket.global_position
			if burns:
				_burn_part(radio, socket)
		&"radio":
			at = radio.global_position
			radio.wear(INF if burns else SCORCH)
		_:
			wear(INF if burns else SCORCH)
	burnt = piece if burns else &""
	_spark_at(at, 40 if burns else 16, true)


## The piece an arc hits: any one in the chain alike, the kite, its lead, the
## converter the set hears it through and the set.
func _pick() -> StringName:
	return chain().pick_random()


## The pieces of its rig an arc can run down, kite to set.
func chain() -> Array[StringName]:
	var radio: Radio = rig.get("radio")
	var pieces: Array[StringName] = [&"kite"]
	if rig.has("cable"):
		pieces.append(&"lead")
	if radio != null and _converts(radio) != &"" and radio.converter_socket(_converts(radio)) != null:
		pieces.append(&"converter")
	if radio != null:
		pieces.append(&"radio")
	return pieces


## The stat of the converter a set hears its band through (&"fm", &"sw"), or
## &"" on the AM dial, which needs none.
static func _converts(radio: Radio) -> StringName:
	return {Radio.FM_BAND: &"fm", Radio.SW_BAND: &"sw"}.get(radio.band, &"")


## A part burnt out in its socket: gone, smoke and all.
static func _burn_part(device: Device, socket: Socket) -> void:
	var part := device.take(socket)
	if part != null:
		part.queue_free()


## A crack of sparks and a violet flash at a place; loud for an arc.
func _spark_at(at: Vector3, count: int, loud: bool) -> void:
	_dress()
	ScrapFx.burst(world.content, at, count, 3.0 if loud else 1.5)
	var voice := Sounds.world_voice(Sounds.ZAP, 0.0 if loud else -10.0, 4.0 if loud else 2.0)
	voice.autoplay = true
	voice.finished.connect(voice.queue_free)
	world.content.add_child(voice)
	voice.global_position = at
	_flash.global_position = at
	_flash_left = 0.15 if loud else 0.06


## The kite, its line and its corona drawn, every frame.
func _process(delta: float) -> void:
	var out := line_out > 0.0 and world != null
	if _kite == null:
		if not out:
			return
		_dress()
	_kite.visible = out
	_line.visible = out
	_flash_left = maxf(_flash_left - delta, 0.0)
	_flash.light_energy = 6.0 * _flash_left / 0.15 if _flash_left > 0.0 else 0.0
	_crackle.volume_db = linear_to_db(smoothstep(CRACKLE, 1.0, charge) + 0.0001) - 6.0 if out else -80.0
	if out and not _crackle.playing:
		_crackle.play()
	elif not out and _crackle.playing:
		_crackle.stop()
	if not out:
		return
	var from := anchor()
	var to_anchor := from - kite_at
	var facing := to_anchor.normalized() if to_anchor.length() > 0.01 else Vector3.BACK
	var side := Vector3.UP.cross(facing)
	# Straight over its reel, as it goes up, any way round will do.
	var up_way := facing.cross(side).normalized() if side.length() > 0.01 else Vector3.BACK
	# Its face toward its line, nose up.
	_kite.global_transform = Transform3D(Basis.looking_at(-facing, up_way), kite_at)
	_kite.set_instance_shader_parameter(&"torn", clampf((1.0 - durability) * 0.9, 0.0, 0.9))
	_kite.set_instance_shader_parameter(&"age", 1.0 - durability)
	_kite.set_instance_shader_parameter(&"weathered", 1.0 - durability)
	_kite.set_instance_shader_parameter(&"charge", smoothstep(CRACKLE, 0.6, charge))
	_crackle.global_position = kite_at
	var ring := _kite.global_transform * KiteLooks.RING
	var span := from.distance_to(ring)
	if span < 0.02:
		_line.visible = false
		return
	var way := Vector3.UP if absf((ring - from).normalized().dot(Vector3.UP)) < 0.99 else Vector3.BACK
	_line.global_transform = Transform3D(Basis.looking_at(ring - from, way).scaled(Vector3(1.0, 1.0, span)),
		(from + ring) * 0.5)
