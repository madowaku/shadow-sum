# SHADOW SUM

# VARIANT_BOARD_IMPLEMENTATION_TASK.md

## Goal

SHADOW SUMに **Variant Board v0.1** を実装する。

既存の5×5 Socket Boardに対して、ステージデータから「POSTを配置できるセル」を指定できるようにする。

重要：

> Variant BoardはLIGHTのルールを変えない。
> Variant BoardはSHADOWのルールを変えない。
> Variant Boardが変えるのはPOSTを配置可能な場所だけ。

既存のShadow計算ロジックは変更しないこと。

---

# 1. 最初にやること

実装前に現在のコードベースを調査する。

以下を特定する。

* Stageデータ定義
* Stage JSON / Resource読込処理
* Socket Board生成処理
* Socket CellのScene / Node
* POST配置処理
* POSTドラッグ処理
* Shadow計算処理
* Save / Load処理
* Solver / Stage Validator
* 既存テスト

既存設計を確認したうえで、最小変更で実装すること。

新しいアーキテクチャへ全面的に書き換えない。

---

# 2. Core Requirement

各Stageに以下のような5×5 maskを指定可能にする。

```json
{
  "boardShape": {
    "type": "mask",
    "width": 5,
    "height": 5,
    "mask": [
      "00100",
      "00100",
      "11111",
      "00100",
      "00100"
    ]
  }
}
```

意味：

```text
1 = POST配置可能なSocket
0 = Socketなし
```

---

# 3. Backward Compatibility

`boardShape` が存在しない既存Stageは、

```text
11111
11111
11111
11111
11111
```

として扱う。

つまり既存Stageの挙動を変えない。

既存Stageデータをすべて書き換える必要はない。

---

# 4. Runtime Representation

ロードしたmaskを、実行時に高速に問い合わせられる形へ変換する。

必要なAPI：

```gdscript
func is_socket_enabled(row: int, column: int) -> bool
```

必要なら：

```gdscript
func can_place_post(row: int, column: int) -> bool
```

を追加してよい。

ただし既存のplacement validationが存在する場合は、そこへ統合する。

---

# 5. Placement Rules

POST配置判定にshapeMaskを追加する。

推奨判定順：

```text
1. board bounds
2. socket enabled
3. occupied check
4. available POST count
5. existing gimmick constraints
6. placement
```

無効セル：

```text
shapeMask == 0
```

には絶対にPOSTを配置できないこと。

対象：

* click
* tap
* drag & drop
* keyboard操作
* debug placement
* stage restore

存在するすべての配置経路を確認する。

---

# 6. Critical Rule: Disabled Cell Is NOT A Wall

最重要。

```text
shapeMask == 0
```

は、

```text
POSTを置けない場所
```

であって、

```text
壁
遮蔽物
光を止めるセル
影を止めるセル
```

ではない。

Shadow計算では通常空間として扱う。

例：

```text
PLACEMENT

11111
10001
10001
10001
11111
```

中央3×3にはPOSTを置けない。

しかし中央3×3のShadow Screenには影が表示され得る。

---

# 7. DO NOT MODIFY SHADOW MATH

既存Shadow計算ロジックへ、

```gdscript
if shape_mask[cell]:
```

のような条件を追加してはいけない。

Variant BoardはShadow simulationから独立させる。

Shadow計算への入力となるPOST配置だけが変わる。

---

# 8. Socket Board Visual

mask=`1`：

既存Socketを表示。

mask=`0`：

Socketそのものを表示しない。

つまり、

```text
enabled  = metal socket / ring / hole
disabled = continuous board plate
```

とする。

無効セルに、

* X
* LOCK
* 禁止マーク
* 赤表示
* blocked icon

を表示しない。

世界観として、

> 穴が塞がれている

のではなく、

> 最初からSocketが加工されていない実験プレート

と見せる。

---

# 9. Interaction

## Enabled Cell

既存挙動。

* hover
* drag target
* placement preview
* click

を維持。

## Disabled Cell

原則完全無反応。

* hover highlightなし
* placement previewなし
* click無効
* drop無効
* error soundなし

「拒否された」表現をしない。

---

# 10. Drag & Drop

POSTをドラッグして無効セル上へ移動した場合：

* valid placement previewを表示しない
* dropしても配置しない

既存POSTを移動している場合：

```text
invalid drop
→ original positionへ戻す
```

既存のキャンセル挙動があればそれを使用する。

---

# 11. Stage Load

Stage開始時：

```text
load stage
↓
load boardShape
↓
validate boardShape
↓
apply shapeMask
↓
build/update Socket Board
↓
restore / initialize POST state
↓
calculate shadows
```

の順番を保証する。

POST復元より前にmaskを適用すること。

---

# 12. Save / Load Safety

shapeMask自体はSaveデータに保存しない。

Stage定義から復元する。

既存Saveに、

現在のshapeMaskでは無効になったPOST座標が含まれる場合：

```text
ignore invalid POST position
```

として安全に処理する。

クラッシュさせない。

可能ならwarningログを出す。

---

# 13. Validation

Stageロード時にboardShapeを検証する。

最低条件：

```text
width == 5
height == 5
mask.length == 5
each row.length == 5
characters are only 0 or 1
enabled socket count >= 1
postCount <= enabled socket count
```

不正データの場合：

開発ビルド：

```text
push_error / assertion / clear diagnostic
```

リリース：

可能ならFull Boardへ安全にfallback。

---

# 14. Helper Functions

必要に応じて以下相当を実装する。

```gdscript
func get_default_shape_mask() -> Array[String]:
    return [
        "11111",
        "11111",
        "11111",
        "11111",
        "11111"
    ]
```

```gdscript
func is_socket_enabled(row: int, col: int) -> bool:
    ...
```

```gdscript
func get_enabled_socket_count() -> int:
    ...
```

```gdscript
func apply_shape_mask(mask: Array[String]) -> void:
    ...
```

既存コード構造に合わせて命名・配置は変更してよい。

---

# 15. Shape Definitions

以下をStageデータだけで再現可能にする。

## NORMAL

```text
11111
11111
11111
11111
11111
```

## CROSS

```text
00100
00100
11111
00100
00100
```

## NARROW

```text
00000
11111
11111
11111
00000
```

## STAIR

```text
11000
11100
01110
00111
00011
```

## CORNER

```text
11000
11000
11000
11111
11111
```

## HOLLOW

```text
11111
10001
10001
10001
11111
```

## BRIDGE

```text
11011
11111
00100
11111
11011
```

---

# 16. Grant Prototype Stages

可能であれば以下6ステージを実データとして追加する。

Stage IDは既存命名規則に合わせて変更してよい。

---

## VAR-01 CROSS

POST count:

```text
3
```

Board:

```text
00100
00100
11111
00100
00100
```

TARGET:

```text
???1?
?????
1????
?????
???1?
```

Expected solution:

```text
(1,3)
(3,2)
(5,3)
```

上記座標は1-index表記。

内部実装では0-indexへ変換すること。

---

## VAR-02 NARROW

POST count:

```text
4
```

Board:

```text
00000
11111
11111
11111
00000
```

TARGET:

```text
?????
???1?
?2??1
1?2?1
?????
```

Expected solution:

```text
(2,5)
(3,1)
(3,3)
(4,4)
```

---

## VAR-03 STAIR

POST count:

```text
4
```

Board:

```text
11000
11100
01110
00111
00011
```

TARGET:

```text
?????
?2???
1?2??
???2?
??1??
```

Expected solution:

```text
(2,1)
(2,3)
(3,4)
(4,3)
```

---

## VAR-04 CORNER

POST count:

```text
4
```

Board:

```text
11000
11000
11000
11111
11111
```

TARGET:

```text
?????
?1???
1????
?1111
?1?1?
```

Expected solution:

```text
(2,1)
(4,3)
(4,4)
(5,1)
```

---

## VAR-05 HOLLOW

POST count:

```text
4
```

Board:

```text
11111
10001
10001
10001
11111
```

TARGET:

```text
?2?2?
?????
?????
?????
1?1??
```

Expected solution:

```text
(1,1)
(1,3)
(1,5)
(5,2)
```

---

## VAR-06 BRIDGE

POST count:

```text
4
```

Board:

```text
11011
11111
00100
11111
11011
```

TARGET:

```text
?????
????1
???1?
???2?
1?2??
```

Expected solution:

```text
(2,4)
(4,3)
(4,5)
(5,2)
```

---

# 17. Solver Changes

Solverが現在25セルすべてからPOST候補を作っている場合、

```text
shapeMask == 1
```

のセルのみ候補として列挙する。

Concept:

```gdscript
var candidate_cells = []

for row in range(5):
    for col in range(5):
        if is_socket_enabled(row, col):
            candidate_cells.append(Vector2i(col, row))
```

その後、

```text
Combination(candidate_cells, postCount)
```

を探索する。

Shadow simulationは既存処理をそのまま利用する。

---

# 18. Solver Verification

各Variant Stageについて：

```text
solution count == 1
```

を確認する。

さらにexpected solutionと一致することを確認する。

座標順は無視し、集合として比較する。

---

# 19. Automated Tests

可能な範囲で自動テストを追加する。

最低限：

### TEST 01

boardShapeなし。

Expected：

```text
25 sockets enabled
```

---

### TEST 02

CROSS mask。

Expected：

```text
9 sockets enabled
```

---

### TEST 03

disabled cell placement。

Expected：

```text
placement rejected
```

---

### TEST 04

enabled cell placement。

Expected：

```text
placement succeeds
```

---

### TEST 05

disabled cellを通過するShadow。

Expected：

```text
shadow calculation unaffected
```

---

### TEST 06

invalid restored POST。

Expected：

```text
ignored safely
no crash
```

---

### TEST 07

malformed mask。

Expected：

```text
validation failure
safe fallback or explicit error
```

---

### TEST 08

6 Variant Stages。

Expected：

```text
each stage solution count == 1
```

---

# 20. Regression Tests

既存Stageについて：

* stage load
* placement
* remove POST
* drag
* reset
* undo if available
* clear detection
* save
* load
* sound
* clear animation

が以前と同じ動作をすることを確認。

特にboardShape未指定Stageを重点確認する。

---

# 21. Manual QA

最低限以下をブラウザ / 実ゲームで確認する。

## NORMAL

従来と見た目も操作も変わらない。

## CROSS

十字以外にPOSTを置けない。

## HOLLOW

中央3×3にPOSTを置けない。

中央3×3にはShadowが表示できる。

## BRIDGE

中央Socketを含む特殊形状が正しく表示される。

---

# 22. Visual QA

以下を確認する。

* 無効セルにSocketの残骸がない
* hoverが出ない
* click feedbackが出ない
* spacingが崩れない
* board frameは従来サイズを維持
* TARGET / LIVEは5×5を維持
* 変形盤面でもPOSTが正しい位置に揃う

---

# 23. Performance

5×5なので複雑な最適化は不要。

ただし毎frame文字列maskをparseしない。

Stageロード時に実行時形式へ変換し、

```text
is_socket_enabled()
```

を安価な問い合わせにする。

---

# 24. Architecture Constraint

避けること：

```text
Variant Board専用Shadow Engine
Variant Board専用Stage Scene
Shapeごとの専用コード分岐
CROSS専用処理
HOLLOW専用処理
BRIDGE専用処理
```

全Shapeは同一maskシステムで処理する。

Shape名はゲームロジックに影響させない。

---

# 25. Scope Exclusions

今回実装しない。

* REFLECTOR
* glowing POST
* splitter
* diffuser
* fixed POST
* walls
* blockers
* dynamic sockets
* rotating board
* board-size changes
* 6×6
* 3×5
* animated mask changes
* special cell types

スコープを広げない。

---

# 26. Suggested Implementation Order

```text
01 Inspect current architecture
02 Extend StageData
03 Add default full mask
04 Add mask validation
05 Add runtime mask representation
06 Apply mask to Socket visuals
07 Apply mask to placement validation
08 Fix drag/drop
09 Fix save/load restore
10 Update solver
11 Add CROSS test stage
12 Verify Shadow math unchanged
13 Add remaining 5 stages
14 Add automated tests
15 Run full regression
16 Manual QA
```

CROSSが完全に動くまでは残りShapeを追加しない。

---

# 27. Acceptance Criteria

## AC-01

既存Stageが変更なしで動く。

## AC-02

StageデータだけでSocket形状を変更できる。

## AC-03

mask=0へPOSTを配置できない。

## AC-04

mask=0はShadow計算に影響しない。

## AC-05

mask=0にもShadowを表示可能。

## AC-06

click / drag双方で配置制限が有効。

## AC-07

Save復元で無効POST座標があってもクラッシュしない。

## AC-08

NORMAL / CROSS / NARROW / STAIR / CORNER / HOLLOW / BRIDGEを同一システムで表現できる。

## AC-09

6 Variant Stagesがそれぞれ一意解。

## AC-10

既存Shadow計算ロジックを変更していない。

## AC-11

既存テストがすべてpass。

## AC-12

新規テストがすべてpass。

---

# 28. Completion Report

実装終了時に以下を報告すること。

```text
1. 変更ファイル一覧
2. StageData変更内容
3. shapeMaskの実装場所
4. placement制限の実装場所
5. Solver変更内容
6. 追加Stage一覧
7. 追加テスト一覧
8. テスト結果
9. 手動QA結果
10. 既知の問題
```

また、

```text
git diff --stat
```

相当の変更量も示す。

---

# 29. Do Not Commit Automatically

実装・テスト完了後、

```text
git status
```

を確認して結果を報告する。

明示的に指示されるまでは、

```text
commit
push
merge
```

しない。

---

# Definition of Done

以下が成立した状態を完成とする。

> SHADOW SUMの基本ルールを一切増やさず、
> Stageデータのmaskを変更するだけで、
> 盤面形状によって異なる推理を生み出せる。

そしてCROSS / NARROW / STAIR / CORNER / HOLLOW / BRIDGEの6問が、実際のゲーム上で正常にプレイ・クリアできること。
