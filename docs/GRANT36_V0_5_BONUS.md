# BOARD SHAPES bonus: BS01 — THE EMPTY STAIR

This is one optional stage outside the 36-stage GRANT36 v0.5 campaign. It uses the existing board-shape rule and a separate progress file. The board's outline supplies the decisive information: the target has three exact typed explanations on a full 5×5 placement board, but only one explanation fits the visible staircase sockets.

## Play

Use `--campaign=grant36-v05-bonus` as a Godot user argument, or launch with `--dev-selector` and choose **BOARD SHAPES BONUS**. The selector also exposes **GRANT36 v0.5**. Bonus progress is stored in `user://shadow_sum_grant36_v0_5_bonus.json`.

The stage starts with a short reminder that missing sockets cannot hold Posts but do not stop light. Its three optional whispers point the player to the outline, the D5 overlap, and the explicit zeros. The stage uses fixed TOP and LEFT lamps, Normal ×2, and Tall ×1.

```text
Socket mask          Target shadow
11...                00000
111..                00000
.111.                00001
..111                00011
...11                00020
```

`1` means a socket exists; `.` means there is no socket. The shadow display still has all 25 cells.

## Designer validation (solution spoiler)

The solution is D4 Normal, E5 Normal, D3 Tall. The independent reference enumerates 858 legal typed worlds and finds exactly one match. A full board has 6,900 typed worlds and three matches; the two excluded explanations require C5 or E3, which are missing sockets in the staircase. Replacing Tall with Normal leaves zero matches. The stage is curated from unused exact candidate `gr25-006` and keeps its target, lights, inventory, and mask.

Run `python tools/validate_board_shapes_bonus.py` to recheck those claims. `tools/grant36_v05_smoke.tscn` also exercises the bonus selector route and clears BS01 through mouse input at compact and wide viewport sizes.
