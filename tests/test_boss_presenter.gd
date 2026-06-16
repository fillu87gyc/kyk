# 単体テスト: BossPresenter（インターフェース基底）
#
# カバーする CUJ:
#   CUJ-8  ボス表現（Presenter インターフェース適合）
#   CUJ-9  MOD 差し替え（基底契約：MOD はこの契約を満たす）
#
# 基底の既定実装が「壊れない no-op」かつ is_valid()==true であることを保証する。
# MOD 開発者がこの契約に依存するため、回帰で破壊されないよう固定する。
extends GutTest

func test_base_is_node3d() -> void:
	var p := BossPresenter.new()
	assert_is(p, Node3D, "BossPresenter は Node3D を継承する")
	p.free()

func test_base_is_valid_true_by_default() -> void:
	var p := BossPresenter.new()
	assert_true(p.is_valid(), "既定の Presenter は有効")
	p.free()

func test_base_callbacks_are_safe_noops() -> void:
	# 基底のコールバックは引数を受けても例外を出さない（純粋 no-op）
	var p := BossPresenter.new()
	p.on_state_changed("ATTACK")
	p.on_hp_changed(0.5)
	p.on_spell_declared("紅蓮")
	p.tick(0.016)
	assert_true(true, "基底コールバックは安全に呼び出せる")
	p.free()

func test_procedural_is_a_boss_presenter() -> void:
	# Liskov: ProceduralPresenter は BossPresenter として扱える
	var p := ProceduralPresenter.new()
	assert_is(p, BossPresenter, "ProceduralPresenter は BossPresenter の派生")
	p.free()

func test_sample_humanoid_is_a_boss_presenter() -> void:
	# SDK サンプル MOD も同じ契約を満たす
	var p := SampleHumanoidPresenter.new()
	assert_is(p, BossPresenter, "SampleHumanoidPresenter は BossPresenter の派生")
	p.free()

func test_hit_radius_override_unset_uses_default() -> void:
	var p := BossPresenter.new()
	assert_almost_eq(p.get_hit_radius(1.2), 1.2, 0.0001,
		"未設定(-1.0)のときは呼び出し側のデフォルト半径を使う")
	p.free()

func test_hit_radius_override_set_takes_precedence() -> void:
	var p := BossPresenter.new()
	p.hit_radius_override = 0.8
	assert_almost_eq(p.get_hit_radius(1.2), 0.8, 0.0001,
		"mod.json の hit_radius_override が指定されていればそれを使う")
	p.free()
