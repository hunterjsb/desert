extends Probe
## Selftest: a runtime script error must count against the probe.


func run() -> void:
	var nothing: Node = null
	nothing.queue_free()
