# Radio integration continuity checks

Selected 2026-10-22, under the radio integration review.

## Correction contract

- Save a survey receiver's beacon carrier alongside its state. Untagged legacy
  receiver frequencies within the former 1930 kHz carrier's narrow tuning band
  migrate by the carrier difference, preserving detuning. Untagged frequencies
  already in the current band and tagged current state remain unchanged.
  Restoration does not acquire targets, change the switch or refill a battery.
  Full-radio bookmark frequencies have no reliable station identity; do not guess
  their intended station.
- Both AM and FM reception clear queued over-air speech when station identity
  changes. A receiver staying on the same station keeps its normal queue and
  cadence. Local Console speech retains its existing ownership rules.
- Frequency counter and wire logger actions require the powered-module contract
  already used by the preamp. A crystal set still receives passively, but cannot
  run either powered accessory.

## Focused evidence

Probes 71–73 cover disk restoration, station transitions and passive module power.
Original Snapshot fails all three legacy detuning offsets on the first disk
restore and the following round trip; current-frequency controls remain correct.
Original reception fails both station transitions in 72, and both powered
accessory assertions in 73.

Corrected checks pass on Godot 4.7.2: receiver disk restoration (12 s), station
identity (7 s), passive module power (10 s), receiver controls (10 s), station
voice timing (9 s), wire logger (27 s), frequency counter (10 s), receiver tiers
(10 s), band allocation (12 s), carried equipment save/resume (15 s), and local
Console battery announcements (27 s). A final receiver disk rerun passes in 13 s
after restoring the corrected Snapshot from the baseline comparison.
The receiver check includes untagged current-band state and tagged unusual state
as controls, then repeats save/resume to catch a migration applied twice. The
station check also retains the unchanged station's exact queue and cadence.
These are focused headless checks; combined CI remains the landing gate.
