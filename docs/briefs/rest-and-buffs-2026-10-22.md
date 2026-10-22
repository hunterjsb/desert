# Rest, food and drink: prepare to explore

*Concept for Hunter, 2026-10-22. Everything proposed below needs approval; no build
or release assignment. Baseline: `8b0e305b`. [Survival](../prd/survival.md#rest-food-and-drink-support-exploration-selected-2026-10-22)
owns Hunter's decision: stamina buffs for certain, health only maybe; farming is
not promised. 0.4 versus after Spaceport remains his call.*

**The moment:** a storm pins you under shelter. The radio plays, the condenser
fills a canister, you sit and eat something you found. When the weather breaks,
you leave better prepared: “you *get* to rest and eat cuz youre stuck in a storm”.
Shelter makes this possible; a meal does not make the storm harmless.

## What changes, and what already exists

Today [Bars](../../game/survival/bars.gd) shows four needs; [Vitals](../../game/survival/vitals.gd)
drains hunger/thirst, auto-consumes supplies and damages empty needs. [Player](../../game/player/player.gd)
owns stamina. [Suit](../../game/survival/suit.gd) is weight-limited, with **no inventory
slot count**. [Supply.use](../../game/survival/supply.gd) consumes held/carried supplies;
the [condenser](../../game/survival/condenser.gd) spends power filling containers/hoses,
with greater yield in colder felt temperatures.

**Propose:** retain health/stamina; replace hunger/thirst bars and low-need warnings
with three named **buff slots**, not equipment slots: Rested/Fed/Hydrated. Show active
labels; inspect durations and carried stock on request. Expiry restores today's
usable baseline, without hunger damage or an exhaustion debuff. Longer climbs and
quicker recovery reward preparation; exploration never requires all three. No wrist
or inventory redesign.

## Three rewards, one honest cost

*Starting estimates for playtesting, not accepted balance. All sizes, portions,
qualification times and durations belong in `game/tuning.tres` via Tuning.*

| Slot | Earn it | Proposed stamina benefit | Starting duration |
| --- | --- | --- | --- |
| Rested | 30 world-seconds sitting/lying still on support with no exposure harm; safe sleep can qualify too | +25% base recovery rate | ½ game day after qualifying rest |
| Fed | Use existing food; consume a measured 400 kcal portion | +20% base capacity; no instant stamina refill | 1 game day |
| Hydrated | Use existing water; consume 0.25 L | +15% base recovery rate | ½ game day |

One effect per slot; recovery bonuses add against base. Refuse repeat use while
active; partial portions give proportionally shorter duration. Rations and crops
share the first food effect: no farming prerequisite. Preserve real supplies,
condenser power/capacity and crop irrigation; no free water aura or cooking chain.

**Recommend deliberate use**, replacing auto-top-ups; alternatively Hunter could
choose opt-in suit auto-refresh on expiry, spending the same portions. Remove short
hunger/thirst depletion damage: merely hiding it preserves the rejected race.
**Recommend stamina only first.** Health remains “maybe”: a later safe-rest healing
bonus could fit, but never exposure resistance or healing through harm.

## The desert still kills; time still passes

Keep wind, storm scouring, temperature, shield failure, falls, shocks and sickness
dangerous. Rest requires safety; meals grant no immunity. Preserve harm-free healing.
[Sleep](../../game/survival/sleep.gd) retains exposure/camp-stability checks and advances
buffs, power, water and crops together, but drops the old empty-food/water wakeup.
Food/drink expire during sleep; qualifying safe rest can renew Rested. Save timers
and partial rest progress; loading posture grants nothing. Old saves must neither
turn low hidden needs into damage nor receive invented supplies.

Later hooks only: saved intake quantities/times and versioned low-intake duration
for starvation after 2+ weeks, acute thirst after days and macronutrient modifiers.
Expired buffs do not mean starvation. Exact thresholds, heat/sickness interactions,
nutrients and warnings remain undesigned; no hidden hardcore penalties now.

## Smallest build, evidence and Hunter's choices

Build one buff state feeding movement/HUD, existing use/rest paths, saves and sleep.
Reuse A Moment's Rest; any new preparation deed records actual use. Four focused
checks: exertion/recovery through expiry; supply conservation with repeated/partial
use; sleep/save timing without refills; lethal exposure but no old depletion death
while safely unfed/unwatered. Inspect the HUD and play shelter → meal → excursion,
also without food: preparation should help, not make baseline movement miserable.

**Hunter decides:** (1) 0.4 or later? (2) deliberate use or optional auto-refresh?
(3) stamina-only first, or explore health now? (4) do these three distinct rewards,
visible labels and rough durations fit the feeling? Numbers are tuning proposals,
not release gates; safe food/drink expiry is the recommended starting contract.
