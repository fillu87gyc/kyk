# E2E: タイトル → ゲーム → ゲームオーバーの画面遷移（scenes/main.tscn）
#
# main.gd がタイトル画面・ゲーム本体・ゲームオーバー表示を正しく束ねるかを検証する。
#
# カバーする E2E シナリオ:
#   E2E-9   起動時はタイトル表示             … CUJ-1
#   E2E-10  スタートでゲームへ遷移           … CUJ-2
#   E2E-11  ゲームオーバーでタイトルへ復帰   … CUJ-7
#
# ノードは独自スクリプトのメンバーへ動的アクセスするため、型注釈を付けず Variant で扱う。
extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"

var _main

func before_each() -> void:
	_main = load(MAIN_SCENE).instantiate()
	add_child_autofree(_main)
	await wait_frames(2)

func _title():
	return _main.get_node("TitleScreen")

func _game_root():
	return _main.get_node("GameRoot")

# E2E-9 ----------------------------------------------------------------
func test_boots_to_title() -> void:
	assert_true(_title().visible, "起動時はタイトルが表示される")
	assert_false(_game_root().visible, "起動時はゲーム本体は非表示")

# E2E-10 ---------------------------------------------------------------
func test_start_transitions_to_game() -> void:
	_main._start_game()
	assert_false(_title().visible, "スタートでタイトルが消える")
	assert_true(_game_root().visible, "スタートでゲーム本体が表示される")

# E2E-11 ---------------------------------------------------------------
func test_game_over_returns_to_title() -> void:
	_main._start_game()
	_main._on_game_over(4321)
	assert_true(_title().visible, "ゲームオーバーでタイトルへ戻る")
	var go_label = _main.get_node("TitleScreen/GameOverLabel")
	var score_label = _main.get_node("TitleScreen/FinalScoreLabel")
	assert_eq(go_label.text, "GAME OVER", "ゲームオーバー表示が出る")
	assert_string_contains(score_label.text, "4321", "最終スコアが表示される")
