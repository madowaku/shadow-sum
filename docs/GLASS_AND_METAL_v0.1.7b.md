# SHADOW SUM v0.1.7b GLASS & METAL Visual Polish

## Goal

Move the MONOCHROME NIGHT skin from a refined dark UI toward a quiet physical optical toy without changing puzzle logic, authored stages, progress, hints, or input rules.

The visual read should be:

- Post = small black-metal instrument part;
- Socket = recessed receiver;
- TARGET / LIVE = shadow viewed through frosted optical glass;
- whole scene = a precision instrument in a dark room, not generic neon UI.

## Ownership boundary

`glass_metal_main.gd` extends `night_skin_main.gd` and is presentation-only.

Authoritative interaction remains on the existing `Button` controls. Each placement button becomes a transparent hit target with two mouse-transparent material children:

```text
Button
├─ SocketVisual
└─ PostVisual
```

Shadow cells retain their existing semantic background values and receive a mouse-transparent `ShadowGlassVisual` overlay.

No GLASS & METAL node may mutate `posts`, stage data, save data, solve state, or hint state.

## Post material

Post is no longer represented by a text `●`.

The custom-drawn part uses:

- dark side wall;
- darker lower face;
- cool metallic top ellipse;
- restrained rim and specular reflection;
- small contact shadow inside the socket;
- optional cool outline when used as the drag ghost;
- restrained warm settling ring when seated.

At compact size it should remain roughly 22–24 logical pixels wide inside the existing 48 px touch target.

## Socket material

Socket is no longer represented by text `·`.

The visual uses:

- recessed dark inner surface;
- thin outer and inner rims;
- a tiny geometric bore at center;
- cool cyan ring only while hovered or magnetically owned;
- restrained warm rim while occupied.

The underlying Button remains the complete pointer/touch target.

## Frosted shadow glass

The existing level contrast remains semantic authority:

- 0 = lightest glass;
- 1 = light shadow;
- 2 = medium shadow;
- 3 = deepest shadow;
- hidden = authored unknown / unobservable shadow.

GLASS & METAL adds only material cues:

- 1 px top reflection;
- lowlight at the bottom edge;
- fixed deterministic micro-grain;
- subtle warm TARGET tint;
- subtle cool LIVE tint;
- static fog bands for hidden clues.

Noise must not animate. This is a quiet bedtime-oriented game and the screen should never shimmer continuously.

`?` remains visible in v0.1.7b. The Stage 004 onboarding pass owns the future transition from explicit `?` to self-explanatory fogged glass.

## Drag contract

The floating drag ghost uses the same `PostVisual` material as seated Posts. Drag preview remains non-authoritative until release.

Magnetic ownership may light the destination Socket but must not change puzzle state.

## Depth

TARGET, LIVE, and Placement Board receive slightly deeper panel shadows than v0.1.7a. Background remains nearly flat charcoal. Do not add scenery, stars, particles, or decorative illustration behind the puzzle.

## Responsive contract

Hard layout gates:

- 405×900 compact;
- 676×900 mid-width regression target;
- 720×900 desktop.

No material polish may expand the footprint of gameplay controls.

## Automated QA

`tools/glass_metal_smoke.gd` verifies:

- scene uses `glass_metal_main.gd`;
- 25 SocketVisuals and 25 PostVisuals exist;
- 25 TARGET and 25 LIVE glass overlays exist;
- Stage 001 still solves with C3;
- occupied Post visual appears;
- Stage 004 hidden clue enters frosted state;
- drag ghost uses the physical Post material;
- drag preview does not mutate authoritative Posts.

The full Godot 4.7 smoke suite remains mandatory.

## Human visual QA

Automated tests cannot prove material quality. Inspect a real rendered screen for three questions:

1. Does a Post read as an object rather than a selected state?
2. Does a Socket read as a receiver rather than a button?
3. Do TARGET and LIVE read as glass carrying shadow rather than flat grayscale tiles?

If any answer is no, revise material contrast before adding more effects.

## Deferred to v0.1.7c

Do not fold these into this pass:

- animated shadow seep / ink settling;
- animated fog;
- new sound effects;
- particles;
- shader-heavy glass;
- 3D Post assets;
- Stage 004 onboarding;
- Daily Shadow or retention systems.
