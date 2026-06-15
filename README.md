# 紅夜航 (Kouya-Kou)

3D弾幕シューティングゲーム — Godot 4 / Steam Deck

[![Build & Release](https://github.com/fillu87gyc/kyk/actions/workflows/build.yml/badge.svg)](https://github.com/fillu87gyc/kyk/actions/workflows/build.yml)

## Steam Deck でプレイする

デスクトップモードの Konsole で以下を実行するだけ：

```bash
mkdir -p ~/games/kouya-kou && cd ~/games/kouya-kou
curl -L https://github.com/fillu87gyc/kyk/releases/latest/download/kouya-kou-linux-x86_64.tar.gz | tar xz
./kouya-kou.x86_64
```

### ゲームモードに登録する（任意）

1. デスクトップモードで Steam を開く
2. **「ゲームを追加」→「非Steamゲームを追加」**
3. `~/games/kouya-kou/kouya-kou.x86_64` を選択

---

## コンセプト

「自機が小さく、弾の隙間を高速で潜れる」手触りを3Dで実現する弾幕STG。

- **喰らい判定は極小** — 古典的な弾幕STGの自機より遥かに小さい判定を3Dで再現
- **3Dの奥行き問題を解決** — 奥の弾と手前の弾が重なっても直感に合う設計
- **速度感はカメラとエフェクトで作る** — FOV変化・残像・近接スローで体感速度を演出

## 技術スタック

| 項目 | 採用 |
|------|------|
| エンジン | Godot 4 |
| 言語 | GDScript（必要に応じてGDExtension/C++） |
| 弾幕レンダリング | MultiMeshInstance3D → RenderingServer |
| 自動テスト | GUT + `godot --headless`（単体64＋E2E11＝計75本／[TESTING.md](TESTING.md)）|
| CI | GitHub Actions（テスト緑をゲートに自動ビルド＆Releases 配布） |
| ターゲット | Steam Deck（Linux / x86_64） |
| ライセンス | MIT |

## CI / リリースフロー

バージョンアップは **自動テストの通過がゲート**。テストが赤ならビルドもリリースもされない。

```
git tag v0.1.0 && git push origin v0.1.0   （または main への push / PR）
        │
        ▼
GitHub Actions (.github/workflows/build.yml)
  job: test          GUT headless で全テスト（75本）  ← 赤なら即停止
        │ needs: test（かつ PR 以外）
        ▼
  job: export-linux  Linux x86_64 をエクスポート → Releases にアップロード
        │
        ▼
Steam Deck: curl でダウンロード → 即プレイ
```

PR でも `test` ジョブが走るため、マージ前に赤に気づける。
`workflow_dispatch` で Actions タブから手動実行も可能。

テストの中身・CUJ・カバレッジ集計は [TESTING.md](TESTING.md) を参照。

## 開発者セットアップ

```bash
# 1. Godot 4 のインストール
#    https://godotengine.org/download/linux/

# 2. GUT のインストール（テスト用）
#    Godot Asset Library → "GUT" を検索してインストール

# 3. headless テスト実行
godot --headless --script addons/gut/gut_cmdln.gd \
  -gconfig=res://tests/gut_config.json

# 4. ローカルでエクスポート＆転送
./deploy.sh                          # エクスポートのみ
DECK_HOST=192.168.1.XX ./deploy.sh   # Steam Deck に SCP 転送
DECK_HOST=192.168.1.XX DECK_RUN=1 ./deploy.sh  # 転送＋実機起動
```

## アーキテクチャ

### ロジック層（headless VMで自動テスト可能）

`core/` 以下。SceneTree に一切依存しない純粋ロジック：

- `player_logic.gd` — 移動速度・境界・当たり/グレイズ判定
- `bullet_logic.gd` — 弾の step・ring/aimed スポーン（seed 固定・決定論）
- `boss_presenter.gd` — BossPresenter インターフェース定義
- `procedural_presenter.gd` — デフォルト幾何学ボス
- `mod_loader.gd` — mods/ スキャン → Presenter 選択 → フォールバック

### 描画/手触り層（Steam Deck実機で確認）

`scripts/` 以下。シーンツリーに接続するノードスクリプト：

- MultiMeshInstance3D への transform 転送
- カメラ・FOV・追従
- パーティクル・残像・速度線などエフェクト
- BossPresenter（MOD差し替えポイント）

### 決定論（determinism）

- 乱数シードを固定できる設計（RNGインスタンス管理、`randi()` グローバル禁止）
- 固定タイムステップ（`delta` をロジック関数の引数に切り出す）

## MODシステム

デフォルトはプロシージャル生成（第三者著作物を同梱しない）。
後から外部GLBなどの人型アセットをMODとして差し込める設計。

```
res://mods/custom_boss/
├── mod.json        # メタデータ（gitコミット可）
├── model.glb       # モデル本体（gitignore）
├── animations/     # アニメーション（gitignore）
└── presenter.gd    # HumanoidPresenter実装（gitignore）
```

MODの作り方は [mods/README.md](mods/README.md) を参照。
サンプル実装は [sdk/sample_presenter.gd](sdk/sample_presenter.gd) を参照（MIT）。

## 開発ロードマップ

詳細は [ROADMAP.md](ROADMAP.md) を参照。

| Phase | 内容 | 期間 |
|-------|------|------|
| 0 | 環境構築・自動テスト確立・MOD基盤骨格 | 2〜3日 |
| 1 | 自機・カメラ・速度の土台 | 1週間 |
| 1.5 | 抜ける感覚の検証【最重要】 | 1週間 |
| 2 | 弾幕エンジン | 2週間 |
| 3 | ボス・Presenter実装・MODローダー完成 | 2週間 |
| 4 | ステージ・世界観・速度演出 | 1週間 |
| 5 | ゲームループ・仕上げ | 1週間 |
| **合計** | | **約8〜9週間** |

## ライセンス

本プロジェクトのソースコード（GDScript・シェーダー・設定ファイル等）は [MIT License](LICENSE) で公開。

本リポジトリには第三者の3Dモデル・モーション・テクスチャ・音源等は含まれない。
MODとして利用される外部アセットのライセンス確認および遵守は利用者の責任とする。
