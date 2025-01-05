extends InteractableBody3D

@export_group("Energy")
@export var starting_energy = 999
@export var energy_cost = 1

@export_group("Visual")
@export var tween_time = 0.6

@onready var energy = starting_energy
@onready var bubble_shield_area = $BubbleShield
const MIN_SCALE = 0.001

var is_active := false

signal player_entered_bubble(player)
signal player_exited_bubble(player)


func _ready():
	# BubbleShield area is hidden by default
	bubble_shield_area.visible = false
	bubble_shield_area.monitoring = false
	bubble_shield_area.monitorable = false
	bubble_shield_area.scale = Vector3(MIN_SCALE, MIN_SCALE, MIN_SCALE)

	bubble_shield_area.body_entered.connect(_on_bubble_body_entered)
	bubble_shield_area.body_exited.connect(_on_bubble_body_exited)
	
	set_energy_label_visible(false)
	add_to_group("bubble_shield")  # So Player can find & connect to these if needed.


func _process(delta):
	if is_active:
		energy -= energy_cost * delta
		if energy <= 0:
			energy = 0
			if is_active:  # Shield still on? Turn it off.
				toggle_bubble_shield()

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


# Helper so we can show/hide the energy label easily
func set_energy_label_visible(make_visible: bool) -> void:
	$EnergyLabel.visible = make_visible
