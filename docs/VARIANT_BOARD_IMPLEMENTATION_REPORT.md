# Variant Board v0.1 実装完了報告

2026-09-23 / Godot 4.7 stable / Windows

## 実装結果と起動方法

元の三方向LIGHT・隣接セルSHADOWルールのまま、ステージJSONの `boardShape` だけでPOST配置可能ソケットを変更できるようにした。専用Shadow EngineやShape別Sceneは追加していない。

```powershell
& 'C:\Users\hiro\tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . -- --campaign variants
```

`--dev-selector` → **VAR01–VAR06 VARIANT BOARDS** からも起動可能。既存の標準起動キャンペーンは維持。Variantは `scenes/main.tscn` と既存の `comfort_main.gd` 継承系列をそのまま使用する。

依頼仕様の原本は repo直下の `VARIANT_BOARD_IMPLEMENTATION_TASK.md` に保存。

## 1. 変更ファイル一覧

| ファイル | 内容 |
|---|---|
| `VARIANT_BOARD_IMPLEMENTATION_TASK.md` | 添付仕様をそのまま保存 |
| `README.md` | 起動方法と本報告書へのリンク |
| `docs/VARIANT_BOARD_IMPLEMENTATION_REPORT.md` | 調査・実装・検証・制約の記録 |
| `data/variant_boards_v0_1.json` | 指定6問のmask・TARGET・解 |
| `src/board_shape.gd` / `.uid` | 検証・実行時mask・復元フィルター |
| `src/main.gd` | 読込元設定、maskの先行適用、共通配置判定、ソケット有効性 |
| `src/feel_main.gd` | 範囲外・無効セルを演出前に除外 |
| `src/interaction_main.gd` | ドラッグ候補・プレビュー・無効dropの復帰 |
| `src/magnetic_main.gd` | 無効セル上の吸着禁止とプレビュー解除 |
| `src/glass_metal_main.gd` | 無効ソケット非表示とhover抑止 |
| `src/comfort_main.gd` | 無反応入力、Undo、セッション復元のmask検証 |
| `src/hint_main.gd` | 無反応入力と既存キャンペーン専用ヒントの分離 |
| `src/unknown_main.gd` | 無反応入力と既存Stage004導入の分離 |
| `src/progress_main.gd` | 既存Tier演出の分離と実際の問題数の完了表示 |
| `src/campaign_main.gd` | 既存セレクターへのVariant導線 |
| `src/ui/product_ui.gd` | 無効セルのfocus/tooltip抑止、矢印移動で穴をスキップ |
| `src/ui/localization.gd` | 6形状とVariant区分の日本語名称 |
| `tools/board_shape.py` | オフライン検証の配置候補とmask検証 |
| `tools/validate_stages.py` | 総当たり候補を有効ソケットだけに制限 |
| `tools/analyze_stages.py` | 推論ソルバーの配置領域制約 |
| `tools/validate_variant_boards.py` | 6問の一意性・期待解の検証 |
| `tools/test_variant_boards.py` | 7件のPython単体テスト |
| `tools/variant_board_smoke.gd` / `.uid` | 実入力・保存・クリア・描画・レイアウト検証 |
| `tools/grant_experiment_smoke.gd` | 現行のクリア即時保存・REPLAYに古い期待値を合わせた |
| `tools/shadow_ink_smoke.gd` | Tween開始前のセットアップフレームを時間計測から除外 |

## 2. StageDataの変更と既存構造

このrepoには独立したStageData Resourceクラスはなく、`main.gd::_load_stages()` がJSON配列をDictionary群として読み込む。既存の `id` / `title` / `tier` / `posts` / `clues` / `solution` を維持し、任意フィールド `boardShape` を追加した。座標は既存の `A1`〜`E5` 表記へ変換している。

```json
"boardShape": {
  "type": "mask",
  "width": 5,
  "height": 5,
  "mask": ["00100", "00100", "11111", "00100", "00100"]
}
```

`1` は配置可能、`0` はソケットを加工していないプレート。未指定なら25ソケット。既存ステージJSONは変更不要。

Socketは個別Sceneではなく、GridContainer内のButtonと、その子の `SocketVisual` / `PostVisual`。無効Buttonもレイアウト上は残し、ソケット・POSTを描画せず、入力とfocusを無効化する。TARGET/LIVEはmaskの対象外。

別系統の `experiment_main.gd` はTall/Plate/Shutter等を含む既存実験用。今回の基本ルール6問は元の盤面系列に統合し、この実験エンジンは変更していない。

## 3. shapeMaskの実装場所

`src/board_shape.gd` はステージ読込時にmaskを25bit整数へ変換し、`is_socket_enabled(row, column)` を境界検査とbit照会で実行する。フレームごとの文字列解析はない。

`type`・5×5寸法・5行・各5文字・0/1のみ・1個以上・POST数以下でないことを検証。不正ならステージID付きwarningと全文字1の盤面へfallback。`validation_error()` から診断文字列も取得できる。

`main.gd::_load_stage()` でmaskを先に適用し、空のPOST状態を作り、既存UI更新へ進む。保存復元では復元対象ステージのmaskで座標を検証してから、ステージ読込とPOST適用を行う。

## 4. placement制限の実装場所

- クリック、タップ、Space/Enter、直接の `_toggle_post()` 呼び出しは共通のmask照会で拒否する。
- 無効セルはmouse無視、focusなし、tooltipなし、hoverなし。拒否音や禁止マークは出さない。
- `_is_valid_drag_target()` が有効ソケットと占有を確認する。
- 無効セルに入ると直前の有効プレビューと吸着表示を解除。dropは既存キャンセル経路で元の座標へ戻る。
- 無効セル上から隣の有効ソケットへの磁気吸着も禁止する。
- Undoと保存復元も現在のmaskでフィルターする。

保存先は `user://shadow_sum_variants_v0_1.json` と、その `.session.json`。maskは保存しない。ステージのmaskだけが更新された場合は有効な保存POSTを残し、無効座標をwarning付きで除去する。既存保存形式と通常盤面のfingerprintは維持する。

## 5. Solver変更内容

総当たり検証は `Combination(enabled_cells, posts)` を列挙する。期待解が無効セルを含む場合も検出する。推論ソルバーでは有効領域に制約を絞り、無効座標を空として確定する。

`src/shadow_rules.gd` と `src/experiment_optics.gd` は変更していない。Pythonの `shadow_for()` も変更なし。開始時と終了時のSHA-256は一致：

- `shadow_rules.gd`: `9608C32C207D9662EF0930CCC092083D3F363FA42F3E5B1E66006A792D3195CE`
- `experiment_optics.gd`: `0235D9355C1C85B86D365EC30860C624B0C2A3A8D420A3152018A3B19D089EDF`

## 6. 追加Stage一覧

既存保存・進行の数値ID規則に合わせ、専用データセット内で1〜6を使用。

| 呼称 | 形状 | ソケット数 | POST数 | 唯一の解 |
|---|---|---:|---:|---|
| VAR-01 | CROSS | 9 | 3 | C1, B3, C5 |
| VAR-02 | NARROW | 15 | 4 | E2, A3, C3, D4 |
| VAR-03 | STAIR | 13 | 4 | A2, C2, D3, C4 |
| VAR-04 | CORNER | 16 | 4 | A2, C4, D4, A5 |
| VAR-05 | HOLLOW | 16 | 4 | A1, C1, E1, B5 |
| VAR-06 | BRIDGE | 19 | 4 | D2, C4, E4, B5 |

TARGET・mask・解は依頼仕様のまま。CROSSの実動作確認後に残り5問を追加した。

## 7. 追加テスト

Python 7件：未指定のFull Board、全形状/一意解/推論、HOLLOW内部の影、不正mask、無効セルの期待解、maskが一意性を生むこと、Shape名からの独立。

Godot：既定25/CROSS9、境界、不正maskとfallback、過剰POST数、影の同値性、描画有効性、無反応hover、マウス・タッチ・キーボード入力、ドラッグプレビューと復帰、有効drop、Undo/Reset、無効座標復元、実際の再起動、全6問のクリアと保存、HOLLOW内部への影表示、NORMALへの切替、2サイズの配置・境界・重なり、8枚の画面キャプチャ。

## 8. テスト結果

- Python単体テスト：既存15件＋新規7件＝22件 PASS。
- 6問の総当たり：各1解、期待座標集合と一致。
- 既存Stage/Grant18/G01–G10/Cause & Light/Light & Height/Flat Plate/Grant14/Grant20/Grant36の全Python validator：PASS。
- Grant36：11,506,900通り、16/16問 PASS。
- Variant Godot：headless 1,449チェック、実描画1,457チェック、失敗0。
- Godotスモーク：既存22本＋新規1本、全23/23本PASS。Grant18は3サイズ、全18問とヒント操作もPASS。
- 既存18問：405×900 / 676×900 / 720×900の3サイズで、NEXTによる連続クリアとヒントを検証し失敗0。
- Godot静的検証：57リソース（52 GDScript、4シーン）をすべて読込み/生成。parse/runtime error 0。警告32件はすべてHEADに存在する既存コードの同一行由来。今回追加した行/ファイルの警告は0件。
- 復元テストで出る「Ignored restored Post」は不正座標を意図的に与えた期待どおりのwarning。

再実行例：

```powershell
python -m unittest discover -s tools -p 'test_*.py' -v
python tools/validate_variant_boards.py
python tools/validate_stages.py
# godotをPATHに登録している場合
 godot --headless --path . --script res://tools/variant_board_smoke.gd
```

既存回帰の補足：テスト間で保存先を共有した最初のFlow検証はクリア記録に影響されたため、新規プロファイルで再実行しPASS。空POSTの可視フラグ上書きは既存Glass & Metalテストで検出し修正済み。Grant18テストは全ヒント待機を含むため180秒の上限で実行した。

## 9. 手動・Visual QA結果

GodotのOpenGL実描画を画像で目視確認。405×900 / 720×900のNORMAL・CROSS・HOLLOW・BRIDGEで、枠と間隔の維持、無効セルに穴の残骸がないこと、配置とPOSTの整列、TARGET/LIVEの5×5維持を確認した。HOLLOWではC1のPOSTが、配置できないC2の影スクリーンへ影を落とすことも確認した。

入力はGodotのViewportにマウス・タッチ・キーイベントを送って検証した。物理スマートフォンでの手動操作、Webエクスポート、体感難度の人間によるプレイテストは未実施。

キャプチャ保存先：`C:/Users/hiro/shadow-sum-variant-qa/`。`cross_405.png` / `cross_720.png` / `hollow_405.png` / `hollow_720.png` / `bridge_405.png` / `bridge_720.png` / `normal_405.png` / `normal_720.png`。

## 10. 既知の制約・改善案

- Variant専用の段階ヒント文は今回の仕様に含まれないため未作成。既存18問の無関係なヒントは表示しない。
- 既存静的警告32件は、今回の最小変更方針に合わせて残している。
- 追加ギミック、壁、盤面回転、動的ソケット、盤面サイズ変更は実装していない。

面白さを増やす次の案（今回は未実装）：

1. **同じTARGET、違うプレート**：形状だけで解が変わる2問を連続させ、盤面の余白が手掛かりになる体験を作る。
2. **穴がない場所の影を読む**：HOLLOWの内側に少数の観測値を置き、「置けない」と「影がない」の違いを主役にする。
3. **同じ形状で手掛かりを減らす**：ソルバーで一意性を維持できる範囲まで観測を減らし、導入・応用・挑戦の3段階にする。

## 最終確認欄

`git diff --stat`：17 tracked files changed, 142 insertions(+), 23 deletions(-)。さらに未追跡の今回新規ファイル10件、計2,045行（内訳：仕様1,137、JSON 367、報告165、実装・テスト376行）。この数値には今回変更前からのtracked差分を含む。

- Godot回帰：23/23 PASS。保存先はテストごとに分離。
- `git diff --check`：PASS。
- `git status --short`：変更内容を確認済み。既存のgenerated未追跡ファイルは保持。
- この作業ではcommit / push / mergeを実行していない。
