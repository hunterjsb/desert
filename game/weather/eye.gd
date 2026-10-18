class_name Eye
extends RefCounted
## The camera adapts to the light as an eye does (Hunter, 2026-10-17: "add eye
## adaptation"), by how bright the frame it sees is (EyeMeter), so Tu's light
## stays physical and the eye does the rest. Only once the frame is dim does it
## open, and then it makes up only a share of each further stop, so night still
## reads as night and a storm stays oppressive; never so far that the brightest
## patch in view, such as Tu's disc at night, burns out; and never past a floor,
## where a black night stays black.
##
## As an eye it has two parts. The retina carries the adaptation and opens
## slowly; the pupil opens the first stop or so over it in a few seconds. Both
## close fast. So stepping into the dark you see a little within seconds and
## more over the half-minute after; and a glance at Tu, which closes it, costs
## only the pupil's few seconds to get back.

## It eases into the last of a change over this many stops.
const EASE := 0.25
## It takes in the light over about this long, s, as an eye does, so dust
## flickering past in a storm never pumps it.
const TAKES_IN := 0.5
## A cut (a new run, a clock jump, a teleport) takes this many readings to
## show; the eye snaps to each until then, as it never carries over a cut.
const SETTLE_READINGS := 6
const LN2 := 0.6931471805599453

## How far open it is, stops over the tuning's exposure: the retina's and the
## pupil's together.
var stops := 0.0
var retina := 0.0
var pupil := 0.0
## The light it has taken in, stops: the frames' mean light, and their
## brightest patch. NAN before the first reading.
var seen := NAN
var seen_bright := NAN
## The last frame's reading, before it's taken in.
var reading := Vector2(NAN, NAN)

var _tuning: Tuning
var _settling := SETTLE_READINGS


func _init(tuning: Tuning) -> void:
	_tuning = tuning


## The exposure it puts on the tuning's.
func exposure() -> float:
	return pow(2.0, stops)


## How far open it would be, settled on a frame of this reading.
func wanted(brightness: float, bright: float) -> float:
	var opened := _tuning.eye_share * (_stops(_tuning.eye_dim) - brightness)
	return clampf(minf(opened, _stops(_tuning.eye_white) - bright), 0.0, _stops(_tuning.eye_most))


## Each frame's reading from the meter.
func see(brightness: float, bright: float) -> void:
	reading = Vector2(brightness, bright)
	if _settling > 0 or is_nan(seen):
		seen = brightness
		seen_bright = bright
	if _settling > 0:
		_settling -= 1
		retina = wanted(seen, seen_bright)
		pupil = 0.0
		stops = retina


## Snaps to the next few frames, after a cut.
func settle() -> void:
	_settling = SETTLE_READINGS


## Toward what the light it has taken in wants, by real time.
func adapt(delta: float) -> void:
	if not _tuning.eye_adapts:
		retina = 0.0
		pupil = 0.0
		stops = 0.0
		return
	if is_nan(seen):
		return
	var taken := 1.0 - exp(-delta / TAKES_IN)
	seen = lerpf(seen, reading.x, taken)
	seen_bright = lerpf(seen_bright, reading.y, taken)
	var want := wanted(seen, seen_bright)
	retina = _toward(retina, want, _tuning.eye_slow_rate, delta)
	pupil = _toward(pupil, clampf(want - retina, 0.0, _tuning.eye_quick_stops), _tuning.eye_open_rate, delta)
	# As the retina takes over from the pupil, the two never open past what's wanted.
	if retina + pupil > maxf(want, stops):
		pupil = maxf(want - retina, 0.0)
	stops = retina + pupil


## A step from one opening toward another: opening at most `opening` stops a
## second, closing at the tuning's close rate, easing into the last of either.
func _toward(from: float, to: float, opening: float, delta: float) -> float:
	var gap := to - from
	var rate := opening if gap > 0.0 else _tuning.eye_close_rate
	return from + signf(gap) * minf(rate * minf(absf(gap) / EASE, 1.0) * delta, absf(gap))


static func _stops(light: float) -> float:
	return log(light) / LN2
