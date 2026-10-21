class_name SurveyorManifest
extends RefCounted
## Resolved arrival data, never an equipment grant. Save it rather than rolling again.

const VERSION := 1
## Authored pod roles agree with SurveyorPod's actual chassis and frames.
const STRUCTURE := [
	[&"floor_a", &"chassis", &"", true],
	[&"floor_b", &"chassis", &"floor_a", true],
	[&"frame_a", &"frame", &"floor_a", false],
	[&"frame_b", &"frame", &"floor_b", false],
	[&"roof_a", &"chassis", &"frame_a", false],
	[&"roof_b", &"chassis", &"frame_b", false],
	[&"side_front_a", &"chassis", &"frame_a", false],
	[&"side_front_b", &"chassis", &"frame_b", false],
	[&"side_back_a", &"chassis", &"frame_a", false],
	[&"side_back_b", &"chassis", &"frame_b", false],
	[&"hatch", &"chassis", &"frame_a", false],
	[&"tail", &"chassis", &"frame_b", false],
]
## The first two floors protect survival gear; optional losses change camp mobility.
const EQUIPMENT := [
	[&"water", &"canister", &"floor_a", true, &"supply"],
	[&"food", &"ration", &"floor_a", true, &"supply"],
	[&"guide", &"surveyor_guide", &"floor_a", true, &"device"],
	[&"beacon", &"home_beacon", &"floor_a", true, &"device"],
	[&"shield", &"light_shield", &"floor_a", true, &"device"],
	[&"camp_cell", &"battery", &"floor_a", true, &"cell"],
	[&"panel", &"light_panel", &"floor_a", true, &"device"],
	[&"stake", &"stake", &"floor_b", true, &"part"],
	[&"rope", &"coil", &"floor_b", true, &"rope"],
	[&"board", &"board", &"floor_b", true, &"device"],
	[&"board_cell", &"battery", &"board", true, &"cell"],
	[&"compass", &"compass", &"floor_b", false, &"part"],
	[&"bedroll", &"bedroll", &"floor_b", false, &"device"],
	[&"tray_a", &"hover_tray", &"floor_a", false, &"part"],
	[&"tray_b", &"hover_tray", &"floor_b", false, &"part"],
	[&"hook", &"hook", &"floor_a", true, &"part"],
]


## Exact probabilities and ranges are provisional balance in the tuning resource.
static func resolve(run_seed: int, landing_point: Vector3, rules: Dictionary = {}) -> Dictionary:
	assert(landing_point.is_finite() and is_equal_approx(landing_point.length_squared(), 1.0), "arrival needs a geographic unit point")
	var config := Tuning.current().surveyor_arrival.duplicate(true)
	config.merge(rules, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, &"surveyor_arrival", VERSION])
	var structure: Array[Dictionary] = []
	for spec: Array in STRUCTURE:
		var chance: float = config.frame_survival if spec[1] == &"frame" else config.outer_survival
		var entry := _entry(spec, rng, chance)
		if spec[1] == &"chassis":
			entry.state.durability = _fraction(rng, config.chassis_durability, config.usable_min) if entry.survives else 0.0
		structure.append(entry)
	var equipment: Array[Dictionary] = []
	var cargo_order: Array[StringName] = []
	for spec: Array in EQUIPMENT:
		var entry := _entry(spec, rng, config.extra_survival)
		match spec[4]:
			&"device":
				entry.state.durability = _fraction(rng, config.device_durability, config.usable_min)
			&"cell":
				entry.state.charge_fraction = _fraction(rng, config.board_charge if spec[0] == &"board_cell" else config.camp_charge, config.usable_min)
			&"supply":
				entry.state.fill_fraction = _fraction(rng, config.supply_fill, config.usable_min)
			&"rope":
				entry.state.metres = config.rope_m
		entry.placement = &"fitted" if spec[0] == &"board_cell" else &"stowed"
		equipment.append(entry)
		if entry.survives and entry.placement == &"stowed":
			cargo_order.append(entry.uid)
	# Shuffle locally: unrelated random calls and inventory order cannot change arrival.
	for i in range(cargo_order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var was := cargo_order[i]
		cargo_order[i] = cargo_order[j]
		cargo_order[j] = was
	var survived := {}
	for entry in structure + equipment:
		survived[entry.uid] = entry.survives
	for entry in structure + equipment:
		entry.detached = entry.parent != &"" and not survived.get(entry.parent, false)
	return {"version": VERSION, "seed": run_seed, "landing_point": landing_point,
		"phase": &"orbit", "structure": structure, "equipment": equipment, "cargo_order": cargo_order}


static func _entry(spec: Array, rng: RandomNumberGenerator, chance: float) -> Dictionary:
	return {"uid": spec[0], "id": spec[1], "parent": spec[2], "essential": spec[3],
		"survives": bool(spec[3]) or rng.randf() < chance, "state": {}, "recovered": false}


static func _fraction(rng: RandomNumberGenerator, span: Vector2, usable_min: float) -> float:
	return clampf(rng.randf_range(minf(span.x, span.y), maxf(span.x, span.y)), usable_min, 1.0)
