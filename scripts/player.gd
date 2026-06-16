extends CharacterBody3D

signal died
signal graze_triggered

var lives := 3
var graze := 0
var is_boosting := false
var _invincible := false
var _invincible_timer := 0.0
var _debug_hitbox_visible := false
var _was_focused := false
const INVINCIBLE_DURATION := 2.0

@onready var _hitbox_visual: MeshInstance3D = $HitboxVisual
@onready var _graze_visual: MeshInstance3D = $GrazeVisual
@onready var _presenter: PlayerPresenter = $PlayerPresenterSlot

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if _invincible:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			_invincible = false
			_presenter.on_hit_flash(false)
			_update_hitbox_visual()

	if Input.is_action_just_pressed("toggle_debug_hitbox"):
		toggle_debug_hitbox()

	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var focused := Input.is_action_pressed("focus")
	is_boosting = Input.is_action_pressed("boost")
	if focused != _was_focused:
		_presenter.on_focus_changed(focused)
		_was_focused = focused
	velocity = PlayerLogic.calc_velocity(raw, focused, delta, is_boosting)
	move_and_slide()
	position = PlayerLogic.clamp_position(position)
	_presenter.tick(delta)

func take_hit() -> void:
	if _invincible:
		return
	lives -= 1
	_invincible = true
	_invincible_timer = INVINCIBLE_DURATION
	_presenter.on_hit_flash(true)
	_update_hitbox_visual()
	if lives <= 0:
		emit_signal("died")

func add_graze() -> void:
	graze += 1
	_presenter.on_graze()
	emit_signal("graze_triggered")

func toggle_debug_hitbox() -> void:
	_debug_hitbox_visible = not _debug_hitbox_visible
	_update_hitbox_visual()
	_graze_visual.visible = _debug_hitbox_visible

func _update_hitbox_visual() -> void:
	_hitbox_visual.visible = _invincible or _debug_hitbox_visible
