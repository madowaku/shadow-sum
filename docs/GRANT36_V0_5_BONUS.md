# BOARD SHAPES bonus: BS01 — THE EMPTY STAIR

This is one optional stage outside the 36-stage GRANT36 v0.5 campaign. It uses the existing board-shape rule and a separate progress file. The board's outline supplies the decisive information: the target has three exact typed explanations on a full 5×5 placement board, but only one explanation fits the visible staircase sockets. Human playtest revision 2 also requires every authored Post to contribute visible evidence; no inventory filler may reproduce the target when omitted.

## Play

Use `--campaign=grant36-v05-bonus` as a Godot user argument, or launch with `--dev-selector` and choose **BOARD SHAPES BONUS**. The selector also exposes **GRANT36 v0.5**. Bonus progress is stored in `user://shadow_sum_grant36_v0_5_bonus.json`.

The stage starts with a short reminder that missing sockets cannot hold Posts but do not stop light. Its three optional whispers point the player to the outline, the D5 overlap, and the explicit zeros. The stage uses fixed TOP and LEFT lamps, Normal ×2, and Tall ×1.

```text
Socket mask          Target shadow
11...                00000
111..                00000
.111.                00001
..111                00010
...11                00012
```

`1` means a socket exists; `.` means there is no socket. The shadow display still has all 25 cells.

## Designer validation (solution spoiler)

The revised solution is E4 Normal, D5 Normal, D3 Tall. The independent reference enumerates 858 legal typed worlds and finds exactly one match. A full board has 6,900 typed worlds and three matches; the two excluded explanations require C5, which is a missing socket in the staircase. Replacing Tall with Normal leaves zero matches. Exhaustive reduced-inventory search also finds zero matching worlds with fewer than all three authored Posts, so every inventory piece is causally necessary.

Run `python tools/validate_board_shapes_bonus.py` to recheck those claims, including the reduced-inventory necessity test. `tools/grant36_v05_smoke.tscn` also exercises the bonus selector route and clears BS01 through mouse input at compact and wide viewport sizes.
