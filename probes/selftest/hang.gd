extends Probe
## Selftest: never finishes, so the runner's timeout must catch it.


func run() -> void:
	await get_tree().create_timer(1.0e9).timeout
