# NOXSUM_OPENING_KAMISHIBAI_TASK_v0.1

## 0. 目的

NOXSUMの初回プレイ前に、**短い「アニメーション紙芝居」**を入れる。

説明書ではなく、プレイヤーが自然に

1. ここは「夜の光学資料室」である
2. NOXがいた瞬間の**影が記録される**
3. ひとつの記録には、複数の瞬間の影が重なることがある
4. プレイヤーはその影から、**NOXがどこで何をしていたかを再構築する**
5. その再構築がNOXSUMのパズルである

と理解した状態でGR01へ入れることが目的。

**「ルールを覚えさせる」より、「自分が何をしているゲームなのか」を腹落ちさせる。**

---

# 1. Source of truth

実装前に必ず以下を読む。

```text
NOXSUM_GRANT36_MASTER_SPEC_v1.0.md
data/noxsum_grant36_v1.json
docs/NOXSUM_GRANT_36.md
```

開発ルート:

```text
C:\Dev\Projects\shadow-sum
```

現タイトルは **NOXSUM**。

旧SHADOW SUM表記を新規UIへ追加しない。

Grant版はGR01–GR36の36問で固定。

---

# 2. Canon

NOXSUMは **Nocturnal Optical Archive / 夜の光学資料室** を舞台にした静かな論理ミステリー。

プレイヤーが復元するもの:

- NOXがどこにいたか
- NOXがどの姿勢だったか
- 必要な記録では、どの光が点いていたか
- 必要な記録では、どこで光が遮られていたか

重要:

- 影の記録から「出来事の時系列」は確定しない
- NOXの最終的な運命を断定しない
- 「NOXが帰ってきた」などの結論を追加しない
- 紙芝居では未来のギミックを詳しく教えない

世界観の中心語:

```text
RECORD / 記録
SHADOW / 影
RECONSTRUCT / 再構築
NOX
```

---

# 3. 体験方針

形式は**静止画をただ切り替える紙芝居ではなく、絵の一部だけが静かに動く「アニメーション紙芝居」**。

例:

- 1〜3%のゆっくりしたpush-in
- 月明かりのわずかな揺れ
- 光源の点灯
- NOXのシルエットの短い移動
- 影だけが残る
- 複数の影が1枚のplateへ重なる
- 最後にRECONSTRUCTIONがRECORDED SHADOWへ一致する

派手な映画予告にはしない。

目標感情:

```text
「何だろう、この場所」
↓
「影を記録してるんだ」
↓
「NOXがいた跡だけ残ってる」
↓
「あ、この影から場所と姿を戻すゲームなのか」
↓
GR01開始
```

---

# 4. 長さ

目標:

```text
18〜24秒
```

最大でも30秒以内。

文章を全部読み終えるまで強制待機させない。

各Sceneはtap/clickで次へ進めてもよい。

常時 `SKIP / スキップ` を表示する。

---

# 5. First-run route

初回:

```text
HOME
↓
PLAY
↓
OPENING KAMISHIBAI
↓
GR01 / FIRST SHADOW
```

2回目以降:

```text
HOME
↓
PLAY / CONTINUE
↓
通常どおりStageへ
```

opening視聴済み状態は既存設定ファイルへ保存する。

推奨:

```text
user://noxsum_settings.cfg
opening_seen=true
```

Stage progressファイルには混ぜない。

SKIPした場合も `opening_seen=true` とする。

---

# 6. Replay

あとから再視聴可能にする。

既存HOMEを大きく崩さない範囲で、

```text
ABOUT
or
HOW TO PLAY
```

内に

```text
PROLOGUE / プロローグ
```

を追加する。

Replayでは `opening_seen` を変更しない。

---

# 7. Storyboard

## Scene 01 — THE ARCHIVE

### Duration
約3.0秒

### Visual

最新v0.6 HOMEアート方向を使用。

```text
assets/nox/v0.6/archive_puzzle_window.png
```

猫・窓・月夜・街・資料室。

HOMEそのものを表示するのではなく、UIを除いた「世界」として見せる。

ゆっくりpush-in。

窓や月明かりがわずかに動く程度。

### JP copy

**夜の光学資料室。**

小さく:

`ここでは、光と影が記録される。`

### EN copy

**THE NOCTURNAL OPTICAL ARCHIVE**

Small:

`Here, light and shadow are recorded.`

### Intent

世界へ入る。

まだパズル説明をしない。

---

## Scene 02 — NOX WAS HERE

### Duration
約3.0秒

### Visual

NOXを室内の簡略5×5空間または窓辺に見せる。

一度に全部説明せず、短い3beatでよい。

```text
SIT
STAND
WALK
```

のNOXを、同じ場所の「別の瞬間」として順に見せる。

各瞬間でライトが点灯し、薄い影が伸びる。

最後にNOXの姿だけfade outし、影の痕跡が残る。

### JP copy

**NOXの姿は、もうそこにはない。**

Small:

`けれど、影は記録に残っている。`

### EN copy

**NOX is no longer there.**

Small:

`But the shadows remain in the record.`

### Canon guard

「失踪」「死亡」「帰宅」などの理由を付けない。

---

## Scene 03 — SHADOWS REMEMBER

### Duration
約3.5秒

### Visual

Scene 02の複数瞬間を、紙片/plateが重なるようにまとめる。

SITの影
+
STANDの影
+
WALKの影

が1枚の5×5 `RECORDED SHADOW` に加算される。

同じセルへ重なった箇所は濃くなる。

ここはNOXSUMの核を最も短く伝えるScene。

### JP copy

**いくつかの瞬間が、ひとつの記録に重なる。**

### EN copy

**Several moments can overlap in one record.**

### Important

時間順を示す矢印や「1→2→3」の番号は使わない。

プレイヤーに chronology を推理するゲームだと誤解させない。

---

## Scene 04 — RECONSTRUCT

### Duration
約4.0秒

### Visual

左右に:

```text
RECORDED SHADOW
RECONSTRUCTION
```

左は完成済みの影。

右は空。

下に簡略Placement Board。

NOX poseの候補が現れる。

ひとつのNOXをboardへ置く。

右のRECONSTRUCTIONに影が生まれる。

次のNOXを置く。

影がさらに重なる。

### JP copy

**影から、NOXがいた場所と姿を再構築する。**

### EN copy

**Reconstruct where NOX was, and what NOX was doing.**

### Intent

ここで初めて

```text
影を見る
↓
NOXを置く
↓
影が変わる
```

というゲーム行為を見せる。

---

## Scene 05 — MATCH THE RECORD

### Duration
約3.0秒

### Visual

右側RECONSTRUCTIONが左側RECORDED SHADOWへ一致。

一致したセルを、控えめなbrass/cyan scanで確認する。

ゲーム本編のsolve演出と同じvisual grammarを使う。

### JP copy

**すべての影が合えば、記録はよみがえる。**

### EN copy

**When every shadow matches, the record is restored.**

### Canon guard

「真実が確定する」「過去が完全に分かる」とは書かない。

あくまで「record reconstruction」。

---

## Scene 06 — ENTER TRACE 01

### Duration
約2.5〜3.5秒

### Visual

背景が暗くなり、

```text
NOXSUM
```

wordmark。

その下に:

```text
RECONSTRUCT THE PAST FROM THE SHADOWS
```

または現在の製品subtitle。

そのままGR01の

```text
TRACE 01 / FIRST SHADOW
```

へクロスフェード。

可能ならopening画面を閉じてから新Sceneをloadするのではなく、
同じ光のscanを使って自然につなぐ。

### JP copy

**影をたどって、記録を再構築する。**

### EN copy

**Follow the shadows. Reconstruct the record.**

---

# 8. 紙芝居らしさ

「スライドショー」ではなく「紙芝居」に感じる軽い物質感を入れてよい。

推奨:

- scene transition時に紙/記録plateが数pxだけ滑る
- 古い記録写真のような細いframe
- 端に微かなbrass
- 1sceneにつき動くものは1〜2個
- background panは非常に小さく

禁止:

- 激しいcamera shake
- 大きなparallax
- 3D飛び出し演出
- 連続particle
- 長いtypewriter text
- 映画予告風の高速cut

---

# 9. Art reuse

まず既存アセットだけでprototypeする。

優先:

```text
assets/nox/v0.6/archive_puzzle_window.png
assets/nox/v0.6/app_icon.png
current NOX SIT/STAND/WALK/SLEEP assets
current shadow plate renderer
current socket / lamp visuals
current NOXSUM wordmark
```

新しいNOX毛柄を勝手に作らない。

NOXは

```text
白主体 + 黒 + グレー
```

の固定毛柄ルールを維持。

不足画像がある場合:

1. 既存素材をcomposeして仮実装
2. `docs/OPENING_KAMISHIBAI_ASSET_NEEDS.md` に必要素材を列挙
3. generic iconや別猫で代用しない

---

# 10. Implementation recommendation

Godot内で実装する。

推奨:

```text
scenes/nox_opening_kamishibai.tscn
src/nox_opening_kamishibai.gd
```

構成例:

```text
Control
 ├─ Background
 ├─ SceneLayerA
 ├─ SceneLayerB
 ├─ CaptionPanel
 │   ├─ Title
 │   └─ Body
 ├─ ProgressDots
 ├─ SkipButton
 └─ InputCatch
```

Sceneごとに別Sceneをロードせず、
同一Control内でtimelineを切り替える方が望ましい。

理由:

- Webで軽い
- transitionが自然
- resize対応しやすい
- reduced motion実装が簡単
- first-run state管理が簡単

---

# 11. Timeline architecture

ハードコードした大量awaitの鎖にしない。

Scene定義をdata化する。

例:

```gdscript
var beats = [
    {
        "id": "archive",
        "duration": 3.0,
        "title_key": "opening.archive.title",
        "body_key": "opening.archive.body",
    },
    ...
]
```

各beatは

```text
enter()
animate()
exit()
```

に分ける。

SKIP / next / resize / HOMEへ戻る際にTweenを安全にkillできること。

---

# 12. Input

全Scene:

```text
tap / click / Space / Enter
```

で次へ。

`SKIP` は即GR01または呼び出し元へ遷移。

mobileではSKIP hit target >= 44px。

画面のどこをtapしても進む設計の場合、
SKIPとlanguage controlsのinput priorityを上にする。

double tapで2Scene飛ばないようdebounce。

---

# 13. Language

日本語 / English 完全対応。

既存locale systemへ統合。

新規hard-coded player-facing textを散らさない。

推奨key:

```text
opening.archive.title
opening.archive.body
opening.nox.title
opening.nox.body
opening.record.title
opening.reconstruct.title
opening.match.title
opening.enter.title
opening.skip
opening.replay
```

Stage中の言語設定をそのまま使う。

opening途中のlanguage変更は必須ではないが、
HOMEから選択した言語でopeningが出ること。

---

# 14. Audio

既存NOXSUM sound systemへ統合。

新BGMを追加しない。

Sound OFFなら完全無音。

Sound ONなら、現在のBGMを継続または静かに開始する。

紙芝居専用SFXは最小限:

- lamp ignition
- shadow record
- plate match

既存SFXで表現できる範囲にする。

音のために新しいライセンス依存を増やさない。

---

# 15. Reduced Motion

Reduced Motion ON:

- camera push-inなし
- parallaxなし
- plate slideなし
- shadow tweenは短いcrossfadeまたは即時
- scene transition 100〜150ms程度のfade

文章・Scene順序・情報量は通常版と同じ。

---

# 16. Responsive

必須確認:

```text
360×800
405×900
720×900
```

実WebではDPR問題があったため、

**Godot logical viewportのboundsだけで完了判定しない。**

Web exportをHTTPで配信し、
Chromium mobile viewportの実スクリーンショットを確認する。

Captionが猫の顔や重要な影を隠さないこと。

360pxで:

- text clippingなし
- SKIPが画面内
- left/right cropなし
- NOXSUM wordmark全文が見える

---

# 17. GR01との役割分担

Openingで教える:

```text
世界
影は記録される
複数瞬間が重なる
NOXの場所と姿を再構築する
一致させる
```

GR01 first-play guideで教える:

```text
RECORDED SHADOW と RECONSTRUCTIONを見る
poseを選ぶ
boardへ置く
影を合わせる
```

Openingで以下まで説明しない:

- Tallの2マスreach
- WALKの軸
- SLEEP/shutter
- light selection
- FOG
- Board Shape
- exact 3-direction formula

openingは**意味**を教え、
GR01は**操作**を教える。

---

# 18. Save / progress safety

Openingはpuzzle stateを一切変更しない。

禁止:

- Grant36 progressを進める
- GR01をstarted/cleared扱いにする
- inventory stateを保存する
- Night Log stateを変更する

触るのは原則:

```text
noxsum_settings.cfg -> opening_seen
```

だけ。

---

# 19. Smoke tests

追加:

```text
tools/nox_opening_kamishibai_smoke.gd
```

最低確認:

1. fresh settings + PLAY -> opening
2. complete opening -> GR01
3. SKIP -> GR01
4. opening_seen=true -> PLAY directly enters normal route
5. replay from ABOUT/HOW TO PLAY works
6. replay does not modify progress
7. JP copy exists for every beat
8. EN copy exists for every beat
9. Sound OFF -> no opening audio
10. Reduced Motion -> no large motion
11. 360×800 no clipping
12. 405×900 no clipping
13. 720×900 no regression
14. resize during opening does not break
15. rapid next input does not skip multiple beats
16. exiting opening kills all Tween/callbacks

---

# 20. Visual review captures

必ず以下を撮影。

### 360×800

```text
Scene01 Archive
Scene02 NOX / shadows
Scene03 overlapping record
Scene04 reconstruction
Scene05 match
Scene06 transition to GR01
```

### 720×900

```text
Scene01
Scene03
Scene04
Scene06
```

さらに可能なら、360×800のopeningを短いmp4/gifとしてcaptureする。

---

# 21. Human review questions

madowakuの目視レビューでは以下だけを見る。

```text
□ 最初の5秒でNOXSUMの世界へ入れるか
□ 「影が記録」という発想が伝わるか
□ 複数瞬間が重なることが誤解なく伝わるか
□ 「どこで何をしていたかを再構築」が伝わるか
□ ルール説明臭くないか
□ 長く感じないか
□ GR01へ自然につながるか
□ NOXがかわいく見えるか
```

---

# 22. Definition of Done

以下を満たすまで完了としない。

- 初回PLAY時だけopeningへ入る
- 2回目以降は通常route
- replay可能
- 18〜24秒程度
- 常時SKIP可能
- 世界観が伝わる
- 影を記録していることが伝わる
- 複数瞬間が1枚のrecordへ重なることが伝わる
- プレイヤーがNOXの場所と姿を再構築することが伝わる
- chronologyやNOXの運命を断定しない
- current NOX character lockを維持
- current v0.6 art directionを維持
- JP/EN対応
- Sound OFF / Reduced Motion対応
- puzzle semantics / saveに影響なし
- 360×800 / 405×900 / 720×900確認
- 実Webスクリーンショットでcropなし
- GR01へ自然にtransition
- madowakuの目視承認前にproduction deployしない

---

# 23. Codex実行指示

まず既存HOME / NOX pose / Stage UI / locale / settings / transition実装を調査する。

その後、この仕様を満たす最小構成のopeningをGodotへ実装する。

**新しい世界設定を勝手に増やさない。**

不足アセットがあれば、
`docs/OPENING_KAMISHIBAI_ASSET_NEEDS.md`
へ列挙し、既存素材でprototypeを作る。

最後にスクリーンショットを提示して停止する。

**Netlifyへdeployしない。**
