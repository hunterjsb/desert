class_name SailingAid
extends RefCounted
## One Console works its rig's real controls; losing authority leaves their brakes set.

enum Mode { HAND, TRIM, STEER }
var mode := Mode.HAND
var course := Vector2.ZERO
var home := false
var ideal := {}
var _at := -INF
var _job: SailingIdeal
var refresh_us := 0
var solves := 0


func rig(console: Console) -> Mast:
	if not console.running() or not console.gear().has("anemometer") or not console._root() is Chassis:
		return null
	for device: Device in console._root().mounted():
		if device is Mast and device.sail() != null:
			return device
	return null


func target(console: Console) -> Vector2:
	if home:
		var fix := console.world.home.nav()
		if is_nan(fix.metres) or fix.metres < console.world.tuning.sailing_aid_arrive_m:
			return Vector2.ZERO
		return Vector2(sin(fix.bearing), -cos(fix.bearing)) * -console.world.moon.north().z
	if course == Vector2.ZERO:
		course = SailingIdeal.heading_of(console._root())
	return course


func tick(console: Console) -> void:
	if not console.running():
		ideal.clear()
		_job = null
		mode = Mode.HAND
		return
	if mode == Mode.HAND or ideal.is_empty():
		return
	var mast := ideal.get("mast") as Mast
	if not is_instance_valid(mast) or mast.carrier() != console._root() or mast.sail() == null:
		ideal.clear()
		mode = Mode.HAND
		return
	var sheet := mast.sheet()
	var drum: ManualWinch
	var helm: Helm
	for device: Device in console._system():
		if device is ManualWinch and device.line() == sheet:
			drum = device
		if device is Helm and device.steers and device.rider != null:
			helm = device
	if drum == null or sheet == null:
		mode = Mode.HAND
		return
	drum.trim_by(console, ideal.length)
	if mode == Mode.STEER:
		if helm == null or SailingIdeal.support(console._root()).x <= 0.0:
			mode = Mode.TRIM
		else:
			helm.steer_by(console, ideal.heading)


## Small render-frame slices keep the polar search off the physics clock.
func refresh(console: Console) -> void:
	var started := Time.get_ticks_usec()
	refresh_us = 0
	if not console.running():
		_job = null
		ideal.clear()
		mode = Mode.HAND
		return
	var now := console.world.time
	if _job == null and (now < _at or now >= _at + console.world.tuning.sailing_aid_every):
		_at = now
		var mast := rig(console)
		if mast == null or console._lead() != console:
			ideal.clear()
			mode = Mode.HAND
			return
		_job = SailingIdeal.new()
		if not _job.begin(mast, target(console)):
			_job = null
			ideal.clear()
	while _job != null and Time.get_ticks_usec() - started < console.world.tuning.sailing_aid_budget_us:
		if _job.advance():
			ideal = _job.result
			solves += 1
			_job = null
	refresh_us = Time.get_ticks_usec() - started


func choose(console: Console, to: Mode) -> void:
	mode = to
	_at = -INF
	_job = null
	if course == Vector2.ZERO:
		course = SailingIdeal.heading_of(console._root())


func winch(console: Console) -> ManualWinch:
	var mast := rig(console)
	if mast == null or mast.sheet() == null:
		return null
	for device: Device in console._system():
		if device is ManualWinch and device.line() == mast.sheet():
			return device
	return null


func cycle(console: Console) -> void:
	var next := (mode + 1) % 3
	if next == Mode.STEER:
		var seated := false
		for device: Device in console._system():
			if device is Helm and device.steers and device.rider != null:
				seated = true
		if not seated or SailingIdeal.support(console._root()).x <= 0.0:
			next = Mode.HAND
	choose(console, next as Mode)


func aim(console: Console, at_home: bool) -> void:
	home = at_home
	ideal.clear()
	if not home:
		course = SailingIdeal.heading_of(console._root())
	_at = -INF
	_job = null
