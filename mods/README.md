# MOD作成ガイド

このディレクトリにMODを配置することで、ボスや自機のビジュアルを外部アセットに差し替えられます。

## ディレクトリ構成

```
mods/
└── your_mod_name/
    ├── mod.json        # メタデータ（必須）
    ├── model.glb       # 3Dモデル本体（gitignore対象）
    ├── animations/     # アニメーションファイル（gitignore対象）
    │   ├── idle.anim
    │   ├── attack.anim
    │   └── spell_card.anim
    ├── presenter.gd    # Presenter実装（gitignore対象）
    └── textures/       # テクスチャ（gitignore対象）
```

## `mod.json` の書き方

```json
{
  "name": "your_mod_name",
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

### フィールド説明

| フィールド | 説明 |
|-----------|------|
| `name` | MODの識別名（ディレクトリ名と一致させること） |
| `target` | `"boss"` または `"player"` |
| `presenter` | Presenterスクリプトのパス（mod.jsonからの相対パス） |
| `model` | GLBモデルのパス（mod.jsonからの相対パス） |
| `state_map` | ステートマシンの状態名→アニメーション名のマッピング |
| `hit_radius_override` | 喰らい判定の半径上書き（省略可・省略時はデフォルト値を使用） |

### `state_map` のキー一覧（ボス）

| キー | 説明 |
|-----|------|
| `IDLE` | 待機状態 |
| `ATTACK` | 通常攻撃 |
| `SPELL` | スペル宣言・発動 |
| `DEFEATED` | 撃破 |

## `presenter.gd` の実装

サンプル実装は `res://sdk/sample_presenter.gd` を参照してください（MIT License）。

```gdscript
# presenter.gd — BossPresenter を継承して実装する
extends "res://core/boss_presenter.gd"

@export var model_path: String = ""
var anim_player: AnimationPlayer
var state_map: Dictionary = {}

func _ready() -> void:
    # model.glb をロードしてシーンに追加
    # AnimationPlayer を取得
    pass

func on_state_changed(new_state: String) -> void:
    var anim_name = state_map.get(new_state, "idle")
    if anim_player:
        anim_player.play(anim_name)

func on_hp_changed(ratio: float) -> void:
    # HP割合に応じた演出（省略可）
    pass

func on_spell_declared(spell_name: String) -> void:
    # スペル宣言時の演出
    pass

func tick(delta: float) -> void:
    # 毎フレームの演出更新（省略可）
    pass

func is_valid() -> bool:
    return anim_player != null
```

## gitignore について

`mod.json` はコミット可能ですが、モデル・アニメーション・テクスチャ・`presenter.gd` はgitignore対象です。
これらのファイルは各自のローカル環境にのみ存在します。

**外部アセットのライセンスは利用者自身が確認・遵守してください。**

## セキュリティ注記

`presenter.gd` はGDScriptのため、MODが任意コードを実行できます。
**信頼できない出所のMODは絶対に実行しないでください。**
個人利用（自分が用意したアセットのみ使用）であれば問題ありません。
