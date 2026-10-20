class_name Remedy
extends Part
## A med kit: used in your hands or from what you carry, it cures a sickness
## and is used up. With nothing to cure, it's kept.


func use(by: Player, _at: Vector3) -> bool:
	if not by.vitals.wounds.cure():
		return false
	if by.suit.carried.has(self):
		by.suit.discard(self)
		return true
	if by.hands.held == self:
		by.hands.stow()
	queue_free()
	return true
