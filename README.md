# 紅夜航 (Kouya-Kou)

3D弾幕シューティングゲーム — Godot 4 / Steam Deck

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
| 自動テスト | GUT + `godot --headless` |
| ターゲット | Steam Deck（Linux / x86_64） |
| ライセンス | MIT |

## アーキテクチャ

### ロジック層（headless VMで自動テスト可能）

- 弾の位置計算・速度更新
- 喰らい判定・グレイズ判定
- ボスステートマシン
- スコア・パワー・残機の計算
- 弾幕DSLのパース

### 描画/手触り層（Steam Deck実機で確認）

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

## セットアップ

```bash
# Godot 4 のインストール（headless版）
# https://godotengine.org/download/linux/

# GUT のインストール
# Godot Asset Library から "Gut" を検索してインストール

# テスト実行
godot --headless --script addons/gut/gut_cmdln.gd

# Steam Deck 向けエクスポート
./deploy.sh
```

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
