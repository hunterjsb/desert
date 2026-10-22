# Pod flight look and intensity

Selected 2026-10-22 from Hunter's playtest: give the player more views out of the
actual pod, let them look around during the fall, and make launch and entry feel
more intense. This extends the Surveyor preflight/arrival PRD and follows the
vision's physical equipment and chunky industrial art direction.

## Agreed behavior before implementation

- Retain the same seated first-person pod and real selected cargo through flight.
  Side and roof glazing belong to the actual recoverable panels, with ordinary
  sealed collision envelopes and persistent skins. No duplicate physical parts.
- Mouse movement turns the head within a plausible seated range. Looking never
  steers the pod, changes the departure pulse or alters the resolved landing.
  Menus/console stop look input; normal walking input remains suspended in flight.
- A saved head orientation resumes without an abrupt forced forward view.
- Increase launch/entry intensity with phase-driven air/hull sound and smooth,
  deterministic, bounded turbulence. Do not accumulate random shake or replay an
  impact after restore. Retain the existing bounded impact and camera restoration.
- Glazing heat follows visible windows rather than a fixed center-screen patch.
  Tuning values belong in the existing arrival tuning dictionary. Existing sounds
  retain their credits; no external synthesis or new catalog equipment is required.

## Acceptance

Real input changes the rendered head view while leaving the trajectory unchanged;
menu coverage blocks it; saved orientation and deterministic turbulence restore.
Real recoverable side/roof windows survive ordinary dismantling and save restore.
Inspect actual GPU captures looking forward, sideways and upward during descent
and entry. Combined CI and human motion-comfort acceptance remain separate gates.

## As built and focused evidence

The actual retained tail, four side panels and two roof pieces now use the same
sealed double-glazed window skin. The full ordinary panel collision envelope,
mass, sockets and saved identity remain unchanged. Legacy flights author the same
windowed mesh interior without constructing physical bodies. Actual panel poses,
including loose panels, supply projected convex glazing masks; heat cannot cover
the opaque surrounding cabin just because the head turns.

ArrivalView consumes ordinary unhandled mouse motion while gameplay owns input,
within 110 degrees yaw and 75 degrees pitch. `arrival_state.head_look` persists the
chosen angles. Head rotation is independent of the timed departure trajectory;
the inverse shell transform keeps the capsule still around the turning camera.
Recovery preserves the viewed direction and transfers yaw into ordinary player
movement without changing position. Menus cover input; looking never edits cargo,
course, landing point or time.

A deterministic low-frequency saved-time sample adds at most 0.012 m translation
and 0.65 degrees rotation, scaled down in descent and eased to zero at each phase
boundary. Existing bounded impact recoil is unchanged. An ejection pop and smooth
looping wind/hull beds reuse credited sounds; volume/pitch follow phase progress.
The beds may resume in flight, while one-shot impact audio still does not replay.
All motion and mix tuning lives in the existing arrival tuning dictionary.

Focused checks pass: Arrival41 actual mouse input/menu coverage/head limits/yaw
handoff (6–7 s), 42 real side/roof dismantling and disk save (9 s), 43 deterministic
bounded turbulence (3–4 s), and 45 actual mouse-chosen head direction through disk
save/restore (9 s). Original 33/34/36/37/38 remain green (6/30/7/3/9 s). Check33 now
measures the eye's maximum distance from its physical seat instead of pinning a
motionless relative child transform; it retains full window containment and
body-count checks.

Actual 1280×720 Forward+ views looking forward, sideways, upward and obliquely
through entry were inspected. The existing seated renderer's heat audit changes
246,804 pixels inside the projected real window polygons and zero outside; hot
entry, impact and settled ground views were inspected. These are renderer and
focused evidence, not combined CI or Hunter's comfort acceptance. No release is
declared by this branch.

The successful preflight launch action explicitly sounds the ejection pop after
creating the flight view. A restored view never infers a new launch from its first
phase or an elapsed-time value. Arrival16 checks the sound immediately after the
ordinary seat launch; legacy orbit-to-ejection transitions use the same helper.
