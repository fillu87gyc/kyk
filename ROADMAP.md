# 3D弾幕ゲーム ロードマップ v4

**紅夜航** — Godot 4 / Steam Deck

> **v4の方針：** v3の全方針を継承した上で、**アセット戦略とMODインジェクション設計**を追加。
> デフォルトはプロシージャル生成（第三者著作物を同梱しない）。
> 後から外部GLB等の人型アセットをMODとして差し込める拡張口を最初から設計に織り込む。

---

## エンジン選定の結論：Godot 4

| 候補 | headless自動テスト | テキスト形式(AI編集性) | LLM学習量 | Steam Deck配布 | 0円 | 総合 |
|------|------------------|---------------------|---------|--------------|-----|------|
| **Godot 4** | ◎ `--headless`+GUT | ◎ `.tscn`/GDScript | ◎ | ◎ Linux/x86_64が素直 | ◎ MIT | **採用** |
| Unity | △ 重い・エディタ前提 | △ シーンがバイナリ寄り | ○ | ○ | △ ライセンス審査 | 見送り |
| Cocos | △ | △ エディタ依存 | △ | △ 2D前提 | ○ | 見送り(3D不向き) |
| Bevy/raylib | ◎ コードファースト | ◎ 全部コード | △ 学習データ薄い | △ 足回り自前 | ◎ | 見送り(自前実装過多) |

---

## 設計上の北極星

このゲームの面白さは弾の数ではなく、**「自機が小さく、弾の隙間を高速で潜れる」**手触りで決まる。

1. **喰らい判定は極小** — 古典的な弾幕STGの「自機より遥かに小さい喰らい判定」を3Dで再現する。
2. **3Dの奥行き問題** — 奥の弾と手前の弾が重なり直感に合わなくなる。独立検証する。
3. **速度はカメラとエフェクトで作る** — FOV変化・残像・近接スロー等の演出の寄与が大きい。

---

## アーキテクチャ規律

### ロジック層（headless VMで自動テスト可能）

SceneTree / MultiMesh / Viewport に一切触らない純粋ロジック：

- 弾の位置計算・速度更新
- 喰らい判定・グレイズ判定（距離計算のみ）
- ボスのステートマシン（HP値→フェーズ遷移）— **Presenterが何かを知らない**
- スコア・パワー・残機の計算
- 弾幕DSLのパース（パターン定義→弾データ配列）

### 描画/手触り層（Steam Deck実機でのみ人間が確認）

- MultiMeshInstance3D への transform 転送
- カメラ・FOV・追従
- パーティクル・残像・速度線などエフェクト
- **BossPresenter（後述）** — ここに差し替えポイントがある

### 決定論（determinism）★最重要

- 乱数シードを固定できる設計（RNG インスタンス管理、`randi()` グローバル禁止）
- 固定タイムステップ（`delta` をロジック関数の引数に切り出す）

---

## アセット戦略

### 方針：デフォルトはプロシージャル生成、MODで人型を差し込む

| | デフォルト | MOD時 |
|-|-----------|-------|
| ボスビジュアル | GDScriptで生成する幾何学的オブジェクト | 人型GLB（利用者が権利を有するモデル） |
| ボスアニメーション | シェーダー・パーティクル・形状変形 | AnimationPlayer（ボーン） |
| 自機ビジュアル | プロシージャルな機体形状 | 外部GLB（利用者が用意） |
| GitHub収録 | ✅ 全部コミット可能 | ❌ gitignore（モデル本体のみ） |
| 第三者著作物 | ✅ 同梱なし | 利用者が各自のライセンスを確認・遵守 |

### なぜ「モデル差し替え」ではなく「Presenter差し替え」か

プロシージャルボスはボーンが存在せず、状態を**シェーダー/形状変化**で表現する。
人型MODは状態を**ボーンアニメーション**で表現する。
構造が根本的に違うため、モデルを差し替えるだけでは成立しない。

```
❌ 単純差し替え（成立しない）
  プロシージャル: state → shader.pulse()
  人型:          state → 同じshaderに人型モデルを貼る → ぎこちない

✅ Presenter差し替え（v4の設計）
  プロシージャル: state → ProceduralPresenter → shader.pulse() + ring_expand()
  人型MOD:       state → HumanoidPresenter   → AnimationPlayer.play("attack")
```

ボスステートマシンはシグナルを投げるだけ。Presenterが何かは知らない。

---

## BossPresenter インターフェース設計

### 構造

```
[BossStateMachine]  ← ロジック層（ステートは純粋データ）
    ↓ signal state_changed(new_state: String)
    ↓ signal hp_changed(ratio: float)
    ↓ signal spell_declared(spell_name: String)
[BossPresenter]     ← インターフェース（抽象基底）
    ↓                        ↓
[ProceduralPresenter]   [HumanoidPresenter]
幾何学ボス（デフォルト）   人型MOD（差し込み）
ボーンなし                AnimationPlayer
GDScriptで完結            presenter.gdをMOD同梱
```

### インターフェース定義（`boss_presenter.gd`）

```gdscript
# boss_presenter.gd — MODが実装すべきインターフェース
class_name BossPresenter
extends Node3D

## ステートマシンから呼ばれる。Presenterはここで見た目を更新する。
func on_state_changed(_new_state: String) -> void:
    pass

## HP割合(0.0〜1.0)が変化したとき呼ばれる。
func on_hp_changed(_ratio: float) -> void:
    pass

## スペル宣言時に呼ばれる。
func on_spell_declared(_spell_name: String) -> void:
    pass

## 毎フレーム呼ばれる（演出用）。ロジックは持たない。
func tick(_delta: float) -> void:
    pass

## このPresenterが有効か（MODロード失敗時はfalseを返す）
func is_valid() -> bool:
    return true
```

### MODのファイル構成

```
res://
├── mods/
│   ├── README.md                ← MODの作り方・注意事項（コミット）
│   └── custom_boss/
│       ├── mod.json             ← メタデータ（gitコミット可）
│       ├── model.glb            ← モデル本体（gitignore）
│       ├── animations/
│       │   ├── idle.anim        ← gitignore
│       │   ├── attack.anim
│       │   └── spell_card.anim
│       └── presenter.gd         ← HumanoidPresenterの実装（gitignore）
├── core/
│   ├── boss_presenter.gd        ← インターフェース定義（コミット）
│   ├── procedural_presenter.gd  ← デフォルト実装（コミット）
│   └── mod_loader.gd            ← mods/スキャン＋フォールバック（コミット）
└── sdk/
    └── sample_presenter.gd      ← MIT公開のサンプルPresenter実装（コミット）
```

> `sdk/sample_presenter.gd` をMITライセンスで同梱することで、MODを自作したい人がゼロから書かずに済む。

### `mod.json` の構造

```json
{
  "name": "custom_boss",
  "target": "boss",
  "presenter": "presenter.gd",
  "model": "model.glb",
  "state_map": {
    "IDLE":     "idle",
    "ATTACK":   "attack",
    "SPELL":    "spell",
    "DEFEATED": "defeat"
  },
  "hit_radius_override": 0.8
}
```

`state_map` でステートマシンの状態名→アニメーション名を吸収。
ボーン構造の差異は `presenter.gd` 内部で処理し、インターフェースを汚染しない。

### MODローダーの動作

```gdscript
# mod_loader.gd（起動時に一度だけ実行）
func load_boss_presenter() -> BossPresenter:
    var mod_path = "res://mods/"
    for dir in DirAccess.get_directories_at(mod_path):
        var meta_path = mod_path + dir + "/mod.json"
        if FileAccess.file_exists(meta_path):
            var meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
            if meta.get("target") == "boss":
                var presenter = load(mod_path + dir + "/" + meta["presenter"]).new()
                if presenter.is_valid():
                    print("MOD loaded: ", meta["name"])
                    return presenter
    # フォールバック：プロシージャル生成
    print("No MOD found. Using procedural presenter.")
    return ProceduralPresenter.new()
```

### `.gitignore` の設計

```gitignore
# MODアセット本体（ローカルのみ・版権管理は利用者責任）
mods/*/model.glb
mods/*/model.fbx
mods/*/animations/
mods/*/presenter.gd
mods/*/textures/

# MODメタデータはコミットOK（構造のドキュメントになる）
!mods/*/mod.json
!mods/README.md
```

### セキュリティ注記

`presenter.gd` はGDScriptなので**MODが任意コードを実行できる**。
個人利用（自分だけが使う）なら問題なし。将来的に他者に配布する場合はsandbox設計が必要。
**信頼できない出所のMODは実行しないこと。**

---

## テスト戦略

### Layer A — クラウドVM自動テスト（人間不要）

`godot --headless` + GUT。Claudeが自分でテストを書き・回し・直す。
ロジック層の正しさをすべてここで担保。BossPresenterのインターフェース適合テストもここ。

### Layer B — Steam Deck実機（人間の主観確認専用）

描画の見た目・弾を抜ける手触り・入力遅延・フレームレート・熱・バッテリー。
各フェーズ完了時に1回。MOD差し込み時のビジュアル確認もここ。

---

## Phase 0 — 環境構築（2〜3日）

**目標：** Hello World が Steam Deck で動き、クラウドVMでテストが自動で回ること。

- Godot 4 インストール・プロジェクト作成
- GUT インストール・サンプルテスト1本通す
- クラウドVMで `godot --headless` によるGUT実行を確立（CIで自動green/red）
- CLIエクスポート＋`deploy.sh` をheadlessで完結（GUI操作ゼロ）
- 乱数シード固定・固定タイムステップの土台コードを先に置く
- `boss_presenter.gd`（インターフェース）と `mod_loader.gd`（骨格のみ）を先に置く
- `mods/` の `.gitignore` を設定し、MOD用ディレクトリ構造を確定する
- Steam Deck で Linux ビルドが起動することを確認

**完了基準：**

1. クラウドVMで `godot --headless` 一発でGUTが回り、green/redで返る
2. `./deploy.sh` 一発で Steam Deck に画面が出る（GUI操作なし）
3. `mods/` にMODを置いたとき・置かなかったときの両方でゲームが起動する

> ⚠️ GUI前提の手作業が残ると全フェーズでvibe codingが途切れる。人間の手作業ゼロを必ず達成すること。

---

## Phase 1 — 自機・カメラ（1週間）

**目標：** 3Dフライトシューティングらしい操作感で飛べること。スピード感の土台。

- 自機の6DoF移動（スティック＋ブースト）— 移動ベクトル計算はロジック層
- 自機追従カメラ（SpringArm3D でオフセット追従）
- 慣性・減速の調整
- Steam Deck コントローラー入力マッピング
- 速度演出の土台：ブースト時のFOV拡大、カメラ引き
- 自機もPresenterパターンで設計（後からMODで機体を差し替えられるように同じ構造を適用）

**テスト：**
- Layer A: 入力ベクトル→速度変換、慣性・減速の数値遷移をGUTで決定論テスト
- Layer B: 操作感・入力遅延・速度感の主観確認

**完了基準：** ロジックがLayer A green。Steam Deckで自機が気持ちよく動き、ブーストで「速い」と感じる。

---

## Phase 1.5 — 抜ける感覚の検証【最重要】（1週間）

**目標：** 弾数種類だけで「隙間を潜る快感」が成立すること。物量はまだ作らない。

- 喰らい判定の3D設計：極小球。判定計算はロジック層（距離計算のみ）、サイズ変数化
- 喰らい判定の可視化デバッグ（半透明表示トグル）— 描画層
- 奥行き問題の検証：弾を数十発、自機の高さ平面に並べて高速で抜ける
- グレイズ検出（喰らい判定の少し外側の球）— ロジック層
- 被弾/グレイズ時のヒットストップ・軽いスロー

**テスト：**
- Layer A: 判定・グレイズ境界値テスト（決定論で網羅）
- Layer B: 毎日、弾の隙間を抜ける主観テスト

**完了基準：** 判定がLayer A green。数十発の中を抜けると気持ちよく、判定が直感に合っている。

> ⚠️ ここが甘いまま次に進まないこと。このゲームの成否の8割はここで決まる。

---

## Phase 2 — 弾幕エンジン（2週間）

**目標：** 数万発をフレーム落ちなしに撒けること。

- `MultiMeshInstance3D` による弾幕レンダリング（描画層）
- 弾の移動・判定はGDScriptのforループで回さない（配列更新 → 必要なら RenderingServer直叩き）
- GDScriptで限界が来たら弾更新だけGDExtension(C++)へ（計測→移行、0円維持）
- 弾幕DSL（パーサーは純粋関数＝ロジック層）

  ```
  ring(count=16, radius=80, color=PINK, speed=120)
  spiral(arms=3, density=24, color=CYAN)
  ```

- 奥カリング・ブロードフェーズ判定（空間分割/距離ソート）

**テスト：**
- Layer A: DSLパーサーテスト、3万発5秒シミュレートの決定論テスト
- Layer B: 弾数別フレームレート計測（1万・3万・5万発）

**完了基準：** ロジックがLayer A green。Steam Deckで3万発/60fps、Phase 1.5の手触りが保たれている。

---

## Phase 3 — ボス（2週間）

**目標：** プロシージャルボスと戦えること。MODで人型に差し替えられる拡張口が完成すること。

- ボスステートマシン（待機→攻撃→スペル宣言→撃破）— **純粋ロジック。Presenterを知らない**
- フェーズ管理（HPしきい値でフェーズ移行）— ロジック層
- ProceduralPresenter の実装：
  - 幾何学的ボス形状（リング・球・放射状結晶などをGDScriptで生成）
  - 状態→シェーダー変化・形状変形・パーティクルで表現
  - スペル宣言時の形状展開演出
- HumanoidPresenter の骨格実装：
  - `mod.json` の `state_map` を読み、AnimationPlayerに橋渡し
  - GLBロード・BoneMap適用
  - MODなし時はProceduralPresenterにフォールバック
- MODローダーの完成：`mods/` スキャン→Presenter選択→フォールバック
- ボスHPバー・スペル名 HUD
- 弾幕の「抜けどころ」設計

**テスト：**
- Layer A: ステートマシン遷移テスト。BossPresenterインターフェース適合テスト（ProceduralとHumanoid両方）。MODあり/なし両方でmod_loaderが正しくフォールバックするかテスト
- Layer B: ProceduralPresenterで通しプレイ。「抜けどころ」確認。MODを差し込んだときの見た目確認

**完了基準：** ロジックがLayer A green。プロシージャルボスを倒せる。`mods/custom_boss/` を置いたときに人型に差し替わる（アニメーションは仮でOK）。

---

## Phase 4 — ステージ・世界観・速度演出（1週間）

**目標：** 本作の世界観の空気＋スピード感の総仕上げ。

- ステージ背景（シルエット＋月＋建造物の光）— プロシージャル生成
- 3Dグリッド床面（透視パース）— 速度感を強調する流れる背景
- 速度演出の完成：残像・モーションブラー・速度線・近接スローの最終調整
- BGM・SE 組み込み（オリジナル楽曲 or ライセンスフリー素材）
- パーティクルエフェクト（ヒット・撃破・スペル発動・グレイズ）

**テスト：**
- Layer B: ビジュアル・音・速度感の主観確認。背景込みのパフォーマンス確認

**完了基準：** 雰囲気が出て、弾幕を抜ける瞬間が映像的に気持ちいい。フレームレートが落ちていない。

---

## Phase 5 — ゲームループ・仕上げ（1週間）

**目標：** 最初から最後まで遊べること。

- タイトル画面・ゲームオーバー・クリア画面
- スコア・グレイズ・パワーの計算と表示（計算はロジック層）
- 残機・ボムシステム
- 難易度選択（Easy / Normal / Hard / Lunatic）
- セーブ（ハイスコア）

**テスト：**
- Layer A: スコア計算・ハイスコア保存・ロードのユニットテスト
- Layer B: 難易度別通しプレイ。最終通しプレイ（熱・バッテリー・操作感の総合確認）

**完了基準：** ロジックがLayer A green。Steam Deckで最初から最後まで一人で遊べる。

---

## スケジュール概算

| Phase | 内容 | 期間 |
|-------|------|------|
| 0 | 環境構築＋自動テスト確立＋MOD基盤骨格 | 2〜3日 |
| 1 | 自機・カメラ・速度の土台（Presenterパターン適用） | 1週間 |
| 1.5 | 抜ける感覚の検証【最重要】 | 1週間 |
| 2 | 弾幕エンジン | 2週間 |
| 3 | ボス＋Presenter実装＋MODローダー完成 | 2週間 |
| 4 | ステージ・世界観・速度演出 | 1週間 |
| 5 | ゲームループ・仕上げ | 1週間 |
| **合計** | | **約8〜9週間** |

---

## v3からの主な変更点（v4）

1. **アセット戦略を明文化** — デフォルトはプロシージャル生成（第三者著作物を同梱しない）、MODで外部GLBを後から差し込む方針を確定
2. **BossPresenterインターフェースを設計** — ステートマシン（ロジック）とビジュアル表現を完全分離
3. **「モデル差し替え」ではなく「Presenter差し替え」** — プロシージャル（ボーンなし・シェーダー）と人型（ボーンあり・AnimationPlayer）は構造が根本的に違うため、表現ロジックごと差し替える設計に
4. **MODのファイル構成・mod.json・gitignore設計を確定** — `state_map` でステート名→アニメーション名を吸収
5. **Phase 0にインターフェース骨格とMODディレクトリ設計を追加** — 全Phaseがこの構造に乗るため最初に置く
6. **自機にも同じPresenterパターンを適用**（Phase 1）— 一貫した拡張設計
