# PRD: Rope & tethering

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Your home goes with you, and rope is how. It holds the camp down against the wind, it's
how you move the camp, and it ties the camp to whatever pulls it. The game's base
mechanic is built on it, so it has to be **reliable before anything else**. It should
never be laggy, never bug out, and never go crazy, from a calm afternoon to the worst
storm.

## What the player experiences

- **Tying things together is simple and physical.** A rope in use takes your hand
  slot. Snap its end onto a ring, then walk to another and snap the other end on. Pick
  up any loose end, wherever it lies. Coil a rope to stow it in your inventory.
- **You can tie a line round your waist** to free your hands for towing. The price is
  that it drags you back and the wind grabs you harder.
- **A strong gust can drag you** if you're on the end of a line. You can let go of a
  line in your hand at any time.
- **Ropes behave like rope.** Slack rope sags onto the sand and stirs in the wind. Taut
  rope goes straight, creaks and hums. You can read the load by eye and ear, with no
  meters.
- **Wind loads everything, and rope carries that load to the anchors.** A gust swings
  the floating planter out on its line, the rope takes up the strain, and it holds.
- **More rope means more strength.** Two lines share a load one line couldn't hold.
  Lines on opposite sides pin something in place instead of letting it swing.
- **When it's too much, a rope snaps. It doesn't explode.** You hear it go, and whatever
  it held is gone downwind. In a stateless world, gone means gone.

## What Sand Game taught us

The rope was three systems that disagreed:

1. **The rope you saw** was drawn by nudging points toward each other at a speed tied
   to the frame rate. At a low frame rate the nudge overshoots, which is the "going
   crazy".
2. **The pull on the far end** edited the object's speed directly. It ignored the
   object's weight and the frame rate, and only one end ever felt the pull.
3. **A separate tether component** applied its own spring to the same object, with a
   *different* rope length (10 m against the drawn rope's 5 m). It also bled 2–15% of
   the object's speed every physics tick, which also smothered the wind, hence the
   "re-enable wind when tethered" fix.

## Rules

1. **One rope, one truth.** Each rope is a single constraint that does the holding,
   plus a drawn rope that shows it. They share one length and always agree. Nothing else
   pulls on a tethered object.
2. **Rope has weight** (decided 2026-10-15). A lightly loaded line droops and
   straightens as the pull builds, so you read the load by eye. Only a line under
   real load runs straight. The look-test's weightless line looked as straight at 2%
   load as at 70%.
3. **Stiffness is a feel, not a force.** A rope is defined by how fast it springs back
   and how much it bounces. It's solved the way physics engines solve soft joints,
   from both ends' masses, so it can't gain energy. A lantern and a loaded planter on
   the same rope type both behave sanely.
4. **Equal and opposite.** A rope pulls both ends equally, at the attachment points, so
   loads twist things realistically and anchors feel what they hold.
5. **Frame-rate proof.** The same setup behaves the same at any frame rate.
6. **Too much load breaks something; it never explodes.** Every rope has a breaking
   strength and every anchor has a holding strength. A brief spike doesn't snap a rope,
   only sustained load past its limit does.
7. **Ropes only touch the sand.** Drawn rope rests on `height_at` from World & terrain.
   That's a cheap lookup with no raycasts. Ropes pass through objects and each other,
   which means no tangling and no snagging, and none of the bugs those bring.
8. **Ropes belong to the camp, not the land.** They move with origin shifts and never
   belong to a chunk.

## Attachment points

Ropes attach only at **fixed points** on each object: rings and hooks you can see. That
keeps attaching reliable and easy to read. A basic object has one or two. Upgrades add
more, like an upgraded hover planter, and so do found mods, like an extra hook you fit
yourself.

**Attaching is the snap system** (decided 2026-10-14, from the rope look-test). A rope
end is held like a part and snaps onto a ring with the magnetic snap from
[Devices & mods](devices-and-mods.md): it needs intent, lands exactly, and pulls off
the same way. That works on any ring: a stake's, an object's hook, your hand or waist.
**Any loose end can be picked up,** whether it was dropped, is dragging behind
something, or is half of a snapped rope.

**Stakes are their own item.** Equip one, drive it into the sand where you stand, and
pull it back out to move on. Its ring is just another attachment point, so staking and
tying are separate acts. In the look-test, picking up a line only worked on staked
ones, so a dragging line could never be caught.

## You on the end of a line

The player is a rope end like any other, with a weight and a wind catch, so a strong
enough pull drags you. Held in your hand, a line can be dropped instantly. Tied round
your waist, it frees your hands but slows you down and raises your wind catch.

## Wind on tethered things

Every object that can be tethered has a **wind catch**: how much the wind grabs it,
alongside its weight. The force comes from `wind_at` (Wind & storms), so gusts and
storm outflow load the ropes for free. A floating planter catches a lot and weighs
little, while a crate catches little and weighs a lot. Rope's job is to carry that load
to the anchors without drama.

## Moving the camp

Rope is how the camp travels. There are two states, and the switch between them is a
core action:

- **Camped:** staked down, with lines out against the wind.
- **Travelling:** unstaked and towed. The pieces follow on their lines, swing with the
  gusts, and pull on whatever tows them.

Early on, a **post or a ruin** to tie more of the camp to when a storm hits is worth a
lot.

**What does the towing**, owned by Movement and Camp, with the rope serving all of them.
The hoverboard tows nothing.

- **You.** You hold the lead and feel the pull. You're the most reliable tower.
- **A mechanical beast.** It follows at a distance and carries or tows things. A rusty
  robot made of stiff, separate parts needs no skin rigging at all, which sidesteps the
  problem that sank Delve.
- **A sand yacht.** It rides the wind, fast. No sail goes straight into the wind, but it
  can zigzag upwind (tacking), so it makes travelling into the wind possible at speed.

## Skeleton version

- One rope type, attachable between the player, objects and stakes.
- A constraint that's slack below its length and an elastic spring past it, defined by
  springiness and bounce, with a hard maximum stretch. It pulls both ends at their
  attachment points (rules 1–4).
- Breaking strength on ropes, and holding strength on stakes.
- A drawn rope that sags, rests on the sand, stirs in the wind and goes straight when
  taut.
- A player on the end of a line feels the pull and gets dragged by a strong one. A
  line can be held (dropped instantly) or tied round the waist (hands free, slower,
  more wind catch).
- Wind catch on objects, driven by `wind_at`.
- Fixed attachment points, with rope ends snapping on and off through the snap system.
- Stakes as their own item: equip, drive in, pull out.
- One test floater: a hovering box that stands in for camp pieces.
- Camped and travelling: stake, unstake, tow.
- A tension creak (Sand Game's recording) that rises with load.
- The probes below, all passing.

**As built in the skeleton (2026-10-15):**
- **Weight** makes each line an elastic catenary: it pulls a little short of its
  length and straightens as the pull builds, and its drawn sag is the one its weight
  and pull imply. A line slack enough to lie on the sand pulls nothing.
- **A coil** gives you its first end when you pick it up, with the rest on your belt.
  Once that end is on a ring (or tied at your waist), the coil comes to your hand and
  pays out as you walk, up to 12 m. The line's length is set wherever its second end
  goes. Taking up an end of a line lying loose at both ends rolls it back up; dropping
  the first end before it's on anything puts the coil down whole.
- **Rings** are tie sockets: a hook adds one while it's fitted, and a stake has one on
  its eye. You're a ring in your hand, and at your waist with H. Untying takes a second
  (`untie_seconds`), and Q lets go of every line.
- **A stake** is a small device you can carry. E drives it into the sand where you
  look. E on a driven stake pulls it into your hand with its lines still on its ring,
  pulling on you now, so one gesture unstakes them and the next stakes them again.
- **A snapped line** parts into two lines, each with a loose end where it broke.

## Full version

- **More attachment points** from upgrades and found mods, like an extra hook.
- **Rope types** that trade strength, stretch, weight and length. The best one might be
  colonial cable, since history runs backwards in the ground.
- **Anchors** of different holding strengths: a stake in soft sand, a stake in hard
  flats, a post, a heavy object, a buried ruin.
- **Reeling in and out**, so a winch can pull the camp in or let it out.
- **Towing by movers:** the beast and the sand yacht.
- **Snaps with weight to them:** the whip, the crack, and whatever it held lost
  downwind.
- **Load you can read at a glance:** vibration, hum and the rope straightening.

## Probes

Reliability is the whole point here, so this list is long. All run without a window.

1. **Nothing goes crazy.** Run every combination of wind (calm up to the worst storm
   gust), weight (lightest object to heaviest) and number of lines (1 to 4) for several
   simulated minutes. No speed spikes, no energy appearing from nowhere, no invalid
   numbers, and under steady wind everything settles.
2. **Frame-rate proof.** The same setup at 30, 60 and 120 physics ticks comes to rest in
   the same place.
3. **Equal and opposite.** The force on the anchor matches the pull on the object.
4. **Lines share load.** Two identical parallel lines each carry about half. A load
   that snaps one line holds on two.
5. **Snaps cleanly.** Raise the wind until a line passes its breaking strength. It
   snaps, the object drifts downwind, and nothing spikes.
6. **What you see is what holds.** Drawn rope ends sit on the attachment points every
   frame, the drawn length matches the constraint, and the drawn rope hangs as its
   weight and pull say: straight only under real load.
7. **Rope rests on sand.** No drawn rope ever dips below `height_at`.
8. **Origin shifts are invisible.** A wind-loaded, staked camp crosses an origin shift
   with no jump in tension.
9. **The long tow.** Tow a floater 5 km over dunes through gusts. It arrives, and its
   tension never spikes past a set bound.
10. **Cheap enough.** Thirty ropes in storm wind update within the frame budget.
11. **Dragged, not launched.** A player on a line in the worst gust gets dragged at a
    bounded speed, with no launching and no jitter. That's held or waist-tied, on flat
    sand and on a slip face.

Every probe is first run against a deliberately broken rope, to prove it can fail.

## Out of scope

- Ropes colliding with objects or each other, tangling and knots.
- Climbing, swinging and grappling.
- Cutting ropes to arbitrary lengths with physics. Lengths are set when you attach.

## Open questions

- **How much rope do you carry,** and is every coil the same length? The skeleton's
  coils are all 12 m.
