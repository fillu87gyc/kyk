# 単体テスト: BulletLogic（純粋ロジック層）
#
# カバーする CUJ:
#   CUJ-4  弾幕出現（リング/エイム弾の生成・移動・寿命消滅）
#   CUJ-10 決定論（同一シード → 同一弾幕）
#
# 対象: BulletState / step / spawn_ring / spawn_aimed / 定数
extends GutTest

var _rng := RandomNumberGenerator.new()

func before_each() -> void:
	_rng.seed = 99999

# --- BulletState ----------------------------------------------------------

func test_bullet_state_defaults() -> void:
	var b = BulletLogic.BulletState.new(Vector3(1, 2, 3), Vector3(4, 5, 6))
	assert_eq(b.position, Vector3(1, 2, 3), "position は引数で初期化")
	assert_eq(b.velocity, Vector3(4, 5, 6), "velocity は引数で初期化")
	assert_almost_eq(b.age, 0.0, 0.0001, "age の初期値は 0")
	assert_true(b.active, "生成直後は active")

# --- spawn_ring -----------------------------------------------------------

func test_ring_spawn_count() -> void:
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, _rng)
	assert_eq(bullets.size(), 16, "リングは指定数ちょうどを生成する")

func test_ring_all_active() -> void:
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 8, 3.0, _rng)
	for b in bullets:
		assert_true(b.active)

func test_ring_speeds_uniform() -> void:
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 8, 5.0, _rng)
	for b in bullets:
		assert_almost_eq(b.velocity.length(), 5.0, 0.01,
			"リング弾はすべて同一の速度")

func test_ring_spawns_at_center() -> void:
	var center := Vector3(1.0, 0.0, -4.0)
	var bullets := BulletLogic.spawn_ring(center, 6, 3.0, _rng)
	for b in bullets:
		assert_eq(b.position, center, "リング弾の初期位置はすべて中心")

func test_ring_velocities_are_horizontal() -> void:
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 12, 3.0, _rng)
	for b in bullets:
		assert_almost_eq(b.velocity.y, 0.0, 0.0001, "リング弾は水平面に展開する")

func test_ring_directions_spread() -> void:
	# 16 発のリングは互いに異なる方向を向く（少なくとも 2 方向以上）
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, _rng)
	var first: Vector3 = bullets[0].velocity.normalized()
	var opposite: Vector3 = bullets[8].velocity.normalized()
	assert_lt(first.dot(opposite), 0.0,
		"対角（i=0 と i=8）の弾はほぼ逆方向を向く")

# --- spawn_aimed ----------------------------------------------------------

func test_aimed_bullet_direction() -> void:
	var src := Vector3(0, 0, -5)
	var tgt := Vector3(0, 0, 5)
	var bullets := BulletLogic.spawn_aimed(src, tgt, 1, 0.0, 4.0)
	assert_eq(bullets.size(), 1)
	var vel: Vector3 = bullets[0].velocity
	assert_almost_eq(vel.normalized().z, 1.0, 0.01, "エイム弾は標的方向へ進む")

func test_aimed_spread_count() -> void:
	var bullets := BulletLogic.spawn_aimed(Vector3.ZERO, Vector3(0, 0, 5), 5, 0.3, 4.0)
	assert_eq(bullets.size(), 5, "扇状弾は spread_count ちょうどを生成する")

func test_aimed_single_has_no_offset() -> void:
	# spread_count==1 は中心方向 1 本のみ（lerp の 0 除算を踏まない）
	var bullets := BulletLogic.spawn_aimed(Vector3.ZERO, Vector3(1, 0, 0), 1, 1.0, 4.0)
	assert_eq(bullets.size(), 1)
	assert_almost_eq(bullets[0].velocity.normalized().x, 1.0, 0.01,
		"単発エイムは標的方向ぴったり")

func test_aimed_speed_magnitude() -> void:
	var bullets := BulletLogic.spawn_aimed(Vector3.ZERO, Vector3(0, 0, 5), 3, 0.3, 7.0)
	for b in bullets:
		assert_almost_eq(b.velocity.length(), 7.0, 0.01, "扇状弾も指定速度を保つ")

func test_aimed_spread_is_symmetric() -> void:
	# 奇数本の扇は中央弾を中心に対称（両端の x 成分が符号反転）
	var bullets := BulletLogic.spawn_aimed(Vector3.ZERO, Vector3(0, 0, 5), 5, 0.4, 4.0)
	var left: Vector3 = bullets[0].velocity
	var right: Vector3 = bullets[4].velocity
	assert_almost_eq(left.x, -right.x, 0.01, "両端弾は左右対称")
	var mid: Vector3 = bullets[2].velocity
	assert_almost_eq(mid.x, 0.0, 0.01, "中央弾は標的方向（オフセット 0）")

# --- step -----------------------------------------------------------------

func test_step_moves_bullets() -> void:
	_rng.seed = 42
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 4, 3.0, _rng)
	var initial_pos: Vector3 = bullets[0].position
	BulletLogic.step(bullets, 1.0)
	assert_ne(bullets[0].position, initial_pos, "step 後に弾は移動する")

func test_step_position_is_exact() -> void:
	var b = BulletLogic.BulletState.new(Vector3.ZERO, Vector3(2.0, 0.0, 0.0))
	BulletLogic.step([b], 0.5)
	assert_almost_eq(b.position.x, 1.0, 0.0001, "position += velocity * delta（決定論）")

func test_step_accumulates_age() -> void:
	var b = BulletLogic.BulletState.new(Vector3.ZERO, Vector3.ZERO)
	BulletLogic.step([b], 0.25)
	BulletLogic.step([b], 0.25)
	assert_almost_eq(b.age, 0.5, 0.0001, "age は delta を積算する")

func test_step_expires_old_bullets() -> void:
	_rng.seed = 42
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 4, 3.0, _rng)
	BulletLogic.step(bullets, BulletLogic.LIFETIME + 0.1)
	for b in bullets:
		assert_false(b.active, "寿命を超えた弾は非アクティブになる")

func test_step_ignores_inactive_bullets() -> void:
	var b = BulletLogic.BulletState.new(Vector3.ZERO, Vector3(5.0, 0.0, 0.0))
	b.active = false
	BulletLogic.step([b], 1.0)
	assert_eq(b.position, Vector3.ZERO, "非アクティブな弾は移動しない")
	assert_almost_eq(b.age, 0.0, 0.0001, "非アクティブな弾は加齢しない")

func test_step_at_lifetime_boundary_stays_active() -> void:
	var b = BulletLogic.BulletState.new(Vector3.ZERO, Vector3.ZERO)
	BulletLogic.step([b], BulletLogic.LIFETIME)
	assert_true(b.active, "age == LIFETIME は（> 判定なので）まだ生存")

# --- 定数 / 決定論 --------------------------------------------------------

func test_constants_are_sane() -> void:
	assert_gt(BulletLogic.MAX_BULLETS, 0, "MAX_BULLETS は正")
	assert_gt(BulletLogic.LIFETIME, 0.0, "LIFETIME は正")

func test_determinism_same_seed() -> void:
	var rng1 := RandomNumberGenerator.new()
	var rng2 := RandomNumberGenerator.new()
	rng1.seed = 777
	rng2.seed = 777
	var b1 := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, rng1)
	var b2 := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, rng2)
	for i in b1.size():
		assert_almost_eq(b1[i].velocity.x, b2[i].velocity.x, 0.0001,
			"同一シードは同一結果を生む")

# --- cull_out_of_range（奥カリング） ---------------------------------------

func test_cull_out_of_range_deactivates_far_bullets() -> void:
	var near_b = BulletLogic.BulletState.new(Vector3(5, 0, 5), Vector3.ZERO)
	var far_b = BulletLogic.BulletState.new(Vector3(200, 0, 0), Vector3.ZERO)
	var bullets := [near_b, far_b]
	BulletLogic.cull_out_of_range(bullets, Vector3.ZERO, 60.0)
	assert_true(near_b.active, "範囲内の弾は残る")
	assert_false(far_b.active, "範囲外の弾は非アクティブになる")

func test_cull_out_of_range_ignores_already_inactive() -> void:
	var b = BulletLogic.BulletState.new(Vector3(200, 0, 0), Vector3.ZERO)
	b.active = false
	BulletLogic.cull_out_of_range([b], Vector3.ZERO, 60.0)
	assert_false(b.active, "すでに非アクティブな弾はそのまま")

func test_determinism_different_seed_differs() -> void:
	var rng1 := RandomNumberGenerator.new()
	var rng2 := RandomNumberGenerator.new()
	rng1.seed = 1
	rng2.seed = 2
	var b1 := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, rng1)
	var b2 := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, rng2)
	var any_diff := false
	for i in b1.size():
		if abs(b1[i].velocity.x - b2[i].velocity.x) > 0.0001:
			any_diff = true
			break
	assert_true(any_diff, "異なるシードは異なるジッターを生む")
