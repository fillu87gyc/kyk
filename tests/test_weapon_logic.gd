# 単体テスト: WeaponLogic（自機オートファイア・パワーアップ）
#
# カバーする CUJ:
#   CUJ-11 ボス撃破（自機の攻撃がボスにダメージを与える）
#   CUJ-12 パワーアップ（グレイズでパワーが増え、同時発射数が増える）
extends GutTest

# --- should_fire / tick_cooldown ------------------------------------------

func test_should_fire_when_timer_at_zero() -> void:
	assert_true(WeaponLogic.should_fire(0.0), "クールダウン0なら発射可能")

func test_should_not_fire_when_timer_positive() -> void:
	assert_false(WeaponLogic.should_fire(0.05), "クールダウン中は発射不可")

func test_tick_cooldown_decreases() -> void:
	var t := WeaponLogic.tick_cooldown(0.1, 0.04)
	assert_almost_eq(t, 0.06, 0.0001, "delta分だけ減少する")

func test_tick_cooldown_does_not_go_negative() -> void:
	var t := WeaponLogic.tick_cooldown(0.02, 0.1)
	assert_almost_eq(t, 0.0, 0.0001, "0未満にはならない")

# --- spawn_shots -----------------------------------------------------------

func test_spawn_shots_power_zero_is_single_shot() -> void:
	var shots := WeaponLogic.spawn_shots(Vector3.ZERO, 0)
	assert_eq(shots.size(), 1, "パワー0は1本のみ")
	assert_almost_eq(shots[0].position.x, 0.0, 0.0001, "1本のときは中央から発射")

func test_spawn_shots_power_increases_count() -> void:
	var shots := WeaponLogic.spawn_shots(Vector3.ZERO, WeaponLogic.MAX_POWER)
	assert_eq(shots.size(), 1 + WeaponLogic.MAX_POWER, "パワー分だけ本数が増える")

func test_spawn_shots_travel_forward() -> void:
	var shots := WeaponLogic.spawn_shots(Vector3.ZERO, 0)
	assert_lt(shots[0].velocity.z, 0.0, "弾はボス方向(-Z)へ進む")
	assert_almost_eq(shots[0].velocity.length(), WeaponLogic.BULLET_SPEED, 0.0001,
		"速度は定数 BULLET_SPEED と一致する")

# --- power_from_graze --------------------------------------------------------

func test_power_from_graze_zero() -> void:
	assert_eq(WeaponLogic.power_from_graze(0), 0, "グレイズ0ならパワー0")

func test_power_from_graze_scales() -> void:
	assert_eq(WeaponLogic.power_from_graze(WeaponLogic.GRAZE_PER_POWER), 1,
		"GRAZE_PER_POWER回でパワー1")

func test_power_from_graze_caps_at_max() -> void:
	assert_eq(WeaponLogic.power_from_graze(99999), WeaponLogic.MAX_POWER,
		"パワーは MAX_POWER で頭打ち")

# --- check_boss_hit -----------------------------------------------------------

func test_check_boss_hit_inside_radius() -> void:
	assert_true(WeaponLogic.check_boss_hit(Vector3.ZERO, Vector3(0, 0, 0.5), 1.0),
		"判定内ならヒット")

func test_check_boss_hit_outside_radius() -> void:
	assert_false(WeaponLogic.check_boss_hit(Vector3.ZERO, Vector3(0, 0, 5.0), 1.0),
		"判定外はヒットしない")
