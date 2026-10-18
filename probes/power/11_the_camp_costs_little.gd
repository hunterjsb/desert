extends CampProbe
## Power probe 11: the camp costs little. Parked and running, the reference
## camp's work each tick, its scripts' ticking and drawing, comes to at most
## MOST times the same world's just before it was parked, so a slow machine
## is slow on both sides of the sum. It was five to six times before the
## 2026-10-18 pass, and about two after.
## Runs alone: it times real frames.

const MOST := 3.0
const TICKS := 600

var _costs := PackedFloat64Array()
var _drawn := 0


## Brackets every script's turn in a tick and in a frame, first and last.
class Edge extends Node:
	var probe
	var first := true

	func _physics_process(_delta: float) -> void:
		if first:
			probe.set_meta(&"tick_from", Time.get_ticks_usec())
		else:
			probe._tick(Time.get_ticks_usec() - probe.get_meta(&"tick_from"))

	func _process(_delta: float) -> void:
		if first:
			probe.set_meta(&"frame_from", Time.get_ticks_usec())
		else:
			probe._drawn += Time.get_ticks_usec() - probe.get_meta(&"frame_from")


func run() -> void:
	await load_camp(0.0, false)
	for first in [true, false]:
		var edge := Edge.new()
		edge.probe = self
		edge.first = first
		edge.process_priority = -1000000 if first else 1000000
		edge.process_physics_priority = edge.process_priority
		add_child(edge)
	await physics_frames(120)
	var bare := await _cost()
	park()
	await physics_frames(300)
	var parked := await _cost()
	print("the world alone %.2f ms a tick, with the camp %.2f ms: %.2f times" % [bare, parked, parked / bare])
	check(parked < bare * MOST, "the camp at most %.1f times the world alone" % MOST)


func _tick(usec: int) -> void:
	_costs.append((usec + _drawn) / 1000.0)
	_drawn = 0


## A tick's work, ms, on average over TICKS ticks bar the slowest twentieth:
## a busy machine takes the main thread away now and then.
func _cost() -> float:
	_costs.clear()
	_drawn = 0
	await physics_frames(TICKS)
	_costs.sort()
	var kept := _costs.slice(0, int(_costs.size() * 0.95))
	var total := 0.0
	for c in kept:
		total += c
	return total / kept.size()
