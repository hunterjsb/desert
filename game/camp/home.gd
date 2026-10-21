class_name CampHome
extends Node
## One explicitly marked travelling camp; support is confirmed by World.
signal changed
var world: World
var beacon: HomeBeacon
var root: Chassis
var members: Array[RigidBody3D] = []
var anchor: Sites.Anchor
var bounds := Rect2()
var revision := 0
var supported := false

func has_home() -> bool:
	return is_instance_valid(root)

func contains(body: Node) -> bool:
	return is_instance_valid(body) and members.has(body)

func mark(_marker: HomeBeacon) -> String:
	return "home support is not ready"

func unmark() -> String:
	return "home support is not ready"

func refresh() -> void:
	pass

func nav() -> Dictionary:
	return {"marked": has_home(), "supported": supported, "live": false,
		"metres": 0.0, "bearing": 0.0, "status": "No home marked"}

func snapshot(_ref: Callable) -> Dictionary:
	return {}

func prepare_restore(_data: Dictionary) -> void:
	pass

func finish_restore(_data: Dictionary, _resolve: Callable) -> void:
	pass
