class_name Tuning
extends Resource
## Every tuning number in the game. Values live in res://game/tuning.tres,
## so tuning never means editing code. Probes override fields on current().

const PATH := "res://game/tuning.tres"

## The run's seed. 0 picks a fresh one each run.
@export var run_seed: int = 0


static func current() -> Tuning:
	return load(PATH)
