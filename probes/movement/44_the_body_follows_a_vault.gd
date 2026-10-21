extends "res://probes/movement/43_board_the_powered_chassis.gd"
## Free hands visibly reach during the actual swept climb, with original
## bone lengths and no visual pose write to the physical player's state.
var frames := 0
var forward := INF
var gathered := 0.0
var length_error := 0.0

func run() -> void:
	process_priority = 100
	await super.run()
	print("VAULT_BODY frames%d hand_forward%.3f foot_height%.3f bone_error%.6f" % [frames, forward, gathered, length_error])
	check(frames > 2 and forward < -0.1 and gathered > SurveyorLooks.KNEE.y, "free hands reach forward and a boot gathers above knee height during the actual climb")
	check(length_error < 0.0001, "the climbing suit retains its original limb lengths")
	var before := player.global_transform
	var velocity := player.velocity
	var capsule := player.posture.shape.shape
	player.body.pose(0.0)
	check(player.global_transform == before and player.velocity == velocity
		and player.posture.shape.shape == capsule
		and player.body.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"posing the suit changes no physical player state or collision geometry")

func _process(_delta: float) -> void:
	if player == null or not player.vault.active:
		return
	frames += 1
	var body := player.body
	for side in ["r", "l"]:
		var upper := body.get_node(NodePath("upper_arm_" + side)) as Node3D
		var forearm := body.get_node(NodePath("forearm_" + side)) as Node3D
		var hand := body.get_node(NodePath("hand_" + side)) as Node3D
		var foot := body.get_node(NodePath("foot_" + side)) as Node3D
		forward = minf(forward, body.to_local(hand.to_global(Vector3(0, -Body.GRIP, 0))).z)
		gathered = maxf(gathered, foot.position.y)
		length_error = maxf(length_error, absf(upper.position.distance_to(forearm.position) - Body.UPPER_ARM))
		length_error = maxf(length_error, absf(forearm.position.distance_to(hand.position) - Body.FOREARM))
