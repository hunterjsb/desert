class_name SurveyReceiver
extends Radio
## A loop receiver for the old ruins' beacons, not a full broadcast radio.

const DEFAULT_VISUAL := preload("res://game/look/receiver/survey_receiver_visual.tscn")

const HOW_TO := "survey_receiver"
const HOW_TO_SAYS := "[font_size=20]{interact} switches on and acquires a nearby ruin beacon; again switches off.\n" \
	+ "Turn the loop for a stronger needle and pulse. It peaks in two opposite directions.\n" \
	+ "{reel_in}/{pay_out} tune; {tune_fine_up}/{tune_fine_down} fine tune.\n" \
	+ "{volume_up}/{volume_down} change volume.[/font_size]"

@export var visual_scene: PackedScene = DEFAULT_VISUAL
var visual: ReceiverVisual
var _procedural_frame: ArrayMesh

## How far from this target the receiver first acquired it, saved for the approach deed.
var acquired_from := 0.0
var scan_pending := false
var strength := 0.0
var meter_step := 0
var _shown_strength := 0.0
var _introduced := false
var _switch_sound: AudioStream
var _tick_sound: AudioStream
var _pulse_sound: AudioStream


func _init() -> void:
	super()
	frequency = Dial.BEACON_KHZ


func _ready() -> void:
	super()
	if not replace_visual(visual_scene):
		replace_visual(DEFAULT_VISUAL)
	_switch_sound = Sounds.RECEIVER_SWITCH
	_tick_sound = Sounds.RECEIVER_TICK
	_pulse_sound = Sounds.RECEIVER_PULSE
	_show_dial()


## This tier's loop and needle replace the broadcast set's face controls.
func has_dial_marks() -> bool:
	return false


func _make_lamps() -> void:
	pass


func interact(_by: Player) -> bool:
	return switch(not on)


func switch(up: bool) -> bool:
	if world == null or wrecked() or up == on:
		return false
	world.salvage.claim(self)
	on = up
	_show_appearance()
	scan_pending = up and (target.is_empty() or not target_valid())
	if scan_pending and playing():
		_acquire()
		scan_pending = false
	_since_signal = INF
	if not up:
		_clear_signal()
	if _switch_sound != null and powered and volume > 0.0:
		Sounds.play_at(self, _switch_sound, minf(knob_db(), 3.0), HEARD)
	return true


func tune(notches: int, fine := false) -> bool:
	if world == null or wrecked():
		return false
	world.salvage.claim(self)
	var step := _tuning.dial_fine_khz if fine else _tuning.dial_notch_khz
	frequency = clampf(snappedf(frequency + notches * step, step),
		Dial.BEACON_KHZ - _tuning.receiver_band_khz, Dial.BEACON_KHZ + _tuning.receiver_band_khz)
	if not on:
		switch(true)
	if _tick_sound != null and powered and volume > 0.0:
		Sounds.play_at(self, _tick_sound, minf(knob_db(), 3.0), HEARD)
	return true


func tuned_to() -> StringName:
	return &"beacon" if absf(frequency - Dial.BEACON_KHZ) <= _tuning.dial_width_khz * ON_IT else &""


## This tier exposes strength, not the full radio's compass reading.
func beacon_bearing() -> float:
	return NAN


func demand_w(t := NAN) -> float:
	return super(t) + (_tuning.receiver_w - _tuning.radio_w if on and not wrecked() else 0.0)


func playing() -> bool:
	if not super():
		return false
	if world.power.pool_wh(self) > 0.0:
		return true
	# A mounted panel can supply it directly even with the cells empty.
	return world.power.pool_of(self).any(func(device: Device) -> bool: return device.production_w() > 0.0)


func painted() -> Array[MeshInstance3D]:
	return visual.painted_meshes.duplicate() if visual != null else super()


func show_wear() -> void:
	super()
	_show_appearance()


func _recompute() -> void:
	super()
	_show_appearance()


func _show_appearance() -> void:
	if visual != null:
		visual.appearance(Paint.age_for(self, durability), Paint.row_for(self), 1.0 if on and powered else 0.0)


func apply_frame_look(mesh: ArrayMesh) -> void:
	_procedural_frame = mesh
	if visual == null:
		super(mesh)
	else:
		visual.apply_frame_look(mesh)


## Validate first so a bad asset never removes the working instrument.
func replace_visual(scene: PackedScene) -> bool:
	if scene == null or not is_instance_valid(frame_view):
		return false
	var instance := scene.instantiate()
	var next := instance as ReceiverVisual
	if next == null or not next.usable():
		if is_instance_valid(instance):
			instance.free()
		push_warning("Receiver appearance needs a shell, control pivots and reading anchor")
		return false
	next.prepare()
	# Preserve the current procedural lineage when rebuilding its appearance.
	if _procedural_frame == null:
		_procedural_frame = frame_view.mesh as ArrayMesh
	next.apply_frame_look(_procedural_frame)
	if visual != null:
		remove_child(visual)
		if is_instance_valid(visual):
			visual.free()
	else:
		for old: MeshInstance3D in [frame_view, needle, knob, volume_knob, band_lamp]:
			if is_instance_valid(old):
				remove_child(old)
				if is_instance_valid(old):
					old.free()
	visual = next
	visual_scene = scene
	add_child(visual)
	frame_view = visual.shell
	needle = null
	knob = null
	volume_knob = null
	band_lamp = null
	_show_dial()
	show_wear()
	return true


func face() -> Transform3D:
	return visual.reading.global_transform if visual != null else super()


func preview_pose(view: MeshInstance3D) -> Transform3D:
	return visual.preview_pose(view, float(meter_step) / _tuning.receiver_meter_steps)


## This receiver has no broadcast band lamp.
func _show_band() -> void:
	pass


func _acquire() -> void:
	target = Finds.beacon(world.run_seed, world.shape.sites, world.world_x(global_position.x),
		world.world_z(global_position.z), _tuning, world.salvage.taken, _tuning.receiver_reach_m)
	acquired_from = _distance() if not target.is_empty() else 0.0


func _distance() -> float:
	return Vector2(target.x - world.world_x(global_position.x), target.z - world.world_z(global_position.z)).length()


func target_valid() -> bool:
	return not target.is_empty() and not world.salvage.taken(target.site, target.index) \
		and _distance() <= _tuning.receiver_reach_m


func signal_strength() -> float:
	if not playing() or not target_valid():
		return 0.0
	var toward := Vector2(target.x - world.world_x(global_position.x), target.z - world.world_z(global_position.z))
	var axis := Vector2(global_basis.z.x, global_basis.z.z).normalized()
	var lobe := pow(absf(axis.dot(toward.normalized())), 2.0) if toward.length_squared() > 0.01 else 1.0
	var range_gain := sqrt(clampf(1.0 - toward.length() / _tuning.receiver_reach_m, 0.0, 1.0))
	var tune_gain := Dial.pull(frequency - Dial.BEACON_KHZ, _tuning.dial_width_khz)
	var dust := clampf(world.weather.field_storm(global_position), 0.0, 1.0)
	return range_gain * lerpf(_tuning.receiver_side_gain, 1.0, lobe) * tune_gain * (1.0 - dust * _tuning.receiver_storm_loss)


func _listen(delta: float) -> void:
	_to_your_ears(carried())
	_teach()
	if scan_pending and playing():
		_acquire()
		scan_pending = false
	strength = signal_strength()
	meter_step = roundi(strength * _tuning.receiver_meter_steps)
	if not playing():
		_clear_signal()
		return
	_hiss()
	if not target_valid():
		said = "Survey receiver · no signal"
		_signal.stop()
		return
	said = "Survey receiver · " + ("faint" if strength < _tuning.receiver_faint else ("steady" if strength < _tuning.receiver_strong else "strong"))
	if strength < _tuning.receiver_signal_min:
		_signal.stop()
	else:
		_loudness()
		_signal.pitch_scale = lerpf(0.85, 1.1, strength)
		_every(delta, lerpf(PING_FAR, PING_NEAR, strength), _pulse_sound)
	var player := world.player
	var personally := player.hands.held == self or player.suit.carried.has(self)
	if personally and tuned_to() == &"beacon" and acquired_from >= _tuning.receiver_approach_m \
			and _distance() <= _tuning.receiver_arrive_m and strength >= _tuning.receiver_deed_strength:
		Deeds.done(world, &"follow_signal")


func _teach() -> void:
	if not _introduced and Controls.ui != null and Controls.playing() \
			and (world.player.hands.held == self or world.player.suit.carried.has(self)
			or world.player.hands.look_device == self):
		_introduced = true
		Controls.ui.teach(HOW_TO, HOW_TO_SAYS)


func _hiss() -> void:
	var dust := clampf(world.weather.field_storm(global_position), 0.0, 1.0)
	var tuned := Dial.pull(frequency - Dial.BEACON_KHZ, _tuning.dial_width_khz)
	var bed := lerpf(_tuning.receiver_hiss_empty, _tuning.receiver_hiss_clear, tuned)
	bed += dust * _tuning.receiver_hiss_storm
	bed *= 1.0 - strength * _tuning.receiver_hiss_duck
	hiss.volume_db = -80.0 if volume <= 0.0 else minf(knob_db(), 3.0) + linear_to_db(maxf(bed, 0.0001))
	if not hiss.playing:
		hiss.play()


func _loudness() -> void:
	if _signal != null:
		_signal.volume_db = -80.0 if volume <= 0.0 else minf(knob_db(), 3.0) + linear_to_db(maxf(strength, 0.0001))


func _clear_signal() -> void:
	strength = 0.0
	_shown_strength = 0.0
	meter_step = 0
	_since_signal = INF
	said = ""
	if _signal != null:
		_signal.stop()
	if hiss != null:
		hiss.stop()


func _process(delta: float) -> void:
	if carried() and hiss != null:
		_to_your_ears(true)
	var k := 1.0 - exp(-delta / TURN_SECONDS)
	_shown_strength = lerpf(_shown_strength, float(meter_step) / _tuning.receiver_meter_steps, k)
	shown_khz = lerpf(shown_khz, frequency, k)
	shown_volume = lerpf(shown_volume, volume, k)
	_show_dial()


func _show_dial() -> void:
	if visual != null:
		visual.present(_shown_strength, -knob_turn(shown_khz), VOLUME_SWEEP * (0.5 - shown_volume))
