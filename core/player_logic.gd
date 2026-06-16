class_name PlayerLogic

const NORMAL_SPEED := 8.0
const FOCUS_SPEED := 3.5
const BOOST_SPEED := 14.0
const BOUNDS_X := 6.0
const BOUNDS_Z_MIN := -2.0
const BOUNDS_Z_MAX := 10.0
const HIT_RADIUS := 0.15
const GRAZE_RADIUS := 0.40

# 仮値。Layer B（Steam Deck実機）での操作感確認を経て調整する前提の暫定パラメータ。
const ACCELERATION := 60.0
const DECELERATION := 90.0

static func calc_velocity(input_dir: Vector2, is_focused: bool, _delta: float, is_boosting: bool = false) -> Vector3:
	var speed := NORMAL_SPEED
	if is_boosting:
		speed = BOOST_SPEED
	elif is_focused:
		speed = FOCUS_SPEED
	return Vector3(input_dir.x, 0.0, input_dir.y) * speed

# calc_velocity が返す「目標速度」へ、現在速度を慣性付きで近づける。
# 入力が無い（target == ZERO）ときは DECELERATION、それ以外は ACCELERATION で move_toward する。
static func apply_inertia(current_velocity: Vector3, target_velocity: Vector3, delta: float) -> Vector3:
	var rate := DECELERATION if target_velocity == Vector3.ZERO else ACCELERATION
	return current_velocity.move_toward(target_velocity, rate * delta)

static func clamp_position(pos: Vector3) -> Vector3:
	return Vector3(
		clamp(pos.x, -BOUNDS_X, BOUNDS_X),
		pos.y,
		clamp(pos.z, BOUNDS_Z_MIN, BOUNDS_Z_MAX)
	)

static func check_hit(player_pos: Vector3, bullet_pos: Vector3) -> bool:
	return player_pos.distance_to(bullet_pos) < HIT_RADIUS

static func check_graze(player_pos: Vector3, bullet_pos: Vector3) -> bool:
	var d := player_pos.distance_to(bullet_pos)
	return d >= HIT_RADIUS and d < GRAZE_RADIUS
