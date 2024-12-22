extends RigidBody3D

func _ready():
	pass


func _process(delta):
	if global_position.y < -100:
		print("shield probably fell out of the world")
