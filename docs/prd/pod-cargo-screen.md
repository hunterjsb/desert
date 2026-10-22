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

## Acceptance

Actual physical load/unload changes the visible report; held gear is not packed.
The screen's focused mouse can switch and scroll cargo, while the actual globe
stays visible. Confirm/course state and cargo identities remain unchanged by
reading. Existing physical-screen, launch and one-theme checks remain valid;
inspect a real rendered cargo view before accepting its readability.
