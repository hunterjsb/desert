extends Probe
## A piece's fate is its own: global randomness, load order and what else was
## packed never change it, and the essentials always survive.

func run() -> void:
	var odds := SurveyorManifest.approach(Tuning.current(), &"steep")
	var load: Array[Dictionary] = []
	for spec: Array in SurveyorManifest.EQUIPMENT:
		load.append({"uid": spec[0], "id": spec[1], "durability": 1.0})
	var fates := _fates(1234, load, odds)
	randi()
	check(_fates(1234, load, odds) == fates, "global random calls cannot reroll the opening")
	var reversed := load.duplicate()
	reversed.reverse()
	check(_fates(1234, reversed, odds) == fates, "load order cannot change a fate")
	var fewer: Array[Dictionary] = []
	fewer.assign(load.filter(func(item: Dictionary) -> bool: return item.uid != &"compass"))
	var without := fates.duplicate()
	without.erase(&"compass")
	check(_fates(1234, fewer, odds) == without, "leaving one store behind cannot change another's fate")
	var changed := false
	for run_seed in [1, 2, 3, 4, 5, 6, 7, 8]:
		var other := _fates(run_seed, load, odds)
		changed = changed or other != fates
		for uid in SurveyorManifest.essentials():
			check(other[uid][0], "seed %d keeps the %s" % [run_seed, uid])
	check(changed, "another seed lands a different opening")


func _fates(run_seed: int, load: Array[Dictionary], odds: Dictionary) -> Dictionary:
	var resolved := SurveyorManifest.resolve(run_seed, Vector3.UP, load, odds)
	var out := {}
	for entry: Dictionary in resolved.structure + resolved.equipment:
		out[entry.uid] = [entry.survives, entry.state.get("durability", -1.0)]
	return out
