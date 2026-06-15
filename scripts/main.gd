extends Node

@onready var _title: CanvasLayer = $TitleScreen
@onready var _game_root: Node3D = $GameRoot
@onready var _game: Node = $GameRoot/Game
@onready var _gameover_label: Label = $TitleScreen/GameOverLabel
@onready var _final_score_label: Label = $TitleScreen/FinalScoreLabel

func _ready() -> void:
	_game.game_over.connect(_on_game_over)
	_show_title()

func _unhandled_input(event: InputEvent) -> void:
	if _title.visible and event.is_action_pressed("ui_confirm"):
		_start_game()

func _show_title() -> void:
	_title.visible = true
	_game_root.visible = false

func _start_game() -> void:
	_title.visible = false
	_game_root.visible = true
	_game.start()

func _on_game_over(final_score: int) -> void:
	_gameover_label.text = "GAME OVER"
	_final_score_label.text = "SCORE: %d" % final_score
	_show_title()
