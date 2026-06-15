extends Node3D

signal game_over(score: int)
signal score_updated(score: int)

var score := 0
var _graze_score := 10
var _running := false

@onready var _player: CharacterBody3D = $Player
@onready var _bullet_manager: Node3D = $BulletManager
@onready var _presenter: BossPresenter = $BossPresenterSlot
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _graze_label: Label = $HUD/GrazeLabel

func _ready() -> void:
	_player.died.connect(_on_player_died)
	_player.graze_triggered.connect(_on_graze)
	_bullet_manager.bullet_hit_player.connect(_on_bullet_hit)
	_bullet_manager.bullet_grazed_player.connect(_on_bullet_graze)
	_update_hud()

func start(seed_val: int = 0) -> void:
	_running = true
	score = 0
	if seed_val != 0:
		_bullet_manager._rng.seed = seed_val
	_bullet_manager.reset()
	_player.lives = 3
	_player.graze = 0
	_update_hud()
	_presenter.on_state_changed("ATTACK")

func _physics_process(delta: float) -> void:
	if not _running:
		return
	_bullet_manager.check_collisions(_player.global_position)
	_presenter.tick(delta)

func _on_bullet_hit(_pos: Vector3) -> void:
	_player.take_hit()
	_update_hud()

func _on_bullet_graze(_pos: Vector3) -> void:
	_player.add_graze()
	score += _graze_score
	_update_hud()
	emit_signal("score_updated", score)

func _on_graze() -> void:
	pass

func _on_player_died() -> void:
	_running = false
	_presenter.on_state_changed("DEFEATED")
	emit_signal("game_over", score)

func _update_hud() -> void:
	_score_label.text = "SCORE: %d" % score
	_lives_label.text = "LIVES: %d" % _player.lives
	_graze_label.text = "GRAZE: %d" % _player.graze
