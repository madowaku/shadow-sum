# SHADOW SUM — Tripo 3D Material Lab v0.1

## Purpose

Use generated 3D objects as a **physical-design reference lab**, not as a commitment to convert SHADOW SUM into a 3D game.

The runtime remains Godot 4.7 and the current 2D/Control architecture remains authoritative.

The lab asks one question:

> If SHADOW SUM's optical instrument physically existed on a desk at night, what would its parts look and feel like?

Outputs may later inform:
- procedural 2D drawing;
- pre-rendered sprites;
- store art;
- a small number of optional 3D runtime props;
- future Steam presentation.

## Engine decision

Production target:
1. Google Play first, Godot 4.7;
2. Windows/Steam later, same Godot project where practical.

Do not migrate the project to Unity for this lab.

Reconsider Unity only if the product direction changes into a substantially 3D scene whose core value depends on advanced 3D rendering, large middleware ecosystems, or a Unity-specific production dependency.

## Pipeline

Preferred research pipeline:

```text
Tripo
→ GLB
→ Blender cleanup / inspection
→ turntable renders
→ compare at real game scale
→ extract silhouette/material ideas
→ reproduce in Godot 2D where possible
```

GLB is preferred because it is compact, game-engine friendly, and can carry textures/material data.

Do not import generated assets into the production scene until they pass the visual gates below.

## Design rule

**80% precision instrument, 20% mystery.**

Avoid:
- steampunk clutter;
- cyberpunk neon;
- fantasy runes;
- ornate brass machinery;
- visible gears;
- giant screws;
- sci-fi holograms;
- high-frequency surface detail.

At 22–24 logical pixels, silhouette and highlight placement matter more than detail.

## Lab A — POST

Goal: discover the physical identity of the placed Post.

Generate three families.

### A1. Optical Calibration Pin

Keywords:
- blackened brass;
- compact optical calibration pin;
- precision laboratory part;
- low cylindrical body;
- beveled top;
- restrained satin finish;
- single warm metal rim;
- no text;
- no decorative engraving.

Desired read:
small, heavy, deliberate.

### A2. Aperture Weight

Keywords:
- matte black optical aperture weight;
- dense metal puck;
- shallow cylindrical body;
- slightly recessed top;
- cool steel specular;
- minimal brass edge.

Desired read:
quiet weight, almost stone-like.

### A3. Observation Marker

Keywords:
- vintage scientific instrument marker;
- 1930s–1960s optical laboratory;
- black enamel metal;
- simple precision-machined geometry;
- tiny brushed-metal top highlight;
- not steampunk.

Desired read:
a part from a forgotten measuring instrument.

### Post acceptance gate

At a render equivalent to 22–24 px wide:
- silhouette still reads;
- occupied vs empty Socket is obvious;
- material reads without texture noise;
- no detail depends on normal-map sparkle;
- warm accent occupies less than ~10% of visible surface.

If a model looks good only in close-up, reject it.

## Lab B — SOCKET PLATE

Goal: decide what the 5×5 Placement Board physically is.

Generate three directions.

### B1. Optical Bench Plate

- matte black anodized aluminum;
- 5×5 recessed circular receivers;
- precise spacing;
- extremely clean machining;
- restrained bevel;
- no labels;
- no exposed screws unless structurally necessary.

### B2. Darkroom Measurement Plate

- charcoal coated metal;
- 5×5 shallow wells;
- subtle wear only at edges;
- laboratory object, not military equipment;
- soft reflected light.

### B3. Stone-Metal Instrument

- black mineral/composite plate;
- exact machined sockets;
- faint metallic inner rings;
- heavier and quieter than electronics.

### Board acceptance gate

The grid must remain the hero.
The object may frame the 5×5 system but must not introduce decorative geometry between cells.

## Lab C — LIGHT EMITTER

Goal: make N / W / E feel like physical light sources rather than UI labels.

Generate a single modular emitter in three variants:

### C1. Collimated laboratory lamp
small precision housing, circular aperture, cool white light.

### C2. Optical rail emitter
rectangular matte-black housing with one glass aperture.

### C3. Vintage photometer source
mid-century scientific equipment, restrained metal, tiny lens.

No LEDs, neon strips, sci-fi beams, or visible cables as focal details.

The final game may still render emitters in 2D. This lab only discovers the object language.

## Optional Lab D — FROSTED SCREEN

Do not generate the entire TARGET/LIVE interface first.

Generate one physical material sample:
- frosted optical glass;
- dark frame;
- soft internal gray shadow;
- thin cool top reflection;
- slightly warm TARGET variant;
- slightly cool LIVE variant.

Use the result as a material reference, not a literal texture.

## Prompt template

Use this structure:

```text
[OBJECT TYPE], precision optical laboratory instrument,
matte black / blackened brass,
compact low-profile geometry,
restrained mid-century scientific equipment design,
subtle cool reflections and minimal warm brass accent,
clean silhouette readable at very small size,
no text, no logo, no engraving,
no steampunk, no cyberpunk, no fantasy,
no exposed gears, no neon, no decorative clutter,
product photography object, neutral dark studio background
```

Then substitute the Lab A/B/C object description.

## Evaluation sheet

Score each candidate only on:

1. silhouette at game scale;
2. material readability;
3. compatibility with MONOCHROME NIGHT;
4. ease of reproducing in Godot 2D;
5. uniqueness / recognizability.

Do not score photorealism.

A less realistic shape that reads at 24 px is preferable to a beautiful complex model.

## Production decision after Lab

For each winning object choose one of:

### Route 1 — 2D procedural extraction

Preferred default.

Translate:
- silhouette;
- rim position;
- top ellipse;
- one specular shape;
- contact shadow

into existing `_draw()` visuals.

Advantages:
- tiny runtime footprint;
- perfect responsiveness;
- no new 3D camera/light pipeline;
- keeps current smoke architecture simple.

### Route 2 — pre-rendered sprite

Use if the Tripo object has a unique shape difficult to reproduce procedurally.

Render a small turntable or fixed orthographic angle in Blender.
Use only if it remains crisp at target scale.

### Route 3 — runtime GLB

Use only after explicit proof that 3D materially improves the game.

If chosen:
- simplify mesh;
- bake materials;
- minimize texture count;
- inspect mobile performance;
- keep interaction logic outside the mesh;
- do not replace Button hit targets with 3D picking.

This is not the default for Google Play v1.

## Deliverables

Create:

```text
art-lab/tripo/post/
art-lab/tripo/socket/
art-lab/tripo/emitter/
art-lab/tripo/screen/
```

For each family keep:
- original prompt;
- model preview image;
- GLB if exported;
- short evaluation note;
- decision: reject / reference / candidate.

Do not commit large generated binaries to the main repository unless deliberately adopting them as production assets. Prefer a separate artifact location or Git LFS if the lab becomes large.

## Exit criteria

The lab is successful when we can answer:

- What is a Post physically?
- What material is the Board?
- What do N/W/E emitters physically resemble?
- Which 3–5 visual cues can be reproduced in the current Godot runtime?
- Is any actual 3D asset worth shipping?

The expected answer to the last question may still be "no".

That is a valid success: the 3D lab exists to discover the physical design language, not to force 3D into the product.
