# E2E: タイトル → ゲーム → ゲームオーバーの画面遷移（scenes/main.tscn）
#
# main.gd がタイトル画面・ゲーム本体・ゲームオーバー表示を正しく束ねるかを検証する。
#
# カバーする E2E シナリオ:
#   E2E-9   起動時はタイトル表示             … CUJ-1
#   E2E-10  スタートでゲームへ遷移           … CUJ-2
#   E2E-11  ゲームオーバーでタイトルへ復帰   … CUJ-7
#   E2E-23  ステージクリアでタイトルへ復帰   … CUJ-11
#   E2E-24  難易度選択がゲーム開始に反映される … CUJ-13
#   E2E-27  新記録をハイスコアとして保存する     … CUJ-14
#
# ノードは独自スクリプトのメンバーへ動的アクセスするため、型注釈を付けず Variant で扱う。
extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"

var _main

func before_each() -> void:
	_clear_save_file() # ハイスコアの永続化テストが他テストへ影響しないようにする
	_main = load(MAIN_SCENE).instantiate()
	add_child_autofree(_main)
	await wait_frames(2)

func after_each() -> void:
	_clear_save_file()

func _clear_save_file() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("savedata.cfg"):
		dir.remove("savedata.cfg")

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

# E2E-23 ---------------------------------------------------------------
func test_stage_clear_returns_to_title() -> void:
	_main._start_game()
	_main._on_stage_clear(9999)
	assert_true(_title().visible, "ステージクリアでタイトルへ戻る")
	var go_label = _main.get_node("TitleScreen/GameOverLabel")
	var score_label = _main.get_node("TitleScreen/FinalScoreLabel")
	assert_eq(go_label.text, "STAGE CLEAR", "ステージクリア表示が出る")
	assert_string_contains(score_label.text, "9999", "最終スコアが表示される")

# E2E-24 ---------------------------------------------------------------
func test_difficulty_selection_is_applied_on_start() -> void:
	_main._set_difficulty(Difficulty.Level.HARD)
	var diff_label = _main.get_node("TitleScreen/DifficultyLabel")
	assert_string_contains(diff_label.text, "HARD", "選択した難易度がラベルに反映される")
	_main._start_game()
	var player = _main.get_node("GameRoot/Game/Player")
	assert_eq(player.lives, Difficulty.get_preset(Difficulty.Level.HARD).lives,
		"選択した難易度の残機がゲーム開始に反映される")

# E2E-27 ---------------------------------------------------------------
func test_new_high_score_is_saved_and_shown_on_title() -> void:
	assert_eq(_main._high_score, 0, "保存ファイルが無い起動直後はハイスコア0")
	_main._start_game()
	_main._on_game_over(5000)
	var high_label = _main.get_node("TitleScreen/HighScoreLabel")
	assert_eq(_main._high_score, 5000, "新記録でハイスコアが更新される")
	assert_string_contains(high_label.text, "5000", "タイトルにハイスコアが表示される")
	assert_eq(SaveData.load_high_score(), 5000, "ハイスコアがディスクへ保存される")
