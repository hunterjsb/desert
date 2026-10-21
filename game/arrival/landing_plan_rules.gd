class_name LandingPlanRules
extends Resource
## Regional survey limits and the conservative pod/exit ground requirement.

@export var candidate_count := 4
@export var corridor_radius_m := 2800.0
@export var signal_walk_m := Vector2(250.0, 750.0)
@export var attempts_per_signal := 12
@export var signal_limit := 64
@export var footprint_half_m := 5.0
@export var footprint_rise_m := 0.7
@export var structure_clear_m := 20.0
@export var detectable_height_m := 0.5
@export var distance_band_m := 250.0
@export var candidate_spacing_m := 180.0
