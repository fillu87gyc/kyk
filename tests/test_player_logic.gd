# 単体テスト: PlayerLogic（純粋ロジック層）
#
# カバーする CUJ:
#   CUJ-3  自機操作（移動速度・フォーカス・境界クランプ）
#   CUJ-5  被弾（喰らい判定）
#   CUJ-6  グレイズ（かすり判定）
#
# 対象関数: calc_velocity / clamp_position / check_hit / check_graze
extends GutTest

# --- calc_velocity --------------------------------------------------------

func test_normal_speed_magnitude() -> void:
	var vel := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016)
	assert_almost_eq(vel.length(), PlayerLogic.NORMAL_SPEED, 0.001,
		"通常移動の速度は定数 NORMAL_SPEED と一致する")

func test_focus_speed_exact_value() -> void:
	var vel := PlayerLogic.calc_velocity(Vector2(0.0, 1.0), true, 0.016)
	assert_almost_eq(vel.length(), PlayerLogic.FOCUS_SPEED, 0.001,
		"フォーカス移動の速度は定数 FOCUS_SPEED と一致する")

func test_focus_speed_is_slower() -> void:
	var normal := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016)
	var focused := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), true, 0.016)
	assert_lt(focused.length(), normal.length(), "フォーカス時は通常時より遅い")

func test_zero_input_is_zero_velocity() -> void:
	var vel := PlayerLogic.calc_velocity(Vector2.ZERO, false, 0.016)
	assert_almost_eq(vel.length(), 0.0, 0.0001, "入力ゼロなら速度ゼロ")

func test_input_maps_x_to_x_and_y_to_z() -> void:
	# 入力 (x, y) は 3D 平面上で (x, 0, z) に写像される（奥行きは y）
	var vel := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016)
	assert_gt(vel.x, 0.0, "入力 x は世界座標 x に写る")
	assert_almost_eq(vel.z, 0.0, 0.0001, "x のみ入力なら z 成分は 0")
	assert_almost_eq(vel.y, 0.0, 0.0001, "移動は常に水平面（y=0）")

	var vel2 := PlayerLogic.calc_velocity(Vector2(0.0, 1.0), false, 0.016)
	assert_gt(vel2.z, 0.0, "入力 y は世界座標 z に写る")
	assert_almost_eq(vel2.x, 0.0, 0.0001, "y のみ入力なら x 成分は 0")

func test_velocity_scales_with_input_magnitude() -> void:
	# 入力ベクトルの長さに比例（focus 中も含め決定論）
	var half := PlayerLogic.calc_velocity(Vector2(0.5, 0.0), false, 0.016)
	assert_almost_eq(half.length(), PlayerLogic.NORMAL_SPEED * 0.5, 0.001,
		"入力 0.5 なら速度も半分")

func test_boost_speed_exact_value() -> void:
	var vel := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016, true)
	assert_almost_eq(vel.length(), PlayerLogic.BOOST_SPEED, 0.001,
		"ブースト中の速度は定数 BOOST_SPEED と一致する")

func test_boost_is_faster_than_normal() -> void:
	var normal := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016, false)
	var boosted := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016, true)
	assert_gt(boosted.length(), normal.length(), "ブースト中は通常時より速い")

func test_boost_overrides_focus() -> void:
	var boosted := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), true, 0.016, true)
	assert_almost_eq(boosted.length(), PlayerLogic.BOOST_SPEED, 0.001,
		"フォーカス中でもブーストが優先される")

func test_default_is_boosting_false() -> void:
	# 既存呼び出し（3引数）との後方互換性を保つ
	var vel := PlayerLogic.calc_velocity(Vector2(1.0, 0.0), false, 0.016)
	assert_almost_eq(vel.length(), PlayerLogic.NORMAL_SPEED, 0.001,
		"is_boosting 省略時は通常速度のまま")

# --- apply_inertia（慣性・減速） --------------------------------------------
# NOTE: ACCELERATION/DECELERATION は仮値。Layer B（Steam Deck実機）での
# 主観確認を経て調整される前提の暫定パラメータ。ここでは数値遷移の決定論のみ検証する。

func test_apply_inertia_does_not_jump_instantly_to_target() -> void:
	var result := PlayerLogic.apply_inertia(Vector3.ZERO, Vector3(8, 0, 0), 0.016)
	assert_gt(result.x, 0.0, "目標方向へ加速し始める")
	assert_lt(result.x, 8.0, "1フレームでは目標速度に到達しない（瞬時切替ではない）")

func test_apply_inertia_reaches_target_eventually() -> void:
	var v := Vector3.ZERO
	var target := Vector3(8, 0, 0)
	for i in 120:
		v = PlayerLogic.apply_inertia(v, target, 0.016)
	assert_almost_eq(v.x, 8.0, 0.01, "十分な時間が経てば目標速度に収束する")

func test_apply_inertia_decelerates_when_input_released() -> void:
	var v := PlayerLogic.apply_inertia(Vector3(8, 0, 0), Vector3.ZERO, 0.016)
	assert_lt(v.x, 8.0, "入力を離すと減速する")
	assert_gt(v.x, 0.0, "1フレームでは完全停止しない")

func test_apply_inertia_decelerates_faster_than_it_accelerates() -> void:
	var accel_step: float = PlayerLogic.apply_inertia(Vector3.ZERO, Vector3(8, 0, 0), 0.1).x
	var decel_step: float = 8.0 - PlayerLogic.apply_inertia(Vector3(8, 0, 0), Vector3.ZERO, 0.1).x
	assert_gt(decel_step, accel_step, "減速は加速より素早い（急停止できる）")

func test_apply_inertia_is_deterministic() -> void:
	var v1 := PlayerLogic.apply_inertia(Vector3(1, 0, 0), Vector3(8, 0, 0), 0.016)
	var v2 := PlayerLogic.apply_inertia(Vector3(1, 0, 0), Vector3(8, 0, 0), 0.016)
	assert_eq(v1, v2, "同じ入力なら同じ結果（決定論）")

# --- clamp_position -------------------------------------------------------

func test_clamp_within_bounds() -> void:
	var clamped := PlayerLogic.clamp_position(Vector3(100.0, 0.0, 100.0))
	assert_lte(clamped.x, PlayerLogic.BOUNDS_X)
	assert_lte(clamped.z, PlayerLogic.BOUNDS_Z_MAX)

func test_clamp_negative_bounds() -> void:
	var clamped := PlayerLogic.clamp_position(Vector3(-100.0, 0.0, -100.0))
	assert_gte(clamped.x, -PlayerLogic.BOUNDS_X)
	assert_gte(clamped.z, PlayerLogic.BOUNDS_Z_MIN)

func test_clamp_exact_boundary_values() -> void:
	var clamped := PlayerLogic.clamp_position(Vector3(999.0, 0.0, 999.0))
	assert_almost_eq(clamped.x, PlayerLogic.BOUNDS_X, 0.0001, "x は上限で止まる")
	assert_almost_eq(clamped.z, PlayerLogic.BOUNDS_Z_MAX, 0.0001, "z は上限で止まる")

func test_clamp_preserves_y() -> void:
	var clamped := PlayerLogic.clamp_position(Vector3(0.0, 3.14, 0.0))
	assert_almost_eq(clamped.y, 3.14, 0.0001, "y はクランプ対象外（保持される）")

func test_clamp_noop_inside() -> void:
	var inside := Vector3(1.0, 0.0, 1.0)
	var clamped := PlayerLogic.clamp_position(inside)
	assert_eq(clamped, inside, "境界内の座標は変化しない")

# --- check_hit ------------------------------------------------------------

func test_hit_detection_inside() -> void:
	assert_true(PlayerLogic.check_hit(Vector3.ZERO, Vector3(0, 0, 0.1)),
		"喰らい判定内の弾はヒット")

func test_hit_detection_outside() -> void:
	assert_false(PlayerLogic.check_hit(Vector3.ZERO, Vector3(0, 0, 0.5)),
		"遠い弾はヒットしない")

func test_hit_exact_boundary_is_miss() -> void:
	# 距離 == HIT_RADIUS は「< 判定」なのでヒットしない（境界の片側性）
	var bullet := Vector3(0, 0, PlayerLogic.HIT_RADIUS)
	assert_false(PlayerLogic.check_hit(Vector3.ZERO, bullet),
		"距離がちょうど HIT_RADIUS のときはヒットしない")

func test_hit_just_inside_boundary() -> void:
	var bullet := Vector3(0, 0, PlayerLogic.HIT_RADIUS - 0.001)
	assert_true(PlayerLogic.check_hit(Vector3.ZERO, bullet),
		"HIT_RADIUS のわずか内側はヒット")

# --- check_graze ----------------------------------------------------------

func test_graze_detection() -> void:
	var bullet := Vector3(0, 0, 0.3)
	assert_false(PlayerLogic.check_hit(Vector3.ZERO, bullet), "グレイズ距離はヒットしない")
	assert_true(PlayerLogic.check_graze(Vector3.ZERO, bullet), "グレイズ距離はかする")

func test_no_graze_outside_range() -> void:
	assert_false(PlayerLogic.check_graze(Vector3.ZERO, Vector3(0, 0, 1.0)),
		"グレイズ外周より外はかすらない")

func test_no_graze_inside_hitbox() -> void:
	# 喰らい判定の内側はグレイズではなくヒット扱い（二重カウント防止）
	var bullet := Vector3(0, 0, 0.05)
	assert_true(PlayerLogic.check_hit(Vector3.ZERO, bullet))
	assert_false(PlayerLogic.check_graze(Vector3.ZERO, bullet),
		"喰らい判定内はグレイズしない")

func test_graze_inner_boundary_inclusive() -> void:
	# d == HIT_RADIUS はグレイズ成立（>= 判定）
	var bullet := Vector3(0, 0, PlayerLogic.HIT_RADIUS)
	assert_true(PlayerLogic.check_graze(Vector3.ZERO, bullet),
		"距離 == HIT_RADIUS はグレイズ成立")

func test_graze_outer_boundary_exclusive() -> void:
	# d == GRAZE_RADIUS はグレイズ不成立（< 判定）
	var bullet := Vector3(0, 0, PlayerLogic.GRAZE_RADIUS)
	assert_false(PlayerLogic.check_graze(Vector3.ZERO, bullet),
		"距離 == GRAZE_RADIUS はグレイズしない")
