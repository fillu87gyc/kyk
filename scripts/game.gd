extends Node3D

signal game_over(score: int)
signal score_updated(score: int)

const CAM_OFFSET := Vector3(0.0, 4.0, 7.0)
const CAM_BOOST_OFFSET := Vector3(0.0, 4.5, 9.5)
const CAM_LOOK_AHEAD := 9.0
const CAM_FOLLOW_LERP := 5.0
const FOV_NORMAL := 70.0
const FOV_BOOST := 85.0
const FOV_LERP := 4.0

var score := 0
var _graze_score := 10
var _running := false

@onready var _player: CharacterBody3D = $Player
@onready var _bullet_manager: Node3D = $BulletManager
@onready var _presenter: BossPresenter = $BossPresenterSlot
@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _graze_label: Label = $HUD/GrazeLabel

func _ready() -> void:
	_player.died.connect(_on_player_died)
	_player.graze_triggered.connect(_on_graze)
	_bullet_manager.bullet_hit_player.connect(_on_bullet_hit)
	_bullet_manager.bullet_grazed_player.connect(_on_bullet_graze)
	_setup_world()
	_update_hud()

func _setup_world() -> void:
	_light.shadow_enabled = true

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.05, 0.03, 0.09)
	ground_mat.roughness = 0.85
	plane.material = ground_mat
	ground.mesh = plane
	ground.position = Vector3(0.0, -0.2, 3.0)
	add_child(ground)

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
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	var player_pos := _player.global_position
	var offset := CAM_BOOST_OFFSET if _player.is_boosting else CAM_OFFSET
	var target_pos := player_pos + offset
	_camera.global_position = _camera.global_position.lerp(
		target_pos, delta * CAM_FOLLOW_LERP)
	var look_target := Vector3(
		player_pos.x, player_pos.y + 0.5, player_pos.z - CAM_LOOK_AHEAD)
	_camera.look_at(look_target, Vector3.UP)
	var target_fov := FOV_BOOST if _player.is_boosting else FOV_NORMAL
	_camera.fov = lerp(_camera.fov, target_fov, delta * FOV_LERP)

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
