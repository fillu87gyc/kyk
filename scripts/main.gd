extends Node

@onready var _title: CanvasLayer = $TitleScreen
@onready var _game_root: Node3D = $GameRoot
@onready var _game: Node = $GameRoot/Game
@onready var _gameover_label: Label = $TitleScreen/GameOverLabel
@onready var _final_score_label: Label = $TitleScreen/FinalScoreLabel
@onready var _difficulty_label: Label = $TitleScreen/DifficultyLabel
@onready var _high_score_label: Label = $TitleScreen/HighScoreLabel

var _difficulty: int = Difficulty.Level.NORMAL
var _high_score := 0

func _ready() -> void:
	_game.game_over.connect(_on_game_over)
	_game.stage_clear.connect(_on_stage_clear)
	_high_score = SaveData.load_high_score()
	_show_title()

func _unhandled_input(event: InputEvent) -> void:
	if not _title.visible:
		return
	if event.is_action_pressed("ui_confirm"):
		_start_game()
	elif event.is_action_pressed("move_left"):
		_set_difficulty(Difficulty.previous_level(_difficulty))
	elif event.is_action_pressed("move_right"):
		_set_difficulty(Difficulty.next_level(_difficulty))

func _set_difficulty(level: int) -> void:
	_difficulty = level
	_difficulty_label.text = "難易度: %s" % Difficulty.get_preset(_difficulty).name

func _show_title() -> void:
	_title.visible = true
	_game_root.visible = false
	_set_difficulty(_difficulty)
	_high_score_label.text = "HIGH SCORE: %d" % _high_score

func _start_game() -> void:
	_title.visible = false
	_game_root.visible = true
	_game.start(0, _difficulty)

func _on_game_over(final_score: int) -> void:
	_gameover_label.modulate = Color(1, 0.3, 0.3, 1)
	_gameover_label.text = "GAME OVER"
	_finish_run(final_score)

func _on_stage_clear(final_score: int) -> void:
	_gameover_label.modulate = Color(0.4, 1, 0.6, 1)
	_gameover_label.text = "STAGE CLEAR"
	_finish_run(final_score)

func _finish_run(final_score: int) -> void:
	_final_score_label.text = "SCORE: %d" % final_score
	if SaveData.is_new_high_score(final_score, _high_score):
		_high_score = final_score
		SaveData.save_high_score(_high_score)
	_show_title()
