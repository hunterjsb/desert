class_name WreckPlan
extends RefCounted
## What scrapping a wreck takes, as data on its kit piece (`Piece.wreck`):
## the plates welded over its openings, cut away by tracing their seams with
## a heat cutter; the holds storm-packed with sand, cleared with a scoop a
## slice at a time from their open end; and which of its sockets are modules,
## whole devices held fast until what's in their way is gone, some with a
## hazard riding on them. No digging and nothing underground: the sand you
## clear is inside the wreck, where the storms packed it. Wreckage builds it
## on the ground.
##
## Plan metres in the piece's own frame, leaning with it.

## A seam is cut a cell this long at a time, m.
const CELL := 0.1
## The ways a hold clears: down from its top, level whatever the wreck's lean,
## or in from one end along a plan axis.
const TOP := Vector3.UP

## How hard its plates are to cut: times the seconds a metre of seam takes.
var armour := 1.0
var plates: Array[Plate] = []
var holds: Array[Hold] = []
## Socket index -> Module.
var modules := {}


## A plate welded over an opening, its seams round its outer face.
class Plate:
	var box: AABB
	## The plate's thin axis (0 u, 1 y, 2 v) and which way its outer face
	## looks along it.
	var thin := 0
	var out := 1.0
	var label := ""
	## Every cell of every seam: its middle on the outer face, plan, and the
	## way its seam runs.
	var cells := PackedVector3Array()
	var runs := PackedVector3Array()

	## The outer face's middle, plan.
	func face() -> Vector3:
		var at := box.get_center()
		at[thin] += out * box.size[thin] * 0.5
		return at

	## The way out of its outer face, plan.
	func normal() -> Vector3:
		var n := Vector3.ZERO
		n[thin] = out
		return n

	## Its area, m².
	func area() -> float:
		var s := box.size
		s[thin] = 1.0
		return s.x * s.y * s.z

	## Seams along the edges of its outer face: `welded` says which, as
	## booleans for its low and high edge along each of its two face axes.
	func weld(welded: Array) -> void:
		var axes := [(thin + 1) % 3, (thin + 2) % 3]
		var f := face()
		var k := 0
		for a in 2:
			var along: int = axes[a]
			var across: int = axes[1 - a]
			for side in [-1.0, 1.0]:
				if welded[k]:
					var from := f
					from[across] += side * (box.size[across] * 0.5 - CELL * 0.5)
					from[along] -= box.size[along] * 0.5
					var run := Vector3.ZERO
					run[along] = 1.0
					var count := maxi(1, roundi(box.size[along] / CELL))
					var step := box.size[along] / count
					for c in count:
						var at := from
						at[along] += step * (c + 0.5)
						cells.append(at)
						runs.append(run)
				k += 1


## A hold storm-packed with sand, in slices cleared from its open end.
class Hold:
	var box: AABB
	var slices := 3
	## TOP, or the plan way out of its open end.
	var from := TOP
	var label := ""
	## How it got in: said as you look at it.
	var how := ""


## A module: a socket's device held fast until what it needs is gone.
## `needs` as [&"plate", i] or [&"hold", i, slices cleared from its open
## end]; a hazard rides on some, its box's middle at `at`.
class Module:
	var socket := 0
	var needs: Array = []
	var hazard := &""
	var at := Vector3.ZERO


func plate(lo: Vector3, hi: Vector3, thin: int, out: float, label: String, welded := [true, true, true, true]) -> int:
	var p := Plate.new()
	p.box = AABB(lo, hi - lo)
	p.thin = thin
	p.out = out
	p.label = label
	p.weld(welded)
	plates.append(p)
	return plates.size() - 1


func hold(lo: Vector3, hi: Vector3, slices: int, from: Vector3, label: String, how: String) -> int:
	var h := Hold.new()
	h.box = AABB(lo, hi - lo)
	h.slices = slices
	h.from = from
	h.label = label
	h.how = how
	holds.append(h)
	return holds.size() - 1


func module(socket: int, needs: Array, hazard := &"", at := Vector3.ZERO) -> void:
	var m := Module.new()
	m.socket = socket
	m.needs = needs
	m.hazard = hazard
	m.at = at
	modules[socket] = m
