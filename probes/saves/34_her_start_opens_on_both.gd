extends Probe
## Profile & saves probe 34: the Archaeologist's start stays locked until both
## of her deeds are done. Field Kit alone leaves her ????, unmarked; Spadework
## then opens her and marks her new; each says it opens her, and in the other
## order the same.


func run() -> void:
	var profile := get_node(^"/root/Profile")
	var her := Kit.named(&"archaeologist")
	check(her != null and not her.balanced, "she's an origin, a novelty one")
	if her == null:
		return
	check(Deeds.opens(&"dig_setup").has(her) and Deeds.opens(&"dune_dig").has(her), "each of her deeds says it opens her")
	for order: Array in [[&"dig_setup", &"dune_dig"], [&"dune_dig", &"dig_setup"]]:
		profile.reset()
		check(not her.is_open_to(profile), "locked with neither")
		profile.deed(order[0])
		check(not her.is_open_to(profile) and not profile.is_new(profile.start(her.id)),
			"locked after %s alone, and not marked new" % order[0])
		profile.deed(order[1])
		check(her.is_open_to(profile) and profile.is_new(profile.start(her.id)), "open after both, and new")
