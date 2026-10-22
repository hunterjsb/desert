# Starcom: a quest spine

*Proposal for Hunter, 2026-10-22. Docs only; no new canon or build approval.*

Repairing Starcom should grow out of learning to live here: first hear a nearby ruin,
then learn what a working local network sounds like, then carry a sustainable camp to
an interstellar station that has nobody maintaining it. Reconnection changes who can
speak to whom. It does not make the desert safe or produce an immediate rescue.

**Status convention:** the seven beats below are proposed sequencing and interactions.
“Built” identifies existing foundations, not approval of the proposed quest. Every new
fixture, dependency, response and story treatment below is **proposed**. Existing rules
belong to the linked sources, not this brief. Baseline inspected: master `4d3de771`.

## What the proposal must preserve

- [The current ending ladder](../vision.md#the-ladder) supersedes the old five-ending
  table. StarCom and radio can lead to the long wait; launch has its own authorisations.
- Hunter's contract ship really is coming. Fixing the station must not retroactively
  make that promise a lie. Whether a call changes the pickup is an open design question.
- Present-day contact is with Tilg & Standard, the successor in the current vision,
  not colonial TILG. Legacy UG credentials are old machinery, not a living empire.
- [Halloran's decline and ban](../world/lore-research.md#hallorans-decline-and-the-ban-on-the-stoker-agreed-2026-10-22)
  concern a dangerous industrial mind people once understood. Its surveys describe real
  heat; missing pipe, labour and supply prevent exploitation. The Walker is its friend.
- [Reachable horizons](../prd/world-and-terrain.md#reachable-horizons-built-2026-10-20)
  already give Starcom and the observatory real ground. The observatory is at the
  anti-Tu equatorial point, not the south pole. Distant mountains remain optional bearings.

## Seven physical beats

### 1. Hear something close enough to reach — the starting salvage country

**Proposed experience:** the first useful signal takes the player to ordinary nearby
salvage. Shelter, water and power come before an intercontinental destination. A found
broadcast set opens a wider world after the player has learned the receiver's needle.
No opening quest marker points at Starcom, and no particular ruin must contain a key.

**Built:** the survey receiver acquires nearby ruin beacons and rewards a real approach
with Follow the Signal. It is not a broadcast set. Radio tiers, FM/SW converters and
ordinary ruin salvage exist ([radio PRD](../prd/radio-sound-and-atmosphere.md)).
**Needed:** a deliberately paced clue distribution for this quest.
**Smallest next build:** audit normal starting salvage routes for obtainable broadcast
gear; propose a bounded placement adjustment only if runs cannot reach that next step.
Do not turn the survey receiver into an FM receiver or guarantee a rare component at spawn.

### 2. Hear a network that still works — Port Morgan's approaches

**Proposed experience:** carry a broadcast radio with FM reception up to a sheltered
vantage. The Tower reports weather at the port; the deliveryship crosses overhead.
At the Ledger's useful hour, listen for its existing Starcom bearing and range. That
contrast is the clue: local machines still talk, but the way out is silent.

**Built:** Tower weather, local FM propagation, the shortwave relay, the deliveryship's
orbit and package system, and the Ledger's landmark bearings. The deliveryship is an
existing local craft, not the contract rescue ship. Its presence proves activity, not
interstellar contact (`game/radio/fm.gd`, `radio.gd`, `gods.gd`).
**Partly built:** the place and transmissions; no repair request or quest-specific clue.
**Smallest next build:** let an intact Ledger bearing be retained through the existing
Console map/navigation path, subject to its owner's current work. Keep manual navigation
possible. No new Tower exposition or compulsory deliveryship drop.

### 3. Make an expedition possible — Aitch, the Crossing, the furnace

**Proposed experience:** an optional provisioning detour. Passing an old blocked entrance
and later worn passages shows a practical prohibition becoming a pilgrimage. Feed the
furnace; enjoy its brief steadiness, take the finite service stock, hear the quota remain
unmet. Closed pipe ends and empty mounting beds make the absent supply chain visible.
No broken survey decoder is invented to explain the Stoker's torment.

**Built:** the 660 m route, finite coalcane, maintenance burn, service cache, radio state,
persistent claims and First Fire (`game/story/stoker.gd`;
[salvage PRD](../prd/salvage-and-ruins.md#halloran-first-fire-built-2026-10-20)).
**Partly built:** architectural layers; the ban's specific physical evidence is needed.
**Smallest next build:** one readable blocked approach with later bypass wear, retaining
safe collision and burial access. No new cult name; Muster remains the Quartermaster's.
The cache supplies camp equipment, not a newly mandatory Starcom key. The maintenance
burn neither restores the refinery nor produces launch fuel.

### 4. Meet the actual fault — Starcom's service gallery

**Proposed experience:** arrive with provisions and portable power. The mountain seen
from afar becomes the slope climbed. Under the gallery roof, connect power to a service
socket: a local test responds, but the outgoing circuit stays dark. A visibly absent,
replaceable coupling identifies a physical repair. Its exact component is undecided.
A first visit can be reconnaissance; the player can leave, equip and return.

**Built:** traversable mountain, summit gallery, shelter, salvage sockets, distant-to-near
geometry, ordinary devices and power. **Needed:** the repair fixture and saved fault state.
`game/story/summit_kit.gd` and `summit_site.gd` currently provide exteriors, not a quest.
**Smallest next build:** one powered, inspectable test fixture showing local success and
outgoing failure, with a real socket. Do not consume a unique item during diagnosis.
Persist state by landmark identity, independent of streamed instances and floating origin.

### 5. Repair, then choose whether to connect — Starcom's array

**Proposed experience:** bring a compatible salvaged component, install it physically,
then align the array using a live meter. Local readiness and network connection are
separate actions. A repair can stay powered down; opening the circuit can disconnect it
again. Parts come through salvage, not a compulsory lap of every god's home.

**Built:** salvage handling, power connections and the array model.
**Needed:** component compatibility, alignment feedback, connection state and network effects.
**Smallest next build:** a single replaceable component and stable powered test result;
then one deliberate connect/disconnect action. Save removal and installation without
item duplication. Record a proposed reconnection deed at the successful action, not arrival.
Coordinate any deed ID with the deeds owner; this brief reserves none.

### 6. Hear an answer that changes the plan — Starcom and the mobile camp

**Proposed experience:** connection produces a short live acknowledgement, not a history
lecture. An old credential is accepted as evidence of identity but needs a current reply
before contact is complete. A distinct repeatable exchange makes “someone heard me”
unambiguous. The player then returns to sustaining a camp, with a reason to keep listening.
The exact voice and treatment of obsolete UG authorisation need Hunter's approval.

**Built:** receiving, weather interference and saved camp systems.
**Needed:** player transmission, external response, contact persistence and the long-wait
ending. A shortwave converter alone is not an interstellar transmitter.
**Smallest next build:** one saved request/acknowledgement transaction at Starcom, including
power loss and retry. Do not announce a new pickup date until the contract rule is settled.
Receiving local Tower or satellite traffic must never count as this contact.

### 7. Decide what the connection is for — the far-side observatory

**Proposed experience:** an optional later journey, not an extra lock before the call.
Restore the telescope physically and see a changed sky through it. The Eye's responses
differ when it has other minds to speak with. An isolated Eye instead remains vulnerable
to the Stoker's carried dispatches. This makes the network's consequence something the
player encounters, rather than a morality selection screen.

**Built:** the far-side mountain, elevator-stub exterior, gallery and Eye radio carrier.
**Needed:** telescope restoration, inner chamber, dispatch interactions and linked-god
responses. The Eye's carrier is not proof those quests are implemented.
**Smallest next build:** a usable telescope with one observable restored view; defer
interior and dispatch sequence until approved. A reconnection/dispatch interaction must
read the same saved network state, not independent quest flags that can contradict it.

## Branches, not a compulsory pilgrimage

| Route | Established rule | Proposed connection to these beats / remaining work |
|---|---|---|
| StarCom / long wait | Call, then survive years; communications are instant, travel is not. | Beats 4–6 make contact playable; contract timing and ending resolution remain needed. |
| Launch / escape | Ledger and Quartermaster authorise; the fed Stoker is the only launch-grade fuel source. Carrying the Quartermaster, a cable or repaired Starcom can bridge them. | Reconnection becomes one bridge, not the only one. Full refinery fuel production, launch craft and authorisation outcomes remain needed; First Fire is only an introduction. |
| Shot down | Unauthorised launch meets the old air-defence net. Captive Quartermaster and hive-mind exceptions follow the current vision. | Show clearance acceptance or refusal through a physical preflight check before committing. Do not imply Starcom contact alone grants clearance. Launch/net resolution remains needed. |
| Nomad city | Rare, ambiguous contact with the last city; the exact ending trigger remains open. | Leave it independent. Walker FM contacts, Console bearing triangulation, city movement/chatter and distant lights already support discovery; rescue/tether finale is not built. No Starcom task should reveal its coordinates automatically. |
| Radio | Alternate call into the long wait is agreed; the older standalone “radio ending” is undesigned. | Better receiving gear can suggest another way to listen. Transmitting hardware, recipient and range are still decisions, not functions secretly present in converters. Do not create a fifth finished ending by renaming listening. |

The [captive launch rule](../vision.md#the-captive-launch-rule-agreed-session-4-part-5)
and [observatory modifier](../vision.md#modifier-the-observatory-beyond-the-eye) own those
rules. This brief does not replace the wider ladder: revival, ascendancy, the pathfinder
and other endings still need their own proposals.

For the [Stoker's destructive ending](../vision.md#blow-up-the-moon-agreed-session-4-part-5),
Starcom must be down: never connected or deliberately cut. The carried dispatches and vent
charges remain a separate, unbuilt commitment. A repaired network lets other gods challenge
the Eye. Exactly what happens to an already-corrupted Eye after reconnecting is unresolved;
do not silently implement a cure or let contradictory ending conditions both succeed.

## Integration boundaries and first build recommendation

**Proposed first build after approval:** beat 4's diagnostic fixture, then beat 5's bounded
repair. It turns an existing expedition destination into a physical purpose without pretending
the ending is ready. Keep contact rewards disabled until beat 6 has a truthful response.

- Reuse history positions, summit galleries and their terrain sampling. No second ground
  plane, scaled horizon-only destination, or global quest geometry kept alive offscreen.
- Keep the essential fixture reachable across burial states. Storm-exposed ordinary ruins
  supply equipment opportunities; rare exposure must not permanently gate a required part.
- Preserve near-start survival cues. The Ledger supplies an honest distance, not a promise
  the journey is safe. Preparations remain player judgement, not an invisible gear score.
- Focus eventual checks on a physical repair, power interruption, leave/return/save,
  disconnect/reconnect and removal without duplication; inspect real summit captures.
- Gonk owns Walker changes. Existing FM logs and contact bearings are optional parallel
  discovery, not a mandatory courier dependency. Any new survey/dispatch payload needs
  agreement with Gonk before code or a new interface is claimed.
- Current radio, Console-map and deeds work is separately claimed. This proposal changes
  none of those files; integration must use their landed behaviour rather than pin old UI.

## Hunter's decisions needed

1. What does a successful call change about the already-promised ten-year pickup: location,
   confirmation, help, or timing? How does that fit the long wait in non-surveyor starts?
2. Should the first repair use existing salvage, or a distinctive replaceable component?
   Which physical failure makes sense for this particular station?
3. Does local god networking return with interstellar service, or can players power them
   separately? What happens if the Eye was corrupted before a reconnection?
4. Is radio an independent transmission route, or another way into station/orbital contact?
   Keep the separate radio finale open until that distinction is chosen.
5. Approve the Halloran ban's blocked-entrance treatment and the optional observatory beat,
   or keep this first quest entirely between Port Morgan and Starcom?
