class_name PlayerLogic

const NORMAL_SPEED := 8.0
const FOCUS_SPEED := 3.5
const BOUNDS_X := 6.0
const BOUNDS_Z_MIN := -2.0
const BOUNDS_Z_MAX := 10.0
const HIT_RADIUS := 0.15
const GRAZE_RADIUS := 0.40

static func calc_velocity(input_dir: Vector2, is_focused: bool, _delta: float) -> Vector3:
	var speed := FOCUS_SPEED if is_focused else NORMAL_SPEED
	return Vector3(input_dir.x, 0.0, input_dir.y) * speed

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
