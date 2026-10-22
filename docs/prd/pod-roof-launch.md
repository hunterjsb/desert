# Manual pod roofs and launch readiness

Agreed 2026-10-22. Extends [Surveyor preflight](surveyor-preflight.md).

The two original roof panels are physically interchangeable. Ordinary hand
placement on either pod frame's top face must count as a valid installed roof,
regardless of the panel's original front/rear identity. Keep every body's saved
arrival identity and mounted cargo. Do not require removing a correctly fitted
roof just to let automatic sealing reinstall it.

A retained loose roof may still close automatically onto the remaining free roof
face. A wrong attachment remains a refusal: name the actual host and face, then
say to take the panel off and fit it on a pod frame's top face. A roof attached to
another craft or across the hatch is not a valid roof. Readiness inspection is
read-only; it must not detach or rename physical pieces. Sealing may move only
available loose closures, never a manually fitted valid roof.

Acceptance: reproduce ordinary hand placement of swapped roof panels; launch with
both fitted and with one fitted/one loose; retain the original UIDs and installed
poses. Wrong-frame-face and other-craft cases must remain actionable refusals,
without changing body poses or the run manifest. Existing explicit support and
required-store checks remain in force.

## As built

The prior source fails after ordinary Hands placement puts the original front
roof on the rear top face. It also refuses both manually swapped roofs and cannot
close the remaining loose roof around that valid manual placement.

PreflightCargo now recognizes either top frame face for either original roof.
Sealing fills free top faces with only loose roofs and leaves installed panels
where the player fitted them. Counts of required loose roofs and free faces must
match, so an unrelated panel cannot leave two roofs sharing one available mount.
Wrong frame faces, edge joins and other hosts remain refusals; their messages name
the actual attachment and a correct destination instead of “other fitting”.

Arrival39 passes (7 s): ordinary Hands preview/placement swaps the original roof
panels, both installed and one-installed/one-loose states seal successfully, the
installed transforms and arrival UIDs stay unchanged, and wrong hatch/other-craft
and insufficient-face states refuse. Arrival22 passes (35 s) with swapped roofs
saved in preparation and restored on their exact selected faces, followed by the
existing seated, flight and recovered cargo disk checks. Support-readiness26
passes (8 s), retaining foreign-face, other-craft, held, missing-support and blocked
mount refusals; approach-blocker30 passes (5 s). All four pass together. No graphics
or material behavior changed in this slice; motion/visual acceptance remains with
the connected playtest.
