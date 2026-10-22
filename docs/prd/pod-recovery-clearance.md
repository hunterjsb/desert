# Pod recovery clearance

Agreed 2026-10-22: after the Surveyor drop, the player must regain ordinary
movement inside the recoverable pod without being embedded in its chassis frame.
Keep the first-person landing and real reusable shell; do not bypass recovery by
teleporting the player outside. The actual player capsule needs a clear resting
pose and an ordinary crawl/stand route through the opened exit. Preserve cargo
identities, damage and saved recovery state. Verify actual movement after impact,
not only camera restoration or disabled player physics.

The roof placement/readiness and flight-look changes are coordinated separately.

## Selected repair

The existing seat is clear while prone, but the standard mounted shield/cell
occupy the route to the opened hatch and the centre frame rail prevents standing
there. During impact recovery, reserve the player's real prone capsule swept from
the seat through the open hatch. Dislodge surviving cargo fittings that obstruct
that route, preserving the same physical objects, charge and damage; place them
nearby using the existing crash-scatter rules. Keep actual frame/floor collision
and seated continuity. Do not shrink the player, disable collision or remove a
surviving structural frame to conceal the blockage.

## Measured result

The original seed-1234 launch reaches recovery with player physics enabled, but
ordinary backward crawl moves only 0.314 m before the mounted shield blocks it;
standing under the central frame rail is also refused. Arrival40 first reproduces
both failures. With the actual escape route reserved during scatter, the same
30-second launch/crawl check passes: the capsule is clear, crawls more than 1.5 m
through the original open hatch, then stands through the normal posture check.
This checks physical escape, not just input/camera flags. The new check runs on
native platforms as well as Linux.
