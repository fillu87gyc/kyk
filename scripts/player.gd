extends CharacterBody3D

signal died
signal graze_triggered

var lives := 3
var graze := 0
var _invincible := false
var _invincible_timer := 0.0
const INVINCIBLE_DURATION := 2.0

@onready var _hitbox_visual: MeshInstance3D = $HitboxVisual

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if _invincible:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			_invincible = false
			_hitbox_visual.visible = false

	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var focused := Input.is_action_pressed("focus")
	velocity = PlayerLogic.calc_velocity(raw, focused, delta)
	move_and_slide()
	position = PlayerLogic.clamp_position(position)

func take_hit() -> void:
	if _invincible:
		return
	lives -= 1
	_invincible = true
	_invincible_timer = INVINCIBLE_DURATION
	_hitbox_visual.visible = true
	if lives <= 0:
		emit_signal("died")

func add_graze() -> void:
	graze += 1
	emit_signal("graze_triggered")
