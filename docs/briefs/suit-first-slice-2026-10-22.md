# Suit and inventory: first playable slice

*Proposal for Hunter, 2026-10-22. **Approved the same day** (“1. yes 2. optional 3. yes 4. yes”): the order, optional
fitting, an impact-proof starter lamp and the compatibility lamps. Docs only; no build authorization. After Spaceport,
not 0.4, per the [selected timing](../prd/menus-and-ui.md). The canonical owners record each answer. Sources: [answered concept](inventory-and-suit-modules-2026-10-22.md)
and canonical decisions at `f9348bb4`; current code audited at `dba4ad92`.*

## Order: all three, built in steps

1. **B begins with the headlamp.** One physical fitted object and a visual gear
   layout prove that carrying and equipping are different. Include enough A
   (clearer carry presentation) to distinguish those states; keep existing weight
   storage during this first step. This is the beginning of B's inventory overhaul.
2. **C: the set-down pack.** Prove quick deployment, physically visible contents
   while open, and reliable pickup with those same objects inside. Test repeated
   stops during travel before expanding capacity or requiring unpacking for every use.
3. **Broaden B and finish A.** Visible body attachments and reachable tools become
   the working inventory, with a clear carry view across harness and pack. Prove
   that finding, holding, fitting and stowing stay understandable under pressure.

## First slice: fit the light, then leave

Hunter's selected direction: “start with headlamp. tarkove-style visual layour of
 your gear in tab. bring it on the pod. that way we can introdice that mecahnic on the ship.”
The [opening PRD](../prd/surveyor-opening.md#headlamp-fitting-on-the-ship-selected-2026-10-22)
owns that decision. Proposed lesson: a headlamp sits in a reachable clip inside the
open pod during sheltered cabin preparation. Pick it up with the existing low grip;
open the **inventory action** to a visual gear layout, fit the actual object at the
head, then use the headlamp action to see its beam. Empty and occupied fittings are
visible. Removing it disables the beam. No Console, tutorial text page or new suit
power meter is needed; [neotech power](../prd/survival.md#neotech-suit-and-modular-headlamp-selected-2026-10-22)
is already selected to last years. Camp and carried-device batteries remain separate.

Recommend an optional lesson with no new launch blocker. A fitted lamp travels with
the wearer; an unfitted lamp in the pod follows physical cargo placement rules.
Recommend protecting this starter lamp from impact loss in either state. Neither
recommendation is settled. Departure and recovery hints must reflect its real state;
an absent lamp cannot produce the current recovery instruction to switch it on.

Proposed compatibility: legacy saves receive one fitted starter lamp exactly once,
including old cabin/flight saves; new non-Surveyor origins start with one fitted.
New Surveyors learn fitting aboard ship. Persist identity and fitted state through
cabin, departure, impact and reload: never both spawn a starter and migrate one.
Mass counts once whether loose, held, stowed or fitted. Existing saves currently
have no explicit headlamp-toggle field; migration can begin switched off, as today.

## Code boundaries and evidence

[Suit](../../game/survival/suit.gd) currently stores real objects by weight with no
slot count; retain that limit for this slice. Hands/holding retain their small-object
grip and empty-hand rules. [Headlamp](../../game/survival/headlamp.gd) currently toggles
an unconditional player light; gate it on fitted ownership. The inventory layout
must not require the powered camp Console. God-module mounting is a separate framework.
[Preflight cargo](../../game/arrival/preflight_cargo.gd) excludes carried objects from
loaded cargo: fitted equipment needs explicit wearer persistence, not a duplicate
cargo body or an exception that makes all carried supplies count as loaded.

Rest-buffs `d7eda8f2` is pending integration at audit time: its five ordinary HUD
entries are **health, stamina, Rested, Fed and Hydrated**, not inventory slots. Keep
those status entries and their inspection accessible; fitting grants no rest buff.

Smallest build: one catalog object/look, one fitting, inventory gear view, light gate,
opening placement, save migration, and one deed recorded on actual player fitting.
Focused probes should catch item/mass duplication during fitting; loss or duplication
across launch and disk reload; repeat migration and non-Surveyor regressions; and a
beam remaining active after removal. Migration must not award the fitting deed.
Inspect real GPU captures of grip, layout and beam, then play the cabin-to-dark-landing
sequence without coaching. Confirm inventory closes promptly, preserves status access,
and does not pause the world. Pack deployment and additional modules belong later.

## Hunter's remaining decisions

Hunter, 2026-10-22: “1. yes 2. optional 3. yes 4. yes”.

1. Is headlamp B → physical pack C → broader harness B and carry-view A the right order? **Yes.**
2. May the Surveyor skip fitting before departure, or must fitting be a readiness check? **Optional:** no launch blocker.
3. Should the starter lamp survive impact when fitted or packed, as proposed? **Yes.**
4. Approve the one-time fitted lamp for old saves and fitted starts for origins without a ship? **Yes.**
