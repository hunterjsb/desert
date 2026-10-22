extends "res://probes/movement/43_board_the_powered_chassis.gd"
## Runs alone
## Free hands visibly reach and a boot gathers during the actual swept climb.
var frames := 0
var forward := INF
var gathered := 0.0

func run() -> void:
	process_priority = 100
	await super.run()
	print("VAULT_BODY frames%d hand_forward%.3f foot_height%.3f" % [frames, forward, gathered])
	check(frames > 2 and forward < -0.1 and gathered > SurveyorLooks.KNEE.y, "free hands reach forward and a boot gathers above knee height during the actual climb")

func _process(_delta: float) -> void:
	if player == null or not player.vault.active:
		return
	frames += 1
	var body := player.body
	for side in ["r", "l"]:
		var hand := body.get_node(NodePath("hand_" + side)) as Node3D
		var foot := body.get_node(NodePath("foot_" + side)) as Node3D
		forward = minf(forward, body.to_local(hand.to_global(Vector3(0, -Body.GRIP, 0))).z)
		gathered = maxf(gathered, foot.position.y)
