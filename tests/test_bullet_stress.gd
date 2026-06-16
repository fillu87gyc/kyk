# 単体テスト: 大規模弾幕の決定論性（ROADMAP Phase 2「3万発5秒シミュレートの決定論テスト」）
#
# 実フレームレート・実機パフォーマンスは Layer B（Steam Deck実機）でのみ確認できる。
# Layer A では「同シードなら3万発5秒分シミュレートしても同じ結果になる」
# という決定論性のみを検証する。
extends GutTest

const TOTAL_BULLETS := 30000
const STEPS_FOR_5_SECONDS := 300 # 60fps * 5秒

func _spawn_30k(seed_val: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var bullets: Array = []
	while bullets.size() < TOTAL_BULLETS:
		bullets.append_array(BulletLogic.spawn_ring_3d(Vector3.ZERO, 200, 3.0, rng))
	return bullets

func _position_sum(bullets: Array) -> Vector3:
	var total := Vector3.ZERO
	for b in bullets:
		total += b.position
	return total

func test_30000_bullets_5_seconds_is_deterministic_for_same_seed() -> void:
	var bullets_a := _spawn_30k(2024)
	var bullets_b := _spawn_30k(2024)
	assert_eq(bullets_a.size(), TOTAL_BULLETS, "3万発スポーンされる")

	for i in STEPS_FOR_5_SECONDS:
		BulletLogic.step(bullets_a, 1.0 / 60.0)
		BulletLogic.step(bullets_b, 1.0 / 60.0)

	assert_eq(_position_sum(bullets_a), _position_sum(bullets_b),
		"同シードで5秒分シミュレートすると3万発の位置合計が一致する（決定論）")

func test_30000_bullets_different_seed_diverges() -> void:
	var bullets_a := _spawn_30k(1)
	var bullets_b := _spawn_30k(2)

	for i in STEPS_FOR_5_SECONDS:
		BulletLogic.step(bullets_a, 1.0 / 60.0)
		BulletLogic.step(bullets_b, 1.0 / 60.0)

	assert_ne(_position_sum(bullets_a), _position_sum(bullets_b),
		"シードが違えば5秒後の結果も異なる（疑似乱数が機能している）")
