extends Node3D

signal game_over(score: int)
signal stage_clear(score: int)
signal score_updated(score: int)

const CAM_OFFSET := Vector3(0.0, 4.0, 7.0)
const CAM_BOOST_OFFSET := Vector3(0.0, 4.5, 9.5)
const CAM_LOOK_AHEAD := 9.0
const CAM_FOLLOW_LERP := 5.0
const FOV_NORMAL := 70.0
const FOV_BOOST := 85.0
const FOV_LERP := 4.0
const BOSS_HIT_RADIUS := 1.2
const HIT_STOP_DURATION := 0.12
const HIT_STOP_SCALE := 0.1
const GRAZE_STOP_DURATION := 0.04
const GRAZE_STOP_SCALE := 0.5

var score := 0
var _running := false
var _boss_state := BossStateMachine.new()
var _hit_stop := HitStopController.new()
var _hit_particles: GPUParticles3D
var _graze_particles: GPUParticles3D
var _defeat_particles: GPUParticles3D

@onready var _player: CharacterBody3D = $Player
@onready var _bullet_manager: Node3D = $BulletManager
@onready var _presenter: BossPresenter = $BossPresenterSlot
@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _score_label: Label = $HUD/ScoreLabel
@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _graze_label: Label = $HUD/GrazeLabel
@onready var _power_label: Label = $HUD/PowerLabel
@onready var _bombs_label: Label = $HUD/BombsLabel
@onready var _dash_label: Label = $HUD/DashLabel
@onready var _boss_hp_label: Label = $HUD/BossHpLabel
@onready var _spell_label: Label = $HUD/SpellLabel

func _ready() -> void:
	_player.died.connect(_on_player_died)
	_player.graze_triggered.connect(_on_graze)
	_bullet_manager.bullet_hit_player.connect(_on_bullet_hit)
	_bullet_manager.bullet_grazed_player.connect(_on_bullet_graze)
	_bullet_manager.bullet_hit_boss.connect(_on_bullet_hit_boss)
	_boss_state.state_changed.connect(_presenter.on_state_changed)
	_boss_state.hp_changed.connect(_on_boss_hp_changed)
	_boss_state.spell_declared.connect(_on_spell_declared)
	_boss_state.defeated.connect(_on_boss_defeated)
	_setup_world()
	_update_hud()

func _setup_world() -> void:
	_light.shadow_enabled = true

	var ground := StageDressing.build_grid_floor(Vector2(60.0, 60.0))
	ground.position = Vector3(0.0, -0.2, 3.0)
	add_child(ground)

	add_child(StageDressing.build_moon())
	add_child(StageDressing.build_silhouette(9, 99))

	_hit_particles = StageDressing.build_burst_particles(Color(1.0, 0.3, 0.2), 24)
	add_child(_hit_particles)
	_graze_particles = StageDressing.build_burst_particles(Color(1.0, 0.8, 0.2), 12)
	add_child(_graze_particles)
	_defeat_particles = StageDressing.build_burst_particles(Color(1.0, 0.6, 0.9), 64)
	add_child(_defeat_particles)

func start(seed_val: int = 0, difficulty_level: int = Difficulty.Level.NORMAL) -> void:
	_running = true
	score = 0
	if seed_val != 0:
		_bullet_manager._rng.seed = seed_val
	var preset := Difficulty.get_preset(difficulty_level)
	_bullet_manager.reset()
	_bullet_manager.set_speed_mult(preset.bullet_speed_mult)
	_player.lives = preset.lives
	_player.bombs = WeaponLogic.STARTING_BOMBS
	_player.graze = 0
	_boss_state.start(preset.boss_hp_mult)
	_spell_label.text = ""
	_update_hud()

func _physics_process(delta: float) -> void:
	if not _running:
		return
	var scale := _hit_stop.update(delta)
	Engine.time_scale = scale
	if Input.is_action_just_pressed("bomb"):
		_try_use_bomb()
	_bullet_manager.check_collisions(_player.global_position)
	_bullet_manager.check_boss_collisions(
		_presenter.global_position, _presenter.get_hit_radius(BOSS_HIT_RADIUS))
	_presenter.tick(delta)
	_update_camera(delta)
	_update_dash_hud()

func _try_use_bomb() -> void:
	if _player.use_bomb():
		_bullet_manager.clear_bullets_in_radius(_player.global_position, WeaponLogic.BOMB_RADIUS)
		_update_hud()

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

func _on_bullet_hit(pos: Vector3) -> void:
	_player.take_hit()
	_hit_stop.trigger(HIT_STOP_DURATION, HIT_STOP_SCALE)
	_emit_burst(_hit_particles, pos)
	_update_hud()

func _on_bullet_graze(pos: Vector3) -> void:
	_player.add_graze()
	score += ScoreLogic.graze_score()
	_hit_stop.trigger(GRAZE_STOP_DURATION, GRAZE_STOP_SCALE)
	_emit_burst(_graze_particles, pos)
	_update_hud()
	emit_signal("score_updated", score)

func _emit_burst(particles: GPUParticles3D, pos: Vector3) -> void:
	particles.global_position = pos
	particles.emitting = true
	particles.restart()

func _on_graze() -> void:
	pass

func _on_bullet_hit_boss(damage: float) -> void:
	_boss_state.take_damage(damage)

func _on_boss_hp_changed(ratio: float) -> void:
	_presenter.on_hp_changed(ratio)
	_boss_hp_label.text = "BOSS HP: %d%%" % round(ratio * 100.0)

func _on_spell_declared(spell_name: String) -> void:
	_presenter.on_spell_declared(spell_name)
	_spell_label.text = spell_name

func _on_player_died() -> void:
	_running = false
	Engine.time_scale = 1.0
	_presenter.on_state_changed("DEFEATED")
	emit_signal("game_over", score)

func _on_boss_defeated() -> void:
	_running = false
	Engine.time_scale = 1.0
	score += ScoreLogic.boss_defeat_score()
	_update_hud()
	emit_signal("score_updated", score)
	_emit_burst(_defeat_particles, _presenter.global_position)
	emit_signal("stage_clear", score)

func _update_hud() -> void:
	_score_label.text = "SCORE: %d" % score
	_lives_label.text = "LIVES: %d" % _player.lives
	_graze_label.text = "GRAZE: %d" % _player.graze
	_power_label.text = "POWER: %d" % WeaponLogic.power_from_graze(_player.graze)
	_bombs_label.text = "BOMB: %d" % _player.bombs
	_update_dash_hud()

func _update_dash_hud() -> void:
	if _player.is_dashing():
		_dash_label.text = "DASH: ACTIVE"
	elif _player.can_dash():
		_dash_label.text = "DASH: READY"
	else:
		_dash_label.text = "DASH: COOLDOWN"
