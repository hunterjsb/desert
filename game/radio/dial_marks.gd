class_name DialMarks
extends RefCounted
## The frequencies marked on the radio this run, low to high: {khz, name,
## color (as html)}. They belong to the run and its save, not to you: a
## carrier is the seed's, and wanders day by day (Dial.walk).

static var _marks: Array = []
static var _for := []
## Counts every change, so each radio redraws its ticks once after one.
static var version := 0


## Every mark of the run the world is in.
static func all(world: World) -> Array:
	_of(world)
	return _marks.duplicate(true)


## The mark within `near` kHz of a frequency, or {}.
static func at(world: World, khz: float, near: float) -> Dictionary:
	for each: Dictionary in all(world):
		if absf(each.khz - khz) <= near:
			return each
	return {}


## A frequency marked with a name and a colour, in place of any within `near` kHz of it.
static func add(world: World, khz: float, name: String, color: Color, near: float) -> void:
	remove(world, khz, near)
	_marks.append({"khz": khz, "name": name, "color": color.to_html(false)})
	_marks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.khz < b.khz)
	version += 1


## Any mark within `near` kHz of a frequency taken off. Says whether there was one.
static func remove(world: World, khz: float, near: float) -> bool:
	_of(world)
	var before := _marks.size()
	_marks = _marks.filter(func(each: Dictionary) -> bool: return absf(each.khz - khz) > near)
	version += 1
	return _marks.size() < before


## A save's marks, as the run it belongs to resumes.
static func restore(world: World, saved: Array) -> void:
	_of(world)
	_marks = saved.duplicate(true)
	version += 1


## A new run starts with none.
static func _of(world: World) -> void:
	var run := [world.run_seed, world.start, world.began]
	if _for != run:
		_for = run
		_marks = []
		version += 1
