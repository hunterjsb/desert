# Documentation map

Start with the [vision](vision.md). It describes the game; each system's design and
current implementation live in its [PRD](prd/). The [code map](code-map.md) connects
those systems to code and probes.

## Project direction

- [1.0 Alpha roadmap](alpha-roadmap.md): release goals and current priorities.
- [Skeleton plan](skeleton-plan.md): the original build sequence and its history.
- [Art direction](art-direction.md): visual rules and approved look.

## World

The living world references are grouped in [`world/`](world/): [Zan's lore](world/lore-research.md),
[physical profile](world/the-moon.md), and [world-generation system](world/world-system.md).

## System design

The current design sources are in [`prd/`](prd/), one file per system. Start with the
relevant PRD before changing that system. The Surveyor's cabin, launch, fall and pod
camp are in [Surveyor opening](prd/surveyor-opening.md).

## Supporting briefs

[`briefs/`](briefs/) holds dated research and design briefs. They preserve context and
proposals; when they conflict with the vision or a PRD, the vision and PRD govern.
Settled world decisions should be read from `world/`, not inferred from a brief alone.

Voice-session records and personal working notes are kept outside the repository. Their
settled design decisions are folded into the vision, world references, and PRDs.

### Continued Sanddune checks

- [Native contact cost](prd/native-contact-cost.md)
