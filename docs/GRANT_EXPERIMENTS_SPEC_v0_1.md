# SHADOW SUM — GRANT EXPERIMENTS G01–G10

## Godot Implementation Specification v0.1

## 1. 目的

G01〜G10は、既存18問を置き換える新キャンペーンではない。

目的は、

**SHADOW SUMの基本ルールから、説明文なしで「新しい発見」を生み出せるか**

を検証すること。

既存18問は、投影、重なり、霧、残Post数、短い仮説検証を段階的に教える完成度の高いロジックパズル群として保持する。現在のGrant版も、機械検証ではなく人間による楽しさ・理解・難易度確認が残課題と整理されている。

G01〜G10では別の問いを見る。

> 「難しいから面白い」のではなく、
> 「世界の見え方が変わったから面白い」か。

目標体験は以下。

1. 操作対象を見れば、説明なしでも触ってみたくなる。
2. すぐには分からないが、闇雲な総当たりにはならない。
3. 新しい現象を一度観察すると、仮説を立てられる。
4. 仮説が盤面上で即座にフィードバックされる。
5. 発見後は問題が一気に読みやすくなる。
6. 解答時に「そういうことか」という納得がある。
7. NEXTを自発的に押したくなる。

---

# 2. 絶対に壊さないもの

現行SHADOW SUMの基本モデルを維持する。

* Board: 5×5
* Postはセル単位のbinary state
* Shadow ScreenとPlacement Boardは概念的に別空間
* 見えている影と指定Post数の両方が成立してClear
* authoritative stateはグリッドロジック
* 描画上の光や影はpresentation
* exhaustive uniqueness validationを維持

現行ルールは、

`S(r,c) = P(r-1,c) + P(r,c-1) + P(r,c+1)`

という単純な3方向投影で成立している。

また、ゲームロジックをレンダリングされた光や影のpixel値に依存させない原則も維持する。

**光学ギミックを追加しても、solverが完全に再現できる離散モデルであること。**

---

# 3. 既存18問との隔離

既存Grant 18には変更を加えない。

新規：

```text
data/grant_experiments_v0_1.json
src/experiment_optics.gd
src/experiment_main.gd
tools/validate_grant_experiments.py
tools/grant_experiment_smoke.gd
```

推奨セーブ：

```text
user://shadow_sum_grant_experiments_v0_1.json
```

既存：

```text
user://shadow_sum_grant18_progress_v1.json
```

とは完全分離する。

現行Grant版が旧キャンペーンとセーブを分離した理由と同じく、異なる意味を持つStage ID同士を混ぜない。

開発中は、

```text
--campaign grant18
--campaign experiments
```

またはdebug menuから切替可能にする。

---

# 4. 光学モデル拡張

## 4.1 LightDir

```gdscript
enum LightDir {
    TOP,
    LEFT,
    RIGHT,
    BOTTOM
}
```

既存3方向：

```text
TOP    -> Postの下側へ影
LEFT   -> Postの右側へ影
RIGHT  -> Postの左側へ影
```

追加：

```text
BOTTOM -> Postの上側へ影
```

Shadow Screen側から見ると、

```text
TOP    contribution = P(r-1, c)
LEFT   contribution = P(r, c-1)
RIGHT  contribution = P(r, c+1)
BOTTOM contribution = P(r+1, c)
```

となる。

active lightのみ寄与する。

```gdscript
func compute_shadow(
    posts,
    active_lights,
    shutters,
    post_types
) -> Array[int]
```

---

# 5. Light状態

各StageまたはObservationは、

```json
"active_lights": ["TOP", "LEFT", "RIGHT"]
```

を持つ。

OFFのライトは、

* 発光しない
* beam/glowを出さない
* Shadow計算に参加しない
* tap可能ならdimmed interactive state
* 固定OFFならdimmed locked state

を明確に区別する。

**「壊れているのか、押せるのか」が曖昧にならないこと。**

---

# 6. Observation

複数観測を扱えるようにする。

```json
"observations": [
  {
    "id": "A",
    "active_lights": ["TOP", "LEFT"],
    "target": {}
  },
  {
    "id": "B",
    "active_lights": ["TOP", "RIGHT"],
    "target": {}
  }
]
```

Post / Shutter stateはObservation間で共有する。

つまり、

```text
World State
 ├ Posts
 ├ Shutters
 └ Post Types

Observation A
 └ Light State

Observation B
 └ Light State
```

という構造。

Clear判定：

```text
すべてのObservationでTarget == Current
AND
必要な配置数・状態条件を満たす
```

一つのObservationだけ一致してもClearしない。

---

# 7. Observation操作

複数観測Stageでは、画面上部の光源そのものを触って状態を切り替える。

状態切替時：

```text
tap
↓
lamp click
↓
旧shadow 80〜120ms fade
↓
新しいlight beam点灯
↓
shadow 160〜220ms recomposition
```

完全な暗転は禁止。

**同じ物体を別照明で見ている**

感覚を残す。

Postの配置は1pixelも動かさない。

これが「別問題」ではなく「別観測」だと視覚的に伝える。

---

# 8. Shutter

v0.1ではTop Light用だけ実装する。

5列：

```text
A B C D E
```

に対応する小型の遮光板。

```gdscript
class_name OpticalShutter

var light_dir: LightDir
var slot: int
```

Top/CにShutterがある場合、

**C列にあるPostへのTOP Light寄与だけを無効化する。**

Post自体やLEFT/RIGHT Lightには影響しない。

この仕様なら、

```text
TOP
 ↓
[SHUTTER]
 ↓
 Post
 ↓
 shadow
```

が遮断される。

ShutterはTarget Shadowセルを隠す物体ではない。

---

# 9. Shutter操作

可動Shutterはboard cellに置かない。

Top Light直下に細いrailを設ける。

```text
LIGHT ARRAY
 ● ● ● ● ●

 A B C D E
 ─────────  <- shutter rail

     ■       <- draggable shutter

 BOARD
```

操作：

* drag開始で少し持ち上がる
* rail上を横移動
* 最近傍slotへ磁気snap
* releaseで確定
* slot変更のたびCurrent Shadowを即再計算

tap-only fallbackも実装。

空slotをtapするとShutterがそこへ移動する。

これによりスマホで細い物体をdragしにくい場合も操作できる。

---

# 10. Tall Post

通常：

```text
cast_length = 1
```

Tall：

```text
cast_length = 2
```

3方向それぞれ、

```text
distance 1
distance 2
```

に1ずつ寄与する。

盤外は無視。

Tall Postは形状だけで通常Postとの差を認識できること。

文字：

```text
TALL
LONG
2
```

などをPost本体に表示しない。

G06ではInventoryにTall Postしか置かないため、種類選択UIも不要。

---

# 11. Shadow値

内部値は固定0〜3に限定しない。

```gdscript
shadow_value: int
```

active light数や将来拡張に応じて0以上。

G01〜G10では、プレイヤーに新概念を発見させることを優先し、原則として新ギミックStageのTargetは`0 / 1`中心にする。

新しい現象と濃淡推理を同時に教えない。

---

# 12. 操作感の基本原則

現行のmagnetic/drag semanticsを維持する。Grant版でもこの操作系は変更しない方針になっている。

### Post

既存どおり：

```text
tap empty socket -> place
tap occupied -> remove

または

drag Post -> magnetic socket preview -> release
```

### Light

```text
tap lamp -> immediate physical response
```

100ms以上「押したのに何も起きない」時間を作らない。

### Shutter

```text
drag rail
or
tap slot
```

### Observation

新しい画面へ遷移しない。

**盤面はその場に残り、光だけ変わる。**

---

# 13. Input Priority

同時入力の誤爆防止。

```text
1. Footer UI
2. Light
3. Shutter
4. Existing Post
5. Empty socket
6. Background
```

Light付近からPost dragが開始されないこと。

Shutter rail付近のtapをboard placementとして扱わないこと。

---

# 14. 新概念Stageの難易度原則

G01〜G08では、

**「概念に気づくこと」自体を問題にする。**

概念発見後に長いロジックチェーンを要求しない。

目標：

```text
発見前:
「ん？ なぜ合わない？」

発見:
「あ、これ触れるのか」
「あ、ここで光が遮られてる」

発見後:
1〜3個の明快な操作・推理

CLEAR
```

G09〜G10のみ複数概念を組み合わせる。

新概念＋高難度推理＋大量の霧を同時投入しない。

---

# 15. G01 — ONE LIGHT OUT

## Concept

光源がOFFなら、その方向の影は存在しない。

## Player State

```text
movable Posts: 1
controllable lights: none
fixed active lights:
  TOP
  LEFT

fixed off:
  RIGHT
```

## Solution

```text
C3
```

## Target non-zero

| Cell | Value |
| ---- | ----: |
| D3   |     1 |
| C4   |     1 |

その他 visible cell = 0。

## Discovery

RIGHT lightは視覚的に消灯。

最初から、

```text
「故障したアイコン」
```

ではなく、

**実際にそこだけ光が出ていない装置**

として見せる。

## Expected Thought

「C3なら普通は3方向に出るはず」

↓

消灯ライトを見る。

↓

「だから2方向なのか」

## Complexity

Concept discoveryのみ。

発見後はほぼ即解。

---

# 16. G02 — SWITCH

## Concept

光源は観測条件。

プレイヤー自身が変更できる。

## Posts

```text
2
```

## Solution

```text
B2
D5
```

## Observation A

```text
active: TOP
```

Target:

| Cell | Value |
| ---- | ----: |
| B3   |     1 |

この観測だけでは全配置を確定できない。

## Observation B

```text
active: LEFT
```

Target:

| Cell | Value |
| ---- | ----: |
| C2   |     1 |
| E5   |     1 |

## Interaction

TOP lampとLEFT lampを直接tap可能。

初期はTOP。

未使用LEFT lampは、

プレイヤーが一定時間停止した場合のみ、

```text
scale 1.00 -> 1.035 -> 1.00
```

を一度だけ行う。

文字指示は禁止。

## Clear

両Observationに一致するPost配置。

Solutionは一意。

---

# 17. G03 — DOUBLE EXPOSURE

## Concept

同じ物体を複数の照明条件で見る。

片方だけでは足りない情報が、組み合わせると決まる。

## Posts

```text
3
```

## Solution

```text
A1
B3
D5
```

## Observation A

```text
TOP + LEFT
```

Target non-zero:

```text
B1
A2
C3
B4
E5
```

すべて1。

## Observation B

```text
TOP + RIGHT
```

Target non-zero:

```text
A2
A3
B4
C5
```

すべて1。

## UX

Observationを切り替えてもPostsは完全静止。

Shadow Screenだけが再構成される。

## Design Goal

ここが最初の**Grant候補Stage**。

狙う感情：

> 「2枚の影が同じ物体を見てるんだ！」

単なるヒント増加ではなく、「観測」という新しい読み方を成立させる。

---

# 18. G04 — SHUTTER

## Concept

光源がONでも光路が遮られることがある。

## Posts

```text
2
```

## Fixed Shutter

```text
TOP / C
```

## Solution

```text
C3
E2
```

## Active

```text
TOP
LEFT
RIGHT
```

## Target non-zero

```text
D2
B3
D3
E3
```

すべて1。

## Important Visual

C列Top railのShutterから、

ごく薄いbeamが手前で切れているのが見える。

ただし解答を直接示す大げさな線は出さない。

## Intended Realization

C3は横には影を出す。

しかし下には出ない。

↓

「C3が特殊なのではない」

↓

光路を見る。

↓

Shutter。

---

# 19. G05 — FOURTH LIGHT

## Concept

「3方向」が法則なのではない。

光源が3つだったから3方向だった。

## Posts

```text
1
```

## Active

```text
TOP
LEFT
RIGHT
BOTTOM
```

## Solution

```text
C3
```

## Target non-zero

```text
C2
B3
D3
C4
```

すべて1。

## Presentation

Stage load後、

盤面下の4灯目が静かに点灯。

派手な説明演出は禁止。

0.3秒程度のwarm ignitionだけ。

## Intended Realization

十字の影を見る。

↓

「上向きにも影？」

↓

下側のlightを見る。

↓

理解。

## Priority

**Grant最重要候補。**

既存18問で覚えたルールを否定せず、

```text
3方向投影
```

を、

```text
光が3方向から来ていた
```

という上位概念へ包み直す。

---

# 20. G06 — TALL POST

## Concept

物体の形状によって影の届き方が変わる。

## Inventory

```text
Tall Post x1
```

通常Postなし。

## Solution

```text
C3
```

## Active

```text
TOP
LEFT
RIGHT
```

## Target non-zero

```text
A3
B3
D3
E3
C4
C5
```

すべて1。

## Feedback

Tall Postを置いた瞬間、

内側の3 shadowsが先に出て、

外側3 shadowsが30〜50ms遅れて伸びる。

計算結果は即確定してよい。

animationだけで「長く伸びた」を感じさせる。

## Evaluation

このStageは**落選候補にもなり得る**。

プレイヤーが、

「背が高いから影が長い」

と自然に理解するなら残す。

「Tall Postという新駒のルールを暗記した」

と感じるならMobile後半へ回す。

---

# 21. G07 — WHICH LIGHT?

## Concept

推理対象はPostとは限らない。

## Fixed Posts

```text
C3
D4
```

Postは移動不可。

## Player Action

3 lightsのうち1つをOFFにする。

## Solution

```text
RIGHT OFF
```

## Target non-zero

```text
D3
C4
E4
D5
```

すべて1。

## UI

Post socketをtapしても動かない。

ただし「禁止」SEは鳴らさない。

固定Postに軽いmaterial knock feedbackだけ。

Lightはhover/touch reactionあり。

## Intended Realization

いつものようにPostを触る。

↓

動かない。

↓

Lightが反応する。

↓

「今回はこっちを解くのか」

## Clear Beat

RIGHTをOFF。

ShadowがTargetへ収束。

0.45秒solve breath。

Clear。

現行Grant版のsolve breathは0.45秒を維持しているため、このリズムに合わせる。

---

# 22. G08 — MOVE THE SHUTTER

## Concept

光路そのものを復元する。

## Fixed Posts

```text
B2
D4
```

## Inventory

```text
Top Shutter x1
```

## Solution

```text
TOP / D
```

## Target non-zero

```text
A2
C2
B3
C4
E4
```

すべて1。

## Interaction

ShutterをA〜E railにdrag。

slotが変わるたびShadowがライブ更新。

### Feel

```text
drag
↓
small metallic slide
↓
snap
↓
one component of shadow disappears/returns
```

操作と因果が密接に見えること。

## Intended Realization

「この黒い板、どこに置けばこの影になる？」

ここからSHADOW SUMは、

**Postの位置だけでなく光路を解くゲーム**

になる。

---

# 23. G09 — TWO KINDS OF UNKNOWN

## Concept

Postと光路を同時に復元する。

## Inventory

```text
Post x2
Top Shutter x1
```

## Solution

```text
Posts:
C2
D4

Shutter:
TOP / C
```

## Active

```text
TOP
LEFT
RIGHT
```

## Target non-zero

```text
B2
D2
C4
E4
D5
```

すべて1。

## Verification

全25セルをvisibleとして、

```text
2 Posts
+
Top Shutter A〜E
```

の全組み合わせを列挙した場合、この組は一意になることをvalidatorで固定検証する。

## Intended Reasoning

横方向shadowからPostsを絞る。

↓

縦方向だけ合わない。

↓

Post配置を疑い続けるのではなく、

「TOP Lightだけ何かがおかしい」

と気づく。

↓

Shutter位置を決定。

## Difficulty

ここから初めて、

**発見後にも少し考える**

問題にする。

ただし仮説のネストは禁止。

---

# 24. G10 — PARALLAX

## Concept

観測条件を変えることで、複数種類の未知を分離する。

## Inventory

```text
Post x2
Top Shutter x1
```

## Solution

```text
Posts:
D2
B4

Shutter:
TOP / B
```

## Observation A

```text
TOP + LEFT
```

Target non-zero:

```text
E2
D3
C4
```

## Observation B

```text
TOP + RIGHT
```

Target non-zero:

```text
C2
D3
A4
```

## Uniqueness Structure

現在の離散モデルでは、

```text
Observation A単独: 5候補
Observation B単独: 4候補
A+B: 1候補
```

となる構成。

validatorでこの候補数も回帰テストする。

単に「一意解」で終わらせず、

**本当に複数観測が必要な問題であること**

まで保証する。

## Desired Experience

Aを見る。

考える。

決まらない。

↓

Observationを切り替える。

↓

Shadowが動く。

↓

共通して説明できる配置を考える。

↓

「あっ、違いを見るのか」

↓

PostsとShutterが一気につながる。

## Finale Condition

難しいからFinaleなのではない。

**G01から触ってきた光学装置そのものを理解したことが解答になる**

からFinale。

---

# 25. Puzzle Feel

全Stageで、

```text
INPUT
↓
CAUSE
↓
OPTICAL RESPONSE
```

を200ms前後で感じられること。

Postを置いた場合：

```text
socket snap
20〜40ms
light/shadow recomposition
160〜220ms
settle
```

Light：

```text
click
instant emitter response
80〜180ms shadow transition
```

Shutter：

```text
snap
small physical click
shadow contribution retracts
```

音は短く静か。

正誤判定の「ブブー」音は禁止。

間違った配置も、

**装置として正しく反応している**

ことが重要。

プレイヤーは失敗したのではなく、実験をした。

---

# 26. Clear演出

現行仕様では、

```text
fragmentary clues
→ solved placement
→ complete shadow blooms into view
```

が報酬として設計されている。

Experimentsでも継承する。

Clear：

```text
0 ms    最後の操作
150 ms  Shadow settles
450 ms  full optical state reveal
650 ms  subtle resonance
900 ms  NEXT available
```

Observation StageではClear時、

A / Bを高速点滅させない。

代わりに、

```text
A
→ gentle transition
→ B
→ complete optical state
```

を一度だけ見せてもよい。

プレイヤーが「なぜ正しかったか」を視覚的に再確認できること。

---

# 27. Hint Policy

内部プレイテスト版でも既存WHISPERシステムを利用可能にする。

WHISPERの原則は、

**どこを見るか、どんな推理を試すかを示し、Postを直接置かない**

こと。

Experiments用にsurfaceを拡張：

```text
clue
socket
light
shutter_slot
observation
```

ただし、最初の発見テストではHintを自動表示しない。

記録：

```text
NO HINT
HINT I
HINT II
HINT III
```

Grant候補条件として、

**大半がHint II/IIIなしで概念を理解できること**

を重視する。

---

# 28. Puzzle Validation

新validatorは各Stageについて全状態探索する。

最低条件：

```text
G01 unique Post solution
G02 unique across both observations
G03 unique across both observations
G04 unique with fixed shutter
G05 unique
G06 unique Tall Post placement
G07 unique light state
G08 unique shutter slot
G09 unique Posts + shutter
G10 A alone non-unique
G10 B alone non-unique
G10 A+B unique
```

特にG10については、

```text
A candidates == 5
B candidates == 4
combined candidates == 1
```

をexpected assertionとして固定する。

将来ロジック変更で「片方だけでも解ける問題」に壊れた場合、CIをREDにする。

---

# 29. Godot Smoke

`tools/grant_experiment_smoke.gd`

最低限：

```text
1. G01 load
2. active light state correct
3. G01 C3 solves
4. G02 light tap changes observation without changing Posts
5. G03 observation switch preserves world state
6. G04 fixed shutter suppresses only TOP/C contribution
7. G05 BOTTOM light generates upward contribution
8. G06 Tall Post reaches distance 2
9. G07 fixed Posts cannot move
10. G07 correct light OFF solves
11. G08 shutter drag/tap snaps A〜E
12. G08 shadow updates after shutter move
13. G09 mixed state solves only exact configuration
14. G10 A/B switching preserves Posts and Shutter
15. G10 clear requires both observations
16. RESET restores stage-specific optical state
17. BACK/NEXT kills old tweens
18. Experiment progress never touches Grant18 progress
19. 405 / 676 / 720 width layout
20. existing smoke suite stays GREEN
```

---

# 30. First-Time Playtest

最低5〜8人。

説明：

```text
「このパズルを遊んでみてください」
```

だけ。

新しい光学ルールを口頭説明しない。

各Stageで記録：

| 観測       | 記録                           |
| -------- | ---------------------------- |
| 最初に触ったもの | Post / Light / Shutter / その他 |
| 新概念への気づき | 自力 / 偶然操作後 / Hint / 説明必要     |
| 気づくまで    | 時間                           |
| 解答まで     | 時間                           |
| 無意味な総当たり | 回数                           |
| Reset    | 回数                           |
| Hint     | I / II / III                 |
| 解答直後の発言  | verbatim                     |
| NEXT     | 自発的 /促されて                    |
| もう一問     | yes / neutral / no           |

重要なのはsolve timeだけではない。

**気づいた瞬間に表情や発言が変わるか。**

Grant候補はここで選ぶ。

---

# 31. Grant Candidate Gate

各ギミックについて：

### KEEP

* 説明なしで理解できる
* 操作と現象の因果が見える
* 発見前には適度な疑問がある
* 発見後には盤面がほどける
* Clear後に納得できる
* NEXT率が高い
* 「もっと難しい」ではなく「そんなこともできるのか」が出る

### MOBILE

面白いが、

* 説明が必要
* 新駒の暗記に見える
* 既存ロジックのvariationとしては良い

場合。

### DROP

* 何をすればよいか分からない
* brute forceの方が早い
* 解答後にも理由が分からない
* 見た目とロジックの因果が一致しない

場合。

---

# 32. 現時点の優先評価

Grant本命候補：

```text
G03 DOUBLE EXPOSURE
G05 FOURTH LIGHT
G07 WHICH LIGHT?
G10 PARALLAX
```

強い補助候補：

```text
G04 SHUTTER
G08 MOVE THE SHUTTER
G09 TWO KINDS OF UNKNOWN
```

判定待ち：

```text
G01 ONE LIGHT OUT
G02 SWITCH
G06 TALL POST
```

G01/G02は単体の驚きより、後半の発見を成立させる教育として評価する。

G06は「物理現象の発見」になるか「特殊駒の追加」に見えるかで採否を決める。

---

# 33. 実装順

Phase 1：

```text
LightDir abstraction
active_lights
BOTTOM support
generic optical compute
validator
```

Phase 2：

```text
G01
G02
G03
G05
```

まず**光源系4問だけ**を触れる状態にする。

ここで面白くなければ、Shutter系へ大量投資しない。

Phase 3：

```text
Shutter model
rail UI
G04
G08
```

Phase 4：

```text
mixed solver
G09
G10
```

Phase 5：

```text
Tall Post
G06
```

Tall Postは最後。

G06のために基盤を複雑化しない。

---

# 34. Definition of Done v0.1

G01〜G10が完成した、ではなく以下を満たして完了とする。

* 既存Grant18無変更
* Experiment専用campaignとして起動可能
* 全Stage authoritative stateが離散ロジック
* 全Stage exhaustive validation
* G10候補数 5 / 4 / 1 を保証
* Light切替が即応する
* Shutterがtouchでもdragでも快適
* Observation変更時にworld stateを保持
* 405 / 676 / 720 widthで誤操作なし
* G01〜G10全通しsmoke GREEN
* 既存CI GREEN
* 5〜8人の初見テスト完了
* 各ギミックをKEEP / MOBILE / DROPに分類
* Grant版への採用はその後に行う

---

# 35. この実験の成功条件

成功は「G01〜G10が全部面白い」ことではない。

むしろ、

**10個試して3〜5個だけ異様に強い**

くらいが望ましい。

その強い発見だけを拾い、

既存18問とは別に、

```text
teach
discover
reinterpret
reverse
combine
```

というGrant Campaignを改めて構築する。

一方、突出した発見が出なければ、

既存18問の気持ちよい難易度曲線を軸に、

**Mobile 100**

へ進む。

どちらになっても、この実験でSHADOW SUMの正体が一段はっきりする。

最初のSHADOW SUMは、

> 影からPostを当てる。

G10まで進んだSHADOW SUMは、

> **光を変え、影を比較し、見えない世界の構造を復元する。**

そこまで自然に到達できるかを、この10問で確かめる。
