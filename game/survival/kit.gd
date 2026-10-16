class_name Kit
extends Resource
## What a run starts with, as data: catalog ids and how many of each. What's
## carried goes into the suit's slots; what's beside you is set down on the
## sand where the run begins.

const STANDARD := "res://game/survival/standard_kit.tres"

## Into the suit's slots, in order.
@export var carried: Dictionary[StringName, int] = {}
## Set down beside you, in a row ahead, in order.
@export var beside: Dictionary[StringName, int] = {}
## How full the batteries in what's beside you start, 0 to 1.
@export var charge := 1.0
## How long a coil beside you lays, m.
@export var rope_m := 12.0
## Whether what's beside you starts cabled together: the first device with a
## port to each other one with a port.
@export var wired := false


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
