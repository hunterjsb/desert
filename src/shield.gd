extends Node3D

signal player_entered_bubble(player)
signal player_exited_bubble(player)

@onready var bubble_shield_area = $BubbleShield
var is_active := false

const MIN_SCALE = 0.001
@export var tween_time = 0.6

func _ready():
	# BubbleShield area is hidden by default
	bubble_shield_area.visible = false
	bubble_shield_area.monitoring = false
	bubble_shield_area.monitorable = false
	bubble_shield_area.scale = Vector3(MIN_SCALE, MIN_SCALE, MIN_SCALE)

	bubble_shield_area.body_entered.connect(_on_bubble_body_entered)
	bubble_shield_area.body_exited.connect(_on_bubble_body_exited)

func _process(delta):
	if global_position.y < -100:
		print("shield probably fell out of the world")

func _on_bubble_body_entered(body: Node):
	# Only emit signal if it's specifically the Player
	if body.name == "Player":
		emit_signal("player_entered_bubble", body)
		print("Player entered the bubble shield!")

func _on_bubble_body_exited(body: Node):
	if body.name == "Player":
		emit_signal("player_exited_bubble", body)
		print("Player exited the bubble shield!")


func toggle_bubble_shield():
	is_active = !is_active
	if !is_active:
		$ShieldDeactivateAudio.play()
	else:
		$ShieldActivateAudio.play()
	
	if is_active:
		$BubbleShield.visible = true
		$BubbleShield.monitoring = true
		$BubbleShield.monitorable = true
		$BubbleShield.scale = Vector3(MIN_SCALE, MIN_SCALE, MIN_SCALE)
		
		# Start hum
		if not $ShieldHumAudio.playing:
			$ShieldHumAudio.play()
		
		create_tween().tween_property(
			$BubbleShield,
			"scale",
			Vector3.ONE,
			tween_time
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	else:
		create_tween().tween_property(
			$BubbleShield,
			"scale",
			Vector3(MIN_SCALE, MIN_SCALE, MIN_SCALE),
			tween_time
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		await get_tree().create_timer(tween_time).timeout
		$BubbleShield.visible = false
		$BubbleShield.monitoring = false
		$BubbleShield.monitorable = false
		
		# Stop the hum when shield goes off
		if $ShieldHumAudio.playing:
			$ShieldHumAudio.stop()

func interact(player: Node):
	toggle_bubble_shield()
	
func pickup(player: Node):
	pass
