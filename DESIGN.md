# SHADOW SUM Design Context

## Product identity

SHADOW SUM is a quiet logic puzzle about light, shadow, and deduction. The product should feel like a precision optical instrument resting in a dark room at night.

The desired emotional register is calm, tactile, nocturnal, intelligent, and slightly mysterious. The game must never drift into generic neon-dark UI, fantasy ornament, casino glow, or dashboard-like presentation.

## Core design sentence

**A silent optical toy that makes shadow feel physical.**

The puzzle itself is the hero. UI chrome stays quiet enough that the TARGET, LIVE SHADOW, and Placement Board remain the dominant visual structure.

## MONOCHROME NIGHT direction

Theme name: **Obsidian Lantern**

Material language:
- charcoal-black instrument body;
- pale frosted glass for observed shadow cells;
- recessed dark sockets;
- black-metal Posts with restrained warm brass reflections;
- cool moonlit cyan only for light/hint feedback;
- muted red only for contradiction/error states.

Color is semantic, never decorative. Most hierarchy must come from value, spacing, material contrast, and typography.

## Signature element

The one expressive flourish is **shadow settling into glass**. When a Post changes the projection, the shadow should seep and settle rather than snap like a spreadsheet repaint.

Everything else stays restrained.

## Typography roles

Prototype/runtime system-font stack:
- Display / title: `Cormorant Garamond`, fallback `Georgia`, `serif`;
- Instrument / counters / stage metadata: `IBM Plex Mono`, fallback `Consolas`, `monospace`;
- Body / Japanese helper text: `Zen Kaku Gothic New`, fallback `Yu Gothic UI`, `Meiryo`, `sans-serif`.

System-font use is a prototype convenience. A release build may later bundle appropriately licensed fonts after platform testing. Do not change typography families casually; preserve the three-role contrast.

## Layout contract

Primary logical reference: **405×900**. The 360×800 Android target maps naturally through the current stretch configuration.

The whole puzzle must remain visible without scrolling:
1. title and stage metadata;
2. TARGET and LIVE SHADOW side by side;
3. emitters and Placement Board;
4. one short status line;
5. BACK / RESET / HINT / NEXT;
6. tiny legend.

Never allow decorative polish to push controls outside the compact canvas. Existing layout smoke tests are a hard gate.

## Unknown clue language

A hidden clue is not zero. It represents **unobservable shadow**.

Current static skin keeps `?` for legibility, but the intended final treatment is fogged glass with a short first-use onboarding at Stage 004. Do not style hidden cells like ordinary empty cells.

## Post language

An occupied Post should read as a small physical object, not a selected gold tile. Keep the socket dark; use metallic value contrast and a restrained brass rim/reflection to imply presence and weight.

## Interaction hierarchy

- normal controls: neutral charcoal;
- HINT: cool cyan accent;
- NEXT when meaningful: restrained brass/gold;
- contradiction: muted red;
- solve: brief warm gold reveal, then quiet again.

Avoid persistent glow. Glow is an event, not a surface treatment.

## Motion

Motion should be short, small, and meaningful. Strong motion is reserved for projection changes, solve reveal, and onboarding. Reduced-motion behavior must remain possible.

## Audio direction

Use sparse, close-mic tactile sounds: small mechanical clicks, soft air/ink movement, gentle glass/metal resonance. Silence is part of the sound design. Avoid constant BGM pressure, bright arcade confirmation sounds, or repeated reward jingles.

## Product ritual

Long-term product goal: a puzzle people willingly open during quiet time, especially before sleep. A single solved puzzle should feel complete enough to stop, while the next puzzle remains inviting rather than demanding.

Potential future mode: one calm DAILY SHADOW, without streak-pressure or noisy retention mechanics.

## Anti-patterns

Do not introduce:
- saturated neon gradients;
- large glowing cards;
- gold-filled buttons everywhere;
- excessive particles;
- busy background illustration behind the puzzle;
- permanent hint overlays;
- large modal tutorials for ordinary mechanics;
- dense copy;
- generic mobile-game reward chrome;
- layout changes that reduce the playable glass/board area for decoration.

## Runtime token owner

`src/night_tokens.gd` is the current runtime token source for MONOCHROME NIGHT. Durable token changes should update this document and runtime tokens together.
