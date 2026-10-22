# Antenna kite integration checks

Selected corrections follow [radio integration review](radio-integration-review.md).
Check two existing invariants independently: a flying aerial retains its world
geometry/height/charge across an origin shift, and a genuinely snapped strong
lead no longer connects the kite or grounds its charge. Keep the physical stake,
original plugs and remaining cable recoverable. No new kite physics, changed
arc balance, broader radio feature or weakened routing limits is selected here.

## Reproduction and correction

Both new real-rig checks fail before the correction (9 s each). Radio69 observes
a changed aerial/reel offset and ground-relative height after an eight-by-five
chunk recenter. Radio70 uses the real rope rupture action: both fitted original
plugs remain, but the broken lead still grants aerial gain and grounding.

The kite now follows the world's exact origin displacement in its cached airborne
point and existing top-level kite/line/flash visuals; it does not reset to the wind
target or interpolate across the origin jump. Rig discovery refuses a StrongCable
whose rope has broken. Earthing checks the live cable and rupture state directly,
including immediately after the snap, instead of trusting the last cached rig.
No cable physics, routing, power connection or arc tuning changes are made.

## Focused evidence

The two new checks pass after correction. The original flight/reeling check55,
three-point route56, unearthed arc/grounded protection57, storm damage58 and
strong-cable load check Power7 also pass (46/11/166/35/31 s respectively).
Radio70 preserves both original fitted plugs and returns reception to the same
bare shortwave gain after rupture. The origin check also covers the already-made
top-level visuals in the same instant as the host displacement.

These are bounded integration checks, not a claim of physically simulated kite
flight, full saved-flight continuity, native-platform coverage or release
acceptance. The feature remains the radio PRD's wind-placed aerial; its separate
traction-kite direction is unchanged.

The final same-instant geometry69 and rupture70 rerun passes (9 s each).
An invisible Forward+ attempt compiled and drew the real aerial, but its external
capture camera did not follow the world's subsequent automatic recenter. Those
images do not establish before/after visual acceptance; the exact mesh-transform
check supplies the bounded recentering evidence. A camera-fixture correction is
not a new gameplay blocker. Temporary images were inspected and removed.

Actual Forward+ captures of the production kite fixture were inspected for the
radio–stake–reel assembly, whole flight, intact canopy, charged canopy and torn
cloth. The rig uses the real catalog radio, aerial, grounded cable and mounted
parts. Canopy/frame/tail silhouettes, charge edges, wear holes and the physical
stake route render. Temporary images were removed after inspection. These views
check feature presentation; origin-shift correctness is established by the
focused geometry checks above, not by a before/after camera comparison.
