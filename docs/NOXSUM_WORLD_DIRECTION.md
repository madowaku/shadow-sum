# NOXSUM World and Presentation Direction

## Canon

NOXSUM is a quiet scientific mystery set in the old **NOCTURNAL OPTICAL ARCHIVE**. Its optical plates accumulate shadow intensity across several moments: overlapping shadows appear darker. NOX is one ordinary, silent cat who disappeared one night. The player restores where NOX was and which pose appears in each moment.

A plate records a sum, not a sequence. Multiple NOX figures are the same cat at different moments; the record does not say which came first. Keep the reason for the disappearance and the ending open. The world is melancholic and curious, never horror or tragedy.

Player-facing states are **SIT**, **STAND**, **WALK**, and **SLEEP**. Use **RECORDED SHADOW**, **RECONSTRUCTION**, **NOX TRACE**, **OBSERVE**, **WHERE WAS NOX?**, **TRACE MATCHED**, and **RECONSTRUCTION COMPLETE** for player-facing puzzle language. Existing solver keys may remain internal.

Story text stays sparse: an opening, a new mechanic, a chapter turn, or a special plate. Keep each message to one or two short lines. Let the plate and room carry the rest.

## Visual direction

The HOME image is the reference for composition and mood: an old observatory archive, a broad night window, distant quiet lights, a warm desk lamp, and NOX seated with its back to the player, looking outside. NOX looks where the player looks. Keep its pose natural and its reactions restrained.

Use dark stone and wood, black metal, frosted glass, brass details, cool blue window light, and a small amount of warm lamplight. Preserve clear, calm space for the title and controls. Keep text crisp and selectable in Godot; artwork should not contain baked-in title, labels, or buttons. The logo's X can use two translucent crossing bands whose intersection is darker, expressing additive shadows.

## Web layout

The Grant submission targets a PC browser and Godot Web export. Design around a **720 x 900** logical viewport and reflow cleanly down to **405 x 900**. At the narrow width, keep the same portrait composition, move or stack navigation into compact rows, protect title and button text from the NOX silhouette, and retain usable control sizes and margins. Crop or scale the room art around its window and seated-cat focal points; do not stretch it.

The stage view should preserve the recorded plate and reconstruction as the primary reading area. Keep controls and labels legible at both widths, with scrolling only where the content genuinely needs it. The HOME-to-stage transition dims the room and lets NOX merge into the shadow before the first plate appears.