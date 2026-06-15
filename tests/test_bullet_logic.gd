extends GutTest

var _rng := RandomNumberGenerator.new()

func before_each() -> void:
	_rng.seed = 99999

func test_ring_spawn_count() -> void:
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, _rng)
	assert_eq(bullets.size(), 16, "ring should spawn exact count")

func test_ring_all_active() -> void:
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 8, 3.0, _rng)
	for b in bullets:
		assert_true(b.active)

func test_ring_speeds_uniform() -> void:
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 8, 5.0, _rng)
	for b in bullets:
		assert_almost_eq(b.velocity.length(), 5.0, 0.01,
			"all ring bullets should have same speed")

func test_step_moves_bullets() -> void:
	_rng.seed = 42
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 4, 3.0, _rng)
	var initial_pos := bullets[0].position
	BulletLogic.step(bullets, 1.0)
	assert_ne(bullets[0].position, initial_pos, "bullet should move after step")

func test_step_expires_old_bullets() -> void:
	_rng.seed = 42
	var bullets := BulletLogic.spawn_ring(Vector3.ZERO, 4, 3.0, _rng)
	BulletLogic.step(bullets, BulletLogic.LIFETIME + 0.1)
	for b in bullets:
		assert_false(b.active, "expired bullet should be inactive")

func test_aimed_bullet_direction() -> void:
	var src := Vector3(0, 0, -5)
	var tgt := Vector3(0, 0, 5)
	var bullets := BulletLogic.spawn_aimed(src, tgt, 1, 0.0, 4.0)
	assert_eq(bullets.size(), 1)
	var vel: Vector3 = bullets[0].velocity
	assert_almost_eq(vel.normalized().z, 1.0, 0.01, "aimed bullet should travel toward target")

func test_determinism_same_seed() -> void:
	var rng1 := RandomNumberGenerator.new()
	var rng2 := RandomNumberGenerator.new()
	rng1.seed = 777
	rng2.seed = 777
	var b1 := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, rng1)
	var b2 := BulletLogic.spawn_ring(Vector3.ZERO, 16, 3.0, rng2)
	for i in b1.size():
		assert_almost_eq(b1[i].velocity.x, b2[i].velocity.x, 0.0001,
			"same seed must produce same result")
