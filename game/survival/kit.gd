class_name Kit
extends Resource
## What a run starts with, as data: catalog ids and how many of each. What's
## carried goes into the suit's slots; what's beside you is set down on the
## sand where the run begins, some of it put together.

const STANDARD := "res://game/survival/standard_kit.tres"

## Into the suit's slots, in order.
@export var carried: Dictionary[StringName, int] = {}
## Set down beside you: a catalog id, or the name of something assembled, each
## at its place, m to your right and ahead of where you start.
@export var beside: Dictionary[StringName, Vector2] = {}
## Devices that come put together, by name: "frame", a catalog device, and
## "sockets", what fills them by their place in its list, a part fitted or a
## device seated. A plain device beside you comes with its batteries.
@export var assembled: Dictionary[StringName, Dictionary] = {}
## Lines laid between two things beside you, by name, each a coil's length:
## a floater moored to its stake, the stake to be taken up to tow it.
@export var lines: Dictionary[StringName, StringName] = {}
## How full the batteries in what's beside you start, 0 to 1.
@export var charge := 1.0
## How long a coil or a line beside you lays, m.
@export var rope_m := 12.0


## The kit every run starts with.
static func standard() -> Kit:
	return load(STANDARD)


## What's carried, one id per slot.
func slots() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in carried:
		for i in carried[id]:
			out.append(id)
	return out
