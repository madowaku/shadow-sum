# NOXSUM — Grant36 Master Specification v1.0

> **用途:** ChatGPT Project / 開発引き継ぎ用の「現在の正本」  
> **基準日:** 2026-09-25  
> **旧タイトル:** SHADOW SUM  
> **現タイトル:** **NOXSUM**  
> **提出範囲:** **GR01–GR36 の36問のみ**
>
> 今後のチャットでは、古い Grant18 / Grant20 / v0.4 draft / G01–G10 / H01–H06 / BS01 bonus と内容が衝突した場合、**この文書と `data/noxsum_grant36_v1.json` を優先する**。
>
> 特に **GR28 は最終版 `PLATE IN THE GAP`**。旧 `THREE KINDS OF ABSENCE` を復活させない。

---

## 1. Source of Truth

### ローカル開発ルート

```text
C:\Dev\Projects\shadow-sum
```

### 製品用36問データ

```text
data/noxsum_grant36_v1.json
```

このデッキが NOXSUM Grant版の正本。

### 最終 Board Shapes ソース

```text
feature/grant36-v0.5-board-shapes
commit 42a4b5b
```

この最終 v0.5 から以下8問を差し替えている。

```text
GR24
GR25
GR28
GR29
GR32
GR34
GR35
GR36
```

残り28問は既存Grant36系列を維持し、開発用 `review_only` メタデータのみ製品デッキから除外する。

### セーブ

```text
user://noxsum_grant36_v1.json
```

旧SHADOW SUM / 実験キャンペーンのセーブと混ぜない。

### 設定

```text
user://noxsum_settings.cfg
```

言語、サウンド、Reduced Motion等の製品設定を保持する。

---

# 2. ゲームの核

NOXSUM は、夜の光学資料室 **Nocturnal Optical Archive** を舞台にした静かな論理ミステリー。

プレイヤーが復元するのは、

- NOXが**どこにいたか**
- NOXが**どの姿勢だったか**
- 必要な場合は**どの光が点いていたか**
- 必要な場合は**どこで光が遮られていたか**

である。

影の記録は複数の瞬間の「原因」を合成したものとして扱う。

**影の記録から出来事の時系列や、NOXの最終的な運命は確定しない。**

プレイヤー体験の中心は、

```text
記録された影
↓
考えられる原因を逆算
↓
NOXの位置・姿勢・照明条件を再構築
↓
すべての影が一致
```

である。

---

# 3. 盤面

## 3.1 Placement Board

```text
5 × 5
A1–E5
```

列:

```text
A B C D E
```

行:

```text
1
2
3
4
5
```

Placement Board と Shadow Plate は概念的に別空間。

NOXを置いたセルそのものが、そのまま同じセルの影を意味するわけではない。

---

# 4. NOX姿勢と内部光学タイプ

NOXSUMの見た目では「Post」ではなくNOXの姿勢として表現する。

| NOXSUM表示 | 内部タイプ | 性質 |
|---|---|---|
| SIT | `normal` | 通常の1マス到達 |
| STAND | `tall` | 各有効方向へ2マス到達 |
| directional WALK | `plate_v` / `plate_h` | 向きによって影を作る軸が異なる |
| SLEEP on rail | shutter | TOP光の特定列だけを遮る |

### WALK / Plate

内部光学規則:

- `plate_v`: LEFT / RIGHT 方向の光に反応し、TOP / BOTTOM軸を通す
- `plate_h`: TOP / BOTTOM 方向の光に反応し、LEFT / RIGHT軸を通す

UI上では directional WALK として方向を読ませる。

### SLEEP / Shutter

SLEEP は盤面セルには置かない。

A–E列に対応するrail上を移動し、

```text
TOP light
↓
SLEEP / shutter
↓
その列のNOX
```

というTOP光路だけを遮る。

LEFT / RIGHT / BOTTOMには影響しない。

---

# 5. 光源

方向:

```text
TOP
LEFT
RIGHT
BOTTOM
```

影の向きは「光源からNOXを通って反対側へ伸びる」。

通常NOXの1ステップ影を概念的に書くと:

```text
TOP    -> 下
BOTTOM -> 上
LEFT   -> 右
RIGHT  -> 左
```

各Stageは、

- installed lights
- fixed active lights
- selectable lights
- active light count

を持つ。

### selectable light

必要数がすでにONの場合、別のライトを点ける前にひとつOFFへ戻す。

**BOTTOM light は selectable stage でも必ず操作可能。**

過去にBOTTOM入力UIの不具合があったため、今後も回帰ポイントとして扱う。

---

# 6. Shadow Plate

セル値は原因の重なり数。

```text
0 = clear / 影なし
1 = 単一の影
2 = 二重影
3+ = さらに重なった影
```

内部値は0〜3に固定しない。

複数NOX・Tall reach・複数光源の寄与は加算される。

---

# 7. FOG / 未観測

FOGまたは `?` は、

```text
「0」
```

ではない。

意味は、

```text
「このセルは観測されていない」
```

である。

Clear判定ではFOGセルを比較対象から除外する。

FOGを0として扱う実装は禁止。

---

# 8. Board Shape / 欠けたソケット

`boardShape.mask` が存在するStageでは、Placement Board自体が変形する。

```text
1 = ソケットあり
0 = ソケットなし
```

重要:

- 欠けたセルにはNOXを配置できない。
- **欠けたセルは壁ではない。**
- 光と影は欠けた場所を通過する。
- Shadow Plateは基本的に5×5の記録面を維持する。
- FOGと「ソケットなし」は別概念。

最終8問では盤面形状そのものが一意解に必要。

各問とも、maskを外すと解候補が2つへ増えることを検証済み。

---

# 9. Clear条件

Stage Clearには少なくとも以下が必要。

1. 必要なNOX数をすべて使用
2. 必要な型の個数が一致
3. visibleなShadowセルがすべてTargetと一致
4. light選択Stageでは正しい有効光数・組合せ
5. shutter Stageでは正しいrail位置
6. Board Shapeでは合法ソケットのみ使用
7. FOGは未知として無視

型付きinventoryでは、

```text
NormalをPlateの代わりに置く
TallをNormal扱いする
Plateをgeneric Post扱いする
```

などの代用でClearしてはいけない。

---

# 10. 36問の進行構造

大枠:

```text
GR01–GR20  基礎ルール・各ギミックの導入と組合せ
GR21–GR33  発展推理
GR34–GR36  変形盤面を含む総合問題・フィナーレ
```

GALLERYでは36記録を6章に整理する。

Grant提出は **36問で締める**。

以下はGrant提出に含めない:

```text
BS01 THE EMPTY STAIR
G01–G10 experiments
H01–H06 cause-light
旧Grant18
旧Grant20単体
v0.4 review campaign
```

---

# 11. GR01–GR36 Stage Index
## SPOILER: QA solutionを含む

記号:

```text
SIT     = normal
STAND   = tall
WALK-V  = plate_v
WALK-H  = plate_h
SLEEP-X = shutter column X
T/L/R/B = TOP / LEFT / RIGHT / BOTTOM light
```

| ID | Title | Inventory / mechanic | QA solution / special state |
|---|---|---|---|
| GR01 | FIRST SHADOW | SIT×1, T/L/R fixed | SIT C3 |
| GR02 | OVERLAP | SIT×2, T/L/R fixed | SIT B2, C3 |
| GR03 | EMPTY SPEAKS | SIT×3, T/L/R fixed | SIT B4, A5, B5 / 空白のD5で一意に決まる |
| GR04 | FOURTH LIGHT | SIT×1, T/L/R/B fixed | SIT C3 |
| GR05 | TWO SOURCES | fixed SIT C3, choose 2 lights | T+L |
| GR06 | LIGHT & POST | SIT×2 + light selection | SIT B3,D3 / L+R |
| GR07 | SHUTTER | SIT×2 + fixed SLEEP-C, T/L/R | SIT C3,E2 |
| GR08 | TWO UNKNOWNS | SIT×2 + movable SLEEP, T/L/R | SIT C2,D4 / SLEEP-C |
| GR09 | LONG REACH | STAND×1, T/L/R | STAND C3 |
| GR10 | MIXED HEIGHTS | SIT×1 + STAND×1, T/L/R | STAND C3 / SIT D4 |
| GR11 | TURN THE PLATE | fixed WALK at C3, rotate, T/L/R/B | C3: WALK-V → WALK-H |
| GR12 | CROSS SECTION | SIT×1 + WALK×1, T/L/R/B | SIT C3 / WALK-V D4 |
| GR13 | EDGE OR DARK? | fixed SIT C3 + WALK×1 + choose 3 lights | WALK-V C1 / T+L+R |
| GR14 | LONG & LIT | SIT×1 + STAND×1 + choose 2 lights | STAND C3 / SIT B3 / L+R |
| GR15 | PLATE & SHUTTER | SIT×1 + WALK×1 + movable SLEEP, four lights | SIT B3 / WALK-V D3 / SLEEP-B |
| GR16 | TWO AXES | WALK×2, four lights | WALK-V C2 / WALK-H C4 |
| GR17 | REACH & EDGE | STAND×1 + WALK×1, four lights | STAND C2 / WALK-H C4 |
| GR18 | LIGHT THROUGH A GAP | SIT×2 + movable SLEEP + choose 3 lights | SIT B3,D3 / SLEEP-B / T+L+R |
| GR19 | THREE MATERIALS | SIT×1 + STAND×1 + WALK×1, four lights | SIT B3 / STAND C4 / WALK-H C3 |
| GR20 | CALIBRATION | SIT×1 + STAND×1 + WALK×1 + movable SLEEP + choose 3 lights | SIT B2 / STAND C1 / WALK-V C4 / SLEEP-B / T+L+R |
| GR21 | BLOCKED REACH | SIT×2 + STAND×1 + movable SLEEP, four lights | SIT E2,E4 / STAND D3 / SLEEP-E |
| GR22 | WHICH AXIS IS LIT | SIT×2 + WALK×1 + choose 3 lights | SIT B2,C3 / WALK-H C4 / L+R+B |
| GR23 | LOCAL OR GLOBAL | SIT×3 + movable SLEEP + choose 3 lights | SIT B2,D2,A3 / SLEEP-D / T+L+B |
| GR24 | SHAPE OF THE SILENCE | shaped board, SIT×3, fixed T+L | SIT B1,E2,C4 |
| GR25 | THE LONG WAY THROUGH | shaped board, SIT×2 + STAND×1, fixed T+L | SIT C3,C5 / STAND C4 |
| GR26 | BEYOND THE BLOCKED AXIS | SIT×1 + STAND×1 + WALK×1 + movable SLEEP, four lights | SIT D3 / STAND C3 / WALK-V A3 / SLEEP-C |
| GR27 | TURN TOWARD THE LIGHT | SIT×1 + STAND×1 + WALK×1 + choose 3 lights | SIT D4 / STAND C4 / WALK-V D3 / T+L+B |
| GR28 | PLATE IN THE GAP | shaped board, SIT×2 + WALK×1, four fixed lights | SIT D4,C5 / WALK-V A2 |
| GR29 | VEILED SOCKETS | shaped board + FOG, SIT×3, fixed T+L | SIT D1,E2,C4 |
| GR30 | PARTIAL CROSS | SIT×2 + WALK×1 + movable SLEEP + FOG, four lights | SIT D3,D5 / WALK-H C4 / SLEEP-D |
| GR31 | UNSEEN BUT KNOWN | SIT×2 + STAND×1 + choose 2 lights + FOG | SIT D1,C5 / STAND D5 / R+B |
| GR32 | THE LAST OPEN AXIS | shaped board, SIT×1 + STAND×1 + WALK×1, four fixed lights | SIT B1 / STAND A3 / WALK-V B3 |
| GR33 | FOUR VOICES | SIT×2 + STAND×1 + WALK×1 + movable SLEEP, four lights | SIT A4,A5 / STAND C3 / WALK-V D4 / SLEEP-A |
| GR34 | FOUR CAUSES AGREE | shaped board, SIT×2 + STAND×1 + WALK×1, four fixed lights | SIT B1,A3 / STAND D4 / WALK-V B3 |
| GR35 | DENSE BOARD SYNTHESIS | shaped board, SIT×2 + STAND×1 + WALK×1, four fixed lights | SIT B2,C5 / STAND D2 / WALK-V E3 |
| GR36 | THE SHAPED FINALE | shaped board, SIT×2 + STAND×1 + WALK×1, four fixed lights | SIT A2,B4 / STAND C3 / WALK-H C2 |

> Targetの25セル値、FOG、ヒント文、reasoning signature等を変更・参照するときは、必ず `data/noxsum_grant36_v1.json` を読むこと。上表をJSONの代替データとして使用しない。

---

# 12. Board Shapes 最終8問

## GR24 — SHAPE OF THE SILENCE

```text
11 011 ではなく、正確には:

11011
11111
00100
11111
11011
```

- fixed lights: TOP + LEFT
- inventory: SIT×3
- solution: B1 / E2 / C4
- signature: SHADOW
- maskなし: 2 solutions

## GR25 — THE LONG WAY THROUGH

```text
00100
00100
11111
00100
00100
```

- fixed lights: TOP + LEFT
- inventory: SIT×2 + STAND×1
- solution: SIT C3,C5 / STAND C4
- signature: ZERO/TALL
- maskなし: 2 solutions

## GR28 — PLATE IN THE GAP

```text
10101
11111
00100
11111
10101
```

- fixed lights: TOP + LEFT + RIGHT + BOTTOM
- inventory: SIT×2 + WALK×1
- solution: SIT D4,C5 / WALK-V A2
- signature: OVERLAP/PLATE
- maskなし: 2 solutions

**旧GR28 `THREE KINDS OF ABSENCE` は不採用。**

## GR29 — VEILED SOCKETS

```text
11111
11111
00100
11111
11111
```

- fixed lights: TOP + LEFT
- inventory: SIT×3
- solution: D1 / E2 / C4
- FOG: E1, D3, D5
- signature: SHADOW
- maskなし: 2 solutions

## GR32 — THE LAST OPEN AXIS

```text
11000
11000
11000
11111
11111
```

- four fixed lights
- inventory: SIT×1 + STAND×1 + WALK×1
- solution: SIT B1 / STAND A3 / WALK-V B3
- signature: OVERLAP/TALL/PLATE
- maskなし: 2 solutions

## GR34 — FOUR CAUSES AGREE

```text
11000
11000
11000
11111
11111
```

- four fixed lights
- inventory: SIT×2 + STAND×1 + WALK×1
- solution: SIT B1,A3 / STAND D4 / WALK-V B3
- signature: SHADOW/TALL/PLATE
- maskなし: 2 solutions

## GR35 — DENSE BOARD SYNTHESIS

```text
00100
01110
11111
01110
00100
```

- four fixed lights
- inventory: SIT×2 + STAND×1 + WALK×1
- solution: SIT B2,C5 / STAND D2 / WALK-V E3
- signature: ZERO/TALL/PLATE
- maskなし: 2 solutions

## GR36 — THE SHAPED FINALE

```text
11011
11111
00100
11111
11011
```

- TOP / LEFT / RIGHT / BOTTOM **すべて固定ON**
- inventory: SIT×2 + STAND×1 + WALK×1
- solution: SIT A2,B4 / STAND C3 / WALK-H C2
- signature: OVERLAP/TALL/PLATE
- maskなし: 2 solutions

GR36では光源選択やSLEEP操作を追加しない。

最後は、これまで学んだ「影・重なり・空白・Reach・WALK軸・盤面形状」を読むことに集中させる。

---

# 13. FOGを含む最終問題

少なくとも最終デッキでは以下を回帰確認対象にする。

### GR29

```text
FOG = E1, D3, D5
```

Board Shapeあり。

### GR30

```text
FOG = A1, C5, D5
```

movable SLEEPあり。

### GR31

```text
FOG = E1, A2, E3, E4, B5
```

2-light selectionあり。

FOGはすべてUNKNOWNであり、0ではない。

---

# 14. UI用語

英語の基本UI:

```text
RECORDED SHADOW
RECONSTRUCTION
WHERE WAS NOX?
NIGHT LOG
OBSERVE
BACK
RESET
UNDO
NEXT
```

日本語は完全ローカライズを維持する。

言語切替は、

- HOME
- SETTINGS
- Stage header

から可能。

Stage途中で言語を切り替えても、

- 現在配置
- light状態
- SLEEP位置
- Night Log clue level

を壊さない。

---

# 15. Hint / Night Log

通常ヒントは答えを配置しない。

Night Log / OBSERVEは、

```text
「どこを見るか」
「何を比較するか」
```

を示すためのもの。

自動解答は禁止。

スマホでは Night Log を開閉式にし、巨大な空パネルを常設しない。

---

# 16. First Play UX

初回のTrace 01には日英4ステップのガイドを持つ。

概念:

```text
1. RECORDED SHADOW と RECONSTRUCTION を比較
2. NOX姿勢を選ぶ
3. WHERE WAS NOX? に置く
4. すべての濃淡を合わせる
```

Stage中の `?` から再確認可能。

---

# 17. Solve / Finale

Solve時:

- 影の一致を即時判定
- plate scan / glint
- 控えめな完成音
- TRACE MATCHED
- NEXT解禁

36問すべて完了した状態でGR36をClearすると専用フィナーレ。

36点を1本のrecord pathとして結び、

```text
RECONSTRUCTION COMPLETE
```

を示す。

**「NOXが帰ってきた」とは断定しない。**

HOMEでは完走後、

```text
CONTINUE
```

の代わりに、

```text
VIEW RECORDS / 記録を見直す
```

を出す。

---

# 18. Art / HOME

最新HOMEは旧 optical-lab HOMEではなく、v0.6系を使う。

```text
assets/nox/v0.6/archive_puzzle_window.png
assets/nox/v0.6/app_icon.png
```

方向性:

- 猫
- 窓
- 月夜
- パズル盤
- NOXSUM文字はlive rendering

NOXの毛柄は白主体 + 黒 + グレーの三毛を固定し、HOME / SIT / STAND / WALK / SLEEPで一貫させる。

旧 `archive_window.png` や古いgrid lab HOMEを最新版として扱わない。

---

# 19. Audio

現在のGrant Web版ではサウンド初期状態は **OFF**。

プレイヤーがONにした後に再生を開始する。

現在の実装は **4曲を順送りするBGM構成**。

古い文書にある、

```text
ガラス張りの三角錐.mp3 1曲だけを永続loop
```

という説明は、現行4曲構成より古い可能性があるため、今後は**現在のコード/playlist定義を優先**する。

ブラウザではユーザー操作前のautoplay制限を守る。

SFXは現在の実装を維持する。

---

# 20. Web / Grant提出

エンジン:

```text
Godot 4.7
```

Export preset:

```text
NOXSUM Web
```

Web設定の基本:

- Canvas resize: Adaptive
- Threads: OFF
- PWA packaging: OFF
- current Grant dataを明示的にinclude
- 古い puzzle decks / dev toolsは製品から除外

公開先:

```text
https://noxsum.netlify.app/
```

ローカライズshare pages:

```text
/en/
/ja/
```

---

# 21. Viewport / Responsive

基準:

```text
720×900  PC / Grant
405×900  mobile
360×800  small mobile
```

ただし **2026-09-25時点で、実スマホWebのDPR / canvas幅問題を修正中**。

重要な既知履歴:

```text
CSS viewport 360px
devicePixelRatio 2
Godot internal viewport 720px
```

となり、mobile breakpointがdesktop扱いになる不具合が発生した。

その後CSS viewport基準の判定へ修正したが、実ブラウザでcanvas crop / 座標系のずれが再度確認された。

したがって、

> headless smokeの「bounds内」だけでモバイル完了と判定しない。

最終承認条件:

- 実Web export
- HTTP配信
- 実ブラウザ360×800
- RECORDED + RECONSTRUCTION 両方が見える
- Board 5列すべて見える
- Header全体が見える
- Light全方向が見える
- Inventoryが見える
- Night Log collapsed
- Action barが画面内

を**スクリーンショットで目視確認すること**。

---

# 22. Validation

最終 Grant36 は機械的に一意解検証済み。

確認対象:

- 36 stages
- 128 Board Shape candidates
- exact typed inventory
- malformed mask rejection
- FOG unknown-as-zero rejection
- Board Shapeなしcounterfactual
- Tall-as-Normal substitution
- Plate-as-Normal substitution
- illegal socket placement
- Plate return / rotate
- save/load
- undo
- BOTTOM input

最終8 replacementは全て、

```text
with mask: 1 solution
without mask: 2 solutions
```

を満たす。

---

# 23. 人間プレイテストで分かっていること

旧v0.4後半のテストでは、light selection + shutterの複合が負荷になりやすかった。

特に、

```text
GR22
GR23
GR27
GR31
```

はlight selectionが詰まり要因になった履歴がある。

その後BOTTOM UI不具合も見つかり修正対象になった。

Grant最終版では、難しさを「操作項目を増やすこと」より、

```text
影
重なり
ZERO
Reach
方向性
FOG
盤面形状
```

の読みへ寄せる方針。

最終Board Shapes 8問ではlight selection / movable shutterを新規に足していない。

---

# 24. Grant版でやらないこと

現Grant36には追加しない:

- Reflector
- 発光Post
- BS01 bonus
- 新しいbonus puzzle
- 新ルール
- 37問目以降
- 100問スマホ版の追加問題

Grant提出までは36問をContent Freezeする。

今後のスマホ製品版100問化は別フェーズ。

---

# 25. 歴史資料の扱い

以下は「参考資料」であり、現在のGrant仕様の正本ではない。

```text
GRANT18_DESIGN.md
GRANT_EXPERIMENTS_SPEC_v0_1.md
CAUSE_LIGHT.md
grant36_v0_4_draft.json
BS01 THE EMPTY STAIR
Jev second review
古いSHADOW SUM HOME資料
```

Jevは定性的な第二審査のみ。

一意解や合法性はvalidatorを優先する。

---

# 26. 今後のチャットで守るルール

新しいチャットでNOXSUMを扱う場合:

1. タイトルは **NOXSUM**
2. Grant版は **36問**
3. 製品デッキは `data/noxsum_grant36_v1.json`
4. 最終8 replacementは Board Shapes版
5. GR28は **PLATE IN THE GAP**
6. GR36は **THE SHAPED FINALE**
7. BS01はGrant版に含めない
8. FOGは0ではない
9. missing socketは壁ではない
10. BOTTOM light入力を忘れない
11. HOMEはv0.6系
12. 旧prototype UIへ戻さない
13. モバイル完了は実ブラウザ画像で判断
14. 不明なStage細部を過去チャットの記憶で補完せず、current JSONを確認する

---

# 27. Canonical reference priority

矛盾がある場合の優先順位:

```text
1. 現在の data/noxsum_grant36_v1.json
2. この NOXSUM Grant36 Master Specification
3. docs/NOXSUM_GRANT_36.md
4. final Board Shapes validator/report
5. 現在のGodot runtime
6. 過去のGrant20 / v0.4 / experiments資料
7. 過去チャット上の記憶
```

ビジュアルについては:

```text
現在の C:\Dev\Projects\shadow-sum
+ v0.6 assets
```

を最優先する。

---

# 28. Short Context for AI

> NOXSUM is the renamed SHADOW SUM project.  
> The Draknek Grant build is fixed at 36 puzzles, GR01–GR36.  
> The canonical product data is `data/noxsum_grant36_v1.json`.  
> GR24/25/28/29/32/34/35/36 are the final Board Shapes replacements from commit `42a4b5b`; GR28 is `PLATE IN THE GAP`, and GR36 is `THE SHAPED FINALE`.  
> The player reconstructs where NOX was and in which pose from recorded shadows using SIT, STAND, directional WALK, lights, occasional SLEEP/shutter, FOG and shaped boards.  
> FOG means unknown, not zero. Missing sockets cannot hold NOX but do not block light.  
> Grant scope is exactly 36 puzzles; bonus/experiment campaigns are excluded.  
> Current visual source is the latest local NOXSUM build under `C:\Dev\Projects\shadow-sum`, with v0.6 HOME/icon assets.  
> Never restore an older Grant20/v0.4 puzzle or old optical-lab HOME merely because an older document or branch contains it.
