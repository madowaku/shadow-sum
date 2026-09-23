# GRANT36 v0.5 BOARD SHAPES report

This build replaces GR24/25/28/29/32/34/35/36. GR01–20 and the eight human KEEP stages are copied unchanged from v0.4.
Grant submission set: GR01–GR36 only.
All replacement stages use fixed lights, exact typed inventory, and legal socket masks. None adds free lamp selection or a movable shutter. Adjacent replacements use different first-evidence categories wherever the candidate pool permits.

## Candidate pool

Generated 128 exact-unique candidates in 17.31s.

| Slot | Candidates | N/T/P | Fixed light profiles tried |
|---|---:|---|---|
| GR24 | 16 | 3/0/0 | TOP+LEFT (16) |
| GR25 | 16 | 2/1/0 | TOP+LEFT (16) |
| GR28 | 16 | 2/0/1 | TOP+LEFT+RIGHT+BOTTOM (16) |
| GR29 | 16 | 3/0/0 | TOP+LEFT (16) |
| GR32 | 16 | 1/1/1 | TOP+LEFT+RIGHT+BOTTOM (16) |
| GR34 | 16 | 2/1/1 | TOP+LEFT+RIGHT+BOTTOM (16) |
| GR35 | 16 | 2/1/1 | TOP+LEFT+RIGHT+BOTTOM (16) |
| GR36 | 16 | 2/1/1 | TOP+LEFT+RIGHT+BOTTOM (16) |

## Legacy fixture regressions

All six fixtures use the original fixed TOP/LEFT/RIGHT simple model. The independent validator enumerates the legal mask worlds and checks exact uniqueness.

| Fixture | Legal sockets | Search space | Matches |
|---|---:|---:|---:|
| CROSS | 9 | 84 | 1 |
| NARROW | 15 | 1365 | 1 |
| STAIR | 13 | 715 | 1 |
| CORNER | 16 | 1820 | 1 |
| HOLLOW | 16 | 1820 | 1 |
| BRIDGE | 19 | 3876 | 1 |

## Selected replacements

| Stage | Mask | Solution | Lamps | Search space | Survivors | No-mask survivors | Tall substitute | Plate substitute | Fog removes shortcut | Reasoning signature |
|---|---|---|---|---:|---:|---:|---:|---|---|---|
| GR24 | 11011 / 11111 / 00100 / 11111 / 11011 | B1:normal, E2:normal, C4:normal | TOP+LEFT | 969 | 1 | 2 | 0 | 0 | false | SHADOW |
| GR25 | 00100 / 00100 / 11111 / 00100 / 00100 | C3:normal, C5:normal, C4:tall | TOP+LEFT | 252 | 1 | 2 | 0 | 0 | false | ZERO/TALL |
| GR28 | 10101 / 11111 / 00100 / 11111 / 10101 | D4:normal, C5:normal, A2:plate_v | TOP+LEFT+RIGHT+BOTTOM | 4080 | 1 | 2 | 0 | 0 | false | OVERLAP/PLATE |
| GR29 | 11111 / 11111 / 00100 / 11111 / 11111 | D1:normal, E2:normal, C4:normal | TOP+LEFT | 1330 | 1 | 2 | 0 | 0 | true | SHADOW |
| GR32 | 11000 / 11000 / 11000 / 11111 / 11111 | B1:normal, A3:tall, B3:plate_v | TOP+LEFT+RIGHT+BOTTOM | 6720 | 1 | 2 | 0 | 0 | false | OVERLAP/TALL/PLATE |
| GR34 | 11000 / 11000 / 11000 / 11111 / 11111 | B1:normal, A3:normal, D4:tall, B3:plate_v | TOP+LEFT+RIGHT+BOTTOM | 43680 | 1 | 2 | 0 | 0 | false | SHADOW/TALL/PLATE |
| GR35 | 00100 / 01110 / 11111 / 01110 / 00100 | B2:normal, C5:normal, D2:tall, E3:plate_v | TOP+LEFT+RIGHT+BOTTOM | 17160 | 1 | 2 | 0 | 0 | false | ZERO/TALL/PLATE |
| GR36 | 11011 / 11111 / 00100 / 11111 / 11011 | A2:normal, B4:normal, C3:tall, C2:plate_h | TOP+LEFT+RIGHT+BOTTOM | 93024 | 1 | 2 | 0 | 0 | false | OVERLAP/TALL/PLATE |

## Selected mask visuals and witness traces

### GR24 — SHAPE OF THE SILENCE

```text
■■·■■
■■■■■
··■··
■■■■■
■■·■■
```

Solution: B1:normal, E2:normal, C4:normal. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 969 legal typed worlds; witness: C1=1 (153) → E3=1 (17) → D4=1 (1).
Reasoning signature: SHADOW. Replacement rationale: Replaces the Plate-heavy silent-cross puzzle with visible placement geometry and fixed two-axis evidence.

### GR25 — THE LONG WAY THROUGH

```text
··■··
··■··
■■■■■
··■··
··■··
```

Solution: C3:normal, C5:normal, C4:tall. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 252 legal typed worlds; witness: C3=0 (75) → E3=0 (30) → E5=0 (10) → D3=1 (4) → D5=1 (1).
Reasoning signature: ZERO/TALL. Replacement rationale: Keeps the reach lesson while making Tall necessary on a narrowed board.

### GR28 — PLATE IN THE GAP

```text
■·■·■
■■■■■
··■··
■■■■■
■·■·■
```

Solution: D4:normal, C5:normal, A2:plate_v. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 4080 legal typed worlds; witness: D5=2 (171) → B2=1 (18) → C4=2 (2) → D2=0 (1).
Reasoning signature: OVERLAP/PLATE. Replacement rationale: Replaces an opaque Plate question with a shape-constrained Plate orientation deduction.

### GR29 — VEILED SOCKETS

```text
■■■■■
■■■■■
··■··
■■■■■
■■■■■
```

Solution: D1:normal, E2:normal, C4:normal. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 1330 legal typed worlds; witness: E3=1 (190) → D4=1 (19) → D2=1 (2) → C3=0 (1).
Reasoning signature: SHADOW. Replacement rationale: Retains partial observation while letting board shape and remaining evidence carry the solve.

### GR32 — THE LAST OPEN AXIS

```text
■■···
■■···
■■···
■■■■■
■■■■■
```

Solution: B1:normal, A3:tall, B3:plate_v. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 6720 legal typed worlds; witness: A1=2 (190) → C3=2 (8) → C1=1 (4) → A3=1 (2) → B4=0 (1).
Reasoning signature: OVERLAP/TALL/PLATE. Replacement rationale: Replaces setting search with an on-board Tall reach and Plate-axis interaction.

### GR34 — FOUR CAUSES AGREE

```text
■■···
■■···
■■···
■■■■■
■■■■■
```

Solution: B1:normal, A3:normal, D4:tall, B3:plate_v. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 43680 legal typed worlds; witness: D2=1 (5460) → C1=1 (910) → C3=1 (196) → A4=1 (36) → B4=1 (12) → B5=0 (4) → B1=0 (2) → A3=1 (1).
Reasoning signature: SHADOW/TALL/PLATE. Replacement rationale: Replaces v0.4 GR34 with an exact typed inventory where substituting Plate cannot clear.

### GR35 — DENSE BOARD SYNTHESIS

```text
··■··
·■■■·
■■■■■
·■■■·
··■··
```

Solution: B2:normal, C5:normal, D2:tall, E3:plate_v. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 17160 legal typed worlds; witness: C3=0 (2240) → A4=0 (840) → E4=0 (216) → B2=1 (84) → C2=2 (36) → D3=2 (14) → A2=1 (3) → B3=1 (2) → D5=1 (1).
Reasoning signature: ZERO/TALL/PLATE. Replacement rationale: Keeps four-object density while making legal socket geometry part of the unique explanation.

### GR36 — THE SHAPED FINALE

```text
■■·■■
■■■■■
··■··
■■■■■
■■·■■
```

Solution: A2:normal, B4:normal, C3:tall, C2:plate_h. Exact survivors: 1; unrestricted-board counterfactual: 2.
Search space: 93024 legal typed worlds; witness: A3=2 (5952) → B3=2 (316) → C3=1 (24) → A4=1 (8) → A1=1 (4) → C1=2 (2) → D2=0 (1).
Reasoning signature: OVERLAP/TALL/PLATE. Replacement rationale: Finishes with fixed lamps and Normal×2/Tall/Plate; both special types pass substitution checks.

## Mechanic counterfactuals and P0

Every selected stage records typed_inventory_exact and shape_required. Tall-focused stages have zero matching Tall-as-Normal worlds; Plate-focused stages have zero Plate-as-Normal worlds. GR36 checks both reductions.
The old GR34 v0.4 target was independently searched under its authored lamp and no-Plate inventory profiles. No optical no-Plate solution exists in that mathematical model, so the playtest observation is retained as a runtime inventory regression rather than misreported as an optical alternative.

## Verification

Generation: 17.31s. Independent validator: 9.99s.
The independent validator re-enumerates all 36 campaign stages and all pool candidates, checks six exact legacy fixtures, malformed masks, exact typing, shape/Tall/Plate counterfactuals, and FOG-as-unknown. Godot smoke drives all replacements with mouse input and checks illegal sockets, save/load, undo, Plate return, layout bounds, and FOG.

Optional follow-up idea: a later variant could make missing sockets cast shadows normally but show subtle light passing across them. This build already locks in that physical rule without adding a new control.
