extends CanvasLayer
## What the screen shows before any instruments exist: how you're moving, and
## whether the dev clock is running fast.

@onready var _world: World = $"../World"
@onready var _mode: Label = $Mode


func _process(_delta: float) -> void:
	var text := _world.player.mode.to_upper()
	if _world.time_warp != 1.0:
		text += "    TIME x%d" % _world.time_warp
	_mode.text = text
