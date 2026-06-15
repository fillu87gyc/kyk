extends GutTest

func test_normal_speed_magnitude() -> void:
	var vel := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016)
	assert_almost_eq(vel.length(), PlayerLogic.NORMAL_SPEED, 0.001,
		"normal speed should match constant")

func test_focus_speed_is_slower() -> void:
	var normal := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016)
	var focused := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), true, 0.016)
	assert_lt(focused.length(), normal.length(), "focus speed must be less than normal speed")

func test_clamp_within_bounds() -> void:
	var clamped := PlayerLogic.clamp_position(Vector3(100.0, 0.0, 100.0))
	assert_lte(clamped.x, PlayerLogic.BOUNDS_X)
	assert_lte(clamped.z, PlayerLogic.BOUNDS_Z_MAX)

func test_clamp_negative_bounds() -> void:
	var clamped := PlayerLogic.clamp_position(Vector3(-100.0, 0.0, -100.0))
	assert_gte(clamped.x, -PlayerLogic.BOUNDS_X)
	assert_gte(clamped.z, PlayerLogic.BOUNDS_Z_MIN)

func test_hit_detection_inside() -> void:
	var player := Vector3(0, 0, 0)
	var bullet := Vector3(0, 0, 0.1)
	assert_true(PlayerLogic.check_hit(player, bullet), "bullet inside hitbox should hit")

func test_hit_detection_outside() -> void:
	var player := Vector3(0, 0, 0)
	var bullet := Vector3(0, 0, 0.5)
	assert_false(PlayerLogic.check_hit(player, bullet), "distant bullet should not hit")

func test_graze_detection() -> void:
	var player := Vector3(0, 0, 0)
	var bullet := Vector3(0, 0, 0.3)
	assert_false(PlayerLogic.check_hit(player, bullet), "graze-range bullet should not hit")
	assert_true(PlayerLogic.check_graze(player, bullet), "graze-range bullet should graze")

func test_no_graze_outside_range() -> void:
	var player := Vector3(0, 0, 0)
	var bullet := Vector3(0, 0, 1.0)
	assert_false(PlayerLogic.check_graze(player, bullet), "far bullet should not graze")
