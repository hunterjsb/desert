class_name EarthStake
extends Device
## The earth stake (the radio-equipment lab's): a copper rod driven into the
## sand, a clamp, and up top an insulated ring with a spark gap beside it.
## Set down within kite_earth_m of an antenna kite's reel or the set it's
## clipped to, it earths the rig: what charge the kite's line gathers past
## the gap's threshold leaps the gap to earth instead of riding down into the
## set (AntennaKite). Carried or in your hands it earths nothing.

const GROUP := &"earth_stakes"
## Where its spark gap is, from its middle (RadioKitLooks.STAKE_GAP).
const GAP := Vector3(0.015, 0.512, 0.026)
## A spark shows at most this often, s.
const SPARK_EVERY := 0.25

var _sparked_at := -INF


func _init() -> void:
	carryable = true
	add_to_group(GROUP)


## Whether it earths anything: set down in the world, not on you or in your hands.
func earthed() -> bool:
	if not is_inside_tree() or has_meta(&"carried") or wrecked():
		return false
	return world == null or world.player == null or world.player.hands.held != self


## The charge leaping its gap: a small bright crack and a few sparks.
func spark() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _sparked_at < SPARK_EVERY:
		return
	_sparked_at = now
	ScrapFx.burst(world.content, global_transform * GAP, 8, 1.5)
	Sounds.play_at(self, Sounds.ZAP, -10.0)
