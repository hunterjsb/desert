# Physical departure cargo view

Selected for this continued Sanddune pass, 2026-10-22. Extends the existing
preflight loading/readiness contract and the menus PRD: the physical equipment
remains the inventory; the computer reports what the loading rules recognize.

## Behavior

The same physical launch screen offers a Cargo view alongside its landing
forecast. Keep the rotating globe/path visible. Show each original supply/item
with its actual loading state, including carried items, an occupied seat,
unsecured rope ends and gear still aboard the ship. Loaded counts must use the
same physical bounds/fitting rules that launch uses. Do not imply that packed
optional equipment is guaranteed to survive impact.

Use ordinary focused-screen mouse interaction and the project theme. Long cargo
lists scroll with PageBar; there is no permanent HUD or separate inventory modal.
Stepping back leaves the physical screen lit. The report is read-only: viewing,
scrolling or switching pages cannot pack, move, claim, repair or launch objects.
Live changes to packing must update the report without losing scroll position.
Keep launch readiness visible in this view: Aboard describes loading, not fuel,
supply or structural readiness. Show the actual blockers in the report and a
persistent ready/blocked summary even when reading farther down the cargo list.

## Acceptance

Actual physical load/unload changes the visible report; held gear is not packed.
The screen's focused mouse can switch and scroll cargo, while the actual globe
stays visible. Confirm/course state and cargo identities remain unchanged by
reading. Existing physical-screen, launch and one-theme checks remain valid;
inspect a real rendered cargo view before accepting its readability.

## As built, 2026-10-22

The existing glass now switches its right-hand forecast column to a live report
while retaining the actual globe and pulse. The report calls the same physical
loading selection as launch, distinguishing carried gear, seat obstruction, cargo
bounds and unsecured rope ends. Camp and board cells have distinct labels. Actual launch blockers lead the report;
a persistent ready/blocked summary distinguishes packing from launch readiness.
Refresh preserves the themed page position; the original objects, course and
confirmation remain unchanged. This does not change impact survival.

Arrival46 drives the actual station with projected mouse presses, releases and
wheel events, checks original held and legally mounted gear, reads/scrolls the
report, returns to landing and steps away. Headless check passes. An unseen
1280×720 Forward+ capture shows readable shared-theme text and PageBar beside
the rotating globe; the report clips at its page edge and scrolls.

The connected packing/recovery audit also found misleading field-guide text:
standing shield and beacon instructions must name an upward-facing chassis top,
matching their actual mounting rules. Batteries/panels retain general face and
preview guidance. This is an instruction correction, with no placement changes.
