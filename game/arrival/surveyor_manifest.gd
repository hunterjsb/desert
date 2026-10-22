class_name SurveyorManifest
extends RefCounted
## Resolved impact data, never an equipment grant. Save it rather than rolling again.
const VERSION := 2
const APPROACHES: Array[StringName] = [&"shallow", &"standard", &"steep"]
## Authored pod roles agree with PodShell's actual chassis and frames; floors always survive.
const STRUCTURE := [
	[&"floor_a", &"chassis", true],
	[&"floor_b", &"chassis", true],
	[&"frame_a", &"frame", false],
	[&"frame_b", &"frame", false],
	[&"roof_a", &"chassis", false],
	[&"roof_b", &"chassis", false],
	[&"side_front_a", &"chassis", false],
	[&"side_front_b", &"chassis", false],
	[&"side_back_a", &"chassis", false],
	[&"side_back_b", &"chassis", false],
	[&"hatch", &"chassis", false],
	[&"tail", &"chassis", false],
]
## The ship's stores. Essentials start in the pod, must be aboard to launch and always survive.
const EQUIPMENT := [
	[&"water", &"canister", true],
	[&"food", &"ration", true],
	[&"shield", &"light_shield", true],
	[&"camp_cell", &"battery", true],
	[&"guide", &"surveyor_guide", false],
	[&"beacon", &"home_beacon", false],
	[&"panel", &"light_panel", false],
	[&"stake", &"stake", false],
	[&"rope", &"coil", false],
	[&"board", &"board", false],
	[&"board_cell", &"battery", false],
	[&"compass", &"compass", false],
	[&"bedroll", &"bedroll", false],
	[&"tray_a", &"hover_tray", false],
	[&"tray_b", &"hover_tray", false],
	[&"hook", &"hook", false],
]


static func essentials() -> Array[StringName]:
	var out: Array[StringName] = []
	for spec: Array in EQUIPMENT:
		if spec[2]:
			out.append(spec[0])
	return out


## One approach's odds and timing, kept with the save so a resume never re-reads tuning.
static func approach(tuning: Tuning, id: StringName) -> Dictionary:
	var i := maxi(APPROACHES.find(id), 0)
	return {"id": APPROACHES[i], "entry_s": tuning.arrival_entry_s[i],
		"frame_survival": tuning.arrival_frame_survival[i], "outer_survival": tuning.arrival_outer_survival[i],
		"extra_survival": tuning.arrival_extra_survival[i],
		"chassis_wear": Vector2(tuning.arrival_chassis_wear_low[i], tuning.arrival_chassis_wear_high[i]),
		"device_wear": Vector2(tuning.arrival_device_wear_low[i], tuning.arrival_device_wear_high[i]),
		"usable_min": tuning.arrival_usable_min}


## Each piece rolls on its own identity: what else you packed never changes its fate.
static func resolve(run_seed: int, landing_point: Vector3, loaded: Array[Dictionary], odds: Dictionary) -> Dictionary:
	var structure: Array[Dictionary] = []
	for spec: Array in STRUCTURE:
		var chance: float = odds.frame_survival if spec[1] == &"frame" else odds.outer_survival
		var rng := _rng(run_seed, spec[0])
		var entry := {"uid": spec[0], "id": spec[1], "parent": &"", "essential": spec[2],
			"survives": spec[2] or rng.randf() < chance, "state": {}, "recovered": false}
		if spec[1] == &"chassis":
			entry.state.durability = _fraction(rng, odds.chassis_wear, odds.usable_min) if entry.survives else 0.0
		structure.append(entry)
	var essential := essentials()
	var equipment: Array[Dictionary] = []
	for item: Dictionary in loaded:
		var uid: StringName = item.uid
		var rng := _rng(run_seed, uid)
		var kept: bool = uid in essential
		var entry := {"uid": uid, "id": item.id, "parent": item.get("parent", &""), "essential": kept,
			"survives": kept or rng.randf() < float(odds.extra_survival),
			"state": {}, "recovered": false, "placement": &"loaded"}
		if item.has("durability"):
			entry.state.durability = float(item.durability) * (1.0 if kept else _fraction(rng, odds.device_wear, odds.usable_min))
		equipment.append(entry)
	return {"version": VERSION, "seed": run_seed, "landing_point": landing_point,
		"structure": structure, "equipment": equipment}


static func _rng(run_seed: int, uid: StringName) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, uid, &"surveyor_impact", VERSION])
	return rng


static func _fraction(rng: RandomNumberGenerator, span: Vector2, usable_min: float) -> float:
	return clampf(rng.randf_range(minf(span.x, span.y), maxf(span.x, span.y)), usable_min, 1.0)
